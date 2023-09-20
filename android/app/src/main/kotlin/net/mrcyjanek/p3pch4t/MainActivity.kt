package net.mrcyjanek.p3pch4t

import android.os.Build
import android.util.Log
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugins.GeneratedPluginRegistrant
import java.util.Arrays


class MainActivity: FlutterActivity() {
    private val CHANNEL = "net.mrcyjanek.p3pch4t/nativelibrarydir"
    
    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        Log.d("p3pmainactivity", "loading");
        super.configureFlutterEngine(flutterEngine)
        GeneratedPluginRegistrant.registerWith(flutterEngine);
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler {
            call, result ->
            Log.d("p3pmainactivity", call.method);
            if (call.method == "getAndroidNativeLibraryDirectory") {
                result.success(applicationInfo.nativeLibraryDir.toString())
                Log.d("p3pmainactivity", applicationInfo.nativeLibraryDir);
            } else {
                result.notImplemented()
            }
        }
    }

    private fun getNativeArch(): String? {
        // Note that we cannot use System.getProperty("os.arch") since that may give e.g. "aarch64"
        // while a 64-bit runtime may not be installed (like on the Samsung Galaxy S5 Neo).
        // Instead we search through the supported abi:s on the device, see:
        // http://developer.android.com/ndk/guides/abis.html
        // Note that we search for abi:s in preferred order (the ordering of the
        // Build.SUPPORTED_ABIS list) to avoid e.g. installing arm on an x86 system where arm
        // emulation is available.
        for (androidArch in Build.SUPPORTED_ABIS) {
            when (androidArch) {
                "arm64-v8a" -> return "arm64"
                "armeabi-v7a" -> return "armeabi"
                "x86_64" -> return "x86_64"
                "x86" -> return "x86"
            }
        }
        throw RuntimeException(
            "Unable to determine arch from Build.SUPPORTED_ABIS =  " +
                    Arrays.toString(Build.SUPPORTED_ABIS)
        )
    }
}