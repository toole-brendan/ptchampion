package com.example.ptchampion.ui

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.AccountCircle
import androidx.compose.material.icons.filled.Home
import androidx.compose.material.icons.filled.List
import androidx.compose.material.icons.filled.FitnessCenter
import androidx.compose.material3.Icon
import androidx.compose.material3.NavigationBar
import androidx.compose.material3.NavigationBarItem
import androidx.compose.material3.Scaffold
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.tooling.preview.Preview
import androidx.navigation.NavDestination.Companion.hierarchy
import androidx.navigation.NavGraph.Companion.findStartDestination
import androidx.navigation.NavType
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.currentBackStackEntryAsState
import androidx.navigation.compose.rememberNavController
import androidx.navigation.navArgument
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
import dagger.hilt.android.AndroidEntryPoint

// Define items for the bottom navigation bar
data class BottomNavItem(val screen: Screen, val label: String, val icon: ImageVector)

@AndroidEntryPoint
class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContent {
            PTChampionApp()
        }
    }
}

@Composable
fun PTChampionApp() {
    PTChampionTheme {
        val navController = rememberNavController()
        val navBackStackEntry by navController.currentBackStackEntryAsState()
        val currentDestination = navBackStackEntry?.destination

        // Screens that should show the bottom navigation bar
        val bottomBarVisibleScreens = setOf(
            Screen.Home.route,
            Screen.ExerciseList.route,
            Screen.Leaderboard.route,
            Screen.Profile.route
        )

        // Determine if the bottom bar should be shown
        val shouldShowBottomBar = currentDestination?.route in bottomBarVisibleScreens

        // List of items for the bottom bar
        val bottomNavItems = listOf(
            BottomNavItem(Screen.Home, "Home", Icons.Default.Home),
            BottomNavItem(Screen.ExerciseList, "Exercises", Icons.Default.FitnessCenter),
            BottomNavItem(Screen.Leaderboard, "Leaders", Icons.Default.List),
            BottomNavItem(Screen.Profile, "Profile", Icons.Default.AccountCircle)
        )

        Scaffold(
            bottomBar = {
                if (shouldShowBottomBar) {
                    NavigationBar {
                        bottomNavItems.forEach { item ->
                            val isSelected = currentDestination?.hierarchy?.any { it.route == item.screen.route } == true
                            NavigationBarItem(
                                icon = { Icon(item.icon, contentDescription = item.label) },
                                label = { Text(item.label) },
                                selected = isSelected,
                                onClick = {
                                    navController.navigate(item.screen.route) {
                                        // Pop up to the start destination of the graph to
                                        // avoid building up a large stack of destinations
                                        // on the back stack as users select items
                                        popUpTo(navController.graph.findStartDestination().id) {
                                            saveState = true
                                        }
                                        // Avoid multiple copies of the same destination when
                                        // reselecting the same item
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
                startDestination = Screen.Splash.route,
                modifier = Modifier.padding(innerPadding)
            ) {
                composable(Screen.Splash.route) { SplashScreen(navController = navController) }
                composable(Screen.Home.route) { HomeScreen(/* Add navigation callbacks if needed */) }
                composable(Screen.ExerciseList.route) {
                    ExerciseListScreen(
                        navigateToCamera = { exerciseType ->
                            navController.navigate(Screen.Camera.createRoute(exerciseType))
                        }
                    )
                }
                composable(
                    route = Screen.ExerciseDetail.route,
                    arguments = listOf(navArgument("exerciseId") { type = NavType.StringType })
                ) {
                    ExerciseDetailScreen(
                        exerciseId = it.arguments?.getString("exerciseId")
                        /* navController */
                    )
                }
                composable(Screen.Leaderboard.route) { LeaderboardScreen(/* Add navigation if needed */) }
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
                    arguments = listOf(navArgument("exerciseType") { type = NavType.StringType })
                ) {
                    CameraScreen(
                        exerciseType = it.arguments?.getString("exerciseType")
                        /* navController */
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