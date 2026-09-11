"""Prepare the last-observation after-call domain from unchanged committed predecessors."""
import hashlib
import importlib.util
import json
from pathlib import Path
import subprocess

BASE = Path(__file__).resolve().parent
ROOT = BASE.parents[2]
PREDECESSOR = BASE.with_name('native-proxy-observation-archive-release-last-before-20260911')
REVISION = '612aa2052eabec11b446742918f8c87ac71ae05b'


def load(path): return json.loads(path.read_bytes())
def module(name, path):
    spec = importlib.util.spec_from_file_location(name, path)
    value = importlib.util.module_from_spec(spec); spec.loader.exec_module(value)
    return value


def build():
    previous = module('last_after_predecessor_audit', PREDECESSOR / 'audit.py')
    old = load(PREDECESSOR / 'plan.json'); previous.domain(old); previous.authenticate(old)
    selection = load(previous.SELECTION / 'plan.json')
    partition = selection['partitions'][7]
    assert partition['id'] == 'ordinary_retired_last_observation:after'
    paths = {p['path'] for p in old['inputs']}
    paths.update(str(p.relative_to(ROOT)) for p in PREDECESSOR.rglob('*') if p.is_file())
    inputs = []
    for name in sorted(paths):
        path = ROOT / name; raw = path.read_bytes()
        assert not path.is_symlink() and path.stat().st_dev == ROOT.stat().st_dev
        assert raw == subprocess.check_output(['git', 'show', REVISION + ':' + name], cwd=ROOT)
        inputs.append(dict(path=name, size_bytes=len(raw), sha256=hashlib.sha256(raw).hexdigest()))
    cases = [dict(index=0, name='healthy:last-observation', selector=None)]
    cases.extend(dict(index=i, name=c['address'], selector=c) for i, c in enumerate(partition['cases'], 1))
    assert len(cases) == 430
    return dict(schema='fsmgen.release_last_after_plan.v1', owner=partition['owner'], source_revision=REVISION,
        component=BASE.name, partition=partition['id'], profile_id=partition['profile_id'], selection=partition['selection'],
        source_boundaries=old['source_boundaries'], sealed_symbols=old['sealed_symbols'], inputs=inputs, cases=cases,
        failure_contract=selection['failure_contract'], publication=old['publication'],
        scope='One new healthy last-observation control and the complete ordinary last-observation after-call partition. Retire the target runtime and remove only the other observation hold during controlled setup. Preserve the selected image after its final reference is released. The selected helper is complete and only its callers remain interrupted. Source returns and sealed-after aliases are excluded. No original qualifier, native process, other profile, readback mutation, modeled close report or omitted close.')


if __name__ == '__main__':
    plan = build()
    with (BASE / 'plan.json').open('x') as stream: stream.write(json.dumps(plan, indent=2, sort_keys=True) + '\n')
    print(json.dumps(dict(matrix_cases=len(plan['cases']), inputs=len(plan['inputs'])), sort_keys=True))
