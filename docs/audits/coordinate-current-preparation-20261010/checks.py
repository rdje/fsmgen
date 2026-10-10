"""Retain fresh guarded checks and exact instrumentation without overwriting receipts."""
import hashlib
import json
import subprocess
import sys
from pathlib import Path

BASE = Path('docs/audits/coordinate-current-preparation-20261010')


def main():
    destination = BASE / 'checks.json'
    checks = json.loads(destination.read_bytes()) if destination.exists() else {}
    name = sys.argv[1]
    if name in checks:
        raise ValueError('one fresh named actual receipt required')
    command = ['scripts/run_with_ram_guard.sh', '--', *sys.argv[2:]]
    paths = {str(Path(__file__).resolve().relative_to(Path.cwd())), command[0]}
    paths.update(arg for arg in sys.argv[2:] if Path(arg).is_file())
    instruments = {path: {'bytes': Path(path).stat().st_size, 'sha256': hashlib.sha256(Path(path).read_bytes()).hexdigest()} for path in sorted(paths)}
    result = subprocess.run(command, capture_output=True, text=True)
    checks = json.loads(destination.read_bytes()) if destination.exists() else {}
    checks[name] = {'command': command, 'status': result.returncode, 'stdout': result.stdout,
                    'stderr': result.stderr, 'instruments': instruments}
    destination.write_text(json.dumps(checks, sort_keys=True, indent=2) + '\n')
    print(name, result.returncode, result.stdout[-1200:], result.stderr[-1000:])
    raise SystemExit(result.returncode)


if __name__ == '__main__':
    main()
