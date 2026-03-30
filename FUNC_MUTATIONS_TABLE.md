# Таблица мутаций FunC

Этот файл — компактная таблица FunC-мутаций, собранная по локальной stdlib и
документации FunC.

Источники, на которые опирается таблица:

- `func/1.md`
- `func/2.md`
- `func/3.md`
- `func/4.md`
- `func/5.md`
- `func/6.md`
- `func/7.md`
- `examples/tolk-bench/contracts_FunC/01_jetton/stdlib.fc`
- `examples/tolk-bench/contracts_FunC/**` (до секции `;; CUSTOM:`)

Regex-движок:

- для `universalmutator/static/func.rules` — Python `re`.

## Краткая таблица

| Статус           | Конструкция                           | Правило                                                                                                                           | Эффект                                                              | Риск          |
| ---------------- | ------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------- | ------------- |
| Есть (служебное) | `#include`                            | `^\s*#include\s ==> DO_NOT_MUTATE`                                                                                                | исключает include-строки из мутаций                                 | низкий        |
| Есть (служебное) | комментарии `;;`                      | `;; ==> SKIP_MUTATING_REST`                                                                                                       | прекращает мутации в хвосте однострочного комментария               | низкий        |
| Есть             | `throw_if` / `throw_unless`           | `throw_if ==> throw_unless`<br>`throw_unless ==> throw_if`                                                                        | инвертирует исключение в guard-операторе                            | высокий       |
| Есть             | `throw_arg_if` / `throw_arg_unless`   | `throw_arg_if ==> throw_arg_unless`<br>`throw_arg_unless ==> throw_arg_if`                                                        | инвертирует guard в `throw_arg_*`                                   | высокий       |
| Есть             | `THROW_IF` / `THROW_UNLESS`           | `THROW_IF ==> THROW_UNLESS`<br>`THROW_UNLESS ==> THROW_IF`                                                                        | то же для верхнего регистра                                         | высокий       |
| Есть             | `inline` / `inline_ref`               | `\binline\b ==> inline_ref`<br>`\binline_ref\b ==> inline`                                                                        | меняет стратегию inlining                                           | высокий       |
| Есть             | `impure`                              | `\bimpure\b ==> `                                                                                                                 | снимает specifier побочных эффектов                                 | высокий       |
| Есть             | `method_id(...)`                      | `\bmethod_id\s*\(\s*[^)\n]+\s*\) ==> method_id(0)`                                                                                | подменяет явный method id                                           | очень высокий |
| Есть             | `method_id`                           | `\bmethod_id\b(?!\s*\() ==> method_id(0)`                                                                                         | добавляет фиксированный method id                                   | очень высокий |
| Есть             | `now` / `cur_lt` / `block_lt`         | `\bnow\( ==> cur_lt(`<br>`\bcur_lt\( ==> block_lt(`<br>`\bblock_lt\( ==> cur_lt(`                                                 | подменяет источники времени/логического времени                     | высокий       |
| Есть             | `random` / `get_seed`                 | `\brandom\( ==> get_seed(`<br>`\bget_seed\( ==> random(`                                                                          | подмена RNG vs seed                                                 | высокий       |
| Есть             | `load_ref` / `preload_ref`            | `\bload_ref\( ==> preload_ref(`<br>`\bpreload_ref\( ==> load_ref(`                                                                | меняет mutating parse на preload и обратно                          | высокий       |
| Есть             | `load_dict` / `preload_dict`          | `\bload_dict\( ==> preload_dict(`<br>`\bpreload_dict\( ==> load_dict(`                                                            | то же для dict                                                      | высокий       |
| Есть             | `load_maybe_ref` / `preload_maybe_ref` | `\bload_maybe_ref\( ==> preload_maybe_ref(`<br>`\bpreload_maybe_ref\( ==> load_maybe_ref(`                                        | то же для optional ref                                              | высокий       |
| Есть             | `load_int` / `preload_int`            | `\bload_int\( ==> preload_int(`<br>`\bpreload_int\( ==> load_int(`                                                                | модифицирующий vs немодифицирующий парсер int                        | высокий       |
| Есть             | `load_uint` / `preload_uint`          | `\bload_uint\( ==> preload_uint(`<br>`\bpreload_uint\( ==> load_uint(`                                                            | модифицирующий vs немодифицирующий парсер uint                       | высокий       |
| Есть             | `load_bits` / `preload_bits`          | `\bload_bits\( ==> preload_bits(`<br>`\bpreload_bits\( ==> load_bits(`                                                            | модифицирующий vs немодифицирующий парсер bits                       | высокий       |
| Есть             | `load_uint` / `load_int`              | `\bload_uint\b ==> load_int`<br>`\bload_int\b ==> load_uint`                                                                      | меняет signedness при загрузке                                      | высокий       |
| Есть             | `store_uint` / `store_int`            | `\bstore_uint\b ==> store_int`<br>`\bstore_int\b ==> store_uint`                                                                  | меняет signedness при записи                                        | высокий       |
| Есть             | `obj.method` vs `obj~method`          | `s.load_uint(...) <-> s~load_uint(...)`<br>`s.load_int(...) <-> s~load_int(...)`<br>`s.load_bits(...) <-> s~load_bits(...)`<br>`b.store_uint(...) <-> b~store_uint(...)`<br>`b.store_int(...) <-> b~store_int(...)` | переключает modifying vs non-modifying notation                     | высокий       |
| Есть             | `slice_refs` / `slice_bits`           | `\bslice_refs\( ==> slice_bits(`<br>`\bslice_bits\( ==> slice_refs(`                                                              | меняет базовую метрику среза                                        | высокий       |
| Есть             | `builder_refs` / `builder_bits`       | `\bbuilder_refs\( ==> builder_bits(`<br>`\bbuilder_bits\( ==> builder_refs(`                                                      | меняет метрику builder                                              | высокий       |
| Есть             | `slice_empty?` / `slice_refs_empty?`  | `\bslice_empty\?\( ==> slice_refs_empty?(`<br>`\bslice_refs_empty\?\( ==> slice_empty?(`                                          | подмена проверки пустоты                                            | высокий       |
| Есть             | `divmod` / `moddiv`                   | `\bdivmod\b ==> moddiv`<br>`\bmoddiv\b ==> divmod`                                                                                | меняет порядок частного/остатка                                     | высокий       |
| Есть             | `~divmod` / `~moddiv`                 | `~divmod ==> ~moddiv`<br>`~moddiv ==> ~divmod`                                                                                    | то же, но для modifying notation                                   | высокий       |
| Есть             | `muldiv` / `muldivr` / `muldivc`       | `\bmuldiv\b ==> muldivr`<br>`\bmuldivr\b ==> muldivc`<br>`\bmuldivc\b ==> muldiv`                                                  | меняет режим округления в умножении/делении                         | высокий       |
| Есть             | `muldivmod`                           | `\bmuldivmod\b ==> divmod`                                                                                                        | меняет тип операции на деление с остатком                           | высокий       |
| Есть             | `int_at` / `cell_at` / `slice_at` / `tuple_at` / `at` | `int_at( ==> cell_at(`<br>`cell_at( ==> slice_at(`<br>`slice_at( ==> tuple_at(`<br>`tuple_at( ==> int_at(`<br>`at( ==> tuple_at(` | меняет тип извлекаемого элемента tuple                              | высокий       |
| Есть             | `idict_*` / `udict_*`                 | `\bidict_... ==> udict_...`<br>`\budict_... ==> idict_...`                                                                        | меняет signedness dictionary API                                    | очень высокий |
| Есть             | numeric mode literals                 | `send_raw_message(..., N)` / `raw_reserve(..., N)` / `raw_reserve_extra(..., N)`<br>`0 -> 1`, `1/2/16/32/1024 -> 0`, `64 <-> 128` | мутирует режимы отправки/резерва при использовании числовых literal | очень высокий |
