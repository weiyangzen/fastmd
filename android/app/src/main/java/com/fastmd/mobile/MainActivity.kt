package com.fastmd.mobile

import android.content.Intent
import android.os.Bundle
import android.os.SystemClock
import androidx.activity.compose.BackHandler
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.ui.Modifier
import androidx.compose.ui.semantics.LiveRegionMode
import androidx.compose.ui.semantics.liveRegion
import androidx.compose.ui.semantics.paneTitle
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.unit.dp
import androidx.lifecycle.lifecycleScope
import androidx.lifecycle.ViewModelProvider
import com.fastmd.mobile.core.document.MarkdownLoadResult
import com.fastmd.mobile.core.document.MarkdownSaveResult
import com.fastmd.mobile.core.document.RecentDocumentMetadata
import com.fastmd.mobile.core.diagnostics.LocalDiagnosticsReport
import com.fastmd.mobile.core.error.FastMdErrorCode
import com.fastmd.mobile.core.markdown.StructuredMarkdownParser
import com.fastmd.mobile.core.performance.AndroidPerformanceProfile
import com.fastmd.mobile.core.reader.BlockSourceEdit
import com.fastmd.mobile.core.reader.BlockSourceEditResult
import com.fastmd.mobile.core.reader.BlockSourceEditSnapshot
import com.fastmd.mobile.core.reader.FontTier
import com.fastmd.mobile.core.reader.ReaderThemeMode
import com.fastmd.mobile.core.reader.ReaderUiState
import com.fastmd.mobile.core.render.MarkdownBlockId
import com.fastmd.mobile.core.search.ReaderSearchEngine
import com.fastmd.mobile.core.search.ReaderSearchSummary
import com.fastmd.mobile.document.AndroidDocumentEntry
import com.fastmd.mobile.document.AndroidDocumentEntryParser
import com.fastmd.mobile.document.AndroidMarkdownDocumentLoader
import com.fastmd.mobile.feature.library.LibraryScreen
import com.fastmd.mobile.feature.reader.ReaderScreen
import com.fastmd.mobile.feature.reader.RecoveryDraftPrompt
import com.fastmd.mobile.feature.settings.SettingsScreen
import com.fastmd.mobile.performance.AndroidRuntimeProfileProvider
import com.fastmd.mobile.preferences.AndroidReaderPreferenceStore
import com.fastmd.mobile.recovery.AndroidRecoveryDraft
import com.fastmd.mobile.recovery.AndroidRecoveryDraftStore
import com.fastmd.mobile.recovery.AndroidRecoveryDraftSummary
import com.fastmd.mobile.recent.AndroidRecentDocumentStore
import com.fastmd.mobile.session.FastMdReaderSessionViewModel
import com.fastmd.mobile.theme.FastMdTheme
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.isActive
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext

class MainActivity : ComponentActivity() {
    private lateinit var documentLoader: AndroidMarkdownDocumentLoader
    private lateinit var recentDocumentStore: AndroidRecentDocumentStore
    private lateinit var readerPreferenceStore: AndroidReaderPreferenceStore
    private lateinit var recoveryDraftStore: AndroidRecoveryDraftStore
    private lateinit var session: FastMdReaderSessionViewModel
    private var recoveryPersistJob: Job? = null
    private var searchJob: Job? = null
    private var searchGeneration = 0L

    private val openDocument = registerForActivityResult(ActivityResultContracts.OpenDocument()) { uri ->
        if (uri != null) {
            loadSafDocument(uri = uri)
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        session = ViewModelProvider(this)[FastMdReaderSessionViewModel::class.java]
        documentLoader = AndroidMarkdownDocumentLoader(applicationContext)
        recentDocumentStore = AndroidRecentDocumentStore(applicationContext)
        readerPreferenceStore = AndroidReaderPreferenceStore(applicationContext)
        recoveryDraftStore = AndroidRecoveryDraftStore(applicationContext)
        session.setPerformanceProfile(AndroidRuntimeProfileProvider.select(this))
        lifecycleScope.launch {
            recentDocumentStore.recentDocuments.collect { recents ->
                session.recentDocumentsState.value = recents
            }
        }
        lifecycleScope.launch {
            readerPreferenceStore.fontTier.collect { fontTier ->
                session.fontTierState.value = fontTier
                session.readerState.value = session.readerState.value.withFontTier(fontTier)
            }
        }
        lifecycleScope.launch {
            readerPreferenceStore.themeMode.collect { themeMode ->
                session.themeModeState.value = themeMode
            }
        }
        if (savedInstanceState == null || session.readerState.value == ReaderUiState.Empty) {
            handleEntryIntent(intent)
        }
        lifecycleScope.launch {
            session.recoveryDraftSummaryState.value = recoveryDraftStore.readSummary()
        }
        setContent {
            val state by remember { session.readerState }
            val recentDocuments by remember { session.recentDocumentsState }
            val fontTier by remember { session.fontTierState }
            val themeMode by remember { session.themeModeState }
            val performanceProfile by remember { session.performanceProfileState }
            val showDiscardEditDialog by remember { session.showDiscardEditDialogState }
            val recoveryDraftSummary by remember { session.recoveryDraftSummaryState }
            val diagnosticsReport by remember { session.diagnosticsReportState }
            FastMdApp(
                readerState = state,
                recentDocuments = recentDocuments,
                recoveryDraftPrompt = recoveryDraftSummary?.toRecoveryDraftPrompt(),
                diagnosticsReport = diagnosticsReport,
                currentFontTier = fontTier,
                currentThemeMode = themeMode,
                performanceProfile = performanceProfile,
                showDiscardEditDialog = showDiscardEditDialog,
                onOpenDocument = {
                    openDocument.launch(MARKDOWN_MIME_TYPES)
                },
                onOpenRecent = ::loadRecentDocument,
                onFontTierSelected = ::setFontTier,
                onThemeModeSelected = ::setThemeMode,
                onSearchQueryChanged = ::setSearchQuery,
                onSearchPrevious = ::selectPreviousSearchResult,
                onSearchNext = ::selectNextSearchResult,
                onSearchClear = ::clearSearch,
                onVisibleBlockChanged = session::updateVisibleBlock,
                onEditSource = session::beginSourceEdit,
                onEditBlock = session::beginBlockEdit,
                onSourceDraftChanged = { draft ->
                    session.updateSourceDraft(draft)
                    persistRecoveryDraft()
                },
                onSaveSource = ::saveSourceEdit,
                onCancelSourceEdit = {
                    session.cancelSourceEdit()
                    persistRecoveryDraft()
                },
                onBlockDraftChanged = { draft ->
                    session.updateBlockDraft(draft)
                    persistRecoveryDraft()
                },
                onSaveBlock = ::saveBlockEdit,
                onCancelBlockEdit = {
                    session.cancelBlockEdit()
                    persistRecoveryDraft()
                },
                onRestoreRecoveryDraft = ::restoreRecoveryDraft,
                onDeleteRecoveryDraft = ::deleteRecoveryDraft,
                onKeepEditing = session::keepEditing,
                onDiscardEdits = {
                    session.discardEdits()
                    clearRecoveryDraft()
                },
                onNavigateBack = session::handleBackNavigation,
            )
        }
    }

    override fun onStop() {
        persistRecoveryDraft()
        super.onStop()
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        handleEntryIntent(intent)
    }

    private fun handleEntryIntent(intent: Intent?) {
        val entry = AndroidDocumentEntryParser.parse(intent)
        if (entry != AndroidDocumentEntry.Launcher) {
            loadDocument(entry = entry, loadingLabel = intent?.data?.lastPathSegment)
        }
    }

    private fun loadDocument(
        entry: AndroidDocumentEntry,
        loadingLabel: String?,
    ) {
        session.clearActiveDocumentContext()
        session.readerState.value = ReaderUiState.Loading(loadingLabel)
        lifecycleScope.launch {
            session.readerState.value = documentLoader.load(entry).toReaderState(loadingLabel)
        }
    }

    private fun restoreRecoveryDraft() {
        session.readerState.value = ReaderUiState.Loading("recovery draft")
        lifecycleScope.launch {
            when (val draft = recoveryDraftStore.readDraft()) {
                null -> {
                    session.recoveryDraftSummaryState.value = null
                    session.readerState.value = ReaderUiState.Error(
                        code = FastMdErrorCode.OpenMissingDocument,
                        message = "No recoverable Android draft was found.",
                        recoverable = true,
                    )
                }

                else -> restoreRecoveryDraft(draft)
            }
        }
    }

    private suspend fun restoreRecoveryDraft(draft: AndroidRecoveryDraft) {
        val base = draft.base
        when (val result = documentLoader.loadRecoveryHandle(base.handle)) {
            is MarkdownLoadResult.Failed -> {
                session.recordFailure(result.code)
                session.readerState.value = ReaderUiState.Error(
                    code = result.code,
                    message = result.message,
                    recoverable = result.recoverable,
                )
            }

            is MarkdownLoadResult.Loaded -> {
                session.setActiveDocumentContext(result)
                session.recordLoadedDocument(result)
                recentDocumentStore.recordLoaded(result)
                session.readerState.value = when (draft) {
                    is AndroidRecoveryDraft.Source -> ReaderUiState.EditingSource(
                        document = result.document,
                        draftSource = base.draftSource,
                        fontTier = base.fontTier,
                        isDirty = base.draftSource != result.document.source,
                        saveErrorMessage = "Recovered unsaved source draft. Save or discard it to clear recovery.",
                    )

                    is AndroidRecoveryDraft.Block -> ReaderUiState.EditingBlock(
                        document = result.document,
                        blockId = draft.blockId,
                        originalSourceRange = draft.originalSourceRange,
                        originalBlockSource = draft.originalBlockSource,
                        draftSource = base.draftSource,
                        fontTier = base.fontTier,
                        isDirty = base.draftSource != draft.originalBlockSource,
                        saveErrorMessage = "Recovered unsaved block draft. Save or discard it to clear recovery.",
                    )
                }
            }
        }
    }

    private fun deleteRecoveryDraft() {
        recoveryPersistJob?.cancel()
        recoveryPersistJob = lifecycleScope.launch {
            recoveryDraftStore.clear()
            session.recoveryDraftSummaryState.value = null
        }
    }

    private fun persistRecoveryDraft() {
        val draft = session.createRecoveryDraft()
        recoveryPersistJob?.cancel()
        recoveryPersistJob = lifecycleScope.launch {
            recoveryDraftStore.save(draft)
            session.recoveryDraftSummaryState.value = recoveryDraftStore.readSummary()
        }
    }

    private fun clearRecoveryDraft() {
        recoveryPersistJob?.cancel()
        recoveryPersistJob = lifecycleScope.launch {
            recoveryDraftStore.clear()
            session.recoveryDraftSummaryState.value = null
        }
    }

    private fun loadSafDocument(uri: android.net.Uri) {
        session.clearActiveDocumentContext()
        session.readerState.value = ReaderUiState.Loading(uri.lastPathSegment)
        lifecycleScope.launch {
            session.readerState.value = documentLoader.loadSafSelection(uri).toReaderState(uri.lastPathSegment)
        }
    }

    private fun loadRecentDocument(recent: RecentDocumentMetadata) {
        session.clearActiveDocumentContext()
        session.readerState.value = ReaderUiState.Loading(recent.displayName)
        lifecycleScope.launch {
            session.readerState.value = documentLoader.loadRecentDocument(recent).toReaderState(recent.displayName)
        }
    }

    private fun setFontTier(fontTier: FontTier) {
        session.fontTierState.value = fontTier
        session.readerState.value = session.readerState.value.withFontTier(fontTier)
        lifecycleScope.launch {
            readerPreferenceStore.setFontTier(fontTier)
        }
    }

    private fun setThemeMode(themeMode: ReaderThemeMode) {
        session.themeModeState.value = themeMode
        lifecycleScope.launch {
            readerPreferenceStore.setThemeMode(themeMode)
        }
    }

    private fun setSearchQuery(query: String) {
        val ready = session.readerState.value.readyForSearch() ?: return
        val requestGeneration = ++searchGeneration
        searchJob?.cancel()

        if (query.isBlank()) {
            session.recordSearchSuccess(
                durationMillis = 0L,
                resultCount = 0,
            )
            session.readerState.value = ready
            return
        }

        session.readerState.value = ReaderUiState.Searching(
            ready = ready,
            query = query,
            resultCount = 0,
            activeResultIndex = null,
        )
        searchJob = lifecycleScope.launch {
            val startedAt = SystemClock.elapsedRealtime()
            val renderModel = ready.renderModel
            val summary = withContext(Dispatchers.Default) {
                ReaderSearchEngine.summarize(
                    renderModel = renderModel,
                    query = query,
                    preferredActiveResultIndex = 0,
                )
            }
            if (!isActive || requestGeneration != searchGeneration) {
                return@launch
            }

            val currentReady = session.readerState.value.readyForSearch() ?: return@launch
            if (currentReady.renderModel.sourceRevision != renderModel.sourceRevision) {
                return@launch
            }
            session.recordSearchSuccess(
                durationMillis = SystemClock.elapsedRealtime() - startedAt,
                resultCount = summary?.resultCount ?: 0,
            )
            session.readerState.value = summary?.toSearchingState(currentReady) ?: currentReady
        }
    }

    private fun selectPreviousSearchResult() {
        val searching = session.readerState.value as? ReaderUiState.Searching ?: return
        val summary = searching.toSearchSummary()
        session.readerState.value = ReaderSearchEngine.previous(summary).toSearchingState(searching.ready)
    }

    private fun selectNextSearchResult() {
        val searching = session.readerState.value as? ReaderUiState.Searching ?: return
        val summary = searching.toSearchSummary()
        session.readerState.value = ReaderSearchEngine.next(summary).toSearchingState(searching.ready)
    }

    private fun clearSearch() {
        val searching = session.readerState.value as? ReaderUiState.Searching ?: return
        session.readerState.value = searching.ready
    }

    private fun saveSourceEdit() {
        val editing = session.readerState.value as? ReaderUiState.EditingSource ?: return
        val document = editing.document
        val draftSource = editing.draftSource
        val fontTier = editing.fontTier
        session.readerState.value = ReaderUiState.Saving(document, draftSource)
        lifecycleScope.launch {
            val saveStartedAt = SystemClock.elapsedRealtime()
            when (
                val result = documentLoader.save(
                    handle = session.activeHandle,
                    originalMetadata = session.activeMetadata,
                    originalSource = document.source,
                    draftSource = draftSource,
                    originalOrigin = document.origin,
                )
            ) {
                is MarkdownSaveResult.Saved -> {
                    clearRecoveryDraft()
                    session.updateActiveMetadata(result.metadata)
                    session.recordSaveSuccess(
                        durationMillis = SystemClock.elapsedRealtime() - saveStartedAt,
                        metadata = result.metadata,
                    )
                    recentDocumentStore.recordSaved(
                        handle = session.activeHandle,
                        metadata = result.metadata,
                    )
                    val parseStartedAt = SystemClock.elapsedRealtime()
                    val renderModel = withContext(Dispatchers.Default) {
                        StructuredMarkdownParser.parse(
                            source = result.document.source,
                            documentBaseUri = session.activeHandle?.reference?.rawReference,
                        )
                    }
                    session.recordParseSuccess(
                        durationMillis = SystemClock.elapsedRealtime() - parseStartedAt,
                        blockCount = renderModel.blocks.size,
                    )
                    session.readerState.value = ReaderUiState.Ready(
                        document = result.document,
                        renderModel = renderModel,
                        fontTier = fontTier,
                    )
                }

                is MarkdownSaveResult.Failed -> {
                    session.recordSaveFailure(
                        durationMillis = SystemClock.elapsedRealtime() - saveStartedAt,
                        code = result.code,
                    )
                    session.restoreFailedSourceSave(
                        document = document,
                        draftSource = draftSource,
                        fontTier = fontTier,
                        errorMessage = result.message,
                    )
                    persistRecoveryDraft()
                }
            }
        }
    }

    private fun saveBlockEdit() {
        val editing = session.readerState.value as? ReaderUiState.EditingBlock ?: return
        val document = editing.document
        val replacement = BlockSourceEdit.apply(
            currentSource = document.source,
            snapshot = BlockSourceEditSnapshot(
                blockId = editing.blockId,
                sourceRange = editing.originalSourceRange,
                originalSource = editing.originalBlockSource,
            ),
            draftBlockSource = editing.draftSource,
        )
        if (replacement is BlockSourceEditResult.RangeMismatch) {
            session.recordSaveFailure(
                durationMillis = 0L,
                code = FastMdErrorCode.EditBlockRangeStale,
            )
            session.restoreFailedBlockSave(
                editing = editing,
                errorMessage = replacement.message,
            )
            persistRecoveryDraft()
            return
        }

        val fullSource = (replacement as BlockSourceEditResult.Applied).fullSource
        session.readerState.value = ReaderUiState.Saving(document, fullSource)
        lifecycleScope.launch {
            val saveStartedAt = SystemClock.elapsedRealtime()
            when (
                val result = documentLoader.save(
                    handle = session.activeHandle,
                    originalMetadata = session.activeMetadata,
                    originalSource = document.source,
                    draftSource = fullSource,
                    originalOrigin = document.origin,
                )
            ) {
                is MarkdownSaveResult.Saved -> {
                    clearRecoveryDraft()
                    session.updateActiveMetadata(result.metadata)
                    session.recordSaveSuccess(
                        durationMillis = SystemClock.elapsedRealtime() - saveStartedAt,
                        metadata = result.metadata,
                    )
                    recentDocumentStore.recordSaved(
                        handle = session.activeHandle,
                        metadata = result.metadata,
                    )
                    val parseStartedAt = SystemClock.elapsedRealtime()
                    val renderModel = withContext(Dispatchers.Default) {
                        StructuredMarkdownParser.parse(
                            source = result.document.source,
                            documentBaseUri = session.activeHandle?.reference?.rawReference,
                        )
                    }
                    session.recordParseSuccess(
                        durationMillis = SystemClock.elapsedRealtime() - parseStartedAt,
                        blockCount = renderModel.blocks.size,
                    )
                    session.readerState.value = ReaderUiState.Ready(
                        document = result.document,
                        renderModel = renderModel,
                        fontTier = editing.fontTier,
                    )
                }

                is MarkdownSaveResult.Failed -> {
                    session.recordSaveFailure(
                        durationMillis = SystemClock.elapsedRealtime() - saveStartedAt,
                        code = result.code,
                    )
                    session.restoreFailedBlockSave(
                        editing = editing,
                        errorMessage = result.message,
                    )
                    persistRecoveryDraft()
                }
            }
        }
    }

    private suspend fun MarkdownLoadResult.toReaderState(displayName: String?): ReaderUiState =
        when (this) {
            is MarkdownLoadResult.Loaded -> {
                session.setActiveDocumentContext(this)
                session.recordLoadedDocument(this)
                recentDocumentStore.recordLoaded(this)
                val parseStartedAt = SystemClock.elapsedRealtime()
                val renderModel = withContext(Dispatchers.Default) {
                    StructuredMarkdownParser.parse(
                        source = document.source,
                        documentBaseUri = handle.reference.rawReference,
                    )
                }
                session.recordParseSuccess(
                    durationMillis = SystemClock.elapsedRealtime() - parseStartedAt,
                    blockCount = renderModel.blocks.size,
                )
                ReaderUiState.Ready(
                    document = document,
                    renderModel = renderModel,
                    fontTier = session.fontTierState.value,
                )
            }

            is MarkdownLoadResult.Failed -> {
                session.clearActiveDocumentContext()
                session.recordFailure(code)
                if (code == FastMdErrorCode.PermissionLost) {
                    ReaderUiState.PermissionLost(displayName = displayName)
                } else {
                    ReaderUiState.Error(
                        code = code,
                        message = message,
                        recoverable = recoverable,
                    )
                }
            }
        }

    private fun ReaderUiState.withFontTier(fontTier: FontTier): ReaderUiState =
        when (this) {
            ReaderUiState.Empty -> this
            is ReaderUiState.Loading -> this
            is ReaderUiState.Error -> this
            is ReaderUiState.PermissionLost -> this
            is ReaderUiState.Saving -> this
            is ReaderUiState.Rendering -> copy(fontTier = fontTier)
            is ReaderUiState.Ready -> copy(fontTier = fontTier)
            is ReaderUiState.ReadOnly -> copy(ready = ready.copy(fontTier = fontTier))
            is ReaderUiState.Searching -> copy(ready = ready.copy(fontTier = fontTier))
            is ReaderUiState.EditingSource -> copy(fontTier = fontTier)
            is ReaderUiState.EditingBlock -> copy(fontTier = fontTier)
        }

    private fun ReaderUiState.readyForSearch(): ReaderUiState.Ready? =
        when (this) {
            is ReaderUiState.Ready -> this
            is ReaderUiState.Searching -> ready
            is ReaderUiState.ReadOnly -> ready
            else -> null
        }

    private fun ReaderSearchSummary.toSearchingState(ready: ReaderUiState.Ready): ReaderUiState.Searching =
        ReaderUiState.Searching(
            ready = ready,
            query = query,
            resultCount = resultCount,
            activeResultIndex = activeResultIndex,
        )

    private fun AndroidRecoveryDraftSummary.toRecoveryDraftPrompt(): RecoveryDraftPrompt =
        RecoveryDraftPrompt(
            label = "Unsaved ${mode.name.lowercase()} draft",
            title = title,
        )

    private fun ReaderUiState.Searching.toSearchSummary(): ReaderSearchSummary =
        ReaderSearchSummary(
            query = query,
            resultCount = resultCount,
            activeResultIndex = activeResultIndex,
        )

    private companion object {
        val MARKDOWN_MIME_TYPES = arrayOf("text/markdown", "text/x-markdown", "text/plain", "*/*")
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun FastMdApp(
    readerState: ReaderUiState,
    recentDocuments: List<RecentDocumentMetadata>,
    recoveryDraftPrompt: RecoveryDraftPrompt?,
    diagnosticsReport: LocalDiagnosticsReport,
    currentFontTier: FontTier,
    currentThemeMode: ReaderThemeMode,
    performanceProfile: AndroidPerformanceProfile,
    showDiscardEditDialog: Boolean,
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
    onKeepEditing: () -> Unit,
    onDiscardEdits: () -> Unit,
    onNavigateBack: () -> Boolean,
) {
    FastMdTheme(
        themeMode = currentThemeMode,
        performanceProfile = performanceProfile,
    ) {
        BackHandler(enabled = readerState != ReaderUiState.Empty) {
            onNavigateBack()
        }
        Scaffold(
            topBar = {
                TopAppBar(
                    title = { Text(text = "FastMD") },
                    colors = TopAppBarDefaults.topAppBarColors(
                        containerColor = MaterialTheme.colorScheme.surface,
                    ),
                )
            },
        ) { innerPadding ->
            Surface(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(innerPadding),
            ) {
                Column(
                    modifier = Modifier
                        .padding(16.dp)
                        .verticalScroll(rememberScrollState()),
                    verticalArrangement = Arrangement.spacedBy(16.dp),
                ) {
                    ReaderScreen(
                        state = readerState,
                        recentDocuments = recentDocuments,
                        recoveryDraftPrompt = recoveryDraftPrompt,
                        currentFontTier = currentFontTier,
                        currentThemeMode = currentThemeMode,
                        onOpenDocument = onOpenDocument,
                        onOpenRecent = onOpenRecent,
                        onFontTierSelected = onFontTierSelected,
                        onThemeModeSelected = onThemeModeSelected,
                        onSearchQueryChanged = onSearchQueryChanged,
                        onSearchPrevious = onSearchPrevious,
                        onSearchNext = onSearchNext,
                        onSearchClear = onSearchClear,
                        onVisibleBlockChanged = onVisibleBlockChanged,
                        onEditSource = onEditSource,
                        onEditBlock = onEditBlock,
                        onSourceDraftChanged = onSourceDraftChanged,
                        onSaveSource = onSaveSource,
                        onCancelSourceEdit = onCancelSourceEdit,
                        onBlockDraftChanged = onBlockDraftChanged,
                        onSaveBlock = onSaveBlock,
                        onCancelBlockEdit = onCancelBlockEdit,
                        onRestoreRecoveryDraft = onRestoreRecoveryDraft,
                        onDeleteRecoveryDraft = onDeleteRecoveryDraft,
                    )
                    LibraryScreen()
                    SettingsScreen(
                        selectedThemeMode = currentThemeMode,
                        diagnosticsReport = diagnosticsReport.toRedactedText(),
                        onThemeModeSelected = onThemeModeSelected,
                    )
                }
            }
        }
        if (showDiscardEditDialog) {
            androidx.compose.material3.AlertDialog(
                modifier = Modifier.semantics {
                    paneTitle = "Discard unsaved changes"
                    liveRegion = LiveRegionMode.Assertive
                },
                onDismissRequest = onKeepEditing,
                title = { Text(text = "Discard unsaved changes?") },
                text = { Text(text = "Your source edits have not been saved.") },
                confirmButton = {
                    androidx.compose.material3.TextButton(onClick = onDiscardEdits) {
                        Text(text = "Discard")
                    }
                },
                dismissButton = {
                    androidx.compose.material3.TextButton(onClick = onKeepEditing) {
                        Text(text = "Keep editing")
                    }
                },
            )
        }
    }
}
