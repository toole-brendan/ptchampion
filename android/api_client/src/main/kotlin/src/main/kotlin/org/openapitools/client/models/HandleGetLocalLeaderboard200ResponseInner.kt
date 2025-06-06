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
 * 
 *
 * @param userId 
 * @param username 
 * @param exerciseId 
 * @param score 
 * @param displayName 
 */
@JsonClass(generateAdapter = true)

data class HandleGetLocalLeaderboard200ResponseInner (

    @Json(name = "userId")
    val userId: kotlin.Int,

    @Json(name = "username")
    val username: kotlin.String,

    @Json(name = "exerciseId")
    val exerciseId: kotlin.Int,

    @Json(name = "score")
    val score: kotlin.Int,

    @Json(name = "displayName")
    val displayName: kotlin.String? = null

) : Serializable {
    companion object {
        private const val serialVersionUID: Long = 123
    }


}

