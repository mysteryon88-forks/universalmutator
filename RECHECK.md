# Recheck Guide

Этот файл повторяет практический сценарий локальной проверки форка: установка пакета как обычного `pip`-пакета, запуск CLI `mutate`, генерация мутантов для TON и Solidity, а также отдельная compile-check проверка.

## Что нужно в окружении

- `python`
- `pip`
- `node`
- `npx`
- `tact`
- `solc`

Проверка:

```powershell
python --version
pip --version
node --version
npx --version
tact --version
solc --version
```

## Подготовка

Команды ниже рассчитаны на PowerShell из корня репозитория.

Создай временные каталоги:

```powershell
New-Item -ItemType Directory -Force `
  tmp, `
  tmp\compile_logs, `
  tmp\recheck-tact-nocheck, `
  tmp\recheck-tact-check, `
  tmp\recheck-tolk-nocheck, `
  tmp\recheck-tolk-check, `
  tmp\recheck-func-nocheck, `
  tmp\recheck-func-check, `
  tmp\recheck-sol-nocheck, `
  tmp\recheck-sol-check | Out-Null
```

## Установка как обычного пакета

Если хочешь повторить именно сценарий "как пакет после `pip install`", а не editable-режим:

```powershell
.\.venv\Scripts\python.exe -m build --wheel --no-isolation
.\.venv\Scripts\python.exe -m pip install --force-reinstall .\dist\universalmutator-1.1.13-py3-none-any.whl
.\.venv\Scripts\mutate.exe --help
```

Если wheel получил другую версию или суффикс, подставь актуальное имя файла из `dist\`.

## Базовая compile-check проверка исходных файлов

Эта часть проверяет, что сами входные примеры собираются до генерации мутантов:

```powershell
cmd /c "solc examples\foo.sol --asm --optimize > tmp\compile_logs\sol_foo.log 2>&1"
cmd /c "tact --check examples\foo.tact > tmp\compile_logs\tact_foo.log 2>&1"
cmd /c "npx -y @ton/tolk-js --output-json tmp\tolk-out.json examples\foo.tolk > tmp\compile_logs\tolk_foo.log 2>&1"
cmd /c "npx -y @ton-community/func-js --cwd examples foo.fc --fift tmp\func-out.fif > tmp\compile_logs\func_foo.log 2>&1"
```

Логи будут в `tmp\compile_logs\`.

## Генерация мутантов без compile-check

Этот прогон проверяет, что CLI реально генерирует мутантов и складывает их в каталоги:

```powershell
cmd /c ".\.venv\Scripts\mutate.exe examples\foo.tact tact --noCheck --mutantDir tmp\recheck-tact-nocheck > tmp\recheck-tact-nocheck.log 2>&1"
cmd /c ".\.venv\Scripts\mutate.exe examples\foo.tolk tolk --noCheck --mutantDir tmp\recheck-tolk-nocheck > tmp\recheck-tolk-nocheck.log 2>&1"
cmd /c ".\.venv\Scripts\mutate.exe examples\foo.fc func --noCheck --mutantDir tmp\recheck-func-nocheck > tmp\recheck-func-nocheck.log 2>&1"
cmd /c ".\.venv\Scripts\mutate.exe examples\foo.sol solidity --noCheck --mutantDir tmp\recheck-sol-nocheck > tmp\recheck-sol-nocheck.log 2>&1"
```

## Генерация мутантов с compile-check

Этот прогон использует стандартные language handler-ы пакета:

```powershell
cmd /c ".\.venv\Scripts\mutate.exe examples\foo.tact tact --mutantDir tmp\recheck-tact-check > tmp\recheck-tact-check.log 2>&1"
cmd /c ".\.venv\Scripts\mutate.exe examples\foo.tolk tolk --mutantDir tmp\recheck-tolk-check > tmp\recheck-tolk-check.log 2>&1"
cmd /c ".\.venv\Scripts\mutate.exe examples\foo.fc func --mutantDir tmp\recheck-func-check > tmp\recheck-func-check.log 2>&1"
cmd /c ".\.venv\Scripts\mutate.exe examples\foo.sol solidity --mutantDir tmp\recheck-sol-check > tmp\recheck-sol-check.log 2>&1"
```

## Что смотреть в результате

Сводка по последним строкам логов:

```powershell
Get-Content tmp\recheck-tact-nocheck.log | Select-Object -Last 12
Get-Content tmp\recheck-tolk-nocheck.log | Select-Object -Last 12
Get-Content tmp\recheck-func-nocheck.log | Select-Object -Last 12
Get-Content tmp\recheck-sol-nocheck.log | Select-Object -Last 12

Get-Content tmp\recheck-tact-check.log | Select-Object -Last 12
Get-Content tmp\recheck-tolk-check.log | Select-Object -Last 12
Get-Content tmp\recheck-func-check.log | Select-Object -Last 12
Get-Content tmp\recheck-sol-check.log | Select-Object -Last 12
```

Количество записанных мутантов:

```powershell
(Get-ChildItem tmp\recheck-tact-nocheck -File | Measure-Object).Count
(Get-ChildItem tmp\recheck-tolk-nocheck -File | Measure-Object).Count
(Get-ChildItem tmp\recheck-func-nocheck -File | Measure-Object).Count
(Get-ChildItem tmp\recheck-sol-nocheck -File | Measure-Object).Count

(Get-ChildItem tmp\recheck-tact-check -File | Measure-Object).Count
(Get-ChildItem tmp\recheck-tolk-check -File | Measure-Object).Count
(Get-ChildItem tmp\recheck-func-check -File | Measure-Object).Count
(Get-ChildItem tmp\recheck-sol-check -File | Measure-Object).Count
```

Если нужен полностью чистый повторный прогон, перед запуском можно удалить `tmp\recheck-*` и соответствующие `.log`.
