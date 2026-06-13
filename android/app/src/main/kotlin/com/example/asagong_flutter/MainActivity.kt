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
                else -> result.notImplemented()
            }
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        val extrasInfo = intent?.extras?.keySet()?.joinToString(", ") ?: "null"
        Log.d(TAG, "onCreate - START. Intent: $intent, Action: ${intent?.action}, Data: ${intent?.dataString}, Extras: $extrasInfo")
        handleIntent(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        val extrasInfo = intent.extras?.keySet()?.joinToString(", ") ?: "null"
        Log.d(TAG, "onNewIntent - START. Intent: $intent, Action: ${intent.action}, Data: ${intent.dataString}, Extras: $extrasInfo")
        handleIntent(intent)
    }

    private fun handleIntent(intent: Intent?) {
        if (intent == null) {
            Log.d(TAG, "handleIntent - Intent is null")
            return
        }
        val action = intent.action
        val data = intent.dataString
        Log.d(TAG, "handleIntent - Processing Action: $action, DataString: $data")
        
        if (Intent.ACTION_VIEW == action && data != null) {
            Log.d(TAG, "handleIntent - Successfully cached deep link: $data")
            pendingData = data
            channel?.invokeMethod("onLinkReceived", data)
        } else {
            Log.d(TAG, "handleIntent - Deep link caching skipped. Condition check -> (Action is VIEW: ${Intent.ACTION_VIEW == action}, Data is not null: ${data != null})")
        }
    }
}
