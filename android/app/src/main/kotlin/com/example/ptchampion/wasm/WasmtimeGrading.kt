package com.example.ptchampion.wasm

import android.content.Context
import android.util.Log
import com.example.ptchampion.domain.model.Joint
import com.example.ptchampion.domain.model.Pose
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import org.json.JSONArray
import org.json.JSONObject
import java.io.File
import java.io.FileOutputStream
import org.wasmtime.Config
import org.wasmtime.Engine
import org.wasmtime.Func
import org.wasmtime.Linker
import org.wasmtime.Module
import org.wasmtime.Store
import org.wasmtime.WasmFunctions
import org.wasmtime.Extern

/**
 * WasmtimeGrading provides a JNI interface to the Go-compiled grading WASM module
 * using Wasmtime for WASM execution on Android.
 */
class WasmtimeGrading private constructor(context: Context) {
    companion object {
        private const val TAG = "WasmtimeGrading"
        private const val WASM_FILE_NAME = "grading.wasm"
        
        @Volatile
        private var instance: WasmtimeGrading? = null
        
        fun getInstance(context: Context): WasmtimeGrading {
            return instance ?: synchronized(this) {
                instance ?: WasmtimeGrading(context.applicationContext).also { instance = it }
            }
        }
    }
    
    private val wasmFile: File
    private var engine: Engine? = null
    private var store: Store<Void>? = null
    private var module: Module? = null
    private var linker: Linker? = null
    private var calculateScoreFunc: Func? = null
    private var gradePushupPoseFunc: Func? = null
    private var initialized = false
    private val initLock = Object()
    
    init {
        // Copy WASM file from assets to internal storage for Wasmtime access
        wasmFile = File(context.filesDir, WASM_FILE_NAME)
        if (!wasmFile.exists()) {
            copyWasmFromAssets(context)
        }
    }
    
    private fun copyWasmFromAssets(context: Context) {
        try {
            context.assets.open(WASM_FILE_NAME).use { input ->
                FileOutputStream(wasmFile).use { output ->
                    input.copyTo(output)
                }
            }
            Log.d(TAG, "WASM file copied from assets")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to copy WASM file from assets", e)
            throw RuntimeException("Failed to copy WASM file from assets", e)
        }
    }
    
    /**
     * Initialize the Wasmtime engine and load the WASM module
     */
    suspend fun initialize() = withContext(Dispatchers.IO) {
        synchronized(initLock) {
            if (initialized) return@withContext
            
            try {
                // Configure Wasmtime
                val config = Config()
                engine = Engine(config)
                store = Store(engine!!)
                
                // Load WASM module
                module = Module.fromFile(engine!!, wasmFile.absolutePath)
                
                // Create linker and add WASI
                linker = Linker(engine!!)
                
                // Add environment functions if needed
                // e.g., linker.define("env", "log", ...)
                
                // Instantiate module
                val instance = linker!!.instantiate(store!!, module!!)
                
                // Get exported functions
                calculateScoreFunc = instance.getFunc(store!!, "calculateExerciseScore")
                gradePushupPoseFunc = instance.getFunc(store!!, "gradePushupPose")
                
                if (calculateScoreFunc == null || gradePushupPoseFunc == null) {
                    throw RuntimeException("Required WASM functions not found")
                }
                
                initialized = true
                Log.d(TAG, "WASM grading module initialized successfully")
            } catch (e: Exception) {
                Log.e(TAG, "Failed to initialize WASM grading module", e)
                throw RuntimeException("Failed to initialize WASM module", e)
            }
        }
    }
    
    /**
     * Calculate score for an exercise performance
     */
    suspend fun calculateScore(exerciseType: String, performanceValue: Float): Int = withContext(Dispatchers.IO) {
        ensureInitialized()
        
        try {
            // Create callback to receive result from WASM
            var result = -1
            val callback = WasmFunctions.wrap(store!!, Extern.fromFunc(store!!), { score: Int ->
                result = score
                Unit
            })
            
            // Call WASM function
            val exerciseTypePtr = allocateString(exerciseType)
            calculateScoreFunc!!.call(store!!, exerciseTypePtr, performanceValue.toDouble(), callback)
            
            if (result < 0) {
                throw RuntimeException("Invalid score result")
            }
            
            return@withContext result
        } catch (e: Exception) {
            Log.e(TAG, "Error calculating score", e)
            throw RuntimeException("Failed to calculate score", e)
        }
    }
    
    /**
     * Grade a push-up pose for form analysis and rep counting
     */
    suspend fun gradePushupPose(pose: Pose, stateJson: String? = null): PushupGradingResult = withContext(Dispatchers.IO) {
        ensureInitialized()
        
        try {
            // Convert pose to JSON
            val poseJson = convertPoseToJson(pose)
            
            // Create callback to receive result from WASM
            var resultJson: String? = null
            val callback = WasmFunctions.wrap(store!!, Extern.fromFunc(store!!), { jsonPtr: Int ->
                resultJson = readString(jsonPtr)
                Unit
            })
            
            // Call WASM function
            val poseJsonPtr = allocateString(poseJson)
            val stateJsonPtr = if (stateJson != null) allocateString(stateJson) else 0
            gradePushupPoseFunc!!.call(store!!, poseJsonPtr, stateJsonPtr, callback)
            
            if (resultJson == null) {
                throw RuntimeException("No result received from WASM")
            }
            
            return@withContext parseGradingResult(resultJson!!)
        } catch (e: Exception) {
            Log.e(TAG, "Error grading push-up pose", e)
            throw RuntimeException("Failed to grade push-up pose", e)
        }
    }
    
    private suspend fun ensureInitialized() {
        if (!initialized) {
            initialize()
        }
    }
    
    // Helper functions for WASM memory manipulation
    
    private fun allocateString(str: String): Int {
        // TODO: Implement memory allocation in WASM
        // This would involve using exported memory allocation functions from the WASM module
        return 0 // Placeholder
    }
    
    private fun readString(ptr: Int): String {
        // TODO: Implement reading strings from WASM memory
        return "{}" // Placeholder
    }
    
    private fun convertPoseToJson(pose: Pose): String {
        val jsonObject = JSONObject()
        val keypointsArray = JSONArray()
        
        pose.joints.forEach { joint ->
            val jointObject = JSONObject()
            jointObject.put("name", joint.name)
            jointObject.put("x", joint.x)
            jointObject.put("y", joint.y)
            jointObject.put("confidence", joint.confidence)
            keypointsArray.put(jointObject)
        }
        
        jsonObject.put("keypoints", keypointsArray)
        return jsonObject.toString()
    }
    
    private fun parseGradingResult(json: String): PushupGradingResult {
        val jsonObject = JSONObject(json)
        
        val success = jsonObject.getBoolean("success")
        if (!success) {
            val error = jsonObject.optString("error", "Unknown error")
            throw RuntimeException("WASM error: $error")
        }
        
        val resultObj = jsonObject.getJSONObject("result")
        val repCount = jsonObject.getInt("repCount")
        val state = jsonObject.getString("state")
        
        val feedbackArray = resultObj.getJSONArray("feedback")
        val feedback = mutableListOf<String>()
        for (i in 0 until feedbackArray.length()) {
            feedback.add(feedbackArray.getString(i))
        }
        
        return PushupGradingResult(
            isValid = resultObj.getBoolean("isValid"),
            repCounted = resultObj.getBoolean("repCounted"),
            formScore = resultObj.getDouble("formScore").toFloat(),
            feedback = feedback,
            repCount = repCount,
            state = state
        )
    }
}

/**
 * Result data class for push-up grading
 */
data class PushupGradingResult(
    val isValid: Boolean,
    val repCounted: Boolean,
    val formScore: Float,
    val feedback: List<String>,
    val repCount: Int,
    val state: String
) 