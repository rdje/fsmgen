#!/usr/bin/env python3
"""Retain guarded command results for the lowered-control partition slice."""
import argparse
import gzip
import hashlib
import json
import subprocess
from pathlib import Path
import tempfile

BASE = Path(__file__).resolve().parent
ROOT = BASE.parents[2]
OWNER = 'PERL-POD-API-REFERENCE.6.1.2.3.2.1.2.3.2.2.6.1'


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('name')
    parser.add_argument('commands', help='JSON list of {command, expected_status} records')
    args = parser.parse_args()
    if not args.name.replace('-', '').isalnum():
        raise SystemExit('Invalid capture name')
    record = BASE / (args.name + '.json')
    log = BASE / (args.name + '.log.gz')
    if record.exists() or log.exists():
        raise SystemExit('Refusing to overwrite retained results')
    commands = json.loads(args.commands)
    rows = []
    scratch = ROOT / '.artifacts/lowered-control'
    scratch.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryFile(dir=scratch) as stream:
        for row in commands:
            command = row['command']
            stream.write((json.dumps(command) + '\n').encode()); stream.flush()
            result = subprocess.run(['scripts/run_with_ram_guard.sh', '--'] + command,
                                    cwd=ROOT, stdout=stream, stderr=subprocess.STDOUT)
            rows.append({'command': command, 'expected_status': row.get('expected_status', 0),
                         'exit_status': result.returncode})
            print(json.dumps(rows[-1]), flush=True)
            if result.returncode != row.get('expected_status', 0):
                break
        stream.seek(0)
        raw = stream.read()
    normalized = raw.replace(str(ROOT).encode(), b'<repository>')
    log.write_bytes(gzip.compress(normalized, mtime=0))
    record.write_text(json.dumps({'owner': OWNER, 'commands': rows,
        'complete': len(rows) == len(commands),
        'log': log.relative_to(ROOT).as_posix(),
        'original_log_sha256': hashlib.sha256(raw).hexdigest(),
        'retained_log_sha256': hashlib.sha256(normalized).hexdigest(),
        'normalization': 'Dynamic repository-root prefix only; command statuses unchanged.',
        'instrument': {'path': Path(__file__).relative_to(ROOT).as_posix(),
                       'text': Path(__file__).read_text(),
                       'sha256': hashlib.sha256(Path(__file__).read_bytes()).hexdigest()}}, indent=2) + '\n')
    if len(rows) != len(commands) or any(row['exit_status'] != row['expected_status'] for row in rows):
        raise SystemExit('Unexpected check result; original output retained')


if __name__ == '__main__':
    main()
