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

@kotlin.Metadata(mv = {1, 9, 0}, k = 1, xi = 48, d1 = {"\u0000\\\n\u0002\u0018\u0002\n\u0002\u0010\u0000\n\u0000\n\u0002\u0010\u0007\n\u0002\b\u0003\n\u0002\u0010\b\n\u0000\n\u0002\u0018\u0002\n\u0000\n\u0002\u0018\u0002\n\u0000\n\u0002\u0018\u0002\n\u0002\b\u0016\n\u0002\u0010\u0002\n\u0002\b\u0002\n\u0002\u0018\u0002\n\u0000\n\u0002\u0010\t\n\u0002\b\u0002\n\u0002\u0018\u0002\n\u0000\n\u0002\u0010\u000b\n\u0002\b\u0002\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0002\b\u0006\u0018\u0000 52\u00020\u0001:\u0003567BK\u0012\b\b\u0002\u0010\u0002\u001a\u00020\u0003\u0012\b\b\u0002\u0010\u0004\u001a\u00020\u0003\u0012\b\b\u0002\u0010\u0005\u001a\u00020\u0003\u0012\b\b\u0002\u0010\u0006\u001a\u00020\u0007\u0012\b\b\u0002\u0010\b\u001a\u00020\t\u0012\u0006\u0010\n\u001a\u00020\u000b\u0012\n\b\u0002\u0010\f\u001a\u0004\u0018\u00010\r\u00a2\u0006\u0002\u0010\u000eJ\u0006\u0010#\u001a\u00020$J\u0018\u0010%\u001a\u00020$2\u0006\u0010&\u001a\u00020\'2\u0006\u0010(\u001a\u00020)H\u0007J\u0016\u0010*\u001a\u00020$2\u0006\u0010+\u001a\u00020,2\u0006\u0010-\u001a\u00020.J\u0014\u0010/\u001a\u00020$2\n\u00100\u001a\u000601j\u0002`2H\u0002J\b\u00103\u001a\u00020$H\u0002J\b\u00104\u001a\u00020$H\u0002R\u0011\u0010\n\u001a\u00020\u000b\u00a2\u0006\b\n\u0000\u001a\u0004\b\u000f\u0010\u0010R\u001a\u0010\u0006\u001a\u00020\u0007X\u0086\u000e\u00a2\u0006\u000e\n\u0000\u001a\u0004\b\u0011\u0010\u0012\"\u0004\b\u0013\u0010\u0014R\u001a\u0010\u0002\u001a\u00020\u0003X\u0086\u000e\u00a2\u0006\u000e\n\u0000\u001a\u0004\b\u0015\u0010\u0016\"\u0004\b\u0017\u0010\u0018R\u001a\u0010\u0005\u001a\u00020\u0003X\u0086\u000e\u00a2\u0006\u000e\n\u0000\u001a\u0004\b\u0019\u0010\u0016\"\u0004\b\u001a\u0010\u0018R\u001a\u0010\u0004\u001a\u00020\u0003X\u0086\u000e\u00a2\u0006\u000e\n\u0000\u001a\u0004\b\u001b\u0010\u0016\"\u0004\b\u001c\u0010\u0018R\u0013\u0010\f\u001a\u0004\u0018\u00010\r\u00a2\u0006\b\n\u0000\u001a\u0004\b\u001d\u0010\u001eR\u001a\u0010\b\u001a\u00020\tX\u0086\u000e\u00a2\u0006\u000e\n\u0000\u001a\u0004\b\u001f\u0010 \"\u0004\b!\u0010\"\u00a8\u00068"}, d2 = {"Lcom/example/ptchampion/posedetection/PoseLandmarkerHelper;", "", "minPoseDetectionConfidence", "", "minPoseTrackingConfidence", "minPosePresenceConfidence", "currentDelegate", "", "runningMode", "Lcom/example/ptchampion/posedetection/RunningMode;", "context", "Landroid/content/Context;", "poseLandmarkerHelperListener", "Lcom/example/ptchampion/posedetection/PoseLandmarkerHelper$LandmarkerListener;", "(FFFILcom/example/ptchampion/posedetection/RunningMode;Landroid/content/Context;Lcom/example/ptchampion/posedetection/PoseLandmarkerHelper$LandmarkerListener;)V", "getContext", "()Landroid/content/Context;", "getCurrentDelegate", "()I", "setCurrentDelegate", "(I)V", "getMinPoseDetectionConfidence", "()F", "setMinPoseDetectionConfidence", "(F)V", "getMinPosePresenceConfidence", "setMinPosePresenceConfidence", "getMinPoseTrackingConfidence", "setMinPoseTrackingConfidence", "getPoseLandmarkerHelperListener", "()Lcom/example/ptchampion/posedetection/PoseLandmarkerHelper$LandmarkerListener;", "getRunningMode", "()Lcom/example/ptchampion/posedetection/RunningMode;", "setRunningMode", "(Lcom/example/ptchampion/posedetection/RunningMode;)V", "clearPoseLandmarker", "", "detectAsync", "mpImage", "Lcom/example/ptchampion/posedetection/MPImage;", "frameTime", "", "detectLiveStream", "imageProxy", "Landroidx/camera/core/ImageProxy;", "isFrontCamera", "", "returnLivestreamError", "error", "Ljava/lang/RuntimeException;", "Lkotlin/RuntimeException;", "returnLivestreamResult", "setupPoseLandmarker", "Companion", "LandmarkerListener", "ResultBundle", "app_debug"})
public final class PoseLandmarkerHelper {
    private float minPoseDetectionConfidence;
    private float minPoseTrackingConfidence;
    private float minPosePresenceConfidence;
    private int currentDelegate;
    @org.jetbrains.annotations.NotNull
    private com.example.ptchampion.posedetection.RunningMode runningMode;
    @org.jetbrains.annotations.NotNull
    private final android.content.Context context = null;
    @org.jetbrains.annotations.Nullable
    private final com.example.ptchampion.posedetection.PoseLandmarkerHelper.LandmarkerListener poseLandmarkerHelperListener = null;
    @org.jetbrains.annotations.NotNull
    public static final java.lang.String TAG = "PoseLandmarkerHelper";
    public static final int DELEGATE_CPU = 0;
    public static final int DELEGATE_GPU = 1;
    public static final float DEFAULT_POSE_DETECTION_CONFIDENCE = 0.5F;
    public static final float DEFAULT_POSE_TRACKING_CONFIDENCE = 0.5F;
    public static final float DEFAULT_POSE_PRESENCE_CONFIDENCE = 0.5F;
    public static final int OTHER_ERROR = 0;
    public static final int ERROR_RUNTIME = 1;
    public static final int ERROR_INIT_FAILED = 2;
    public static final int ERROR_GPU_DELEGATE = 3;
    @org.jetbrains.annotations.NotNull
    public static final com.example.ptchampion.posedetection.PoseLandmarkerHelper.Companion Companion = null;
    
    public PoseLandmarkerHelper(float minPoseDetectionConfidence, float minPoseTrackingConfidence, float minPosePresenceConfidence, int currentDelegate, @org.jetbrains.annotations.NotNull
    com.example.ptchampion.posedetection.RunningMode runningMode, @org.jetbrains.annotations.NotNull
    android.content.Context context, @org.jetbrains.annotations.Nullable
    com.example.ptchampion.posedetection.PoseLandmarkerHelper.LandmarkerListener poseLandmarkerHelperListener) {
        super();
    }
    
    public final float getMinPoseDetectionConfidence() {
        return 0.0F;
    }
    
    public final void setMinPoseDetectionConfidence(float p0) {
    }
    
    public final float getMinPoseTrackingConfidence() {
        return 0.0F;
    }
    
    public final void setMinPoseTrackingConfidence(float p0) {
    }
    
    public final float getMinPosePresenceConfidence() {
        return 0.0F;
    }
    
    public final void setMinPosePresenceConfidence(float p0) {
    }
    
    public final int getCurrentDelegate() {
        return 0;
    }
    
    public final void setCurrentDelegate(int p0) {
    }
    
    @org.jetbrains.annotations.NotNull
    public final com.example.ptchampion.posedetection.RunningMode getRunningMode() {
        return null;
    }
    
    public final void setRunningMode(@org.jetbrains.annotations.NotNull
    com.example.ptchampion.posedetection.RunningMode p0) {
    }
    
    @org.jetbrains.annotations.NotNull
    public final android.content.Context getContext() {
        return null;
    }
    
    @org.jetbrains.annotations.Nullable
    public final com.example.ptchampion.posedetection.PoseLandmarkerHelper.LandmarkerListener getPoseLandmarkerHelperListener() {
        return null;
    }
    
    public final void clearPoseLandmarker() {
    }
    
    private final void setupPoseLandmarker() {
    }
    
    public final void detectLiveStream(@org.jetbrains.annotations.NotNull
    androidx.camera.core.ImageProxy imageProxy, boolean isFrontCamera) {
    }
    
    @androidx.annotation.VisibleForTesting
    public final void detectAsync(@org.jetbrains.annotations.NotNull
    com.example.ptchampion.posedetection.MPImage mpImage, long frameTime) {
    }
    
    private final void returnLivestreamResult() {
    }
    
    private final void returnLivestreamError(java.lang.RuntimeException error) {
    }
    
    @kotlin.Metadata(mv = {1, 9, 0}, k = 1, xi = 48, d1 = {"\u0000\"\n\u0002\u0018\u0002\n\u0002\u0010\u0000\n\u0002\b\u0002\n\u0002\u0010\u0007\n\u0002\b\u0003\n\u0002\u0010\b\n\u0002\b\u0006\n\u0002\u0010\u000e\n\u0000\b\u0086\u0003\u0018\u00002\u00020\u0001B\u0007\b\u0002\u00a2\u0006\u0002\u0010\u0002R\u000e\u0010\u0003\u001a\u00020\u0004X\u0086T\u00a2\u0006\u0002\n\u0000R\u000e\u0010\u0005\u001a\u00020\u0004X\u0086T\u00a2\u0006\u0002\n\u0000R\u000e\u0010\u0006\u001a\u00020\u0004X\u0086T\u00a2\u0006\u0002\n\u0000R\u000e\u0010\u0007\u001a\u00020\bX\u0086T\u00a2\u0006\u0002\n\u0000R\u000e\u0010\t\u001a\u00020\bX\u0086T\u00a2\u0006\u0002\n\u0000R\u000e\u0010\n\u001a\u00020\bX\u0086T\u00a2\u0006\u0002\n\u0000R\u000e\u0010\u000b\u001a\u00020\bX\u0086T\u00a2\u0006\u0002\n\u0000R\u000e\u0010\f\u001a\u00020\bX\u0086T\u00a2\u0006\u0002\n\u0000R\u000e\u0010\r\u001a\u00020\bX\u0086T\u00a2\u0006\u0002\n\u0000R\u000e\u0010\u000e\u001a\u00020\u000fX\u0086T\u00a2\u0006\u0002\n\u0000\u00a8\u0006\u0010"}, d2 = {"Lcom/example/ptchampion/posedetection/PoseLandmarkerHelper$Companion;", "", "()V", "DEFAULT_POSE_DETECTION_CONFIDENCE", "", "DEFAULT_POSE_PRESENCE_CONFIDENCE", "DEFAULT_POSE_TRACKING_CONFIDENCE", "DELEGATE_CPU", "", "DELEGATE_GPU", "ERROR_GPU_DELEGATE", "ERROR_INIT_FAILED", "ERROR_RUNTIME", "OTHER_ERROR", "TAG", "", "app_debug"})
    public static final class Companion {
        
        private Companion() {
            super();
        }
    }
    
    @kotlin.Metadata(mv = {1, 9, 0}, k = 1, xi = 48, d1 = {"\u0000$\n\u0002\u0018\u0002\n\u0002\u0010\u0000\n\u0000\n\u0002\u0010\u0002\n\u0000\n\u0002\u0010\u000e\n\u0000\n\u0002\u0010\b\n\u0002\b\u0002\n\u0002\u0018\u0002\n\u0000\bf\u0018\u00002\u00020\u0001J\u001a\u0010\u0002\u001a\u00020\u00032\u0006\u0010\u0004\u001a\u00020\u00052\b\b\u0002\u0010\u0006\u001a\u00020\u0007H&J\u0010\u0010\b\u001a\u00020\u00032\u0006\u0010\t\u001a\u00020\nH&\u00a8\u0006\u000b"}, d2 = {"Lcom/example/ptchampion/posedetection/PoseLandmarkerHelper$LandmarkerListener;", "", "onError", "", "error", "", "errorCode", "", "onResults", "resultBundle", "Lcom/example/ptchampion/posedetection/PoseLandmarkerHelper$ResultBundle;", "app_debug"})
    public static abstract interface LandmarkerListener {
        
        public abstract void onError(@org.jetbrains.annotations.NotNull
        java.lang.String error, int errorCode);
        
        public abstract void onResults(@org.jetbrains.annotations.NotNull
        com.example.ptchampion.posedetection.PoseLandmarkerHelper.ResultBundle resultBundle);
        
        @kotlin.Metadata(mv = {1, 9, 0}, k = 3, xi = 48)
        public static final class DefaultImpls {
        }
    }
    
    @kotlin.Metadata(mv = {1, 9, 0}, k = 1, xi = 48, d1 = {"\u0000,\n\u0002\u0018\u0002\n\u0002\u0010\u0000\n\u0000\n\u0002\u0018\u0002\n\u0000\n\u0002\u0010\t\n\u0000\n\u0002\u0010\b\n\u0002\b\u000f\n\u0002\u0010\u000b\n\u0002\b\u0003\n\u0002\u0010\u000e\n\u0000\b\u0086\b\u0018\u00002\u00020\u0001B%\u0012\u0006\u0010\u0002\u001a\u00020\u0003\u0012\u0006\u0010\u0004\u001a\u00020\u0005\u0012\u0006\u0010\u0006\u001a\u00020\u0007\u0012\u0006\u0010\b\u001a\u00020\u0007\u00a2\u0006\u0002\u0010\tJ\t\u0010\u0011\u001a\u00020\u0003H\u00c6\u0003J\t\u0010\u0012\u001a\u00020\u0005H\u00c6\u0003J\t\u0010\u0013\u001a\u00020\u0007H\u00c6\u0003J\t\u0010\u0014\u001a\u00020\u0007H\u00c6\u0003J1\u0010\u0015\u001a\u00020\u00002\b\b\u0002\u0010\u0002\u001a\u00020\u00032\b\b\u0002\u0010\u0004\u001a\u00020\u00052\b\b\u0002\u0010\u0006\u001a\u00020\u00072\b\b\u0002\u0010\b\u001a\u00020\u0007H\u00c6\u0001J\u0013\u0010\u0016\u001a\u00020\u00172\b\u0010\u0018\u001a\u0004\u0018\u00010\u0001H\u00d6\u0003J\t\u0010\u0019\u001a\u00020\u0007H\u00d6\u0001J\t\u0010\u001a\u001a\u00020\u001bH\u00d6\u0001R\u0011\u0010\u0004\u001a\u00020\u0005\u00a2\u0006\b\n\u0000\u001a\u0004\b\n\u0010\u000bR\u0011\u0010\u0006\u001a\u00020\u0007\u00a2\u0006\b\n\u0000\u001a\u0004\b\f\u0010\rR\u0011\u0010\b\u001a\u00020\u0007\u00a2\u0006\b\n\u0000\u001a\u0004\b\u000e\u0010\rR\u0011\u0010\u0002\u001a\u00020\u0003\u00a2\u0006\b\n\u0000\u001a\u0004\b\u000f\u0010\u0010\u00a8\u0006\u001c"}, d2 = {"Lcom/example/ptchampion/posedetection/PoseLandmarkerHelper$ResultBundle;", "", "results", "Lcom/example/ptchampion/posedetection/PoseLandmarkerResult;", "inferenceTime", "", "inputImageHeight", "", "inputImageWidth", "(Lcom/example/ptchampion/posedetection/PoseLandmarkerResult;JII)V", "getInferenceTime", "()J", "getInputImageHeight", "()I", "getInputImageWidth", "getResults", "()Lcom/example/ptchampion/posedetection/PoseLandmarkerResult;", "component1", "component2", "component3", "component4", "copy", "equals", "", "other", "hashCode", "toString", "", "app_debug"})
    public static final class ResultBundle {
        @org.jetbrains.annotations.NotNull
        private final com.example.ptchampion.posedetection.PoseLandmarkerResult results = null;
        private final long inferenceTime = 0L;
        private final int inputImageHeight = 0;
        private final int inputImageWidth = 0;
        
        public ResultBundle(@org.jetbrains.annotations.NotNull
        com.example.ptchampion.posedetection.PoseLandmarkerResult results, long inferenceTime, int inputImageHeight, int inputImageWidth) {
            super();
        }
        
        @org.jetbrains.annotations.NotNull
        public final com.example.ptchampion.posedetection.PoseLandmarkerResult getResults() {
            return null;
        }
        
        public final long getInferenceTime() {
            return 0L;
        }
        
        public final int getInputImageHeight() {
            return 0;
        }
        
        public final int getInputImageWidth() {
            return 0;
        }
        
        @org.jetbrains.annotations.NotNull
        public final com.example.ptchampion.posedetection.PoseLandmarkerResult component1() {
            return null;
        }
        
        public final long component2() {
            return 0L;
        }
        
        public final int component3() {
            return 0;
        }
        
        public final int component4() {
            return 0;
        }
        
        @org.jetbrains.annotations.NotNull
        public final com.example.ptchampion.posedetection.PoseLandmarkerHelper.ResultBundle copy(@org.jetbrains.annotations.NotNull
        com.example.ptchampion.posedetection.PoseLandmarkerResult results, long inferenceTime, int inputImageHeight, int inputImageWidth) {
            return null;
        }
        
        @java.lang.Override
        public boolean equals(@org.jetbrains.annotations.Nullable
        java.lang.Object other) {
            return false;
        }
        
        @java.lang.Override
        public int hashCode() {
            return 0;
        }
        
        @java.lang.Override
        @org.jetbrains.annotations.NotNull
        public java.lang.String toString() {
            return null;
        }
    }
}