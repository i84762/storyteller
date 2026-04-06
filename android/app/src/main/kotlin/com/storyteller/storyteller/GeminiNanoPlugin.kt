package com.storyteller.storyteller

import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext

/**
 * MethodChannel bridge for on-device Gemini Nano via Android AICore.
 *
 * The AICore library has no stable Maven coordinate yet.  Until one ships,
 * this plugin reports itself as unavailable so the Flutter layer can fall
 * back gracefully (see on_device_service.dart).
 *
 * When the official com.google.ai.edge.aicore artifact becomes available:
 *   1. Add the dependency to android/app/build.gradle.
 *   2. Replace the stub below with real GenerativeModel calls.
 */
class GeminiNanoPlugin {

    companion object {
        const val CHANNEL = "com.storyteller.storyteller/gemini_nano"
    }

    private val scope = CoroutineScope(Dispatchers.IO)

    fun register(flutterEngine: FlutterEngine) {
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "checkAvailability" -> {
                        // AICore library not linked — always report unavailable.
                        scope.launch {
                            withContext(Dispatchers.Main) { result.success(false) }
                        }
                    }
                    "generate" -> {
                        scope.launch {
                            withContext(Dispatchers.Main) {
                                result.error(
                                    "AICORE_UNAVAILABLE",
                                    "On-device AI is not available. Install Google AICore from the Play Store.",
                                    null
                                )
                            }
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }
}
