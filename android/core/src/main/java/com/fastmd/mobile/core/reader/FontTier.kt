package com.fastmd.mobile.core.reader

enum class FontTier(
    val bodySp: Int,
    val codeSp: Int,
    val lineHeightMultiplier: Float,
) {
    Compact(bodySp = 14, codeSp = 13, lineHeightMultiplier = 1.48f),
    Default(bodySp = 16, codeSp = 15, lineHeightMultiplier = 1.52f),
    Large(bodySp = 18, codeSp = 17, lineHeightMultiplier = 1.56f),
    Reader(bodySp = 21, codeSp = 19, lineHeightMultiplier = 1.60f);

    companion object {
        val initial: FontTier = Default
    }
}
