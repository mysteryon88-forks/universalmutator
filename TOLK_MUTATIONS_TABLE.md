# Таблица мутаций Tolk для документации

Этот файл — отдельная компактная таблица Tolk-мутаций, собранная по контрактам из `examples/tolk-bench/contracts_Tolk` и по локальной документации Tolk.

Назначение файла:

- быстро вставить таблицу в README, PR или отдельную секцию документации;
- отделить уже реализованные правила от новых кандидатов;
- сразу зафиксировать ограничения regex-подхода, чтобы не переоценивать точность правил.

Источники, на которые опирается таблица:

- контракты из `examples/tolk-bench/contracts_Tolk`;
- `tolk/basic-syntax.mdx`;
- `tolk/syntax/functions-methods.mdx`;
- `tolk/syntax/mutability.mdx`;
- `tolk/features/compiler-optimizations.mdx`;
- `tolk/features/message-handling.mdx`;
- `tolk/features/auto-serialization.mdx`;
- `tolk/features/standard-library.mdx`;
- `tolk/types/type-checks-and-casts.mdx`;
- `tolk/types/unions.mdx`;
- `tolk/types/strings.mdx`;

Regex-движок:

- для `universalmutator/static/tolk.rules` — Python `re`;
- для конструкций с вложенными generic-типами и для многострочных `assert (...) throw ...` желательно иметь Comby-дубль, потому что один regex там быстро становится хрупким.

## Краткая таблица

| Статус | Конструкция | Правило | Эффект | Риск |
| ------ | ----------- | ------- | ------ | ---- |
| Есть (служебное) | `import` | `^\s*import\s ==> DO_NOT_MUTATE` | исключает import-строки из мутаций, чтобы не ломать модульные зависимости шумовыми мутантами | низкий |
| Есть (служебное) | комментарии `//` / `/*` | `// ==> SKIP_MUTATING_REST`<br>`/\* ==> SKIP_MUTATING_REST` | прекращает мутации на оставшейся части комментария | низкий |
| Есть | `true` / `false` | `true ==> false`<br>`false ==> true` | инвертирует boolean literals | низкий |
| Есть | `is` / `!is` | `(?<![!\w])is\b ==> !is`<br>`(?<!\w)!is\b ==> is` | инвертирует runtime-проверку union/nullable-типа | средний |
| Есть | `lazy` | `<code>(^&#124;\s)lazy(\s+) ==> \1</code>` | убирает ленивую десериализацию / ленивую загрузку | средний |
| Есть | `get fun` | `\bget\s+fun\b ==> fun` | убирает getter-экспорт у функции | высокий |
| Есть | `@inline` / `@noinline` | `^(\s*)@inline\b ==> \1@noinline`<br>`^(\s*)@noinline\b ==> \1@inline` | меняет стратегию inlining у функции/метода | высокий |
| Есть | `@inline_ref` | `^(\s*)@inline_ref\b ==> \1@inline` | меняет ref-inlining на обычный inline | высокий |
| Есть | `@pure` | `^(\s*)@pure\b ==> \1` | убирает purity-аннотацию у функции | средний |
| Есть | `@method_id(...)` | `^(\s*)@method_id\s*\(\s*[^)\n]+\s*\) ==> \1@method_id(0)` | подменяет явно заданный TVM `method_id` | очень высокий |
| Есть | `mutate self` | `\bmutate\s+self\b ==> self` | запрещает изменение receiver-а | высокий |
| Есть | параметр `mutate x: T` | `\bmutate\s+(?!self\b)([A-Za-z_]\w+)(\s*:) ==> \1\2` | убирает mutability у обычного параметра, не у `self` | средний |
| Есть | `assert (...) throw E` | `(^\s*)assert\s*\((.+)\)\s*throw\s+([^;\n]+)(;?) ==> \1if (\2) throw \3\4` | меняет guard из "throw on false" в "throw on true" | высокий |
| Есть | postfix non-null assertion `!` | `([A-Za-z0-9_)\]])!(?=[\.,;\)\]\s]) ==> \1` | убирает принудительное снятие nullable-проверки | средний |
| Есть | `uintN` / `intN` | `<code>\buint([1-9]\d?&#124;1\d\d&#124;2[0-4]\d&#124;25[0-6])\b ==> int\1</code><br><code>\bint([1-9]\d?&#124;1\d\d&#124;2[0-4]\d&#124;25[0-6])\b ==> uint\1</code>` | меняет signedness у фиксированной разрядности | высокий |
| Есть | `varuint*` / `varint*` | `\bvaruint16\b ==> varint16`<br>`\bvarint16\b ==> varuint16`<br>`\bvaruint32\b ==> varint32`<br>`\bvarint32\b ==> varuint32` | меняет signedness у variable-width integer family | высокий |
| Есть | `as uintN` / `as intN` | `<code>\bas\s+uint([1-9]\d?&#124;1\d\d&#124;2[0-4]\d&#124;25[0-6])\b ==> as int\1</code><br><code>\bas\s+int([1-9]\d?&#124;1\d\d&#124;2[0-4]\d&#124;25[0-6])\b ==> as uint\1</code>` | меняет signedness у unsafe cast | высокий |
| Есть | `blockchain.logicalTime` / `blockchain.currentBlockLogicalTime` | `\bblockchain\.logicalTime\b ==> blockchain.currentBlockLogicalTime`<br>`\bblockchain\.currentBlockLogicalTime\b ==> blockchain.logicalTime` | подменяет близкие stdlib-источники logical time | высокий |
| Есть | `blockchain.now` / `blockchain.logicalTime` | `\bblockchain\.now\b ==> blockchain.logicalTime` | подменяет Unix time на logical time | высокий |
| Есть | `calculateSizeStrict` / `calculateSize` | `\bcalculateSizeStrict\b ==> calculateSize`<br>`\bcalculateSize\b ==> calculateSizeStrict` | меняет strict/non-strict вариант расчёта размера cell/slice | высокий |
| Есть | `calculateForwardFee` / `calculateForwardFeeWithoutLumpPrice` | `\bcalculateForwardFeeWithoutLumpPrice\b ==> calculateForwardFee`<br>`\bcalculateForwardFee\b ==> calculateForwardFeeWithoutLumpPrice` | меняет вариант расчёта forward fee с учётом lump price и без него | высокий |
| Есть | `calculateGasFee` / `calculateGasFeeWithoutFlatPrice` | `\bcalculateGasFeeWithoutFlatPrice\b ==> calculateGasFee`<br>`\bcalculateGasFee\b ==> calculateGasFeeWithoutFlatPrice` | меняет вариант расчёта gas fee с flat price и без него | высокий |
| Есть | `acceptExternalMessage` / `commitContractDataAndActions` | `\bacceptExternalMessage\b ==> commitContractDataAndActions`<br>`\bcommitContractDataAndActions\b ==> acceptExternalMessage` | меняет два близких stdlib-вызова в external-message flow | очень высокий |
| Есть | `random.uint256` / `random.getSeed` | `\brandom\.uint256\b ==> random.getSeed`<br>`\brandom\.getSeed\b ==> random.uint256` | подменяет новый псевдослучайный value текущим seed и обратно | высокий |
| Есть | `load*` / `preload*` stdlib helpers | `loadRef <-> preloadRef`<br>`loadInt <-> preloadInt`<br>`loadUint <-> preloadUint`<br>`loadBits <-> preloadBits`<br>`loadDict <-> preloadDict`<br>`loadMaybeRef <-> preloadMaybeRef` | меняет mutating parse на non-mutating parse и обратно у документированных stdlib helper-ов | высокий |
| Есть | signed/unsigned stdlib serialization helpers | `loadInt <-> loadUint`<br>`preloadInt <-> preloadUint`<br>`storeInt <-> storeUint` | меняет signedness на уровне stdlib API чтения/записи, а не только типов `intN/uintN` | высокий |
| Есть | slice inspection helpers | `remainingBitsCount <-> remainingRefsCount`<br>`isEmpty -> isEndOfBits`<br>`isEmpty -> isEndOfRefs`<br>`isEndOfBits -> isEmpty`<br>`isEndOfRefs -> isEmpty`<br>`getFirstBits <-> getLastBits` | меняет проверки и срезы slice на близкие, но семантически другие stdlib helper-ы | высокий |
| Есть | storage/message fee helpers | `getStorageDuePayment <-> getStoragePaidPayment`<br>`sendAndEstimateFee <-> estimateFeeWithoutSending` | подменяет близкие helper-ы наблюдения/оценки оплаты и отправки сообщений | очень высокий |
| Есть | address kind helpers | `isInternal <-> isExternal` | меняет классификацию `any_address` между internal/external | высокий |
| Есть | manual message parsing helpers | `loadMessageOp <-> loadMessageQueryId`<br>`storeMessageOp <-> storeMessageQueryId` | подменяет низкоуровневые helper-ы ручного parsing/serialization заголовка сообщения | высокий |
| Есть | low-level dict signedness family | `iDict* <-> uDict*` для get/set/delete/getRef/getNext/... семейств | меняет знаковость integer-key dict API в низкоуровневом stdlib | очень высокий |
| Есть | low-level dict order/navigation helpers | `*GetFirst <-> *GetLast`<br>`*DeleteFirstAndGet <-> *DeleteLastAndGet`<br>`*GetNext <-> *GetPrev`<br>`*GetNextOrEqual <-> *GetPrevOrEqual` | меняет направление и порядок обхода низкоуровневого TVM dictionary API | очень высокий |
| Есть | send mode constants | `\bSEND_MODE_REGULAR\b ==> SEND_MODE_PAY_FEES_SEPARATELY`<br>`\bSEND_MODE_IGNORE_ERRORS\b ==> 0`<br>`\bSEND_MODE_PAY_FEES_SEPARATELY\b ==> 0`<br>`\bSEND_MODE_BOUNCE_ON_ACTION_FAIL\b ==> 0`<br>`\bSEND_MODE_DESTROY\b ==> 0`<br>`\bSEND_MODE_CARRY_ALL_REMAINING_MESSAGE_VALUE\b ==> SEND_MODE_CARRY_ALL_BALANCE`<br>`\bSEND_MODE_CARRY_ALL_BALANCE\b ==> SEND_MODE_CARRY_ALL_REMAINING_MESSAGE_VALUE`<br>`\bSEND_MODE_CARRY_ALL_REMAINING_MESSAGE_VALUE\b ==> 0`<br>`\bSEND_MODE_CARRY_ALL_BALANCE\b ==> 0`<br>`\bSEND_MODE_ESTIMATE_FEE_ONLY\b ==> 0` | удаляет или подменяет documented send mode flags/constants, включая regular/destroy/estimate-fee-only | очень высокий |
| Есть | `RESERVE_MODE_*` | `EXACT_AMOUNT <-> ALL_BUT_AMOUNT`<br>`AT_MOST -> EXACT_AMOUNT`<br>`EXACT_AMOUNT -> AT_MOST`<br>`INCREASE_BY_ORIGINAL_BALANCE -> 0`<br>`NEGATE_AMOUNT -> 0`<br>`BOUNCE_ON_ACTION_FAIL -> 0` | меняет базовый reserve mode и удаляет add-on флаги documented reserve API | очень высокий |
| Есть | numeric mode literals в `.send(...)`, `.sendAndEstimateFee(...)`, `.estimateFeeWithoutSending(...)`, `sendRawMessage(..., mode)`, `reserveToncoinsOnBalance(..., mode)` и `reserveExtraCurrenciesOnBalance(..., ..., mode)` | `<code>0 -&gt; 1</code> и <code>0 -&gt; 2</code> для базовых режимов;<br><code>1/2/16/32/1024 -&gt; 0</code> для drop-мутаций;<br><code>64 -&gt; 128</code>, <code>128 -&gt; 64</code>` | мутирует те же message/reserve режимы, когда код использует literal-числа вместо stdlib-констант, включая fee-estimation и extra-currencies helper-ы | очень высокий |
| Есть | поле `value:` в `createMessage({ ... })` | `(^\s*value:\s*)0(...) ==> \g<1>1...`<br>`(^\s*value:\s*)([1-9]\d*)(...) ==> \g<1>0...`<br>`(^\s*value:\s*)ton(...) ==> \g<1>0...`<br>`(^\s*value:\s*)(simpleCall(...))(...) ==> \g<1>0...`<br>`(^\s*value:\s*)(expr)(...) ==> \g<1>0...` | мутирует явно заданное message value в object literal: `0` делает ненулевым, а числа, `ton(...)`, простые вызовы и другие простые выражения зануляет | высокий |
| Есть | legacy `stringCrc*` / `stringSha256*` | `\bstringCrc32\s*\( ==> stringCrc16(`<br>`\bstringCrc16\s*\( ==> stringCrc32(`<br>`\bstringSha256\s*\( ==> stringSha256_32(`<br>`\bstringSha256_32\s*\( ==> stringSha256(` | покрывает старую function-style форму string compile-time helpers | высокий |
| Есть (Comby) | `StringBuilder.append(...).append(...)` | `StringBuilder.create().append(:[a]).append(:[b]).build() ==> StringBuilder.create().append(:[b]).append(:[a]).build()` | переставляет два соседних сегмента в цепочке сборки строки | высокий |
| Есть (Comby) | default parameter value | `fun :[name](:[before], :[arg]: :[type] = :[default], :[after]) ==> fun :[name](:[before], :[arg]: :[type], :[after])` | убирает documented default parameter value в сигнатуре функции | средний |
| Есть | `throwIfOpcodeDoesNotMatch` | `(\bthrowIfOpcodeDoesNotMatch\s*:\s*)[\w]+ ==> \g<1>63` | возвращает обработку несовпавшего opcode к стандартному коду ошибки | высокий |
| Есть | `BounceMode.*` | `\bBounceMode\.NoBounce\b ==> BounceMode.RichBounce`<br>`\bBounceMode\.Only256BitsOfBody\b ==> BounceMode.RichBounce`<br>`\bBounceMode\.RichBounceOnlyRootCell\b ==> BounceMode.RichBounce` | меняет bounce-семантику исходящих сообщений между no-bounce, cheap bounce и rich bounce | очень высокий |
| Есть | `struct (PREFIX) Name` для любого numeric prefix | `<code>(^\s*struct\s+\()(?:0x[0-9A-Fa-f]+&#124;0b[01]+)(\)\s+[A-Za-z_]\w*) ==> \g&lt;1&gt;0x00000000\2</code><br><code>(^\s*struct\s+\()(?:0x[0-9A-Fa-f]+&#124;0b[01]+)(\)\s+[A-Za-z_]\w*) ==> \g&lt;1&gt;0xFFFFFFFF\2</code>` | обобщает мутацию opcode/prefix на prefix-и любой длины | очень высокий |

## Что уже хорошо обобщается

Уже реализованные правила действительно выглядят не как "мутации под конкретные jetton/nft/wallet-примеры", а как мутации под сам язык Tolk:

- `lazy`, `get fun`, `mutate self`, `is` / `!is` — это документированные языковые конструкции;
- `@inline`, `@noinline`, `@inline_ref`, `@pure`, `@method_id(...)` — это документированные атрибуты функций и методов;
- `uintN`, `intN`, `varuint16`, `varint16`, `varuint32`, `varint32` и `as intN` / `as uintN` — это документированные Tolk-формы числовых типов и unsafe cast;
- `blockchain.now`, `blockchain.logicalTime`, `blockchain.currentBlockLogicalTime`, `calculateSizeStrict`, `calculateSize`, `calculateForwardFee`, `calculateForwardFeeWithoutLumpPrice`, `calculateGasFee`, `calculateGasFeeWithoutFlatPrice`, `acceptExternalMessage`, `commitContractDataAndActions`, `random.uint256`, `random.getSeed`, `SEND_MODE_*`, `RESERVE_MODE_*` — это документированные Tolk stdlib API и constants;
- `stringCrc*` / `stringSha256*` — это документированные Tolk string helpers для compile-time checksum/hash;
- `BounceMode` — это документированный Tolk-специфичный enum для message-handling;
- `struct (prefix)` — это документированный синтаксис автосериализации и message routing.

Самое заметное упущение текущего набора — правило по `struct (prefix)` пока привязано только к восьмизначным hex-opcode. В контрактах из `contracts_Tolk` встречаются и более короткие prefix-и вроде `0x00`, `0x01`, `0x64`, поэтому обобщённое правило из таблицы выше полезно даже без добавления других кандидатов.
Ранее это действительно было главным пробелом набора, но теперь обобщённая версия
для numeric prefix уже добавлена в правила и отражена в таблице.

## Реализованные правила и пояснения

### Числовые мутации, которые уже добавлены

На основе раздела про числа в документации Tolk в правила уже добавлены Solidity-подобные мутации signed/unsigned типов, но адаптированные к Tolk-модели:

- `uintN -> intN`;
- `intN -> uintN`;
- `varuint16 <-> varint16`;
- `varuint32 <-> varint32`;
- `as uintN -> as intN`;
- `as intN -> as uintN`.

Почему именно так:

- в Tolk рантайм-представление общее, но `intN` / `uintN` и `varint` / `varuint` влияют на сериализацию, диапазоны и type-checking;
- это даёт класс мутаций "как в Solidity по signedness", но без выдумывания несуществующих типов вроде `uint`.

Что сознательно не добавлялось:

- `coins <-> varuint16`, потому что `coins` в документации описан как alias к `varuint16`, и это дало бы слишком много почти-эквивалентных мутантов;
- `uintN -> int`, потому что это уже отдельная ось мутаций, связанная не только со signedness, но и с потерей сериализуемой ширины.

### Мутации по Tolk standard library mapping, которые уже добавлены

На основе официальной страницы сравнения standard libraries в правила добавлены несколько узких Tolk-side замен:

- `blockchain.logicalTime <-> blockchain.currentBlockLogicalTime`;
- `blockchain.now -> blockchain.logicalTime`;
- `calculateSizeStrict <-> calculateSize`;
- `calculateForwardFee <-> calculateForwardFeeWithoutLumpPrice`;
- `calculateGasFee <-> calculateGasFeeWithoutFlatPrice`;
- `acceptExternalMessage <-> commitContractDataAndActions`.

Почему именно эти пары:

- это documented Tolk API names, а не внутренние project-specific helpers;
- у них одинаковая или очень близкая форма вызова, поэтому они хорошо ложатся на surface-syntax mutation;
- они проверяют важные предположения вокруг block timing, fee accounting, size accounting и external-message flow.

Риск:

- высокий или очень высокий, потому что это уже мутации не синтаксического сахара, а реально разных stdlib API с заметно отличающейся семантикой.

Что пока сознательно не добавлялось:

- `debug.print <-> debug.printString`, потому что тип аргумента часто важен;
- более далёкие замены вроде `contract.getAddress <-> contract.getOriginalBalance`, потому что они слишком часто будут ломать типы сразу.

### Stdlib parsing, slice inspection и low-level dict мутации, которые уже добавлены

После просмотра `common.tolk`, `gas-payments.tolk` и `tvm-dicts.tolk`
в правила также добавлены более "операционные" stdlib-мутации:

- `load* <-> preload*` для `Ref`, `Int`, `Uint`, `Bits`, `Dict`, `MaybeRef`;
- `loadInt <-> loadUint`, `preloadInt <-> preloadUint`, `storeInt <-> storeUint`;
- `remainingBitsCount <-> remainingRefsCount`;
- `isEmpty -> isEndOfBits` / `isEndOfRefs`, а также обратные переходы в `isEmpty`;
- `getFirstBits <-> getLastBits`;
- `getStorageDuePayment <-> getStoragePaidPayment`;
- `sendAndEstimateFee <-> estimateFeeWithoutSending`;
- `isInternal <-> isExternal`;
- `loadMessageOp <-> loadMessageQueryId`, `storeMessageOp <-> storeMessageQueryId`;
- `iDict* <-> uDict*`;
- `GetFirst <-> GetLast`, `DeleteFirstAndGet <-> DeleteLastAndGet`, `GetNext <-> GetPrev`, `GetNextOrEqual <-> GetPrevOrEqual`.

Почему это полезно:

- это всё documented stdlib surface forms с устойчивыми именами и одинаковой или очень близкой сигнатурой;
- такие мутации проверяют реальные предположения кода про сдвиг курсора slice, signedness, форму обхода dict и различие между "наблюдать" и "менять state / отправлять";
- они хорошо ложатся на regex, потому что здесь меняется один method name, а surrounding syntax сохраняется.

Ограничение:

- low-level dict правила особенно рискованные и могут давать много невалидных мутантов в коде, где signedness ключа жёстко завязана на типы;
- часть `load* <-> preload*`-мутантов будет компилироваться, но ломать дальнейший parsing лишь в runtime, что как раз и полезно для mutation testing.

### Атрибуты функций и методов, которые уже добавлены

На основе раздела про functions/methods и compiler optimizations в правила добавлены:

- `@inline <-> @noinline`;
- `@inline_ref -> @inline`;
- удаление `@pure`;
- `@method_id(...) -> @method_id(0)`.

Почему это полезно:

- это документированные surface-level аннотации Tolk;
- они меняют inlining, purity assumptions и ABI/getter routing через `method_id`;
- это хороший класс мутаций именно для Tolk, а не общий операторный шум.

Отдельно на Comby-уровне добавлено удаление default parameter value из сигнатуры функции,
потому что для regex такая мутация слишком быстро становится хрупкой.

### Send/reserve/value мутации, которые уже добавлены

На основе stdlib и реально встречающихся в `contracts_Tolk` отправочных режимов
в правила добавлены:

- `SEND_MODE_REGULAR -> SEND_MODE_PAY_FEES_SEPARATELY`;
- drop `SEND_MODE_IGNORE_ERRORS`, `SEND_MODE_PAY_FEES_SEPARATELY`, `SEND_MODE_BOUNCE_ON_ACTION_FAIL` через замену на `0`;
- drop `SEND_MODE_DESTROY` и `SEND_MODE_ESTIMATE_FEE_ONLY` через замену на `0`;
- `SEND_MODE_CARRY_ALL_REMAINING_MESSAGE_VALUE <-> SEND_MODE_CARRY_ALL_BALANCE`;
- drop `SEND_MODE_CARRY_ALL_REMAINING_MESSAGE_VALUE` / `SEND_MODE_CARRY_ALL_BALANCE` через замену на `0`;
- `RESERVE_MODE_EXACT_AMOUNT <-> RESERVE_MODE_ALL_BUT_AMOUNT`;
- `RESERVE_MODE_AT_MOST <-> RESERVE_MODE_EXACT_AMOUNT`;
- drop `RESERVE_MODE_INCREASE_BY_ORIGINAL_BALANCE`, `RESERVE_MODE_NEGATE_AMOUNT`, `RESERVE_MODE_BOUNCE_ON_ACTION_FAIL` через замену на `0`;
- те же numeric-мутации для literal-режимов в `.send(...)`, `.sendAndEstimateFee(...)`, `.estimateFeeWithoutSending(...)`, `sendRawMessage(..., mode)`, `reserveToncoinsOnBalance(..., mode)` и `reserveExtraCurrenciesOnBalance(..., ..., mode)`;
- мутации поля `value:` внутри `createMessage({ ... })`: `0 -> 1`, а явные числа, `ton(...)`, простые вызовы и простые выражения -> `0`.

Почему это полезно:

- эти константы реально широко используются в jetton/nft/vesting/wallet контрактах из бенча;
- замена на `0` оставляет выражение синтаксически валидным даже в комбинациях через `|` и `+`;
- numeric-правила ловят проекты, которые используют не константы stdlib, а сразу числа `0/1/2/16/32/64/128/1024`;
- `reserveExtraCurrenciesOnBalance(...)` закрывает ту же reserve-semantics ось для multi-currency case, а не только для TON-only reserve;
- `value:`-мутации бьют по очень частому паттерну zero-valued сервисных сообщений вроде `ReturnExcessesBack`;
- это бьёт по очень важной части observable behavior: отправка сообщений и reserve semantics.

### Строковые мутации, которые уже добавлены

На основе раздела про строки в правила добавлены несколько Tolk-специфичных
string-мутаций:

- legacy function-style варианты `stringCrc*` и `stringSha256*`.

Почему это полезно:

- compile-time string helpers часто участвуют в вычислении dict keys, IDs, constant hashes
  и других встроенных констант.

Что пока оставлено только на Comby-уровне:

- перестановка двух соседних `StringBuilder.append(...)` в цепочке
  `StringBuilder.create().append(a).append(b).build()`, потому что для regex это
  уже слишком хрупкий шаблон.

### 1. Убирать `mutate` у обычных параметров

Документация Tolk отдельно описывает `mutate` не только для `self`, но и для обычных параметров:

- `fun increment(mutate x: int)`;
- `fun readFlags(mutate cs: slice)`;
- `fun Point.resetAndRemember(mutate self, mutate sum: int)`.

В `contracts_Tolk` это встречается регулярно:

- `fun TelegramString.unpackFromSlice(mutate s: slice)`;
- `fun Auction.calcNewOwnerOnExpire(self, mutate myBalance: coins, ...)`;
- `fun Auction.processNewBid(mutate self, mutate myBalance: coins, ...)`.

Почему правило обобщаемое:

- это не idiom конкретного проекта, а часть синтаксиса Tolk;
- правило легко ограничить заголовком `fun ...(`, не задевая call-site формы `f(mutate x)`.

Ограничение:

- если тело функции реально мутирует параметр, мутант станет невалидным и должен отсеиваться compile-check-ом.

### 2. Мутировать single-line `assert (...) throw E`

Синтаксис `assert (cond) throw ERR` прямо документирован в Tolk и очень широко встречается во всех просмотренных контрактах:

- проверки прав доступа;
- проверки opcode/workchain;
- проверки газовых ограничений;
- проверки корректности сериализации и parsing options.

Почему правило полезно:

- оно бьёт не по отдельным операторам внутри условия, а по самой конструкции guard-а;
- это другой класс дефекта, чем обычная замена `==` на `!=`.

Ограничение:

- предложенный regex годится только для однострочных `assert`;
- для многострочных условий лучше дублировать идею в `comby/tolk.rules`.

### 3. Убирать postfix `!` у nullable-значений

Документация Tolk описывает postfix `!` как bypass nullable-check-а. В контрактах встречаются типичные примеры:

- `msg.transferInitiator!`;
- `state.auction!.load()`;
- `configCell!.beginParse()`;
- `adminAddress!`.

Почему правило обобщаемое:

- это базовая Tolk-конструкция nullability;
- встречается и в message parsing, и в storage, и в helper-методах.

Ограничение:

- часть мутантов будет не компилироваться, если без `!` компилятор не может smart-cast-нуть выражение до non-null типа.

### 4. Мутировать `throwIfOpcodeDoesNotMatch`

В документации по автосериализации описан `throwIfOpcodeDoesNotMatch` как стандартная опция unpack-а. В контрактах из папки он встречается в реальном коде:

- `telemint-item-contract.tolk`;
- `wallet-v5-contract.tolk`;
- `c5-register-validation.tolk`;
- `jetton-minter-contract.tolk` в `03_notcoin` и `04_sharded_tgbtc`.

Почему правило обобщаемое:

- это документированная языковая опция десериализации;
- она влияет не на бизнес-логику напрямую, а на parser/error path, что полезно для mutation testing.

Почему в примере выбран `63`:

- это документированный default для `throwIfOpcodeDoesNotMatch`.

### 5. Обобщить мутацию `struct (PREFIX)`

Документация по автосериализации говорит, что prefix у `struct` не обязан быть ровно 32-битным. В контрактах это подтверждается:

- есть длинные opcode вроде `0x7362d09c`;
- есть короткие prefix-и `0x00`, `0x01`, `0x64`.

Почему это стоит выделить отдельно:

- текущая rule в форке ловит только `0x` плюс ровно 8 hex-цифр;
- из-за этого часть реальных Tolk message-prefix-ов просто не мутируется.

Практический вывод:

- даже если не добавлять ни одного нового семейства мутаций, это расширение текущего opcode-rule почти наверняка стоит внести.

## Что пока не стоит оформлять как regex-правила

Есть несколько идей, которые выглядят заманчиво, но для regex-движка `static/*.rules` будут слишком хрупкими:

- удаление отдельных альтернатив из `type Alias = A | B | C`, потому что алиасы часто многострочные;
- переписывание `match`-веток, потому что ветки бывают выражениями, statement-блоками и могут быть вложенными;
- массовая мутация `T?` nullability, потому что `?` в Tolk участвует не только в типах, но и в других синтаксических формах;
- произвольные мутации object-literal-ов `createMessage({ ... })`, потому что там быстро начинаются вложенные блоки и значения со сложной структурой.

Для таких случаев лучше:

- либо делать Comby-правила;
- либо оставлять их на ручной / AST-ориентированный этап.
