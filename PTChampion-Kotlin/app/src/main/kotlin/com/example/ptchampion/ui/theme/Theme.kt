package com.example.ptchampion.ui.theme

import android.app.Activity
// import android.os.Build // No longer needed for dynamic color check
// import androidx.compose.foundation.isSystemInDarkTheme // No longer forcing based on system
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.lightColorScheme
// import androidx.compose.material3.darkColorScheme // Removed
// import androidx.compose.material3.dynamicDarkColorScheme // Removed
// import androidx.compose.material3.dynamicLightColorScheme // Removed
import androidx.compose.runtime.Composable
import androidx.compose.runtime.SideEffect
// import androidx.compose.ui.graphics.Color // No longer directly used here
import androidx.compose.ui.graphics.toArgb
import androidx.compose.ui.platform.LocalContext // No longer needed for dynamic color
import androidx.compose.ui.platform.LocalView
import androidx.core.view.WindowCompat

// Define the Light Color Scheme using the M3 names from Color.kt
private val LightColorScheme = lightColorScheme(
    primary = primaryLight,
    onPrimary = onPrimaryLight,
    primaryContainer = primaryContainerLight,
    onPrimaryContainer = onPrimaryContainerLight,
    secondary = secondaryLight,
    onSecondary = onSecondaryLight,
    secondaryContainer = secondaryContainerLight,
    onSecondaryContainer = onSecondaryContainerLight,
    tertiary = tertiaryLight,
    onTertiary = onTertiaryLight,
    tertiaryContainer = tertiaryContainerLight,
    onTertiaryContainer = onTertiaryContainerLight,
    error = errorLight,
    onError = onErrorLight,
    errorContainer = errorContainerLight,
    onErrorContainer = onErrorContainerLight,
    background = backgroundLight,
    onBackground = onBackgroundLight,
    surface = surfaceLight,
    onSurface = onSurfaceLight,
    surfaceVariant = surfaceVariantLight, // For dark cards
    onSurfaceVariant = onSurfaceVariantLight, // Text on dark cards
    outline = outlineLight,
    outlineVariant = outlineVariantLight,
    scrim = scrimLight, // For modal overlay
)

// Remove the Dark Color Scheme definition
/*
private val DarkColorScheme = darkColorScheme(
    primary = Primary,
    onPrimary = OnPrimary,
    // ... rest of dark scheme ...
)
*/

// Remove unused old scheme definition
/*
private val IndustrialDarkColorScheme = darkColorScheme(...)
*/

// Remove unused LightColorScheme placeholder comment
// private val LightColorScheme = lightColorScheme(...)

@Composable
fun PTChampionTheme(
    // darkTheme: Boolean = false, // Force light theme based on guide
    // dynamicColor: Boolean = false, // Disable dynamic color
    content: @Composable () -> Unit
) {
    // Force light scheme using our defined colors
    val colorScheme = LightColorScheme

    // Remove dynamic color logic
    /*
    val colorScheme = when { ... }
    */
    val view = LocalView.current
    if (!view.isInEditMode) {
        SideEffect {
            val window = (view.context as Activity).window
            // Set status bar color to match the app's light background
            window.statusBarColor = colorScheme.background.toArgb()
            // Ensure status bar icons are dark (since background is light)
            WindowCompat.getInsetsController(window, view).isAppearanceLightStatusBars = true // Set to true for light background
        }
    }

    MaterialTheme(
        colorScheme = colorScheme,
        typography = AppTypography, // Use our custom typography
        shapes = Shapes, // Keep existing shapes for now (can be updated later if needed)
        content = content
    )
} 