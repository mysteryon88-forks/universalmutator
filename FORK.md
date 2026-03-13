# UniversalMutator + TON (Tact / FunC / Tolk)

Это форк `universalmutator`, в который добавлена поддержка **трёх TON-языков**:

- **Tact** (`.tact`)
- **FunC** (`.fc`, `.func`)
- **Tolk** (`.tolk`)

Идея простая: UniversalMutator уже упоминается в официальной документации Solidity как один из ресурсов, а добавить новый язык здесь обычно сводится к:

1. написанию наборов regex-правил (`*.rules`)
2. добавлению handler’а (Python), который умеет валидировать мутанта (например, компиляцией)

## Что добавлено в этом форке

### 1) Новые языки и расширения

Добавлены соответствия расширений файлов и новые handlers:

- `universalmutator/tact_handler.py`
- `universalmutator/func_handler.py`
- `universalmutator/tolk_handler.py`

А также обновлена логика выбора языка по расширению (чтобы `mutate file.tact tact` работало так же, как для остальных языков).

### 2) Правила мутаций для TON-языков

Добавлены файлы правил (регулярки мутаций):

- `universalmutator/static/tact.rules`
- `universalmutator/static/func.rules`
- `universalmutator/static/tolk.rules`

В основе — типовые мутации (операторы сравнения/арифметика/логика/константы), плюс несколько точечных мутаций под синтаксис языков.

### 3) Compile-check для валидности мутантов

UniversalMutator сам по себе “делает мутантов” на основе правил, а валидность мутанта (компилируется/нет) зависит от того, какой handler используется.

В этом форке для TON-языков рекомендуется валидировать мутантов **через компиляцию**:

- **Tact** — через `tact` CLI
- **Tolk** — через `npx @ton/tolk-js` (WASM-компилятор)
- **FunC** — через `ton-compiler` (CLI, удобно для CI и локальных прогонов)

## Где находятся инструкции

- Основные команды запуска собраны в **`Makefile`** в корне репозитория.
- Логи компиляции и диагностические выводы складываются в:

  - `tmp/compile_logs/`

- Сгенерированные мутанты складываются в:

  - `tmp/mutants_tact/`
  - `tmp/mutants_tolk/`
  - `tmp/mutants_func/`

## Быстрый старт

### 0) Проверить окружение

```bash
make doctor
```

### 1) Python окружение и установка проекта

```bash
python3 -m venv .venv
source .venv/bin/activate

# локальная установка форка
pip install -e . --no-build-isolation --no-deps
```

Если окружение без доступа в интернет или pip пытается тянуть build-зависимости, используй флаг `--no-build-isolation`.

## Установка компиляторов

### Tact

Нужен установленный `tact` (CLI должен быть доступен как команда `tact`).
Проверка:

```bash
npm i -g @tact-lang/compiler
tact --help
```

### Tolk

Нужны `node`, `npm`, `npx`.
Проверка:

```bash
node -v
npm -v
npx -v
```

Компиляция Tolk выполняется через:

```bash
npm i -g @ton/tolk-js
npx -y @ton/tolk-js --help
```

### FunC

Рекомендуемый CLI:

```bash
npm i -g ton-compiler
ton-compiler
```

## Валидация одиночных файлов

Эти команды компилируют один файл и показывают ошибку (а полный лог кладут в `tmp/compile_logs/`).

### Tact

```bash
make tact-validate FILE=examples/foo.tact
```

### Tolk

```bash
make tolk-validate FILE=examples/foo.tolk
```

### FunC

Для FunC есть важный нюанс: сборка в `.cell` часто требует `main`, будь бдительным когда выбираешь код для мутирования

```bash
make func-validate FILE=examples/foo.fc
```

## Генерация мутантов (mutation testing)

Смысл: UniversalMutator генерирует мутанты, и для каждого мутанта запускает compile-check.
Если компиляция проходит — мутант считается `VALID` и сохраняется.

### Tact

```bash
make mutate-tact FILE=examples/foo.tact
```

или напрямую:

```bash
mutate examples/foo.tact tact \
  --cmd "tact MUTANT --output /tmp/tact-out" \
  --mutantDir tmp/mutants_tact
```

### Tolk

Для Tolk часто есть `import`, и компилятору важен контекст расположения файла.
Поэтому рекомендуемый режим — компилировать фиксированный путь исходника, без `MUTANT` в команде, чтобы UniversalMutator подменял файл на месте:

```bash
make mutate-tolk FILE=examples/foo.tolk
```

или напрямую:

```bash
mutate examples/foo.tolk tolk \
  --cmd "npx -y @ton/tolk-js --output-json /tmp/tolk-out.json examples/foo.tolk" \
  --mutantDir tmp/mutants_tolk
```

### FunC (Fift-only compile-check)

```bash
make mutate-func FILE=examples/foo.fc
```

или напрямую:

```bash
mutate examples/foo.fc func \
  --cmd 'bash -lc "rm -f /tmp/func-out.fif; (command -v ton-compiler >/dev/null && ton-compiler || npx -y ton-compiler) --input examples/foo.fc --output-fift /tmp/func-out.fif"' \
  --mutantDir tmp/mutants_func
```

## Как понять, что всё работает правильно

После запуска `mutate` можно увидеть статистику по мере выполнения:

- сколько `VALID` (сохранились в `tmp/mutants_*`)
- сколько `INVALID` (не компилируются)
- процент валидных мутантов

Практически всегда будут `INVALID` (особенно от “универсальных” правил), но цель — держать валидность достаточно высокой, чтобы мутации были полезны.

## Заметки по реализации

Из основного с чем столкнулся:

- Для начала дефолтный проект, который требовал зависимости pkg_resources, который уже не найти (заменил на pkgutil)
- После проблема с импортом T из re, ее тоже поправил
- Дальше в целом все было ок, за исключением поиска пакетов с компиляторами и их правильный запуск
- По сути, вайбкод вперемешку с моими фиксами, идеями и прочим, ГПТ помог значительно и ускорил весь процесс

### Что улучшить дальше

- TODO: поднять % валидных мутантов для Tact/Tolk/FunC без влияния на другие языки (break/continue спонтанно подставляется, что сразу делает код на этих трех языках не исполняемым)
- TODO: расширить набор “полезных” мутаций под синтаксис TON-языков
- TODO: добавить CI job, который прогоняет smoke-test на примерах

# Тестовые запуски

```sh
cd examples
python -m universalmutator.genmutants foo.tact tact --cmd "tact MUTANT --output ..\tmp\tact-out" --mutantDir ..\tmp\mutants_tact

cd examples
python -m universalmutator.genmutants foo.tolk tolk --cmd "npx -y @ton/tolk-js MUTANT" --mutantDir ..\tmp\mutants_tolk

cd examples
python -m universalmutator.genmutants foo.fc func --cmd "ton-compiler --input MUTANT --output-fift ..\tmp\func-out.fif" --mutantDir ..\tmp\mutants_func
```

### 1) CI

- Заменили старые раздельные рабочие процессы GitHub Actions на единый объединенный рабочий процесс `CI` в файле `.github/workflows/ci.yml`
- Добавили триггеры для событий `push` и `pull_request` на ветках `main` и `master`
- Добавлен `workflow_dispatch` для ручного запуска
- Добавлена `concurrency` для отмены устаревших запусков на одной ветке/PR
- Обновлены версии Actions (`actions/setup-python@v5`, `actions/setup-node@v4`)
- Добавлено кэширование `pip` с `cache-dependency-path: setup.py`
- Расширено покрытие тестирования, включив:
  - `lint`
  - `test`
  - `package-smoke`
  - `ton-smoke`
- Добавлено покрытие Windows в CI (`windows-latest`), так как несколько реальных ошибок были специфичны для Windows
- Добавлены TON-проверки для текущего пути поддержки TON
- Обновлена конфигурация pylint CI, чтобы также отключить `R0402`

### 2) Compiler and shell execution bugs were fixed

- Исправлено вызов оболочки Windows в файле `universalmutator/analyze.py`
  - команды, передаваемые с параметром `shell=True`, теперь выполняются как строки, а не как списки с одним элементом
  - Замена `MUTANT` теперь корректно работает в командах анализа
  - Улучшена логика резервного копирования/восстановления для команд, которые уже работают напрямую с `MUTANT`
- Исправлена та же ошибка вызова оболочки в `universalmutator/genmutants.py`
  - это было причиной того, что команды проверки компиляции, такие как `tact MUTANT --output ...`, неверно помечали практически все мутанты как `INVALID` в Windows
- Исправлен разбор правил в `universalmutator/mutator.py`
  - Нормализована обработка CRLF, чтобы встроенные файлы `.rules` работали корректно в Windows
  - это исправило разбор файлов правил TON, таких как `tact.rules`, `func.rules` и `tolk.rules`
- Обновлены тесты, чтобы вызывать текущий чек-аут с помощью `python -m ...` вместо использования глобально установленных точек входа CLI из `PATH`
- Стабилизированы локальные тесты на основе примеров, чтобы они не зависели от состояния рабочего дерева, измененного ранее

### Result

- Генерация мутаций TON работает корректно в текущей версии
- Проверка компиляции Tact работает корректно с такими командами, как:

```sh
cd examples
python -m universalmutator.genmutants foo.tact tact --cmd "tact MUTANT --output ..\tmp\tact-out" --mutantDir ..\tmp\mutants_tact
```

- The local Python test suite passes after the fixes:

```sh
python -m pytest -q
```
