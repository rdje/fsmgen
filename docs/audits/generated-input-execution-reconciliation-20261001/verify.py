"""Authenticate the scoped requirement crosswalk and retained verification."""
import hashlib
import json
import subprocess
from pathlib import Path

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[2]


def digest(data):
    return hashlib.sha256(data).hexdigest()


def receipts(public, direct, generated):
    assert 'All tests successful.' in public and 'Files=6, Tests=39,' in public
    assert 'Result: PASS' in public and 'Result: FAIL' not in public
    assert 'Both direct packed-input targets and actual unsigned-property rejection verified' in direct
    assert 'Both generated/domain witnesses in both Verilog-family targets and actual unsigned-property rejection verified' in generated


def main():
    m = json.loads((HERE / 'manifest.json').read_bytes())
    assert m['schema'] == 'fsmgen.generated_input_execution_reconciliation_manifest.v1'
    assert m['baseline_revision'] == '153c79aca9b75354dd0753c448688a4f032f3956'
    files = {str(p.relative_to(HERE)) for p in HERE.rglob('*') if p.is_file() and p.name != 'manifest.json'}
    assert files == set(m['sha256'])
    for name, expected in m['sha256'].items():
        assert digest((HERE / name).read_bytes()) == expected
    for name, record in m['producers'].items():
        blob = subprocess.check_output(['git', 'rev-parse', m['baseline_revision'] + ':' + name], cwd=ROOT).decode().strip()
        assert blob == record['git_blob']
        assert digest(subprocess.check_output(['git', 'cat-file', 'blob', blob], cwd=ROOT)) == record['sha256']
    for name, expected in m['prerequisites'].items():
        assert digest((ROOT / name).read_bytes()) == expected
    r = json.loads((HERE / 'requirements.json').read_bytes())
    assert r['schema'] == 'fsmgen.generated_input_execution_reconciliation.v1'
    assert r['baseline_revision'] == m['baseline_revision']
    assert [row['requirement'] for row in r['requirements']] == [
        'Exact ordered packed layout and signed/state leaf declarations',
        'Live inherited inputs and reused readers',
        'Sole generated whole-copy writer and owner reset',
        'Call-role scalar output binding',
        'Ordinary and named-domain ownership',
        'Repeated activation and signed-property falsification',
        'Public products, refusals and prior baselines']
    assert r['remaining'] == ['supported backend/input completion .5.5',
        'record outputs and full aggregate delivery', 'X/Z and reset-free initialization qualification',
        'historical native EPERM cause and startup/full-CI/push gates']
    values = [(HERE / name).read_text() for name in ('public-regression.txt', 'direct-saved.txt', 'generated-saved.txt')]
    receipts(*values)
    for bad in ((values[0].replace('Result: PASS', 'Result: FAIL'), values[1], values[2]),
                (values[0], 'unrelated success', values[2]),
                (values[0], values[1], values[2].replace('actual unsigned-property rejection verified', 'unqualified'))):
        try:
            receipts(*bad)
        except AssertionError:
            continue
        raise AssertionError('weakened or unrelated reconciliation receipt accepted')
    print('Complete scoped requirement crosswalk, exact baseline source objects and public/scalar/storage regression authenticated. Saved direct/generated positive and actual unsigned-negative verification pass; hostile receipt controls reject. Backend/input and full aggregate delivery remain open.')


if __name__ == '__main__':
    main()
