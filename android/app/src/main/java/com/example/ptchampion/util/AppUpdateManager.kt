package com.example.ptchampion.util

import android.app.Activity
import android.content.IntentSender
import androidx.fragment.app.FragmentActivity
import androidx.lifecycle.DefaultLifecycleObserver
import androidx.lifecycle.LifecycleOwner
import com.google.android.material.snackbar.Snackbar
import com.google.android.play.core.appupdate.AppUpdateInfo
import com.google.android.play.core.appupdate.AppUpdateManagerFactory
import com.google.android.play.core.appupdate.AppUpdateOptions
import com.google.android.play.core.install.InstallStateUpdatedListener
import com.google.android.play.core.install.model.AppUpdateType
import com.google.android.play.core.install.model.InstallStatus
import com.google.android.play.core.install.model.UpdateAvailability
import com.google.android.play.core.ktx.isFlexibleUpdateAllowed
import com.google.android.play.core.ktx.isImmediateUpdateAllowed
import javax.inject.Inject
import javax.inject.Singleton
import kotlin.coroutines.resume
import kotlin.coroutines.suspendCoroutine
import kotlinx.coroutines.tasks.await

/**
 * Handles in-app updates using the Google Play Core library.
 * 
 * Supports both immediate updates (blocking) and flexible updates (background).
 * Integrates with Activity lifecycle to automatically check for updates.
 */
@Singleton
class AppUpdateManager @Inject constructor() : DefaultLifecycleObserver {
    
    companion object {
        private const val UPDATE_REQUEST_CODE = 500
        private const val DAYS_FOR_FLEXIBLE_UPDATE = 3  // Show flexible update if app hasn't been updated in 3 days
        private const val DAYS_FOR_IMMEDIATE_UPDATE = 7 // Force immediate update if app hasn't been updated in 7 days
    }
    
    private var activity: FragmentActivity? = null
    private val appUpdateManager by lazy { 
        AppUpdateManagerFactory.create(activity?.applicationContext ?: throw IllegalStateException("Activity not attached")) 
    }
    
    private val installStateUpdatedListener = InstallStateUpdatedListener { state ->
        if (state.installStatus() == InstallStatus.DOWNLOADED) {
            // Update has been downloaded, notify user to complete installation
            activity?.let { showCompletionSnackbar(it) }
        }
    }
    
    /**
     * Attach the update manager to an activity's lifecycle
     */
    fun attachToActivity(activity: FragmentActivity) {
        this.activity = activity
        activity.lifecycle.addObserver(this)
    }
    
    override fun onResume(owner: LifecycleOwner) {
        super.onResume(owner)
        // Check if update was downloaded but not installed
        appUpdateManager.appUpdateInfo.addOnSuccessListener { appUpdateInfo ->
            if (appUpdateInfo.installStatus() == InstallStatus.DOWNLOADED) {
                activity?.let { showCompletionSnackbar(it) }
            }
            
            // Check if an update that was started needs to be resumed
            if (appUpdateInfo.updateAvailability() == UpdateAvailability.DEVELOPER_TRIGGERED_UPDATE_IN_PROGRESS) {
                startImmediateUpdate(appUpdateInfo)
            }
        }
    }
    
    override fun onDestroy(owner: LifecycleOwner) {
        appUpdateManager.unregisterListener(installStateUpdatedListener)
        activity = null
        super.onDestroy(owner)
    }
    
    /**
     * Check for app updates and handle them based on update policy
     */
    suspend fun checkForUpdates() {
        try {
            val appUpdateInfo = appUpdateManager.appUpdateInfo.await()
            
            when {
                // Critical update available - use immediate update
                isImmediateUpdateRequired(appUpdateInfo) -> {
                    startImmediateUpdate(appUpdateInfo)
                }
                
                // Non-critical update available - use flexible update
                isFlexibleUpdateAvailable(appUpdateInfo) -> {
                    startFlexibleUpdate(appUpdateInfo)
                }
            }
        } catch (e: Exception) {
            // Log update check failure but don't crash
            // Timber.e(e, "Failed to check for updates")
        }
    }
    
    private fun isImmediateUpdateRequired(appUpdateInfo: AppUpdateInfo): Boolean {
        return appUpdateInfo.updateAvailability() == UpdateAvailability.UPDATE_AVAILABLE &&
                appUpdateInfo.isImmediateUpdateAllowed &&
                appUpdateInfo.clientVersionStalenessDays() ?: 0 >= DAYS_FOR_IMMEDIATE_UPDATE
    }
    
    private fun isFlexibleUpdateAvailable(appUpdateInfo: AppUpdateInfo): Boolean {
        return appUpdateInfo.updateAvailability() == UpdateAvailability.UPDATE_AVAILABLE &&
                appUpdateInfo.isFlexibleUpdateAllowed &&
                appUpdateInfo.clientVersionStalenessDays() ?: 0 >= DAYS_FOR_FLEXIBLE_UPDATE
    }
    
    private fun startImmediateUpdate(appUpdateInfo: AppUpdateInfo) {
        val activity = this.activity ?: return
        
        try {
            appUpdateManager.startUpdateFlowForResult(
                appUpdateInfo,
                activity,
                AppUpdateOptions.newBuilder(AppUpdateType.IMMEDIATE).build(),
                UPDATE_REQUEST_CODE
            )
        } catch (e: IntentSender.SendIntentException) {
            // Handle error
            // Timber.e(e, "Failed to start immediate update flow")
        }
    }
    
    private suspend fun startFlexibleUpdate(appUpdateInfo: AppUpdateInfo): Boolean = suspendCoroutine { continuation ->
        val activity = this.activity
        
        if (activity == null) {
            continuation.resume(false)
            return@suspendCoroutine
        }
        
        try {
            // Register listener for update state changes
            appUpdateManager.registerListener(installStateUpdatedListener)
            
            appUpdateManager.startUpdateFlowForResult(
                appUpdateInfo,
                activity,
                AppUpdateOptions.newBuilder(AppUpdateType.FLEXIBLE).build(),
                UPDATE_REQUEST_CODE
            )
            
            continuation.resume(true)
        } catch (e: IntentSender.SendIntentException) {
            // Timber.e(e, "Failed to start flexible update flow")
            continuation.resume(false)
        }
    }
    
    private fun showCompletionSnackbar(activity: Activity) {
        Snackbar.make(
            activity.findViewById(android.R.id.content),
            "An update has been downloaded.",
            Snackbar.LENGTH_INDEFINITE
        ).apply {
            setAction("INSTALL") {
                appUpdateManager.completeUpdate()
            }
            show()
        }
    }
    
    /**
     * Call this method from your activity's onActivityResult
     */
    fun onActivityResult(requestCode: Int, resultCode: Int) {
        if (requestCode == UPDATE_REQUEST_CODE) {
            if (resultCode != Activity.RESULT_OK) {
                // Update flow failed or was cancelled
                // Timber.d("Update flow failed or was cancelled: $resultCode")
            }
        }
    }
} 