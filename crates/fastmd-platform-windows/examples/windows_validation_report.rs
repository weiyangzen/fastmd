#[cfg(target_os = "windows")]
fn main() -> Result<(), Box<dyn std::error::Error>> {
    let report = fastmd_platform_windows::capture_live_windows_validation_evidence_report()?;
    print!("{}", report.to_markdown());
    Ok(())
}

#[cfg(not(target_os = "windows"))]
fn main() {
    eprintln!(
        "windows_validation_report must be run on Windows 11 with Explorer frontmost and the pointer resting on a local .md file."
    );
    std::process::exit(1);
}
