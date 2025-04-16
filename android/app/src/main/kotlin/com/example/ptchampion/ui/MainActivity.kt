package com.example.ptchampion.ui

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.foundation.Image
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.AccountCircle
import androidx.compose.material.icons.filled.Home
import androidx.compose.material.icons.filled.List
import androidx.compose.material.icons.filled.FitnessCenter
import androidx.compose.material.icons.filled.History
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.NavigationBar
import androidx.compose.material3.NavigationBarItem
import androidx.compose.material3.Scaffold
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import androidx.navigation.NavDestination.Companion.hierarchy
import androidx.navigation.NavGraph.Companion.findStartDestination
import androidx.navigation.NavType
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.currentBackStackEntryAsState
import androidx.navigation.compose.rememberNavController
import androidx.navigation.navArgument
import com.example.ptchampion.R
import com.example.ptchampion.ui.navigation.Screen
import com.example.ptchampion.ui.navigation.BottomNavItem
import com.example.ptchampion.ui.screens.login.LoginScreen
import com.example.ptchampion.ui.screens.signup.SignUpScreen
import com.example.ptchampion.ui.screens.splash.SplashScreen
import com.example.ptchampion.ui.screens.profile.ProfileScreen
import com.example.ptchampion.ui.screens.home.HomeScreen
import com.example.ptchampion.ui.screens.leaderboard.LeaderboardScreen
import com.example.ptchampion.ui.screens.exerciselist.ExerciseListScreen
import com.example.ptchampion.ui.screens.camera.CameraScreen
import com.example.ptchampion.ui.screens.history.HistoryScreen
import com.example.ptchampion.ui.theme.PTChampionTheme
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.material3.NavigationBarItemDefaults
import com.example.ptchampion.ui.theme.PtAccent
import com.example.ptchampion.ui.theme.PtBackground
import com.example.ptchampion.ui.theme.PtPrimaryText
import com.example.ptchampion.ui.screens.workoutdetail.WorkoutDetailScreen
import com.example.ptchampion.ui.screens.running.RunningTrackingScreen
import com.example.ptchampion.ui.screens.settings.SettingsScreen
import com.example.ptchampion.ui.screens.bluetooth.BluetoothDeviceManagementScreen
import com.example.ptchampion.ui.screens.onboarding.OnboardingScreen
import com.example.ptchampion.ui.screens.editprofile.EditProfileScreen

// Define items for the bottom navigation bar
// data class BottomNavItem(val screen: Screen, val label: String, val icon: ImageVector)

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContent {
            PTChampionApp()
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun PTChampionApp() {
    PTChampionTheme {
        val navController = rememberNavController()
        val navBackStackEntry by navController.currentBackStackEntryAsState()
        val currentDestination = navBackStackEntry?.destination

        // Screens that should show the bottom navigation bar and top app bar with emblem
        val authenticatedScreens = setOf(
            Screen.Home.route,
            Screen.ExerciseList.route,
            Screen.Leaderboard.route,
            Screen.Profile.route,
            Screen.History.route
        )

        // Determine if the bottom bar should be shown
        val isAuthenticatedScreen = currentDestination?.route in authenticatedScreens

        // List of items for the bottom bar
        val bottomNavItems = listOf(
            BottomNavItem(Screen.Home, "Home", Icons.Default.Home),
            BottomNavItem(Screen.ExerciseList, "Exercises", Icons.Default.FitnessCenter),
            BottomNavItem(Screen.History, "History", Icons.Filled.History),
            BottomNavItem(Screen.Leaderboard, "Leaders", Icons.Default.List),
            BottomNavItem(Screen.Profile, "Profile", Icons.Default.AccountCircle)
        )

        Scaffold(
            topBar = {
                if (isAuthenticatedScreen) {
                    TopAppBar(
                        title = { /* No Title Text Needed Per Guide */ },
                        navigationIcon = {
                            // Logo emblem in the top corner, styled
                            Image(
                                painter = painterResource(id = R.drawable.pt_champion_logo), // Use available logo resource
                                contentDescription = "PT Champion Logo",
                                modifier = Modifier
                                    .padding(start = 16.dp) // Add padding to position it
                                    .size(32.dp) // Guide says 32-48px
                            )
                        },
                        colors = TopAppBarDefaults.topAppBarColors(
                            containerColor = MaterialTheme.colorScheme.background, // Tactical Cream
                            navigationIconContentColor = PtAccent, // Brass Gold for logo emblem
                            // No title, so titleContentColor is not directly used
                        )
                    )
                }
            },
            bottomBar = {
                if (isAuthenticatedScreen) {
                    // Custom implementation for better alignment control
                    Surface(
                        color = PtPrimaryText, // Deep Ops Green as nav background
                        modifier = Modifier.height(60.dp)
                    ) {
                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            horizontalArrangement = Arrangement.SpaceEvenly
                        ) {
                            bottomNavItems.forEach { item ->
                                val isSelected = currentDestination?.hierarchy?.any { it.route == item.screen.route } == true
                                
                                Column(
                                    horizontalAlignment = Alignment.CenterHorizontally,
                                    modifier = Modifier
                                        .weight(1f)
                                        .fillMaxHeight()
                                        .padding(vertical = 4.dp)
                                        .clickable {
                                            navController.navigate(item.screen.route) {
                                                popUpTo(navController.graph.findStartDestination().id) {
                                                    saveState = true
                                                }
                                                launchSingleTop = true
                                                restoreState = true
                                            }
                                        }
                                ) {
                                    Icon(
                                        imageVector = item.icon,
                                        contentDescription = item.label,
                                        tint = if (isSelected) PtBackground else PtAccent,
                                        modifier = Modifier.size(24.dp)
                                    )
                                    
                                    Spacer(modifier = Modifier.height(4.dp))
                                    
                                    Text(
                                        text = item.label.uppercase(),
                                        style = MaterialTheme.typography.labelSmall,
                                        color = if (isSelected) PtBackground else PtAccent
                                    )
                                }
                            }
                        }
                    }
                }
            }
        ) { innerPadding ->
            NavHost(
                navController = navController,
                startDestination = Screen.Splash.route,
                modifier = Modifier.padding(innerPadding).fillMaxSize() // Ensure NavHost fills size
            ) {
                composable(Screen.Splash.route) { SplashScreen(navController = navController) }
                composable(Screen.Home.route) { HomeScreen() }
                composable(Screen.ExerciseList.route) {
                    ExerciseListScreen(
                        navigateToCamera = { exerciseId, exerciseType ->
                            navController.navigate(Screen.Camera.createRoute(exerciseId, exerciseType))
                        }
                    )
                }
                composable(Screen.History.route) {
                    HistoryScreen()
                }
                composable(Screen.Leaderboard.route) {
                    LeaderboardScreen()
                }
                composable(Screen.Profile.route) {
                    ProfileScreen(
                        navigateToLogin = {
                            navController.navigate(Screen.Login.route) {
                                popUpTo(navController.graph.id) { inclusive = true }
                                launchSingleTop = true
                            }
                        },
                        navigateToEditProfile = { navController.navigate(Screen.EditProfile.route) },
                        navigateToSettings = { navController.navigate(Screen.Settings.route) }
                    )
                }
                composable(Screen.Login.route) { LoginScreen(navController = navController) }
                composable(Screen.SignUp.route) { SignUpScreen(navController = navController) }
                composable(Screen.EditProfile.route) {
                    EditProfileScreen(
                        onNavigateBack = { navController.popBackStack() }
                    )
                }
                composable(
                    route = Screen.Camera.route,
                    arguments = Screen.Camera.arguments
                ) { backStackEntry ->
                    CameraScreen(
                        onWorkoutComplete = {
                            navController.popBackStack()
                        }
                    )
                }
                composable(
                    route = Screen.WorkoutDetail.route,
                    arguments = Screen.WorkoutDetail.arguments
                ) { backStackEntry ->
                    val workoutId = backStackEntry.arguments?.getString("workoutId")
                    if (workoutId != null) {
                        WorkoutDetailScreen(
                            workoutId = workoutId,
                            onNavigateBack = { navController.popBackStack() }
                        )
                    } else {
                        navController.popBackStack()
                    }
                }
                composable(Screen.RunningTracking.route) {
                    RunningTrackingScreen(
                        onNavigateBack = { navController.popBackStack() }
                    )
                }
                composable(Screen.Settings.route) {
                    SettingsScreen(
                        onNavigateBack = { navController.popBackStack() },
                        onNavigateToBluetooth = {
                            navController.navigate(Screen.BluetoothDeviceManagement.route)
                        },
                        onNavigateToAccount = { /* TODO: Navigate to account management screen if separate */ },
                        onLogout = {
                            navController.navigate(Screen.Login.route) {
                                popUpTo(navController.graph.id) { inclusive = true }
                                launchSingleTop = true
                            }
                        }
                    )
                }
                composable(Screen.BluetoothDeviceManagement.route) {
                    BluetoothDeviceManagementScreen(
                        onNavigateBack = { navController.popBackStack() }
                    )
                }
                composable(Screen.Onboarding.route) {
                    OnboardingScreen(
                        onCompleteOnboarding = {
                            navController.navigate(Screen.Home.route) {
                                popUpTo(Screen.Onboarding.route) { inclusive = true }
                                launchSingleTop = true
                            }
                        }
                    )
                }
            }
        }
    }
}

// Remove old Greeting preview or update it if needed for component testing
/*
@Preview(showBackground = true)
@Composable
fun DefaultPreview() {
    PTChampionTheme {
        PTChampionApp()
    }
}
*/ 