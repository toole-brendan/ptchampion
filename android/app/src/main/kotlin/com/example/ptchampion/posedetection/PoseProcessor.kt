package com.example.ptchampion.posedetection

import com.google.mediapipe.tasks.vision.poselandmarker.PoseLandmarkerResult

/**
 * Interface for processing pose detection results
 */
interface PoseProcessor {
    
    /**
     * Listener interface for pose detection events
     */
    interface PoseProcessorListener {
        /**
         * Called when a pose is detected
         * @param result The pose detection result
         * @param timestampMs The timestamp when the frame was captured
         */
        fun onPoseDetected(result: PoseLandmarkerResult, timestampMs: Long)
        
        /**
         * Called when an error occurs during pose detection
         * @param error The error message
         * @param errorCode The error code
         */
        fun onError(error: String, errorCode: Int)
    }

    /**
     * The current listener for pose detection events
     * Can be changed dynamically if needed
     */
    var listener: PoseProcessorListener?

    /**
     * Initialize the pose detector
     */
    fun initialize()

    /**
     * Check if the pose detector is initialized
     * @return True if initialized, false otherwise
     */
    fun isInitialized(): Boolean

    /**
     * Process an image frame for pose detection
     * @param imageProxy The camera frame to process
     * @param rotationDegrees The rotation of the image
     */
    fun processImageProxy(imageProxy: androidx.camera.core.ImageProxy, rotationDegrees: Int)

    /**
     * Set the lens facing direction
     * @param lensFacing Camera lens direction (front/back)
     */
    fun setLensFacing(lensFacing: Int)

    /**
     * Close the pose detector and release resources
     */
    fun close()
} 