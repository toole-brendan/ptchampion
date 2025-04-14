package com.example.ptchampion.ui.navigation

import androidx.navigation.NamedNavArgument
import androidx.navigation.NavType
import androidx.navigation.navArgument

sealed class Screen(val route: String, val arguments: List<NamedNavArgument> = emptyList()) {
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
    object Camera : Screen(
        route = "camera/{exerciseId}/{exerciseType}",
        arguments = listOf(
            navArgument("exerciseId") { type = NavType.IntType },
            navArgument("exerciseType") { type = NavType.StringType; nullable = true }
        )
    ) {
        fun createRoute(exerciseId: Int, exerciseType: String?) = "camera/$exerciseId/${exerciseType ?: "unknown"}"
    }
    object History : Screen("history")
    object WorkoutDetail : Screen(
        route = "workout_detail/{workoutId}",
        arguments = listOf(navArgument("workoutId") { type = NavType.StringType })
    ) {
        fun createRoute(workoutId: String) = "workout_detail/$workoutId"
    }
    object RunningTracking : Screen("running_tracking")
    object Settings : Screen("settings")
    object BluetoothDeviceManagement : Screen("bluetooth_management")
    object Onboarding : Screen("onboarding")
    object EditProfile : Screen("editProfile")
} 