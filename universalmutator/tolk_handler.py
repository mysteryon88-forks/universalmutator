"""Tolk handler.

Default behavior is "dumb" (treat every mutant as VALID).

To enable compilation-based validity filtering during mutant generation, set:

  UM_TOLK_CMD='tolk compile MUTANT'

The command must return 0 for a valid mutant.
"""

from __future__ import annotations

import os
import shutil
import subprocess


_CMD = os.environ.get("UM_TOLK_CMD")

dumb = _CMD is None


def handler(tmpMutantName, mutant, sourceFile, uniqueMutants, compileFile=None):
    cmd = _CMD
    if cmd is None:
        return "VALID"

    target = compileFile if compileFile is not None else sourceFile
    pid = os.getpid()
    backupName = None

    if "MUTANT" not in cmd:
        backupName = target + ".um.backup." + str(pid)
        shutil.copy(target, backupName)
        shutil.copy(tmpMutantName, target)

    try:
        outFile = f".um.tolk_output.{pid}"
        with open(outFile, "w") as f:
            r = subprocess.call(
                [cmd.replace("MUTANT", tmpMutantName)],
                shell=True,
                stderr=f,
                stdout=f,
            )
        return "VALID" if r == 0 else "INVALID"
    finally:
        if backupName is not None:
            shutil.copy(backupName, target)
