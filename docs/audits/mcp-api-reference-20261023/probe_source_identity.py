#!/usr/bin/env python3
"""Capture complete real source-selector exchanges at the current code boundary."""
import gzip
import hashlib
import json
from pathlib import Path
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[3]
assert Path.cwd().resolve() == ROOT
sys.path.insert(0, str(ROOT / 't/python'))
from test_fixture_mcp_source_identity import capture
from test_fixture_mcp_stdio import Session
from generate_pod_reference import local_path

output = local_path(ROOT, sys.argv[1])
assert output.suffix == '.gz' and not output.exists()
paths = ['perl/FSM/Support/SemanticIntrospectionMCPAdapter.pm', 'bin/fsmgen-mcp',
         't/python/test_fixture_mcp_source_identity.py',
         'docs/audits/mcp-api-reference-20261023/verify_inventory.py',
         'docs/audits/mcp-api-reference-20261023/probe_source_identity.py']
record = {'head': subprocess.check_output(['git', 'rev-parse', 'HEAD']).decode().strip(),
          'source_sha256': {p: hashlib.sha256((ROOT / p).read_bytes()).hexdigest() for p in paths}}
with Session(['perl', 'bin/fsmgen-mcp', '--workspace-root', '.']) as server:
    record['result'] = capture(server)
    record['sent_utf8'] = server.sent.decode('utf-8')
    record['received_utf8'] = server.received.decode('utf-8')
record['exit_status'] = server.process.returncode
record['orderly_eof'] = True
with gzip.GzipFile(filename=str(output), mode='wb', mtime=0) as out:
    out.write((json.dumps(record, indent=2, ensure_ascii=False) + '\n').encode('utf-8'))
print('Captured complete source-identity exchanges: ' + output.relative_to(ROOT).as_posix())
