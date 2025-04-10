package com.example.ptchampion.ui.navigation

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
    object Camera : Screen("camera/{exerciseType}") { // Example for specific exercise camera
        fun createRoute(exerciseType: String) = "camera/$exerciseType"
    }
} 