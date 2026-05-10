package com.fastmd.mobile.core.theme

import androidx.compose.runtime.Immutable
import androidx.compose.runtime.staticCompositionLocalOf
import androidx.compose.ui.graphics.Color

@Immutable
data class FastMdSemanticColors(
    val background: Color,
    val foreground: Color,
    val muted: Color,
    val border: Color,
    val codeBackground: Color,
    val quoteBorder: Color,
    val link: Color,
    val danger: Color,
    val success: Color,
)

val LocalFastMdSemanticColors = staticCompositionLocalOf {
    FastMdSemanticColors(
        background = Color.White,
        foreground = Color.Black,
        muted = Color.DarkGray,
        border = Color.LightGray,
        codeBackground = Color(0xFFF1F3F0),
        quoteBorder = Color(0xFF265C8D),
        link = Color(0xFF265C8D),
        danger = Color(0xFFBA1A1A),
        success = Color(0xFF3E6B2B),
    )
}
