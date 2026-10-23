#!/usr/bin/env python3
"""Execute the actual facade POD synopses with repository-local artifacts."""
import hashlib
import json
from pathlib import Path
import subprocess

root = Path(__file__).resolve().parents[3]
assert Path.cwd().resolve() == root, 'Run from the repository root'
work = root / '.artifacts/pod-api/examples'
work.mkdir(parents=True, exist_ok=True)
entries = json.loads((root / 'docs/pod-api-entrypoints.json').read_text())
evidence = []
for module in entries:
    path = Path('perl/' + module.replace('::', '/') + '.pm')
    raw = path.read_bytes()
    section = raw.decode().split('=head1 SYNOPSIS\n', 1)[1].split('=head1 ', 1)[0].split('=cut', 1)[0]
    snippet = '\n'.join(line[4:] for line in section.splitlines() if line.startswith('    ')) + '\n'
    assert 'use FSM::' in snippet, module
    script = work / (module.replace('::', '-') + '.pl')
    script.write_text(snippet)
    result = subprocess.run(['perl', '-Iperl', str(script.relative_to(root))],
                            cwd=root, capture_output=True)
    (script.with_suffix('.stdout')).write_bytes(result.stdout)
    (script.with_suffix('.stderr')).write_bytes(result.stderr)
    assert result.returncode == 0, (module, result.returncode, result.stderr.decode(errors='replace'))
    text = result.stdout.decode('utf-8')
    if module == 'FSM::Adapter::ISF':
        assert text.strip() == 'i2c_master'
    elif module == 'FSM::Pipeline::HDLGenerator':
        assert 'module ahb_lite_subordinate' in text and 'endmodule' in text
    elif module == 'FSM::Scheduler::ISF':
        report = json.loads(text)
        assert report['scheduled_fsm'] == 'i2c_master.fsm' and report['schema_version'] == 1
    elif module == 'FSM::Support::CapabilityManifest':
        manifest = json.loads(text)
        assert manifest['manifest_schema_version'] == 1
        assert manifest['embedding']['hdl_generator_facade']['method_names'] == ['new', 'generate_hdl_from_file']
    elif module == 'FSM::Support::SemanticIntrospectionMCPAdapter':
        response = json.loads(text)
        assert response['jsonrpc'] == '2.0' and response['id'] == 1
        assert 'fsmgen_vial_inspect' in [tool['name'] for tool in response['result']['tools']]
    elif module == 'FSM::VIAL::Tool':
        inspection = json.loads(text)
        assert isinstance(inspection, dict) and inspection
    else:
        raise AssertionError('Unqualified synopsis: ' + module)
    evidence.append({'module': module, 'source': path.as_posix(),
                     'source_sha256': hashlib.sha256(raw).hexdigest(),
                     'snippet_sha256': hashlib.sha256(snippet.encode()).hexdigest(),
                     'exit_status': result.returncode, 'observation': 'expected public result accepted'})
print(json.dumps(evidence, indent=2, sort_keys=True))
