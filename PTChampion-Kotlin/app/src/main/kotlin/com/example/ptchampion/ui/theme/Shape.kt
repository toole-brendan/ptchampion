package com.example.ptchampion.ui.theme

import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Shapes
import androidx.compose.ui.unit.dp

// Define shapes based on the Styling Guide V2
val Shapes = Shapes(
    // Used for buttons - 8px radius per styling guide
    small = RoundedCornerShape(8.dp),
    // Used for cards - 12px radius per styling guide
    medium = RoundedCornerShape(12.dp),
    // Used for larger panels - 16px radius per styling guide
    large = RoundedCornerShape(16.dp)
) 