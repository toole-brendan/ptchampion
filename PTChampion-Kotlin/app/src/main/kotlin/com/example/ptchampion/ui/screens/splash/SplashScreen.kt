package com.example.ptchampion.ui.screens.splash

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.lifecycle.viewmodel.compose.viewModel
import androidx.navigation.NavController
import com.example.ptchampion.ui.navigation.Screen

@Composable
fun SplashScreen(
    navController: NavController,
    viewModel: SplashViewModel = viewModel()
) {
    val destination by viewModel.destination.collectAsState()

    LaunchedEffect(destination) {
        when (destination) {
            SplashDestination.Login -> {
                navController.navigate(Screen.Login.route) {
                    popUpTo(Screen.Splash.route) { inclusive = true } // Remove splash from back stack
                }
            }
            SplashDestination.Home -> {
                navController.navigate(Screen.Home.route) {
                    popUpTo(Screen.Splash.route) { inclusive = true }
                }
            }
            SplashDestination.Undetermined -> { /* Wait */ }
        }
    }

    // Simple loading indicator for the splash screen
    Box(modifier = Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
        CircularProgressIndicator()
    }
} 