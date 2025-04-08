package com.example.ptchampion.data.repository

import com.example.ptchampion.domain.model.UserProfile
import com.example.ptchampion.domain.repository.UserRepository
import com.example.ptchampion.domain.util.Resource
import org.openapitools.client.apis.UsersApi // Import the API
import org.openapitools.client.models.User // Assuming this is the DTO model
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.map
import javax.inject.Inject
import javax.inject.Singleton
import retrofit2.HttpException // Import for error handling
import java.io.IOException // Import for error handling

// TODO: Potentially add local caching (Room) later
@Singleton
class UserRepositoryImpl @Inject constructor(
    private val usersApi: UsersApi // Inject the Retrofit API interface
) : UserRepository {

    // Simulate a simple in-memory cache for now - could be replaced/augmented by Room later
    private val _userProfileFlow = MutableStateFlow<Resource<UserProfile>>(Resource.Loading())

    // Removed initial placeholder data, will be loaded by refresh

    override fun getUserProfileFlow(): Flow<Resource<UserProfile>> {
        return _userProfileFlow.asStateFlow()
    }

    override suspend fun refreshUserProfile(): Resource<Unit> {
        _userProfileFlow.value = Resource.Loading(
            data = _userProfileFlow.value.data // Keep previous data while loading
        )
        return try {
            // Call the actual API endpoint - replace `getCurrentUserProfile` if the method name differs
            val response = usersApi.getCurrentUserProfile() // Assuming this method exists

            // Assuming the response is the User DTO directly (adjust if nested)
            val userDto = response
            _userProfileFlow.value = Resource.Success(userDto.toDomainModel()) // Map DTO to Domain Model
            Resource.Success(Unit)

        } catch (e: HttpException) {
            // Handle HTTP errors (e.g., 4xx, 5xx)
            val errorMessage = "HTTP Error: ${e.code()} ${e.message()}"
            _userProfileFlow.value = Resource.Error(
                message = errorMessage,
                data = _userProfileFlow.value.data
            )
            Resource.Error(errorMessage)
        } catch (e: IOException) {
            // Handle network errors (e.g., no connection)
            val errorMessage = "Network Error: ${e.localizedMessage}"
            _userProfileFlow.value = Resource.Error(
                message = errorMessage,
                data = _userProfileFlow.value.data
            )
            Resource.Error(errorMessage)
        } catch (e: Exception) {
            // Handle other unexpected errors (e.g., serialization issues)
            val errorMessage = "An unexpected error occurred: ${e.localizedMessage}"
            _userProfileFlow.value = Resource.Error(
                message = errorMessage,
                data = _userProfileFlow.value.data
            )
            Resource.Error(errorMessage)
        }
    }

    // --- Mapping Function --- 
    // TODO: Implement mapping from the generated DTO (e.g., User) to the domain model (UserProfile)
    private fun User.toDomainModel(): UserProfile {
        // This is a placeholder implementation - adjust based on actual DTO fields
        return UserProfile(
            userId = this.id ?: "", // Assuming DTO has 'id'
            email = this.email ?: "", // Assuming DTO has 'email'
            name = this.name // Assuming DTO has 'name'
        )
    }
} 