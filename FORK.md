# UniversalMutator + TON (Tact / FunC / Tolk)

Это форк `universalmutator`, в который добавлена поддержка трех TON-языков:

- `tact` для файлов `.tact`
- `func` для файлов `.fc` и `.func`
- `tolk` для файлов `.tolk`

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

## Команды

### `mutate`

Генерирует мутантов и кладёт их в `--mutantDir`. При необходимости можно добавить `--cmd` или `--noFastCheck`.

```sh
mutate examples/tolk-bench/contracts_Tolk/01_jetton/jetton-wallet-contract.tolk --mutantDir tmp/tolk-jetton-wallet-mutants
```

### `analyze_mutants`

Прогоняет тесты на каждом мутанте. Создаёт `killed.txt` и `notkilled.txt` в текущей директории.

```sh
analyze_mutants examples/tolk-bench/contracts_Tolk/01_jetton/jetton-wallet-contract.tolk "cd /d examples\tolk-bench && npx jest --runInBand tests/01_jetton/JettonWallet.spec.ts" --mutantDir tmp/tolk-jetton-wallet-mutants --timeout 180
```

Полезные флаги: `--show`, `--verbose`, `--resume`, `--noShuffle`, `--numMutants N`, `--prefix name`.

### `check_covered`

Фильтрует мутантов по покрытым строкам. Формат `coverfile` — список номеров строк (по одному номеру на строку). Для TSTL-отчётов есть `--tstl`.

```sh
check_covered examples/tolk-bench/contracts_Tolk/01_jetton/jetton-wallet-contract.tolk tmp/covered_lines.txt tmp/covered_mutants.txt --mutantDir tmp/tolk-jetton-wallet-mutants
```

### `prioritize_mutants`

Ранжирует список мутантов по структурной дистанции. На вход принимает файл со списком имён мутантов.

```sh
prioritize_mutants tmp/covered_mutants.txt tmp/prioritized.txt --mutantDir tmp/tolk-jetton-wallet-mutants --sourceDir examples/tolk-bench/contracts_Tolk/01_jetton
```

### `show_mutants`

Показывает диффы для мутантов из списка.

```sh
show_mutants tmp/prioritized.txt --mutantDir tmp/tolk-jetton-wallet-mutants --sourceDir examples/tolk-bench/contracts_Tolk/01_jetton
```

Флаг `--concise` делает вывод компактным.

### `prune_mutants`

Фильтрует список мутантов по правилам из конфигурации. Формат правил — строки вида `field: value`, доступны `orig`, `mutant`, `change`, `source`, `line` и их варианты с `!` или `_RE`.

```sh
prune_mutants tmp/prioritized.txt tmp/pruned.txt tmp/prune.cfg --mutantDir tmp/tolk-jetton-wallet-mutants --sourceDir examples/tolk-bench/contracts_Tolk/01_jetton
```

### `intersect_mutants`

Берёт пересечение двух списков мутантов.

```sh
intersect_mutants tmp/covered_mutants.txt tmp/prioritized.txt tmp/intersection.txt
```

Для smoke-теста можно пересекать любые два существующих списка, например:

```sh
intersect_mutants tmp/all_mutants.txt tmp/prioritized.txt tmp/intersection.txt
```

## Тестирую Jetton (Tolk)

```sh
npx jest --runInBand tests/01_jetton/JettonWallet.spec.ts

mutate examples/tolk-bench/contracts_Tolk/01_jetton/jetton-wallet-contract.tolk --mutantDir tmp/tolk-jetton-wallet-mutants

analyze_mutants examples/tolk-bench/contracts_Tolk/01_jetton/jetton-wallet-contract.tolk "cd /d examples\tolk-bench && npx jest --runInBand tests/01_jetton/JettonWallet.spec.ts" --mutantDir tmp/tolk-jetton-wallet-mutants --timeout 180
```

## Тестирую Jetton (FunC)

Перед запуском переключи wrapper на FunC:
`examples/tolk-bench/wrappers/01_jetton/JettonWallet.compile.ts`
должен быть с `lang: 'func'` и списком `targets` для `.fc` файлов.

```sh
npx jest --runInBand tests/01_jetton/JettonWallet.spec.ts

mutate examples/tolk-bench/contracts_FunC/01_jetton/jetton-wallet.fc func --mutantDir tmp/func-jetton-wallet-mutants

analyze_mutants examples/tolk-bench/contracts_FunC/01_jetton/jetton-wallet.fc "cd /d examples\tolk-bench && npx jest --runInBand tests/01_jetton/JettonWallet.spec.ts" --mutantDir tmp/func-jetton-wallet-mutants --timeout 180
```
