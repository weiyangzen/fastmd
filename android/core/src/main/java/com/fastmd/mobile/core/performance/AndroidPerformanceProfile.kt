package com.fastmd.mobile.core.performance

data class AndroidDeviceProfileInputs(
    val apiLevel: Int,
    val isLowRamDevice: Boolean,
    val smallestScreenWidthDp: Int,
    val screenWidthDp: Int,
    val screenHeightDp: Int,
    val memoryClassMb: Int? = null,
) {
    init {
        require(apiLevel >= 27) { "Android Stage 1 profile inputs start at API 27." }
        require(smallestScreenWidthDp > 0) { "Smallest screen width must be positive." }
        require(screenWidthDp > 0) { "Screen width must be positive." }
        require(screenHeightDp > 0) { "Screen height must be positive." }
        require(memoryClassMb == null || memoryClassMb > 0) { "Memory class must be positive when present." }
    }
}

enum class AndroidPerformanceProfile(
    val fileSizeSoftLimitBytes: Long,
    val disableExpensiveAnimations: Boolean,
    val compactSpacing: Boolean,
    val remoteMediaEnabledByDefault: Boolean,
    val preferPlainFallbackForHeavyRichBlocks: Boolean,
) {
    WatchCompact(
        fileSizeSoftLimitBytes = 256L * 1024L,
        disableExpensiveAnimations = true,
        compactSpacing = true,
        remoteMediaEnabledByDefault = false,
        preferPlainFallbackForHeavyRichBlocks = true,
    ),
    LegacyEfficient(
        fileSizeSoftLimitBytes = 1L * 1024L * 1024L,
        disableExpensiveAnimations = true,
        compactSpacing = false,
        remoteMediaEnabledByDefault = false,
        preferPlainFallbackForHeavyRichBlocks = true,
    ),
    ModernStandard(
        fileSizeSoftLimitBytes = 5L * 1024L * 1024L,
        disableExpensiveAnimations = false,
        compactSpacing = false,
        remoteMediaEnabledByDefault = false,
        preferPlainFallbackForHeavyRichBlocks = false,
    ),
    LargeScreen(
        fileSizeSoftLimitBytes = 5L * 1024L * 1024L,
        disableExpensiveAnimations = false,
        compactSpacing = false,
        remoteMediaEnabledByDefault = false,
        preferPlainFallbackForHeavyRichBlocks = false,
    );
}

object AndroidPerformanceProfileSelector {
    fun select(inputs: AndroidDeviceProfileInputs): AndroidPerformanceProfile =
        when {
            inputs.smallestScreenWidthDp < WATCH_COMPACT_MAX_SW_DP -> AndroidPerformanceProfile.WatchCompact
            inputs.isLowRamDevice && inputs.smallestScreenWidthDp < PHONE_MIN_SW_DP ->
                AndroidPerformanceProfile.WatchCompact
            inputs.apiLevel <= LEGACY_MAX_API_LEVEL -> AndroidPerformanceProfile.LegacyEfficient
            inputs.isLowRamDevice -> AndroidPerformanceProfile.LegacyEfficient
            inputs.smallestScreenWidthDp >= LARGE_SCREEN_MIN_SW_DP -> AndroidPerformanceProfile.LargeScreen
            else -> AndroidPerformanceProfile.ModernStandard
        }

    private const val WATCH_COMPACT_MAX_SW_DP = 320
    private const val PHONE_MIN_SW_DP = 360
    private const val LEGACY_MAX_API_LEVEL = 28
    private const val LARGE_SCREEN_MIN_SW_DP = 600
}
