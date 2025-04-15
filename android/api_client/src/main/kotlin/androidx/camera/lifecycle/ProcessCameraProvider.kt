package androidx.camera.lifecycle

import android.content.Context
import androidx.camera.core.CameraSelector
import androidx.camera.core.Preview
import androidx.camera.core.ImageAnalysis
import androidx.lifecycle.LifecycleOwner
import com.google.common.util.concurrent.ListenableFuture

/**
 * Stub implementation of ProcessCameraProvider for compilation purposes
 */
class ProcessCameraProvider {
    fun unbindAll() {}
    
    fun bindToLifecycle(
        lifecycleOwner: LifecycleOwner,
        cameraSelector: CameraSelector,
        vararg useCases: Any
    ): Any = Any()
    
    companion object {
        fun getInstance(context: Context): ListenableFuture<ProcessCameraProvider> {
            // This is a stub implementation that can't return an actual ListenableFuture
            // The real method would use a SettableFuture and set its value when ready
            return DummyListenableFuture(ProcessCameraProvider())
        }
    }
}

/**
 * Dummy implementation of ListenableFuture for compilation purposes
 */
class DummyListenableFuture<V>(private val value: V) : ListenableFuture<V> {
    override fun get(): V = value
    override fun get(timeout: Long, unit: java.util.concurrent.TimeUnit): V = value
    override fun cancel(mayInterruptIfRunning: Boolean): Boolean = false
    override fun isCancelled(): Boolean = false
    override fun isDone(): Boolean = true
    override fun addListener(listener: Runnable, executor: java.util.concurrent.Executor) {}
} 