// Example Tolk file for UniversalMutator smoke-tests.
// Intentionally small; not guaranteed to compile in every environment.
import "another-file"

struct (0x12345678) CounterIncrement {
    incBy: uint32
}

type AllowedMessage = CounterIncrement | null

fun CounterIncrement.bump(mutate self): self {
    self.incBy += 1;
    return self;
}

get fun currentCounter(): int {
    return 0;
}

fun classify(value: AllowedMessage, body: slice): int {
    val msg = AllowedMessage.fromSlice(body);
    if (value is CounterIncrement && true) {
        var mode = BounceMode.NoBounce;
        mode = BounceMode.RichBounce;
        return value.incBy;
    }
    if (msg !is CounterIncrement) {
        return 0;
    }
    return msg.incBy;
}

fun onBouncedMessage(in: InMessageBounced) {
    // no-op
}

// Minimal entrypoint to satisfy handler/entrypoint examples.
fun onInternalMessage(in: InMessage) {
    // no-op
}
