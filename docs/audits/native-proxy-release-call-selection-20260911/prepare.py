"""Select the complete saved healthy domain without reusing numeric call IDs."""
import hashlib
import importlib.util
import json
from pathlib import Path
import subprocess

BASE = Path(__file__).resolve().parent
ROOT = BASE.parents[2]
BOUNDARY = BASE.parent / 'native-proxy-observation-archive-release-boundaries-20260911'
REVISION = 'e0cfaecedbfb44f757e44660fa940bf15df47e6b'


def load(path): return json.loads(path.read_bytes())
def module(name, path):
    spec = importlib.util.spec_from_file_location(name, path); value = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(value); return value


def build():
    original = load(BOUNDARY / 'plan.json'); saved = load(BOUNDARY / 'result/qualification.json')
    domain = load(BOUNDARY / 'result/fault-domain.json')
    model = module('call_selection_model_prepare', BASE / 'model.py')
    prior = module('call_selection_boundary_prepare', BOUNDARY / 'audit.py')
    prior.authenticate(original); prior.verify(original, saved)
    owner = original['owner'].rsplit('.', 1)[0] + '.3.1'; parent = owner.rsplit('.', 1)[0]
    partitions = []
    for profile, row, projection in zip(original['profiles'], saved['cases'], domain['profiles'], strict=True):
        spec, _ = prior.OLD.setup(row)
        calls = prior.FLOW.derive(row['context'], row['operation']['before'], spec)
        states = {v['address']: v['effects'] for v in model.vector(calls, original['sealed_continuations'])}
        for phase in ('before', 'after'):
            cases = []
            for cut in projection['boundaries']:
                if not cut['eligible'] or cut['phase'] != phase: continue
                call = row['operation']['boundary_calls'][cut['call_id']]
                address = model.address(call['name'], call['occurrence'], phase)
                cases.append(dict(address=address, symbol=call['name'], occurrence=call['occurrence'], phase=phase,
                                  source_call_id=call['id'], source_event=cut['event'], baseline_effects=states[address]))
            partitions.append(dict(id=profile['id'] + ':' + phase, owner=parent + '.' + str(len(partitions) + 2),
                                   profile_id=profile['id'], phase=phase, selection=profile['selection'], cases=cases))
    paths = {p['path'] for p in original['inputs']}
    paths.update(str(p.relative_to(ROOT)) for p in BOUNDARY.rglob('*') if p.is_file())
    inputs = []
    for path in sorted(paths):
        raw = (ROOT / path).read_bytes()
        assert raw == subprocess.check_output(['git', 'show', REVISION + ':' + path], cwd=ROOT)
        inputs.append(dict(path=path, size_bytes=len(raw), sha256=hashlib.sha256(raw).hexdigest()))
    return dict(schema='fsmgen.release_call_selection_plan.v1', owner=owner, source_revision=REVISION,
                inputs=inputs, partitions=partitions, sealed_symbols=list(original['sealed_continuations']),
                binding='Resolve exact symbol, zero-based occurrence and admitted phase against the source-derived current physical-input flow before release. Numeric source_call_id and source_event identify preserved evidence only, never a portable injection target.',
                failure_contract=dict(returned=1, success=0, release=None, runtime_authorized=0, executable=None,
                                      error='injected release call: <address>\n'),
                scope='Finite prospective safe-call partitions and pure effect/order-skeleton models. Original healthy runs remain exact. Synthetic order permutations are not valid reference codecs or admitted filesystem fixtures. No interruption matrix, close-error, omission, original producer or native execution runs in this leaf.')


if __name__ == '__main__':
    plan = build()
    with (BASE / 'plan.json').open('x') as stream: stream.write(json.dumps(plan, indent=2, sort_keys=True) + '\n')
    print(json.dumps(dict(partitions=len(plan['partitions']), inputs=len(plan['inputs']),
                         cases=[len(p['cases']) for p in plan['partitions']]), sort_keys=True))
