package com.fastmd.mobile.core.diagnostics

object DiagnosticsRedactionPolicy {
    private val forbiddenFragments = listOf(
        "://",
        "/Users/",
        "/home/",
        "\\Users\\",
        "rawReference=",
        "displayName=",
        "path=",
        "uri=",
        "query=",
        "clipboard=",
        "source=",
        "markdown=",
        "body=",
    )

    fun requireRedacted(text: String): String {
        val forbidden = forbiddenFragments.firstOrNull { fragment ->
            text.contains(fragment, ignoreCase = true)
        }
        require(forbidden == null) {
            "Diagnostics report contains sensitive fragment marker: $forbidden"
        }
        require(text.lines().all { line -> line.length <= MAX_LINE_LENGTH }) {
            "Diagnostics report lines must remain compact and summary-only."
        }
        return text
    }

    private const val MAX_LINE_LENGTH = 160
}
