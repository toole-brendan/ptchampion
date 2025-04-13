package com.example.ptchampion.ui

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.foundation.Image
import androidx.compose.foundation.layout.fillMaxSize
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
import com.example.ptchampion.ui.screens.*
import com.example.ptchampion.ui.screens.login.LoginScreen
import com.example.ptchampion.ui.screens.signup.SignUpScreen
import com.example.ptchampion.ui.screens.splash.SplashScreen
import com.example.ptchampion.ui.theme.PTChampionTheme
import com.example.ptchampion.ui.screens.profile.ProfileScreen
import com.example.ptchampion.ui.screens.home.HomeScreen
import com.example.ptchampion.ui.screens.leaderboard.LeaderboardScreen
import com.example.ptchampion.ui.screens.exerciselist.ExerciseListScreen
import com.example.ptchampion.ui.screens.leaderboard.LocalLeaderboardScreen
import com.example.ptchampion.ui.screens.camera.CameraScreen
import com.example.ptchampion.ui.screens.history.HistoryScreen
import com.example.ptchampion.ui.navigation.BottomNavItem
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.material3.NavigationBarItemDefaults
import com.example.ptchampion.ui.theme.PtAccent
import com.example.ptchampion.ui.theme.PtBackground
import com.example.ptchampion.ui.theme.PtPrimaryText

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
            // Add TopAppBar with logo emblem
            topBar = {
                if (isAuthenticatedScreen) {
                    TopAppBar(
                        title = { Text("PT Champion") },
                        navigationIcon = {
                            // Logo emblem in the top corner
                            Image(
                                painter = painterResource(id = R.drawable.pt_champion_logo),
                                contentDescription = "PT Champion Logo",
                                modifier = Modifier.size(32.dp) // Small emblem size
                            )
                        },
                        colors = TopAppBarDefaults.topAppBarColors(
                            containerColor = MaterialTheme.colorScheme.background, // Use theme background color
                            titleContentColor = MaterialTheme.colorScheme.onBackground, // Use theme text color
                        )
                    )
                }
            },
            bottomBar = {
                if (isAuthenticatedScreen) {
                    NavigationBar(
                        containerColor = PtPrimaryText
                    ) {
                        bottomNavItems.forEach { item ->
                            val isSelected = currentDestination?.hierarchy?.any { it.route == item.screen.route } == true
                            NavigationBarItem(
                                icon = { Icon(item.icon, contentDescription = item.label) },
                                label = { Text(item.label, style = MaterialTheme.typography.labelSmall) },
                                selected = isSelected,
                                onClick = {
                                    navController.navigate(item.screen.route) {
                                        popUpTo(navController.graph.findStartDestination().id) {
                                            saveState = true
                                        }
                                        launchSingleTop = true
                                        restoreState = true
                                    }
                                },
                                colors = NavigationBarItemDefaults.colors(
                                    selectedIconColor = PtBackground,
                                    selectedTextColor = PtBackground,
                                    unselectedIconColor = PtAccent,
                                    unselectedTextColor = PtAccent,
                                    indicatorColor = PtPrimaryText
                                )
                            )
                        }
                    }
                }
            }
        ) { innerPadding ->
            NavHost(
                navController = navController,
                startDestination = Screen.Splash.route,
                modifier = Modifier.padding(innerPadding)
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
                composable(Screen.History.route) { HistoryScreen() }
                composable(
                    route = Screen.ExerciseDetail.route,
                    arguments = listOf(navArgument("exerciseId") { type = NavType.StringType })
                ) {
                    ExerciseDetailScreen(
                        exerciseId = it.arguments?.getString("exerciseId")
                    )
                }
                composable(Screen.Leaderboard.route) { LocalLeaderboardScreen() }
                composable(Screen.Profile.route) {
                    ProfileScreen(
                        navigateToLogin = {
                            navController.navigate(Screen.Login.route) {
                                popUpTo(Screen.Login.route) { inclusive = true }
                                launchSingleTop = true
                            }
                        }
                    )
                }
                composable(Screen.Login.route) { LoginScreen(navController = navController) }
                composable(Screen.SignUp.route) { SignUpScreen(navController = navController) }
                composable(
                    route = Screen.Camera.route,
                    arguments = listOf(
                        navArgument("exerciseId") { type = NavType.IntType },
                        navArgument("exerciseType") { type = NavType.StringType }
                    )
                ) {
                    CameraScreen(
                        exerciseId = it.arguments?.getInt("exerciseId") ?: -1,
                        exerciseType = it.arguments?.getString("exerciseType")
                    )
                }
            }
        }
    }
}

// Remove old Greeting preview
/*
@Preview(showBackground = true)
@Composable
fun GreetingPreview() {
    PTChampionTheme {
        Greeting("Android")
    }
}
*/ 