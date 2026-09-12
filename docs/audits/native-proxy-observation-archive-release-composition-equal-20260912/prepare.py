"""Admit equal-reference compositions and their unchanged qualified dependencies."""
import hashlib
import json
from pathlib import Path
import subprocess

BASE = Path(__file__).resolve().parent
ROOT = BASE.parents[2]
REVISION = 'c89aef75c494e7216b31d20ff441bcd7e7f20cf0'
OWNER = 'HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.3.1.2.2.5.5.2.3.1.2.2.3.2.15.7.3.12.4.1.3.4.4.4.6.3'
ORDINARY = BASE.with_name('native-proxy-observation-archive-release-composition-ordinary-20260912')
SELECTION = BASE.with_name('native-proxy-release-close-composition-selection-20260912')
BOUNDARY = BASE.with_name('native-proxy-observation-archive-release-boundaries-20260911')
EQUAL = BASE.with_name('native-proxy-observation-archive-release-readback-equal-20260912')


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
    old = load(ORDINARY / 'plan.json')
    paths = {p['path'] for p in old['inputs']}
    paths.update(subprocess.check_output(['git', 'ls-tree', '-r', '--name-only', REVISION,
        '--', str(ORDINARY.relative_to(ROOT))], cwd=ROOT, text=True).splitlines())
    paths.add(str((EQUAL / 'audit.py').relative_to(ROOT)))
    previous = old['previous_root_reports'] + [str((ORDINARY / 'result/qualification.json').relative_to(ROOT))]
    assert len(previous) == len(set(previous))
    paths.update(previous)
    inputs = []
    for relative in sorted(paths):
        path = ROOT / relative
        assert path.read_bytes() == subprocess.check_output(['git', 'show', REVISION + ':' + relative], cwd=ROOT)
        inputs.append(pin(path))
    prior = load(SELECTION / 'plan.json'); selected = prior['profiles'][1]
    assert selected['owner'] == OWNER and selected['id'] == 'equal_reference_retired_other_observation'
    assert load(ORDINARY / 'result/audit.json')['success'] is True
    assert load(ORDINARY / 'result/qualification.json')['success'] is True
    cases = [dict(index=c['index'], name=':'.join(str(c['recipe'][k]) for k in ('kind', 'scope', 'order')),
                  recipe=c['recipe']) for c in selected['cases']]
    return dict(schema='fsmgen.release_equal_composition_plan.v1', owner=OWNER, source_revision=REVISION,
        component=BASE.name, profile_id=selected['id'], selection=selected['selection'], cases=cases,
        inputs=inputs, previous_root_reports=previous,
        source_boundaries=prior['source_boundaries'], sealed_symbols=prior['sealed_symbols'],
        report_contract=prior['report_contract'], directory_contract=prior['directory_contract'],
        scope='Equal-reference inert file-fixture compositions only. Qualified pure binding, real-close-first '
              'reporting, directory-read reporting and independent trace oracles remain unchanged. Equal source '
              'bytes retain distinct native identities and share an independently identified archive copy. '
              'No ordinary fixture, other-profile fixture, prior producer/main, compiler or native process is replayed.')


if __name__ == '__main__':
    plan = build()
    with (BASE / 'plan.json').open('x') as stream:
        stream.write(json.dumps(plan, sort_keys=True, indent=2) + '\n')
    print(json.dumps(dict(success=True, inputs=len(plan['inputs']), cases=len(plan['cases'])), sort_keys=True))
