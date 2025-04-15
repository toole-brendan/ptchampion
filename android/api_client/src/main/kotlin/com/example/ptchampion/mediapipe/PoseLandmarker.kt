package com.google.mediapipe.tasks.vision.poselandmarker

import android.content.Context
import android.graphics.Bitmap

/**
 * Stub implementation of PoseLandmarker for compilation purposes
 * Replace this with actual implementation when the MediaPipe library is available
 */
class PoseLandmarker private constructor() {
    
    fun detectForVideo(bitmap: Bitmap, timestampMs: Long): PoseLandmarkerResult {
        return PoseLandmarkerResult()
    }
    
    fun detect(bitmap: Bitmap): PoseLandmarkerResult {
        return PoseLandmarkerResult()
    }
    
    fun close() {
        // Stub implementation
    }
    
    class Builder {
        fun setBaseOptions(baseOptions: BaseOptions): Builder = this
        fun setRunningMode(runningMode: RunningMode): Builder = this
        fun setNumPoses(numPoses: Int): Builder = this
        fun setMinPoseDetectionConfidence(confidence: Float): Builder = this
        fun setMinPosePresenceConfidence(confidence: Float): Builder = this
        fun setMinTrackingConfidence(confidence: Float): Builder = this
        fun setResultListener(listener: Any): Builder = this
        fun setErrorListener(listener: Any): Builder = this
        
        fun build(context: Context): PoseLandmarker {
            return PoseLandmarker()
        }
    }
    
    companion object {
        fun createFromOptions(context: Context, options: Any): PoseLandmarker {
            return PoseLandmarker()
        }
        
        fun createFromFile(context: Context, modelPath: String): PoseLandmarker {
            return PoseLandmarker()
        }
        
        fun createFromFileAndOptions(context: Context, modelPath: String, options: Any): PoseLandmarker {
            return PoseLandmarker()
        }
    }
} 