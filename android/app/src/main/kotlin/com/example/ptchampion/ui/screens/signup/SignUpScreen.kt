package com.example.ptchampion.ui.screens.signup

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.input.PasswordVisualTransformation
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.navigation.NavController
import com.example.ptchampion.ui.navigation.Screen
import com.example.ptchampion.ui.theme.*

@Composable
fun SignUpScreen(
    navController: NavController,
    viewModel: SignUpViewModel = hiltViewModel()
) {
    val uiState by viewModel.uiState.collectAsState()

    // Handle navigation effects
    LaunchedEffect(key1 = true) {
        viewModel.effect.collect { effect ->
            when (effect) {
                is SignUpEffect.NavigateToLogin -> {
                    navController.navigate(Screen.Login.route) {
                        // Optional: Pop SignUp from back stack
                        popUpTo(Screen.SignUp.route) { inclusive = true }
                    }
                }
                else -> {
                    // Handle unexpected effect or null if flow allows
                    println("SignUpScreen: Received unexpected effect: $effect")
                }
            }
        }
    }

    Surface(
        modifier = Modifier.fillMaxSize(),
        color = PtBackground // Use theme background
    ) {
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(32.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.Center
        ) {
            Text("Sign Up", style = MaterialTheme.typography.headlineLarge, color = PtCommandBlack)
            Spacer(modifier = Modifier.height(24.dp))

            // Username Field
            OutlinedTextField(
                value = uiState.username,
                onValueChange = { viewModel.onEvent(SignUpEvent.UsernameChanged(it)) },
                label = { Text("Username") },
                modifier = Modifier.fillMaxWidth(),
                singleLine = true,
                colors = ptTextFieldColors(),
                isError = uiState.error?.contains("Username", ignoreCase = true) == true
            )
            Spacer(modifier = Modifier.height(16.dp))

            // Email Field
            OutlinedTextField(
                value = uiState.email,
                onValueChange = { viewModel.onEvent(SignUpEvent.EmailChanged(it)) },
                label = { Text("Email") },
                modifier = Modifier.fillMaxWidth(),
                singleLine = true,
                keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Email),
                colors = ptTextFieldColors(),
                isError = uiState.error?.contains("Email", ignoreCase = true) == true
            )
            Spacer(modifier = Modifier.height(16.dp))

            // Password Field
            OutlinedTextField(
                value = uiState.password,
                onValueChange = { viewModel.onEvent(SignUpEvent.PasswordChanged(it)) },
                label = { Text("Password") },
                modifier = Modifier.fillMaxWidth(),
                singleLine = true,
                visualTransformation = PasswordVisualTransformation(),
                keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Password),
                colors = ptTextFieldColors(),
                isError = uiState.error?.contains("Password", ignoreCase = true) == true
            )
            Spacer(modifier = Modifier.height(16.dp))

            // Confirm Password Field
            OutlinedTextField(
                value = uiState.confirmPassword,
                onValueChange = { viewModel.onEvent(SignUpEvent.ConfirmPasswordChanged(it)) },
                label = { Text("Confirm Password") },
                modifier = Modifier.fillMaxWidth(),
                singleLine = true,
                visualTransformation = PasswordVisualTransformation(),
                keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Password),
                colors = ptTextFieldColors(),
                isError = uiState.error?.contains("Password", ignoreCase = true) == true // Highlight if passwords mismatch error
            )
            Spacer(modifier = Modifier.height(24.dp))

            // Error Message Display
            uiState.error?.let {
                Text(
                    text = it,
                    color = MaterialTheme.colorScheme.error,
                    style = MaterialTheme.typography.bodySmall,
                    textAlign = TextAlign.Center,
                    modifier = Modifier.padding(bottom = 8.dp)
                )
            }

            // Sign Up Button with Loading Indicator
            Button(
                onClick = { viewModel.onEvent(SignUpEvent.Submit) },
                enabled = !uiState.isLoading,
                modifier = Modifier.fillMaxWidth(),
                colors = ButtonDefaults.buttonColors(
                    containerColor = PtAccent,
                    contentColor = PtCommandBlack,
                    disabledContainerColor = PtAccent.copy(alpha = 0.5f),
                    disabledContentColor = PtCommandBlack.copy(alpha = 0.5f)
                ),
                shape = MaterialTheme.shapes.small
            ) {
                if (uiState.isLoading) {
                    CircularProgressIndicator(
                        modifier = Modifier.size(24.dp),
                        color = PtCommandBlack,
                        strokeWidth = 2.dp
                    )
                } else {
                    Text("SIGN UP")
                }
            }

            Spacer(modifier = Modifier.height(16.dp))

            // Login Link
            TextButton(onClick = { viewModel.navigateToLogin() }) {
                Text("Already have an account? Login", color = PtAccent)
            }
        }
    }
}

// Helper for consistent TextField colors
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ptTextFieldColors() = TextFieldDefaults.outlinedTextFieldColors(
    focusedBorderColor = PtAccent,
    unfocusedBorderColor = PtSecondaryText,
    cursorColor = PtAccent,
    focusedLabelColor = PtAccent,
    unfocusedLabelColor = PtSecondaryText
) 