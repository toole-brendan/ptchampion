package com.example.ptchampion.domain.exercise.bluetooth

/**
 * Generic class to wrap data with its loading state
 */
sealed class Resource<T> {
    class Loading<T> : Resource<T>()
    data class Success<T>(val data: T) : Resource<T>()
    data class Error<T>(val message: String, val data: T? = null) : Resource<T>()
    
    companion object {
        fun <T> loading(): Resource<T> = Loading()
        fun <T> success(data: T): Resource<T> = Success(data)
        fun <T> error(message: String, data: T? = null): Resource<T> = Error(message, data)
    }
} 