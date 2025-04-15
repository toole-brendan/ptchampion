package com.example.ptchampion.domain.model

/**
 * Request model for updating user location
 *
 * @param latitude Latitude (WGS 84)
 * @param longitude Longitude (WGS 84)
 */
data class UpdateLocationRequest(
    val latitude: Double,
    val longitude: Double
) 