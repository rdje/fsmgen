#!/usr/bin/env python3
"""Recheck native POD delivery and prove current generation writes no assets."""
import hashlib
import json
from pathlib import Path
import subprocess
import sys

root = Path(__file__).resolve().parents[3]
assert Path.cwd().resolve() == root, 'Run from repository root'
output = root / 'docs/book/src/perl-api'


def snapshot():
    return {p.relative_to(output).as_posix():
            {'sha256': hashlib.sha256(p.read_bytes()).hexdigest(), 'mtime_ns': p.stat().st_mtime_ns}
            for p in output.rglob('*') if p.is_file()}


commands = []


def run(arguments):
    result = subprocess.run(arguments, cwd=root, capture_output=True)
    commands.append({'arguments': arguments, 'exit_status': result.returncode,
                     'stdout': result.stdout.decode(), 'stderr': result.stderr.decode()})
    assert result.returncode == 0, commands[-1]
    return result.stdout


before = snapshot()
assert before, 'Generate an intact current reference before this qualification'
assert run(['python3', '-B', 'scripts/generate_pod_reference.py', '--check']).strip() == b'pod-reference: current'
assert run(['python3', '-B', 'scripts/generate_pod_reference.py']).strip() == b'pod-reference: current'
run(['mdbook', 'build', 'docs/book'])
assert snapshot() == before, 'Current generation/check/native build wrote reference assets'
delivery = json.loads(run(['python3', '-B', 'docs/audits/pod-api-20261023/verify_delivery.py', 'docs/book/book']))
run(['python3', '-B', 'scripts/check_book_source_index.py'])
run(['python3', '-B', 'scripts/book_source_references.py', '--check'])
run(['python3', '-B', 'scripts/book_source_references.py', '--verify-build', 'docs/book/book'])
print(json.dumps({'reader_sha256': hashlib.sha256(Path(__file__).read_bytes()).hexdigest(),
                  'commands': commands, 'delivery': delivery, 'no_asset_bytes_or_mtimes_changed': True,
                  'reference_snapshot': before,
                  'reference_manifest': json.loads((output / '.fsmgen-pod-reference.json').read_bytes())},
                 indent=2, sort_keys=True))
