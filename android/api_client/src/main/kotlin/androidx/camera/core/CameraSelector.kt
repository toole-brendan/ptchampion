package androidx.camera.core

/**
 * Stub implementation of CameraSelector for compilation purposes
 */
class CameraSelector private constructor() {
    companion object {
        const val LENS_FACING_BACK = 0
        const val LENS_FACING_FRONT = 1
        
        fun Builder(): Builder = Builder()
    }
    
    class Builder {
        fun requireLensFacing(lensFacing: Int): Builder = this
        fun build(): CameraSelector = CameraSelector()
    }
} 