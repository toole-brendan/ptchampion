package com.example.ptchampion.data.network.generated.models

import com.squareup.moshi.JsonClass

@JsonClass(generateAdapter = true)
data class LoginResponse(
    val token: String,
    val user: User
) 