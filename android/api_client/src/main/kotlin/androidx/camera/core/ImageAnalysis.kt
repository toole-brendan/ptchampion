package androidx.camera.core

import java.util.concurrent.Executor

/**
 * Stub implementation of ImageAnalysis for compilation purposes
 */
class ImageAnalysis private constructor() {
    fun setAnalyzer(executor: Executor, analyzer: Analyzer) {}
    
    companion object {
        const val STRATEGY_KEEP_ONLY_LATEST = 0
        const val OUTPUT_IMAGE_FORMAT_RGBA_8888 = 0
        
        fun Builder(): Builder = Builder()
    }
    
    class Builder {
        fun setTargetResolution(size: android.util.Size): Builder = this
        fun setBackpressureStrategy(strategy: Int): Builder = this
        fun setOutputImageFormat(format: Int): Builder = this
        fun build(): ImageAnalysis = ImageAnalysis()
    }
    
    fun interface Analyzer {
        fun analyze(imageProxy: ImageProxy)
    }
} 