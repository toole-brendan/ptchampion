package com.example.ptchampion.ui

import androidx.test.core.app.ActivityScenario
import androidx.test.core.app.launchActivity
import androidx.test.espresso.Espresso.onView
import androidx.test.espresso.action.ViewActions.*
import androidx.test.espresso.assertion.ViewAssertions.matches
import androidx.test.espresso.matcher.ViewMatchers.*
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.filters.LargeTest
import com.example.ptchampion.R
import com.example.ptchampion.MainActivity
import com.example.ptchampion.di.AppModule
import com.example.ptchampion.di.TestAppModule
import com.google.android.material.textfield.TextInputLayout
import dagger.hilt.android.testing.HiltAndroidRule
import dagger.hilt.android.testing.HiltAndroidTest
import dagger.hilt.android.testing.UninstallModules
import org.hamcrest.BaseMatcher
import org.hamcrest.CoreMatchers.containsString
import org.hamcrest.CoreMatchers.not
import org.hamcrest.Description
import org.hamcrest.Matcher
import org.hamcrest.TypeSafeMatcher
import org.junit.Before
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith
import android.view.View

@LargeTest
@RunWith(AndroidJUnit4::class)
@HiltAndroidTest
@UninstallModules(AppModule::class) // Comment this line if TestAppModule is not yet created
class LoginScreenTest {
    
    @get:Rule
    var hiltRule = HiltAndroidRule(this)
    
    private lateinit var scenario: ActivityScenario<MainActivity>
    
    @Before
    fun setup() {
        hiltRule.inject()
        // Launch the main activity
        scenario = launchActivity()
        
        // Navigate to login screen if needed
        // This assumes we have a way to navigate to login from MainActivity
        // Either MainActivity shows login directly or we navigate there
        if (!isOnLoginScreen()) {
            // If we're not already on login screen, navigate there
            onView(withId(R.id.nav_login)).perform(click())
        }
    }
    
    private fun isOnLoginScreen(): Boolean {
        // Check if the username field is displayed to determine if we're on login screen
        var isOnLoginScreen = false
        try {
            onView(withId(R.id.username_input)).check(matches(isDisplayed()))
            isOnLoginScreen = true
        } catch (e: Exception) {
            // Not on login screen
        }
        return isOnLoginScreen
    }
    
    @Test
    fun loginScreen_hasAllRequiredElements() {
        // Verify all login screen elements are displayed
        onView(withId(R.id.login_title)).check(matches(withText(R.string.login_title)))
        onView(withId(R.id.username_input)).check(matches(isDisplayed()))
        onView(withId(R.id.password_input)).check(matches(isDisplayed()))
        onView(withId(R.id.login_button)).check(matches(isDisplayed()))
        onView(withId(R.id.register_button)).check(matches(isDisplayed()))
        onView(withId(R.id.forgot_password_button)).check(matches(isDisplayed()))
    }
    
    @Test
    fun emptyFields_showsValidationErrors() {
        // Try to login with empty fields
        onView(withId(R.id.login_button)).perform(click())
        
        // Check that validation errors are shown
        onView(withId(R.id.username_input_layout)).check(matches(hasTextInputLayoutErrorText(R.string.error_username_required)))
        onView(withId(R.id.password_input_layout)).check(matches(hasTextInputLayoutErrorText(R.string.error_password_required)))
    }
    
    @Test
    fun validCredentials_navigatesToDashboard() {
        // Enter valid credentials
        onView(withId(R.id.username_input)).perform(typeText("testuser"), closeSoftKeyboard())
        onView(withId(R.id.password_input)).perform(typeText("password123"), closeSoftKeyboard())
        
        // Click login button
        onView(withId(R.id.login_button)).perform(click())
        
        // Verify we navigate to the dashboard
        onView(withId(R.id.dashboard_title)).check(matches(isDisplayed()))
        onView(withId(R.id.welcome_message)).check(matches(withText(containsString("Welcome, Test User"))))
    }
    
    @Test
    fun invalidCredentials_showsErrorMessage() {
        // Enter invalid credentials
        onView(withId(R.id.username_input)).perform(typeText("wronguser"), closeSoftKeyboard())
        onView(withId(R.id.password_input)).perform(typeText("wrongpass"), closeSoftKeyboard())
        
        // Click login button
        onView(withId(R.id.login_button)).perform(click())
        
        // Verify error message is shown
        onView(withId(R.id.error_message)).check(matches(withText(R.string.error_invalid_credentials)))
        onView(withId(R.id.error_message)).check(matches(isDisplayed()))
        
        // Verify we're still on the login screen
        onView(withId(R.id.login_button)).check(matches(isDisplayed()))
    }
    
    @Test
    fun registerButton_navigatesToRegistrationScreen() {
        // Click register button
        onView(withId(R.id.register_button)).perform(click())
        
        // Verify we navigate to registration screen
        onView(withId(R.id.registration_title)).check(matches(isDisplayed()))
        onView(withId(R.id.register_button)).check(matches(isDisplayed()))
    }
    
    @Test
    fun forgotPasswordButton_showsResetPasswordDialog() {
        // Click forgot password button
        onView(withId(R.id.forgot_password_button)).perform(click())
        
        // Verify reset password dialog is shown
        onView(withText(R.string.reset_password_title)).check(matches(isDisplayed()))
        onView(withId(R.id.email_input)).check(matches(isDisplayed()))
        onView(withId(R.id.send_reset_button)).check(matches(isDisplayed()))
    }
    
    // Custom matcher for TextInputLayout errors
    private fun hasTextInputLayoutErrorText(expectedErrorTextId: Int): Matcher<View> {
        return object : TypeSafeMatcher<View>() {
            override fun describeTo(description: Description) {
                description.appendText("has error text with id: $expectedErrorTextId")
            }
            
            override fun matchesSafely(item: View): Boolean {
                if (item !is TextInputLayout) {
                    return false
                }
                val errorText = item.error ?: return false
                val expectedErrorText = item.context.getString(expectedErrorTextId)
                return errorText.toString() == expectedErrorText
            }
        }
    }
} 