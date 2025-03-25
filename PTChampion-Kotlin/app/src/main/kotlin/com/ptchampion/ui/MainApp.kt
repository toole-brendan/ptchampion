package com.ptchampion.ui

import androidx.compose.foundation.layout.padding
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.AccountCircle
import androidx.compose.material.icons.filled.History
import androidx.compose.material.icons.filled.Home
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.NavigationBar
import androidx.compose.material3.NavigationBarItem
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.navigation.NavHostController
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.currentBackStackEntryAsState
import androidx.navigation.compose.rememberNavController
import com.ptchampion.ui.auth.AuthScreen
import com.ptchampion.ui.auth.AuthViewModel
import com.ptchampion.ui.dashboard.DashboardScreen
import com.ptchampion.ui.exercises.ExercisesScreen
import com.ptchampion.ui.history.HistoryScreen
import com.ptchampion.ui.profile.ProfileScreen

/**
 * Navigation item
 */
data class NavigationItem(
    val route: String,
    val title: String,
    val icon: ImageVector,
    val contentDescription: String
)

/**
 * Main app navigation
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun MainApp() {
    val navController = rememberNavController()
    val authViewModel: AuthViewModel = hiltViewModel()
    val authState by authViewModel.uiState.collectAsState()
    
    // Check if user is logged in to determine start destination
    val startDestination = if (authState.isLoggedIn) {
        "dashboard"
    } else {
        "auth"
    }
    
    // Bottom navigation items
    val navigationItems = listOf(
        NavigationItem(
            route = "dashboard",
            title = "Home",
            icon = Icons.Default.Home,
            contentDescription = "Home"
        ),
        NavigationItem(
            route = "history",
            title = "History",
            icon = Icons.Default.History,
            contentDescription = "History"
        ),
        NavigationItem(
            route = "profile",
            title = "Profile",
            icon = Icons.Default.AccountCircle,
            contentDescription = "Profile"
        )
    )
    
    // Current route tracking
    val navBackStackEntry by navController.currentBackStackEntryAsState()
    val currentRoute = navBackStackEntry?.destination?.route
    
    // Whether to show bottom nav bar
    val showBottomBar = currentRoute in navigationItems.map { it.route }
    
    Scaffold(
        bottomBar = {
            if (showBottomBar) {
                NavigationBar {
                    navigationItems.forEach { item ->
                        NavigationBarItem(
                            icon = { 
                                Icon(
                                    imageVector = item.icon,
                                    contentDescription = item.contentDescription
                                ) 
                            },
                            label = { Text(item.title) },
                            selected = currentRoute == item.route,
                            onClick = {
                                navController.navigate(item.route) {
                                    // Pop up to the start destination of the graph to
                                    // avoid building up a large stack of destinations
                                    popUpTo(navController.graph.startDestinationId) {
                                        saveState = true
                                    }
                                    // Avoid multiple copies of the same destination
                                    launchSingleTop = true
                                    // Restore state when reselecting a previously selected item
                                    restoreState = true
                                }
                            }
                        )
                    }
                }
            }
        }
    ) { innerPadding ->
        NavHost(
            navController = navController,
            startDestination = startDestination,
            modifier = Modifier.padding(innerPadding)
        ) {
            // Authentication screen
            composable("auth") {
                AuthScreen(
                    onNavigateToHome = {
                        navController.navigate("dashboard") {
                            popUpTo("auth") { inclusive = true }
                        }
                    }
                )
            }
            
            // Dashboard screen
            composable("dashboard") {
                DashboardScreen(
                    onNavigateToExercise = { exerciseId ->
                        navController.navigate("exercise/$exerciseId")
                    }
                )
            }
            
            // Exercise screen
            composable("exercise/{exerciseId}") { backStackEntry ->
                val exerciseId = backStackEntry.arguments?.getString("exerciseId")?.toIntOrNull() ?: 0
                ExercisesScreen(
                    exerciseId = exerciseId,
                    onNavigateBack = {
                        navController.popBackStack()
                    }
                )
            }
            
            // History screen
            composable("history") {
                HistoryScreen(
                    onNavigateBack = {
                        navController.popBackStack()
                    }
                )
            }
            
            // Profile screen
            composable("profile") {
                ProfileScreen(
                    onNavigateToLogin = {
                        navController.navigate("auth") {
                            popUpTo(navController.graph.id) { inclusive = true }
                        }
                    }
                )
            }
        }
    }
}

/**
 * Main activity content
 */
@Composable
fun MainActivityContent() {
    MaterialTheme {
        MainApp()
    }
}