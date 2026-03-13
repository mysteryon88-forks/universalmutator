// Example Tolk file for UniversalMutator smoke-tests.
// Intentionally small; not guaranteed to compile in every environment.
import "another-file"

fun sum(a: int, b: int): int {
    val coeff = 5;
    if (a < b && true) {
        return a + b;
    }
    return a - b;
}

// Minimal entrypoint to satisfy the compiler.
fun onInternalMessage() {
    // no-op
}
