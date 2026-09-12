"""Authenticate predecessors and pin finite release composition recipes."""
import hashlib
import importlib.util
import json
from pathlib import Path
import subprocess

BASE = Path(__file__).resolve().parent
ROOT = BASE.parents[2]
LOG = ROOT / '.artifacts/logs' / BASE.name
REVISION = '49a4d1f50cec77149eeadf799501d0ee33447f12'
OWNER = 'HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.3.1.2.2.5.5.2.3.1.2.2.3.2.15.7.3.12.4.1.3.4.4.4.6.1'
PREVIOUS = BASE.with_name('native-proxy-observation-archive-release-close-last-20260912')
BOUNDARY = BASE.with_name('native-proxy-observation-archive-release-boundaries-20260911')
SELECTION = BASE.with_name('native-proxy-release-close-selection-20260912')
CALLS = BASE.with_name('native-proxy-observation-archive-release-ordinary-before-20260911')
ORDINARY = BASE.with_name('native-proxy-observation-archive-release-close-ordinary-20260912')


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


def inputs():
    old = load(PREVIOUS / 'plan.json')
    paths = {p['path'] for p in old['inputs']}
    paths.update(p['path'] for p in load(PREVIOUS / 'preflight-pins.json'))
    paths.update(str((PREVIOUS / n).relative_to(ROOT)) for n in
                 ('plan.json', 'preflight-pins.json', 'result/qualification.json',
                  'result/audit.json', 'result/recovery-copies.json'))
    reports = old['previous_root_reports'] + [str((PREVIOUS / 'result/qualification.json').relative_to(ROOT))]
    paths.update(reports)
    result = []
    for relative in sorted(paths):
        path = ROOT / relative
        assert path.read_bytes() == subprocess.check_output(['git', 'show', REVISION + ':' + relative], cwd=ROOT)
        result.append(pin(path))
    return result, reports


def build():
    assert load(BASE / 'source-pins.json') == [pin(BASE / n) for n in ('prepare.py', 'model.py', 'audit.py')]
    admitted, reports = inputs()
    prior = module('composition_boundary', BOUNDARY / 'audit.py')
    original = load(BOUNDARY / 'plan.json'); saved = load(BOUNDARY / 'result/qualification.json')
    prior.authenticate(original); prior.verify(original, saved)
    source = module('composition_healthy_scope', CALLS / 'expected_trace.py')
    selection = module('composition_scope_bindings', SELECTION / 'audit.py')
    model = module('composition_event_selector', BASE / 'model.py')
    profiles = []
    for index, row in enumerate(saved['cases']):
        spec, _ = prior.OLD.setup(row)
        calls = prior.FLOW.derive(row['context'], row['operation']['before'], spec)
        healthy = source.derive(calls, row['context'], original['sealed_continuations'], None)
        bindings = selection.ownership(calls, row['context'])
        cases = [dict(index=i, recipe=r, baseline=model.resolve(calls, healthy, bindings, r))
                 for i, r in enumerate(model.recipes())]
        profiles.append(dict(id=row['profile_id'], selection=original['profiles'][index]['selection'],
            owner=OWNER.rsplit('.', 1)[0] + '.' + str(index + 2), cases=cases))
    return dict(schema='fsmgen.release_close_composition_selection.v1', owner=OWNER,
        source_revision=REVISION, inputs=admitted, previous_root_reports=reports,
        source_boundaries=load(PREVIOUS / 'plan.json')['source_boundaries'],
        sealed_symbols=list(original['sealed_continuations']), profiles=profiles,
        binding='Reapply the closed recipe to each current-input healthy flow and independently derived owner bindings. Baseline addresses, paths, labels and numeric calls are witnesses, never execution targets.',
        report_contract=dict(actual_close_first=True, require_actual_success=True, require_native_closed=True,
            preserve_actual_failure=True, errno_values=['EIO', 'ENOSPC'], order_pairs=['observed', 'reversed'],
            primary_wins=True, otherwise_first_actual_close_wins=True, all_actual_owners_close=True),
        directory_contract=dict(actual_scalar_readdir_first=True, require_actual_defined_entry=True,
            require_actual_errno_zero=True, reported_value=None, reported_errno='EIO',
            record_actual_name_and_errno=True, one_hit=True, preserve_unexpected_actual_failure=True,
            caller_scopes=list(model.DIRECTORY_SCOPES)),
        coverage='One healthy control, one grouped first-error recipe for each cleanup scope, source-recheck primaries for each source owner, directory-read primaries and three release milestones, with observed/reversed declarations. Finite representative composition coverage; no all-pairs or Cartesian claim.',
        scope='Saved-evidence planning and pure input-order controls only. No new file fixture, close/read control, previous producer/main or native process. Actual compositions, single/report join, genuine omissions, final release, native/lifetime and historical startup/parent/full CI/push remain separately gated.')


if __name__ == '__main__':
    plan = build()
    with (BASE / 'plan.json').open('x') as stream:
        stream.write(json.dumps(plan, indent=2, sort_keys=True) + '\n')
    print(json.dumps(dict(success=True, inputs=len(plan['inputs']),
        proposed_cases=[len(p['cases']) for p in plan['profiles']]), sort_keys=True))
