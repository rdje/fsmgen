#!/usr/bin/env python3
"""Run guarded publication checks with a recoverable live log and state file."""
import argparse
import gzip
import hashlib
import json
import os
from pathlib import Path
import subprocess

BASE = Path(__file__).resolve().parent
ROOT = BASE.parents[2]
OWNER = 'SEMANTIC-INTROSPECTION-MCP-FRONTIER.69.3'


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('name')
    parser.add_argument('commands', help='JSON list of command argument arrays')
    args = parser.parse_args()
    if not args.name.replace('-', '').isalnum():
        raise SystemExit('Invalid capture name')
    commands = json.loads(args.commands)
    if not commands or any(not isinstance(c, list) or not c or any(not isinstance(a, str) for a in c) for c in commands):
        raise SystemExit('Expected nonempty command argument arrays')
    if subprocess.check_output(['git', 'status', '--porcelain'], cwd=ROOT):
        raise SystemExit('Commit the checked inputs before starting a live run')
    scratch = ROOT / '.artifacts/push-readiness-20261025'
    scratch.mkdir(parents=True, exist_ok=True)
    if not scratch.resolve().is_relative_to(ROOT) or scratch.stat().st_dev != ROOT.stat().st_dev:
        raise SystemExit('Live data must remain inside the repository volume')
    live = scratch / (args.name + '.live.log')
    state = scratch / (args.name + '.state.json')
    record = BASE / (args.name + '.json')
    log = BASE / (args.name + '.log.gz')
    if any(p.exists() for p in (live, state, record, log)):
        raise SystemExit('Refusing to overwrite an existing run; inspect its state first')
    revision = subprocess.check_output(['git', 'rev-parse', 'HEAD'], cwd=ROOT, text=True).strip()
    rows = []

    def save_state(value):
        temporary = state.with_suffix('.next')
        temporary.write_text(json.dumps({'owner': OWNER, 'revision': revision,
            'live_log': live.relative_to(ROOT).as_posix(), 'commands': rows, **value}, indent=2) + '\n')
        temporary.replace(state)

    with live.open('xb') as stream:
        for command in commands:
            stream.write((json.dumps(command) + '\n').encode()); stream.flush()
            child = subprocess.Popen(['scripts/run_with_ram_guard.sh', '--'] + command,
                                     cwd=ROOT, stdout=stream, stderr=subprocess.STDOUT)
            birth = subprocess.run(['ps', '-p', str(child.pid), '-o', 'lstart='],
                                   capture_output=True, text=True).stdout.strip() or None
            save_state({'state': 'running', 'recorder_pid': os.getpid(), 'guard_pid': child.pid,
                        'guard_start_observed': birth, 'active_command': command})
            print(json.dumps({'state': state.relative_to(ROOT).as_posix(), 'command': command}), flush=True)
            status = child.wait()
            rows.append({'command': command, 'exit_status': status})
            save_state({'state': 'command_finished', 'last_exit_status': status})
            print(json.dumps(rows[-1]), flush=True)
            if status:
                break
    raw = live.read_bytes()
    normalized = raw.replace(str(ROOT).encode(), b'<repository>')
    log.write_bytes(gzip.compress(normalized, mtime=0))
    result = {'owner': OWNER, 'revision': revision, 'commands': rows,
        'complete': len(rows) == len(commands), 'log': log.relative_to(ROOT).as_posix(),
        'original_log_sha256': hashlib.sha256(raw).hexdigest(),
        'retained_log_sha256': hashlib.sha256(normalized).hexdigest(),
        'normalization': 'Dynamic repository-root prefix only; command statuses unchanged.',
        'instrument': {'path': Path(__file__).relative_to(ROOT).as_posix(),
                       'text': Path(__file__).read_text(),
                       'sha256': hashlib.sha256(Path(__file__).read_bytes()).hexdigest()}}
    record.write_text(json.dumps(result, indent=2) + '\n')
    save_state({'state': 'finished', 'result': record.relative_to(ROOT).as_posix()})
    if not result['complete'] or any(row['exit_status'] for row in rows):
        raise SystemExit('Check failed; complete first-run output and status retained')


if __name__ == '__main__':
    main()
