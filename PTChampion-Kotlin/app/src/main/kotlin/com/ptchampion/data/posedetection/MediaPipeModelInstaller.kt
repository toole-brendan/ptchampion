package com.ptchampion.data.posedetection

import android.content.Context
import android.util.Log
import dagger.hilt.android.qualifiers.ApplicationContext
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import java.io.File
import java.io.FileOutputStream
import java.net.URL
import javax.inject.Inject
import javax.inject.Singleton

/**
 * Utility class to download and install the MediaPipe pose detection model
 */
@Singleton
class MediaPipeModelInstaller @Inject constructor(
    @ApplicationContext private val context: Context
) {
    companion object {
        private const val TAG = "MediaPipeModelInstaller"
        private const val MODEL_FILE = "pose_landmarker_full.task"
        private const val MODEL_URL = "https://storage.googleapis.com/mediapipe-models/pose_landmarker/pose_landmarker_full/float16/latest/pose_landmarker_full.task"
    }
    
    /**
     * Check if the model file exists in the app's files directory
     */
    fun isModelInstalled(): Boolean {
        val modelFile = File(context.filesDir, MODEL_FILE)
        return modelFile.exists() && modelFile.length() > 0
    }
    
    /**
     * Install the model from assets if available, otherwise download from URL
     * Returns true if the model was successfully installed
     */
    suspend fun installModel(): Boolean {
        return withContext(Dispatchers.IO) {
            try {
                val modelFile = File(context.filesDir, MODEL_FILE)
                
                // First, try to copy from assets if available
                if (copyFromAssets()) {
                    Log.d(TAG, "Model installed from assets")
                    return@withContext true
                }
                
                // If not available in assets, download from URL
                try {
                    val url = URL(MODEL_URL)
                    val connection = url.openConnection()
                    connection.connectTimeout = 15000
                    connection.readTimeout = 15000
                    
                    val inputStream = connection.getInputStream()
                    val outputStream = FileOutputStream(modelFile)
                    
                    val buffer = ByteArray(4096)
                    var byteCount: Int
                    var totalBytes = 0L
                    
                    while (inputStream.read(buffer).also { byteCount = it } != -1) {
                        outputStream.write(buffer, 0, byteCount)
                        totalBytes += byteCount
                    }
                    
                    outputStream.flush()
                    outputStream.close()
                    inputStream.close()
                    
                    Log.d(TAG, "Model downloaded from URL: $totalBytes bytes")
                    true
                } catch (e: Exception) {
                    Log.e(TAG, "Error downloading model", e)
                    false
                }
            } catch (e: Exception) {
                Log.e(TAG, "Error installing model", e)
                false
            }
        }
    }
    
    /**
     * Copy model from assets to files directory
     * Returns true if the model was successfully copied from assets
     */
    private fun copyFromAssets(): Boolean {
        try {
            val modelFile = File(context.filesDir, MODEL_FILE)
            
            // List assets and check if model file exists
            val assetsList = context.assets.list("") ?: emptyArray()
            if (!assetsList.contains(MODEL_FILE)) {
                return false
            }
            
            val inputStream = context.assets.open(MODEL_FILE)
            val outputStream = FileOutputStream(modelFile)
            
            val buffer = ByteArray(4096)
            var byteCount: Int
            
            while (inputStream.read(buffer).also { byteCount = it } != -1) {
                outputStream.write(buffer, 0, byteCount)
            }
            
            outputStream.flush()
            outputStream.close()
            inputStream.close()
            
            return true
        } catch (e: Exception) {
            Log.e(TAG, "Error copying model from assets", e)
            return false
        }
    }
}
