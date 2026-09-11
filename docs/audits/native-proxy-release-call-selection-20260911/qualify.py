"""Qualify only pure call selectors and effect/order skeletons; no new fixture."""
import hashlib
import importlib.util
import itertools
import json
from pathlib import Path

BASE = Path(__file__).resolve().parent
ROOT = BASE.parents[2]
LOG = ROOT / '.artifacts/logs' / BASE.name
BOUNDARY = BASE.parent / 'native-proxy-observation-archive-release-boundaries-20260911'


def load(path): return json.loads(path.read_bytes())
def signature(value): return hashlib.sha256(json.dumps(value, sort_keys=True, separators=(',', ':')).encode()).hexdigest()
def module(name, path):
    spec = importlib.util.spec_from_file_location(name, path); value = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(value); return value


def main():
    plan = load(BASE / 'plan.json'); pins = load(BASE / 'preflight-pins.json')
    for pin in pins + plan['inputs']:
        raw = (ROOT / pin['path']).read_bytes()
        assert len(raw) == pin['size_bytes'] and hashlib.sha256(raw).hexdigest() == pin['sha256']
    model = module('call_selection_qualified_model', BASE / 'model.py')
    prior = module('call_selection_qualified_boundary', BOUNDARY / 'audit.py')
    original = load(BOUNDARY / 'result/qualification.json'); fingerprint = signature(original)
    result = dict(schema='fsmgen.release_call_selection_qualification.v1', success=False, prospective_pins=pins,
                  baseline=[], order_skeletons=[], allocated=[], forbidden_process_attempts=0)
    def save(): (LOG / 'qualification.json').write_text(json.dumps(result, indent=2, sort_keys=True) + '\n')
    save()
    for row in original['cases']:
        spec, _ = prior.OLD.setup(row); context = row['context']; before = row['operation']['before']
        calls = prior.FLOW.derive(context, before, spec); vector = model.vector(calls, plan['sealed_symbols'])
        result['baseline'].append(dict(profile_id=row['profile_id'], calls=len(calls), selectors=len(vector), vector_sha256=signature(vector)))
        count = sum(path.startswith('references/') for path in before['store'])
        for order in itertools.permutations(range(count)):
            revised_context, revised_before = model.order_skeleton(context, before, order)
            reordered = prior.FLOW.derive(revised_context, revised_before, spec)
            output = model.vector(reordered, plan['sealed_symbols'])
            result['order_skeletons'].append(dict(profile_id=row['profile_id'], order=list(order), calls=len(reordered),
                selectors=len(output), vector_sha256=signature(output), numeric_symbol_order_sha256=signature([c['name'] for c in reordered])))
            save()
            assert output == vector
    result['inputs_unchanged'] = signature(original) == fingerprint
    assert result['inputs_unchanged']
    result['success'] = True; save()
    print(json.dumps(dict(baselines=len(result['baseline']), order_skeletons=len(result['order_skeletons']), success=True), sort_keys=True))


if __name__ == '__main__': main()
