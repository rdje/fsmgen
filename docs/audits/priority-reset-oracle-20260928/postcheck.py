#!/usr/bin/env python3
"""Independently check workspace and selected-command residue after observation."""
from datetime import datetime, timezone
import json
from pathlib import Path
import subprocess

ROOT = Path(__file__).resolve().parents[3]
CAPTURE = ROOT / '.artifacts/priority-native-observer/priority_repair_corrected'
first = json.loads((CAPTURE / 'compile_a.json').read_bytes())
argv = first['arguments'][0]
work = str(Path(argv[argv.index('--Mdir') + 1]).parent)
assert work.startswith('.artifacts/tmp/tests/') and '..' not in Path(work).parts
processes = subprocess.check_output(['/bin/ps', '-axo', 'pid=,ppid=,command='], text=True)
residue = [line.strip() for line in processes.splitlines() if work in line]
record = {
    'observed_utc': datetime.now(timezone.utc).isoformat(),
    'work': work,
    'workspace_absent': not (ROOT / work).exists(),
    'selected_command_residue': residue,
    'native_pid_absence': 'not independently measured; successful native calls intentionally produce no context records',
    'stage_cleanup': 'retained complete supervisor cleanup in each stage',
}
output = ROOT / '.artifacts/priority-runtime-qualified/postcheck.json'
with output.open('x') as stream:
    json.dump(record, stream, indent=2, sort_keys=True)
    stream.write('\n')
assert record['workspace_absent'] and not residue
print('Selected workspace and commands are absent; successful native-child PID identities were not independently captured.')
