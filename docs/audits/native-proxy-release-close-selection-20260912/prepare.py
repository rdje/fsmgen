"""Pin prospective single-close selection without creating a file fixture."""
import hashlib
import importlib.util
import json
from pathlib import Path
import subprocess

BASE = Path(__file__).resolve().parent
ROOT = BASE.parents[2]
REVISION = 'fccfa04cb74f4604582aa3d5cb788d5ccd0a054e'
OWNER = 'HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.3.1.2.2.5.5.2.3.1.2.2.3.2.15.7.3.12.4.1.3.4.4.4.1'
BOUNDARY = BASE.parent / 'native-proxy-observation-archive-release-boundaries-20260911'
CALL_SELECTION = BASE.parent / 'native-proxy-release-call-selection-20260911'
BEFORE = BASE.parent / 'native-proxy-observation-archive-release-ordinary-before-20260911'
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


def input_paths():
    tracked = subprocess.check_output(['git', 'ls-tree', '-r', '--name-only', REVISION], cwd=ROOT, text=True).splitlines()
    paths = {p['path'] for p in load(BOUNDARY / 'plan.json')['inputs']}
    for directory in (BOUNDARY, CALL_SELECTION):
        prefix = str(directory.relative_to(ROOT)) + '/'
        paths.update(p for p in tracked if p.startswith(prefix))
    paths.add(str((BEFORE / 'expected_trace.py').relative_to(ROOT)))
    paths.update(str((JOIN / n).relative_to(ROOT)) for n in ('result/join.json', 'preflight-pins.json'))
    return sorted(paths)


def build():
    assert load(BASE / 'source-pins.json') == [pin(BASE / n) for n in ('prepare.py', 'model.py', 'audit.py')]
    inputs = []
    for relative in input_paths():
        path = ROOT / relative
        raw = path.read_bytes()
        assert raw == subprocess.check_output(['git', 'show', REVISION + ':' + relative], cwd=ROOT)
        inputs.append(pin(path))
    prior = module('close_selection_boundary_prepare', BOUNDARY / 'audit.py')
    original = load(BOUNDARY / 'plan.json'); saved = load(BOUNDARY / 'result/qualification.json')
    prior.authenticate(original); prior.verify(original, saved)
    model = module('close_selection_event_model', BASE / 'model.py')
    profiles = []
    for profile, row in zip(original['profiles'], saved['cases'], strict=True):
        assert profile['id'] == row['profile_id']
        selected = model.select(row)
        profiles.append(dict(id=profile['id'], selection=profile['selection'],
            owner=OWNER.rsplit('.', 1)[0] + '.' + str(len(profiles) + 2),
            selectors=selected, cases=model.cases(selected)))
    return dict(schema='fsmgen.release_close_selection.v1', owner=OWNER, source_revision=REVISION,
        inputs=inputs, profiles=profiles,
        binding='Resolve kind, opening symbol and zero-based occurrence from the current physical-input flow. Baseline handles, paths, call IDs and close scopes are archival provenance only. Current source scopes determine expected error and unwind; changing reference order can change those bindings.',
        report_contract=dict(errno='EIO', actual_close_first=True, require_actual_success=True,
            require_native_closed=True, modeled_return=0, preserve_unexpected_actual_failure=True,
            operating_system_close_failure_claim=False),
        coverage='One healthy control and one single EIO report for every normal retained source, directory and lock close in each declared profile. This is prospective selection, not executed fault qualification.',
        later=dict(primary_and_grouped=OWNER.rsplit('.', 1)[0] + '.6',
            report_join=OWNER.rsplit('.', 1)[0] + '.7',
            omissions=OWNER.rsplit('.', 2)[0] + '.5'),
        scope='Pure saved-evidence selection and current-flow binding. No new fixture root, close control, original producer/main, native process or operating-system close ambiguity experiment.')


if __name__ == '__main__':
    plan = build()
    with (BASE / 'plan.json').open('x') as output:
        output.write(json.dumps(plan, sort_keys=True, indent=2) + '\n')
    print(json.dumps(dict(success=True, inputs=len(plan['inputs']),
        selectors=[len(p['selectors']) for p in plan['profiles']],
        proposed_cases=[len(p['cases']) for p in plan['profiles']]), sort_keys=True))
