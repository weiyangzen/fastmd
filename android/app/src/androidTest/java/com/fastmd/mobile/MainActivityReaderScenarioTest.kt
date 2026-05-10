package com.fastmd.mobile

import android.content.Intent
import androidx.compose.ui.test.assertTextContains
import androidx.compose.ui.test.hasText
import androidx.compose.ui.test.junit4.createEmptyComposeRule
import androidx.compose.ui.test.onNodeWithTag
import androidx.compose.ui.test.onNodeWithText
import androidx.compose.ui.test.performClick
import androidx.compose.ui.test.performTextInput
import androidx.test.core.app.ActivityScenario
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith

@RunWith(AndroidJUnit4::class)
class MainActivityReaderScenarioTest {
    @get:Rule
    val compose = createEmptyComposeRule()

    private val context = InstrumentationRegistry.getInstrumentation().targetContext

    @Test
    fun sharedMarkdownReaderSupportsRenderSearchAndFontTierOnConstrainedRuntime() {
        val intent = Intent(Intent.ACTION_SEND)
            .setClass(context, MainActivity::class.java)
            .setType("text/plain")
            .putExtra(Intent.EXTRA_TEXT, runtimeMarkdown)

        val scenario = ActivityScenario.launch<MainActivity>(intent)
        try {
            compose.waitUntilExists(hasText("Stage 1 Runtime Reader"))
            compose.onNodeWithText("Stage 1 Runtime Reader").assertTextContains("Stage 1 Runtime Reader")
            compose.onNodeWithText("10 lines loaded").assertTextContains("10 lines loaded")
            compose.onNodeWithText("Paragraph with runtime-search-token for connected validation.")
                .assertTextContains("runtime-search-token", substring = true)

            compose.onNodeWithTag("reader-search-field").performTextInput("runtime-search-token")
            compose.waitUntilExists(hasText("1 of 1 matches"))
            compose.onNodeWithText("1 of 1 matches").assertTextContains("1 of 1 matches")

            compose.onNodeWithText("Reader").performClick()
            compose.onNodeWithText("Reader").assertTextContains("Reader")
        } finally {
            scenario.close()
        }
    }

    private fun androidx.compose.ui.test.junit4.ComposeTestRule.waitUntilExists(
        matcher: androidx.compose.ui.test.SemanticsMatcher,
        timeoutMillis: Long = 10_000L,
    ) {
        waitUntil(timeoutMillis = timeoutMillis) {
            onAllNodes(matcher).fetchSemanticsNodes().isNotEmpty()
        }
    }

    private companion object {
        val runtimeMarkdown = """
            |# Stage 1 Runtime Reader
            |
            |Paragraph with runtime-search-token for connected validation.
            |
            |- [x] Native task item
            |- Plain list item
            |
            |```kotlin
            |val stage = 1
            |```
        """.trimMargin()
    }
}
