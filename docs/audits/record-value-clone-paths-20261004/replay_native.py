"""Full unchanged original T1986 ordinary/bad native runs; exact stable selection.

Raw errors, synthetic trace and generated import nonce remain captured separately.
They are explicitly scoped outside this referent/value proof, never normalized.
"""
import argparse
import json
import subprocess
import sys
from pathlib import Path
from native import base, check_joint, conserved, exact, identity

BASE = Path('docs/audits/record-value-clone-paths-20261004')
NATIVE = Path('docs/audits/record-value-structured-clones-20261004')
parser = argparse.ArgumentParser()
parser.add_argument('--check', action='store_true')
args = parser.parse_args()
scratch = Path('.artifacts/record-value-clones-native-replay-20261004')
scratch.mkdir(parents=True, exist_ok=True)
binding = json.loads((BASE / 'binding.json').read_text())
inputs = {}
for path, row in binding['sources'].items():
    if path.startswith('docs/'):
        continue
    raw = Path(path).read_bytes()
    assert raw.decode() == row['body']
    inputs[path] = identity(raw)
receipts = []
for alias in (False, True):
    label = 'alias-result' if alias else 'ordinary'
    destination = scratch / (label + '.json')
    command = ['scripts/run_with_ram_guard.sh', '--', 'perl', str(NATIVE / 'observe.pl')] + (['--alias-result'] if alias else []) + ['--output', str(destination)]
    run = subprocess.run(command, text=True, capture_output=True)
    (scratch / (label + '.txt')).write_text(run.stdout + run.stderr)
    assert run.returncode == 0, run.stdout + run.stderr
    current = json.loads(destination.read_text())
    baseline = json.loads((NATIVE / (label + '.json')).read_text())
    # This closed checker compares every product/caller/input/kind and precise
    # primary failure, leaving complete raw process errors explicitly retained.
    deltas = conserved(baseline, current, False)
    clones = [dict(index=i, record=row) for i, row in enumerate(current['api']) if row['kind'] == 'structured-clone']
    expected = [dict(index=i, record=row) for i, row in enumerate(baseline['api']) if row['kind'] == 'structured-clone']
    assert exact(clones, expected), 'full native clone records including joint input/result referents reexecute exactly'
    for clone in clones:
        nodes = check_joint(clone['record'], require_detached=not alias)
        assert bool(nodes['shared']) == (alias and nodes['container'])
    consumer_projection = [{key: value for key, value in row.items() if not (i == 3 and key == 'actual')} for i, row in enumerate(current['consumers'])]
    stable = {'clones': clones, 'copies': current['copies'], 'helpers': current['helpers'], 'consumers': consumer_projection, 'host': current['host'], 'warnings': current['warnings']}
    raw_projection = json.dumps(stable, sort_keys=True, separators=(',', ':')).encode()
    # The full raw current native JSON/TAP stays in the same-volume workspace;
    # first executions are tracked whole, not replaced with normalized streams.
    receipts.append({'command': command, 'working_directory': '.', 'status': run.returncode, 'inputs': inputs, 'observer': identity((NATIVE / 'observe.pl').read_bytes()), 'stable_native_projection': identity(raw_projection), 'raw_process_exclusions': {'api_error_indices': [row['index'] for row in deltas if row['section'] == 'api'], 'consumer_actual_indices': [row['index'] for row in deltas if row['section'] == 'consumer'], 'parse_fields': [[row['index'], row['field']] for row in deltas if row['section'] == 'parse']}})
    if not args.check:
        (BASE / (label + '-reexecuted.json')).write_bytes(destination.read_bytes())
        (BASE / (label + '-reexecuted.txt')).write_text(run.stdout + run.stderr)
packet = {'python': sys.version, 'source_revision': binding['revision'], 'receipts': receipts}
if args.check:
    assert packet == json.loads((BASE / 'native-replays.json').read_text()), 'complete native source/profile/stable product/input/output/referent receipt identity'
else:
    (BASE / 'native-replays.json').write_text(json.dumps(packet, sort_keys=True, indent=2) + '\n')
print('PASS complete unchanged original native ordinary/actual shared-result runs retain every selected source/API/copy/helper/product/consumer pass and8251 full joint clone records. Raw native error streams/synthetic trace/temp import nonce stay separate; no full cause identity is claimed.')
