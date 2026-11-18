package com.example.hostel_mess_app

import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val channelName = "com.example.hostel_mess_app/screen_security"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            channelName
        ).setMethodCallHandler { call, result ->

            when (call.method) {

                "enableSecure" -> {
                    window.addFlags(
                        WindowManager.LayoutParams.FLAG_SECURE
                    )
                    result.success(null)
                }

                "disableSecure" -> {
                    window.clearFlags(
                        WindowManager.LayoutParams.FLAG_SECURE
                    )
                    result.success(null)
                }

                else -> {
                    result.notImplemented()
                }
            }
        }
    }
}