package com.example.ptchampion.ui.screens.signup

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.text.KeyboardActions
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Visibility
import androidx.compose.material.icons.filled.VisibilityOff
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalFocusManager
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.input.PasswordVisualTransformation
import androidx.compose.ui.text.input.VisualTransformation
import androidx.compose.ui.unit.dp
// import androidx.hilt.navigation.compose.hiltViewModel // Remove Hilt import
import androidx.lifecycle.viewmodel.compose.viewModel // Add standard ViewModel import
import androidx.navigation.NavController
import com.example.ptchampion.ui.navigation.Screen
import kotlinx.coroutines.flow.collectLatest

@Composable
fun SignUpScreen(
    navController: NavController,
    // viewModel: SignUpViewModel = hiltViewModel() // Replace Hilt function
    viewModel: SignUpViewModel = viewModel() // Use standard ViewModel function
) {
    val state = viewModel.state
    val focusManager = LocalFocusManager.current
    var passwordVisible by remember { mutableStateOf(false) }
    var confirmPasswordVisible by remember { mutableStateOf(false) }

    LaunchedEffect(key1 = true) {
        viewModel.effect.collectLatest { effect ->
            when (effect) {
                SignUpEffect.NavigateToLogin -> {
                    // Navigate back to Login, potentially show a success message
                    navController.navigate(Screen.Login.route) {
                         popUpTo(Screen.Login.route) { inclusive = true } // Clear sign up from backstack
                    }
                }
            }
        }
    }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(16.dp),
        verticalArrangement = Arrangement.Center,
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        Text(text = "Sign Up", style = MaterialTheme.typography.headlineMedium)
        Spacer(modifier = Modifier.height(32.dp))

        OutlinedTextField(
            value = state.email,
            onValueChange = { viewModel.onEvent(SignUpEvent.EmailChanged(it)) },
            label = { Text("Email") },
            modifier = Modifier.fillMaxWidth(),
            keyboardOptions = KeyboardOptions(
                keyboardType = KeyboardType.Email,
                imeAction = ImeAction.Next
            ),
            isError = state.error != null,
            singleLine = true
        )
        Spacer(modifier = Modifier.height(16.dp))

        OutlinedTextField(
            value = state.password,
            onValueChange = { viewModel.onEvent(SignUpEvent.PasswordChanged(it)) },
            label = { Text("Password") },
            modifier = Modifier.fillMaxWidth(),
            visualTransformation = if (passwordVisible) VisualTransformation.None else PasswordVisualTransformation(),
            keyboardOptions = KeyboardOptions(
                keyboardType = KeyboardType.Password,
                imeAction = ImeAction.Next
            ),
             trailingIcon = {
                val image = if (passwordVisible)
                    Icons.Filled.Visibility
                else Icons.Filled.VisibilityOff
                val description = if (passwordVisible) "Hide password" else "Show password"

                IconButton(onClick = {passwordVisible = !passwordVisible}){
                    Icon(imageVector  = image, description)
                }
            },
            isError = state.error != null,
            singleLine = true
        )
         Spacer(modifier = Modifier.height(16.dp))

        OutlinedTextField(
            value = state.confirmPassword,
            onValueChange = { viewModel.onEvent(SignUpEvent.ConfirmPasswordChanged(it)) },
            label = { Text("Confirm Password") },
            modifier = Modifier.fillMaxWidth(),
            visualTransformation = if (confirmPasswordVisible) VisualTransformation.None else PasswordVisualTransformation(),
            keyboardOptions = KeyboardOptions(
                keyboardType = KeyboardType.Password,
                imeAction = ImeAction.Done
            ),
            keyboardActions = KeyboardActions(
                onDone = { focusManager.clearFocus() }
            ),
             trailingIcon = {
                val image = if (confirmPasswordVisible)
                    Icons.Filled.Visibility
                else Icons.Filled.VisibilityOff
                val description = if (confirmPasswordVisible) "Hide password" else "Show password"

                IconButton(onClick = {confirmPasswordVisible = !confirmPasswordVisible}){
                    Icon(imageVector  = image, description)
                }
            },
            isError = state.error != null,
            singleLine = true
        )
        Spacer(modifier = Modifier.height(16.dp))

        if (state.error != null) {
            Text(
                text = state.error,
                color = MaterialTheme.colorScheme.error,
                modifier = Modifier.align(Alignment.Start)
            )
            Spacer(modifier = Modifier.height(8.dp))
        }

        Button(
            onClick = {
                focusManager.clearFocus()
                viewModel.onEvent(SignUpEvent.Submit)
            },
            modifier = Modifier.fillMaxWidth(),
            enabled = !state.isLoading
        ) {
            if (state.isLoading) {
                CircularProgressIndicator(modifier = Modifier.size(24.dp), strokeWidth = 2.dp)
            } else {
                Text("Sign Up")
            }
        }
         Spacer(modifier = Modifier.height(16.dp))

        TextButton(onClick = { viewModel.navigateToLogin() }) {
             Text("Already have an account? Login")
        }
    }
} 