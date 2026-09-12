"""Admit the last-observation close domain and unchanged qualified dependencies."""
import hashlib
import json
from pathlib import Path
import subprocess

BASE = Path(__file__).resolve().parent
ROOT = BASE.parents[2]
REVISION = '85cc24eeb184f6197f72a8275ff55f8c5f59d112'
ORDINARY = BASE.with_name('native-proxy-observation-archive-release-close-ordinary-20260912')
SELECTION = BASE.with_name('native-proxy-release-close-selection-20260912')
BOUNDARY = BASE.with_name('native-proxy-observation-archive-release-boundaries-20260911')
PREVIOUS = BASE.with_name('native-proxy-observation-archive-release-close-active-20260912')
LAST = BASE.with_name('native-proxy-observation-archive-release-readback-last-20260912')
OWNER = 'HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.3.1.2.2.5.5.2.3.1.2.2.3.2.15.7.3.12.4.1.3.4.4.4.5'


def load(path):
    return json.loads(path.read_bytes())


def pin(path):
    assert path.is_relative_to(ROOT)
    for node in [path, *path.parents]:
        if node == ROOT: break
        assert not node.is_symlink() and node.stat().st_dev == ROOT.stat().st_dev
    assert path.is_file()
    raw = path.read_bytes()
    return dict(path=str(path.relative_to(ROOT)), size_bytes=len(raw), sha256=hashlib.sha256(raw).hexdigest())


def build():
    assert load(BASE / 'prepare-pin.json') == pin(BASE / 'prepare.py')
    old = load(PREVIOUS / 'plan.json')
    paths = {p['path'] for p in old['inputs']}
    paths.update(p['path'] for p in load(PREVIOUS / 'preflight-pins.json'))
    paths.update(str((PREVIOUS / n).relative_to(ROOT)) for n in (
        'plan.json', 'preflight-pins.json', 'result/qualification.json', 'result/audit.json',
        'result/recovery-copies.json'))
    paths.update(str((LAST / n).relative_to(ROOT)) for n in ('audit.py', 'qualify.t'))
    previous = old['previous_root_reports'] + [str((PREVIOUS / 'result/qualification.json').relative_to(ROOT))]
    assert len(previous) == len(set(previous)) == 17
    paths.update(previous)
    inputs = []
    for relative in sorted(paths):
        path = ROOT / relative
        assert path.read_bytes() == subprocess.check_output(['git', 'show', REVISION + ':' + relative], cwd=ROOT)
        inputs.append(pin(path))
    chosen = load(SELECTION / 'plan.json')['profiles'][3]
    assert chosen['id'] == 'ordinary_retired_last_observation' and chosen['owner'] == OWNER
    assert load(PREVIOUS / 'result/audit.json')['success'] is True
    assert load(PREVIOUS / 'result/qualification.json')['success'] is True
    return dict(schema='fsmgen.release_last_close_plan.v1', owner=OWNER, source_revision=REVISION,
        component=BASE.name, profile_id=chosen['id'], selection=chosen['selection'], cases=chosen['cases'],
        source_boundaries=old['source_boundaries'], sealed_symbols=old['sealed_symbols'],
        report_contract=old['report_contract'], publication=old['publication'],
        inputs=inputs, previous_root_reports=previous,
        scope='Last-observation healthy control and every pinned single EIO close report. Original controlled '
              'setup retires the target runtime and removes the distinct other hold before observed release. '
              'The final hold is removed only when release reaches its real unlink; the canonical image '
              'remains exact even when unreferenced. No prior fixture replay, other-profile file fixture, '
              'grouped/primary-error composition, omission, original producer/main or native process.')


if __name__ == '__main__':
    plan = build()
    with (BASE / 'plan.json').open('x') as output:
        output.write(json.dumps(plan, sort_keys=True, indent=2) + '\n')
    print(json.dumps(dict(success=True, inputs=len(plan['inputs']), cases=len(plan['cases'])), sort_keys=True))
