#!/usr/bin/env python3
"""Compare complete unchanged T1445 projections using old and current adapters."""
import hashlib
import json
from pathlib import Path
import subprocess
import tempfile

root = Path(__file__).resolve().parents[3]
assert Path.cwd().resolve() == root
revision = subprocess.check_output(['git', 'rev-parse', 'c63f76753']).decode().strip()
module = 'perl/FSM/Support/SemanticIntrospectionMCPAdapter.pm'
original = subprocess.check_output(['git', 'show', revision + ':' + module])
test = (root / 't/1445-semantic-introspection-mcp-schema-snapshots.t').read_text()
needle = "my $repo_root = abs_path(File::Spec->catdir($FindBin::Bin, '..'));"
assert test.count(needle) == 1
test = test.replace(needle, "my $repo_root = abs_path('.');")
rows = []
with tempfile.TemporaryDirectory(prefix='mcp-snapshot-probe-', dir=root / '.artifacts/tmp') as name:
    work = Path(name)
    old = work / module
    old.parent.mkdir(parents=True)
    old.write_bytes(original)
    for label, imports in [('original', ['-I' + str(work / 'perl'), '-Iperl']),
                           ('current', ['-Iperl'])]:
        output = work / (label + '.json')
        script = work / (label + '.t')
        script.write_text(test + "\nopen my $capture, '>', $ENV{FSMGEN_SNAPSHOT_CAPTURE} or die $!;\n"
                          + "print {$capture} JSON::PP->new->canonical->encode(build_schema_snapshot($adapter));\n"
                          + "close $capture or die $!;\n")
        import os
        environment = dict(os.environ, FSMGEN_SNAPSHOT_CAPTURE=str(output))
        result = subprocess.run(['perl', *imports, '-MFSM::Support::SemanticIntrospectionMCPAdapter',
                                 str(script)], cwd=root, env=environment, capture_output=True)
        rows.append({'case': label, 'exit_status': result.returncode,
                     'stdout': result.stdout.decode(), 'stderr': result.stderr.decode(),
                     'projection': json.loads(output.read_bytes())})
    assert rows[0]['exit_status'] == rows[1]['exit_status'] == 1
    assert rows[0]['projection'] == rows[1]['projection']
    expected = json.loads((root / 't/fixtures/semantic_introspection_mcp/read_only_schema_snapshot.json').read_bytes())
    assert rows[0]['projection'] != expected
assert not work.exists()
print(json.dumps({'original_revision': revision, 'original_adapter_sha256': hashlib.sha256(original).hexdigest(),
                  'current_adapter_sha256': hashlib.sha256((root / module).read_bytes()).hexdigest(),
                  'original_test_sha256': hashlib.sha256((root / 't/1445-semantic-introspection-mcp-schema-snapshots.t').read_bytes()).hexdigest(),
                  'relocation_only': 'root changed to current repository; exact snapshot projector and assertions retained',
                  'complete_projected_products_equal': True, 'expected_fixture': expected,
                  'cases': rows, 'exact_disposable_workspace_removed': True}, indent=2, sort_keys=True))
