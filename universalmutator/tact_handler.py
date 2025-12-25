"""Tact handler.

By default this is a "dumb" handler (treats every mutant as VALID), like the
handlers for C/C++/JS.

If you want validity filtering during generation, set an env var:

  UM_TACT_CMD='tact compile MUTANT'

The command must return exit code 0 for a valid mutant. If the string "MUTANT"
is not present, the handler will temporarily swap the mutant into the source
file before running the command (same behavior as genmutants --cmd).
"""

from __future__ import annotations

import os
import shutil
import subprocess


_CMD = os.environ.get("UM_TACT_CMD")

# If no compiler command is configured, behave like a dumb handler.
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
        outFile = f".um.tact_output.{pid}"
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
