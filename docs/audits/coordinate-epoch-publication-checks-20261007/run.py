"""Retain actual guarded commands without replacing earlier receipts."""
import json
import subprocess
import sys
from pathlib import Path

BASE = Path('docs/audits/coordinate-epoch-publication-checks-20261007')


def main():
    path = BASE / sys.argv[1]
    if path.exists() or path.parent != BASE:
        raise ValueError('one new same-directory actual receipt required')
    command = ['scripts/run_with_ram_guard.sh', '--', *sys.argv[2:]]
    actual = subprocess.run(command, capture_output=True, text=True)
    path.write_text(json.dumps(dict(command=command, status=actual.returncode,
        stdout=actual.stdout, stderr=actual.stderr), sort_keys=True, indent=2) + '\n')
    print(actual.stdout, end='')
    print(actual.stderr, end='', file=sys.stderr)
    raise SystemExit(actual.returncode)


if __name__ == '__main__':
    main()
