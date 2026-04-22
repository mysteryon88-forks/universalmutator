# Команды Генерации Мутантов

Все команды ниже запускались из каталога:

```sh
C:\Users\ssobolev\Documents\GitHub\Forks\universalmutator
```

## Основные команды

### FunC

Итоговый успешный запуск:

```sh
New-Item -ItemType Directory -Force examples/func | Out-Null; python -m universalmutator.genmutants examples/foo.fc func --only func.rules --mutantDir examples/func *> examples/func/check.out

New-Item -ItemType Directory -Force examples/func_all | Out-Null; python -m universalmutator.genmutants examples/foo.fc func --mutantDir examples/func_all *> examples/func_all/check.out
```

Промежуточный первый запуск той же команды с коротким таймаутом был прерван по времени.

### Tact

Итоговый успешный запуск:

```sh
New-Item -ItemType Directory -Force examples/tact | Out-Null; python -m universalmutator.genmutants examples/foo.tact tact --only tact.rules --mutantDir examples/tact *> examples/tact/check.out

New-Item -ItemType Directory -Force examples/tact_all | Out-Null; python -m universalmutator.genmutants examples/foo.tact tact --mutantDir examples/tact_all *> examples/tact_all/check.out
```

### Tolk

Итоговый успешный запуск:

```sh
New-Item -ItemType Directory -Force examples/tolk | Out-Null; python -m universalmutator.genmutants examples/foo.tolk tolk --only tolk.rules --mutantDir examples/tolk *> examples/tolk/check.out

New-Item -ItemType Directory -Force examples/tolk_all | Out-Null; python -m universalmutator.genmutants examples/foo.tolk tolk --mutantDir examples/tolk_all *> examples/tolk_all/check.out
```
