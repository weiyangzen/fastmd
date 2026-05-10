package com.fastmd.mobile.core.render

import java.security.MessageDigest
import java.util.Locale

enum class RichRendererSurface {
    Mermaid,
    Math,
}

enum class RichRendererAssetKind {
    JavaScript,
    StyleSheet,
    Font,
}

enum class RichRendererRequestKind {
    InitialDocument,
    RendererAsset,
    Subresource,
    Navigation,
    Iframe,
}

enum class RichRendererRequestBlockReason {
    BlankUrl,
    NetworkRequest,
    ExternalNavigation,
    JavascriptUrl,
    DataUrl,
    BlobUrl,
    FileSystemUrl,
    Iframe,
    ContentUri,
    NonRendererFile,
    UnknownScheme,
}

data class RichRendererRequestDecision(
    val allowed: Boolean,
    val blockReason: RichRendererRequestBlockReason? = null,
) {
    init {
        require(allowed == (blockReason == null)) {
            "A renderer request decision must be either allowed or blocked with a reason."
        }
    }

    companion object {
        val Allow = RichRendererRequestDecision(allowed = true)

        fun block(reason: RichRendererRequestBlockReason): RichRendererRequestDecision =
            RichRendererRequestDecision(allowed = false, blockReason = reason)
    }
}

object RichRendererRequestPolicy {
    private const val ANDROID_ASSET_RENDERER_PREFIX = "file:///android_asset/fastmd-renderers/"

    fun decide(
        rawUrl: String?,
        kind: RichRendererRequestKind,
    ): RichRendererRequestDecision {
        if (kind == RichRendererRequestKind.Iframe) {
            return RichRendererRequestDecision.block(RichRendererRequestBlockReason.Iframe)
        }

        val url = rawUrl?.trim().orEmpty()
        if (url.isEmpty()) {
            return RichRendererRequestDecision.block(RichRendererRequestBlockReason.BlankUrl)
        }

        val lowercaseUrl = url.lowercase(Locale.ROOT)
        val decodedLowercaseUrl = decodePercentEscapesRepeatedly(lowercaseUrl)
        if (lowercaseUrl.startsWith("javascript:")) {
            return RichRendererRequestDecision.block(RichRendererRequestBlockReason.JavascriptUrl)
        }
        if (lowercaseUrl.startsWith("data:")) {
            return RichRendererRequestDecision.block(RichRendererRequestBlockReason.DataUrl)
        }
        if (lowercaseUrl.startsWith("blob:")) {
            return RichRendererRequestDecision.block(RichRendererRequestBlockReason.BlobUrl)
        }
        if (lowercaseUrl.startsWith("filesystem:")) {
            return RichRendererRequestDecision.block(RichRendererRequestBlockReason.FileSystemUrl)
        }
        if (lowercaseUrl.startsWith("content:")) {
            return RichRendererRequestDecision.block(RichRendererRequestBlockReason.ContentUri)
        }

        if (lowercaseUrl.startsWith("http://") || lowercaseUrl.startsWith("https://") || lowercaseUrl.startsWith("//")) {
            return RichRendererRequestDecision.block(RichRendererRequestBlockReason.NetworkRequest)
        }

        if (decodedLowercaseUrl != lowercaseUrl) {
            if (decodedLowercaseUrl.startsWith("javascript:")) {
                return RichRendererRequestDecision.block(RichRendererRequestBlockReason.JavascriptUrl)
            }
            if (decodedLowercaseUrl.startsWith("data:")) {
                return RichRendererRequestDecision.block(RichRendererRequestBlockReason.DataUrl)
            }
            if (decodedLowercaseUrl.startsWith("blob:")) {
                return RichRendererRequestDecision.block(RichRendererRequestBlockReason.BlobUrl)
            }
            if (decodedLowercaseUrl.startsWith("filesystem:")) {
                return RichRendererRequestDecision.block(RichRendererRequestBlockReason.FileSystemUrl)
            }
            if (decodedLowercaseUrl.startsWith("content:")) {
                return RichRendererRequestDecision.block(RichRendererRequestBlockReason.ContentUri)
            }
            if (
                decodedLowercaseUrl.startsWith("http://") ||
                decodedLowercaseUrl.startsWith("https://") ||
                decodedLowercaseUrl.startsWith("//")
            ) {
                return RichRendererRequestDecision.block(RichRendererRequestBlockReason.NetworkRequest)
            }
            if (decodedLowercaseUrl.startsWith("file:")) {
                return RichRendererRequestDecision.block(RichRendererRequestBlockReason.NonRendererFile)
            }
        }

        if (kind == RichRendererRequestKind.Navigation) {
            return RichRendererRequestDecision.block(RichRendererRequestBlockReason.ExternalNavigation)
        }

        if (lowercaseUrl.startsWith("file:")) {
            return if (isAndroidRendererAssetUrl(lowercaseUrl)) {
                RichRendererRequestDecision.Allow
            } else {
                RichRendererRequestDecision.block(RichRendererRequestBlockReason.NonRendererFile)
            }
        }

        return RichRendererRequestDecision.block(RichRendererRequestBlockReason.UnknownScheme)
    }

    private fun decodePercentEscapesRepeatedly(lowercaseUrl: String): String {
        var current = lowercaseUrl
        repeat(MAX_PERCENT_DECODE_PASSES) {
            val decoded = decodePercentEscapesOnce(current)
            if (decoded == current) {
                return current
            }
            current = decoded
        }
        return current
    }

    private fun decodePercentEscapesOnce(lowercaseUrl: String): String {
        val output = StringBuilder(lowercaseUrl.length)
        var index = 0
        while (index < lowercaseUrl.length) {
            val char = lowercaseUrl[index]
            if (
                char == '%' &&
                index + 2 < lowercaseUrl.length &&
                lowercaseUrl[index + 1].isHexDigit() &&
                lowercaseUrl[index + 2].isHexDigit()
            ) {
                val value = lowercaseUrl.substring(index + 1, index + 3).toInt(radix = 16)
                output.append(value.toChar())
                index += 3
            } else {
                output.append(char)
                index += 1
            }
        }
        return output.toString()
    }

    private fun Char.isHexDigit(): Boolean = this in '0'..'9' || this in 'a'..'f'

    private const val MAX_PERCENT_DECODE_PASSES = 4

    private fun isAndroidRendererAssetUrl(lowercaseUrl: String): Boolean {
        if (!lowercaseUrl.startsWith(ANDROID_ASSET_RENDERER_PREFIX)) {
            return false
        }

        val rendererPath = lowercaseUrl.removePrefix(ANDROID_ASSET_RENDERER_PREFIX)
        if (
            rendererPath.any { it <= ' ' } ||
            rendererPath.any { it == '\\' || it == '?' || it == '#' || it == '%' || it == ':' }
        ) {
            return false
        }

        return rendererPath.isNotBlank() &&
            rendererPath.hasAllowedPackagedRendererAssetExtension() &&
            rendererPath != RENDERER_ASSET_HASH_MANIFEST &&
            rendererPath != RENDERER_ASSET_METADATA_LOCK &&
            rendererPath.split('/').none { segment ->
                segment.isBlank() || segment == "." || segment == ".." || segment == "%2e" || segment == "%2e%2e"
            }
    }

    private const val RENDERER_ASSET_HASH_MANIFEST = "renderer-assets.sha256"
    private const val RENDERER_ASSET_METADATA_LOCK = "renderer-assets.lock"
}

@JvmInline
value class LocalRendererAssetPath(
    val value: String,
) {
    init {
        require(value.isNotBlank()) { "Renderer asset path cannot be blank." }
        require(value.startsWith(RENDERER_ASSET_ROOT)) {
            "Renderer assets must live under $RENDERER_ASSET_ROOT."
        }
        require(!value.startsWith("/")) { "Renderer asset path must be relative." }
        require(value != RENDERER_ASSET_ROOT) { "Renderer asset path must include a file under its asset root." }
        require(value.none { it <= ' ' }) { "Renderer asset path cannot contain whitespace or control characters." }
        require(value.none { it == '\\' || it == '?' || it == '#' || it == '%' }) {
            "Renderer asset path cannot contain escaped, query, fragment, or backslash markers."
        }
        require(!value.contains(":")) { "Renderer asset path cannot contain a URI scheme." }

        value.split('/').forEach { segment ->
            require(segment.isNotBlank()) { "Renderer asset path cannot contain blank segments." }
            require(segment != ".") { "Renderer asset path cannot contain current-directory segments." }
            require(segment != "..") { "Renderer asset path cannot escape its asset root." }
        }
    }

    companion object {
        const val RENDERER_ASSET_ROOT = "fastmd-renderers/"
    }
}

data class LocalRendererAsset(
    val kind: RichRendererAssetKind,
    val path: LocalRendererAssetPath,
    val sha256: String,
) {
    init {
        require(SHA_256_HEX.matches(sha256)) {
            "Renderer asset SHA-256 must be 64 lowercase hex characters."
        }
    }

    companion object {
        private val SHA_256_HEX = Regex("[0-9a-f]{64}")
    }
}

data class LocalRendererAssetManifestEntry(
    val path: LocalRendererAssetPath,
    val sha256: String,
) {
    init {
        require(
            path.value.removePrefix(LocalRendererAssetPath.RENDERER_ASSET_ROOT) ==
                LocalRendererAssetManifest.METADATA_LOCK_FILE ||
                path.value.hasAllowedPackagedRendererAssetExtension(),
        ) {
            "Renderer asset manifest can only list supported local renderer asset file types."
        }
        require(SHA_256_HEX.matches(sha256)) {
            "Renderer asset manifest SHA-256 must be 64 lowercase hex characters."
        }
    }

    val manifestRelativePath: String
        get() = path.value.removePrefix(LocalRendererAssetPath.RENDERER_ASSET_ROOT)

    companion object {
        private val SHA_256_HEX = Regex("[0-9a-f]{64}")
    }
}

data class LocalRendererAssetMetadataEntry(
    val path: LocalRendererAssetPath,
    val upstreamName: String,
    val upstreamVersion: String,
    val licenseNotes: String,
    val sha256: String,
) {
    init {
        require(path.value.hasAllowedPackagedRendererAssetExtension()) {
            "Renderer asset metadata lock can only describe supported local renderer asset file types."
        }
        require(upstreamName.isCleanMetadataField()) {
            "Renderer asset metadata upstream name cannot be blank or padded."
        }
        require(upstreamVersion.isCleanMetadataField()) {
            "Renderer asset metadata upstream version cannot be blank or padded."
        }
        require(licenseNotes.isCleanMetadataField()) {
            "Renderer asset metadata license notes cannot be blank or padded."
        }
        require(SHA_256_HEX.matches(sha256)) {
            "Renderer asset metadata SHA-256 must be 64 lowercase hex characters."
        }
    }

    val metadataRelativePath: String
        get() = path.value.removePrefix(LocalRendererAssetPath.RENDERER_ASSET_ROOT)

    companion object {
        private val SHA_256_HEX = Regex("[0-9a-f]{64}")
    }
}

data class LocalRendererAssetMetadataLock(
    val entries: List<LocalRendererAssetMetadataEntry>,
) {
    init {
        val duplicateMetadataPaths = entries
            .groupingBy { it.metadataRelativePath }
            .eachCount()
            .filterValues { count -> count > 1 }
            .keys
        require(duplicateMetadataPaths.isEmpty()) {
            "Renderer asset metadata lock cannot contain duplicate paths: ${duplicateMetadataPaths.joinToString()}."
        }
        require(entries.none { it.metadataRelativePath == LocalRendererAssetManifest.HASH_MANIFEST_FILE }) {
            "Renderer asset metadata lock must not describe the SHA-256 manifest."
        }
        require(entries.none { it.metadataRelativePath == LocalRendererAssetManifest.METADATA_LOCK_FILE }) {
            "Renderer asset metadata lock must not describe itself."
        }
    }

    fun verifyMatchesManifest(manifest: LocalRendererAssetManifest) {
        val manifestAssetHashes = manifest.entries
            .filterNot { entry -> entry.manifestRelativePath == LocalRendererAssetManifest.METADATA_LOCK_FILE }
            .associate { entry -> entry.manifestRelativePath to entry.sha256 }
        val metadataAssetHashes = entries.associate { entry ->
            entry.metadataRelativePath to entry.sha256
        }

        val missingMetadata = manifestAssetHashes.keys - metadataAssetHashes.keys
        require(missingMetadata.isEmpty()) {
            "Renderer assets are missing from the metadata lock: ${missingMetadata.joinToString()}."
        }

        val unlistedMetadata = metadataAssetHashes.keys - manifestAssetHashes.keys
        require(unlistedMetadata.isEmpty()) {
            "Renderer asset metadata lock describes assets missing from the SHA-256 manifest: ${
                unlistedMetadata.joinToString()
            }."
        }

        val mismatchedMetadataHashes = metadataAssetHashes
            .filter { (path, metadataHash) -> manifestAssetHashes[path] != metadataHash }
            .keys
        require(mismatchedMetadataHashes.isEmpty()) {
            "Renderer asset metadata lock hash mismatch for: ${mismatchedMetadataHashes.joinToString()}."
        }
    }

    companion object {
        fun parse(lockText: String): LocalRendererAssetMetadataLock {
            val entries = lockText
                .lineSequence()
                .withIndex()
                .filter { (_, line) -> line.isNotBlank() && !line.trimStart().startsWith("#") }
                .map { (index, line) -> parseLine(line, index + 1) }
                .toList()

            return LocalRendererAssetMetadataLock(entries)
        }

        private fun parseLine(
            line: String,
            lineNumber: Int,
        ): LocalRendererAssetMetadataEntry {
            val fields = line.split('|')
            require(fields.size == METADATA_FIELD_COUNT) {
                "Malformed renderer asset metadata lock line $lineNumber."
            }

            val metadataRelativePath = normalizeMetadataPath(fields[0])
            return LocalRendererAssetMetadataEntry(
                path = LocalRendererAssetPath(
                    LocalRendererAssetPath.RENDERER_ASSET_ROOT + metadataRelativePath,
                ),
                upstreamName = fields[1],
                upstreamVersion = fields[2],
                licenseNotes = fields[3],
                sha256 = fields[4],
            )
        }

        private fun normalizeMetadataPath(path: String): String {
            require(path == path.trim()) {
                "Renderer asset metadata path cannot contain leading or trailing whitespace."
            }
            require(path.isNotBlank()) { "Renderer asset metadata path cannot be blank." }
            require(!path.startsWith(LocalRendererAssetPath.RENDERER_ASSET_ROOT)) {
                "Renderer asset metadata paths must be relative to the renderer asset root."
            }
            LocalRendererAssetPath(LocalRendererAssetPath.RENDERER_ASSET_ROOT + path)
            return path
        }

        private const val METADATA_FIELD_COUNT = 5
    }
}

object LocalRendererAssetPackageVerifier {
    fun verifyOfflinePackage(
        manifestText: String,
        metadataLockText: String,
        packagedAssetBytes: Map<String, ByteArray>,
    ) {
        val manifest = LocalRendererAssetManifest.parse(manifestText)
        val metadataLock = LocalRendererAssetMetadataLock.parse(metadataLockText)

        manifest.verifyPackagedAssetBytes(packagedAssetBytes)
        metadataLock.verifyMatchesManifest(manifest)
        verifyPackagedAssetsAreOffline(packagedAssetBytes)
    }

    private fun verifyPackagedAssetsAreOffline(packagedAssetBytes: Map<String, ByteArray>) {
        packagedAssetBytes
            .filterKeys { path -> path.hasScannableRendererAssetExtension() }
            .forEach { (path, bytes) ->
                val assetTextsToScan = bytes.toString(Charsets.UTF_8).normalizedRendererAssetTexts()
                val hasForbiddenMarker = assetTextsToScan.any { assetText ->
                    OFFLINE_FORBIDDEN_MARKERS.any { marker -> marker in assetText } ||
                        OFFLINE_FORBIDDEN_PATTERNS.any { pattern -> pattern.containsMatchIn(assetText) } ||
                        PROTOCOL_RELATIVE_REMOTE_REFERENCE.containsMatchIn(assetText)
                }
                require(!hasForbiddenMarker) {
                    "Renderer asset must be offline and isolated; found network, navigation, iframe, dynamic code, or dangerous URL marker in $path."
                }
            }
    }

    private fun String.normalizedRendererAssetTexts(): Set<String> {
        val lowercaseText = lowercase(Locale.ROOT)
        val decodedPercentText = lowercaseText.decodePercentEscapesRepeatedly()
        val decodedJavascriptText = lowercaseText.decodeJavascriptEscapes()
        val decodedHtmlEntityText = lowercaseText.decodeHtmlNumericEntities()

        return setOf(
            lowercaseText,
            decodedPercentText,
            decodedJavascriptText,
            decodedHtmlEntityText,
            decodedJavascriptText.decodePercentEscapesRepeatedly(),
            decodedHtmlEntityText.decodePercentEscapesRepeatedly(),
        )
    }

    private fun String.decodePercentEscapesRepeatedly(): String {
        var current = this
        repeat(MAX_ASSET_PERCENT_DECODE_PASSES) {
            val decoded = current.decodePercentEscapesOnce()
            if (decoded == current) {
                return current
            }
            current = decoded
        }
        return current
    }

    private fun String.decodePercentEscapesOnce(): String {
        val output = StringBuilder(length)
        var index = 0
        while (index < length) {
            val char = this[index]
            if (
                char == '%' &&
                index + 2 < length &&
                this[index + 1].isLowercaseHexDigit() &&
                this[index + 2].isLowercaseHexDigit()
            ) {
                output.append(substring(index + 1, index + 3).toInt(radix = 16).toChar())
                index += 3
            } else {
                output.append(char)
                index += 1
            }
        }
        return output.toString()
    }

    private fun String.decodeJavascriptEscapes(): String {
        val output = StringBuilder(length)
        var index = 0
        while (index < length) {
            if (this[index] == '\\' && index + 1 < length) {
                val escapeType = this[index + 1]
                when {
                    escapeType == 'x' &&
                        index + 3 < length &&
                        this[index + 2].isLowercaseHexDigit() &&
                        this[index + 3].isLowercaseHexDigit() -> {
                        output.append(substring(index + 2, index + 4).toInt(radix = 16).toChar())
                        index += 4
                        continue
                    }
                    escapeType == 'u' &&
                        index + 2 < length &&
                        this[index + 2] == '{' -> {
                        val closingBrace = indexOf('}', startIndex = index + 3)
                        val hexValue = if (closingBrace > index + 3) substring(index + 3, closingBrace) else ""
                        if (hexValue.length <= MAX_JAVASCRIPT_BRACED_ESCAPE_DIGITS &&
                            hexValue.all { it.isLowercaseHexDigit() }
                        ) {
                            val codeUnit = hexValue.toInt(radix = 16)
                            if (codeUnit <= Char.MAX_VALUE.code) {
                                output.append(codeUnit.toChar())
                                index = closingBrace + 1
                                continue
                            }
                        }
                    }
                    escapeType == 'u' &&
                        index + 5 < length &&
                        this[index + 2].isLowercaseHexDigit() &&
                        this[index + 3].isLowercaseHexDigit() &&
                        this[index + 4].isLowercaseHexDigit() &&
                        this[index + 5].isLowercaseHexDigit() -> {
                        output.append(substring(index + 2, index + 6).toInt(radix = 16).toChar())
                        index += 6
                        continue
                    }
                }
            }

            output.append(this[index])
            index += 1
        }
        return output.toString()
    }

    private fun String.decodeHtmlNumericEntities(): String {
        val output = StringBuilder(length)
        var index = 0
        while (index < length) {
            if (this[index] == '&' && index + 3 < length && this[index + 1] == '#') {
                val semicolonIndex = indexOf(';', startIndex = index + 2)
                if (semicolonIndex > index + 2) {
                    val entityBody = substring(index + 2, semicolonIndex)
                    val radix = if (entityBody.startsWith("x")) 16 else 10
                    val digits = if (radix == 16) entityBody.drop(1) else entityBody
                    if (
                        digits.isNotBlank() &&
                        digits.length <= MAX_HTML_ENTITY_DIGITS &&
                        digits.all { digit -> if (radix == 16) digit.isLowercaseHexDigit() else digit in '0'..'9' }
                    ) {
                        val codeUnit = digits.toInt(radix)
                        if (codeUnit <= Char.MAX_VALUE.code) {
                            output.append(codeUnit.toChar())
                            index = semicolonIndex + 1
                            continue
                        }
                    }
                }
            }

            output.append(this[index])
            index += 1
        }
        return output.toString()
    }

    private fun Char.isLowercaseHexDigit(): Boolean = this in '0'..'9' || this in 'a'..'f'

    private fun String.hasScannableRendererAssetExtension(): Boolean {
        val lowercasePath = lowercase(Locale.ROOT)
        return lowercasePath.endsWith(".js") ||
            lowercasePath.endsWith(".mjs") ||
            lowercasePath.endsWith(".css") ||
            lowercasePath.endsWith(".html") ||
            lowercasePath.endsWith(".htm") ||
            lowercasePath.endsWith(".svg")
    }

    private val PROTOCOL_RELATIVE_REMOTE_REFERENCE = Regex("(^|[^:])//[a-z0-9.-]+")

    private const val MAX_ASSET_PERCENT_DECODE_PASSES = 4
    private const val MAX_JAVASCRIPT_BRACED_ESCAPE_DIGITS = 6
    private const val MAX_HTML_ENTITY_DIGITS = 7

    private val OFFLINE_FORBIDDEN_MARKERS = listOf(
        "http://",
        "https://",
        "http%3a",
        "https%3a",
        "javascript:",
        "javascript%3a",
        "data:",
        "data%3a",
        "blob:",
        "blob%3a",
        "filesystem:",
        "filesystem%3a",
        "file:",
        "file%3a",
        "content:",
        "content%3a",
        "cdnjs",
        "unpkg",
        "jsdelivr",
        "<script",
        "<iframe",
        "srcdoc=",
        "<meta",
        "http-equiv",
        "<form",
        " onload=",
        " onclick=",
        " onerror=",
        "window.location",
        "document.location",
        "location.href",
        "location.assign",
        "location.replace",
        "window.open",
        "fetch(",
        "xmlhttprequest",
        "websocket(",
        "eventsource(",
        "sendbeacon(",
        "importscripts(",
        "import(",
        "new worker(",
        "sharedworker(",
        "serviceworker",
        "navigator.serviceworker",
    )

    private val OFFLINE_FORBIDDEN_PATTERNS = listOf(
        Regex("""\beval\s*\("""),
        Regex("""\bnew\s+function\s*\("""),
        Regex("""\bfunction\s*\(\s*['"`]"""),
        Regex("""\bsettimeout\s*\(\s*['"`]"""),
        Regex("""\bsetinterval\s*\(\s*['"`]"""),
        Regex("""\son(load|click|error)\s*="""),
    )
}

data class LocalRendererAssetManifest(
    val entries: List<LocalRendererAssetManifestEntry>,
) {
    init {
        val duplicateManifestPaths = entries
            .groupingBy { it.manifestRelativePath }
            .eachCount()
            .filterValues { count -> count > 1 }
            .keys
        require(duplicateManifestPaths.isEmpty()) {
            "Renderer asset manifest cannot contain duplicate paths: ${duplicateManifestPaths.joinToString()}."
        }
        require(entries.none { it.manifestRelativePath == HASH_MANIFEST_FILE }) {
            "Renderer asset manifest must not hash itself."
        }
        require(entries.any { it.manifestRelativePath == METADATA_LOCK_FILE }) {
            "Renderer asset metadata lock must be included in the SHA-256 manifest."
        }
    }

    fun verifyPackagedAssetHashes(packagedAssetHashes: Map<String, String>) {
        val normalizedPackagedAssetHashes = packagedAssetHashes.mapKeys { (path, _) ->
            normalizeManifestPath(path)
        }

        require(HASH_MANIFEST_FILE !in normalizedPackagedAssetHashes.keys) {
            "Packaged renderer asset hashes must not include the hash manifest itself."
        }

        val manifestHashesByPath = entries.associate { entry ->
            entry.manifestRelativePath to entry.sha256
        }

        val missingPackagedAssets = manifestHashesByPath.keys - normalizedPackagedAssetHashes.keys
        require(missingPackagedAssets.isEmpty()) {
            "Renderer asset manifest references missing packaged assets: ${missingPackagedAssets.joinToString()}."
        }

        val unlistedPackagedAssets = normalizedPackagedAssetHashes.keys - manifestHashesByPath.keys
        require(unlistedPackagedAssets.isEmpty()) {
            "Packaged renderer assets are missing from the SHA-256 manifest: ${unlistedPackagedAssets.joinToString()}."
        }

        val mismatchedHashes = manifestHashesByPath
            .filter { (path, manifestHash) -> normalizedPackagedAssetHashes[path] != manifestHash }
            .keys
        require(mismatchedHashes.isEmpty()) {
            "Renderer asset manifest hash mismatch for: ${mismatchedHashes.joinToString()}."
        }
    }

    fun verifyPackagedAssetBytes(packagedAssetBytes: Map<String, ByteArray>) {
        val packagedAssetHashes = packagedAssetBytes.mapValues { (_, bytes) ->
            bytes.sha256Hex()
        }

        verifyPackagedAssetHashes(packagedAssetHashes)
    }

    companion object {
        const val HASH_MANIFEST_FILE = "renderer-assets.sha256"
        const val METADATA_LOCK_FILE = "renderer-assets.lock"

        fun parse(manifestText: String): LocalRendererAssetManifest {
            val entries = manifestText
                .lineSequence()
                .withIndex()
                .filter { (_, line) -> line.isNotBlank() }
                .map { (index, line) -> parseLine(line, index + 1) }
                .toList()

            return LocalRendererAssetManifest(entries)
        }

        private fun parseLine(
            line: String,
            lineNumber: Int,
        ): LocalRendererAssetManifestEntry {
            val match = HASH_MANIFEST_LINE.matchEntire(line)
                ?: throw IllegalArgumentException("Malformed renderer asset manifest line $lineNumber.")
            val sha256 = match.groupValues[1]
            val manifestRelativePath = normalizeManifestPath(match.groupValues[2])

            return LocalRendererAssetManifestEntry(
                path = LocalRendererAssetPath(
                    LocalRendererAssetPath.RENDERER_ASSET_ROOT + manifestRelativePath,
                ),
                sha256 = sha256,
            )
        }

        private fun normalizeManifestPath(path: String): String {
            require(path == path.trim()) {
                "Renderer asset manifest path cannot contain leading or trailing whitespace."
            }
            val normalizedPath = path
            require(normalizedPath.isNotBlank()) { "Renderer asset manifest path cannot be blank." }
            require(!normalizedPath.startsWith(LocalRendererAssetPath.RENDERER_ASSET_ROOT)) {
                "Renderer asset manifest paths must be relative to the renderer asset root."
            }
            LocalRendererAssetPath(LocalRendererAssetPath.RENDERER_ASSET_ROOT + normalizedPath)
            return normalizedPath
        }

        private val HASH_MANIFEST_LINE = Regex("([0-9a-f]{64})[ \\t]+\\*?(.+)")
    }
}

private fun String.isCleanMetadataField(): Boolean =
    isNotBlank() &&
        this == trim() &&
        !contains('|') &&
        none { it < ' ' } &&
        !containsRendererMetadataUrlMarker()

private fun String.containsRendererMetadataUrlMarker(): Boolean {
    val lowercaseValue = lowercase(Locale.ROOT)
    val normalizedValues = setOf(
        lowercaseValue,
        lowercaseValue.decodeRendererMetadataPercentEscapesRepeatedly(),
        lowercaseValue.decodeRendererMetadataHtmlNumericEntities(),
        lowercaseValue.decodeRendererMetadataJavascriptEscapes(),
        lowercaseValue.decodeRendererMetadataHtmlNumericEntities().decodeRendererMetadataPercentEscapesRepeatedly(),
        lowercaseValue.decodeRendererMetadataJavascriptEscapes().decodeRendererMetadataPercentEscapesRepeatedly(),
    )

    return normalizedValues.any { value ->
        RENDERER_METADATA_URL_MARKERS.any { marker -> marker in value } ||
            RENDERER_METADATA_PROTOCOL_RELATIVE_REFERENCE.containsMatchIn(value)
    }
}

private val RENDERER_METADATA_URL_MARKERS = listOf(
    "http://",
    "https://",
    "javascript:",
    "data:",
    "blob:",
    "filesystem:",
    "file:",
    "content:",
    "http%3a",
    "https%3a",
    "javascript%3a",
    "data%3a",
    "blob%3a",
    "filesystem%3a",
    "file%3a",
    "content%3a",
    "//cdn.",
    "//unpkg.",
    "//jsdelivr.",
    "cdnjs",
    "unpkg",
    "jsdelivr",
)

private val RENDERER_METADATA_PROTOCOL_RELATIVE_REFERENCE = Regex("(^|[^:])//[a-z0-9.-]+")

private fun String.decodeRendererMetadataPercentEscapesRepeatedly(): String {
    var current = this
    repeat(MAX_RENDERER_METADATA_PERCENT_DECODE_PASSES) {
        val decoded = current.decodeRendererMetadataPercentEscapesOnce()
        if (decoded == current) {
            return current
        }
        current = decoded
    }
    return current
}

private fun String.decodeRendererMetadataPercentEscapesOnce(): String {
    val output = StringBuilder(length)
    var index = 0
    while (index < length) {
        val char = this[index]
        if (
            char == '%' &&
            index + 2 < length &&
            this[index + 1].isRendererMetadataHexDigit() &&
            this[index + 2].isRendererMetadataHexDigit()
        ) {
            output.append(substring(index + 1, index + 3).toInt(radix = 16).toChar())
            index += 3
        } else {
            output.append(char)
            index += 1
        }
    }
    return output.toString()
}

private fun String.decodeRendererMetadataHtmlNumericEntities(): String {
    val output = StringBuilder(length)
    var index = 0
    while (index < length) {
        if (this[index] == '&' && index + 3 < length && this[index + 1] == '#') {
            val semicolonIndex = indexOf(';', startIndex = index + 2)
            if (semicolonIndex > index + 2) {
                val entityBody = substring(index + 2, semicolonIndex)
                val radix = if (entityBody.startsWith("x")) 16 else 10
                val digits = if (radix == 16) entityBody.drop(1) else entityBody
                if (
                    digits.isNotBlank() &&
                    digits.length <= MAX_RENDERER_METADATA_ENTITY_DIGITS &&
                    digits.all { digit ->
                        if (radix == 16) digit.isRendererMetadataHexDigit() else digit in '0'..'9'
                    }
                ) {
                    val codeUnit = digits.toInt(radix)
                    if (codeUnit <= Char.MAX_VALUE.code) {
                        output.append(codeUnit.toChar())
                        index = semicolonIndex + 1
                        continue
                    }
                }
            }
        }

        output.append(this[index])
        index += 1
    }
    return output.toString()
}

private fun String.decodeRendererMetadataJavascriptEscapes(): String {
    val output = StringBuilder(length)
    var index = 0
    while (index < length) {
        if (this[index] == '\\' && index + 1 < length) {
            val escapeType = this[index + 1]
            when {
                escapeType == 'x' &&
                    index + 3 < length &&
                    this[index + 2].isRendererMetadataHexDigit() &&
                    this[index + 3].isRendererMetadataHexDigit() -> {
                    output.append(substring(index + 2, index + 4).toInt(radix = 16).toChar())
                    index += 4
                    continue
                }
                escapeType == 'u' &&
                    index + 2 < length &&
                    this[index + 2] == '{' -> {
                    val closingBrace = indexOf('}', startIndex = index + 3)
                    val hexValue = if (closingBrace > index + 3) substring(index + 3, closingBrace) else ""
                    if (
                        hexValue.length <= MAX_RENDERER_METADATA_BRACED_ESCAPE_DIGITS &&
                        hexValue.all { it.isRendererMetadataHexDigit() }
                    ) {
                        val codeUnit = hexValue.toInt(radix = 16)
                        if (codeUnit <= Char.MAX_VALUE.code) {
                            output.append(codeUnit.toChar())
                            index = closingBrace + 1
                            continue
                        }
                    }
                }
                escapeType == 'u' &&
                    index + 5 < length &&
                    this[index + 2].isRendererMetadataHexDigit() &&
                    this[index + 3].isRendererMetadataHexDigit() &&
                    this[index + 4].isRendererMetadataHexDigit() &&
                    this[index + 5].isRendererMetadataHexDigit() -> {
                    output.append(substring(index + 2, index + 6).toInt(radix = 16).toChar())
                    index += 6
                    continue
                }
            }
        }

        output.append(this[index])
        index += 1
    }
    return output.toString()
}

private fun Char.isRendererMetadataHexDigit(): Boolean = this in '0'..'9' || this in 'a'..'f'

private const val MAX_RENDERER_METADATA_PERCENT_DECODE_PASSES = 4
private const val MAX_RENDERER_METADATA_ENTITY_DIGITS = 7
private const val MAX_RENDERER_METADATA_BRACED_ESCAPE_DIGITS = 6

private fun String.hasAllowedPackagedRendererAssetExtension(): Boolean {
    val fileName = substringAfterLast('/')
    if (fileName.startsWith(".") || !fileName.contains('.') || fileName.endsWith(".")) {
        return false
    }

    return fileName.substringAfterLast('.') in ALLOWED_PACKAGED_RENDERER_ASSET_EXTENSIONS
}

private val ALLOWED_PACKAGED_RENDERER_ASSET_EXTENSIONS = setOf(
    "js",
    "mjs",
    "css",
    "html",
    "htm",
    "woff",
    "woff2",
    "ttf",
    "otf",
    "svg",
    "png",
    "jpg",
    "jpeg",
    "webp",
)

private fun ByteArray.sha256Hex(): String =
    MessageDigest.getInstance("SHA-256")
        .digest(this)
        .joinToString(separator = "") { byte -> (byte.toInt() and 0xff).toString(radix = 16).padStart(2, '0') }

data class RichRendererAssetPolicy(
    val surface: RichRendererSurface,
    val assets: List<LocalRendererAsset>,
    val networkRequestsBlocked: Boolean = true,
    val externalNavigationBlocked: Boolean = true,
    val javascriptUrlsBlocked: Boolean = true,
    val dataUrlsBlocked: Boolean = true,
    val iframesBlocked: Boolean = true,
    val remoteSubresourcesBlocked: Boolean = true,
) {
    init {
        require(networkRequestsBlocked) { "Rich renderer surfaces must block network requests." }
        require(externalNavigationBlocked) { "Rich renderer surfaces must block external navigation." }
        require(javascriptUrlsBlocked) { "Rich renderer surfaces must block javascript: URLs." }
        require(dataUrlsBlocked) { "Rich renderer surfaces must block data: URLs." }
        require(iframesBlocked) { "Rich renderer surfaces must block iframes." }
        require(remoteSubresourcesBlocked) { "Rich renderer surfaces must block remote subresources." }
        val duplicateAssetPaths = assets
            .groupingBy { it.path.value }
            .eachCount()
            .filterValues { count -> count > 1 }
            .keys
        require(duplicateAssetPaths.isEmpty()) {
            "Renderer asset policy cannot contain duplicate asset paths: ${duplicateAssetPaths.joinToString()}."
        }
    }

    val usesVendoredAssets: Boolean
        get() = assets.isNotEmpty()

    companion object {
        fun nativeFallback(surface: RichRendererSurface): RichRendererAssetPolicy =
            RichRendererAssetPolicy(surface = surface, assets = emptyList())
    }
}
