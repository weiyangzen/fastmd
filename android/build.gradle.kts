plugins {
    alias(libs.plugins.android.application) apply false
    alias(libs.plugins.android.library) apply false
    alias(libs.plugins.kotlin.android) apply false
}

val auditRendererAssets by tasks.registering(Exec::class) {
    group = "verification"
    description = "Audits Android rich renderer assets, WebView usage, and web-runtime exclusions."

    workingDir = projectDir
    commandLine("bash", "tools/audit_renderer_assets.sh")
}

val testRendererAssetAudit by tasks.registering(Exec::class) {
    group = "verification"
    description = "Runs regression tests for the Android rich renderer asset audit gate."

    workingDir = projectDir
    commandLine("bash", "tools/test_renderer_asset_audit.sh")
}

val testRendererRequestBlockingAudit by tasks.registering(Exec::class) {
    group = "verification"
    description = "Runs regression tests for the Android rich renderer request-blocking audit gate."

    workingDir = projectDir
    commandLine("bash", "tools/test_renderer_request_blocking_audit.sh")
}

val auditRendererRequestBlocking by tasks.registering(Exec::class) {
    group = "verification"
    description = "Audits Android rich renderer request-blocking contracts for WebView-capable surfaces."

    workingDir = projectDir
    commandLine("bash", "tools/audit_renderer_request_blocking.sh")
}

val auditPerformanceReport by tasks.registering(Exec::class) {
    group = "verification"
    description = "Audits Android Stage 1 performance posture and prints the local fixture/profile report."

    workingDir = projectDir
    commandLine("bash", "tools/audit_performance_report.sh")
}

val auditSecurityReport by tasks.registering(Exec::class) {
    group = "verification"
    description = "Audits Android Stage 1 manifest, renderer asset, and web-runtime security posture."

    workingDir = projectDir
    commandLine(
        "bash",
        "-c",
        "bash tools/audit_stage1_manifest.sh && bash tools/audit_renderer_assets.sh && bash tools/audit_renderer_request_blocking.sh",
    )
}

val auditRichFixtureRenderReport by tasks.registering(Exec::class) {
    group = "verification"
    description = "Audits Android Stage 1 native rich Markdown fixture rendering coverage."

    workingDir = projectDir
    commandLine("bash", "tools/audit_rich_fixture_render.sh")
}

tasks.register("stage1AndroidRendererAssetGates") {
    group = "verification"
    description = "Runs Android Stage 1 renderer asset packaging, offline, and request-blocking gates."

    dependsOn(auditRendererAssets, testRendererAssetAudit, auditRendererRequestBlocking, testRendererRequestBlockingAudit)
}

tasks.register("stage1AndroidPerformanceReport") {
    group = "verification"
    description = "Captures the Android Stage 1 source-level performance report."

    dependsOn(auditPerformanceReport)
}

tasks.register("stage1AndroidSecurityAuditReport") {
    group = "verification"
    description = "Captures the Android Stage 1 source-level security audit report."

    dependsOn(auditSecurityReport)
}

tasks.register("stage1AndroidRichFixtureRenderReport") {
    group = "verification"
    description = "Captures the Android Stage 1 rich fixture render report."

    dependsOn(auditRichFixtureRenderReport)
}

subprojects {
    fun wireRendererAssetGateIntoCheck() {
        tasks.named("check").configure {
            dependsOn(rootProject.tasks.named("stage1AndroidRendererAssetGates"))
        }
    }

    plugins.withId("com.android.application") {
        wireRendererAssetGateIntoCheck()
    }
    plugins.withId("com.android.library") {
        wireRendererAssetGateIntoCheck()
    }
}
