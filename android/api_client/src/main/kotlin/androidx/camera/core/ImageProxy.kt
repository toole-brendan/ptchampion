package androidx.camera.core

/**
 * Stub implementation of ImageProxy for compilation purposes
 */
class ImageProxy {
    val width: Int = 0
    val height: Int = 0
    val imageInfo: ImageInfo = ImageInfo()
    
    fun close() {}
    
    class ImageInfo {
        val rotationDegrees: Int = 0
    }
} 