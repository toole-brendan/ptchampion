package com.example.ptchampion.utils

import android.content.Context
import android.graphics.Bitmap
import android.graphics.ImageFormat
import android.media.Image
import androidx.renderscript.Allocation
import androidx.renderscript.Element
import androidx.renderscript.RenderScript
import androidx.renderscript.ScriptIntrinsicYuvToRGB
import androidx.renderscript.Type
import java.nio.ByteBuffer
import android.util.Log

class YuvToRgbConverter(context: Context) {
    private val rs: RenderScript = RenderScript.create(context)
    private val scriptYuvToRgb: ScriptIntrinsicYuvToRGB = ScriptIntrinsicYuvToRGB.create(rs, Element.U8_4(rs))

    private var inputAllocation: Allocation? = null
    private var outputAllocation: Allocation? = null
    
    // Cached image dimensions
    private var lastImageWidth: Int = 0
    private var lastImageHeight: Int = 0

    @Synchronized
    fun yuvToRgb(image: Image, output: Bitmap) {
        val width = image.width
        val height = image.height

        // Check format outside allocation logic
        if (image.format != ImageFormat.YUV_420_888) {
            Log.e("YuvToRgbConverter", "Unsupported image format: ${image.format}")
            // Optionally throw an exception or handle gracefully
            // throw IllegalArgumentException("Unsupported image format: ${image.format}")
            return // Exit if format is wrong
        }

        // Create or update allocations only if dimensions change
        if (inputAllocation == null || lastImageWidth != width || lastImageHeight != height) {
            // Need a YUV Type for inputAllocation
            val yuvType = Type.Builder(rs, Element.U8(rs)).setX(width).setY(height)
                .setYuvFormat(ImageFormat.YUV_420_888).create()
            inputAllocation = Allocation.createTyped(rs, yuvType, Allocation.USAGE_SCRIPT)
            
            // Create output allocation based on bitmap
            outputAllocation = Allocation.createFromBitmap(rs, output)
            
            lastImageWidth = width
            lastImageHeight = height
            Log.d("YuvToRgbConverter", "Recreated allocations for size: ${width}x${height}")
        }

        // Process conversion
        inputAllocation?.copyFrom(image) // Use direct copyFrom for YUV_420_888
        scriptYuvToRgb.setInput(inputAllocation)
        scriptYuvToRgb.forEach(outputAllocation)
        outputAllocation?.copyTo(output)
    }

    // Removed getYuvBytes and related buffer logic as RenderScript handles YUV_420_888 directly

    // Add a close method to release RenderScript resources
    @Synchronized
    fun close() {
        inputAllocation?.destroy()
        outputAllocation?.destroy()
        scriptYuvToRgb.destroy()
        rs.destroy()
        inputAllocation = null
        outputAllocation = null
        Log.d("YuvToRgbConverter", "RenderScript resources released.")
    }
} 