# Таблица мутаций Tact

Этот файл — рабочая сводка по текущему `universalmutator/static/tact.rules`.
Таблица ниже описывает фактический unified ruleset после чистки шумных legacy-правил.

## Эффективный ruleset

- стандартный regex-запуск для Tact: `universal.rules` + `tact.rules` + `c_like.rules`
- точечный запуск только Tact-правил: `--only universalmutator/static/tact.rules`
- regex-движок: Python `re`
- Comby-слой для Tact существует отдельно: `universalmutator/comby/tact.rules`

## Краткая таблица

| Статус | Слой | Конструкция | Правило | Эффект | Риск |
| ------ | ---- | ----------- | ------- | ------ | ---- |
| Есть | regex | `import` | `^\s*import\b.* ==> DO_NOT_MUTATE` | исключает import-строки из мутаций | низкий |
| Есть | regex | full-line comments | `^\s*//.* ==> DO_NOT_MUTATE`<br>`^\s*///.* ==> DO_NOT_MUTATE`<br>`^\s*/\*.* ==> DO_NOT_MUTATE`<br>`^\s*\*.* ==> DO_NOT_MUTATE` | не мутирует строки-комментарии | низкий |
| Есть | regex | inline comments | `// ==> SKIP_MUTATING_REST`<br>`/// ==> SKIP_MUTATING_REST`<br>`/\* ==> SKIP_MUTATING_REST` | прекращает мутации в хвосте комментария на строке | низкий |
| Есть | regex | `true` / `false` | `\btrue\b ==> false`<br>`\bfalse\b ==> true` | инвертирует boolean literals | низкий |
| Есть | regex | `throwIf` / `throwUnless` | `\bthrowIf\b ==> throwUnless`<br>`\bthrowUnless\b ==> throwIf` | меняет guard-семантику helper-ов | средний |
| Есть | regex | equality | `(?<![<>=!])==(?!=) ==> !=`<br>`!=(?!=) ==> ==` | инвертирует равенство / неравенство | низкий |
| Есть | regex | ordered comparisons | ` <=  ==>  < `<br>` <=  ==>  == `<br>` >=  ==>  > `<br>` >=  ==>  == `<br>` <  ==>  <= `<br>` <  ==>  > `<br>` >  ==>  >= `<br>` >  ==>  < ` | меняет границы сравнения, не задевая generic-синтаксис | средний |
| Есть | regex | logical ops | `&& ==> \|\|`<br>`\|\| ==> &&`<br>`!! ==> ` | инвертирует boolean-комбинации и optional unwrap | средний |
| Есть | regex | arithmetic ops | `+ -> -`<br>`- -> +`<br>`* -> /`<br>`/ -> *`<br>`+= <-> -=`<br>`*= <-> /=` | мутирует арифметику и compound assignment | средний |
| Есть | regex | shifts / bitwise assignments | `<< <-> >>`<br>`&= -> |=`<br>`\|= -> &=`<br>`^= -> \|=`<br>`^= -> &=` | мутирует направление сдвига и compound bitwise update | средний |
| Есть | regex | null checks | `== null <-> != null` | меняет nullable-guard-логику | низкий |
| Есть | regex | boolean returns | `return true; -> return false;`<br>`return false; -> return true;` | инвертирует простые boolean getter/helper returns | низкий |
| Есть | regex | `min` / `max` | `\bmin\b ==> max`<br>`\bmax\b ==> min` | меняет выбор по границе | средний |
| Есть | regex | `bounce:` | `bounce: true <-> bounce: false` | меняет bounce behavior сообщений | средний |
| Есть | regex | numeric `mode:` | `mode: 0 -> 64`<br>`mode: 64 -> 0/128`<br>`mode: 128 -> 0/64` | меняет отправочные режимы в object literal | высокий |
| Есть | regex | send mode constants | `SendPayGasSeparately -> 0`<br>`SendIgnoreErrors -> 0`<br>`SendRemainingValue -> 0`<br>`SendRemainingBalance -> 0` | убирает важные флаги send mode | высокий |
| Есть | regex | attached value | `value: 0 <-> 1`<br>`context().value -> 0` | мутирует attached TON/value-flow | высокий |
| Есть | regex | integer serialization widths | `as uint256 -> as uint128`<br>`as uint128 -> as uint64`<br>`as uint64 -> as uint32`<br>`as uint32 -> as uint64`<br>`as uint16 -> as uint8`<br>`as uint8 -> as uint16`<br>`as int256 -> as int128`<br>`as int128 -> as int64`<br>`as int64 -> as int32`<br>`as int32 -> as int16`<br>`as int16 -> as int8`<br>`as int8 -> as int16` | меняет сериализацию и width constraints | средний |
| Есть | regex | Tact-specific serializers | `as coins -> as uint64`<br>`as remaining -> as bytes32` | мутирует Tact/TL-B field encoding | высокий |
| Есть | regex | optional field declarations | `Address? -> Address`<br>`Cell? -> Cell`<br>`Slice? -> Slice`<br>`Int? -> Int`<br>`Bool? -> Bool`<br>`String? -> String` | убирает nullable-тип у поля | средний |
| Есть | regex | access control patterns | `sender() == self.owner -> !=`<br>`self.owner == sender() -> !=`<br>`sender() == self.<field> -> !=`<br>`self.<field> == sender() -> !=`<br>`myAddress() == ... -> !=` | бьёт по ACL и auth logic | высокий |
| Есть | regex | security builtin | `acceptMessage(); -> ;` | убирает явное принятие external message | высокий |
| Есть | regex | function kind | `get fun -> fun`<br>`inline fun -> fun`<br>`override inline fun -> override fun`<br>`virtual inline fun -> virtual fun`<br>`abstract inline fun -> abstract fun`<br>`extends fun -> fun`<br>`extends mutates fun -> mutates fun` | меняет ABI/getter exposure, inline-стратегию и extension-method semantics | средний |
| Есть | regex | `message(opcode)` | `message(0x12345678) -> message(0xFFFFFFFF)` | меняет numeric opcode/prefix у сообщения | высокий |
| Есть | regex | receiver kind | `external( -> receive(`<br>`receive( -> external(`)<br>`bounced( -> receive(` | меняет dispatch/entrypoint semantics | высокий |
| Есть | regex | map update helper | `.set( -> .replace(`<br>`.replace( -> .set(` | меняет storage update semantics | высокий |
| Есть | regex | context/time boundary checks | `ctx.value > -> >=`<br>`ctx.value < -> <=`<br>`context().value > -> >=`<br>`context().value < -> <=`<br>`now() > -> >=`<br>`now() < -> <=` | ослабляет/смещает критичные guards по времени и value | средний |

## Что было сознательно убрано из старого `tact.rules`

Из ruleset удалены наиболее шумные regex-мутации, которые давали много `INVALID` или бессмысленных мутантов:

- broad statement replacement вида `... -> throw(0);`
- `require(...) -> throwUnless(...)`
- `self.x -> x`
- `return expr; -> return;`
- широкие `<` / `>` замены, ломающие `map<K, V>` и другой generic-синтаксис
- `message(0x...) -> message(0x0)`
- `.get(...) -> .replaceGet(...)` и обратная замена

## Что ещё приходит из общих правил

Если запускать Tact без `--only`, поверх `tact.rules` подключаются ещё:

- `universal.rules` — базовые мутации арифметики, сравнений, строковых и числовых литералов, `&&/||`, `++/--`, swap аргументов и др.;
- `c_like.rules` — C-like мутации по `if`, `while`, `else` и части boolean-ветвлений.

Поэтому фактическое покрытие при обычном `mutate foo.tact tact ...` шире, чем один только `static/tact.rules`.

## Что пока не покрыто точечными Tact-правилами

Есть ещё Tact-формы, для которых пока нет узких и достаточно чистых regex-правил:

- более аккуратные мутации `message(opcode)` с низким числом invalid-мутантов и без риска конфликтов opcodes
- аккуратные мутации `SendParameters { ... }` с зависимостями между `value`, `mode`, `bounce`, `code`, `data`
- безопасные мутации `!!`, различающие optional unwrap и иные контексты
- более точные storage/collection-мутации для `map<K, V>`, arrays и nested optionals

## Что лучше делать не чистым regex-ом

Слишком хрупко для `static/tact.rules` без AST или хотя бы Comby:

- глубокая переработка `receive(...)` / `external(...)` / `bounced(...)` по сигнатуре сообщений
- мутации вложенных `SendParameters { ... }` и `message(...)` object literal-ов
- перестановка/удаление полей в `message` / `struct`
- мутации generic-типов `map<K, V>` и сложных nested type forms
- структурные преобразования control-flow и многострочных guard-блоков
