package com.fastmd.mobile.feature.library

import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable

@Composable
fun LibraryScreen() {
    Text(
        text = "Recent documents",
        style = MaterialTheme.typography.titleMedium,
    )
}
