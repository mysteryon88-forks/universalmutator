# Commands

## FunC

```sh
New-Item -ItemType Directory -Force examples/func | Out-Null; python -m universalmutator.genmutants examples/foo.fc func --only func.rules --mutantDir examples/func *> examples/func/check.out

New-Item -ItemType Directory -Force examples/func_all | Out-Null; python -m universalmutator.genmutants examples/foo.fc func --mutantDir examples/func_all *> examples/func_all/check.out

New-Item -ItemType Directory -Force examples/func2_all | Out-Null; python -m universalmutator.genmutants examples/foo2.fc func --mutantDir examples/func2_all *> examples/func2_all/check.out
```

## Tact

```sh
New-Item -ItemType Directory -Force examples/tact | Out-Null; python -m universalmutator.genmutants examples/foo.tact tact --only tact.rules --mutantDir examples/tact *> examples/tact/check.out

New-Item -ItemType Directory -Force examples/tact_all | Out-Null; python -m universalmutator.genmutants examples/foo.tact tact --mutantDir examples/tact_all *> examples/tact_all/check.out
```

## Tolk

```sh
New-Item -ItemType Directory -Force examples/tolk | Out-Null; python -m universalmutator.genmutants examples/foo.tolk tolk --only tolk.rules --mutantDir examples/tolk *> examples/tolk/check.out

New-Item -ItemType Directory -Force examples/tolk_all | Out-Null; python -m universalmutator.genmutants examples/foo.tolk tolk --mutantDir examples/tolk_all *> examples/tolk_all/check.out

New-Item -ItemType Directory -Force examples/tolk2_all | Out-Null; python -m universalmutator.genmutants examples/foo2.tolk tolk --mutantDir examples/tolk2_all *> examples/tolk2_all/check.out
```
