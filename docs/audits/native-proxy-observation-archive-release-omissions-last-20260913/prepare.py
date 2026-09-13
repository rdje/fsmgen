"""Bind the last-observation omission partition and qualified ordinary dependencies."""
import hashlib
import importlib.util
import json
from pathlib import Path
import subprocess

BASE = Path(__file__).resolve().parent
ROOT = BASE.parents[2]
REVISION = '8d872f2c05d21cffbfe29c0bfafcaedb30c18211'
OWNER = 'HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.3.1.2.2.5.5.2.3.1.2.2.3.2.15.7.3.12.4.1.3.4.4.5.5'
SELECTION = BASE.with_name('native-proxy-release-omission-selection-20260913')
ORDINARY = BASE.with_name('native-proxy-observation-archive-release-omissions-ordinary-20260913')
PREVIOUS = BASE.with_name('native-proxy-observation-archive-release-omissions-active-20260913')
LAST = BASE.with_name('native-proxy-observation-archive-release-readback-last-20260912')
PURE_NAMES = ['prepare.py']


def module(name, path):
    spec = importlib.util.spec_from_file_location(name, path)
    value = importlib.util.module_from_spec(spec); spec.loader.exec_module(value)
    return value


def load(path):
    return json.loads(path.read_bytes())


def safe_bytes(path):
    assert path.is_relative_to(ROOT)
    for node in [path, *path.parents]:
        if node == ROOT:
            break
        assert not node.is_symlink() and node.stat().st_dev == ROOT.stat().st_dev
    assert path.is_file()
    return path.read_bytes()


def pin(path):
    raw = safe_bytes(path)
    return dict(path=str(path.relative_to(ROOT)), size_bytes=len(raw), sha256=hashlib.sha256(raw).hexdigest())


def tree(revision=REVISION):
    assert subprocess.check_output(['git', 'rev-parse', '--show-object-format'], cwd=ROOT).strip() == b'sha1'
    rows = subprocess.check_output(['git', 'ls-tree', '-r', '-z', revision], cwd=ROOT).split(b'\0')
    result = {}
    for row in rows:
        if not row:
            continue
        metadata, name = row.split(b'\t', 1)
        mode, kind, oid = metadata.split()
        result[name.decode()] = dict(mode=mode.decode(), kind=kind.decode(), oid=oid.decode())
    return result



def build():
    assert load(BASE / 'source-pins.json') == [pin(BASE / n) for n in PURE_NAMES]
    selection = load(SELECTION / 'plan.json')
    assert load(SELECTION / 'result/audit.json')['success'] is True
    previous_plan = load(PREVIOUS / 'plan.json')
    version = tree(); paths = {r['path'] for r in previous_plan['inputs']}
    prefix = str(PREVIOUS.relative_to(ROOT)) + '/'
    paths.update(path for path in version if path.startswith(prefix))
    inputs = []
    for relative in sorted(paths):
        info = version[relative]; assert info['kind'] == 'blob' and info['mode'] in ('100644', '100755')
        raw = safe_bytes(ROOT / relative)
        oid = hashlib.sha1(b'blob ' + str(len(raw)).encode() + b'\0' + raw).hexdigest()
        assert oid == info['oid'], relative
        inputs.append(dict(path=relative, size_bytes=len(raw), sha256=hashlib.sha256(raw).hexdigest(), git_blob=oid))
    chosen = selection['profiles'][3]
    assert chosen['owner'] == OWNER and chosen['id'] == 'ordinary_retired_last_observation'
    assert str((LAST / 'audit.py').relative_to(ROOT)) in paths
    previous = previous_plan['previous_root_reports'] + [str((PREVIOUS / 'result/qualification.json').relative_to(ROOT))]
    assert len(previous) == len(set(previous))
    return dict(schema='fsmgen.release_last_omission_plan.v1', owner=OWNER, source_revision=REVISION,
        component=BASE.name, profile_id=chosen['id'], selection=chosen['selection'], cases=chosen['cases'],
        source_boundaries=selection['source_boundaries'], sealed_symbols=selection['sealed_symbols'], inputs=inputs,
        previous_root_reports=previous,
        omission_contract=selection['omission_contract'], observation_contract=selection['observation_contract'],
        recovery_contract=selection['recovery_contract'],
        publication='Retain original verdict and exact native liveness before separate recovery. Complete recovery before root cleanup, then publish each immutable case exclusively. Stop and retain the first failed case.',
        scope='Last-observation healthy control and selected representative source, directory and lock omissions. '
              'Original controlled setup retires the runtime and removes the distinct other hold before release. '
              'Actual release removes the final hold while preserving the exact now-unreferenced canonical '
              'image. Original open-handle verdict and exact later recovery remain separate. No prior fixture '
              'replay, original producer/main, compiler, native fixture process or collector; final release and '
              'historical startup/parent/full CI/push remain gated.')


if __name__ == '__main__':
    plan = build()
    with (BASE / 'plan.json').open('x') as stream:
        stream.write(json.dumps(plan, sort_keys=True, indent=2) + '\n')
    print(json.dumps(dict(success=True, input_files=len(plan['inputs']), input_bytes=sum(p['size_bytes'] for p in plan['inputs']),
        selected_cases=len(plan['cases'])), sort_keys=True))
