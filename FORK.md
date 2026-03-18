# UniversalMutator + TON (Tact / FunC / Tolk)

Это форк `universalmutator`, в который добавлена поддержка трех TON-языков:

- `tact` для файлов `.tact`
- `func` для файлов `.fc` и `.func`
- `tolk` для файлов `.tolk`

В форке добавлены:

- handlers:
  - `universalmutator/tact_handler.py`
  - `universalmutator/func_handler.py`
  - `universalmutator/tolk_handler.py`
- правила мутаций:
  - `universalmutator/static/tact.rules`
  - `universalmutator/static/func.rules`
  - `universalmutator/static/tolk.rules`
  - `universalmutator/comby/tact.rules`
  - `universalmutator/comby/func.rules`
  - `universalmutator/comby/tolk.rules`
- выбор языка по расширению файла, чтобы `mutate file.tact tact` работало так же, как и для других языков

## Как запускать именно этот форк

У пакета уже есть `console_scripts` в `setup.py`. После установки форка доступны такие команды:

- `mutate`
- `analyze_mutants`
- `check_covered`
- `prioritize_mutants`
- `show_mutants`
- `prune_mutants`
- `intersect_mutants`

### Вариант 1: editable install для разработки

Это лучший режим, если ты активно правишь код форка.

PowerShell:

```sh
py -3 -m venv .venv
.\.venv\Scripts\Activate.ps1
python -m pip install -U pip setuptools wheel
python -m pip install -e . --no-build-isolation
mutate --help
```

Что это дает:

- CLI появляется сразу
- используются текущие файлы из репозитория
- после правок не нужно пересобирать wheel

Если CLI не нужен, можно запускать напрямую модуль:

```sh
python -m universalmutator.genmutants --help
```

### Вариант 2: собрать wheel и поставить свою версию как обычный пакет

Это режим для полноценного локального CLI-пакета.

PowerShell:

```sh
py -3 -m venv .venv
.\.venv\Scripts\Activate.ps1
python -m pip install -U pip setuptools wheel build
python -m build --wheel --no-isolation
python -m pip install --force-reinstall dist\*.whl
mutate --help
```

Если `python -m build` пишет `No module named build`, сначала поставь:

```sh
python -m pip install build
```

Для этого форка wheel локально собирается командой:

```sh
python -m build --wheel --no-isolation
```

## Установка компиляторов TON

### Tact

```sh
npm i -g @tact-lang/compiler
tact --help
```

### Tolk

```sh
npm i -g @ton/tolk-js
tolk-js --help
```

### FunC

```sh
npm i -g @ton-community/func-js
func-js -h
```

## Быстрая проверка окружения

PowerShell:

```sh
python --version
node --version
npm --version
mutate --help
tact --version
npx -y @ton/tolk-js --help
npx -y @ton-community/func-js -h
```

## Валидация одиночных файлов

### Tact

Для compile-check лучше использовать `--check`.

```sh
tact --check examples/foo.tact *> tmp/compile_logs/tact_foo.log
```

### Tolk

```sh
npx -y @ton/tolk-js --output-json tmp/tolk-out.json examples/foo.tolk *> tmp/compile_logs/tolk_foo.log
```

### FunC

```sh
npx -y @ton-community/func-js --cwd examples foo.fc --fift tmp/func-out.fif *> tmp/compile_logs/func_foo.log
```

Важный нюанс по FunC:

- `@ton-community/func-js` делает полноценную компиляцию
- даже если просишь только `--fift`, компилятор все равно требует `main`
- если в проекте есть `#include`, лучше задавать `--cwd` и передавать имя файла относительно этого каталога

## Генерация мутантов

Смысл такой:

- `mutate` генерирует мутантов
- для каждого мутанта для `tact` / `tolk` / `func` compile-check запускается автоматически через language handler
- если команда возвращает `0`, мутант считается `VALID`
- `--cmd` нужен только если хочется принудительно переопределить команду проверки
- `--cmd` имеет приоритет над встроенными TON handler-ами и подходит для нестандартного компилятора, обёртки или локального скрипта

Удобно заранее создать каталоги:

```sh
New-Item -ItemType Directory -Force tmp, tmp\mutants_tact, tmp\mutants_tolk, tmp\mutants_func | Out-Null
```

### Tact

Рекомендуемая команда:

```sh
mutate examples/foo.tact tact --mutantDir tmp/mutants_tact
```

Почему именно так:

- handler использует только `exit code`
- `tact --check` на Windows стабильнее, чем single-file сборка с относительным `--output`

### Tolk

По умолчанию handler сам запускает compile-check из каталога исходника, поэтому `import` продолжают нормально резолвиться.

```sh
mutate examples/foo.tolk tolk --mutantDir tmp/mutants_tolk
```

### FunC

По умолчанию handler сам запускает `func-js` из каталога исходника, чтобы не ломать относительные `#include`.

```sh
mutate examples/foo.fc func --mutantDir tmp/mutants_func
```

Если нужен нестандартный compile-check, можно переопределить его через переменные окружения:

```sh
$env:UM_TACT_CMD='tact --check MUTANT'
$env:UM_TOLK_CMD='npx -y @ton/tolk-js --output-json tmp/tolk-out.json MUTANT'
$env:UM_FUNC_CMD='npx -y @ton-community/func-js MUTANT --fift tmp/func-out.fif'
```

То же самое можно сделать разово через `--cmd`.

Если в команде есть `MUTANT`, UniversalMutator подставит путь к временному файлу мутанта.
Если `MUTANT` нет, UniversalMutator временно подменит исходный файл на месте и запустит команду над фиксированным путём.

Примеры:

```sh
mutate examples/foo.tolk tolk --cmd "my-tolk-wrapper MUTANT" --mutantDir tmp/mutants_tolk
mutate examples/foo.fc func --cmd "my-func-compiler check examples/foo.fc" --mutantDir tmp/mutants_func
```

Если кастомная команда не является настоящей compile-check командой и может возвращать `0` даже для синтаксически сломанного кода, добавь `--noFastCheck`.

## Полезные артефакты компиляции

### Tact

Для compile-check:

- достаточно `tact --check ...`
- handler смотрит только на `exit code`

Для полноценной сборки контракта:

```sh
tact path/to/contract.tact --output out
```

Обычно появляются артефакты:

- `.pkg`
- `.code.boc`
- `.fc`
- `.fif`
- `.abi`
- `.ts`
- `.md`

### Tolk

Самый удобный артефакт:

```sh
npx -y @ton/tolk-js --output-json tmp/tolk-out.json examples/foo.tolk
```

В JSON есть:

- `artifactVersion`
- `tolkVersion`
- `fiftCode`
- `codeBoc64`
- `codeHashHex`
- `sourcesSnapshot`

### FunC

Только Fift:

```sh
npx -y @ton-community/func-js --cwd examples foo.fc --fift tmp/func-out.fif
```

JSON artifact:

```sh
npx -y @ton-community/func-js --cwd examples foo.fc --artifact tmp/func-out.json
```

В JSON есть:

- `artifactVersion`
- `version`
- `sources`
- `codeBoc`
- `fiftCode`

Если нужен бинарный BOC:

```sh
npx -y @ton-community/func-js --cwd examples foo.fc --boc tmp/func-out.cell --fift tmp/func-out.fif
```

## Recheck

Пошаговый сценарий повторной локальной проверки вынесен в `RECHECK.md`.
