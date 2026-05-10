package com.fastmd.mobile.core.link

import com.fastmd.mobile.core.error.FastMdErrorCategory
import com.fastmd.mobile.core.error.FastMdErrorCode
import java.util.Locale

data class LinkTarget(
    val rawTarget: String,
    val displayText: String? = null,
) {
    init {
        require(rawTarget.isNotBlank()) { "Link target cannot be blank." }
        require(displayText?.isNotBlank() != false) { "Link display text cannot be blank when present." }
    }

    val normalizedScheme: String?
        get() = rawTarget.schemePrefixOrNull()

    val isInternalAnchor: Boolean
        get() = rawTarget.startsWith("#")
}

sealed interface LinkPolicyDecision {
    val target: LinkTarget

    data class Allowed(
        override val target: LinkTarget,
        val reason: String,
    ) : LinkPolicyDecision {
        init {
            require(reason.isNotBlank()) { "Allowed link reason cannot be blank." }
        }
    }

    data class Confirm(
        override val target: LinkTarget,
        val reason: String,
    ) : LinkPolicyDecision {
        init {
            require(reason.isNotBlank()) { "Confirm link reason cannot be blank." }
        }
    }

    data class Blocked(
        override val target: LinkTarget,
        val code: FastMdErrorCode,
        val reason: String,
    ) : LinkPolicyDecision {
        init {
            require(code.category == FastMdErrorCategory.Link ||
                code.category == FastMdErrorCategory.Security) {
                "Blocked link decisions must use link or security error codes."
            }
            require(reason.isNotBlank()) { "Blocked link reason cannot be blank." }
        }
    }
}

data class LinkPolicy(
    val allowedAnchorLinks: Boolean = true,
    val confirmExternalSchemes: Set<String> = defaultConfirmExternalSchemes,
    val blockedSchemes: Set<String> = defaultBlockedSchemes,
    val allowRelativeDocumentLinks: Boolean = false,
) {
    init {
        require(confirmExternalSchemes.none { it.isBlank() }) {
            "External confirmation schemes cannot contain blank values."
        }
        require(blockedSchemes.none { it.isBlank() }) { "Blocked schemes cannot contain blank values." }
    }

    fun decide(target: LinkTarget): LinkPolicyDecision {
        val scheme = target.normalizedScheme

        return when {
            scheme in blockedSchemes -> LinkPolicyDecision.Blocked(
                target = target,
                code = FastMdErrorCode.LinkBlockedScheme,
                reason = "Scheme is blocked by the Stage 1 link policy.",
            )

            scheme in confirmExternalSchemes -> LinkPolicyDecision.Confirm(
                target = target,
                reason = "External links require an explicit user confirmation.",
            )

            scheme != null -> LinkPolicyDecision.Blocked(
                target = target,
                code = FastMdErrorCode.LinkBlockedScheme,
                reason = "Scheme is not in the Stage 1 allowlist.",
            )

            target.isInternalAnchor && allowedAnchorLinks -> LinkPolicyDecision.Allowed(
                target = target,
                reason = "Internal document anchors are handled inside the reader.",
            )

            allowRelativeDocumentLinks -> LinkPolicyDecision.Confirm(
                target = target,
                reason = "Relative document links require explicit user confirmation.",
            )

            else -> LinkPolicyDecision.Blocked(
                target = target,
                code = FastMdErrorCode.LinkRequiresConfirmation,
                reason = "Relative document links are disabled until local navigation is implemented.",
            )
        }
    }

    companion object {
        val defaultConfirmExternalSchemes: Set<String> = setOf("http", "https", "mailto", "tel")
        val defaultBlockedSchemes: Set<String> = setOf(
            "javascript",
            "data",
            "file",
            "content",
            "intent",
            "android-app",
            "vbscript",
        )
    }
}

private fun String.schemePrefixOrNull(): String? {
    val separatorIndex = indexOf(':')
    if (separatorIndex <= 0) {
        return null
    }

    val candidate = substring(0, separatorIndex)
    val isValidScheme = candidate.first().isLetter() &&
        candidate.all { it.isLetterOrDigit() || it == '+' || it == '-' || it == '.' }

    return if (isValidScheme) {
        candidate.lowercase(Locale.US)
    } else {
        null
    }
}
