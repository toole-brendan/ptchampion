package com.example.ptchampion.domain.exercise.bluetooth

import com.example.ptchampion.domain.util.Resource

/**
 * Type alias pointing to the main Resource class
 * This helps migrate code that was using the duplicate Resource class
 */
typealias Resource<T> = com.example.ptchampion.domain.util.Resource<T>

/**
 * Extension functions to provide convenient factory methods
 * These maintain compatibility with existing code
 */
object ResourceHelpers {
    fun <T> loading(data: T? = null): Resource<T> = Resource.Loading(data)
    fun <T> success(data: T): Resource<T> = Resource.Success(data)
    fun <T> error(message: String, data: T? = null): Resource<T> = Resource.Error(message, data)
} 