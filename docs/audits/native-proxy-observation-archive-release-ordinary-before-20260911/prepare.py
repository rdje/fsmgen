"""Prepare the first matrix and independent pure-flow expectations before pins."""
import hashlib
import importlib.util
import itertools
import json
from pathlib import Path
import subprocess

BASE = Path(__file__).resolve().parent
ROOT = BASE.parents[2]
SELECTION = BASE.parent / 'native-proxy-release-call-selection-20260911'
REVISION = '51bf29de9880c0db37ccfbbcc33ae9b1d7fdd937'


def load(path): return json.loads(path.read_bytes())
def signature(value): return hashlib.sha256(json.dumps(value, sort_keys=True, separators=(',', ':')).encode()).hexdigest()
def module(name, path):
    spec = importlib.util.spec_from_file_location(name, path); value = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(value); return value


def build():
    prior = module('ordinary_before_selection', SELECTION / 'audit.py')
    selection = load(SELECTION / 'plan.json'); prior.authenticate(selection)
    prior.verify(selection, load(SELECTION / 'result/qualification.json'))
    partition = selection['partitions'][0]
    assert partition['id'] == 'ordinary_retired_other_observation:before'
    boundary_plan = load(prior.BOUNDARY / 'plan.json')
    saved = load(prior.BOUNDARY / 'result/qualification.json')
    vectors = []
    for row in saved['cases']:
        spec, _ = prior.PRIOR.OLD.setup(row)
        calls = prior.PRIOR.FLOW.derive(row['context'], row['operation']['before'], spec)
        orders = []
        count = sum(p.startswith('references/') for p in row['operation']['before']['store'])
        for order in itertools.permutations(range(count)):
            reordered = prior.alternate_flow(row, spec, order)
            orders.append(dict(order=list(order), calls=len(reordered), flow_sha256=signature(reordered)))
        selectors = [case for part in selection['partitions'] if part['profile_id'] == row['profile_id'] for case in part['cases']]
        vectors.append(dict(profile_id=row['profile_id'], original_case=row['name'], context=row['context'],
                            before=row['operation']['before'], specification=spec, calls=len(calls),
                            flow_sha256=signature(calls), selectors=selectors, order_skeletons=orders))
    paths = {p['path'] for p in selection['inputs']}
    paths.update(str(p.relative_to(ROOT)) for p in SELECTION.rglob('*') if p.is_file())
    inputs = []
    for path in sorted(paths):
        raw = (ROOT / path).read_bytes()
        assert raw == subprocess.check_output(['git', 'show', REVISION + ':' + path], cwd=ROOT)
        inputs.append(dict(path=path, size_bytes=len(raw), sha256=hashlib.sha256(raw).hexdigest()))
    cases = [dict(index=0, name='healthy:ordinary', selector=None)]
    cases.extend(dict(index=i, name=case['address'], selector=case) for i, case in enumerate(partition['cases'], 1))
    plan = dict(schema='fsmgen.release_ordinary_before_plan.v1', owner=partition['owner'], source_revision=REVISION,
                component=BASE.name, partition=partition['id'], profile_id=partition['profile_id'],
                selection=partition['selection'], source_boundaries=boundary_plan['source_boundaries'],
                sealed_symbols=selection['sealed_symbols'], inputs=inputs, cases=cases,
                failure_contract=selection['failure_contract'],
                publication='Each completed case is a separate immutable JSON body, joined by exact size/hash in the final matrix manifest. Current inputs and resolved selector are persisted before release. Full completed bodies are not accumulated in the mutable ArchiveFixture report.',
                scope='One new healthy ordinary control and the complete ordinary retired before-call partition. Pure cross-profile flow/resolver controls support the shared helper only. No original qualifier, native process, after-call matrix, readback mutation, modeled close report or omitted close.')
    flow = dict(schema='fsmgen.release_call_flow_vectors.v1', owner=partition['owner'], sealed_symbols=selection['sealed_symbols'],
                cases=vectors, scope='Pure current-input call construction and selector resolution. Order-only variants are not valid reference codecs or admitted filesystem fixtures.')
    return plan, flow


if __name__ == '__main__':
    plan, flow = build()
    for name, value in [('plan.json', plan), ('flow-vectors.json', flow)]:
        with (BASE / name).open('x') as stream: stream.write(json.dumps(value, indent=2, sort_keys=True) + '\n')
    print(json.dumps(dict(matrix_cases=len(plan['cases']), inputs=len(plan['inputs']),
                         pure_baselines=len(flow['cases']), order_skeletons=sum(len(c['order_skeletons']) for c in flow['cases'])), sort_keys=True))
