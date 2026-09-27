#!/usr/bin/env python3
"""Read bounded log-store statistics for the same historical window."""
import json
import os
from pathlib import Path
import subprocess

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[2]
WORK = ROOT / '.artifacts/native-group-host-statistics-human'
WORK.mkdir(exist_ok=False)
window = json.loads((HERE / 'window.json').read_bytes())
command = ['/usr/bin/log', 'stats', '--overview', '--style', 'human', '--count', '1',
           '--start', '@' + str(window['window_start_unix']),
           '--end', '@' + str(window['window_end_unix'])]
result = subprocess.run(command, cwd=ROOT,
                        env=dict(os.environ, TMPDIR=str(ROOT / '.artifacts/tmp')),
                        capture_output=True, timeout=30)
(WORK / 'stdout.txt').write_bytes(result.stdout)
(WORK / 'stderr.txt').write_bytes(result.stderr)
(WORK / 'result.json').write_text(json.dumps({
    'schema': 'fsmgen.native_group_host_statistics.v1', 'command': command,
    'exit_code': result.returncode, 'deadline_seconds': 30,
    'scope': 'same-window store overview; no message payloads requested',
}, sort_keys=True, indent=2) + '\n')
print(json.dumps({'exit_code': result.returncode,
                  'stdout_bytes': len(result.stdout), 'stderr_bytes': len(result.stderr)}))
