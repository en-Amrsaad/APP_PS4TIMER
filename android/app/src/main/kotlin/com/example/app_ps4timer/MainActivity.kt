package com.example.app_ps4timer

import android.app.Activity
import android.content.Intent
import android.media.RingtoneManager
import android.net.Uri
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "ps4timer/alarm_sound"
    private var pendingResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getAlarmUri" -> {
                    // إبقاء الكود الخاص بك كما هو لجلب النغمة الافتراضية
                    result.success(Settings.System.DEFAULT_ALARM_ALERT_URI.toString())
                }
                "pickRingtone" -> {
                    // فتح نافذة اختيار النغمات
                    pendingResult = result
                    val intent = Intent(RingtoneManager.ACTION_RINGTONE_PICKER).apply {
                        putExtra(RingtoneManager.EXTRA_RINGTONE_TYPE, RingtoneManager.TYPE_ALARM or RingtoneManager.TYPE_NOTIFICATION)
                        putExtra(RingtoneManager.EXTRA_RINGTONE_SHOW_DEFAULT, true)
                        putExtra(RingtoneManager.EXTRA_RINGTONE_SHOW_SILENT, false)
                    }
                    startActivityForResult(intent, 199)
                }
                else -> result.notImplemented()
            }
        }
    }

    // استقبال النغمة التي اختارها المستخدم وإرسالها إلى Flutter
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == 199) {
            if (resultCode == Activity.RESULT_OK) {
                val uri: Uri? = data?.getParcelableExtra(RingtoneManager.EXTRA_RINGTONE_PICKED_URI)
                pendingResult?.success(uri?.toString())
            } else {
                pendingResult?.success(null)
            }
            pendingResult = null
        }
    }
}