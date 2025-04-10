package com.example.ptchampion.util

/**
 * A generic class that holds a value with its loading status.
 * @param <T> The type of data being held.
 */
sealed class Resource<T>(val data: T? = null, val message: String? = null) {
    class Success<T>(data: T) : Resource<T>(data)
    class Error<T>(message: String, data: T? = null) : Resource<T>(data, message)
    class Loading<T>(data: T? = null) : Resource<T>(data)
} 