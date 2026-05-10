package com.fastmd.mobile

import android.content.Intent
import android.content.pm.PackageManager
import android.content.pm.ResolveInfo
import android.net.Uri
import android.os.Build
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith

@RunWith(AndroidJUnit4::class)
class MainActivityIntentContractTest {
    private val context = InstrumentationRegistry.getInstrumentation().targetContext
    private val packageManager = context.packageManager

    @Test
    fun launcherIntentResolvesToExportedMainActivity() {
        val intent = Intent(Intent.ACTION_MAIN)
            .addCategory(Intent.CATEGORY_LAUNCHER)
            .setPackage(context.packageName)

        assertMainActivityResolution(intent)
    }

    @Test
    fun markdownViewIntentResolvesToExportedMainActivity() {
        val intent = Intent(Intent.ACTION_VIEW)
            .addCategory(Intent.CATEGORY_DEFAULT)
            .setDataAndType(Uri.parse("content://com.fastmd.mobile.test/sample.md"), "text/markdown")
            .setPackage(context.packageName)

        assertMainActivityResolution(intent)
    }

    @Test
    fun sharedTextIntentResolvesToExportedMainActivity() {
        val intent = Intent(Intent.ACTION_SEND)
            .addCategory(Intent.CATEGORY_DEFAULT)
            .setType("text/plain")
            .putExtra(Intent.EXTRA_TEXT, "# Shared Markdown")
            .setPackage(context.packageName)

        assertMainActivityResolution(intent)
    }

    private fun assertMainActivityResolution(intent: Intent) {
        val matches = packageManager.queryActivities(intent)
        val mainActivityMatches = matches.filter { match ->
            match.activityInfo.packageName == context.packageName &&
                match.activityInfo.name == MainActivity::class.java.name
        }

        assertTrue("Expected MainActivity to resolve $intent", mainActivityMatches.isNotEmpty())
        mainActivityMatches.forEach { match ->
            assertTrue("MainActivity must remain exported for external document entry", match.activityInfo.exported)
            assertEquals(context.packageName, match.activityInfo.packageName)
        }
    }

    private fun PackageManager.queryActivities(intent: Intent): List<ResolveInfo> {
        val flags = if (intent.categories?.contains(Intent.CATEGORY_DEFAULT) == true) {
            PackageManager.MATCH_DEFAULT_ONLY
        } else {
            0
        }

        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            queryIntentActivities(
                intent,
                PackageManager.ResolveInfoFlags.of(flags.toLong()),
            )
        } else {
            @Suppress("DEPRECATION")
            queryIntentActivities(intent, flags)
        }
    }
}
