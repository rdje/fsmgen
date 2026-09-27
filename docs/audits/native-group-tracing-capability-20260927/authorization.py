#!/usr/bin/env python3
"""Try the same read-only listing with existing non-interactive authorization."""
import json
import os
from pathlib import Path
import subprocess

ROOT = Path(__file__).resolve().parents[3]
destination = ROOT / '.artifacts/native-group-tracing-capability/authorization.json'
command = ['/usr/bin/sudo', '-n', '/usr/sbin/dtrace', '-l', '-n', 'syscall::setpgid:*']
with destination.open('x') as sink:
    try:
        run = subprocess.run(command, cwd=ROOT,
            env=dict(os.environ, TMPDIR=str(ROOT / '.artifacts/tmp')),
            stdin=subprocess.DEVNULL, capture_output=True, timeout=15)
        result = {'command': command, 'exit_code': run.returncode, 'timed_out': False,
                  'stdout': run.stdout.decode(), 'stderr': run.stderr.decode()}
    except subprocess.TimeoutExpired as error:
        result = {'command': command, 'exit_code': None, 'timed_out': True,
                  'stdout': (error.stdout or b'').decode(), 'stderr': (error.stderr or b'').decode()}
    json.dump(result, sink, indent=2, sort_keys=True)
    sink.write('\n')
print(json.dumps(result))
