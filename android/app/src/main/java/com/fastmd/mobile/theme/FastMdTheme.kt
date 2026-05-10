package com.fastmd.mobile.theme

import androidx.compose.material3.ColorScheme
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.darkColorScheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color
import com.fastmd.mobile.core.performance.AndroidPerformanceProfile
import com.fastmd.mobile.core.performance.LocalAndroidPerformanceProfile
import com.fastmd.mobile.core.reader.ReaderThemeMode
import com.fastmd.mobile.core.theme.FastMdSemanticColors
import com.fastmd.mobile.core.theme.LocalFastMdSemanticColors

@Composable
fun FastMdTheme(
    themeMode: ReaderThemeMode,
    performanceProfile: AndroidPerformanceProfile,
    content: @Composable () -> Unit,
) {
    val colorScheme = when (themeMode) {
        ReaderThemeMode.Light -> lightFastMdColorScheme
        ReaderThemeMode.Dark -> darkFastMdColorScheme
    }
    val semanticColors = when (themeMode) {
        ReaderThemeMode.Light -> lightSemanticColors
        ReaderThemeMode.Dark -> darkSemanticColors
    }

    androidx.compose.runtime.CompositionLocalProvider(
        LocalFastMdSemanticColors provides semanticColors,
        LocalAndroidPerformanceProfile provides performanceProfile,
    ) {
        MaterialTheme(
            colorScheme = colorScheme,
            content = content,
        )
    }
}

private val lightFastMdColorScheme: ColorScheme = lightColorScheme(
    primary = Color(0xFF265C8D),
    onPrimary = Color.White,
    primaryContainer = Color(0xFFD7E9FF),
    onPrimaryContainer = Color(0xFF0C2438),
    secondary = Color(0xFF5D6B38),
    onSecondary = Color.White,
    secondaryContainer = Color(0xFFE2EABC),
    onSecondaryContainer = Color(0xFF1C220C),
    tertiary = Color(0xFF7D4F21),
    onTertiary = Color.White,
    tertiaryContainer = Color(0xFFFFDCC0),
    onTertiaryContainer = Color(0xFF2D1601),
    background = Color(0xFFFCFCF8),
    onBackground = Color(0xFF1E1F1A),
    surface = Color(0xFFFCFCF8),
    onSurface = Color(0xFF1E1F1A),
    surfaceVariant = Color(0xFFE5E8DF),
    onSurfaceVariant = Color(0xFF474B41),
    outline = Color(0xFF787D70),
    outlineVariant = Color(0xFFC8CCC0),
    error = Color(0xFFBA1A1A),
    onError = Color.White,
    errorContainer = Color(0xFFFFDAD6),
    onErrorContainer = Color(0xFF410002),
)

private val darkFastMdColorScheme: ColorScheme = darkColorScheme(
    primary = Color(0xFFA3CDF7),
    onPrimary = Color(0xFF003354),
    primaryContainer = Color(0xFF164B73),
    onPrimaryContainer = Color(0xFFD7E9FF),
    secondary = Color(0xFFC6CE9F),
    onSecondary = Color(0xFF303711),
    secondaryContainer = Color(0xFF464F25),
    onSecondaryContainer = Color(0xFFE2EABC),
    tertiary = Color(0xFFF0BD8F),
    onTertiary = Color(0xFF48290B),
    tertiaryContainer = Color(0xFF623A10),
    onTertiaryContainer = Color(0xFFFFDCC0),
    background = Color(0xFF12130F),
    onBackground = Color(0xFFE5E3DA),
    surface = Color(0xFF12130F),
    onSurface = Color(0xFFE5E3DA),
    surfaceVariant = Color(0xFF474B41),
    onSurfaceVariant = Color(0xFFC8CCC0),
    outline = Color(0xFF929688),
    outlineVariant = Color(0xFF474B41),
    error = Color(0xFFFFB4AB),
    onError = Color(0xFF690005),
    errorContainer = Color(0xFF93000A),
    onErrorContainer = Color(0xFFFFDAD6),
)

private val lightSemanticColors = FastMdSemanticColors(
    background = Color(0xFFFCFCF8),
    foreground = Color(0xFF1E1F1A),
    muted = Color(0xFF5F6359),
    border = Color(0xFFC8CCC0),
    codeBackground = Color(0xFFECEFE7),
    quoteBorder = Color(0xFF265C8D),
    link = Color(0xFF265C8D),
    danger = Color(0xFFBA1A1A),
    success = Color(0xFF3E6B2B),
)

private val darkSemanticColors = FastMdSemanticColors(
    background = Color(0xFF12130F),
    foreground = Color(0xFFE5E3DA),
    muted = Color(0xFFC8CCC0),
    border = Color(0xFF474B41),
    codeBackground = Color(0xFF242821),
    quoteBorder = Color(0xFFA3CDF7),
    link = Color(0xFFA3CDF7),
    danger = Color(0xFFFFB4AB),
    success = Color(0xFFA8D28B),
)
