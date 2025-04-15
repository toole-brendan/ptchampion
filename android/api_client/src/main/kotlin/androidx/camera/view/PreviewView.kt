package androidx.camera.view

import android.content.Context
import androidx.camera.core.Preview

/**
 * Stub implementation of PreviewView for compilation purposes
 */
class PreviewView(context: Context) {
    val surfaceProvider: Preview.SurfaceProvider = object : Preview.SurfaceProvider {
        override fun onSurfaceRequested(request: Preview.SurfaceRequest) {}
    }
} 