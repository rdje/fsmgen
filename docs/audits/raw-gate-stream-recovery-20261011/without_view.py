"""Run the committed-evidence reader with its ignored source view absent."""
from pathlib import Path
import subprocess

import view

saved = Path(str(view.VIEW) + '-held-for-default')
view.recovery.require(view.recovery.local(view.VIEW).is_dir()
                      and not view.recovery.local(saved).exists(), 'exact owned view and fresh same-volume hold path')
before = view.census(streams=True)
view.recovery.local(view.VIEW).rename(view.recovery.local(saved))
try:
    view.recovery.require(not view.recovery.local(view.VIEW).exists(), 'ignored source view absent during default')
    result = subprocess.run(['python3', '-B', str(view.BASE / 'verify.py')])
finally:
    view.recovery.require(not view.recovery.local(view.VIEW).exists(), 'never replace a concurrent source-view writer')
    view.recovery.local(saved).rename(view.recovery.local(view.VIEW))
view.recovery.require(view.census(streams=True) == before, 'whole owned view restored unchanged after default')
raise SystemExit(result.returncode)
