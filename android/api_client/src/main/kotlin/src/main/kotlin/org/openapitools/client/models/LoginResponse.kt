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

import org.openapitools.client.models.User

import com.squareup.moshi.Json
import com.squareup.moshi.JsonClass
import java.io.Serializable

/**
 * Authentication token and user profile
 *
 * @param token 
 * @param user 
 */
@JsonClass(generateAdapter = true)

data class LoginResponse (

    @Json(name = "token")
    val token: kotlin.String,

    @Json(name = "user")
    val user: User

) : Serializable {
    companion object {
        private const val serialVersionUID: Long = 123
    }


}

