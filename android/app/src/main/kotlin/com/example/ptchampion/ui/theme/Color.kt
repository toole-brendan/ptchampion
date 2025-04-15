package com.example.ptchampion.ui.theme

import androidx.compose.ui.graphics.Color

// PT Champion Styling Guide V2 Colors (Light Theme)
val PtBackground = Color(0xFFF4F1E6)      // Tactical Cream - Light Background
val PtPrimaryText = Color(0xFF1E241E)     // Deep Ops Green - Primary Dark Background
val PtSecondaryText = Color(0xFF4E5A48)   // Tactical Gray - Secondary Text
val PtAccent = Color(0xFFBFA24D)          // Brass Gold - Accent/Highlight
val PtArmyTan = Color(0xFFE0D4A6)         // Army Tan - Button/Text Highlight
val PtOliveMist = Color(0xFFC9CCA6)       // Olive Mist - Chart Fill
val PtCommandBlack = Color(0xFF1E1E1E)    // Command Black - Primary Text

// Material 3 Color Mapping for Light Theme
val primaryLight = PtAccent
val onPrimaryLight = PtCommandBlack
val primaryContainerLight = PtAccent
val onPrimaryContainerLight = PtCommandBlack

val secondaryLight = PtSecondaryText
val onSecondaryLight = PtBackground
val secondaryContainerLight = PtPrimaryText 
val onSecondaryContainerLight = PtBackground

val tertiaryLight = PtArmyTan
val onTertiaryLight = PtCommandBlack
val tertiaryContainerLight = PtArmyTan
val onTertiaryContainerLight = PtCommandBlack

val backgroundLight = PtBackground
val onBackgroundLight = PtCommandBlack

val surfaceLight = PtBackground 
val onSurfaceLight = PtCommandBlack

// Surface variant for cards
val surfaceVariantLight = PtBackground
val onSurfaceVariantLight = PtSecondaryText

val errorLight = Color(0xFFB00020)
val onErrorLight = Color.White
val errorContainerLight = Color(0xFFFCD8DB)
val onErrorContainerLight = Color(0xFFB00020)

val outlineLight = PtSecondaryText
val outlineVariantLight = PtSecondaryText

// Scrim for modals
val scrimLight = PtPrimaryText.copy(alpha = 0.9f)

// ---- Dark Theme Colors (not used in current design but kept for reference) ----

// Non-material specific colors (inactive icon etc)
val InactiveIconColor = Color(0xFFA3A390)  // For bottom nav inactive icons

// PT Champion Dark Theme Palette (Approximated from images)
val AppBackground = Color(0xFF1A1A1A)         // Primary Background
val AppGold = Color(0xFFB3A369)               // Primary Accent (Gold/Olive)
val AppBeige = Color(0xFFF5F5DC)               // Secondary Accent (Light Beige)
val AppTextPrimary = Color.White               // Primary Text
val AppTextSecondary = Color(0xFFA0A0A0)       // Secondary Text (Light Grey)
val AppButtonBackground = Color(0xFF333333)    // Button Background (Primary)
val AppButtonText = Color.White                // Button Text (Primary)
val AppLink = Color(0xFFB3A369)                // Link/Tertiary Text (Gold/Olive)

// M3 Compatibility Names (Mapping the conceptual colors to our defined palette)
// We'll use these in Theme.kt's colorScheme
val Primary = AppGold           // Main accent color
val OnPrimary = AppBackground   // Text/icons on Primary color
val PrimaryContainer = AppGold  // Containers using primary color (e.g., selected toggle)
val OnPrimaryContainer = AppBackground // Text/icons on PrimaryContainer

val Secondary = AppButtonBackground // Secondary elements like input fields, unselected toggles
val OnSecondary = AppTextPrimary    // Text/icons on Secondary color
val SecondaryContainer = AppButtonBackground // Containers using secondary color
val OnSecondaryContainer = AppTextPrimary // Text/icons on SecondaryContainer

val Tertiary = AppLink          // Accent color for links, less prominent highlights
val OnTertiary = AppBackground  // Text/icons on Tertiary color
val TertiaryContainer = AppButtonBackground // Containers using tertiary color
val OnTertiaryContainer = AppTextPrimary // Text/icons on TertiaryContainer

val Background = AppBackground      // Overall screen background
val OnBackground = AppTextPrimary   // Text/icons on Background

val Surface = AppButtonBackground  // Card backgrounds, surfaces slightly elevated
val OnSurface = AppTextPrimary     // Text/icons on Surface

val SurfaceVariant = Color.Gray // Replace GreyMedium with Color.Gray
val OnSurfaceVariant = AppTextSecondary // Text/icons on SurfaceVariant

val Error = Color(0xFFB00020)     // Standard error color
val OnError = Color.White         // Text/icons on Error color
val ErrorContainer = Color(0xFFFCD8DB) // Background for error messages/indicators
val OnErrorContainer = Color(0xFFB00020) // Text/icons on ErrorContainer

val Outline = AppTextSecondary    // Borders, dividers
val OutlineVariant = AppTextSecondary // Subtle outlines or dividers

val Scrim = Color.Black           // Scrim overlay color

// ---- Deprecated/Placeholder Names from Original Template (Remove or map if needed) ----
// These were likely defaults or placeholders. We've defined replacements above.
// val GreyDark = Color(0xFF121212)
// val GreyMedium = Color(0xFF1E1E1E)
// val GreyLight = Color(0xFF424242)
// val GreyVeryLight = Color(0xFFE0E0E0)
// val White = Color.White
// val Purple80 = GreyLight // Example: Map to 'Primary' if it served that purpose
// val PurpleGrey80 = GreyLight // Example: Map to 'Secondary' if it served that purpose
// val Pink80 = GreyLight // Example: Map to 'Tertiary' if it served that purpose

// Remove unused light colors
// val Purple40 = Color(0xFF6650a4)
// val PurpleGrey40 = Color(0xFF625b71)
// val Pink40 = Color(0xFF7D5260) 