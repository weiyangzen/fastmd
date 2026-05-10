package com.fastmd.mobile.feature.reader

import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.net.Uri
import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.Image
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.lazy.rememberLazyListState
import androidx.compose.foundation.rememberScrollState
import androidx.compose.material3.Button
import androidx.compose.material3.Checkbox
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.TextField
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.produceState
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.runtime.snapshotFlow
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.asImageBitmap
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.text.AnnotatedString
import androidx.compose.ui.text.SpanStyle
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.BaselineShift
import androidx.compose.ui.text.style.TextDecoration
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.platform.LocalClipboardManager
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalUriHandler
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.semantics.LiveRegionMode
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.heading
import androidx.compose.ui.semantics.liveRegion
import androidx.compose.ui.semantics.paneTitle
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.fastmd.mobile.core.document.RecentDocumentMetadata
import com.fastmd.mobile.core.performance.LocalAndroidPerformanceProfile
import com.fastmd.mobile.core.reader.FontTier
import com.fastmd.mobile.core.reader.ReaderThemeMode
import com.fastmd.mobile.core.reader.ReaderUiState
import com.fastmd.mobile.core.render.MarkdownInlineStyle
import com.fastmd.mobile.core.render.MarkdownLinkDecision
import com.fastmd.mobile.core.render.MarkdownBlockId
import com.fastmd.mobile.core.render.MarkdownBlockKind
import com.fastmd.mobile.core.render.MarkdownInlineSpan
import com.fastmd.mobile.core.render.MarkdownRenderBlock
import com.fastmd.mobile.core.render.MarkdownRenderModel
import com.fastmd.mobile.core.search.ReaderSearchEngine
import com.fastmd.mobile.core.theme.LocalFastMdSemanticColors
import java.io.File
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.distinctUntilChanged
import kotlinx.coroutines.withContext

data class RecoveryDraftPrompt(
    val label: String,
    val title: String,
)

@Composable
fun ReaderScreen(
    state: ReaderUiState,
    recentDocuments: List<RecentDocumentMetadata>,
    recoveryDraftPrompt: RecoveryDraftPrompt?,
    currentFontTier: FontTier,
    currentThemeMode: ReaderThemeMode,
    onOpenDocument: () -> Unit,
    onOpenRecent: (RecentDocumentMetadata) -> Unit,
    onFontTierSelected: (FontTier) -> Unit,
    onThemeModeSelected: (ReaderThemeMode) -> Unit,
    onSearchQueryChanged: (String) -> Unit,
    onSearchPrevious: () -> Unit,
    onSearchNext: () -> Unit,
    onSearchClear: () -> Unit,
    onVisibleBlockChanged: (MarkdownBlockId) -> Unit,
    onEditSource: () -> Unit,
    onEditBlock: (MarkdownBlockId) -> Unit,
    onSourceDraftChanged: (String) -> Unit,
    onSaveSource: () -> Unit,
    onCancelSourceEdit: () -> Unit,
    onBlockDraftChanged: (String) -> Unit,
    onSaveBlock: () -> Unit,
    onCancelBlockEdit: () -> Unit,
    onRestoreRecoveryDraft: () -> Unit,
    onDeleteRecoveryDraft: () -> Unit,
) {
    when (state) {
        ReaderUiState.Empty -> EmptyReader(
            recentDocuments = recentDocuments,
            recoveryDraftPrompt = recoveryDraftPrompt,
            currentFontTier = currentFontTier,
            currentThemeMode = currentThemeMode,
            onOpenDocument = onOpenDocument,
            onOpenRecent = onOpenRecent,
            onRestoreRecoveryDraft = onRestoreRecoveryDraft,
            onDeleteRecoveryDraft = onDeleteRecoveryDraft,
            onFontTierSelected = onFontTierSelected,
            onThemeModeSelected = onThemeModeSelected,
        )
        is ReaderUiState.Ready -> ReadyReader(
            state = state,
            searchState = SearchUiState.Empty,
            onOpenDocument = onOpenDocument,
            onFontTierSelected = onFontTierSelected,
            currentThemeMode = currentThemeMode,
            onThemeModeSelected = onThemeModeSelected,
            onSearchQueryChanged = onSearchQueryChanged,
            onSearchPrevious = onSearchPrevious,
            onSearchNext = onSearchNext,
            onSearchClear = onSearchClear,
            onVisibleBlockChanged = onVisibleBlockChanged,
            onEditSource = onEditSource,
            onEditBlock = onEditBlock,
        )
        is ReaderUiState.Error -> ErrorReader(state, currentFontTier, onOpenDocument)
        is ReaderUiState.PermissionLost -> PermissionLostReader(state, currentFontTier, onOpenDocument)
        is ReaderUiState.ReadOnly -> ReadyReader(
            state = state.ready,
            searchState = SearchUiState.Empty,
            onOpenDocument = onOpenDocument,
            onFontTierSelected = onFontTierSelected,
            currentThemeMode = currentThemeMode,
            onThemeModeSelected = onThemeModeSelected,
            onSearchQueryChanged = onSearchQueryChanged,
            onSearchPrevious = onSearchPrevious,
            onSearchNext = onSearchNext,
            onSearchClear = onSearchClear,
            onVisibleBlockChanged = onVisibleBlockChanged,
            onEditSource = onEditSource,
            onEditBlock = onEditBlock,
        )
        is ReaderUiState.Searching -> ReadyReader(
            state = state.ready,
            searchState = SearchUiState.Active(
                query = state.query,
                resultCount = state.resultCount,
                activeResultIndex = state.activeResultIndex,
            ),
            onOpenDocument = onOpenDocument,
            onFontTierSelected = onFontTierSelected,
            currentThemeMode = currentThemeMode,
            onThemeModeSelected = onThemeModeSelected,
            onSearchQueryChanged = onSearchQueryChanged,
            onSearchPrevious = onSearchPrevious,
            onSearchNext = onSearchNext,
            onSearchClear = onSearchClear,
            onVisibleBlockChanged = onVisibleBlockChanged,
            onEditSource = onEditSource,
            onEditBlock = onEditBlock,
        )
        is ReaderUiState.Rendering -> ReaderProgress(
            title = "Rendering ${state.document.title}",
            fontTier = state.fontTier,
        )
        is ReaderUiState.EditingSource -> SourceEditor(
            state = state,
            onDraftChanged = onSourceDraftChanged,
            onSave = onSaveSource,
            onCancel = onCancelSourceEdit,
        )
        is ReaderUiState.EditingBlock -> BlockEditor(
            state = state,
            onDraftChanged = onBlockDraftChanged,
            onSave = onSaveBlock,
            onCancel = onCancelBlockEdit,
        )
        is ReaderUiState.Saving -> ReaderProgress(
            title = "Saving ${state.document.title}",
            fontTier = currentFontTier,
        )
        is ReaderUiState.Loading -> ReaderProgress(
            title = "Loading ${state.displayName ?: "document"}",
            fontTier = currentFontTier,
        )
    }
}

@Composable
private fun EmptyReader(
    recentDocuments: List<RecentDocumentMetadata>,
    recoveryDraftPrompt: RecoveryDraftPrompt?,
    currentFontTier: FontTier,
    currentThemeMode: ReaderThemeMode,
    onOpenDocument: () -> Unit,
    onOpenRecent: (RecentDocumentMetadata) -> Unit,
    onRestoreRecoveryDraft: () -> Unit,
    onDeleteRecoveryDraft: () -> Unit,
    onFontTierSelected: (FontTier) -> Unit,
    onThemeModeSelected: (ReaderThemeMode) -> Unit,
) {
    Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
        Text(
            modifier = Modifier.semantics { heading() },
            text = "No document open",
            style = MaterialTheme.typography.titleLarge.withFontTier(currentFontTier, scale = 1.25f),
        )
        Button(onClick = onOpenDocument) {
            Text(text = "Open Markdown")
        }
        if (recoveryDraftPrompt != null) {
            Surface(
                modifier = Modifier.fillMaxWidth(),
                border = BorderStroke(1.dp, MaterialTheme.colorScheme.outlineVariant),
                shape = MaterialTheme.shapes.small,
            ) {
                Column(
                    modifier = Modifier.padding(12.dp),
                    verticalArrangement = Arrangement.spacedBy(8.dp),
                ) {
                    Text(
                        text = recoveryDraftPrompt.label,
                        style = MaterialTheme.typography.titleMedium.withFontTier(currentFontTier, scale = 1.05f),
                    )
                    Text(
                        text = recoveryDraftPrompt.title,
                        style = MaterialTheme.typography.bodyMedium.withFontTier(currentFontTier),
                        maxLines = 2,
                        overflow = TextOverflow.Ellipsis,
                    )
                    Row(
                        modifier = Modifier.horizontalScroll(rememberScrollState()),
                        horizontalArrangement = Arrangement.spacedBy(8.dp),
                    ) {
                        Button(onClick = onRestoreRecoveryDraft) {
                            Text(text = "Restore")
                        }
                        OutlinedButton(onClick = onDeleteRecoveryDraft) {
                            Text(text = "Delete")
                        }
                    }
                }
            }
        }
        FontTierControls(
            selected = currentFontTier,
            onSelected = onFontTierSelected,
        )
        ThemeModeControls(
            selected = currentThemeMode,
            onSelected = onThemeModeSelected,
        )
        if (recentDocuments.isNotEmpty()) {
            Text(
                modifier = Modifier.semantics { heading() },
                text = "Recent documents",
                style = MaterialTheme.typography.titleMedium.withFontTier(currentFontTier, scale = 1.1f),
            )
            recentDocuments.forEach { recent ->
                OutlinedButton(
                    modifier = Modifier
                        .fillMaxWidth()
                        .heightIn(min = 44.dp),
                    onClick = { onOpenRecent(recent) },
                ) {
                    Text(
                        text = recent.displayName ?: "Markdown document",
                        style = MaterialTheme.typography.bodyMedium.withFontTier(currentFontTier),
                        maxLines = 2,
                        overflow = TextOverflow.Ellipsis,
                    )
                }
            }
        }
    }
}

@Composable
private fun ReadyReader(
    state: ReaderUiState.Ready,
    searchState: SearchUiState,
    onOpenDocument: () -> Unit,
    onFontTierSelected: (FontTier) -> Unit,
    currentThemeMode: ReaderThemeMode,
    onThemeModeSelected: (ReaderThemeMode) -> Unit,
    onSearchQueryChanged: (String) -> Unit,
    onSearchPrevious: () -> Unit,
    onSearchNext: () -> Unit,
    onSearchClear: () -> Unit,
    onVisibleBlockChanged: (MarkdownBlockId) -> Unit,
    onEditSource: () -> Unit,
    onEditBlock: (MarkdownBlockId) -> Unit,
) {
    val fontTier = state.fontTier
    val performanceProfile = LocalAndroidPerformanceProfile.current
    val blockSpacing = if (performanceProfile.compactSpacing) 6.dp else 10.dp
    val readerMaxHeight = if (performanceProfile.compactSpacing) 360.dp else 420.dp
    val activeSearch = searchState as? SearchUiState.Active
    val blockSearchOffsets = remember(state.renderModel, activeSearch?.query) {
        activeSearch
            ?.let { ReaderSearchHighlightPlanner.blockMatchOffsets(state.renderModel, it.query) }
            .orEmpty()
    }
    val initialScrollIndex = remember(state.renderModel, state.scrollBlockId) {
        state.scrollBlockId?.let { id ->
            state.renderModel.blocks.indexOfFirst { block -> block.id == id }
        }?.takeIf { it >= 0 } ?: 0
    }
    val lazyListState = rememberLazyListState(initialFirstVisibleItemIndex = initialScrollIndex)
    LaunchedEffect(state.document.title, state.renderModel.sourceRevision) {
        lazyListState.scrollToItem(initialScrollIndex)
    }
    LaunchedEffect(lazyListState, state.renderModel) {
        snapshotFlow { lazyListState.firstVisibleItemIndex }
            .distinctUntilChanged()
            .collect { index ->
                state.renderModel.blocks.getOrNull(index)?.id?.let(onVisibleBlockChanged)
            }
    }
    Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
        Text(
            modifier = Modifier.semantics { heading() },
            text = state.document.title,
            style = MaterialTheme.typography.titleLarge.withFontTier(fontTier, scale = 1.25f),
            maxLines = 2,
            overflow = TextOverflow.Ellipsis,
        )
        Text(
            text = "${state.document.lineCount} lines loaded",
            style = MaterialTheme.typography.bodyMedium.withFontTier(fontTier, scale = 0.9f),
        )
        if (state.isDirty) {
            Text(
                modifier = Modifier.dirtyWarningSemantics("Unsaved changes"),
                text = "Unsaved changes",
                style = MaterialTheme.typography.labelMedium.withFontTier(fontTier, scale = 0.82f),
                color = MaterialTheme.colorScheme.error,
            )
        }
        FontTierControls(
            selected = fontTier,
            onSelected = onFontTierSelected,
        )
        ThemeModeControls(
            selected = currentThemeMode,
            onSelected = onThemeModeSelected,
        )
        SearchControls(
            searchState = searchState,
            fontTier = fontTier,
            onQueryChanged = onSearchQueryChanged,
            onPrevious = onSearchPrevious,
            onNext = onSearchNext,
            onClear = onSearchClear,
        )
        Surface(
            modifier = Modifier
                .fillMaxWidth()
                .heightIn(min = 120.dp, max = readerMaxHeight),
            tonalElevation = 1.dp,
            shape = MaterialTheme.shapes.small,
        ) {
            LazyColumn(
                modifier = Modifier
                    .padding(12.dp),
                state = lazyListState,
                verticalArrangement = Arrangement.spacedBy(blockSpacing),
            ) {
                items(
                    items = state.renderModel.blocks,
                    key = { block -> block.id.value },
                ) { block ->
                    Column(verticalArrangement = Arrangement.spacedBy(6.dp)) {
                        MarkdownBlockPreview(
                            block = block,
                            fontTier = fontTier,
                            searchHighlight = activeSearch?.toHighlightSpec(blockSearchOffsets[block.id] ?: 0),
                        )
                        OutlinedButton(onClick = { onEditBlock(block.id) }) {
                            Text(text = "Edit Block")
                        }
                    }
                }
            }
        }
        Row(
            modifier = Modifier.horizontalScroll(rememberScrollState()),
            horizontalArrangement = Arrangement.spacedBy(8.dp),
        ) {
            OutlinedButton(onClick = onEditSource) {
                Text(text = "Edit Source")
            }
            OutlinedButton(onClick = onOpenDocument) {
                Text(text = "Open Another")
            }
        }
    }
}

@Composable
private fun SourceEditor(
    state: ReaderUiState.EditingSource,
    onDraftChanged: (String) -> Unit,
    onSave: () -> Unit,
    onCancel: () -> Unit,
) {
    val fontTier = state.fontTier
    Column(
        modifier = Modifier.semantics { paneTitle = "Full source editor" },
        verticalArrangement = Arrangement.spacedBy(8.dp),
    ) {
        Text(
            modifier = Modifier.semantics { heading() },
            text = state.document.title,
            style = MaterialTheme.typography.titleLarge.withFontTier(fontTier, scale = 1.25f),
            maxLines = 2,
            overflow = TextOverflow.Ellipsis,
        )
        Text(
            modifier = if (state.isDirty) {
                Modifier.dirtyWarningSemantics("Unsaved source changes")
            } else {
                Modifier
            },
            text = if (state.isDirty) "Unsaved changes" else "No unsaved changes",
            style = MaterialTheme.typography.labelMedium.withFontTier(fontTier, scale = 0.82f),
            color = if (state.isDirty) MaterialTheme.colorScheme.error else MaterialTheme.colorScheme.onSurfaceVariant,
        )
        if (!state.document.isWritable) {
            Text(
                text = "Opened read-only",
                style = MaterialTheme.typography.bodySmall.withFontTier(fontTier, scale = 0.88f),
                color = MaterialTheme.colorScheme.onSurfaceVariant,
            )
        }
        state.saveErrorMessage?.let { message ->
            Text(
                modifier = Modifier.dirtyWarningSemantics("Source save warning: $message"),
                text = message,
                style = MaterialTheme.typography.bodySmall.withFontTier(fontTier, scale = 0.88f),
                color = MaterialTheme.colorScheme.error,
            )
        }
        TextField(
            modifier = Modifier
                .fillMaxWidth()
                .heightIn(min = 320.dp, max = 560.dp)
                .testTag("source-editor-field"),
            value = state.draftSource,
            onValueChange = onDraftChanged,
            textStyle = MaterialTheme.typography.bodyMedium
                .withFontTier(fontTier)
                .copy(fontFamily = FontFamily.Monospace),
            minLines = 14,
            maxLines = 28,
            label = { Text(text = "Markdown source") },
        )
        Row(
            modifier = Modifier.horizontalScroll(rememberScrollState()),
            horizontalArrangement = Arrangement.spacedBy(8.dp),
        ) {
            Button(
                enabled = state.isDirty && state.document.isWritable,
                onClick = onSave,
            ) {
                Text(text = "Save")
            }
            OutlinedButton(onClick = onCancel) {
                Text(text = "Cancel")
            }
        }
    }
}

@Composable
private fun BlockEditor(
    state: ReaderUiState.EditingBlock,
    onDraftChanged: (String) -> Unit,
    onSave: () -> Unit,
    onCancel: () -> Unit,
) {
    val fontTier = state.fontTier
    Column(
        modifier = Modifier.semantics { paneTitle = "Block source editor" },
        verticalArrangement = Arrangement.spacedBy(8.dp),
    ) {
        Text(
            modifier = Modifier.semantics { heading() },
            text = state.document.title,
            style = MaterialTheme.typography.titleLarge.withFontTier(fontTier, scale = 1.25f),
            maxLines = 2,
            overflow = TextOverflow.Ellipsis,
        )
        Text(
            text = "Block lines ${state.originalSourceRange.startLine}-${state.originalSourceRange.endLineInclusive}",
            style = MaterialTheme.typography.labelMedium.withFontTier(fontTier, scale = 0.82f),
            color = MaterialTheme.colorScheme.onSurfaceVariant,
        )
        Text(
            modifier = if (state.isDirty) {
                Modifier.dirtyWarningSemantics("Unsaved block changes")
            } else {
                Modifier
            },
            text = if (state.isDirty) "Unsaved block changes" else "No unsaved block changes",
            style = MaterialTheme.typography.labelMedium.withFontTier(fontTier, scale = 0.82f),
            color = if (state.isDirty) MaterialTheme.colorScheme.error else MaterialTheme.colorScheme.onSurfaceVariant,
        )
        if (!state.document.isWritable) {
            Text(
                text = "Opened read-only",
                style = MaterialTheme.typography.bodySmall.withFontTier(fontTier, scale = 0.88f),
                color = MaterialTheme.colorScheme.onSurfaceVariant,
            )
        }
        state.saveErrorMessage?.let { message ->
            Text(
                modifier = Modifier.dirtyWarningSemantics("Block save warning: $message"),
                text = message,
                style = MaterialTheme.typography.bodySmall.withFontTier(fontTier, scale = 0.88f),
                color = MaterialTheme.colorScheme.error,
            )
        }
        TextField(
            modifier = Modifier
                .fillMaxWidth()
                .heightIn(min = 260.dp, max = 460.dp)
                .testTag("block-editor-field"),
            value = state.draftSource,
            onValueChange = onDraftChanged,
            textStyle = MaterialTheme.typography.bodyMedium
                .withFontTier(fontTier)
                .copy(fontFamily = FontFamily.Monospace),
            minLines = 10,
            maxLines = 22,
            label = { Text(text = "Block source") },
        )
        Row(
            modifier = Modifier.horizontalScroll(rememberScrollState()),
            horizontalArrangement = Arrangement.spacedBy(8.dp),
        ) {
            Button(
                enabled = state.isDirty && state.document.isWritable,
                onClick = onSave,
            ) {
                Text(text = "Save Block")
            }
            OutlinedButton(onClick = onCancel) {
                Text(text = "Cancel")
            }
        }
    }
}

@Composable
private fun SearchControls(
    searchState: SearchUiState,
    fontTier: FontTier,
    onQueryChanged: (String) -> Unit,
    onPrevious: () -> Unit,
    onNext: () -> Unit,
    onClear: () -> Unit,
) {
    val query = when (searchState) {
        SearchUiState.Empty -> ""
        is SearchUiState.Active -> searchState.query
    }
    val resultCount = (searchState as? SearchUiState.Active)?.resultCount ?: 0
    val activeResultIndex = (searchState as? SearchUiState.Active)?.activeResultIndex

    Column(verticalArrangement = Arrangement.spacedBy(6.dp)) {
        TextField(
            modifier = Modifier
                .fillMaxWidth()
                .testTag("reader-search-field"),
            value = query,
            onValueChange = onQueryChanged,
            singleLine = true,
            label = { Text(text = "Search") },
        )
        Row(
            modifier = Modifier.horizontalScroll(rememberScrollState()),
            horizontalArrangement = Arrangement.spacedBy(8.dp),
        ) {
            OutlinedButton(
                enabled = resultCount > 0,
                onClick = onPrevious,
            ) {
                Text(text = "Previous")
            }
            OutlinedButton(
                enabled = resultCount > 0,
                onClick = onNext,
            ) {
                Text(text = "Next")
            }
            OutlinedButton(
                enabled = query.isNotBlank(),
                onClick = onClear,
            ) {
                Text(text = "Clear")
            }
        }
        if (query.isNotBlank()) {
            val resultSummary = if (resultCount == 0) {
                "No matches"
            } else {
                "${activeResultIndex?.plus(1) ?: 0} of $resultCount matches"
            }
            Text(
                modifier = Modifier.semantics {
                    liveRegion = LiveRegionMode.Polite
                    contentDescription = "Search results: $resultSummary"
                },
                text = resultSummary,
                style = MaterialTheme.typography.labelMedium.withFontTier(fontTier, scale = 0.82f),
                color = MaterialTheme.colorScheme.onSurfaceVariant,
            )
        }
    }
}

private sealed interface SearchUiState {
    data object Empty : SearchUiState

    data class Active(
        val query: String,
        val resultCount: Int,
        val activeResultIndex: Int?,
    ) : SearchUiState
}

private data class SearchHighlightSpec(
    val query: String,
    val activeResultIndex: Int?,
    val firstGlobalMatchIndex: Int,
) {
    fun sliceFor(
        parentText: String,
        startOffset: Int,
    ): SearchHighlightSpec =
        copy(
            firstGlobalMatchIndex = firstGlobalMatchIndex +
                ReaderSearchHighlightPlanner.matchCountBeforeOffset(parentText, query, startOffset),
        )
}

private fun SearchUiState.Active.toHighlightSpec(firstGlobalMatchIndex: Int): SearchHighlightSpec =
    SearchHighlightSpec(
        query = query,
        activeResultIndex = activeResultIndex,
        firstGlobalMatchIndex = firstGlobalMatchIndex,
    )

@Composable
private fun FontTierControls(
    selected: FontTier,
    onSelected: (FontTier) -> Unit,
) {
    Row(
        modifier = Modifier.horizontalScroll(rememberScrollState()),
        horizontalArrangement = Arrangement.spacedBy(8.dp),
    ) {
        FontTier.entries.forEach { tier ->
            val label = tier.name
            if (tier == selected) {
                Button(onClick = { onSelected(tier) }) {
                    Text(text = label)
                }
            } else {
                OutlinedButton(onClick = { onSelected(tier) }) {
                    Text(text = label)
                }
            }
        }
    }
}

@Composable
private fun ThemeModeControls(
    selected: ReaderThemeMode,
    onSelected: (ReaderThemeMode) -> Unit,
) {
    Row(
        modifier = Modifier.horizontalScroll(rememberScrollState()),
        horizontalArrangement = Arrangement.spacedBy(8.dp),
    ) {
        ReaderThemeMode.entries.forEach { mode ->
            val label = mode.name
            if (mode == selected) {
                Button(onClick = { onSelected(mode) }) {
                    Text(text = label)
                }
            } else {
                OutlinedButton(onClick = { onSelected(mode) }) {
                    Text(text = label)
                }
            }
        }
    }
}

@Composable
private fun ReaderProgress(
    title: String,
    fontTier: FontTier,
) {
    Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
        Text(
            modifier = Modifier.semantics { heading() },
            text = title,
            style = MaterialTheme.typography.titleMedium.withFontTier(fontTier, scale = 1.1f),
        )
        Text(
            text = "Please wait",
            style = MaterialTheme.typography.bodyMedium.withFontTier(fontTier),
            color = MaterialTheme.colorScheme.onSurfaceVariant,
        )
    }
}

private fun Modifier.dirtyWarningSemantics(description: String): Modifier =
    semantics {
        liveRegion = LiveRegionMode.Assertive
        contentDescription = description
    }

@Composable
private fun MarkdownBlockPreview(
    block: MarkdownRenderBlock,
    fontTier: FontTier,
    searchHighlight: SearchHighlightSpec?,
) {
    when (block.kind) {
        MarkdownBlockKind.Heading -> {
            val level = block.attributes["level"]?.toIntOrNull() ?: 1
            val style = when (level) {
                1 -> MaterialTheme.typography.headlineSmall.withFontTier(fontTier, scale = 1.55f)
                2 -> MaterialTheme.typography.titleLarge.withFontTier(fontTier, scale = 1.35f)
                3 -> MaterialTheme.typography.titleMedium.withFontTier(fontTier, scale = 1.2f)
                else -> MaterialTheme.typography.titleSmall.withFontTier(fontTier, scale = 1.08f)
            }
            MarkdownText(block = block, style = style, searchHighlight = searchHighlight)
        }

        MarkdownBlockKind.HorizontalRule -> HorizontalDivider()
        MarkdownBlockKind.Blockquote -> BlockquoteBlock(block, fontTier, searchHighlight)
        MarkdownBlockKind.UnorderedList,
        MarkdownBlockKind.OrderedList,
        MarkdownBlockKind.TaskList,
        -> ListBlock(block, fontTier, searchHighlight)
        MarkdownBlockKind.Table -> TableBlock(block, fontTier, searchHighlight)
        MarkdownBlockKind.CodeFence,
        MarkdownBlockKind.Mermaid,
        MarkdownBlockKind.MathBlock,
        -> CodeLikeBlock(block, fontTier, searchHighlight)
        MarkdownBlockKind.Image -> ImageBlock(block, fontTier, searchHighlight)
        MarkdownBlockKind.VideoHtml -> MediaPlaceholderBlock(block, fontTier, searchHighlight)
        MarkdownBlockKind.Footnote -> FootnoteBlock(block, fontTier, searchHighlight)
        MarkdownBlockKind.Details -> DetailsBlock(block, fontTier, searchHighlight)
        MarkdownBlockKind.HtmlFallback -> SafeFallbackBlock(block, fontTier, searchHighlight)

        else -> MarkdownText(
            block = block,
            style = MaterialTheme.typography.bodyMedium.withFontTier(fontTier),
            searchHighlight = searchHighlight,
        )
    }
}

@Composable
private fun MarkdownText(
    block: MarkdownRenderBlock,
    style: TextStyle,
    searchHighlight: SearchHighlightSpec?,
) {
    MarkdownStyledText(
        plainText = block.plainText,
        inlineSpans = block.inlineSpans,
        style = style,
        searchHighlight = searchHighlight,
    )
}

@Composable
private fun MarkdownStyledText(
    plainText: String,
    inlineSpans: List<MarkdownInlineSpan>,
    style: TextStyle,
    searchHighlight: SearchHighlightSpec?,
) {
    val semanticColors = LocalFastMdSemanticColors.current
    Text(
        text = toAnnotatedString(
            plainText = plainText,
            inlineSpans = inlineSpans,
            linkColor = semanticColors.link,
            blockedLinkColor = semanticColors.danger,
            confirmLinkColor = MaterialTheme.colorScheme.tertiary,
            codeBackgroundColor = semanticColors.codeBackground,
            markBackgroundColor = MaterialTheme.colorScheme.secondaryContainer,
            searchHighlightColor = MaterialTheme.colorScheme.primaryContainer,
            activeSearchHighlightColor = MaterialTheme.colorScheme.tertiaryContainer,
            searchHighlight = searchHighlight,
        ),
        style = style,
    )
}

@Composable
private fun BlockquoteBlock(
    block: MarkdownRenderBlock,
    fontTier: FontTier,
    searchHighlight: SearchHighlightSpec?,
) {
    val semanticColors = LocalFastMdSemanticColors.current
    Surface(
        modifier = Modifier.fillMaxWidth(),
        tonalElevation = 1.dp,
        shape = MaterialTheme.shapes.small,
    ) {
        Column(
            modifier = Modifier.padding(horizontal = 10.dp, vertical = 8.dp),
            verticalArrangement = Arrangement.spacedBy(6.dp),
        ) {
            var lineStartOffset = 0
            block.plainText.lines().forEach { rawLine ->
                if (rawLine.isBlank()) {
                    lineStartOffset += rawLine.length + 1
                    return@forEach
                }
                val quoteLine = rawLine.toQuoteLine()
                val textStartOffset = lineStartOffset + rawLine.indexOf(quoteLine.text).coerceAtLeast(0)
                Row(horizontalArrangement = Arrangement.spacedBy(6.dp)) {
                    repeat(quoteLine.depth) {
                        Surface(
                            modifier = Modifier
                                .width(3.dp)
                                .heightIn(min = 18.dp),
                            color = semanticColors.quoteBorder,
                        ) {}
                    }
                    Text(
                        text = toAnnotatedString(
                            plainText = quoteLine.text,
                            inlineSpans = emptyList(),
                            linkColor = MaterialTheme.colorScheme.primary,
                            blockedLinkColor = MaterialTheme.colorScheme.error,
                            confirmLinkColor = MaterialTheme.colorScheme.tertiary,
                            codeBackgroundColor = MaterialTheme.colorScheme.surfaceVariant,
                            markBackgroundColor = MaterialTheme.colorScheme.secondaryContainer,
                            searchHighlightColor = MaterialTheme.colorScheme.primaryContainer,
                            activeSearchHighlightColor = MaterialTheme.colorScheme.tertiaryContainer,
                            searchHighlight = searchHighlight?.sliceFor(block.plainText, textStartOffset),
                        ),
                        style = MaterialTheme.typography.bodyMedium.withFontTier(fontTier),
                        color = MaterialTheme.colorScheme.onSurfaceVariant,
                    )
                }
                lineStartOffset += rawLine.length + 1
            }
        }
    }
}

@Composable
private fun ListBlock(
    block: MarkdownRenderBlock,
    fontTier: FontTier,
    searchHighlight: SearchHighlightSpec?,
) {
    Column(verticalArrangement = Arrangement.spacedBy(6.dp)) {
        block.plainText.toListItems(block.kind)
            .forEach { item ->
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(start = (item.depth * 16).dp),
                    horizontalArrangement = Arrangement.spacedBy(8.dp),
                ) {
                    if (item.checked != null) {
                        Checkbox(
                            checked = item.checked,
                            onCheckedChange = null,
                            modifier = Modifier.width(32.dp),
                        )
                    } else {
                        Text(
                            modifier = Modifier.widthIn(min = 24.dp),
                            text = item.marker,
                            style = MaterialTheme.typography.bodyMedium.withFontTier(fontTier),
                            fontWeight = FontWeight.SemiBold,
                        )
                    }
                    MarkdownStyledText(
                        plainText = item.text,
                        inlineSpans = block.inlineSpans.sliceFor(item.textStartOffset, item.textEndOffsetExclusive),
                        style = MaterialTheme.typography.bodyMedium.withFontTier(fontTier),
                        searchHighlight = searchHighlight?.sliceFor(block.plainText, item.textStartOffset),
                    )
                }
            }
    }
}

@Composable
private fun TableBlock(
    block: MarkdownRenderBlock,
    fontTier: FontTier,
    searchHighlight: SearchHighlightSpec?,
) {
    val rows = block.plainText.toTableRows()
    if (rows.isEmpty()) {
        SafeFallbackBlock(block, fontTier, searchHighlight)
        return
    }

    Surface(
        modifier = Modifier.fillMaxWidth(),
        tonalElevation = 1.dp,
        shape = MaterialTheme.shapes.small,
    ) {
        Column(
            modifier = Modifier
                .horizontalScroll(rememberScrollState())
                .padding(8.dp),
            verticalArrangement = Arrangement.spacedBy(6.dp),
        ) {
            rows.forEachIndexed { rowIndex, row ->
                Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    row.forEach { cell ->
                        Text(
                            modifier = Modifier
                                .widthIn(min = 96.dp, max = 220.dp)
                                .padding(vertical = 4.dp),
                            text = toAnnotatedString(
                                plainText = cell,
                                inlineSpans = emptyList(),
                                linkColor = MaterialTheme.colorScheme.primary,
                                blockedLinkColor = MaterialTheme.colorScheme.error,
                                confirmLinkColor = MaterialTheme.colorScheme.tertiary,
                                codeBackgroundColor = MaterialTheme.colorScheme.surfaceVariant,
                                markBackgroundColor = MaterialTheme.colorScheme.secondaryContainer,
                                searchHighlightColor = MaterialTheme.colorScheme.primaryContainer,
                                activeSearchHighlightColor = MaterialTheme.colorScheme.tertiaryContainer,
                                searchHighlight = searchHighlight,
                            ),
                            style = MaterialTheme.typography.bodySmall.withFontTier(fontTier, scale = 0.88f),
                            fontWeight = if (rowIndex == 0) FontWeight.SemiBold else null,
                        )
                    }
                }
                if (rowIndex == 0) {
                    HorizontalDivider()
                }
            }
        }
    }
}

@Composable
private fun CodeLikeBlock(
    block: MarkdownRenderBlock,
    fontTier: FontTier,
    searchHighlight: SearchHighlightSpec?,
) {
    val clipboardManager = LocalClipboardManager.current
    val semanticColors = LocalFastMdSemanticColors.current
    val label = when (block.kind) {
        MarkdownBlockKind.Mermaid -> "Mermaid diagram source"
        MarkdownBlockKind.MathBlock -> "Math source"
        else -> block.attributes["language"]?.takeIf { it.isNotBlank() } ?: "Code"
    }

    Surface(
        modifier = Modifier.fillMaxWidth(),
        tonalElevation = 2.dp,
        shape = MaterialTheme.shapes.small,
        color = semanticColors.codeBackground,
    ) {
        Column(
            modifier = Modifier.padding(10.dp),
            verticalArrangement = Arrangement.spacedBy(8.dp),
        ) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
            ) {
                Text(
                    text = label,
                    style = MaterialTheme.typography.labelMedium.withFontTier(fontTier, scale = 0.82f),
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                )
                OutlinedButton(
                    onClick = {
                        clipboardManager.setText(AnnotatedString(block.plainText))
                    },
                ) {
                    Text(text = "Copy")
                }
            }
            Box(modifier = Modifier.horizontalScroll(rememberScrollState())) {
                Text(
                    text = toAnnotatedString(
                        plainText = block.plainText,
                        inlineSpans = emptyList(),
                        linkColor = MaterialTheme.colorScheme.primary,
                        blockedLinkColor = MaterialTheme.colorScheme.error,
                        confirmLinkColor = MaterialTheme.colorScheme.tertiary,
                        codeBackgroundColor = MaterialTheme.colorScheme.surfaceVariant,
                        markBackgroundColor = MaterialTheme.colorScheme.secondaryContainer,
                        searchHighlightColor = MaterialTheme.colorScheme.primaryContainer,
                        activeSearchHighlightColor = MaterialTheme.colorScheme.tertiaryContainer,
                        searchHighlight = searchHighlight,
                    ),
                    style = MaterialTheme.typography.bodySmall.withFontTier(fontTier, code = true),
                    fontFamily = FontFamily.Monospace,
                )
            }
        }
    }
}

@Composable
private fun ImageBlock(
    block: MarkdownRenderBlock,
    fontTier: FontTier,
    searchHighlight: SearchHighlightSpec?,
) {
    val context = LocalContext.current
    val source = block.attributes["src"].orEmpty()
    val alt = block.attributes["alt"] ?: block.plainText
    val sourceKind = block.attributes["sourceKind"].orEmpty()
    val documentBaseUri = block.attributes["documentBaseUri"].orEmpty()
    val uriHandler = LocalUriHandler.current
    val resolvedSource = remember(source, sourceKind, documentBaseUri) {
        resolveLocalImageSource(
            source = source,
            sourceKind = sourceKind,
            documentBaseUri = documentBaseUri,
        )
    }
    val bitmap by produceState<Bitmap?>(
        initialValue = null,
        key1 = resolvedSource,
        key2 = context,
    ) {
        value = resolvedSource?.let { source ->
            withContext(Dispatchers.IO) {
                decodeBoundedBitmap(context, source)
            }
        }
    }

    Surface(
        modifier = Modifier.fillMaxWidth(),
        tonalElevation = 1.dp,
        shape = MaterialTheme.shapes.small,
        border = BorderStroke(1.dp, MaterialTheme.colorScheme.outlineVariant),
    ) {
        Column(
            modifier = Modifier.padding(10.dp),
            verticalArrangement = Arrangement.spacedBy(6.dp),
        ) {
            val decodedBitmap = bitmap
            if (decodedBitmap != null) {
                Image(
                    bitmap = decodedBitmap.asImageBitmap(),
                    contentDescription = alt.ifBlank { "Markdown image" },
                    modifier = Modifier
                        .fillMaxWidth()
                        .heightIn(max = 320.dp),
                    contentScale = ContentScale.Fit,
                )
            } else {
                Text(
                    text = when (sourceKind) {
                        "remote" -> "Remote image"
                        "relative" -> "Local image reference"
                        else -> "Image"
                    },
                    style = MaterialTheme.typography.labelMedium.withFontTier(fontTier, scale = 0.82f),
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                )
                Text(
                    text = toAnnotatedString(
                        plainText = alt.ifBlank { source.ifBlank { "Image source unavailable" } },
                        inlineSpans = emptyList(),
                        linkColor = MaterialTheme.colorScheme.primary,
                        blockedLinkColor = MaterialTheme.colorScheme.error,
                        confirmLinkColor = MaterialTheme.colorScheme.tertiary,
                        codeBackgroundColor = MaterialTheme.colorScheme.surfaceVariant,
                        markBackgroundColor = MaterialTheme.colorScheme.secondaryContainer,
                        searchHighlightColor = MaterialTheme.colorScheme.primaryContainer,
                        activeSearchHighlightColor = MaterialTheme.colorScheme.tertiaryContainer,
                        searchHighlight = searchHighlight,
                    ),
                    style = MaterialTheme.typography.bodyMedium.withFontTier(fontTier),
                )
            }
            if (source.isNotBlank()) {
                Box(
                    modifier = Modifier
                        .fillMaxWidth()
                        .horizontalScroll(rememberScrollState()),
                ) {
                    Text(
                        text = if (sourceKind == "remote") {
                            "Remote images are not fetched automatically."
                        } else if (resolvedSource != null && resolvedSource != source) {
                            resolvedSource
                        } else {
                            source
                        },
                        style = MaterialTheme.typography.bodySmall.withFontTier(fontTier, code = sourceKind != "remote"),
                        color = MaterialTheme.colorScheme.onSurfaceVariant,
                        fontFamily = if (sourceKind == "remote") null else FontFamily.Monospace,
                    )
                }
            }
            if (sourceKind == "remote" && source.isNotBlank()) {
                OutlinedButton(onClick = { uriHandler.openUri(source) }) {
                    Text(text = "Open")
                }
            }
        }
    }
}

@Composable
private fun MediaPlaceholderBlock(
    block: MarkdownRenderBlock,
    fontTier: FontTier,
    searchHighlight: SearchHighlightSpec?,
) {
    Surface(
        modifier = Modifier.fillMaxWidth(),
        tonalElevation = 1.dp,
        shape = MaterialTheme.shapes.small,
        border = BorderStroke(1.dp, MaterialTheme.colorScheme.outlineVariant),
    ) {
        Column(
            modifier = Modifier.padding(10.dp),
            verticalArrangement = Arrangement.spacedBy(6.dp),
        ) {
            Text(
                text = block.attributes["label"] ?: "Media",
                style = MaterialTheme.typography.labelMedium.withFontTier(fontTier, scale = 0.82f),
                color = MaterialTheme.colorScheme.onSurfaceVariant,
            )
            Text(
                text = toAnnotatedString(
                    plainText = "Media playback is represented as a safe placeholder.",
                    inlineSpans = emptyList(),
                    linkColor = MaterialTheme.colorScheme.primary,
                    blockedLinkColor = MaterialTheme.colorScheme.error,
                    confirmLinkColor = MaterialTheme.colorScheme.tertiary,
                    codeBackgroundColor = MaterialTheme.colorScheme.surfaceVariant,
                    markBackgroundColor = MaterialTheme.colorScheme.secondaryContainer,
                    searchHighlightColor = MaterialTheme.colorScheme.primaryContainer,
                    activeSearchHighlightColor = MaterialTheme.colorScheme.tertiaryContainer,
                    searchHighlight = searchHighlight,
                ),
                style = MaterialTheme.typography.bodyMedium.withFontTier(fontTier),
            )
            block.attributes["src"]?.takeIf { it.isNotBlank() }?.let { source ->
                Box(
                    modifier = Modifier
                        .fillMaxWidth()
                        .horizontalScroll(rememberScrollState()),
                ) {
                    Text(
                        text = source,
                        style = MaterialTheme.typography.bodySmall.withFontTier(fontTier, code = true),
                        fontFamily = FontFamily.Monospace,
                        color = MaterialTheme.colorScheme.onSurfaceVariant,
                    )
                }
            }
        }
    }
}

@Composable
private fun FootnoteBlock(
    block: MarkdownRenderBlock,
    fontTier: FontTier,
    searchHighlight: SearchHighlightSpec?,
) {
    Surface(
        modifier = Modifier.fillMaxWidth(),
        tonalElevation = 1.dp,
        shape = MaterialTheme.shapes.small,
        color = MaterialTheme.colorScheme.secondaryContainer,
    ) {
        Column(
            modifier = Modifier.padding(10.dp),
            verticalArrangement = Arrangement.spacedBy(4.dp),
        ) {
            Text(
                text = block.attributes["label"]?.let { "Footnote $it" } ?: "Footnote",
                style = MaterialTheme.typography.labelMedium.withFontTier(fontTier, scale = 0.82f),
                color = MaterialTheme.colorScheme.onSecondaryContainer,
            )
            Text(
                text = toAnnotatedString(
                    plainText = block.plainText,
                    inlineSpans = emptyList(),
                    linkColor = MaterialTheme.colorScheme.primary,
                    blockedLinkColor = MaterialTheme.colorScheme.error,
                    confirmLinkColor = MaterialTheme.colorScheme.tertiary,
                    codeBackgroundColor = MaterialTheme.colorScheme.surfaceVariant,
                    markBackgroundColor = MaterialTheme.colorScheme.secondaryContainer,
                    searchHighlightColor = MaterialTheme.colorScheme.primaryContainer,
                    activeSearchHighlightColor = MaterialTheme.colorScheme.tertiaryContainer,
                    searchHighlight = searchHighlight,
                ),
                style = MaterialTheme.typography.bodySmall.withFontTier(fontTier, scale = 0.88f),
                color = MaterialTheme.colorScheme.onSecondaryContainer,
            )
        }
    }
}

@Composable
private fun DetailsBlock(
    block: MarkdownRenderBlock,
    fontTier: FontTier,
    searchHighlight: SearchHighlightSpec?,
) {
    var expanded by remember(block.id) {
        mutableStateOf(block.attributes["open"].toBoolean())
    }

    Surface(
        modifier = Modifier.fillMaxWidth(),
        tonalElevation = 1.dp,
        shape = MaterialTheme.shapes.small,
        border = BorderStroke(1.dp, MaterialTheme.colorScheme.outlineVariant),
    ) {
        Column(
            modifier = Modifier.padding(10.dp),
            verticalArrangement = Arrangement.spacedBy(8.dp),
        ) {
            OutlinedButton(onClick = { expanded = !expanded }) {
                Text(text = block.attributes["summary"] ?: "Details")
            }
            if (expanded) {
                Text(
                    text = toAnnotatedString(
                        plainText = block.plainText.ifBlank { "No details content." },
                        inlineSpans = emptyList(),
                        linkColor = MaterialTheme.colorScheme.primary,
                        blockedLinkColor = MaterialTheme.colorScheme.error,
                        confirmLinkColor = MaterialTheme.colorScheme.tertiary,
                        codeBackgroundColor = MaterialTheme.colorScheme.surfaceVariant,
                        markBackgroundColor = MaterialTheme.colorScheme.secondaryContainer,
                        searchHighlightColor = MaterialTheme.colorScheme.primaryContainer,
                        activeSearchHighlightColor = MaterialTheme.colorScheme.tertiaryContainer,
                        searchHighlight = searchHighlight,
                    ),
                    style = MaterialTheme.typography.bodySmall.withFontTier(fontTier, scale = 0.88f),
                )
            }
        }
    }
}

@Composable
private fun SafeFallbackBlock(
    block: MarkdownRenderBlock,
    fontTier: FontTier,
    searchHighlight: SearchHighlightSpec?,
) {
    Surface(
        modifier = Modifier.fillMaxWidth(),
        tonalElevation = 2.dp,
        shape = MaterialTheme.shapes.small,
    ) {
        Text(
            modifier = Modifier.padding(10.dp),
            text = toAnnotatedString(
                plainText = block.plainText,
                inlineSpans = emptyList(),
                linkColor = MaterialTheme.colorScheme.primary,
                blockedLinkColor = MaterialTheme.colorScheme.error,
                confirmLinkColor = MaterialTheme.colorScheme.tertiary,
                codeBackgroundColor = MaterialTheme.colorScheme.surfaceVariant,
                markBackgroundColor = MaterialTheme.colorScheme.secondaryContainer,
                searchHighlightColor = MaterialTheme.colorScheme.primaryContainer,
                activeSearchHighlightColor = MaterialTheme.colorScheme.tertiaryContainer,
                searchHighlight = searchHighlight,
            ),
            style = MaterialTheme.typography.bodySmall.withFontTier(fontTier, scale = 0.88f),
        )
    }
}

private fun toAnnotatedString(
    plainText: String,
    inlineSpans: List<MarkdownInlineSpan>,
    linkColor: Color,
    blockedLinkColor: Color,
    confirmLinkColor: Color,
    codeBackgroundColor: Color,
    markBackgroundColor: Color,
    searchHighlightColor: Color,
    activeSearchHighlightColor: Color,
    searchHighlight: SearchHighlightSpec?,
): AnnotatedString {
    if (inlineSpans.isEmpty() && searchHighlight == null) {
        return AnnotatedString(plainText)
    }

    val builder = AnnotatedString.Builder(plainText)
    searchHighlight?.let { highlight ->
        var localMatchIndex = 0
        plainText.searchMatchRanges(highlight.query).forEach { range ->
            val globalMatchIndex = highlight.firstGlobalMatchIndex + localMatchIndex
            builder.addStyle(
                style = SpanStyle(
                    background = if (globalMatchIndex == highlight.activeResultIndex) {
                        activeSearchHighlightColor
                    } else {
                        searchHighlightColor
                    },
                ),
                start = range.first,
                end = range.last + 1,
            )
            localMatchIndex += 1
        }
    }
    inlineSpans.forEach { span ->
        val start = span.startOffset.coerceIn(0, plainText.length)
        val end = span.endOffsetExclusive.coerceIn(start, plainText.length)
        if (start == end) {
            return@forEach
        }

        if (span.styles.isNotEmpty()) {
            builder.addStyle(
                style = span.styles.toSpanStyle(
                    codeBackgroundColor = codeBackgroundColor,
                    markBackgroundColor = markBackgroundColor,
                ),
                start = start,
                end = end,
            )
        }

        val linkTarget = span.linkTarget
        val linkDecision = span.linkDecision
        if (linkTarget != null && linkDecision != null) {
            val color = when (linkDecision) {
                MarkdownLinkDecision.Allowed -> linkColor
                MarkdownLinkDecision.Confirm -> confirmLinkColor
                MarkdownLinkDecision.Blocked -> blockedLinkColor
            }
            builder.addStyle(
                style = SpanStyle(
                    color = color,
                    textDecoration = TextDecoration.Underline,
                ),
                start = start,
                end = end,
            )
            builder.addStringAnnotation(
                tag = "fastmd-link-${linkDecision.name.lowercase()}",
                annotation = linkTarget,
                start = start,
                end = end,
            )
        }
    }

    return builder.toAnnotatedString()
}

private fun TextStyle.withFontTier(
    fontTier: FontTier,
    scale: Float = 1f,
    code: Boolean = false,
): TextStyle {
    val baseSp = if (code) fontTier.codeSp else fontTier.bodySp
    val scaledSp = baseSp * scale
    return copy(
        fontSize = scaledSp.sp,
        lineHeight = (scaledSp * fontTier.lineHeightMultiplier).sp,
    )
}

private data class QuoteLine(
    val depth: Int,
    val text: String,
)

private fun String.toQuoteLine(): QuoteLine {
    var remaining = trimStart()
    var depth = 1
    while (remaining.startsWith(">")) {
        depth += 1
        remaining = remaining.removePrefix(">").trimStart()
    }
    return QuoteLine(depth = depth.coerceAtMost(4), text = remaining)
}

private data class ListItem(
    val marker: String,
    val checked: Boolean?,
    val depth: Int,
    val text: String,
    val textStartOffset: Int,
    val textEndOffsetExclusive: Int,
)

private fun String.toListItems(kind: MarkdownBlockKind): List<ListItem> {
    val items = mutableListOf<ListItem>()
    var lineOffset = 0

    lines().forEach { line ->
        line.toListItem(kind, lineOffset)?.let { items += it }
        lineOffset += line.length + 1
    }

    return items
}

private fun String.toListItem(kind: MarkdownBlockKind, lineOffset: Int): ListItem? {
    val indent = takeWhile { it == ' ' }.length / 2
    val task = TaskListRegex.find(this)
    if (task != null) {
        val content = task.groupValues[2]
        val start = lineOffset + task.range.last + 1 - content.length
        return ListItem(
            marker = "",
            checked = task.groupValues[1].equals("x", ignoreCase = true),
            depth = indent,
            text = content,
            textStartOffset = start,
            textEndOffsetExclusive = start + content.length,
        )
    }

    val ordered = OrderedListRegex.find(this)
    if (ordered != null) {
        val content = ordered.groupValues[2]
        val start = lineOffset + ordered.range.last + 1 - content.length
        return ListItem(
            marker = "${ordered.groupValues[1]}.",
            checked = null,
            depth = indent,
            text = content,
            textStartOffset = start,
            textEndOffsetExclusive = start + content.length,
        )
    }

    val unordered = UnorderedListRegex.find(this)
    if (unordered != null) {
        val content = unordered.groupValues[1]
        val start = lineOffset + unordered.range.last + 1 - content.length
        return ListItem(
            marker = if (kind == MarkdownBlockKind.OrderedList) "1." else "*",
            checked = null,
            depth = indent,
            text = content,
            textStartOffset = start,
            textEndOffsetExclusive = start + content.length,
        )
    }

    return null
}

private fun List<MarkdownInlineSpan>.sliceFor(
    startOffset: Int,
    endOffsetExclusive: Int,
): List<MarkdownInlineSpan> =
    mapNotNull { span ->
        val start = span.startOffset.coerceAtLeast(startOffset)
        val end = span.endOffsetExclusive.coerceAtMost(endOffsetExclusive)
        if (start >= end) {
            null
        } else {
            span.copy(
                startOffset = start - startOffset,
                endOffsetExclusive = end - startOffset,
            )
        }
    }

private fun String.toTableRows(): List<List<String>> =
    lines()
        .filterNot { TableDividerRegex.matches(it.trim()) }
        .map { line ->
            line.trim()
                .trim('|')
                .split('|')
                .map { cell -> cell.trim() }
        }
        .filter { row -> row.any { it.isNotBlank() } }

private fun String.searchMatchRanges(query: String): List<IntRange> {
    val normalizedQuery = query.trim()
    if (isEmpty() || normalizedQuery.isBlank()) {
        return emptyList()
    }

    val ranges = mutableListOf<IntRange>()
    var index = 0
    while (index <= length - normalizedQuery.length) {
        val matches = regionMatches(
            thisOffset = index,
            other = normalizedQuery,
            otherOffset = 0,
            length = normalizedQuery.length,
            ignoreCase = true,
        )
        if (matches) {
            ranges += index until index + normalizedQuery.length
            index += normalizedQuery.length
        } else {
            index += 1
        }
    }
    return ranges
}

private val TaskListRegex = Regex("""^\s*[-+*]\s+\[([ xX])]\s+(.+)$""")
private val OrderedListRegex = Regex("""^\s*(\d+)[.)]\s+(.+)$""")
private val UnorderedListRegex = Regex("""^\s*[-+*]\s+(.+)$""")
private val TableDividerRegex = Regex("""^\|?\s*:?-{3,}:?\s*(\|\s*:?-{3,}:?\s*)+\|?$""")

private fun Set<MarkdownInlineStyle>.toSpanStyle(
    codeBackgroundColor: Color,
    markBackgroundColor: Color,
): SpanStyle {
    val decorations = buildList {
        if (MarkdownInlineStyle.Strikethrough in this@toSpanStyle) {
            add(TextDecoration.LineThrough)
        }
    }

    return SpanStyle(
        fontWeight = if (MarkdownInlineStyle.Bold in this) FontWeight.Bold else null,
        fontStyle = if (MarkdownInlineStyle.Italic in this) FontStyle.Italic else null,
        fontFamily = if (
            MarkdownInlineStyle.InlineCode in this ||
            MarkdownInlineStyle.Math in this
        ) {
            FontFamily.Monospace
        } else {
            null
        },
        background = when {
            MarkdownInlineStyle.InlineCode in this -> codeBackgroundColor
            MarkdownInlineStyle.Math in this -> codeBackgroundColor
            MarkdownInlineStyle.Highlight in this -> markBackgroundColor
            else -> Color.Unspecified
        },
        baselineShift = when {
            MarkdownInlineStyle.Subscript in this -> BaselineShift.Subscript
            MarkdownInlineStyle.Superscript in this -> BaselineShift.Superscript
            else -> null
        },
        textDecoration = decorations.takeIf { it.isNotEmpty() }?.let { TextDecoration.combine(it) },
    )
}

private fun decodeBoundedBitmap(
    context: Context,
    source: String,
    maxDimension: Int = 2048,
): Bitmap? {
    if (source.isBlank()) {
        return null
    }

    return try {
        val bounds = BitmapFactory.Options().apply {
            inJustDecodeBounds = true
        }
        openImageStream(context, source)?.use { stream ->
            BitmapFactory.decodeStream(stream, null, bounds)
        } ?: return null

        if (bounds.outWidth <= 0 || bounds.outHeight <= 0) {
            return null
        }

        val decode = BitmapFactory.Options().apply {
            inSampleSize = calculateInSampleSize(bounds.outWidth, bounds.outHeight, maxDimension)
        }
        openImageStream(context, source)?.use { stream ->
            BitmapFactory.decodeStream(stream, null, decode)
        }
    } catch (_: SecurityException) {
        null
    } catch (_: java.io.IOException) {
        null
    } catch (_: IllegalArgumentException) {
        return null
    }
}

private fun openImageStream(
    context: Context,
    source: String,
): java.io.InputStream? =
    when {
        source.startsWith("content://", ignoreCase = true) ->
            context.contentResolver.openInputStream(Uri.parse(source))
        source.startsWith("file://", ignoreCase = true) ->
            context.contentResolver.openInputStream(Uri.parse(source))
        source.startsWith("/") ->
            java.io.File(source).takeIf { it.isFile }?.inputStream()
        else -> null
    }

private fun resolveLocalImageSource(
    source: String,
    sourceKind: String,
    documentBaseUri: String,
): String? {
    if (source.isBlank() || sourceKind == "remote") {
        return null
    }

    if (source.startsWith("content://", ignoreCase = true) ||
        source.startsWith("file://", ignoreCase = true) ||
        source.startsWith("/")
    ) {
        return source
    }

    if (sourceKind != "local" && sourceKind != "relative") {
        return null
    }

    val base = documentBaseUri.takeIf { it.isNotBlank() } ?: return null
    val baseFile = when {
        base.startsWith("file://", ignoreCase = true) -> Uri.parse(base).path?.let(::File)
        base.startsWith("/") -> File(base)
        else -> null
    } ?: return null

    val parent = baseFile.parentFile ?: return null
    return try {
        File(parent, source).canonicalFile.path
    } catch (_: java.io.IOException) {
        null
    }
}

private fun calculateInSampleSize(
    width: Int,
    height: Int,
    maxDimension: Int,
): Int {
    var sample = 1
    var sampledWidth = width
    var sampledHeight = height
    while (sampledWidth / 2 >= maxDimension || sampledHeight / 2 >= maxDimension) {
        sample *= 2
        sampledWidth /= 2
        sampledHeight /= 2
    }
    return sample
}

@Composable
private fun ErrorReader(
    state: ReaderUiState.Error,
    fontTier: FontTier,
    onOpenDocument: () -> Unit,
) {
    Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
        Text(
            text = "Document could not be opened",
            style = MaterialTheme.typography.titleLarge.withFontTier(fontTier, scale = 1.25f),
        )
        Text(
            text = "${state.code}: ${state.message}",
            style = MaterialTheme.typography.bodyMedium.withFontTier(fontTier),
        )
        if (state.recoverable) {
            Button(onClick = onOpenDocument) {
                Text(text = "Open Markdown")
            }
        }
    }
}

@Composable
private fun PermissionLostReader(
    state: ReaderUiState.PermissionLost,
    fontTier: FontTier,
    onOpenDocument: () -> Unit,
) {
    Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
        Text(
            text = "Permission needed",
            style = MaterialTheme.typography.titleLarge.withFontTier(fontTier, scale = 1.25f),
        )
        Text(
            text = "${state.displayName ?: "This document"} needs to be opened again.",
            style = MaterialTheme.typography.bodyMedium.withFontTier(fontTier),
        )
        Button(onClick = onOpenDocument) {
            Text(text = "Open Again")
        }
    }
}
