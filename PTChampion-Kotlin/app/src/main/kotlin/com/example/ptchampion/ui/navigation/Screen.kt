package com.example.ptchampion.ui.navigation

import androidx.navigation.NavType
import androidx.navigation.navArgument

sealed class Screen(val route: String) {
    object Splash : Screen("splash")
    object Home : Screen("home")
    object ExerciseList : Screen("exercise_list")
    object ExerciseDetail : Screen("exercise_detail/{exerciseId}") { // Example with argument
        fun createRoute(exerciseId: String) = "exercise_detail/$exerciseId"
    }
    object Leaderboard : Screen("leaderboard")
    object Profile : Screen("profile")
    object Login : Screen("login")
    object SignUp : Screen("signup")
    object Camera : Screen("camera/{exerciseId}/{exerciseType}") { // Pass both ID and type
        fun createRoute(exerciseId: Int, exerciseType: String) = "camera/$exerciseId/$exerciseType"
        val arguments = listOf(
            navArgument("exerciseId") { type = NavType.IntType },
            navArgument("exerciseType") { type = NavType.StringType; nullable = true }
        )
    }
    object History : Screen("history")
    object WorkoutDetail : Screen("workout_detail/{workoutId}") {
        fun createRoute(workoutId: String) = "workout_detail/$workoutId"
        val arguments = listOf(navArgument("workoutId") { type = NavType.StringType })
    }
    object RunningTracking : Screen("running_tracking")
    object Settings : Screen("settings")
    object BluetoothDeviceManagement : Screen("bluetooth_management")
    object Onboarding : Screen("onboarding")
} 