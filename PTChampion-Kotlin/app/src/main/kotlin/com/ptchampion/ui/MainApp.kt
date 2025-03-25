package com.ptchampion.ui

import androidx.compose.foundation.layout.padding
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.DirectionsRun
import androidx.compose.material.icons.filled.Home
import androidx.compose.material.icons.filled.Person
import androidx.compose.material.icons.filled.Timeline
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.NavigationBar
import androidx.compose.material3.NavigationBarItem
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.unit.dp
import androidx.navigation.NavGraph.Companion.findStartDestination
import androidx.navigation.NavHostController
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.currentBackStackEntryAsState
import androidx.navigation.compose.rememberNavController
import com.ptchampion.ui.auth.AuthScreen
import com.ptchampion.ui.dashboard.DashboardScreen
import com.ptchampion.ui.exercises.ExercisesScreen
import com.ptchampion.ui.history.HistoryScreen
import com.ptchampion.ui.profile.ProfileScreen

/**
 * Main app composable that sets up the navigation and layout
 */
@Composable
fun MainApp() {
    val navController = rememberNavController()
    
    Scaffold(
        bottomBar = { BottomNavigation(navController) }
    ) { innerPadding ->
        NavHost(
            navController = navController,
            startDestination = Screen.Auth.route,
            modifier = Modifier.padding(innerPadding)
        ) {
            composable(Screen.Auth.route) {
                AuthScreen(onNavigateToDashboard = {
                    navController.navigate(Screen.Dashboard.route) {
                        popUpTo(navController.graph.findStartDestination().id) {
                            saveState = true
                        }
                        launchSingleTop = true
                        restoreState = true
                    }
                })
            }
            
            composable(Screen.Dashboard.route) {
                DashboardScreen(
                    onNavigateToExercise = { exerciseId ->
                        navController.navigate("${Screen.Exercises.route}/$exerciseId")
                    }
                )
            }
            
            composable("${Screen.Exercises.route}/{exerciseId}") { backStackEntry ->
                val exerciseId = backStackEntry.arguments?.getString("exerciseId")?.toIntOrNull() ?: 0
                ExercisesScreen(
                    exerciseId = exerciseId,
                    onNavigateBack = { navController.popBackStack() }
                )
            }
            
            composable(Screen.History.route) {
                HistoryScreen()
            }
            
            composable(Screen.Profile.route) {
                ProfileScreen(
                    onLogout = {
                        navController.navigate(Screen.Auth.route) {
                            popUpTo(0) { inclusive = true }
                        }
                    }
                )
            }
        }
    }
}

/**
 * Bottom navigation bar
 */
@Composable
fun BottomNavigation(navController: NavHostController) {
    val items = listOf(
        Screen.Dashboard,
        Screen.Exercises,
        Screen.History,
        Screen.Profile
    )
    
    val navBackStackEntry by navController.currentBackStackEntryAsState()
    val currentRoute = navBackStackEntry?.destination?.route
    
    // Don't show bottom navigation on auth screen
    if (currentRoute == Screen.Auth.route) {
        return
    }
    
    NavigationBar(
        containerColor = MaterialTheme.colorScheme.surface,
        tonalElevation = 8.dp
    ) {
        items.forEach { screen ->
            NavigationBarItem(
                icon = { Icon(screen.icon, contentDescription = screen.label) },
                label = { Text(screen.label) },
                selected = currentRoute == screen.route || 
                         (currentRoute?.startsWith(screen.route + "/") == true),
                onClick = {
                    navController.navigate(screen.route) {
                        popUpTo(navController.graph.findStartDestination().id) {
                            saveState = true
                        }
                        launchSingleTop = true
                        restoreState = true
                    }
                }
            )
        }
    }
}

/**
 * Screen destinations
 */
sealed class Screen(
    val route: String,
    val label: String,
    val icon: ImageVector
) {
    object Auth : Screen("auth", "Auth", Icons.Filled.Person)
    object Dashboard : Screen("dashboard", "Home", Icons.Filled.Home)
    object Exercises : Screen("exercises", "Exercises", Icons.Filled.DirectionsRun)
    object History : Screen("history", "History", Icons.Filled.Timeline)
    object Profile : Screen("profile", "Profile", Icons.Filled.Person)
}