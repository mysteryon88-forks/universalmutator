# Таблица мутаций FunC

Актуально для текущих `universalmutator/static/func.rules` и `universalmutator/comby/func.rules`.
Стандартный запуск FunC использует `ton_common.rules` + `func.rules`; общие boolean/comparison/assignment/while/break правила описаны отдельно в `TON_COMMON_MUTATIONS_TABLE.md`.

## Сводка

| Файл                | Количество правил | Комментарий                                           |
| ------------------- | ----------------: | ----------------------------------------------------- |
| `static/func.rules` |               145 | FunC-specific regex-слой                              |
| `comby/func.rules`  |               147 | Comby-аналог для безопасно выражаемых surface-мутаций |
| `ton_common.rules`  |                36 | общий слой, подключается перед `func.rules`           |

## Краткая таблица

| Статус  | Слой          | Конструкция                         | Правило                                                                                   | Эффект                                                                                                           | Риск          |
| ------- | ------------- | ----------------------------------- | ----------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------- | ------------- |
| Есть    | regex + Comby | `#include`, `;;`                    | `#include -> DO_NOT_MUTATE`, `;; -> SKIP_MUTATING_REST`                                   | не мутирует imports и хвосты комментариев                                                                        | низкий        |
| Есть    | regex-only    | comment replacement                 | statement-only `line -> ;; line`                                                          | комментирует простые standalone statements; не трогает `{}`, declarations, `return`, `var`, control-flow headers | средний       |
| Есть    | regex + Comby | FunC `if` forcing                   | `if (cond) -> if (0) / if (1)`                                                            | форсирует ветку через FunC-int boolean                                                                           | высокий       |
| Есть    | regex + Comby | throw helpers                       | `throw_if <-> throw_unless`, `throw_arg_if <-> throw_arg_unless`, uppercase marker swaps  | инвертирует guard-style abort helpers                                                                            | высокий       |
| Есть    | regex + Comby | bitwise operator shuffle            | guarded `^ -> & / \|`, `& -> ^`, `\| -> ^`                                                | меняет bitwise expression; `^/`, `^%`, `^/=` не ломаются                                                         | средний       |
| Есть    | regex + Comby | FunC division assignment            | `/= <-> ~/= / ^/=` с guard для plain `/=`                                                 | меняет rounding mode assignment                                                                                  | высокий       |
| Есть    | regex + Comby | FunC division operator              | `/ <-> ~/ / ^/` с guard для plain `/`                                                     | меняет rounding mode expression                                                                                  | высокий       |
| Есть    | regex + Comby | FunC modulo assignment/operator     | `%= <-> ~%= / ^%=`, `% <-> ~% / ^%`                                                       | меняет rounding mode modulo                                                                                      | высокий       |
| Есть    | regex + Comby | `ifnot`, `until`, `repeat`          | `ifnot -> 0 / 1`, `until -> 0`, `repeat -> 0`                                             | меняет достижимость веток и циклов                                                                               | высокий       |
| Есть    | regex + Comby | function specifiers                 | `inline <-> inline_ref`, remove `inline/inline_ref/impure`                                | меняет inlining и side-effect marker                                                                             | высокий       |
| Удалено | regex + Comby | `method_id` zeroing                 | `method_id(...) -> method_id(0)` удалено                                                  | правило давало устойчивые compile-invalid в FunC fixtures                                                        | высокий       |
| Есть    | regex + Comby | gas/state helpers                   | `accept_message();`, `commit();`, `set_code(...); -> ;`                                   | убирает важные state/gas operations                                                                              | высокий       |
| Есть    | regex + Comby | time/random helpers                 | `now -> cur_lt`, `cur_lt <-> block_lt`, `random <-> get_seed`                             | меняет источник времени и randomness                                                                             | высокий       |
| Есть    | regex + Comby | load/preload helpers                | `load_* <-> preload_*`, но `load_* -> preload_*` не после `~`                             | меняет mutating read на non-mutating read и обратно                                                              | высокий       |
| Есть    | regex + Comby | signedness of load/store            | `load_uint <-> load_int`, `store_uint <-> store_int`                                      | меняет signed/unsigned serialization semantics                                                                   | высокий       |
| Есть    | regex + Comby | store zeroing                       | `.store_*` и function-style `store_*` payload -> `0`                                      | зануляет записываемые coins/int/uint значения                                                                    | высокий       |
| Есть    | regex + Comby | modifying vs non-modifying notation | `.load_* <-> ~load_*`, `.store_* <-> ~store_*`                                            | меняет whether receiver is updated                                                                               | высокий       |
| Есть    | regex + Comby | slice/builder inspection            | `slice_refs <-> slice_bits`, `builder_refs <-> builder_bits`, `slice_empty?` family       | меняет проверки slice/builder состояния                                                                          | высокий       |
| Есть    | regex + Comby | dict signedness                     | `idict_* <-> udict_*`                                                                     | меняет signedness dictionary API                                                                                 | очень высокий |
| Есть    | regex + Comby | numeric builtins                    | `divmod <-> moddiv`, `muldiv -> muldivr -> muldivc`, `muldivmod -> divmod`, `*_at` family | меняет rounding/result shape/tuple access                                                                        | очень высокий |
| Есть    | regex + Comby | send/reserve modes                  | numeric mode literals in `send_raw_message`, `raw_reserve`, `raw_reserve_extra`           | меняет message sending and reserve flags                                                                         | очень высокий |
