package com.example.ptchampion.ui.theme

import android.app.Activity
import android.os.Build
import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.darkColorScheme
import androidx.compose.material3.dynamicDarkColorScheme
import androidx.compose.material3.dynamicLightColorScheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.runtime.SideEffect
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.toArgb
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalView
import androidx.core.view.WindowCompat

private val IndustrialDarkColorScheme = darkColorScheme(
    primary = GreyLight,
    onPrimary = GreyVeryLight,
    secondary = GreyLight,
    onSecondary = GreyVeryLight,
    tertiary = GreyLight,
    onTertiary = GreyVeryLight,
    background = GreyDark,
    onBackground = GreyVeryLight,
    surface = GreyMedium,
    onSurface = GreyVeryLight
)

// Remove unused LightColorScheme
// private val LightColorScheme = lightColorScheme(...)

@Composable
fun PTChampionTheme(
    // darkTheme: Boolean = isSystemInDarkTheme(), // Force dark theme
    // Dynamic color is available on Android 12+ - Disabled for industrial look
    // dynamicColor: Boolean = true,
    content: @Composable () -> Unit
) {
    // Force dark scheme
    val colorScheme = IndustrialDarkColorScheme

    // Remove dynamic color logic
    /*
    val colorScheme = when {
        dynamicColor && Build.VERSION.SDK_INT >= Build.VERSION_CODES.S -> {
            val context = LocalContext.current
            if (darkTheme) dynamicDarkColorScheme(context) else dynamicLightColorScheme(context)
        }

        darkTheme -> DarkColorScheme
        else -> LightColorScheme
    }
    */
    val view = LocalView.current
    if (!view.isInEditMode) {
        SideEffect {
            val window = (view.context as Activity).window
            window.statusBarColor = colorScheme.background.toArgb() // Use background for status bar
            // Always use dark status bar icons as our background is dark
            WindowCompat.getInsetsController(window, view).isAppearanceLightStatusBars = false
        }
    }

    MaterialTheme(
        colorScheme = colorScheme,
        typography = Typography,
        shapes = Shapes,
        content = content
    )
} 