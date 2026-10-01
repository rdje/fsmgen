#!/usr/bin/env python3
"""Verify saved repair/control scope and source identities without HDL work."""
import hashlib
import json
from pathlib import Path
import subprocess

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[2]


def digest(data):
    return hashlib.sha256(data).hexdigest()


def receipts(focused, red, regression):
    assert 'All tests successful.' in focused and 'Files=2, Tests=25,' in focused
    assert 'All tests successful.' in regression and 'Files=8, Tests=49,' in regression
    assert 'Result: PASS' in focused and 'Result: PASS' in regression
    assert 'Result: FAIL' in red and 'Failed 2/2 subtests' in red
    assert 'not ok 1 - typed carriers preserve exact nested data models' in red
    assert 'not ok 2 - actual previously failing source changes only its illegal carrier declaration' in red
    assert 'wire bit signed [4:0] two_scalar;' in red
    assert 'wire fsmgen_m14_typed_carriers__mixed__fsmgen_t mixed_bus;' in red


def main():
    manifest = json.loads((HERE / 'manifest.json').read_bytes())
    assert manifest['schema'] == 'fsmgen.typed_composition_carrier_repair.v1'
    assert manifest['hdl_execution'] == 'pending fresh qualified observation; no repair-slice HDL execution'
    members = {str(p.relative_to(HERE)) for p in HERE.rglob('*') if p.is_file() and p.name != 'manifest.json'}
    assert members == set(manifest['sha256'])
    for name, sha in manifest['sha256'].items():
        assert digest((HERE / name).read_bytes()) == sha, name
    for name, record in manifest['sources'].items():
        path = ROOT / name
        data = path.read_bytes() if path.is_file() and digest(path.read_bytes()) == record['sha256'] else subprocess.check_output(
            ['git', 'cat-file', 'blob', record['git_blob']], cwd=ROOT)
        assert digest(data) == record['sha256'], name
    original = subprocess.check_output(['git', 'show', manifest['predecessor'] + ':perl/FSM/Backend/VerilogFamily/StructuralRTLIREmitter.pm'], cwd=ROOT)
    assert original == (HERE / 'old-emitter.pm.source').read_bytes()
    assert digest((ROOT / manifest['first_failure_manifest']).read_bytes()) == manifest['first_failure_sha256']
    focused, red, regression = [(HERE / name).read_text() for name in ('focused.txt', 'old-emitter-red.txt', 'regression.txt')]
    receipts(focused, red, regression)
    for bad in ((red, focused, regression), (focused, regression, red),
                (focused, red.replace('wire bit signed [4:0]', 'wire logic signed [4:0]'), regression),
                (focused, red, regression.replace('Files=8, Tests=49,', 'Files=7, Tests=49,'))):
        try:
            receipts(*bad)
        except AssertionError:
            continue
        raise AssertionError('Unrelated or weakened repair evidence accepted')
    print('Saved typed-carrier repair, exact old-emitter RED and focused regression/source identities verified; genuine corrected HDL remains pending.')


if __name__ == '__main__':
    main()
