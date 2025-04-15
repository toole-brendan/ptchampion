package com.example.ptchampion.data.network.generated.models

import com.squareup.moshi.JsonClass
import java.math.BigDecimal
import java.net.URI

@JsonClass(generateAdapter = true)
data class InsertUser(
    val username: String,
    val password: String,
    val displayName: String? = null,
    val profilePictureUrl: URI? = null,
    val location: String? = null,
    val latitude: BigDecimal? = null,
    val longitude: BigDecimal? = null
) 