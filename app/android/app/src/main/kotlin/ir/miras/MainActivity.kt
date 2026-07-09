package ir.miras

import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // Answer feedback drives the vibrator service directly: Flutter's
        // HapticFeedback.*Impact maps to view-level effects that the system
        // "touch feedback" setting silently disables on many devices.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "miras/haptics")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "vibrate" -> {
                        val durationMs = (call.argument<Int>("durationMs") ?: 40).toLong()
                        val amplitude = call.argument<Int>("amplitude") ?: -1
                        vibrate(durationMs, amplitude)
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
        // System share sheet for the (opt-in) beta report export — one
        // intent, not worth a plugin dependency.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "miras/share")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "shareText" -> {
                        val intent = Intent(Intent.ACTION_SEND).apply {
                            type = "text/plain"
                            putExtra(Intent.EXTRA_TEXT, call.argument<String>("text") ?: "")
                            call.argument<String>("subject")?.let {
                                putExtra(Intent.EXTRA_SUBJECT, it)
                            }
                        }
                        startActivity(Intent.createChooser(intent, null))
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun vibrate(durationMs: Long, amplitude: Int) {
        val vibrator =
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                val manager =
                    getSystemService(Context.VIBRATOR_MANAGER_SERVICE) as VibratorManager
                manager.defaultVibrator
            } else {
                @Suppress("DEPRECATION")
                getSystemService(Context.VIBRATOR_SERVICE) as Vibrator
            }
        if (!vibrator.hasVibrator()) return
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val effectAmplitude =
                if (amplitude in 1..255) amplitude else VibrationEffect.DEFAULT_AMPLITUDE
            vibrator.vibrate(VibrationEffect.createOneShot(durationMs, effectAmplitude))
        } else {
            @Suppress("DEPRECATION")
            vibrator.vibrate(durationMs)
        }
    }
}
