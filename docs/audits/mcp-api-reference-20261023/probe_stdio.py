#!/usr/bin/env python3
"""Observe real open-pipe replies, with an independent forced-flush control."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import select
import subprocess
import time

root = Path(__file__).resolve().parents[3]
assert Path.cwd().resolve() == root
parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--expect', choices=['buffered', 'streaming'], required=True)
args = parser.parse_args()
program = '''use IO::Handle;
use FSM::Support::SemanticIntrospectionMCPAdapter;
STDOUT->autoflush(1) if shift @ARGV;
FSM::Support::SemanticIntrospectionMCPAdapter->new(repo_root=>'.',workspace_root=>'.')->run_stdio();'''
commands = [('launcher', ['perl', 'bin/fsmgen-mcp', '--workspace-root', '.'], args.expect == 'streaming'),
            ('adapter_default', ['perl', '-Iperl', '-e', program, '0'], args.expect == 'streaming'),
            ('adapter_forced_flush', ['perl', '-Iperl', '-e', program, '1'], True)]
observations = []
for label, command, expected in commands:
    request = (json.dumps({'jsonrpc': '2.0', 'id': label, 'method': 'ping'}) + '\n').encode()
    process = subprocess.Popen(command, cwd=root, stdin=subprocess.PIPE, stdout=subprocess.PIPE,
                               stderr=subprocess.PIPE, bufsize=0)
    before = bytearray()
    started = time.monotonic()
    deadline = started + 3
    try:
        process.stdin.write(request)
        process.stdin.flush()
        while b'\n' not in before:
            remaining = deadline - time.monotonic()
            if remaining <= 0 or not select.select([process.stdout], [], [], remaining)[0]:
                break
            raw = os.read(process.stdout.fileno(), 4096)
            if not raw:
                break
            before.extend(raw)
        alive_before_eof = process.poll() is None
        elapsed = time.monotonic() - started
    finally:
        process.stdin.close()
        process.stdin = None
        try:
            after, errors = process.communicate(timeout=10)
        except subprocess.TimeoutExpired:
            process.kill()
            after, errors = process.communicate()
    observation = {'case': label, 'command': command, 'request': request.decode(),
                   'before_eof': before.decode(), 'after_eof': after.decode(),
                   'complete_reply_before_eof': b'\n' in before, 'observation_seconds': elapsed,
                   'process_alive_before_eof': alive_before_eof,
                   'stderr': errors.decode(), 'exit_status': process.returncode}
    assert observation['complete_reply_before_eof'] == expected, observation
    assert alive_before_eof and process.returncode == 0 and not errors, observation
    assert json.loads(before + after) == {'jsonrpc': '2.0', 'id': label, 'result': {}}, observation
    observations.append(observation)
paths = ['bin/fsmgen-mcp', 'perl/FSM/Support/SemanticIntrospectionMCPAdapter.pm']
print(json.dumps({'expectation': args.expect, 'observations': observations,
                  'reader_sha256': hashlib.sha256(Path(__file__).read_bytes()).hexdigest(),
                  'selected_sources': {p: {'sha256': hashlib.sha256((root / p).read_bytes()).hexdigest(),
                                           'text': (root / p).read_text()} for p in paths},
                  'head': subprocess.check_output(['git', 'rev-parse', 'HEAD']).decode().strip(),
                  'perl': subprocess.check_output(['perl', '-e', 'print $^V']).decode(),
                  'scope': 'Selected launcher/adapter identities and bounded open-pipe observations; '
                           'no complete transitive footprint, timing guarantee or platform-matrix claim.'},
                 indent=2, sort_keys=True))
