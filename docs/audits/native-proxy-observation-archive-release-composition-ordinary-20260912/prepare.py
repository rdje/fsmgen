"""Admit the ordinary composition partition and pure cross-profile vectors."""
import copy
import hashlib
import importlib.util
import itertools
import json
from pathlib import Path
import subprocess

BASE = Path(__file__).resolve().parent
ROOT = BASE.parents[2]
LOG = ROOT / '.artifacts/logs' / BASE.name
REVISION = '83b32c80721c2ce76c42b426b274ec72761b360c'
OWNER = 'HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.3.1.2.2.5.5.2.3.1.2.2.3.2.15.7.3.12.4.1.3.4.4.4.6.2'
SELECTION = BASE.with_name('native-proxy-release-close-composition-selection-20260912')
ORDINARY = BASE.with_name('native-proxy-observation-archive-release-close-ordinary-20260912')
BOUNDARY = BASE.with_name('native-proxy-observation-archive-release-boundaries-20260911')
CALLS = BASE.with_name('native-proxy-observation-archive-release-ordinary-before-20260911')


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


SELECTION_AUDIT = module('ordinary_composition_committed_selection', SELECTION / 'audit.py')


def resolve(calls, context, sealed, recipe):
    """Independent prospective value, using the committed interval oracle."""
    selection = SELECTION_AUDIT
    bindings = selection.OWNERS.ownership(calls, context)
    witness = selection.reference(calls, context, sealed, bindings, recipe)
    by_address = {b['address']: b for b in bindings}
    reports = [dict(by_address[r['address']], errno=r['errno']) for r in witness['reports']]
    primary = copy.deepcopy(witness['primary'])
    if primary is not None:
        if primary['kind'] == 'call':
            candidates = [c for c in calls if c['name'] == primary['symbol']]
            primary['call_id'] = candidates[primary['occurrence']]['id']
        else:
            primary['binding'] = copy.deepcopy(by_address[primary['address']])
    return dict(witness=witness, resolved_reports=reports, resolved_primary=primary)


def build():
    assert load(BASE / 'prepare-pin.json') == pin(BASE / 'prepare.py')
    prior = load(SELECTION / 'plan.json')
    paths = {p['path'] for p in prior['inputs']}
    prefix = str(SELECTION.relative_to(ROOT)) + '/'
    paths.update(p for p in subprocess.check_output(
        ['git', 'ls-tree', '-r', '--name-only', REVISION, '--', str(SELECTION.relative_to(ROOT))],
        cwd=ROOT, text=True).splitlines() if p.startswith(prefix))
    inputs = []
    for relative in sorted(paths):
        path = ROOT / relative
        assert path.read_bytes() == subprocess.check_output(['git', 'show', REVISION + ':' + relative], cwd=ROOT)
        inputs.append(pin(path))
    old_prepare = module('ordinary_composition_selection_prepare', SELECTION / 'prepare.py')
    assert old_prepare.build() == prior
    assert load(SELECTION / 'result/audit.json')['success'] is True
    selected = prior['profiles'][0]
    assert selected['owner'] == OWNER and selected['id'] == 'ordinary_retired_other_observation'
    cases = [dict(index=c['index'], name=':'.join(str(c['recipe'][k]) for k in ('kind', 'scope', 'order')),
                  recipe=c['recipe']) for c in selected['cases']]
    plan = dict(schema='fsmgen.release_ordinary_composition_plan.v1', owner=OWNER, source_revision=REVISION,
        component=BASE.name, profile_id=selected['id'], selection=selected['selection'], cases=cases,
        inputs=inputs, previous_root_reports=prior['previous_root_reports'],
        source_boundaries=prior['source_boundaries'], sealed_symbols=prior['sealed_symbols'],
        report_contract=prior['report_contract'], directory_contract=prior['directory_contract'],
        scope='Ordinary inert file-fixture composition partition only. Pure source binding and oracle vectors '
              'cover committed profiles without their file fixtures. Actual close/read truth and reports remain '
              'separate; no prior fixture/main, compiler or native process is replayed.')
    audit = SELECTION_AUDIT
    baseline = load(BOUNDARY / 'result/qualification.json')
    profiles = []
    for profile, row in zip(prior['profiles'], baseline['cases'], strict=True):
        spec, _ = audit.BOUNDARY.OLD.setup(row)
        calls = audit.BOUNDARY.FLOW.derive(row['context'], row['operation']['before'], spec)
        variants = [('baseline', calls)]
        names = [p for p in row['operation']['before']['store'] if p.startswith('references/')]
        variants.extend(('order:' + ','.join(map(str, order)), audit.ALTERNATE.alternate_flow(row, spec, order))
                        for order in itertools.permutations(range(len(names))))
        recipes = [c['recipe'] for c in profile['cases']]
        profiles.append(dict(profile=profile['id'], context=row['context'], recipes=recipes,
            variants=[dict(name=name, calls=flow, expected=[resolve(flow, row['context'], prior['sealed_symbols'], r)
                for r in recipes]) for name, flow in variants]))
    return plan, dict(profiles=profiles)


if __name__ == '__main__':
    plan, vectors = build()
    for name, value in [('plan.json', plan), ('flow-vectors.json', vectors)]:
        with (BASE / name).open('x') as stream:
            stream.write(json.dumps(value, sort_keys=True, indent=2) + '\n')
    print(json.dumps(dict(success=True, inputs=len(plan['inputs']), cases=len(plan['cases']),
        pure_variants=sum(len(p['variants']) for p in vectors['profiles'])), sort_keys=True))
