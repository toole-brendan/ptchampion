package com.example.ptchampion.data.repository

import com.example.ptchampion.data.datastore.AuthDataStore
import org.openapitools.client.apis.UsersApi
import com.example.ptchampion.domain.model.UpdateLocationRequest
import com.example.ptchampion.domain.model.UserProfile
import com.example.ptchampion.domain.repository.UserRepository
import com.example.ptchampion.util.Resource
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.firstOrNull
import retrofit2.HttpException
import java.io.IOException
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class UserRepositoryImpl @Inject constructor(
    private val usersApi: UsersApi,
    private val authDataStore: AuthDataStore
) : UserRepository {

    override fun getUserProfileFlow(): Flow<Resource<UserProfile>> {
         TODO("Implement user profile Flow, potentially from DataStore or local cache")
    }

    override suspend fun refreshUserProfile(): Resource<Unit> {
        TODO("Implement profile refresh from API")
    }

    override suspend fun updateUserLocation(request: UpdateLocationRequest): Resource<Unit> {
         // No need to check auth token here, as it should be added by an Authenticator/Interceptor
         return try {
            // NOTE: Assumes userApiService has updateUserLocation function
            // TODO: Update to use usersApi if that's the correct service
            val response = usersApi.usersMePatch() // Placeholder - adjust method call
            // Assuming the response indicates success/failure without needing specific body
            if (true) { // Replace with actual success check based on API response
                Resource.Success(Unit)
            } else {
                Resource.Error("API Error updating location") // Add details
            }
        } catch (e: HttpException) {
            Resource.Error("HTTP Error updating location: ${e.message()}")
        } catch (e: IOException) {
            Resource.Error("Network Error updating location: Could not reach server. ${e.message}")
        } catch (e: Exception) {
            Resource.Error("An unexpected error occurred updating location: ${e.message}")
        }
    }
} 