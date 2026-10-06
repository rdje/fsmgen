"""Retain an actual command, complete streams and invocation-time instruments."""
import hashlib
import json
import subprocess
import sys
from pathlib import Path

output, *command = sys.argv[1:]
path = Path(output); root = Path.cwd().resolve()
assert command and not path.is_absolute() and '..' not in path.parts
assert path.parent.resolve().is_relative_to(root) and not path.exists()
assert path.parent.stat().st_dev == root.stat().st_dev
instruments = {}
for item in [sys.argv[0], *command]:
    source = Path(item)
    if source.is_file() and (item.endswith('.py') or item == 'scripts/run_with_ram_guard.sh'):
        raw = source.read_bytes()
        instruments[item] = dict(bytes=len(raw), sha256=hashlib.sha256(raw).hexdigest())
result = subprocess.run(command, capture_output=True)
record = dict(command=command, status=result.returncode, stdout=result.stdout.decode(), stderr=result.stderr.decode(), instruments=instruments)
path.write_text(json.dumps(record, sort_keys=True, indent=2) + '\n')
print(record['stdout'], end=''); print(record['stderr'], end='', file=sys.stderr)
raise SystemExit(result.returncode)
