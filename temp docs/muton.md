# Сравнение muton и текущих TON rulesets

Этот файл фиксирует текущее состояние после выноса общих TON-мутаций в `ton_common.rules`.

## Текущие defaults

| Язык | Default regex ruleset | Таблица |
| --- | --- | --- |
| Tact | `ton_common.rules` + `tact.rules` | `TACT_MUTATIONS_TABLE.md` |
| Tolk | `ton_common.rules` + `tolk.rules` | `TOLK_MUTATIONS_TABLE.md` |
| FunC | `ton_common.rules` + `func.rules` | `FUNC_MUTATIONS_TABLE.md` |
| Shared TON | `ton_common.rules` | `TON_COMMON_MUTATIONS_TABLE.md` |

`universal.rules` и `c_like.rules` больше не подключаются по умолчанию для `.tact`, `.tolk`, `.fc`.

## Что совпадает с muton-style семействами

| Семейство | Где сейчас лежит | Комментарий |
| --- | --- | --- |
| `BL` boolean literal flip | `ton_common.rules` | `true <-> false` для всех TON-языков |
| `COS` comparisons | `ton_common.rules` | equality/boundary swaps без generic-angle false positives |
| `LOS` logical operators | `ton_common.rules` | `&& <-> \|\|` |
| `AAOS`, `BAOS`, `SAOS`, `SOS` | `ton_common.rules` | shared assignment/shift families; `/=` guard не трогает FunC `~/=` и `^/=` |
| `WF` while false | `ton_common.rules` | теперь `while(false)`, не `while(0==1)` |
| `LC` break/continue | `ton_common.rules` | statement-only swap |
| `IF` / `IT` | language-specific | отдельно для Tact, Tolk и FunC из-за разных boolean/type-narrowing правил |
| `CR` comment replacement | language-specific regex-only | безопасно сужен до standalone statements |

## Что language-specific

| Язык | Основные дополнительные семейства |
| --- | --- |
| Tact | `throwIf/throwUnless`, `require/throw/nativeThrow`, send/reserve modes, context helpers, RNG, casts, optional field types, ACL patterns, receiver/message/function-kind mutations |
| Tolk | `is/!is`, `lazy`, `get fun`, attributes, `mutate`, numeric/cast/serialization helpers, stdlib fee/message/dict helpers, send/reserve constants, `BounceMode`, `struct(prefix)` |
| FunC | `throw_if/throw_unless`, FunC-specific `/ ~/ ^/` and `% ~% ^%`, `ifnot/until/repeat`, function specifiers, load/preload, dot-vs-tilde calls, dict/builtin/send-reserve helpers |

## Static и Comby

Static и Comby синхронизированы по текущей архитектуре:

- shared families живут в `ton_common.rules`, а не дублируются в language-specific Comby-файлах;
- Tolk `assert (...) throw -> if (...) throw` и FunC `method_id -> method_id(0)` удалены;
- FunC guards для `^/`, `^%`, `^/=`, `~/=`, `~%=` отражены и в Comby через constrained holes;
- Tolk helper/dict swaps в Comby ограничены call-site receiver holes, чтобы не трогать function declarations;
- `CR` остаётся regex-only, потому что текущий one-line Comby rules format не даёт безопасного line-scope guard для declarations и continuation-строк.
