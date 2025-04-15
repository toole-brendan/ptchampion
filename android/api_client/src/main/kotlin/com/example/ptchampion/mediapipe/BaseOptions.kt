package com.google.mediapipe.tasks.vision.poselandmarker

/**
 * Stub implementation of BaseOptions class for compilation purposes
 * Replace this with actual implementation when the MediaPipe library is available
 */
class BaseOptions private constructor() {
    
    class Builder {
        fun setModelAssetPath(path: String): Builder = this
        fun setModelAssetBuffer(buffer: ByteArray): Builder = this
        fun setDelegate(delegate: Int): Builder = this
        fun build(): BaseOptions = BaseOptions()
    }
    
    companion object {
        const val CPU = 0
        const val GPU = 1
    }
} 