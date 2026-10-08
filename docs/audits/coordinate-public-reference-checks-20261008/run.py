"""Retain actual guarded commands without replacing earlier receipts."""
import hashlib
import json
import subprocess
import sys
from pathlib import Path

BASE = Path('docs/audits/coordinate-public-reference-checks-20261008')


def main():
    path = BASE / sys.argv[1]
    if path.exists() or path.parent != BASE:
        raise ValueError('one new same-directory actual receipt required')
    command = ['scripts/run_with_ram_guard.sh', '--', *sys.argv[2:]]
    paths = [Path(__file__).resolve().relative_to(Path.cwd()), Path(command[0])]
    paths.extend(Path(arg) for arg in sys.argv[2:]
                 if arg.startswith(('docs/', 'scripts/', 't/')) and Path(arg).is_file())
    instruments = {str(path): dict(bytes=path.stat().st_size, sha256=hashlib.sha256(path.read_bytes()).hexdigest())
                   for path in paths}
    actual = subprocess.run(command, capture_output=True, text=True)
    path.write_text(json.dumps(dict(command=command, status=actual.returncode,
        stdout=actual.stdout, stderr=actual.stderr, instruments=instruments), sort_keys=True, indent=2) + '\n')
    print(actual.stdout, end='')
    print(actual.stderr, end='', file=sys.stderr)
    raise SystemExit(actual.returncode)


if __name__ == '__main__':
    main()
