package com.example.ptchampion.ui.screens.camera;

import android.Manifest;
import android.content.Context;
import android.util.Log;
import androidx.camera.core.CameraSelector;
import androidx.camera.core.Preview;
import androidx.camera.lifecycle.ProcessCameraProvider;
import androidx.camera.view.PreviewView;
import androidx.compose.foundation.layout.*;
import androidx.compose.runtime.*;
import androidx.compose.ui.Alignment;
import androidx.compose.ui.Modifier;
import androidx.core.content.ContextCompat;
import androidx.lifecycle.LifecycleOwner;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import androidx.compose.foundation.layout.Arrangement;
import androidx.compose.material.icons.Icons;
import androidx.compose.material3.ButtonDefaults;
import com.example.ptchampion.ui.screens.camera.SessionState;
import com.example.ptchampion.ui.screens.camera.CameraNavigationEvent;
import androidx.compose.material3.SnackbarHostState;
import androidx.compose.ui.graphics.vector.ImageVector;
import androidx.camera.core.ImageProxy;
import androidx.camera.core.ImageAnalysis;

@kotlin.Metadata(mv = {1, 9, 0}, k = 2, xi = 48, d1 = {"\u0000D\n\u0000\n\u0002\u0010\u0002\n\u0000\n\u0002\u0018\u0002\n\u0000\n\u0002\u0018\u0002\n\u0000\n\u0002\u0018\u0002\n\u0000\n\u0002\u0018\u0002\n\u0000\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0002\b\u0002\n\u0002\u0010\b\n\u0000\n\u0002\u0010\u000e\n\u0000\n\u0002\u0018\u0002\n\u0000\n\u0002\u0018\u0002\n\u0000\u001a>\u0010\u0000\u001a\u00020\u00012\u0006\u0010\u0002\u001a\u00020\u00032\u0006\u0010\u0004\u001a\u00020\u00052\u0006\u0010\u0006\u001a\u00020\u00072\b\b\u0002\u0010\b\u001a\u00020\t2\u0012\u0010\n\u001a\u000e\u0012\u0004\u0012\u00020\f\u0012\u0004\u0012\u00020\u00010\u000bH\u0007\u001a4\u0010\r\u001a\u00020\u00012\u0006\u0010\u000e\u001a\u00020\u000f2\b\u0010\u0010\u001a\u0004\u0018\u00010\u00112\b\b\u0002\u0010\u0012\u001a\u00020\u00132\u000e\b\u0002\u0010\u0014\u001a\b\u0012\u0004\u0012\u00020\u00010\u0015H\u0007\u00a8\u0006\u0016"}, d2 = {"CameraPreview", "", "context", "Landroid/content/Context;", "lifecycleOwner", "Landroidx/lifecycle/LifecycleOwner;", "cameraExecutor", "Ljava/util/concurrent/ExecutorService;", "modifier", "Landroidx/compose/ui/Modifier;", "onFrameAnalyzed", "Lkotlin/Function1;", "Landroidx/camera/core/ImageProxy;", "CameraScreen", "exerciseId", "", "exerciseType", "", "viewModel", "Lcom/example/ptchampion/ui/screens/camera/CameraViewModel;", "onWorkoutComplete", "Lkotlin/Function0;", "app_release"})
public final class CameraScreenKt {
    
    @androidx.compose.runtime.Composable
    public static final void CameraScreen(int exerciseId, @org.jetbrains.annotations.Nullable
    java.lang.String exerciseType, @org.jetbrains.annotations.NotNull
    com.example.ptchampion.ui.screens.camera.CameraViewModel viewModel, @org.jetbrains.annotations.NotNull
    kotlin.jvm.functions.Function0<kotlin.Unit> onWorkoutComplete) {
    }
    
    @androidx.compose.runtime.Composable
    public static final void CameraPreview(@org.jetbrains.annotations.NotNull
    android.content.Context context, @org.jetbrains.annotations.NotNull
    androidx.lifecycle.LifecycleOwner lifecycleOwner, @org.jetbrains.annotations.NotNull
    java.util.concurrent.ExecutorService cameraExecutor, @org.jetbrains.annotations.NotNull
    androidx.compose.ui.Modifier modifier, @org.jetbrains.annotations.NotNull
    kotlin.jvm.functions.Function1<? super androidx.camera.core.ImageProxy, kotlin.Unit> onFrameAnalyzed) {
    }
}