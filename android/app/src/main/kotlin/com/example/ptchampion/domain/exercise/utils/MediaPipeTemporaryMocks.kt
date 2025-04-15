package com.example.ptchampion.domain.exercise.utils

/**
 * TEMPORARY MOCK CLASSES
 * These classes are temporary placeholders for MediaPipe classes to allow compilation.
 * They should be replaced with proper implementations when the MediaPipe dependencies are 
 * properly configured.
 */

/**
 * Mock class representing the PoseLandmark enum from MediaPipe.
 */
object PoseLandmark {
    const val NOSE = 0
    const val LEFT_EYE_INNER = 1
    const val LEFT_EYE = 2
    const val LEFT_EYE_OUTER = 3
    const val RIGHT_EYE_INNER = 4
    const val RIGHT_EYE = 5
    const val RIGHT_EYE_OUTER = 6
    const val LEFT_EAR = 7
    const val RIGHT_EAR = 8
    const val MOUTH_LEFT = 9
    const val MOUTH_RIGHT = 10
    const val LEFT_SHOULDER = 11
    const val RIGHT_SHOULDER = 12
    const val LEFT_ELBOW = 13
    const val RIGHT_ELBOW = 14
    const val LEFT_WRIST = 15
    const val RIGHT_WRIST = 16
    const val LEFT_PINKY = 17
    const val RIGHT_PINKY = 18
    const val LEFT_INDEX = 19
    const val RIGHT_INDEX = 20
    const val LEFT_THUMB = 21
    const val RIGHT_THUMB = 22
    const val LEFT_HIP = 23
    const val RIGHT_HIP = 24
    const val LEFT_KNEE = 25
    const val RIGHT_KNEE = 26
    const val LEFT_ANKLE = 27
    const val RIGHT_ANKLE = 28
    const val LEFT_HEEL = 29
    const val RIGHT_HEEL = 30
    const val LEFT_FOOT_INDEX = 31
    const val RIGHT_FOOT_INDEX = 32
}

/**
 * Mock class representing a NormalizedLandmark from MediaPipe.
 */
class MockNormalizedLandmark(
    val x: Float = 0f,
    val y: Float = 0f,
    val z: Float = 0f,
    val visibility: Float = 0f
)

/**
 * Extension properties to provide access to mock landmarks for pose landmark results.
 */
val Any.landmarks: List<MockNormalizedLandmark>
    get() = List(33) { MockNormalizedLandmark() }

val Any.worldLandmarks: List<MockNormalizedLandmark>
    get() = List(33) { MockNormalizedLandmark() }

val MockNormalizedLandmark.visibility: Float
    get() = this.visibility 