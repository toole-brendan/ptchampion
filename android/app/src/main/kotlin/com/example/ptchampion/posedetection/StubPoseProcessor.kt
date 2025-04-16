package com.example.ptchampion.posedetection

import android.util.Log
import androidx.camera.core.ImageProxy

/**
 * Stub implementation of PoseProcessor for compilation purposes
 * This implementation doesn't use any MediaPipe classes
 */
class StubPoseProcessor : PoseProcessor {
    private var initialized = false
    private var lensFacing = 0

    // Implement the abstract listener property
    override var listener: PoseProcessor.PoseProcessorListener? = null

    override fun initialize() {
        Log.d(TAG, "initialize() called - stub implementation")
        initialized = true
    }

    override fun isInitialized(): Boolean = initialized

    override fun processImageProxy(imageProxy: ImageProxy, rotationDegrees: Int) {
        Log.d(TAG, "processImageProxy() called - stub implementation")
        // Just close the image proxy without processing
        imageProxy.close()
    }

    override fun setLensFacing(lensFacing: Int) {
        this.lensFacing = lensFacing
        Log.d(TAG, "setLensFacing() called with: lensFacing = $lensFacing")
    }

    override fun close() {
        Log.d(TAG, "close() called")
        initialized = false
    }

    companion object {
        private const val TAG = "StubPoseProcessor"
    }
} 