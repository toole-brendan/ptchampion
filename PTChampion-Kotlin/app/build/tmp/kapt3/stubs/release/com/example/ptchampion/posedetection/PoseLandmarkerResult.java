package com.example.ptchampion.posedetection;

import android.content.Context;
import android.graphics.Bitmap;
import android.graphics.Matrix;
import android.os.SystemClock;
import android.util.Log;
import androidx.annotation.VisibleForTesting;
import androidx.camera.core.ImageProxy;
import com.example.ptchampion.domain.exercise.utils.MockNormalizedLandmark;
import java.lang.IllegalStateException;

@kotlin.Metadata(mv = {1, 9, 0}, k = 1, xi = 48, d1 = {"\u0000\u0018\n\u0002\u0018\u0002\n\u0002\u0010\u0000\n\u0002\b\u0002\n\u0002\u0010 \n\u0002\u0018\u0002\n\u0002\b\u0005\u0018\u00002\u00020\u0001B\u0005\u00a2\u0006\u0002\u0010\u0002R\u0017\u0010\u0003\u001a\b\u0012\u0004\u0012\u00020\u00050\u0004\u00a2\u0006\b\n\u0000\u001a\u0004\b\u0006\u0010\u0007R\u0017\u0010\b\u001a\b\u0012\u0004\u0012\u00020\u00050\u0004\u00a2\u0006\b\n\u0000\u001a\u0004\b\t\u0010\u0007\u00a8\u0006\n"}, d2 = {"Lcom/example/ptchampion/posedetection/PoseLandmarkerResult;", "", "()V", "landmarks", "", "Lcom/example/ptchampion/domain/exercise/utils/MockNormalizedLandmark;", "getLandmarks", "()Ljava/util/List;", "worldLandmarks", "getWorldLandmarks", "app_release"})
public final class PoseLandmarkerResult {
    @org.jetbrains.annotations.NotNull
    private final java.util.List<com.example.ptchampion.domain.exercise.utils.MockNormalizedLandmark> landmarks = null;
    @org.jetbrains.annotations.NotNull
    private final java.util.List<com.example.ptchampion.domain.exercise.utils.MockNormalizedLandmark> worldLandmarks = null;
    
    public PoseLandmarkerResult() {
        super();
    }
    
    @org.jetbrains.annotations.NotNull
    public final java.util.List<com.example.ptchampion.domain.exercise.utils.MockNormalizedLandmark> getLandmarks() {
        return null;
    }
    
    @org.jetbrains.annotations.NotNull
    public final java.util.List<com.example.ptchampion.domain.exercise.utils.MockNormalizedLandmark> getWorldLandmarks() {
        return null;
    }
}