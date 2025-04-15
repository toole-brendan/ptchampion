package androidx.camera.core

import android.view.Surface

/**
 * Stub implementation of Preview for compilation purposes
 */
class Preview private constructor() {
    companion object {
        fun Builder(): Builder = Builder()
    }
    
    class Builder {
        fun build(): Preview = Preview()
    }
    
    fun setSurfaceProvider(provider: SurfaceProvider) {}
    
    interface SurfaceProvider {
        fun onSurfaceRequested(request: SurfaceRequest) {}
    }
    
    class SurfaceRequest(val resolution: Any) {
        fun provideSurface(surface: Surface, executor: java.util.concurrent.Executor, callback: (Result<Void>) -> Unit) {}
    }
} 