package com.example.ptchampion.ui.screens.login

import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardActions
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Visibility
import androidx.compose.material.icons.filled.VisibilityOff
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalFocusManager
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.input.PasswordVisualTransformation
import androidx.compose.ui.text.input.VisualTransformation
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
// import androidx.hilt.navigation.compose.hiltViewModel // Remove Hilt import
import androidx.lifecycle.viewmodel.compose.viewModel // Add standard ViewModel import
import androidx.navigation.NavController
import com.example.ptchampion.R
import com.example.ptchampion.ui.navigation.Screen
import com.example.ptchampion.ui.theme.PtAccent
import com.example.ptchampion.ui.theme.PtCommandBlack
import com.example.ptchampion.ui.theme.PtSecondaryText
import kotlinx.coroutines.flow.collectLatest

@Composable
fun LoginScreen(
    navController: NavController,
    // viewModel: LoginViewModel = hiltViewModel() // Replace Hilt function
    viewModel: LoginViewModel = viewModel() // Use standard ViewModel function
) {
    val state = viewModel.state
    val focusManager = LocalFocusManager.current
    var passwordVisible by remember { mutableStateOf(false) }

    LaunchedEffect(key1 = true) {
        viewModel.effect.collectLatest { effect ->
            when (effect) {
                LoginEffect.NavigateToHome -> {
                    // Navigate to Home and clear back stack
                    navController.navigate(Screen.Home.route) {
                        popUpTo(Screen.Login.route) { inclusive = true }
                    }
                }
                LoginEffect.NavigateToSignUp -> {
                     navController.navigate(Screen.SignUp.route)
                }
            }
        }
    }

    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(MaterialTheme.colorScheme.background) // Use theme background
    ) {
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(horizontal = 32.dp),
            verticalArrangement = Arrangement.Center,
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            Spacer(modifier = Modifier.weight(0.15f))
            
            // Logo
            Image(
                painter = painterResource(id = R.drawable.pt_champion_logo_2),
                contentDescription = "PT Champion Logo",
                modifier = Modifier
                    .width(200.dp) // Adjusted size slightly based on image proportions
                    .padding(bottom = 12.dp)
            )
            
            Spacer(modifier = Modifier.height(48.dp))
            
            // Email field
            OutlinedTextField(
                value = state.email,
                onValueChange = { viewModel.onEvent(LoginEvent.EmailChanged(it)) },
                label = { Text("Email") },
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(bottom = 16.dp),
                colors = OutlinedTextFieldDefaults.colors(
                    focusedContainerColor = MaterialTheme.colorScheme.surface,
                    unfocusedContainerColor = MaterialTheme.colorScheme.surface,
                    focusedTextColor = MaterialTheme.colorScheme.onSurface,
                    unfocusedTextColor = MaterialTheme.colorScheme.onSurface,
                    focusedLabelColor = MaterialTheme.colorScheme.secondary,
                    unfocusedLabelColor = MaterialTheme.colorScheme.secondary,
                    cursorColor = MaterialTheme.colorScheme.primary,
                    focusedBorderColor = MaterialTheme.colorScheme.primary,
                    unfocusedBorderColor = MaterialTheme.colorScheme.outline,
                    errorContainerColor = MaterialTheme.colorScheme.surface,
                    errorBorderColor = MaterialTheme.colorScheme.error,
                    errorLabelColor = MaterialTheme.colorScheme.error,
                    errorCursorColor = MaterialTheme.colorScheme.error,
                    errorTextColor = MaterialTheme.colorScheme.error,
                ),
                textStyle = MaterialTheme.typography.bodyMedium,
                keyboardOptions = KeyboardOptions(
                    keyboardType = KeyboardType.Email,
                    imeAction = ImeAction.Next
                ),
                isError = state.error != null,
                singleLine = true,
                shape = MaterialTheme.shapes.small
            )

            // Password field
            OutlinedTextField(
                value = state.password,
                onValueChange = { viewModel.onEvent(LoginEvent.PasswordChanged(it)) },
                label = { Text("Password") },
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(bottom = 16.dp),
                visualTransformation = if (passwordVisible) VisualTransformation.None else PasswordVisualTransformation(),
                keyboardOptions = KeyboardOptions(
                    keyboardType = KeyboardType.Password,
                    imeAction = ImeAction.Done
                ),
                keyboardActions = KeyboardActions(
                    onDone = { focusManager.clearFocus() }
                ),
                trailingIcon = {
                    val image = if (passwordVisible)
                        Icons.Filled.Visibility
                    else Icons.Filled.VisibilityOff
                    val description = if (passwordVisible) "Hide password" else "Show password"

                    IconButton(onClick = {passwordVisible = !passwordVisible}){
                        Icon(
                            imageVector = image,
                            contentDescription = description,
                            tint = if (state.error != null) MaterialTheme.colorScheme.error else MaterialTheme.colorScheme.secondary
                        )
                    }
                },
                colors = OutlinedTextFieldDefaults.colors(
                    focusedContainerColor = MaterialTheme.colorScheme.surface,
                    unfocusedContainerColor = MaterialTheme.colorScheme.surface,
                    focusedTextColor = MaterialTheme.colorScheme.onSurface,
                    unfocusedTextColor = MaterialTheme.colorScheme.onSurface,
                    focusedLabelColor = MaterialTheme.colorScheme.secondary,
                    unfocusedLabelColor = MaterialTheme.colorScheme.secondary,
                    cursorColor = MaterialTheme.colorScheme.primary,
                    focusedBorderColor = MaterialTheme.colorScheme.primary,
                    unfocusedBorderColor = MaterialTheme.colorScheme.outline,
                    errorContainerColor = MaterialTheme.colorScheme.surface,
                    errorBorderColor = MaterialTheme.colorScheme.error,
                    errorLabelColor = MaterialTheme.colorScheme.error,
                    errorCursorColor = MaterialTheme.colorScheme.error,
                    errorTextColor = MaterialTheme.colorScheme.error,
                    errorTrailingIconColor = MaterialTheme.colorScheme.error
                ),
                textStyle = MaterialTheme.typography.bodyMedium,
                isError = state.error != null,
                singleLine = true,
                shape = MaterialTheme.shapes.small
            )

            if (state.error != null) {
                Text(
                    text = state.error,
                    color = MaterialTheme.colorScheme.error,
                    style = MaterialTheme.typography.bodySmall,
                    modifier = Modifier.align(Alignment.Start).padding(start = 4.dp)
                )
                Spacer(modifier = Modifier.height(8.dp))
            } else {
                 Spacer(modifier = Modifier.height(8.dp + (MaterialTheme.typography.bodySmall.fontSize.value * MaterialTheme.typography.bodySmall.lineHeight.value / MaterialTheme.typography.bodySmall.fontSize.value).dp))
            }

            // Login button
            Button(
                onClick = {
                    focusManager.clearFocus()
                    viewModel.onEvent(LoginEvent.Submit)
                },
                modifier = Modifier
                    .fillMaxWidth()
                    .height(56.dp),
                enabled = !state.isLoading,
                colors = ButtonDefaults.buttonColors(
                    containerColor = PtAccent, // Brass Gold
                    contentColor = PtCommandBlack, // Command Black (text on button)
                    disabledContainerColor = PtAccent.copy(alpha = 0.5f)
                ),
                shape = MaterialTheme.shapes.small
            ) {
                if (state.isLoading) {
                    CircularProgressIndicator(
                        modifier = Modifier.size(24.dp),
                        strokeWidth = 2.dp,
                        color = PtCommandBlack
                    )
                } else {
                    Text(
                        text = "LOG IN",
                        style = MaterialTheme.typography.labelLarge
                    )
                }
            }
            
            // Forgot password
            TextButton(
                onClick = { /* TODO: Implement forgot password */ },
                modifier = Modifier.padding(top = 8.dp)
            ) {
                Text(
                    text = "Forgot password?",
                    color = PtAccent, // Brass Gold for links
                    style = MaterialTheme.typography.bodySmall
                )
            }
            
            // Sign up
            Row(
                modifier = Modifier.padding(top = 16.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text(
                    text = "Don't have an account:",
                    color = PtSecondaryText, // Tactical Gray
                    style = MaterialTheme.typography.bodySmall
                )
                TextButton(
                    onClick = { viewModel.navigateToSignUp() },
                    contentPadding = PaddingValues(start = 4.dp)
                ) {
                    Text(
                        text = "Sign up",
                        color = PtAccent, // Brass Gold for links
                        style = MaterialTheme.typography.bodySmall
                    )
                }
            }
            
            Spacer(modifier = Modifier.weight(0.2f))
        }
    }
} 