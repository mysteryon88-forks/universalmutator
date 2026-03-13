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

# DEFAULT TEXT BELOW

This is a tool based on source-based rewrite of code lines for mutation generation, including
multi-language rules aided by special rules for languages or even projects. Originally, the approach used only regular expressions,
treating code as text. However, there is also a mode that can use the [Comby](https://github.com/comby-tools/comby) tool
for more sophisticated mutation that produces fewer invalid mutants. Regular-expression based mutation works well, in our experience;
comby-aided mutation works even better. The key advantage of either approach is that the tool can probably mutate approximately _any_ interesting source code you have, and language changes don't force
rewriting of the mutation tool. To use the comby mode, just make sure comby is installed and add `--comby` when you run `mutate`.

More information on this project can be found in a [2024 FSE paper](https://agroce.github.io/fse24.pdf), and in the original [2018 ICSE Tool Paper](https://agroce.github.io/icse18t.pdf).

A [guest blog post](https://blog.trailofbits.com/2019/01/23/fuzzing-an-api-with-deepstate-part-2/) for Trail of Bits shows how to use the universalmutator to help improve a C/C++ API fuzzing effort using [DeepState](https://github.com/trailofbits/deepstate) and libFuzzer.

The universalmutator has support for extracting coverage information to guide mutation from the [TSTL](https://github.com/agroce/tstl) testing tool for Python.

# HOW TO USE IT

To use this, you should really just do:

`pip install universalmutator`

then

`mutate --help`

# SIMPLE EXAMPLE USAGE

`mutate foo.py`

or

`mutate foo.swift`

should, if you have the appropriate compilers installed, generate a bunch of valid, non-trivially redundant, mutants.

# A MORE COMPLEX EXAMPLE

Sometimes the mutated code needs to be built with a more complicated command than a simple compiler call, and of course you want help discovering which mutants are killed and not killed. For example, to mutate and test mutants for the mandelbrot plotting example included in the PROGRAMMING RUST book (http://shop.oreilly.com/product/0636920040385.do), just do this:

    git clone https://github.com/ProgrammingRust/mandelbrot
    cd mandelbrot
    cargo build
    target/debug/mandelbrot origmandel.png 1000x750 -1.20,0.35 -1,0.20
    mkdir mutants
    mutate src/main.rs --mutantDir mutants --noCheck
    analyze_mutants src/main.rs "cargo clean; cargo build; rm mandel.png; target/debug/mandelbrot mandel.png 1000x750 -1.20,0.35 -1,0.20; diff mandel.png origmandel.png" --mutantDir mutants

(It will go faster if you edit `main.rs` to lower the maximum number of threads used to something like 8, not 90.) At the moment, this won't use any Trivial Compiler Equivalence, but still kills about 60% of the 1000+ mutants. The killed mutant filenames will be in `killed.txt` and the non-killed ones in `not-killed.txt`.

Working with something like maven is very similar, except you can probably edit the complicated build/clean stuff to just a 'mvn test' or similar.

# CURRENTLY SUPPORTED LANGUAGES

The tool will likely mutate other things, if you tell it they are "c" or something, but there is auto-detection based on file ending and specific rule support for:

```
C
C++
Java
JavaScript
Python
Swift
R
Rust
Go
Lisp
Fortran
Solidity
Vyper
Fe
```

(the last three are smart contract languages for the Ethereum blockchain).

All but C, C++, JavaScript, and Go will try, by default, to compile the mutated
file and use TCE to detect redundancy. Of course, build dependencies
may frustrate this process, in which case --noCheck will turn off TCE
and just dump all the mutants in the directory, for pruning using a
real build process. In the long run, we plan to integrate with
standard build systems to avoid this problem, and with automated test
generation systems such as TSTL (https://github.com/agroce/tstl) for
Python or Echidna for Solidity
(https://github.com/trailofbits/echidna). Even now, however, with
`analyze_mutants` it is fairly easy to set up automatic evaluation of
your automated test generator.

# MUTATING SOLIDITY CODE

The universalmutator has been most frequently applied to smart
contracts written in the Solidity language. It supports a few special
features that are particularly useful in this context.

First,
Solidity libraries are often written with only `internal` functions
--- and the compiler will not emit code for such functions if you
compile a library by itself, resulting in no non-redundant mutants.
In order to handle this case, `mutate` can take a `--compile` option
that specifies another file (a contract using the library, or the
tests in question) that is used to check whether mutants are
redundant.

Second, swapping adjacent lines of code is a seldom-used mutation
operator that is unusually attractive in a Solidity context because
swapping a state-changing operation and a requirement may reveal that
testing is incapable of detecting some
[re-entrancy](https://github.com/crytic/not-so-smart-contracts/tree/master/reentrancy)
vulnerabilities. The testing may notice the absence of the check, but
not a mis-ordering, and these mutants may reveal that. To add code
swaps to your mutations, just add `--swap` to the `mutate` call. Note
that swaps work in any language; they are just particularly appealing
for smart contracts.

# MORE INFORMATON

For much more information, again see https://agroce.github.io/icse18t.pdf -- demo/tool paper at ICSE 18 and especially our full FSE 2024 paper -- https://agroce.github.io/fse24.pdf -- the latter discusses the latest version of the tool/approach, and includes a comparison with many other mutation testing tools.

The aim of this project is partly to see how quickly mutation can be applied to new languages, partly how much the work of a tool can be
offloaded to the compiler / test analysis tools.

Authors: Alex Groce, Josie Holmes, Darko Marinov, August Shi, Lingming Zhang, Kush Jain, Rijnard van Tonder, Sourav Deb
