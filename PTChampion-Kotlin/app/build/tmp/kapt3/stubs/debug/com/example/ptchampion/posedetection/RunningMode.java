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

@kotlin.Metadata(mv = {1, 9, 0}, k = 1, xi = 48, d1 = {"\u0000\f\n\u0002\u0018\u0002\n\u0002\u0010\u0010\n\u0002\b\u0003\b\u0086\u0081\u0002\u0018\u00002\b\u0012\u0004\u0012\u00020\u00000\u0001B\u0007\b\u0002\u00a2\u0006\u0002\u0010\u0002j\u0002\b\u0003\u00a8\u0006\u0004"}, d2 = {"Lcom/example/ptchampion/posedetection/RunningMode;", "", "(Ljava/lang/String;I)V", "LIVE_STREAM", "app_debug"})
public enum RunningMode {
    /*public static final*/ LIVE_STREAM /* = new LIVE_STREAM() */;
    
    RunningMode() {
    }
    
    @org.jetbrains.annotations.NotNull
    public static kotlin.enums.EnumEntries<com.example.ptchampion.posedetection.RunningMode> getEntries() {
        return null;
    }
}