// android/src/main/kotlin/com/example/flutter_ios_pdfkit/FlutterIosPdfkitPlugin.kt

package com.example.flutter_ios_pdfkit

import androidx.annotation.NonNull
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

/** FlutterIosPdfkitPlugin */
class FlutterIosPdfkitPlugin: FlutterPlugin, MethodCallHandler {
  /// The MethodChannel that will the communication between Flutter and native Android
  private lateinit var channel : MethodChannel

  override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    channel = MethodChannel(flutterPluginBinding.binaryMessenger, "interactive_pdf_viewer")
    channel.setMethodCallHandler(this)
  }

  override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
    // This is a stub implementation since this plugin is iOS-only
    if (call.method == "openPDF") {
      // Return an error indicating this is an iOS-only feature
      result.error(
        "UNSUPPORTED_OPERATION", 
        "The flutter_ios_pdfkit plugin is only supported on iOS", 
        null
      )
    } else {
      result.notImplemented()
    }
  }

  override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
  }
}