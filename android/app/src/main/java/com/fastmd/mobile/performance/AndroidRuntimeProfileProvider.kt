package com.fastmd.mobile.performance

import android.app.ActivityManager
import android.content.Context
import android.os.Build
import com.fastmd.mobile.core.performance.AndroidDeviceProfileInputs
import com.fastmd.mobile.core.performance.AndroidPerformanceProfile
import com.fastmd.mobile.core.performance.AndroidPerformanceProfileSelector

object AndroidRuntimeProfileProvider {
    fun select(context: Context): AndroidPerformanceProfile {
        val configuration = context.resources.configuration
        val activityManager = context.getSystemService(Context.ACTIVITY_SERVICE) as? ActivityManager
        val screenWidthDp = configuration.screenWidthDp.takeIf { it > 0 } ?: DEFAULT_PHONE_WIDTH_DP
        val screenHeightDp = configuration.screenHeightDp.takeIf { it > 0 } ?: DEFAULT_PHONE_HEIGHT_DP
        val smallestScreenWidthDp = configuration.smallestScreenWidthDp.takeIf { it > 0 }
            ?: minOf(screenWidthDp, screenHeightDp)

        return AndroidPerformanceProfileSelector.select(
            AndroidDeviceProfileInputs(
                apiLevel = Build.VERSION.SDK_INT.coerceAtLeast(MIN_SUPPORTED_API),
                isLowRamDevice = activityManager?.isLowRamDevice ?: false,
                smallestScreenWidthDp = smallestScreenWidthDp,
                screenWidthDp = screenWidthDp,
                screenHeightDp = screenHeightDp,
                memoryClassMb = activityManager?.memoryClass,
            ),
        )
    }

    private const val MIN_SUPPORTED_API = 27
    private const val DEFAULT_PHONE_WIDTH_DP = 360
    private const val DEFAULT_PHONE_HEIGHT_DP = 640
}
