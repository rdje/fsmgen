"""Seal the completed unary observation; never launch a runtime process."""
import hashlib
import json
import os
from pathlib import Path
import shutil
import subprocess

ROOT = Path.cwd()
HERE = Path('docs/audits/unary-runtime-observation-20261022')
WORK = Path('.artifacts/tmp/unary-runtime-5dce0bc6a-20261022')
CAPTURE = Path('.artifacts/unary-native-observer/unary_oct22')
ADMISSION = CAPTURE.with_name('unary_oct22-admission.json')
EVIDENCE = HERE / 'evidence'
EVIDENCE.mkdir()


def digest(data):
    return hashlib.sha256(data).hexdigest()


def save(name, raw):
    path = EVIDENCE / name
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open('xb') as stream:
        stream.write(raw)


def save_json(name, data):
    save(name, (json.dumps(data, indent=2, sort_keys=True) + '\n').encode())


before = json.loads((WORK / 'before.json').read_bytes())
assert before['revision'] == subprocess.check_output(['git', 'rev-parse', 'HEAD'], text=True).strip()
after = []
for row in before['before_inputs']:
    path = row['path']
    raw = Path(path).read_bytes()
    assert digest(raw) == row['sha256']
    assert raw == subprocess.check_output(['git', 'show', 'HEAD:' + path])
    after.append({'path': path, 'sha256': digest(raw)})
entry = before['tool_dependency']
assert digest(Path(entry['resolved_installed_entrypoint']).read_bytes()) == entry['sha256']
save('before.json', (WORK / 'before.json').read_bytes())
save_json('after.json', after)
save('admission.json', ADMISSION.read_bytes())
save('outer.json', (WORK / 'outer.json').read_bytes())
save('run.pl', (WORK / 'run.pl').read_bytes())
log = Path('.artifacts/logs/unary-runtime-observation-20261022.log').read_bytes()
save('run.log', log.replace(str(ROOT).encode(), b'<REPO>'))
save_json('run-log-identity.json', {'raw_sha256': digest(log), 'raw_bytes': len(log),
                                 'normalization': 'Exact current repository root only.'})
for path in sorted(CAPTURE.iterdir()):
    assert path.is_file() and path.suffix in ('.json', '.jsonl')
    save(path.name, path.read_bytes())
for name in ('t/2090-isf-unary-reduction-runtime.t', 't/data/unary_reduction_runtime.isf',
             't/data/unary_reduction_runtime_tb.sv', 't/data/unary_reduction_runtime_vectors.hex'):
    save('inputs/' + Path(name).name, Path(name).read_bytes())
summary = json.loads((CAPTURE / 'summary.json').read_bytes())
workspaces = set()
for receipt in summary['receipts']:
    stage = json.loads((CAPTURE / receipt['path']).read_bytes())
    argv = stage['arguments'][0]
    if receipt['stage'] == 'compile':
        obj = Path(argv[argv.index('--Mdir') + 1])
        assert not obj.is_absolute() and obj.parent.parent == Path('.artifacts/tmp/tests')
        workspaces.add(str(obj.parent))
assert len(workspaces) == 1
# Independent post-return OS census; successful child births remain uncaptured.
command = ['/bin/ps', '-axo', 'pid=,ppid=,pgid=,command=']
ps = subprocess.run(command, check=True, capture_output=True, text=True)
matching = [line for line in ps.stdout.splitlines() if any(w in line for w in workspaces)]
assert matching == []
assert all(not Path(w).exists() for w in workspaces)
cache_paths = ['.artifacts/cache/unary-runtime/ccache', '.artifacts/tmp/unary-runtime-ccache',
               '.artifacts/cache/unary-runtime/clang-modules', '.artifacts/cache/unary-runtime/xdg']
assert all(os.stat(p).st_dev == os.stat(ROOT).st_dev for p in cache_paths)
save_json('postcheck.json', {'census_argv': command, 'matching_commands': matching,
    'workspaces': sorted(workspaces), 'workspaces_absent': True, 'cache_paths': cache_paths,
    'cache_devices_match_repository': True, 'successful_child_births_observed': False})
manifest = {'schema': 'fsmgen.unary_runtime_observation.v1', 'owner': 'ISF-REDUCTION-DELIVERY.1.4',
    'baseline_revision': before['revision'], 'capture': 'unary_oct22',
    'observer_manifest_sha256': digest(Path('docs/audits/unary-observer-20261022/manifest.json').read_bytes()),
    'scope': 'Both Verilog-family positives and actual wrong-source SystemVerilog; fixed two-state vectors, reset/hold/repeated sweeps.',
    'claim_legs': {'rederivation': 'Independent bit-walk/vector oracle, literal declarations/reduction records and actual compiled public-pin verdicts; complete source/Git/stage identities.',
        'falsification': 'Actual compiled wrong source yields only the intended row-one output-bit mismatch; hostile saved marker/result/coverage/bound/cleanup corruptions reject.',
        'durability': 'Committed fixed witness/observer and complete immutable stage/admission/source identities, static verifier, book/task and Git.'},
    'gaps': ['Successful-child PID birth identities are not observed by the failure-only hook.',
        'Generated HDL and native build files were removed by the fixed test cleanup; their exact bytes are not retained in this runtime epoch.',
        'No full Cartesian paired-input, X/Z, external override, VHDL runtime or complete transitive toolchain/environment attestation.',
        'Historical native EPERM cause remains unproved; no recurrence-only invocation.'],
    'sha256': {str(p.relative_to(HERE)): digest(p.read_bytes()) for p in sorted(HERE.rglob('*')) if p.is_file()}}
with (HERE / 'manifest.json').open('x') as stream:
    json.dump(manifest, stream, indent=2, sort_keys=True)
    stream.write('\n')
print('Completed unary observation retained; independent workspace/command census empty.')
