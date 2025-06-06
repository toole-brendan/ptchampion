/**
 *
 * Please note:
 * This class is auto generated by OpenAPI Generator (https://openapi-generator.tech).
 * Do not edit this file manually.
 *
 */

@file:Suppress(
    "ArrayInDataClass",
    "EnumEntryName",
    "RemoveRedundantQualifierName",
    "UnusedImport"
)

package org.openapitools.client.models


import com.squareup.moshi.Json
import com.squareup.moshi.JsonClass
import java.io.Serializable

/**
 * Fields to update in user profile
 *
 * @param username 
 * @param displayName 
 * @param profilePictureUrl 
 * @param location 
 * @param latitude 
 * @param longitude 
 */
@JsonClass(generateAdapter = true)

data class UpdateUserRequest (

    @Json(name = "username")
    val username: kotlin.String? = null,

    @Json(name = "display_name")
    val displayName: kotlin.String? = null,

    @Json(name = "profile_picture_url")
    val profilePictureUrl: java.net.URI? = null,

    @Json(name = "location")
    val location: kotlin.String? = null,

    @Json(name = "latitude")
    val latitude: java.math.BigDecimal? = null,

    @Json(name = "longitude")
    val longitude: java.math.BigDecimal? = null

) : Serializable {
    companion object {
        private const val serialVersionUID: Long = 123
    }


}

