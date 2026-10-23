#!/usr/bin/env python3
"""Run the original observer and current checker on actual controlled programs."""
import hashlib
import json
from pathlib import Path
import subprocess
import sys
import tempfile

root = Path(__file__).resolve().parents[3]
assert Path.cwd().resolve() == root
sys.path.insert(0, str(root / 'scripts'))
import check_pod_api_examples as checker

revision = subprocess.check_output(['git', 'rev-parse', 'cfb13b284']).decode().strip()
producer_path = 'docs/audits/pod-api-20261023/check_examples.py'
producer = subprocess.check_output(['git', 'show', revision + ':' + producer_path])
rows = []
with tempfile.TemporaryDirectory(prefix='pod-observer-control-', dir=root / '.artifacts/tmp') as name:
    workspace = Path(name)
    for label, token in [('integer', '1'), ('integral_number', '1.0'), ('boolean', 'true')]:
        fixture = workspace / label
        script = fixture / producer_path
        script.parent.mkdir(parents=True)
        script.write_bytes(producer)
        config = fixture / 'docs/pod-api-entrypoints.json'
        config.write_text('{"FSM::Support::CapabilityManifest":"controlled observer input"}')
        payload = '{"manifest_schema_version":' + token + ',"embedding":{"hdl_generator_facade":{"method_names":["new","generate_hdl_from_file"]}}}'
        source = 'package FSM::Support::CapabilityManifest;\n1;\n__END__\n\n=head1 SYNOPSIS\n\n    use FSM::Support::CapabilityManifest;\n    print \'' + payload + '\';\n\n=cut\n'
        path = fixture / 'perl/FSM/Support/CapabilityManifest.pm'
        path.parent.mkdir(parents=True)
        path.write_text(source)
        previous = subprocess.run([sys.executable, '-B', producer_path], cwd=fixture, capture_output=True)
        assert previous.returncode == 0, previous.stderr.decode(errors='replace')
        error = None
        try:
            current = checker.check_examples(fixture)
            accepted = True
        except checker.ExampleError as refused:
            accepted, current, error = False, None, str(refused)
        assert accepted == (label != 'boolean')
        failed_members = {}
        if not accepted:
            assert 'expected numeric manifest schema version 1' in error
            dirs = list((fixture / '.artifacts/tmp').glob('pod-api-examples-*'))
            assert len(dirs) == 1
            failed_members = {p.name: p.read_text() for p in dirs[0].iterdir() if p.is_file()}
            assert failed_members['FSM-Support-CapabilityManifest.stdout'] == payload
        rows.append({'case': label, 'fixture_source': source, 'payload': payload,
                     'previous_exit_status': previous.returncode,
                     'previous_stdout': previous.stdout.decode(), 'previous_stderr': previous.stderr.decode(),
                     'current_accepted': accepted, 'current_evidence': current,
                     'current_error': error, 'current_failed_members': failed_members})
result = {'scope': 'Synthetic POD programs exercise observer result predicates; no product API emits these counterfeit payloads.',
          'original_producer_revision': revision, 'original_producer_path': producer_path,
          'original_producer_sha256': hashlib.sha256(producer).hexdigest(),
          'current_checker_sha256': hashlib.sha256((root / 'scripts/check_pod_api_examples.py').read_bytes()).hexdigest(),
          'probe_sha256': hashlib.sha256(Path(__file__).read_bytes()).hexdigest(),
          'original_producer': producer.decode(), 'cases': rows,
          'exact_disposable_workspace_removed': not workspace.exists()}
assert result['exact_disposable_workspace_removed']
print(json.dumps(result, sort_keys=True, indent=2))
