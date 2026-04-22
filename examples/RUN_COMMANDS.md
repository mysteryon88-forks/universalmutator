# Команды Генерации Мутантов

Все команды ниже запускались из каталога:

```sh
C:\Users\ssobolev\Documents\GitHub\Forks\universalmutator
```

## Основные команды

### FunC

Итоговый успешный запуск:

```sh
python -m universalmutator.genmutants examples/foo.fc func --only func.rules --mutantDir examples/func *> examples/func/check.out
```

Промежуточный первый запуск той же команды с коротким таймаутом был прерван по времени.

### Tact

Итоговый успешный запуск:

```sh
python -m universalmutator.genmutants examples/foo.tact tact --only tact.rules --mutantDir examples/tact *> examples/tact/check.out
```

### Tolk

Итоговый успешный запуск:

```sh
python -m universalmutator.genmutants examples/foo.tolk tolk --only tolk.rules --mutantDir examples/tolk *> examples/tolk/check.out
```

## Повторные команды, которые тоже вызывались

Повторный запуск FunC после первого таймаута:

```sh
python -m universalmutator.genmutants examples/foo.fc func --only func.rules --mutantDir examples/func *> examples/func/check.out
```

Объединённый повторный запуск FunC и Tolk одной командой:

```sh
python -m universalmutator.genmutants examples/foo.fc func --only func.rules --mutantDir examples/func *> examples/func/check.out; python -m universalmutator.genmutants examples/foo.tolk tolk --only tolk.rules --mutantDir examples/tolk *> examples/tolk/check.out
```

Финальный отдельный повторный запуск Tolk:

```sh
python -m universalmutator.genmutants examples/foo.tolk tolk --only tolk.rules --mutantDir examples/tolk *> examples/tolk/check.out
```

## Куда пишется результат

```sh
examples/func
examples/tact
examples/tolk
```

Логи запусков пишутся в:

```sh
examples/func/check.out
examples/tact/check.out
examples/tolk/check.out
```
