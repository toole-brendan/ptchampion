package com.example.ptchampion.ui.navigation

import androidx.compose.ui.graphics.vector.ImageVector

/**
 * Represents an item in the bottom navigation bar.
 *
 * @param screen The navigation [Screen] this item corresponds to.
 * @param label The text label displayed for the item.
 * @param icon The [ImageVector] icon displayed for the item.
 */
data class BottomNavItem(
    val screen: Screen,
    val label: String,
    val icon: ImageVector
) 