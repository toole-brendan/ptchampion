package com.example.ptchampion.ui.theme

import androidx.compose.material3.Typography
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.sp

// Temporarily use system fonts to avoid build errors
val BebasNeue = FontFamily.Default
val Montserrat = FontFamily.Default
val RobotoMono = FontFamily.Monospace

// Define custom text styles based on the styling guide V2
val AppTypography = Typography(
    // Headings: Bebas Neue, Bold, 24–32px, UPPERCASE
    headlineLarge = TextStyle(
        fontFamily = BebasNeue,
        fontWeight = FontWeight.Bold, // Map to the available weight
        fontSize = 32.sp,
        lineHeight = 40.sp,
        letterSpacing = 1.sp, // Slightly increase for Bebas Neue legibility
        color = PtCommandBlack // Ensure color comes from Color.kt
    ),
    headlineMedium = TextStyle(
        fontFamily = BebasNeue,
        fontWeight = FontWeight.Bold,
        fontSize = 28.sp,
        lineHeight = 36.sp,
        letterSpacing = 1.sp,
        color = PtCommandBlack
    ),
    headlineSmall = TextStyle(
        fontFamily = BebasNeue,
        fontWeight = FontWeight.Bold,
        fontSize = 24.sp,
        lineHeight = 32.sp,
        letterSpacing = 1.sp,
        color = PtCommandBlack
    ),

    // Subheadings: Montserrat, Semi-bold, 18–20px, Uppercase
    // Note: Material 3 `title` styles are not uppercase by default. Apply manually where needed.
    titleLarge = TextStyle(
        fontFamily = Montserrat,
        fontWeight = FontWeight.SemiBold,
        fontSize = 20.sp,
        lineHeight = 28.sp,
        letterSpacing = 0.1.sp,
        color = PtSecondaryText // Use Tactical Gray per guide
    ),
    titleMedium = TextStyle(
        fontFamily = Montserrat,
        fontWeight = FontWeight.SemiBold,
        fontSize = 18.sp,
        lineHeight = 24.sp,
        letterSpacing = 0.1.sp,
        color = PtSecondaryText // Use Tactical Gray per guide
    ),
    titleSmall = TextStyle( // Added for consistency, e.g., DetailRow label
        fontFamily = Montserrat,
        fontWeight = FontWeight.SemiBold, // Or Medium
        fontSize = 16.sp,
        lineHeight = 22.sp,
        letterSpacing = 0.1.sp,
        color = PtSecondaryText
    ),

    // Body Text: Montserrat, Regular
    bodyLarge = TextStyle(
        fontFamily = Montserrat,
        fontWeight = FontWeight.Normal,
        fontSize = 16.sp,
        lineHeight = 24.sp,
        letterSpacing = 0.5.sp,
        color = PtCommandBlack // Use Command Black per guide
    ),
    bodyMedium = TextStyle(
        fontFamily = Montserrat,
        fontWeight = FontWeight.Normal,
        fontSize = 14.sp,
        lineHeight = 20.sp,
        letterSpacing = 0.25.sp,
        color = PtCommandBlack
    ),
    // Labels: Montserrat (12-14px, Regular, Sentence case) -> Maps to bodySmall/labelSmall
    bodySmall = TextStyle( // Primary Label Style
        fontFamily = Montserrat,
        fontWeight = FontWeight.Normal, // Guide says Regular for Labels
        fontSize = 14.sp,
        lineHeight = 18.sp,
        letterSpacing = 0.4.sp,
        color = PtSecondaryText // Use Tactical Gray per guide
    ),

    // Small Labels (e.g., Bottom Nav): Montserrat, Medium (or Regular?), 10px, UPPERCASE
    // Note: Material 3 `labelSmall` is not uppercase by default. Apply manually.
    labelSmall = TextStyle(
        fontFamily = Montserrat,
        fontWeight = FontWeight.Medium, // Adjust if needed
        fontSize = 10.sp,
        lineHeight = 16.sp,
        letterSpacing = 0.5.sp,
        color = PtSecondaryText // Color defined where used (e.g., nav)
    ),

    // Buttons: Montserrat Bold, UPPERCASE, 14px
    // Note: Material 3 `labelLarge` is not uppercase by default. Apply manually.
    labelLarge = TextStyle( // Use for Buttons
        fontFamily = Montserrat,
        fontWeight = FontWeight.Bold,
        fontSize = 14.sp,
        lineHeight = 20.sp,
        letterSpacing = 1.sp // Slightly increase for uppercase bold
        // Color defined in Button style
    ),

    // Stats / Numbers: Roboto Mono, Medium, 20–28px
    displayMedium = TextStyle( // Larger stats
        fontFamily = RobotoMono,
        fontWeight = FontWeight.Medium,
        fontSize = 28.sp,
        lineHeight = 36.sp,
        letterSpacing = 0.sp,
        color = PtCommandBlack // Primary stat color
    ),
    displaySmall = TextStyle( // Smaller stats
        fontFamily = RobotoMono,
        fontWeight = FontWeight.Medium,
        fontSize = 20.sp,
        lineHeight = 28.sp,
        letterSpacing = 0.sp,
        color = PtCommandBlack // Primary stat color
    )
) 