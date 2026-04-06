package com.storyteller.storyteller

import android.content.Context
import android.util.Log
import com.google.mlkit.genai.common.FeatureStatus
import com.google.mlkit.genai.prompt.Generation
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext

/**
 * MethodChannel bridge for on-device Gemini Nano via ML Kit GenAI Prompt API.
 *
 * Supported devices include Samsung Galaxy S25/S26 series, Pixel 9+, and others.
 * See: https://developers.google.com/ml-kit/genai/prompt/android
 *
 * Methods exposed to Flutter:
 *   checkAvailability() → Boolean
 *   checkStatus()       → String ("available"|"downloadable"|"downloading"|"unavailable")
 *   downloadModel()     → Boolean
 *   generate({prompt})  → String
 */
class GeminiNanoPlugin(private val context: Context) {

    companion object {
        const val CHANNEL = "com.storyteller.storyteller/gemini_nano"
        private const val TAG = "GeminiNanoPlugin"
    }

    private val scope = CoroutineScope(Dispatchers.IO)
    private val model by lazy { Generation.getClient() }

    fun register(flutterEngine: FlutterEngine) {
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "checkAvailability" -> {
                        scope.launch {
                            try {
                                val status = model.checkStatus()
                                val available = status == FeatureStatus.AVAILABLE
                                withContext(Dispatchers.Main) { result.success(available) }
                            } catch (e: Exception) {
                                Log.e(TAG, "checkAvailability failed", e)
                                withContext(Dispatchers.Main) { result.success(false) }
                            }
                        }
                    }

                    "checkStatus" -> {
                        scope.launch {
                            try {
                                val status = model.checkStatus()
                                val statusStr = when (status) {
                                    FeatureStatus.AVAILABLE -> "available"
                                    FeatureStatus.DOWNLOADABLE -> "downloadable"
                                    FeatureStatus.DOWNLOADING -> "downloading"
                                    else -> "unavailable"
                                }
                                withContext(Dispatchers.Main) { result.success(statusStr) }
                            } catch (e: Exception) {
                                Log.e(TAG, "checkStatus failed", e)
                                withContext(Dispatchers.Main) { result.success("unavailable") }
                            }
                        }
                    }

                    "downloadModel" -> {
                        scope.launch {
                            try {
                                val status = model.checkStatus()
                                if (status == FeatureStatus.DOWNLOADABLE) {
                                    // Start download in background, return true immediately.
                                    // Caller should poll checkStatus() to track progress.
                                    scope.launch {
                                        try { model.download().collect { _ -> } }
                                        catch (e: Exception) { Log.e(TAG, "Download error: ${e.message}") }
                                    }
                                    withContext(Dispatchers.Main) { result.success(true) }
                                } else {
                                    withContext(Dispatchers.Main) {
                                        result.success(status == FeatureStatus.AVAILABLE)
                                    }
                                }
                            } catch (e: Exception) {
                                Log.e(TAG, "downloadModel failed", e)
                                withContext(Dispatchers.Main) { result.success(false) }
                            }
                        }
                    }

                    "generate" -> {
                        val prompt = call.argument<String>("prompt")
                        if (prompt.isNullOrBlank()) {
                            result.error("INVALID_ARGS", "prompt is required", null)
                            return@setMethodCallHandler
                        }
                        scope.launch {
                            try {
                                val response = model.generateContent(prompt)
                                val text = response.candidates
                                    .firstOrNull()?.text ?: ""
                                withContext(Dispatchers.Main) { result.success(text) }
                            } catch (e: Exception) {
                                Log.e(TAG, "generate failed", e)
                                withContext(Dispatchers.Main) {
                                    result.error("GENERATE_ERROR", e.message ?: "Unknown error", null)
                                }
                            }
                        }
                    }

                    else -> result.notImplemented()
                }
            }
    }
}
