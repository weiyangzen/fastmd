# Malicious HTML

Raw HTML must be treated as untrusted content.

<script>alert("FastMD must not execute script")</script>

<img src="x" onerror="alert('no inline handlers')" />

<iframe src="https://example.com/tracker"></iframe>
