# Таблица мутаций Tact

Этот файл — рабочая сводка по Tact-мутациям, которые сейчас реально реализованы в форке `universalmutator`.

## Эффективный ruleset

- regex: `universal.rules` + `tact.rules` + `c_like.rules`
- Comby: `universalmutator/comby/tact.rules`
- regex-движок: Python `re`

## Краткая таблица

| Статус | Слой          | Конструкция                   | Правило                                                                                                                   | Эффект                                         | Риск    |
| ------ | ------------- | ----------------------------- | ------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------- | ------- |
| Есть   | regex + Comby | `import`                      | `^\s*import\s ==> DO_NOT_MUTATE`<br>`import :[rest] ==> DO_NOT_MUTATE`                                                    | исключает import-строки из мутаций             | низкий  |
| Есть   | regex + Comby | комментарии `//`, `///`, `/*` | `// ==> SKIP_MUTATING_REST`<br>`/// ==> SKIP_MUTATING_REST`<br>`/\* ==> SKIP_MUTATING_REST`                               | прекращает мутации внутри комментариев         | низкий  |
| Есть   | regex + Comby | `true` / `false`              | `true ==> false`<br>`false ==> true`                                                                                      | инвертирует boolean literals                   | низкий  |
| Есть   | regex + Comby | `throwIf` / `throwUnless`     | `throwIf ==> throwUnless`<br>`throwUnless ==> throwIf`                                                                    | меняет guard-семантику assert-like helper-а    | высокий |
| Есть   | regex         | arithmetic assignment shuffle | `+=`, `-=`, `*=`, `/=` взаимно переставляются                                                                             | мутирует составные арифметические присваивания | средний |
| Есть   | regex         | bitwise assignment shuffle    | <code>&amp;=</code>, <code>&#124;=</code>, <code>^=</code> взаимно переставляются                                         | мутирует составные побитовые присваивания      | средний |
| Есть   | regex         | shift shuffle                 | `<<= <-> >>=`<br>`<< <-> >>`                                                                                              | меняет направление сдвигов                     | средний |
| Есть   | regex         | bitwise operator shuffle      | <code>^ -&gt; &amp;</code><br><code>^ -&gt; &#124;</code><br><code>&amp; -&gt; ^</code><br><code>&#124; -&gt; ^</code>    | мутирует побитовые операции                    | средний |
| Есть   | regex         | loop/control mutations        | `while (cond) -> while (0==1)`<br>`until (cond) -> until (0==1)`<br>`repeat (expr) -> repeat (0)`<br>`break <-> continue` | меняет достижимость и форму циклов             | высокий |
| Есть   | regex         | ternary `?:`                  | `cond ? a : b -> false ? a : b`<br>`cond ? a : b -> true ? a : b`                                                         | форсирует одну из веток тернарника             | высокий |
| Есть   | regex         | error replacement             | `(^\s*)(\S+[^{}]+.*)\n ==> \1throw(0);\n`                                                                                 | заменяет statement на исключение               | высокий |

## Что ещё приходит из общих правил

Помимо `tact.rules`, для Tact автоматически подключаются ещё два слоя:

- `universal.rules` — базовые мутации арифметики, сравнений, `&&/||`, `++/--`, числовых литералов, строковых литералов, `min/max`, `begin/end`, `while -> if`, вставка `break;` / `continue;`, swap аргументов;
- `c_like.rules` — C-like мутации `if (!cond)`, `if (0==1)`, `if (1==1)`, `while (!cond)`, удаление `else`, а также жёсткие ветки для `||` и `&&`.

Из-за этого фактическое покрытие Tact в форке шире, чем один только `static/tact.rules`.

## Что пока не покрыто точечными Tact-правилами

В Tact есть ещё несколько важных поверхностных форм, для которых в текущем форке пока нет узких Tact-specific правил:

- `inline fun`, `extends fun`, `extends mutates fun`;
- `get fun` и `get(<expr>)` у getter-ов;
- `receive(...)`-обработчики и `message(<opcode>)` / `message(<expr>)`;
- send mode constants и object-literal формы отправки сообщений;
- аккуратная мутация `!!` для optional unwrap без побочных ложных срабатываний.

## Что пока не стоит делать чистым regex-ом

Слишком хрупко для `static/tact.rules` без AST или хотя бы Comby:

- переписывание `receive(...)` по типам сообщений и fallback-веткам;
- мутации вложенных `message(...)` / `SendParameters { ... }` object literal-ов;
- широкие мутации generic-типов, `map<K, V>`, `foreach` и nested optional types;
- точечная работа с `!!`, где нужно отличать unwrap от обычного логического отрицания.
