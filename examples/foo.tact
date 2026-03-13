// Example Tact file for UniversalMutator smoke-tests.
// Intentionally small; not guaranteed to compile in every environment.

import "@stdlib/deploy";

fun sum(a: Int, b: Int): Int {
    // basic ops + boolean literals
    if (a < b && true) {
        return a + b;
    }
    throwUnless(1024, a != 0);
    return a - b;
}
