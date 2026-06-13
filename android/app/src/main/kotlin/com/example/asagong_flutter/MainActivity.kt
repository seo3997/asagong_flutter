package com.example.asagong_flutter

import android.content.Intent
import android.net.Uri
import android.os.Bundle
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val TAG = "MainActivityDeepLink"
    private val CHANNEL = "com.example.asagong_flutter/deeplink"
    private var channel: MethodChannel? = null
    private var pendingData: String? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        Log.d(TAG, "configureFlutterEngine - registering MethodChannel")
        channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        
        channel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "getInitialLink" -> {
                    Log.d(TAG, "getInitialLink called. Returning pendingData: $pendingData")
                    result.success(pendingData)
                    pendingData = null
                }
                "parseIntent" -> {
                    val url = call.argument<String>("url")
                    Log.d(TAG, "parseIntent called for URL: $url")
                    if (url != null) {
                        try {
                            val intent = Intent.parseUri(url, Intent.URI_INTENT_SCHEME)
                            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                            
                            try {
                                Log.d(TAG, "parseIntent - starting activity natively")
                                startActivity(intent)
                                result.success(true)
                            } catch (e: Exception) {
                                Log.d(TAG, "parseIntent - direct launch failed: ${e.message}. Trying fallback/market.")
                                val fallbackUrl = intent.getStringExtra("browser_fallback_url")
                                if (fallbackUrl != null) {
                                    Log.d(TAG, "parseIntent - launching browser fallback: $fallbackUrl")
                                    val browserIntent = Intent(Intent.ACTION_VIEW, Uri.parse(fallbackUrl)).apply {
                                        addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                                    }
                                    startActivity(browserIntent)
                                    result.success(true)
                                } else {
                                    val packageName = intent.`package`
                                    if (packageName != null) {
                                        Log.d(TAG, "parseIntent - launching Play Store for package: $packageName")
                                        val marketIntent = Intent(Intent.ACTION_VIEW, Uri.parse("market://details?id=$packageName")).apply {
                                            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                                        }
                                        startActivity(marketIntent)
                                        result.success(true)
                                    } else {
                                        Log.d(TAG, "parseIntent - no fallback url or package name found")
                                        result.success(false)
                                    }
                                }
                            }
                        } catch (e: Exception) {
                            Log.e(TAG, "parseIntent - exception during Intent parseUri: ${e.message}")
                            result.error("ERROR", e.message, null)
                        }
                    } else {
                        result.error("BAD_ARGS", "URL is null", null)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        Log.d(TAG, "onCreate - intent: $intent, action: ${intent?.action}, data: ${intent?.dataString}")
        handleIntent(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        Log.d(TAG, "onNewIntent - intent: $intent, action: ${intent?.action}, data: ${intent?.dataString}")
        handleIntent(intent)
    }

    private fun handleIntent(intent: Intent) {
        val action = intent.action
        val data = intent.dataString
        Log.d(TAG, "handleIntent - action: $action, data: $data")
        if (Intent.ACTION_VIEW == action && data != null) {
            if (channel != null) {
                Log.d(TAG, "handleIntent - invokeMethod onLinkReceived: $data")
                channel?.invokeMethod("onLinkReceived", data)
            } else {
                Log.d(TAG, "handleIntent - channel is null, storing pendingData: $data")
                pendingData = data
            }
        }
    }
}
