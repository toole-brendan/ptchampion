package com.example.ptchampion.domain.exercise.utils

/**
 * TEMPORARY MOCK CLASSES
 * These classes are temporary placeholders for MediaPipe classes to allow compilation.
 * They should be replaced with proper implementations when the MediaPipe dependencies are 
 * properly configured.
 */

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