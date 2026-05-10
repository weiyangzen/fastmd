# Huge Code Block Representative Fixture

```kotlin
fun renderLine(index: Int): String {
    return "line=$index"
}

repeat(20) { index ->
    println(renderLine(index))
}
```
