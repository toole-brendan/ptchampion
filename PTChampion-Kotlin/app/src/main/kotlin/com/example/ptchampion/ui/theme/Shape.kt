package com.example.ptchampion.ui.theme

import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Shapes
import androidx.compose.ui.unit.dp

// Define shapes based on the Styling Guide
val Shapes = Shapes(
    // Used for smaller components like buttons, chips
    small = RoundedCornerShape(8.dp), // As per Primary Button spec (8px radius)
    // Default shape for medium-sized components like Cards
    medium = RoundedCornerShape(12.dp), // As per Card spec (12px radius)
    // Default shape for larger components like Modals, Dialogs
    large = RoundedCornerShape(20.dp) // As per Modal spec (20px radius)
    // extraLarge can remain default or be set if needed
    // extraLarge = RoundedCornerShape(28.dp) // Example if needed
) 