package com.wooftalk.voice.permission

import android.Manifest
import android.app.Activity
import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat

class AudioPermissionHandler(private val context: Context) {
    companion object {
        const val PERMISSION_REQUEST_CODE = 1001
        val REQUIRED_PERMISSIONS = mutableListOf(Manifest.permission.RECORD_AUDIO).apply {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                add(Manifest.permission.POST_NOTIFICATIONS)
            }
        }
    }

    fun hasAllPermissions(): Boolean = REQUIRED_PERMISSIONS.all {
        ContextCompat.checkSelfPermission(context, it) == PackageManager.PERMISSION_GRANTED
    }

    fun requestPermissions(activity: Activity) {
        val missing = REQUIRED_PERMISSIONS.filter {
            ContextCompat.checkSelfPermission(context, it) != PackageManager.PERMISSION_GRANTED
        }
        if (missing.isNotEmpty()) {
            ActivityCompat.requestPermissions(activity, missing.toTypedArray(), PERMISSION_REQUEST_CODE)
        }
    }

    fun shouldShowRationale(activity: Activity): Boolean = REQUIRED_PERMISSIONS.any {
        ActivityCompat.shouldShowRequestPermissionRationale(activity, it)
    }
}
