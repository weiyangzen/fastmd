package com.fastmd.mobile.core.render

import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertSame
import org.junit.Assert.assertTrue
import org.junit.Test
import java.security.MessageDigest

class RichRendererAssetPolicyTest {
    @Test
    fun nativeFallbackSurfacesUseNoVendoredAssetsButStayLockedDown() {
        RichRendererSurface.entries.forEach { surface ->
            val policy = RichRendererAssetPolicy.nativeFallback(surface)

            assertFalse("Native fallback should not package renderer assets for $surface.", policy.usesVendoredAssets)
            assertTrue("Network requests must stay blocked for $surface.", policy.networkRequestsBlocked)
            assertTrue("External navigation must stay blocked for $surface.", policy.externalNavigationBlocked)
            assertTrue("javascript: URLs must stay blocked for $surface.", policy.javascriptUrlsBlocked)
            assertTrue("data: URLs must stay blocked for $surface.", policy.dataUrlsBlocked)
            assertTrue("iframes must stay blocked for $surface.", policy.iframesBlocked)
            assertTrue("Remote subresources must stay blocked for $surface.", policy.remoteSubresourcesBlocked)
        }
    }

    @Test
    fun vendoredAssetsMustLiveUnderLocalRendererRoot() {
        LocalRendererAssetPath("fastmd-renderers/math/mathjax-lite.js")

        assertIllegalArgument { LocalRendererAssetPath("math/mathjax-lite.js") }
        assertIllegalArgument { LocalRendererAssetPath("fastmd-renderers/") }
        assertIllegalArgument { LocalRendererAssetPath("/fastmd-renderers/math/mathjax-lite.js") }
        assertIllegalArgument { LocalRendererAssetPath("fastmd-renderers/../secret.js") }
        assertIllegalArgument { LocalRendererAssetPath("fastmd-renderers/./mathjax-lite.js") }
        assertIllegalArgument { LocalRendererAssetPath("fastmd-renderers/math//mathjax-lite.js") }
        assertIllegalArgument { LocalRendererAssetPath("fastmd-renderers/%2e%2e/secret.js") }
        assertIllegalArgument { LocalRendererAssetPath("fastmd-renderers/math\\mathjax-lite.js") }
        assertIllegalArgument { LocalRendererAssetPath("fastmd-renderers/math/mathjax-lite.js?remote=https://cdn.example/math.js") }
        assertIllegalArgument { LocalRendererAssetPath("fastmd-renderers/math/mathjax-lite.js#https://cdn.example/math.js") }
        assertIllegalArgument { LocalRendererAssetPath("fastmd-renderers/math/mathjax-lite.js\nhttps://cdn.example/math.js") }
        assertIllegalArgument { LocalRendererAssetPath("https://cdn.example/math.js") }
        assertIllegalArgument { LocalRendererAssetPath("file:///android_asset/fastmd-renderers/math.js") }
        assertIllegalArgument { LocalRendererAssetPath("content://com.fastmd.mobile/math.js") }
        assertIllegalArgument { LocalRendererAssetPath("data:text/javascript,alert(1)") }
    }

    @Test
    fun vendoredAssetHashesMustBeLowercaseSha256() {
        LocalRendererAsset(
            kind = RichRendererAssetKind.JavaScript,
            path = LocalRendererAssetPath("fastmd-renderers/math/mathjax-lite.js"),
            sha256 = "a".repeat(64),
        )

        assertIllegalArgument {
            LocalRendererAsset(
                kind = RichRendererAssetKind.StyleSheet,
                path = LocalRendererAssetPath("fastmd-renderers/math/math.css"),
                sha256 = "A".repeat(64),
            )
        }
        assertIllegalArgument {
            LocalRendererAsset(
                kind = RichRendererAssetKind.Font,
                path = LocalRendererAssetPath("fastmd-renderers/math/math.woff2"),
                sha256 = "a".repeat(63),
            )
        }
    }

    @Test
    fun rendererAssetManifestParsesAndVerifiesPackagedHashes() {
        val scriptHash = "a".repeat(64)
        val styleHash = "b".repeat(64)
        val fontHash = "c".repeat(64)
        val lockHash = "d".repeat(64)
        val manifest = """
            $scriptHash  math/math.js
            $styleHash *math/math.css
            $fontHash  math/fonts/math.woff2
            $lockHash  renderer-assets.lock
        """.trimIndent()

        LocalRendererAssetManifest
            .parse(manifest)
            .verifyPackagedAssetHashes(
                mapOf(
                    "math/math.js" to scriptHash,
                    "math/math.css" to styleHash,
                    "math/fonts/math.woff2" to fontHash,
                    "renderer-assets.lock" to lockHash,
                ),
            )
    }

    @Test
    fun localRendererPackageVerifierComputesPackagedHashesAndLocksMetadataOffline() {
        val scriptBytes = "renderMermaidOffline();".encodeToByteArray()
        val styleBytes = ".fastmd-mermaid{display:block}".encodeToByteArray()
        val metadataLock = """
            # path|upstream name|upstream version|license notes|sha256
            mermaid/renderer.js|FastMD offline fixture|test-fixture|Test-only local fixture|${scriptBytes.sha256Hex()}
            mermaid/renderer.css|FastMD offline fixture|test-fixture|Test-only local fixture|${styleBytes.sha256Hex()}
        """.trimIndent()
        val manifest = """
            ${scriptBytes.sha256Hex()}  mermaid/renderer.js
            ${styleBytes.sha256Hex()}  mermaid/renderer.css
            ${metadataLock.encodeToByteArray().sha256Hex()}  renderer-assets.lock
        """.trimIndent()

        LocalRendererAssetPackageVerifier.verifyOfflinePackage(
            manifestText = manifest,
            metadataLockText = metadataLock,
            packagedAssetBytes = mapOf(
                "mermaid/renderer.js" to scriptBytes,
                "mermaid/renderer.css" to styleBytes,
                "renderer-assets.lock" to metadataLock.encodeToByteArray(),
            ),
        )
    }

    @Test
    fun localRendererPackageVerifierRejectsRemoteNavigationAndNetworkApiMarkers() {
        val safeScriptBytes = "renderMathOffline();".encodeToByteArray()
        val remoteScriptBytes = "const remote = \"https://cdn.example/math.js\";".encodeToByteArray()
        val networkApiScriptBytes = "const load = (path) => fetch(path);".encodeToByteArray()
        val metadataLock = """
            math/renderer.js|FastMD offline fixture|test-fixture|Test-only local fixture|${safeScriptBytes.sha256Hex()}
            math/blocked-remote.js|FastMD offline fixture|test-fixture|Test-only local fixture|${remoteScriptBytes.sha256Hex()}
            math/blocked-network-api.js|FastMD offline fixture|test-fixture|Test-only local fixture|${networkApiScriptBytes.sha256Hex()}
        """.trimIndent()
        val manifest = """
            ${safeScriptBytes.sha256Hex()}  math/renderer.js
            ${remoteScriptBytes.sha256Hex()}  math/blocked-remote.js
            ${networkApiScriptBytes.sha256Hex()}  math/blocked-network-api.js
            ${metadataLock.encodeToByteArray().sha256Hex()}  renderer-assets.lock
        """.trimIndent()

        assertIllegalArgument {
            LocalRendererAssetPackageVerifier.verifyOfflinePackage(
                manifestText = manifest,
                metadataLockText = metadataLock,
                packagedAssetBytes = mapOf(
                    "math/renderer.js" to safeScriptBytes,
                    "math/blocked-remote.js" to remoteScriptBytes,
                    "math/blocked-network-api.js" to networkApiScriptBytes,
                    "renderer-assets.lock" to metadataLock.encodeToByteArray(),
                ),
            )
        }
    }

    @Test
    fun localRendererPackageVerifierRejectsEncodedDangerousMarkers() {
        assertOfflinePackageRejectsAsset(
            "math/escaped-url.js",
            "const remote = \"\\u0068\\u0074\\u0074\\u0070\\u0073\\u003a//cdn.example/math.js\";",
        )
        assertOfflinePackageRejectsAsset(
            "math/module-renderer.mjs",
            "export const load = (path) => fetch(path);",
        )
        assertOfflinePackageRejectsAsset(
            "math/braced-escaped-url.js",
            "const remote = \"\\u{68}\\u{74}\\u{74}\\u{70}\\u{73}\\u{3a}//cdn.example/math.js\";",
        )
        assertOfflinePackageRejectsAsset(
            "math/hex-escaped-api.js",
            "const loader = \\x66\\x65\\x74\\x63\\x68('/renderer-helper.js');",
        )
        assertOfflinePackageRejectsAsset(
            "math/entity-url.html",
            "<a href=\"javascript&#x3a;alert(1)\">open</a>",
        )
        assertOfflinePackageRejectsAsset(
            "math/double-percent-url.css",
            ".math{background:url(https%253a%252f%252fcdn.example%252fmath.css)}",
        )
    }

    @Test
    fun localRendererPackageVerifierRejectsDynamicCodeExecutionMarkers() {
        assertOfflinePackageRejectsAsset(
            "math/eval.js",
            "eval('renderMathOffline()');",
        )
        assertOfflinePackageRejectsAsset(
            "math/function-constructor.js",
            "const run = Function('return renderMathOffline()');",
        )
        assertOfflinePackageRejectsAsset(
            "math/new-function-constructor.js",
            "const run = new Function('return renderMathOffline()');",
        )
        assertOfflinePackageRejectsAsset(
            "math/string-timeout.js",
            "setTimeout('renderMathOffline()', 0);",
        )
        assertOfflinePackageRejectsAsset(
            "math/escaped-eval.js",
            "\\u0065\\u0076\\u0061\\u006c('renderMathOffline()');",
        )
    }

    @Test
    fun localRendererPackageVerifierRejectsSvgActiveContentAndRemoteReferences() {
        assertOfflinePackageRejectsAsset(
            "mermaid/diagram.svg",
            """<svg><script>alert(1)</script></svg>""",
        )
        assertOfflinePackageRejectsAsset(
            "mermaid/remote-image.svg",
            """<svg><image href="https://cdn.example/diagram.png"/></svg>""",
        )
        assertOfflinePackageRejectsAsset(
            "mermaid/onload.svg",
            """<svg onload="window.open('fastmd://unexpected')"></svg>""",
        )
    }

    @Test
    fun localRendererPackageVerifierRejectsMissingMismatchedAndUnlistedPackagedAssets() {
        val scriptBytes = "renderMathOffline();".encodeToByteArray()
        val styleBytes = ".fastmd-math{display:inline}".encodeToByteArray()
        val metadataLock = """
            math/renderer.js|FastMD offline fixture|test-fixture|Test-only local fixture|${scriptBytes.sha256Hex()}
            math/renderer.css|FastMD offline fixture|test-fixture|Test-only local fixture|${styleBytes.sha256Hex()}
        """.trimIndent()
        val manifest = """
            ${scriptBytes.sha256Hex()}  math/renderer.js
            ${styleBytes.sha256Hex()}  math/renderer.css
            ${metadataLock.encodeToByteArray().sha256Hex()}  renderer-assets.lock
        """.trimIndent()

        assertIllegalArgument {
            LocalRendererAssetPackageVerifier.verifyOfflinePackage(
                manifestText = manifest,
                metadataLockText = metadataLock,
                packagedAssetBytes = mapOf(
                    "math/renderer.js" to scriptBytes,
                    "renderer-assets.lock" to metadataLock.encodeToByteArray(),
                ),
            )
        }
        assertIllegalArgument {
            LocalRendererAssetPackageVerifier.verifyOfflinePackage(
                manifestText = manifest,
                metadataLockText = metadataLock,
                packagedAssetBytes = mapOf(
                    "math/renderer.js" to "tampered".encodeToByteArray(),
                    "math/renderer.css" to styleBytes,
                    "renderer-assets.lock" to metadataLock.encodeToByteArray(),
                ),
            )
        }
        assertIllegalArgument {
            LocalRendererAssetPackageVerifier.verifyOfflinePackage(
                manifestText = manifest,
                metadataLockText = metadataLock,
                packagedAssetBytes = mapOf(
                    "math/renderer.js" to scriptBytes,
                    "math/renderer.css" to styleBytes,
                    "math/extra.js" to "extra".encodeToByteArray(),
                    "renderer-assets.lock" to metadataLock.encodeToByteArray(),
                ),
            )
        }
    }

    @Test
    fun rendererAssetMetadataLockParsesAndVerifiesManifestHashes() {
        val scriptHash = "a".repeat(64)
        val styleHash = "b".repeat(64)
        val fontHash = "c".repeat(64)
        val lockHash = "d".repeat(64)
        val manifest = LocalRendererAssetManifest.parse(
            """
                $scriptHash  math/math.js
                $styleHash  math/math.css
                $fontHash  math/fonts/math.woff2
                $lockHash  renderer-assets.lock
            """.trimIndent(),
        )
        val metadataLock = """
            # path|upstream name|upstream version|license notes|sha256
            math/math.js|FastMD offline fixture|test-fixture|Test-only local fixture|$scriptHash
            math/math.css|FastMD offline fixture|test-fixture|Test-only local fixture|$styleHash
            math/fonts/math.woff2|FastMD offline fixture|test-fixture|Test-only local fixture|$fontHash
        """.trimIndent()

        LocalRendererAssetMetadataLock
            .parse(metadataLock)
            .verifyMatchesManifest(manifest)
    }

    @Test
    fun rendererAssetManifestRequiresMetadataLockAndRejectsSelfHashing() {
        assertIllegalArgument {
            LocalRendererAssetManifest.parse("${"a".repeat(64)}  math/math.js")
        }
        assertIllegalArgument {
            LocalRendererAssetManifest.parse(
                """
                    ${"a".repeat(64)}  renderer-assets.sha256
                    ${"b".repeat(64)}  renderer-assets.lock
                """.trimIndent(),
            )
        }
    }

    @Test
    fun rendererAssetManifestRejectsMalformedDuplicateAndEscapingPaths() {
        assertIllegalArgument {
            LocalRendererAssetManifest.parse("not-a-sha  math/math.js")
        }
        assertIllegalArgument {
            LocalRendererAssetManifest.parse(
                """
                    ${"a".repeat(64)}  math/math.js
                    ${"b".repeat(64)}  math/math.js
                    ${"c".repeat(64)}  renderer-assets.lock
                """.trimIndent(),
            )
        }
        assertIllegalArgument {
            LocalRendererAssetManifest.parse(
                """
                    ${"a".repeat(64)}  ../math.js
                    ${"b".repeat(64)}  renderer-assets.lock
                """.trimIndent(),
            )
        }
        assertIllegalArgument {
            LocalRendererAssetManifest.parse(
                """
                    ${"a".repeat(64)}  math/%2e%2e/secret.js
                    ${"b".repeat(64)}  renderer-assets.lock
                """.trimIndent(),
            )
        }
        assertIllegalArgument {
            LocalRendererAssetManifest.parse(
                """
                    ${"a".repeat(64)}  fastmd-renderers/math/math.js
                    ${"b".repeat(64)}  renderer-assets.lock
                """.trimIndent(),
            )
        }
        assertIllegalArgument {
            LocalRendererAssetManifest.parse(
                """
                    ${"a".repeat(64)}  math/math.js 
                    ${"b".repeat(64)}  renderer-assets.lock
                """.trimIndent(),
            )
        }
        assertIllegalArgument {
            LocalRendererAssetManifest.parse(
                """
                    ${"a".repeat(64)}  math/config.json
                    ${"b".repeat(64)}  renderer-assets.lock
                """.trimIndent(),
            )
        }
        assertIllegalArgument {
            LocalRendererAssetManifest.parse(
                """
                    ${"a".repeat(64)}  math/renderer.wasm
                    ${"b".repeat(64)}  renderer-assets.lock
                """.trimIndent(),
            )
        }
    }

    @Test
    fun rendererAssetMetadataLockRejectsMalformedDuplicateAndEscapingPaths() {
        assertIllegalArgument {
            LocalRendererAssetMetadataLock.parse("math/math.js|missing-fields")
        }
        assertIllegalArgument {
            LocalRendererAssetMetadataLock.parse(
                """
                    math/math.js|FastMD offline fixture|test-fixture|Test-only local fixture|${"a".repeat(64)}
                    math/math.js|FastMD offline fixture|test-fixture|Test-only local fixture|${"b".repeat(64)}
                """.trimIndent(),
            )
        }
        assertIllegalArgument {
            LocalRendererAssetMetadataLock.parse(
                "../math.js|FastMD offline fixture|test-fixture|Test-only local fixture|${"a".repeat(64)}",
            )
        }
        assertIllegalArgument {
            LocalRendererAssetMetadataLock.parse(
                "math/%2e%2e/secret.js|FastMD offline fixture|test-fixture|Test-only local fixture|${"a".repeat(64)}",
            )
        }
        assertIllegalArgument {
            LocalRendererAssetMetadataLock.parse(
                "fastmd-renderers/math/math.js|FastMD offline fixture|test-fixture|Test-only local fixture|${
                    "a".repeat(64)
                }",
            )
        }
        assertIllegalArgument {
            LocalRendererAssetMetadataLock.parse(
                "math/math.js |FastMD offline fixture|test-fixture|Test-only local fixture|${"a".repeat(64)}",
            )
        }
        assertIllegalArgument {
            LocalRendererAssetMetadataLock.parse(
                "math/config.json|FastMD offline fixture|test-fixture|Test-only local fixture|${"a".repeat(64)}",
            )
        }
        assertIllegalArgument {
            LocalRendererAssetMetadataLock.parse(
                "math/renderer.wasm|FastMD offline fixture|test-fixture|Test-only local fixture|${"a".repeat(64)}",
            )
        }
    }

    @Test
    fun rendererAssetMetadataLockRejectsMissingFieldsAndManifestFiles() {
        assertIllegalArgument {
            LocalRendererAssetMetadataLock.parse(
                "math/math.js||test-fixture|Test-only local fixture|${"a".repeat(64)}",
            )
        }
        assertIllegalArgument {
            LocalRendererAssetMetadataLock.parse(
                "math/math.js| FastMD offline fixture|test-fixture|Test-only local fixture|${"a".repeat(64)}",
            )
        }
        assertIllegalArgument {
            LocalRendererAssetMetadataLock.parse(
                "math/math.js|FastMD offline fixture|test-fixture|Apache-2.0|extra|${"a".repeat(64)}",
            )
        }
        assertIllegalArgument {
            LocalRendererAssetMetadataLock.parse(
                "renderer-assets.sha256|FastMD offline fixture|test-fixture|Test-only local fixture|${"a".repeat(64)}",
            )
        }
        assertIllegalArgument {
            LocalRendererAssetMetadataLock.parse(
                "renderer-assets.lock|FastMD offline fixture|test-fixture|Test-only local fixture|${"a".repeat(64)}",
            )
        }
        assertIllegalArgument {
            LocalRendererAssetMetadataLock.parse(
                "math/math.js|FastMD offline fixture|test-fixture|Test-only local fixture|${"A".repeat(64)}",
            )
        }
        assertIllegalArgument {
            LocalRendererAssetMetadataLock.parse(
                "math/math.js|FastMD offline fixture\nhttps://cdn.example/math.js|test-fixture|Test-only local fixture|${
                    "a".repeat(64)
                }",
            )
        }
        assertIllegalArgument {
            LocalRendererAssetMetadataLock.parse(
                "math/math.js|FastMD offline fixture|https://cdn.example/math.js|Test-only local fixture|${
                    "a".repeat(64)
                }",
            )
        }
        assertIllegalArgument {
            LocalRendererAssetMetadataLock.parse(
                "math/math.js|FastMD offline fixture|test-fixture|See https%3A%2F%2Fcdn.example%2Fmath.js|${
                    "a".repeat(64)
                }",
            )
        }
        assertIllegalArgument {
            LocalRendererAssetMetadataLock.parse(
                "math/math.js|FastMD offline fixture|test-fixture|See https%253A%252F%252Fcdn.example%252Fmath.js|${
                    "a".repeat(64)
                }",
            )
        }
        assertIllegalArgument {
            LocalRendererAssetMetadataLock.parse(
                "math/math.js|FastMD offline fixture|test-fixture|See https&#58;//cdn.example/math.js|${
                    "a".repeat(64)
                }",
            )
        }
        assertIllegalArgument {
            LocalRendererAssetMetadataLock.parse(
                "math/math.js|FastMD offline fixture|test-fixture|See \\u0068\\u0074\\u0074\\u0070\\u0073\\u003a//cdn.example/math.js|${
                    "a".repeat(64)
                }",
            )
        }
        assertIllegalArgument {
            LocalRendererAssetMetadataLock.parse(
                "math/math.js|FastMD offline fixture|test-fixture|See //cdn.example/math.js|${"a".repeat(64)}",
            )
        }
        assertIllegalArgument {
            LocalRendererAssetMetadataLock.parse(
                "math/math.js|FastMD offline fixture|test-fixture|javascript:alert(1)|${"a".repeat(64)}",
            )
        }
    }

    @Test
    fun rendererAssetMetadataLockRejectsMissingUnlistedAndMismatchedManifestHashes() {
        val manifest = LocalRendererAssetManifest.parse(
            """
                ${"a".repeat(64)}  math/math.js
                ${"b".repeat(64)}  math/math.css
                ${"c".repeat(64)}  renderer-assets.lock
            """.trimIndent(),
        )

        assertIllegalArgument {
            LocalRendererAssetMetadataLock
                .parse("math/math.js|FastMD offline fixture|test-fixture|Test-only local fixture|${"a".repeat(64)}")
                .verifyMatchesManifest(manifest)
        }
        assertIllegalArgument {
            LocalRendererAssetMetadataLock
                .parse(
                    """
                        math/math.js|FastMD offline fixture|test-fixture|Test-only local fixture|${"a".repeat(64)}
                        math/math.css|FastMD offline fixture|test-fixture|Test-only local fixture|${"b".repeat(64)}
                        math/extra.js|FastMD offline fixture|test-fixture|Test-only local fixture|${"d".repeat(64)}
                    """.trimIndent(),
                )
                .verifyMatchesManifest(manifest)
        }
        assertIllegalArgument {
            LocalRendererAssetMetadataLock
                .parse(
                    """
                        math/math.js|FastMD offline fixture|test-fixture|Test-only local fixture|${"f".repeat(64)}
                        math/math.css|FastMD offline fixture|test-fixture|Test-only local fixture|${"b".repeat(64)}
                    """.trimIndent(),
                )
                .verifyMatchesManifest(manifest)
        }
    }

    @Test
    fun rendererAssetManifestRejectsMissingUnlistedAndMismatchedPackagedHashes() {
        val manifest = LocalRendererAssetManifest.parse(
            """
                ${"a".repeat(64)}  math/math.js
                ${"b".repeat(64)}  renderer-assets.lock
            """.trimIndent(),
        )

        assertIllegalArgument {
            manifest.verifyPackagedAssetHashes(
                mapOf(
                    "renderer-assets.lock" to "b".repeat(64),
                ),
            )
        }
        assertIllegalArgument {
            manifest.verifyPackagedAssetHashes(
                mapOf(
                    "math/math.js" to "a".repeat(64),
                    "math/extra.js" to "c".repeat(64),
                    "renderer-assets.lock" to "b".repeat(64),
                ),
            )
        }
        assertIllegalArgument {
            manifest.verifyPackagedAssetHashes(
                mapOf(
                    "math/math.js" to "f".repeat(64),
                    "renderer-assets.lock" to "b".repeat(64),
                ),
            )
        }
        assertIllegalArgument {
            manifest.verifyPackagedAssetHashes(
                mapOf(
                    "math/math.js" to "a".repeat(64),
                    "renderer-assets.lock" to "b".repeat(64),
                    "renderer-assets.sha256" to "c".repeat(64),
                ),
            )
        }
    }

    @Test
    fun localRendererPackageVerifierRejectsUnsupportedPackagedAssetTypes() {
        val jsonBytes = """{"remote":"https://cdn.example/math.js"}""".encodeToByteArray()
        val metadataLock = """
            math/config.json|FastMD offline fixture|test-fixture|Test-only local fixture|${jsonBytes.sha256Hex()}
        """.trimIndent()
        val manifest = """
            ${jsonBytes.sha256Hex()}  math/config.json
            ${metadataLock.encodeToByteArray().sha256Hex()}  renderer-assets.lock
        """.trimIndent()

        assertIllegalArgument {
            LocalRendererAssetPackageVerifier.verifyOfflinePackage(
                manifestText = manifest,
                metadataLockText = metadataLock,
                packagedAssetBytes = mapOf(
                    "math/config.json" to jsonBytes,
                    "renderer-assets.lock" to metadataLock.encodeToByteArray(),
                ),
            )
        }
    }

    @Test
    fun rendererSurfaceCannotOptOutOfRequestAndNavigationBlocking() {
        val asset = LocalRendererAsset(
            kind = RichRendererAssetKind.JavaScript,
            path = LocalRendererAssetPath("fastmd-renderers/mermaid/mermaid-lite.js"),
            sha256 = "b".repeat(64),
        )

        assertIllegalArgument {
            RichRendererAssetPolicy(RichRendererSurface.Mermaid, listOf(asset), networkRequestsBlocked = false)
        }
        assertIllegalArgument {
            RichRendererAssetPolicy(RichRendererSurface.Mermaid, listOf(asset), externalNavigationBlocked = false)
        }
        assertIllegalArgument {
            RichRendererAssetPolicy(RichRendererSurface.Mermaid, listOf(asset), javascriptUrlsBlocked = false)
        }
        assertIllegalArgument {
            RichRendererAssetPolicy(RichRendererSurface.Mermaid, listOf(asset), dataUrlsBlocked = false)
        }
        assertIllegalArgument {
            RichRendererAssetPolicy(RichRendererSurface.Mermaid, listOf(asset), iframesBlocked = false)
        }
        assertIllegalArgument {
            RichRendererAssetPolicy(RichRendererSurface.Mermaid, listOf(asset), remoteSubresourcesBlocked = false)
        }
    }

    @Test
    fun rendererSurfaceRejectsDuplicateVendoredAssetPaths() {
        val script = LocalRendererAsset(
            kind = RichRendererAssetKind.JavaScript,
            path = LocalRendererAssetPath("fastmd-renderers/mermaid/renderer.js"),
            sha256 = "c".repeat(64),
        )
        val stylesheet = LocalRendererAsset(
            kind = RichRendererAssetKind.StyleSheet,
            path = LocalRendererAssetPath("fastmd-renderers/mermaid/renderer.css"),
            sha256 = "d".repeat(64),
        )

        val policy = RichRendererAssetPolicy(RichRendererSurface.Mermaid, listOf(script, stylesheet))

        assertTrue("Distinct vendored renderer assets should be accepted.", policy.usesVendoredAssets)
        assertIllegalArgument {
            RichRendererAssetPolicy(RichRendererSurface.Mermaid, listOf(script, script.copy()))
        }
        assertIllegalArgument {
            RichRendererAssetPolicy(
                RichRendererSurface.Mermaid,
                listOf(script, script.copy(sha256 = "e".repeat(64))),
            )
        }
        assertIllegalArgument {
            RichRendererAssetPolicy(
                RichRendererSurface.Mermaid,
                listOf(script, script.copy(kind = RichRendererAssetKind.StyleSheet)),
            )
        }
    }

    @Test
    fun requestPolicyAllowsOnlyBundledRendererAssets() {
        assertAllowed(
            "file:///android_asset/fastmd-renderers/math/math.js",
            RichRendererRequestKind.InitialDocument,
        )
        assertAllowed(
            "file:///android_asset/fastmd-renderers/math/math.css",
            RichRendererRequestKind.RendererAsset,
        )
        assertAllowed(
            "file:///android_asset/fastmd-renderers/math/fonts/math.woff2",
            RichRendererRequestKind.Subresource,
        )
        assertAllowed(
            "file:///android_asset/fastmd-renderers/math/renderer.mjs",
            RichRendererRequestKind.RendererAsset,
        )

        assertBlocked(
            "file:///android_asset/fastmd-renderers/",
            RichRendererRequestKind.RendererAsset,
            RichRendererRequestBlockReason.NonRendererFile,
        )
        assertBlocked(
            "file:///android_asset/fastmd-renderers/../secret.js",
            RichRendererRequestKind.RendererAsset,
            RichRendererRequestBlockReason.NonRendererFile,
        )
        assertBlocked(
            "file:///android_asset/fastmd-renderers/%2e%2e/secret.js",
            RichRendererRequestKind.RendererAsset,
            RichRendererRequestBlockReason.NonRendererFile,
        )
        assertBlocked(
            "file:///android_asset/fastmd-renderers/math/%2f/secret.js",
            RichRendererRequestKind.RendererAsset,
            RichRendererRequestBlockReason.NonRendererFile,
        )
        assertBlocked(
            "file:///android_asset/fastmd-renderers/math%2fsecret.js",
            RichRendererRequestKind.RendererAsset,
            RichRendererRequestBlockReason.NonRendererFile,
        )
        assertBlocked(
            "file:///android_asset/fastmd-renderers/math\\secret.js",
            RichRendererRequestKind.RendererAsset,
            RichRendererRequestBlockReason.NonRendererFile,
        )
        assertBlocked(
            "file:///android_asset/fastmd-renderers/math/math.js?remote=https://cdn.example/math.js",
            RichRendererRequestKind.RendererAsset,
            RichRendererRequestBlockReason.NonRendererFile,
        )
        assertBlocked(
            "file:///android_asset/fastmd-renderers/math/math.js#https://cdn.example/math.js",
            RichRendererRequestKind.RendererAsset,
            RichRendererRequestBlockReason.NonRendererFile,
        )
        assertBlocked(
            "file:///android_asset/fastmd-renderers/math/math.js\nhttps://cdn.example/math.js",
            RichRendererRequestKind.RendererAsset,
            RichRendererRequestBlockReason.NonRendererFile,
        )
        assertBlocked(
            "file:///android_asset/fastmd-renderers/math/https://cdn.example/math.js",
            RichRendererRequestKind.RendererAsset,
            RichRendererRequestBlockReason.NonRendererFile,
        )
        assertBlocked(
            "file:///android_asset/fastmd-renderers/renderer-assets.sha256",
            RichRendererRequestKind.RendererAsset,
            RichRendererRequestBlockReason.NonRendererFile,
        )
        assertBlocked(
            "file:///android_asset/fastmd-renderers/renderer-assets.lock",
            RichRendererRequestKind.RendererAsset,
            RichRendererRequestBlockReason.NonRendererFile,
        )
        assertBlocked(
            "file:///android_asset/fastmd-renderers/math/config.json",
            RichRendererRequestKind.RendererAsset,
            RichRendererRequestBlockReason.NonRendererFile,
        )
        assertBlocked(
            "file:///android_asset/fastmd-renderers/math/renderer",
            RichRendererRequestKind.RendererAsset,
            RichRendererRequestBlockReason.NonRendererFile,
        )
        assertBlocked(
            "file:///android_asset/fastmd-renderers/math/.secret",
            RichRendererRequestKind.RendererAsset,
            RichRendererRequestBlockReason.NonRendererFile,
        )
        assertBlocked(
            "file:///android_asset/fastmd-renderers/math/renderer.",
            RichRendererRequestKind.RendererAsset,
            RichRendererRequestBlockReason.NonRendererFile,
        )
        assertBlocked(
            "file:///android_asset/public/image.png",
            RichRendererRequestKind.RendererAsset,
            RichRendererRequestBlockReason.NonRendererFile,
        )
    }

    @Test
    fun requestPolicyBlocksRemoteAndDangerousRendererRequests() {
        assertBlocked(
            "https://cdn.example/mermaid.js",
            RichRendererRequestKind.Subresource,
            RichRendererRequestBlockReason.NetworkRequest,
        )
        assertBlocked(
            "http://example.com/math.css",
            RichRendererRequestKind.Subresource,
            RichRendererRequestBlockReason.NetworkRequest,
        )
        assertBlocked(
            "//example.com/math.js",
            RichRendererRequestKind.Subresource,
            RichRendererRequestBlockReason.NetworkRequest,
        )
        assertBlocked(
            "javascript:alert(1)",
            RichRendererRequestKind.Navigation,
            RichRendererRequestBlockReason.JavascriptUrl,
        )
        assertBlocked(
            "JAVASCRIPT:alert(1)",
            RichRendererRequestKind.Subresource,
            RichRendererRequestBlockReason.JavascriptUrl,
        )
        assertBlocked(
            "data:text/html;base64,PGgxPkJhZDwvaDE+",
            RichRendererRequestKind.InitialDocument,
            RichRendererRequestBlockReason.DataUrl,
        )
        assertBlocked(
            "blob:https://cdn.example/renderer-fragment",
            RichRendererRequestKind.Subresource,
            RichRendererRequestBlockReason.BlobUrl,
        )
        assertBlocked(
            "filesystem:https://cdn.example/temporary/renderer.js",
            RichRendererRequestKind.Subresource,
            RichRendererRequestBlockReason.FileSystemUrl,
        )
        assertBlocked(
            "content://com.fastmd.mobile/private.js",
            RichRendererRequestKind.RendererAsset,
            RichRendererRequestBlockReason.ContentUri,
        )
    }

    @Test
    fun requestPolicyClassifiesPercentEncodedDangerousRendererRequests() {
        assertBlocked(
            "https%3A%2F%2Fcdn.example%2Fmermaid.js",
            RichRendererRequestKind.Subresource,
            RichRendererRequestBlockReason.NetworkRequest,
        )
        assertBlocked(
            "JaVaScRiPt%3Aalert(1)",
            RichRendererRequestKind.Navigation,
            RichRendererRequestBlockReason.JavascriptUrl,
        )
        assertBlocked(
            "data%3Atext/html;base64,PGgxPkJhZDwvaDE%2B",
            RichRendererRequestKind.InitialDocument,
            RichRendererRequestBlockReason.DataUrl,
        )
        assertBlocked(
            "blob%3Ahttps%3A%2F%2Fcdn.example%2Frenderer-fragment",
            RichRendererRequestKind.Subresource,
            RichRendererRequestBlockReason.BlobUrl,
        )
        assertBlocked(
            "filesystem%3Ahttps%3A%2F%2Fcdn.example%2Ftemporary%2Frenderer.js",
            RichRendererRequestKind.Subresource,
            RichRendererRequestBlockReason.FileSystemUrl,
        )
        assertBlocked(
            "content%3A%2F%2Fcom.fastmd.mobile%2Fprivate.js",
            RichRendererRequestKind.RendererAsset,
            RichRendererRequestBlockReason.ContentUri,
        )
        assertBlocked(
            "file%3A%2F%2F%2Fandroid_asset%2Ffastmd-renderers%2Fmath%2Fmath.js",
            RichRendererRequestKind.RendererAsset,
            RichRendererRequestBlockReason.NonRendererFile,
        )
        assertBlocked(
            "file:///android_asset/fastmd-renderers/math/%2e%2e/secret.js",
            RichRendererRequestKind.RendererAsset,
            RichRendererRequestBlockReason.NonRendererFile,
        )
        assertBlocked(
            "https%253A%252F%252Fcdn.example%252Fmermaid.js",
            RichRendererRequestKind.Subresource,
            RichRendererRequestBlockReason.NetworkRequest,
        )
        assertBlocked(
            "javascript%253Aalert(1)",
            RichRendererRequestKind.InitialDocument,
            RichRendererRequestBlockReason.JavascriptUrl,
        )
        assertBlocked(
            "data%253Atext/html;base64,PGgxPkJhZDwvaDE%252B",
            RichRendererRequestKind.InitialDocument,
            RichRendererRequestBlockReason.DataUrl,
        )
        assertBlocked(
            "blob%253Ahttps%253A%252F%252Fcdn.example%252Frenderer-fragment",
            RichRendererRequestKind.Subresource,
            RichRendererRequestBlockReason.BlobUrl,
        )
        assertBlocked(
            "filesystem%253Ahttps%253A%252F%252Fcdn.example%252Ftemporary%252Frenderer.js",
            RichRendererRequestKind.Subresource,
            RichRendererRequestBlockReason.FileSystemUrl,
        )
        assertBlocked(
            "content%253A%252F%252Fcom.fastmd.mobile%252Fprivate.js",
            RichRendererRequestKind.RendererAsset,
            RichRendererRequestBlockReason.ContentUri,
        )
    }

    @Test
    fun requestPolicyBlocksExternalNavigationAndIframes() {
        assertBlocked(
            "file:///android_asset/fastmd-renderers/math/math.js",
            RichRendererRequestKind.Navigation,
            RichRendererRequestBlockReason.ExternalNavigation,
        )
        assertBlocked(
            "fastmd://unexpected",
            RichRendererRequestKind.Navigation,
            RichRendererRequestBlockReason.ExternalNavigation,
        )
        assertBlocked(
            "file:///android_asset/fastmd-renderers/math/frame.html",
            RichRendererRequestKind.Iframe,
            RichRendererRequestBlockReason.Iframe,
        )
        assertBlocked(
            "mailto:security@example.com",
            RichRendererRequestKind.Subresource,
            RichRendererRequestBlockReason.UnknownScheme,
        )
        assertBlocked(
            "   ",
            RichRendererRequestKind.Subresource,
            RichRendererRequestBlockReason.BlankUrl,
        )
    }

    private fun assertIllegalArgument(block: () -> Unit) {
        try {
            block()
        } catch (_: IllegalArgumentException) {
            return
        }

        throw AssertionError("Expected IllegalArgumentException.")
    }

    private fun assertAllowed(
        rawUrl: String,
        kind: RichRendererRequestKind,
    ) {
        val decision = RichRendererRequestPolicy.decide(rawUrl, kind)

        assertTrue("Expected renderer request to be allowed: $rawUrl", decision.allowed)
        assertNull("Allowed renderer request should not carry a block reason.", decision.blockReason)
    }

    private fun assertBlocked(
        rawUrl: String,
        kind: RichRendererRequestKind,
        expectedReason: RichRendererRequestBlockReason,
    ) {
        val decision = RichRendererRequestPolicy.decide(rawUrl, kind)

        assertFalse("Expected renderer request to be blocked: $rawUrl", decision.allowed)
        assertSame(expectedReason, decision.blockReason)
    }

    private fun assertOfflinePackageRejectsAsset(
        path: String,
        assetText: String,
    ) {
        val assetBytes = assetText.encodeToByteArray()
        val metadataLock = """
            $path|FastMD offline fixture|test-fixture|Test-only local fixture|${assetBytes.sha256Hex()}
        """.trimIndent()
        val manifest = """
            ${assetBytes.sha256Hex()}  $path
            ${metadataLock.encodeToByteArray().sha256Hex()}  renderer-assets.lock
        """.trimIndent()

        assertIllegalArgument {
            LocalRendererAssetPackageVerifier.verifyOfflinePackage(
                manifestText = manifest,
                metadataLockText = metadataLock,
                packagedAssetBytes = mapOf(
                    path to assetBytes,
                    "renderer-assets.lock" to metadataLock.encodeToByteArray(),
                ),
            )
        }
    }

    private fun ByteArray.sha256Hex(): String =
        MessageDigest.getInstance("SHA-256")
            .digest(this)
            .joinToString(separator = "") { byte -> (byte.toInt() and 0xff).toString(radix = 16).padStart(2, '0') }
}
