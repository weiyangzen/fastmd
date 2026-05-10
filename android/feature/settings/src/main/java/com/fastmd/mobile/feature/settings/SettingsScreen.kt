package com.fastmd.mobile.feature.settings

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.horizontalScroll
import androidx.compose.material3.Button
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import com.fastmd.mobile.core.reader.ReaderThemeMode

@Composable
fun SettingsScreen(
    selectedThemeMode: ReaderThemeMode,
    diagnosticsReport: String,
    onThemeModeSelected: (ReaderThemeMode) -> Unit,
) {
    Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
        Text(
            text = "Theme",
            style = MaterialTheme.typography.titleMedium,
        )
        Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
            ReaderThemeMode.entries.forEach { mode ->
                val modifier = Modifier
                    .heightIn(min = 44.dp)
                    .padding(vertical = 2.dp)
                if (mode == selectedThemeMode) {
                    Button(
                        modifier = modifier,
                        onClick = { onThemeModeSelected(mode) },
                    ) {
                        Text(text = mode.name)
                    }
                } else {
                    OutlinedButton(
                        modifier = modifier,
                        onClick = { onThemeModeSelected(mode) },
                    ) {
                        Text(text = mode.name)
                    }
                }
            }
        }
        Text(
            text = "Diagnostics",
            style = MaterialTheme.typography.titleMedium,
        )
        Text(
            modifier = Modifier
                .fillMaxWidth()
                .horizontalScroll(rememberScrollState()),
            text = diagnosticsReport,
            style = MaterialTheme.typography.bodySmall,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
        )
    }
}
