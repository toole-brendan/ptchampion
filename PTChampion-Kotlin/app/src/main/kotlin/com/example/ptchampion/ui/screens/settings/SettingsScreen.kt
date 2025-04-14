package com.example.ptchampion.ui.screens.settings

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ArrowBack
import androidx.compose.material.icons.filled.ExitToApp
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import com.example.ptchampion.ui.components.StyledButton
import com.example.ptchampion.ui.theme.PtAccent
import com.example.ptchampion.ui.theme.PtBackground
import com.example.ptchampion.ui.theme.PtCommandBlack
import com.example.ptchampion.ui.theme.PtSecondaryText

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun SettingsScreen(
    onNavigateBack: () -> Unit,
    onNavigateToBluetooth: () -> Unit,
    onNavigateToAccount: () -> Unit,
    onLogout: () -> Unit
) {
    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("SETTINGS", color = PtCommandBlack) },
                navigationIcon = {
                    IconButton(onClick = onNavigateBack) {
                        Icon(Icons.Filled.ArrowBack, contentDescription = "Back", tint = PtAccent)
                    }
                },
                colors = TopAppBarDefaults.topAppBarColors(containerColor = PtBackground)
            )
        },
        containerColor = PtBackground
    ) { paddingValues ->
        Column(
            modifier = Modifier
                .padding(paddingValues)
                .fillMaxSize()
                .verticalScroll(rememberScrollState())
                .padding(20.dp)
        ) {
            // Preferences Section
            SectionTitle("Preferences")
            SettingsItem(icon = Icons.Default.Bluetooth, title = "Bluetooth Devices", onClick = onNavigateToBluetooth)
            SettingsItem(icon = Icons.Default.Straighten, title = "Units (Miles/Km, Lbs/Kg)", onClick = { /* TODO */ })
            SettingsItem(icon = Icons.Default.Notifications, title = "Notifications", onClick = { /* TODO */ })
            SettingsItem(icon = Icons.Default.Map, title = "Local Leaderboard Radius", onClick = { /* TODO */ })

            Spacer(modifier = Modifier.height(24.dp))

            // Account Section
            SectionTitle("Account")
            SettingsItem(icon = Icons.Default.AccountCircle, title = "Account Management", onClick = onNavigateToAccount)
            SettingsItem(icon = Icons.Filled.ExitToApp, title = "Logout", onClick = onLogout)

            Spacer(modifier = Modifier.height(24.dp))

            // About Section
            SectionTitle("About")
            SettingsItem(icon = Icons.Default.Info, title = "About PT Champion", onClick = { /* TODO */ })
            SettingsItem(icon = Icons.Default.Policy, title = "Privacy Policy", onClick = { /* TODO */ })
            SettingsItem(icon = Icons.Default.HelpOutline, title = "Help & Support", onClick = { /* TODO */ })

        }
    }
}

@Composable
fun SectionTitle(title: String) {
    Text(
        text = title.uppercase(),
        style = MaterialTheme.typography.titleMedium,
        color = PtSecondaryText,
        modifier = Modifier.padding(bottom = 8.dp)
    )
}

@Composable
fun SettingsItem(
    icon: ImageVector,
    title: String,
    onClick: () -> Unit
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .clickable(onClick = onClick)
            .padding(vertical = 12.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Icon(imageVector = icon, contentDescription = null, tint = PtAccent, modifier = Modifier.size(24.dp))
        Spacer(modifier = Modifier.width(16.dp))
        Text(text = title, style = MaterialTheme.typography.bodyLarge, color = PtCommandBlack)
        Spacer(modifier = Modifier.weight(1f))
        Icon(Icons.Default.KeyboardArrowRight, contentDescription = null, tint = PtSecondaryText)
    }
    Divider(color = PtSecondaryText.copy(alpha = 0.2f))
}

@Composable
fun SettingItemSwitch(
    title: String,
    checked: Boolean,
    onCheckedChange: (Boolean) -> Unit,
    modifier: Modifier = Modifier
) {
    Row(
        modifier = modifier
            .fillMaxWidth()
            .padding(vertical = 16.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Text(
            title,
            modifier = Modifier.weight(1f),
            style = MaterialTheme.typography.bodyLarge
        )
        Switch(
            checked = checked,
            onCheckedChange = onCheckedChange,
            colors = SwitchDefaults.colors(
                checkedThumbColor = PtAccent,
                checkedTrackColor = PtAccent.copy(alpha = 0.5f),
                uncheckedThumbColor = PtSecondaryText,
                uncheckedTrackColor = PtSecondaryText.copy(alpha = 0.5f)
            )
        )
    }
}

@Composable
fun SettingItemNavigable(
    title: String,
    onClick: () -> Unit,
    modifier: Modifier = Modifier
) {
    Row(
        modifier = modifier
            .fillMaxWidth()
            .clickable(onClick = onClick)
            .padding(vertical = 20.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Text(
            title,
            modifier = Modifier.weight(1f),
            style = MaterialTheme.typography.bodyLarge
        )
        // Optional: Add a chevron icon here if desired
        // Icon(Icons.AutoMirrored.Filled.KeyboardArrowRight, contentDescription = null, tint = PtSecondaryText)
    }
} 