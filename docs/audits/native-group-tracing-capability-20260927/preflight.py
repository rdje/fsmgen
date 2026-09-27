#!/usr/bin/env python3
"""List only the relevant native probes; never enable tracing or execute a test."""
import hashlib
import json
import os
from pathlib import Path
import subprocess

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[2]
WORK = ROOT / '.artifacts/native-group-tracing-capability'
WORK.mkdir(exist_ok=False)
manual = Path('/usr/share/man/man1/dtrace.1')
assert '.It Fl l\nList probes instead of enabling them.' in manual.read_text()
commands = [
    ['/usr/sbin/dtrace', '-V'],
    ['/usr/sbin/dtrace', '-l', '-n', 'syscall::setpgid:*'],
]
results = []
for command in commands:
    try:
        run = subprocess.run(command, cwd=ROOT,
            env=dict(os.environ, TMPDIR=str(ROOT / '.artifacts/tmp')),
            capture_output=True, timeout=15)
        row = {'command': command, 'exit_code': run.returncode, 'timed_out': False,
               'stdout': run.stdout.decode(), 'stderr': run.stderr.decode()}
    except subprocess.TimeoutExpired as error:
        row = {'command': command, 'exit_code': None, 'timed_out': True,
               'stdout': (error.stdout or b'').decode(), 'stderr': (error.stderr or b'').decode()}
    results.append(row)
record = {
    'schema': 'fsmgen.native_group_tracing_capability.v1',
    'uid': os.getuid(), 'deadline_seconds_each': 15,
    'os_release': os.uname().release, 'kernel_version': os.uname().version,
    'dtrace_sha256': hashlib.sha256(Path('/usr/sbin/dtrace').read_bytes()).hexdigest(),
    'manual_sha256': hashlib.sha256(manual.read_bytes()).hexdigest(),
    'manual_listing_contract': 'List probes instead of enabling them.',
    'scope': 'installed read-only OS diagnostic dependency; version and filtered probe inventory only',
    'results': results,
}
(WORK / 'result.json').write_text(json.dumps(record, sort_keys=True, indent=2) + '\n')
print(json.dumps(results))
