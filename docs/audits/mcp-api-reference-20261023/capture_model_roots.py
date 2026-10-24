#!/usr/bin/env python3
"""Capture every public metadata result root without running source/backend work."""
import base64
import gzip
import hashlib
import json
from pathlib import Path
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[3]
assert Path.cwd().resolve() == ROOT
sys.path.insert(0, str(ROOT / 'scripts'))
sys.path.insert(0, str(ROOT / 't/python'))
from generate_pod_reference import local_path
from test_fixture_mcp_metadata_schemas import MetadataClient, save_capture

SELF = 'docs/audits/mcp-api-reference-20261023/capture_model_roots.py'
ALIASES = {'all', 'contracts', 'examples', 'vial_tooling_v1', 'vial_tooling_v2', 'vial_inspection'}
OWNER = 'PERL-POD-API-REFERENCE.6.1.2.3.1'
NATIVE_PROGRAM = r'''use strict; use warnings;
use JSON::PP ();
use FSM::Support::CapabilityManifest ();
use FSM::Support::SemanticIntrospectionContract ();
use FSM::VIAL::Tool ();
print JSON::PP->new->canonical->ascii->encode({
    manifest => FSM::Support::CapabilityManifest::build_capability_manifest(),
    source_query_kinds => FSM::Support::SemanticIntrospectionContract::semantic_introspection_source_query_kinds(),
    vial_tooling_v1 => FSM::VIAL::Tool::vial_tool_capabilities(),
    vial_tooling_v2 => FSM::VIAL::Tool::vial_tool_capabilities_v2(),
    vial_inspection => FSM::VIAL::Tool::vial_source_inspection_capabilities(),
});
'''


def capture(server):
    client = MetadataClient(server)
    client.call('tools/list')
    resources = client.call('resources/list')['resources']
    client.call('resources/templates/list')
    manifest = None
    for resource in resources:
        result = client.call('resources/read', {'uri': resource['uri']})
        if resource['uri'] == 'fsmgen://capabilities':
            manifest = json.loads(result['contents'][0]['text'])
    assert type(manifest) is dict
    for version in (1, 2):
        client.call('resources/read', {'uri': 'fsmgen://vial/%d/capabilities' % version})
    for section in sorted(set(manifest) | ALIASES):
        client.call('tools/call', {'name': 'fsmgen_capability_query', 'arguments': {'section': section}})
    return client.exchanges


def main(output_name):
    output = local_path(ROOT, output_name)
    assert output.name.endswith('.json.gz') and not output.exists()
    raw = output.with_name(output.name[:-len('.json.gz')] + '-raw.json.gz')
    assert not raw.exists()
    top = [p for p in subprocess.check_output(['git', 'ls-files', '-z', 'perl']).decode().split('\0')
           if p.endswith('.pm') and not p.startswith('perl/FSM/')]
    save_capture(raw.relative_to(ROOT).as_posix(), capture,
                 extra_paths=top + ['README.md', 'bin/fsmgen', SELF, 'scripts/generate_pod_reference.py'])
    data = json.loads(gzip.decompress(raw.read_bytes()))
    native_path = output.with_name(output.name[:-len('.json.gz')] + '-native.json.gz')
    assert not native_path.exists()
    native = subprocess.run(['perl', '-Iperl', '-e', NATIVE_PROGRAM], cwd=ROOT,
                            capture_output=True, timeout=120)
    # Preserve exact bytes/status even if the independent binding fails.
    native_record = {'head': data['head'], 'source_sha256': data['source_sha256'],
        'mcp_raw_capture': raw.relative_to(ROOT).as_posix(),
        'mcp_raw_sha256': hashlib.sha256(raw.read_bytes()).hexdigest(), 'program': NATIVE_PROGRAM,
        'exit_status': native.returncode, 'stdout_base64': base64.b64encode(native.stdout).decode(),
        'stderr_base64': base64.b64encode(native.stderr).decode()}
    native_path.write_bytes(gzip.compress((json.dumps(native_record, indent=2) + '\n').encode(), mtime=0))
    assert native.returncode == 0 and native.stderr == b'', 'Native metadata binding failed; exact bytes retained'
    data['native_api'] = json.loads(native.stdout)
    # The generic collector fingerprints before startup. Refuse concurrent
    # source/HEAD movement rather than attaching one epoch to another's data.
    assert data['head'] == subprocess.check_output(['git', 'rev-parse', 'HEAD']).decode().strip()
    assert data['source_sha256'] == {p: hashlib.sha256((ROOT / p).read_bytes()).hexdigest()
                                   for p in data['source_sha256']}
    perl = subprocess.check_output(['perl', '-MJSON::PP', '-e',
        'print JSON::PP->new->canonical->encode({perl=>"$^V",json_pp=>"$JSON::PP::VERSION"})'])
    data['capture_identity'] = {
        'owner': OWNER, 'raw_capture': raw.relative_to(ROOT).as_posix(),
        'raw_sha256': hashlib.sha256(raw.read_bytes()).hexdigest(),
        'native_capture': native_path.relative_to(ROOT).as_posix(),
        'native_sha256': hashlib.sha256(native_path.read_bytes()).hexdigest(),
        'python': {'implementation': sys.implementation.name, 'version': list(sys.version_info)},
        'perl_runtime': json.loads(perl),
        'scope': 'metadata roots only; no source query, planning, simulation or backend execution',
    }
    output.write_bytes(gzip.compress((json.dumps(data, indent=2, ensure_ascii=False) + '\n').encode(), mtime=0))
    print('Source/runtime-bound model roots retained: ' + output.relative_to(ROOT).as_posix())


if __name__ == '__main__':
    assert len(sys.argv) == 2, 'Usage: capture_model_roots.py REPOSITORY_RELATIVE_OUTPUT.json.gz'
    main(sys.argv[1])
