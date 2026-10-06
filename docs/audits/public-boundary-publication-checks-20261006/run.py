"""Retain one actual command and full streams without overwriting evidence."""
import json
import subprocess
import sys
import hashlib
from pathlib import Path

output, *command = sys.argv[1:]
path=Path(output); root=Path.cwd().resolve()
assert command and not path.is_absolute() and '..' not in path.parts
assert path.parent.resolve().is_relative_to(root) and not path.exists()
instruments = {}
for item in [sys.argv[0], *command]:
    p=Path(item)
    if p.is_file() and (item.endswith('.py') or item=='scripts/run_with_ram_guard.sh'):
        raw=p.read_bytes(); instruments[item]=dict(bytes=len(raw),sha256=hashlib.sha256(raw).hexdigest())
result=subprocess.run(command,capture_output=True,text=True)
path.write_text(json.dumps(dict(command=command,status=result.returncode,stdout=result.stdout,stderr=result.stderr,
    instruments=instruments),sort_keys=True,indent=2)+'\n')
print(result.stdout,end=''); print(result.stderr,end='',file=sys.stderr)
raise SystemExit(result.returncode)
