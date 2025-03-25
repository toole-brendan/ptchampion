package com.ptchampion.ui.theme

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

// Primary color from original Swift app
private val primary = Color(0xFF4B39EF)
private val primaryVariant = Color(0xFF2E1EE3)
private val onPrimary = Color.White

// Other colors
private val secondary = Color(0xFF39EFAA)
private val secondaryVariant = Color(0xFF00CD68)
private val onSecondary = Color.Black

private val tertiary = Color(0xFFFF9500)
private val tertiaryVariant = Color(0xFFE68600)
private val onTertiary = Color.White

private val background = Color.White
private val onBackground = Color(0xFF1A1A1A)
private val surface = Color.White
private val onSurface = Color(0xFF1A1A1A)

private val error = Color(0xFFD32F2F)
private val onError = Color.White

// Dark theme colors
private val primaryDark = Color(0xFF6258FF)
private val primaryVariantDark = Color(0xFF4B39EF)
private val onPrimaryDark = Color.White

private val secondaryDark = Color(0xFF39EFAA)
private val secondaryVariantDark = Color(0xFF00CD68)
private val onSecondaryDark = Color.Black

private val tertiaryDark = Color(0xFFFFAB40)
private val tertiaryVariantDark = Color(0xFFFF9500)
private val onTertiaryDark = Color.Black

private val backgroundDark = Color(0xFF121212)
private val onBackgroundDark = Color.White
private val surfaceDark = Color(0xFF1E1E1E)
private val onSurfaceDark = Color.White

private val errorDark = Color(0xFFFF5252)
private val onErrorDark = Color.Black

private val LightColorScheme = lightColorScheme(
    primary = primary,
    onPrimary = onPrimary,
    primaryContainer = primaryVariant,
    onPrimaryContainer = onPrimary,
    
    secondary = secondary,
    onSecondary = onSecondary,
    secondaryContainer = secondaryVariant,
    onSecondaryContainer = onSecondary,
    
    tertiary = tertiary,
    onTertiary = onTertiary,
    tertiaryContainer = tertiaryVariant,
    onTertiaryContainer = onTertiary,
    
    background = background,
    onBackground = onBackground,
    surface = surface,
    onSurface = onSurface,
    
    error = error,
    onError = onError
)

private val DarkColorScheme = darkColorScheme(
    primary = primaryDark,
    onPrimary = onPrimaryDark,
    primaryContainer = primaryVariantDark,
    onPrimaryContainer = onPrimaryDark,
    
    secondary = secondaryDark,
    onSecondary = onSecondaryDark,
    secondaryContainer = secondaryVariantDark,
    onSecondaryContainer = onSecondaryDark,
    
    tertiary = tertiaryDark,
    onTertiary = onTertiaryDark,
    tertiaryContainer = tertiaryVariantDark,
    onTertiaryContainer = onTertiaryDark,
    
    background = backgroundDark,
    onBackground = onBackgroundDark,
    surface = surfaceDark,
    onSurface = onSurfaceDark,
    
    error = errorDark,
    onError = onErrorDark
)

@Composable
fun PTChampionTheme(
    darkTheme: Boolean = isSystemInDarkTheme(),
    // Dynamic color is available on Android 12+
    dynamicColor: Boolean = false,
    content: @Composable () -> Unit
) {
    val colorScheme = when {
        dynamicColor && Build.VERSION.SDK_INT >= Build.VERSION_CODES.S -> {
            val context = LocalContext.current
            if (darkTheme) dynamicDarkColorScheme(context) else dynamicLightColorScheme(context)
        }
        darkTheme -> DarkColorScheme
        else -> LightColorScheme
    }
    
    val view = LocalView.current
    if (!view.isInEditMode) {
        SideEffect {
            val window = (view.context as Activity).window
            window.statusBarColor = colorScheme.primary.toArgb()
            WindowCompat.getInsetsController(window, view).isAppearanceLightStatusBars = !darkTheme
        }
    }

    MaterialTheme(
        colorScheme = colorScheme,
        typography = Typography,
        shapes = Shapes,
        content = content
    )
}