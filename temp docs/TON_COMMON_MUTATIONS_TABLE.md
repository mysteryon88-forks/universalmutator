# Таблица общих TON-мутаций

Актуально для `universalmutator/static/ton_common.rules` и `universalmutator/comby/ton_common.rules`.
Этот ruleset подключается первым для Tact, FunC и Tolk и содержит только те семейства, которые сейчас считаются достаточно syntax-safe для всех трёх языков.

## Сводка

| Файл                      | Количество правил | Комментарий                               |
| ------------------------- | ----------------: | ----------------------------------------- |
| `static/ton_common.rules` |                36 | regex-реализация на Python `re`           |
| `comby/ton_common.rules`  |                36 | Comby-аналог без language-specific правил |

## Краткая таблица

| Статус | Слой          | Конструкция                       | Правило                                       | Эффект                                   | Риск    |
| ------ | ------------- | --------------------------------- | --------------------------------------------- | ---------------------------------------- | ------- |
| Есть   | regex + Comby | boolean literals                  | `true <-> false`                              | инвертирует булевы константы             | низкий  |
| Есть   | regex + Comby | сравнения                         | `== <-> !=`, `<= -> < / ==`, `>= -> > / ==`   | меняет guard-условия и границы сравнений | средний |
| Есть   | regex + Comby | логические операторы              | `&& <-> \|\|`                                 | меняет conjunction/disjunction           | средний |
| Есть   | regex + Comby | `while` forcing                   | `while (cond) -> while (false)`               | делает цикл недостижимым                 | высокий |
| Есть   | regex + Comby | loop control                      | `break <-> continue`                          | меняет управление внутри циклов          | высокий |
| Есть   | regex + Comby | arithmetic assignment shuffle     | `+=`, `-=`, `*=`, `/=` взаимно переставляются | меняет compound arithmetic update        | средний |
| Есть   | regex + Comby | guarded `/=` shuffle              | `/= -> += / -= / *=`, но не после `~` или `^` | не трогает FunC-special `~/=` и `^/=`    | средний |
| Есть   | regex + Comby | bitwise assignment shuffle        | `&=`, `\|=`, `^=` взаимно переставляются      | меняет compound bitwise update           | средний |
| Есть   | regex + Comby | shift assignment/operator shuffle | `<<= <-> >>=`, `<< <-> >>`                    | меняет направление сдвига                | средний |

## Что вынесено из common

`if` forcing больше не общий: в Tolk надо избегать `is / !is` narrowing, а в FunC `!cond` не является хорошей общей формой. Сейчас `if`-правила живут отдельно в `func.rules`, `tolk.rules` и `tact.rules`.

Regex и Comby синхронизированы по семействам. Единственное отличие реализации: Comby использует структурные holes, поэтому guard для `/=` выражен как constrained hole `:[lhs~.*[^~^]\s*]/=:[rhs]`.
