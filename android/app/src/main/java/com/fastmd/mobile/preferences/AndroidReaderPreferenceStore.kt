package com.fastmd.mobile.preferences

import android.content.Context
import androidx.datastore.preferences.core.edit
import androidx.datastore.preferences.core.stringPreferencesKey
import androidx.datastore.preferences.preferencesDataStore
import com.fastmd.mobile.core.reader.FontTier
import com.fastmd.mobile.core.reader.ReaderThemeMode
import java.io.IOException
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.catch
import kotlinx.coroutines.flow.map

private val Context.fastMdReaderPreferences by preferencesDataStore(
    name = "fastmd_reader_preferences",
)

class AndroidReaderPreferenceStore(
    context: Context,
) {
    private val dataStore = context.fastMdReaderPreferences

    val fontTier: Flow<FontTier> = dataStore.data
        .catch { throwable ->
            if (throwable is IOException) {
                emit(emptyPreferences())
            } else {
                throw throwable
            }
        }
        .map { preferences ->
            preferences[FontTierPreference]?.let { raw ->
                FontTier.entries.firstOrNull { tier -> tier.name == raw }
            } ?: FontTier.initial
        }

    val themeMode: Flow<ReaderThemeMode> = dataStore.data
        .catch { throwable ->
            if (throwable is IOException) {
                emit(emptyPreferences())
            } else {
                throw throwable
            }
        }
        .map { preferences ->
            preferences[ThemeModePreference]?.let { raw ->
                ReaderThemeMode.entries.firstOrNull { mode -> mode.name == raw }
            } ?: ReaderThemeMode.initial
        }

    suspend fun setFontTier(fontTier: FontTier) {
        dataStore.edit { preferences ->
            preferences[FontTierPreference] = fontTier.name
        }
    }

    suspend fun setThemeMode(themeMode: ReaderThemeMode) {
        dataStore.edit { preferences ->
            preferences[ThemeModePreference] = themeMode.name
        }
    }

    private companion object {
        val FontTierPreference = stringPreferencesKey("reader_font_tier")
        val ThemeModePreference = stringPreferencesKey("reader_theme_mode")

        fun emptyPreferences(): androidx.datastore.preferences.core.Preferences =
            androidx.datastore.preferences.core.emptyPreferences()
    }
}
