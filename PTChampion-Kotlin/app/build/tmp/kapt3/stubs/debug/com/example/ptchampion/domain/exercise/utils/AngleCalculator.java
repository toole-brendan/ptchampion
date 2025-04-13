package com.example.ptchampion.domain.exercise.utils;

/**
 * Utility object for calculating angles between pose landmarks.
 */
@kotlin.Metadata(mv = {1, 9, 0}, k = 1, xi = 48, d1 = {"\u0000(\n\u0002\u0018\u0002\n\u0002\u0010\u0000\n\u0002\b\u0002\n\u0002\u0010\u0007\n\u0002\b\u0002\n\u0002\u0018\u0002\n\u0002\b\u0007\n\u0002\u0010\u000b\n\u0002\u0010\u0006\n\u0002\b\u0003\b\u00c6\u0002\u0018\u00002\u00020\u0001B\u0007\b\u0002\u00a2\u0006\u0002\u0010\u0002J\u001e\u0010\u0005\u001a\u00020\u00042\u0006\u0010\u0006\u001a\u00020\u00072\u0006\u0010\b\u001a\u00020\u00072\u0006\u0010\t\u001a\u00020\u0007J\u0016\u0010\n\u001a\u00020\u00042\u0006\u0010\u000b\u001a\u00020\u00072\u0006\u0010\f\u001a\u00020\u0007J\u0016\u0010\r\u001a\u00020\u00042\u0006\u0010\u000b\u001a\u00020\u00072\u0006\u0010\f\u001a\u00020\u0007J\u001c\u0010\u000e\u001a\u00020\u000f*\u00020\u00102\u0006\u0010\u0011\u001a\u00020\u00042\b\b\u0002\u0010\u0012\u001a\u00020\u0010R\u000e\u0010\u0003\u001a\u00020\u0004X\u0082T\u00a2\u0006\u0002\n\u0000\u00a8\u0006\u0013"}, d2 = {"Lcom/example/ptchampion/domain/exercise/utils/AngleCalculator;", "", "()V", "REQUIRED_VISIBILITY", "", "calculateAngle", "first", "Lcom/example/ptchampion/domain/exercise/utils/MockNormalizedLandmark;", "middle", "last", "calculateHorizontalAlignment", "p1", "p2", "calculateVerticalAlignment", "isCloseTo", "", "", "other", "tolerance", "app_debug"})
public final class AngleCalculator {
    private static final float REQUIRED_VISIBILITY = 0.5F;
    @org.jetbrains.annotations.NotNull
    public static final com.example.ptchampion.domain.exercise.utils.AngleCalculator INSTANCE = null;
    
    private AngleCalculator() {
        super();
    }
    
    /**
     * Calculates the angle between three landmarks in 3D space.
     *
     * @param first The first landmark (e.g., shoulder).
     * @param middle The middle landmark (e.g., elbow).
     * @param last The last landmark (e.g., wrist).
     * @return The angle in degrees (0-180).
     */
    public final float calculateAngle(@org.jetbrains.annotations.NotNull
    com.example.ptchampion.domain.exercise.utils.MockNormalizedLandmark first, @org.jetbrains.annotations.NotNull
    com.example.ptchampion.domain.exercise.utils.MockNormalizedLandmark middle, @org.jetbrains.annotations.NotNull
    com.example.ptchampion.domain.exercise.utils.MockNormalizedLandmark last) {
        return 0.0F;
    }
    
    /**
     * Calculates the vertical alignment difference between two points.
     * Positive value means p1 is below p2.
     */
    public final float calculateVerticalAlignment(@org.jetbrains.annotations.NotNull
    com.example.ptchampion.domain.exercise.utils.MockNormalizedLandmark p1, @org.jetbrains.annotations.NotNull
    com.example.ptchampion.domain.exercise.utils.MockNormalizedLandmark p2) {
        return 0.0F;
    }
    
    /**
     * Calculates the horizontal alignment difference between two points.
     * Positive value means p1 is to the right of p2.
     */
    public final float calculateHorizontalAlignment(@org.jetbrains.annotations.NotNull
    com.example.ptchampion.domain.exercise.utils.MockNormalizedLandmark p1, @org.jetbrains.annotations.NotNull
    com.example.ptchampion.domain.exercise.utils.MockNormalizedLandmark p2) {
        return 0.0F;
    }
    
    public final boolean isCloseTo(double $this$isCloseTo, float other, double tolerance) {
        return false;
    }
}