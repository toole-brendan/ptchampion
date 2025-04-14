package com.example.ptchampion.ui.screens.settings

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.Button
import androidx.compose.material3.Divider
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Switch
import androidx.compose.material3.SwitchDefaults
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import com.example.ptchampion.ui.components.StyledButton
import com.example.ptchampion.ui.theme.PtAccent
import com.example.ptchampion.ui.theme.PtBackground
import com.example.ptchampion.ui.theme.PtCommandBlack
import com.example.ptchampion.ui.theme.PtSecondaryText

@Composable
fun SettingsScreen(
    viewModel: SettingsViewModel = hiltViewModel(),
    onNavigateToBluetooth: () -> Unit,
    onLogout: () -> Unit
) {
    val uiState by viewModel.uiState.collectAsState()

    Scaffold(
        containerColor = MaterialTheme.colorScheme.background
    ) {
        paddingValues ->
        Column(modifier = Modifier.padding(paddingValues).padding(16.dp)) {
            Text("SETTINGS", style = MaterialTheme.typography.headlineMedium)
            Spacer(modifier = Modifier.height(24.dp))

            // Unit Preference Setting
            SettingItemSwitch(
                title = "Use Miles for Distance",
                checked = uiState.useMiles,
                onCheckedChange = { viewModel.setUseMiles(it) }
            )

            Divider(color = MaterialTheme.colorScheme.outlineVariant, thickness = 1.dp)

            // Navigate to Bluetooth Management
            SettingItemNavigable(
                title = "Manage Bluetooth Devices",
                onClick = onNavigateToBluetooth
            )

            Divider(color = MaterialTheme.colorScheme.outlineVariant, thickness = 1.dp)

            // Placeholder for Privacy Policy
            SettingItemNavigable(
                title = "Privacy Policy",
                onClick = { /* TODO: Implement navigation or URL opening */ }
            )

            Divider(color = MaterialTheme.colorScheme.outlineVariant, thickness = 1.dp)

            // Error Display
            uiState.error?.let {
                Spacer(modifier = Modifier.height(16.dp))
                Text(
                    text = "Error: $it",
                    color = MaterialTheme.colorScheme.error,
                    style = MaterialTheme.typography.bodySmall
                )
                Spacer(modifier = Modifier.height(16.dp))
            }

            // Logout Button at the bottom
            Spacer(modifier = Modifier.weight(1f))
            StyledButton(
                onClick = {
                    viewModel.logout()
                    onLogout() // Trigger navigation after ViewModel action
                },
                modifier = Modifier.fillMaxWidth(),
                text = "Logout"
            )
            Spacer(modifier = Modifier.height(16.dp))
        }
    }
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