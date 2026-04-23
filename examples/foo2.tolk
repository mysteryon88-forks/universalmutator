// Focused Tolk probe for rules that produced INVALID mutants in foo.tolk.
const ERR = 41

struct (0x11111111) Foo2Increment {
    value: uint32
}

struct (0x22222222) Foo2Decrement {
    value: uint32
}

type Foo2Message = Foo2Increment | Foo2Decrement

struct Foo2Window {
    due: coins
    paid: coins
}

fun Foo2Window.getStorageDuePayment(self): coins {
    return self.due;
}

fun Foo2Window.getStoragePaidPayment(self): coins {
    return self.paid;
}

fun calculateForwardFee(cells: int, bits: int, isMasterchain: bool): coins {
    return cells + bits;
}

fun calculateForwardFeeWithoutLumpPrice(cells: int, bits: int, isMasterchain: bool): coins {
    return cells + bits;
}

fun calculateGasFee(isMasterchain: int, gasUsed: int): coins {
    return isMasterchain + gasUsed;
}

fun calculateGasFeeWithoutFlatPrice(isMasterchain: int, gasUsed: int): coins {
    return isMasterchain + gasUsed;
}

fun acceptExternalMessage() {}

fun dict.iDictGetFirst(self, keyBits: int) {
    return keyBits;
}

fun dict.iDictGetLast(self, keyBits: int) {
    return keyBits;
}

fun dict.uDictGetFirst(self, keyBits: int) {
    return keyBits;
}

fun dict.uDictGetLast(self, keyBits: int) {
    return keyBits;
}

fun dict.uDictDeleteFirstAndGet(self, keyBits: int) {
    return keyBits;
}

fun dict.uDictDeleteLastAndGet(self, keyBits: int) {
    return keyBits;
}

fun dict.iDictGetNextOrEqual(self, keyBits: int, pivot: int) {
    return keyBits + pivot;
}

fun dict.iDictGetPrevOrEqual(self, keyBits: int, pivot: int) {
    return keyBits + pivot;
}

fun dict.iDictGetNext(self, keyBits: int, pivot: int) {
    return keyBits + pivot;
}

fun dict.uDictGetPrev(self, keyBits: int, pivot: int) {
    return keyBits + pivot;
}

fun dict.uDictGetNext(self, keyBits: int, pivot: int) {
    return keyBits + pivot;
}

fun dict.uDictGetNextOrEqual(self, keyBits: int, pivot: int) {
    return keyBits + pivot;
}

fun dict.uDictGetPrevOrEqual(self, keyBits: int, pivot: int) {
    return keyBits + pivot;
}

fun address.isInternal(self): bool {
    return true;
}

fun address.isExternal(self): bool {
    return false;
}

fun Foo2Increment.bump(mutate self): self {
    self.value += 1;
    return self;
}

fun Foo2Increment.peek(mutate self): int {
    return self.value;
}

fun foo2Assert(amount: int) {
    assert (amount > 0) throw ERR;
}

fun foo2Bool(flag: bool): int {
    var a = 1;
    var b = 2;
    if (flag && true) {
        a += 1;
    }
    if (flag && true && a > 0) {
        b += 1;
    }
    if ((flag && true)) {
        b += 1;
    }
    return a | b;
}

fun foo2Casts(a: uint64, b: int64): int {
    var typed: uint32 = 1;
    var casted = a as uint32;
    var rnd = random.uint256();
    return typed + casted + rnd + b;
}

fun foo2Stdlib(c: cell, dest: address): int {
    var fwd = calculateForwardFee(0, 100, true);
    var fwdNoLump = calculateForwardFeeWithoutLumpPrice(0, 100, true);
    var gas = calculateGasFee(0, 100);
    var gasNoFlat = calculateGasFeeWithoutFlatPrice(0, 100);
    acceptExternalMessage();

    var window = Foo2Window { due: 1, paid: 2 };
    var dueFee = window.getStorageDuePayment();
    var paidFee = window.getStoragePaidPayment();
    var internalKind = dest.isInternal();
    var externalKind = dest.isExternal();

    var loaded = c.beginParse().loadDict();
    var firstSigned = loaded.iDictGetFirst(256);
    var lastSigned = loaded.iDictGetLast(256);
    var firstUnsigned = loaded.uDictGetFirst(256);
    var lastUnsigned = loaded.uDictGetLast(256);
    var deletedSigned = loaded.uDictDeleteFirstAndGet(256);
    var deletedUnsigned = loaded.uDictDeleteLastAndGet(256);
    var nextSigned = loaded.iDictGetNextOrEqual(256, 1);
    var prevSigned = loaded.iDictGetPrevOrEqual(256, 1);
    var nextOnlySigned = loaded.iDictGetNext(256, 1);
    var prevUnsigned = loaded.uDictGetPrev(256, 1);
    var nextUnsigned = loaded.uDictGetNext(256, 1);
    var nextOrEqualUnsigned = loaded.uDictGetNextOrEqual(256, 1);
    var prevOrEqualUnsigned = loaded.uDictGetPrevOrEqual(256, 1);

    return fwd + fwdNoLump + gas + gasNoFlat + dueFee + paidFee +
        firstSigned + lastSigned + firstUnsigned + lastUnsigned +
        deletedSigned + deletedUnsigned + nextSigned + prevSigned +
        nextOnlySigned + prevUnsigned + nextUnsigned + nextOrEqualUnsigned +
        prevOrEqualUnsigned + internalKind as int + externalKind as int;
}

fun foo2Classify(value: Foo2Message | null, body: slice): int {
    val parsed = Foo2Message.fromSlice(body);
    if (value is Foo2Increment) {
        value.bump();
        return value.value;
    }
    if (parsed !is Foo2Increment) {
        return 0;
    }
    return parsed.value;
}

fun onInternalMessage(in: InMessage) {
    // Probe-only entrypoint.
}
