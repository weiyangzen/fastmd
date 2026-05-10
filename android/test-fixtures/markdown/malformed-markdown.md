# Malformed Markdown

This fixture intentionally leaves structures open.

> Quote starts here
>
> - Nested item
>   - deeper item

| Missing | Table |
| --- |
| too | many | cells |

```kotlin
fun broken() {
    println("unterminated fence")
