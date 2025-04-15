package com.example.ptchampion.data.network.dto

import kotlinx.serialization.Serializable

@Serializable
data class LoginResponseDto(
    val token: String,
    val user: UserDto // Uses the UserDto defined previously
)
