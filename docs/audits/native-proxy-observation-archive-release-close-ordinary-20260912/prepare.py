"""Prepare ordinary single-close cases and pure current-flow bindings."""
import hashlib
import importlib.util
import itertools
import json
from pathlib import Path
import subprocess

BASE = Path(__file__).resolve().parent
ROOT = BASE.parents[2]
REVISION = 'ac6208a46c3d2bab8d668c0a942b056520b0bfc6'
SELECTION = BASE.parent / 'native-proxy-release-close-selection-20260912'
CALLS = BASE.parent / 'native-proxy-observation-archive-release-ordinary-before-20260911'
BOUNDARY = BASE.parent / 'native-proxy-observation-archive-release-boundaries-20260911'
CALL_SELECTION = BASE.parent / 'native-proxy-release-call-selection-20260911'
JOIN = BASE.parent / 'native-proxy-release-call-readback-join-20260912'


def load(path):
    return json.loads(path.read_bytes())


def module(name, path):
    spec = importlib.util.spec_from_file_location(name, path)
    value = importlib.util.module_from_spec(spec); spec.loader.exec_module(value)
    return value


def pin(path):
    assert path.is_relative_to(ROOT)
    for node in [path, *path.parents]:
        if node == ROOT: break
        assert not node.is_symlink() and node.stat().st_dev == ROOT.stat().st_dev
    assert path.is_file()
    raw = path.read_bytes()
    return dict(path=str(path.relative_to(ROOT)), size_bytes=len(raw), sha256=hashlib.sha256(raw).hexdigest())


def build():
    selection = load(SELECTION / 'plan.json')
    prior_prepare = module('ordinary_close_selection_prepare', SELECTION / 'prepare.py')
    assert prior_prepare.build() == selection
    prior_audit = module('ordinary_close_selection_audit', SELECTION / 'audit.py')
    model = module('ordinary_close_selection_model', SELECTION / 'model.py')
    boundary_audit = module('ordinary_close_boundary_audit', BOUNDARY / 'audit.py')
    original = load(BOUNDARY / 'plan.json'); saved = load(BOUNDARY / 'result/qualification.json')
    boundary_audit.authenticate(original); boundary_audit.verify(original, saved)
    chosen = selection['profiles'][0]
    assert chosen['id'] == 'ordinary_retired_other_observation'
    joined = load(JOIN / 'result/join.json'); assert joined['success'] is True
    previous = [str((BOUNDARY / 'result/qualification.json').relative_to(ROOT))]
    previous.extend(p['directory'] + '/result/qualification.json' for p in joined['partitions'])
    assert len(previous) == len(set(previous)) == 14
    paths = {r['path'] for r in selection['inputs']} | set(previous)
    prefix = str(SELECTION.relative_to(ROOT)) + '/'
    tracked = subprocess.check_output(['git', 'ls-tree', '-r', '--name-only', REVISION], cwd=ROOT, text=True).splitlines()
    paths.update(p for p in tracked if p.startswith(prefix))
    paths.update(str((CALLS / n).relative_to(ROOT)) for n in ('CallPlan.pm', 'CallFaultTrace.pm', 'audit.py'))
    inputs = []
    for relative in sorted(paths):
        path = ROOT / relative; raw = path.read_bytes()
        assert raw == subprocess.check_output(['git', 'show', REVISION + ':' + relative], cwd=ROOT)
        inputs.append(pin(path))
    alternate_audit = module('ordinary_close_order_inputs', CALL_SELECTION / 'audit.py')
    vectors = []
    for profile, baseline, row in zip(selection['profiles'], original['profiles'], saved['cases'], strict=True):
        spec, _ = boundary_audit.OLD.setup(row)
        calls = boundary_audit.FLOW.derive(row['context'], row['operation']['before'], spec)
        reports = [c['reports'][0] for c in profile['cases'][1:]]
        assert model.resolve(calls, row['context'], reports) == prior_audit.ownership(calls, row['context'])
        count = sum(p.startswith('references/') for p in row['operation']['before']['store'])
        variants = [dict(name='baseline', calls=calls)]
        for order in itertools.permutations(range(count)):
            variants.append(dict(name='order:' + ','.join(map(str, order)),
                calls=alternate_audit.alternate_flow(row, spec, order)))
        vectors.append(dict(profile=profile['id'], context=row['context'], reports=reports,
            variants=[dict(name=v['name'], calls=v['calls'], expected=prior_audit.ownership(v['calls'], row['context'])) for v in variants]))
    plan = dict(schema='fsmgen.release_ordinary_close_plan.v1', owner=chosen['owner'], source_revision=REVISION,
        component=BASE.name, profile_id=chosen['id'], selection=chosen['selection'], cases=chosen['cases'],
        source_boundaries=original['source_boundaries'], sealed_symbols=list(original['sealed_continuations']),
        inputs=inputs, previous_root_reports=previous, report_contract=selection['report_contract'],
        publication='Publish each complete case as immutable bytes only after its exact roots are absent. Preserve one in-flight body, exact admission records and prospective binding before release.',
        scope='Ordinary healthy control and every pinned ordinary single EIO close report. Each report follows an actual successful close and observed native closure. Pure cross-profile/order binding supports the shared helper only. No other-profile file fixture, grouped or primary-error composition, omission, original producer/main or native process.')
    return plan, dict(schema='fsmgen.release_close_binding_vectors.v1', profiles=vectors,
        scope='Pure input-flow and single-selector binding; synthetic orders do not allocate files or execute close controls.')


if __name__ == '__main__':
    plan, vectors = build()
    for name, value in [('plan.json', plan), ('flow-vectors.json', vectors)]:
        with (BASE / name).open('x') as output: output.write(json.dumps(value, sort_keys=True, indent=2) + '\n')
    print(json.dumps(dict(success=True, inputs=len(plan['inputs']), cases=len(plan['cases']),
        baseline_profiles=len(vectors['profiles']), pure_variants=sum(len(p['variants']) for p in vectors['profiles'])), sort_keys=True))
