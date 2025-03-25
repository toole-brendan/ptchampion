package com.ptchampion.ui.theme

import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Shapes
import androidx.compose.ui.unit.dp

/**
 * Shapes for the application
 */
val Shapes = Shapes(
    // Small components like buttons, chips
    small = RoundedCornerShape(4.dp),
    
    // Medium components like cards, dialogs
    medium = RoundedCornerShape(8.dp),
    
    // Large components like bottom sheets
    large = RoundedCornerShape(16.dp),
    
    // Extra large components
    extraLarge = RoundedCornerShape(24.dp)
)