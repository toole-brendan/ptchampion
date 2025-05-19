package com.example.ptchampion.ui.components

import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import com.example.ptchampion.ui.theme.PtAccent // Brass Gold
import com.example.ptchampion.ui.theme.PtCommandBlack // Command Black
import com.example.ptchampion.ui.theme.InactiveIconColor // For disabled state, using existing InactiveIconColor as base

/**
 * A Button composable adhering to the PT Champion Styling Guide V2.
 * Uses Brass Gold background and Command Black text.
 * Text is Montserrat Bold, 14sp, UPPERCASE.
 */
@Composable
fun StyledButton(
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
    enabled: Boolean = true,
    contentPadding: PaddingValues = ButtonDefaults.ContentPadding, // Default M3 padding
    text: String
) {
    Button(
        onClick = onClick,
        modifier = modifier,
        enabled = enabled,
        shape = MaterialTheme.shapes.small, // 8dp radius from Shapes.kt
        colors = ButtonDefaults.buttonColors(
            containerColor = PtAccent, // Brass Gold background
            contentColor = PtCommandBlack, // Command Black text
            // Define disabled colors based on guide principles (muted versions)
            disabledContainerColor = PtAccent.copy(alpha = 0.6f), // Muted Brass Gold
            disabledContentColor = PtCommandBlack.copy(alpha = 0.6f) // Muted Command Black
        ),
        contentPadding = contentPadding
    ) {
        Text(
            text = text.uppercase(), // Ensure uppercase text
            style = MaterialTheme.typography.labelLarge // Uses Montserrat Bold 14sp
        )
    }
}
