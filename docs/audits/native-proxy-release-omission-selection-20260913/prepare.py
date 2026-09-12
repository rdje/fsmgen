"""Pin genuine omission recipes and explicit original-verdict/recovery stages."""
import hashlib
import importlib.util
import json
from pathlib import Path
import subprocess

BASE = Path(__file__).resolve().parent
ROOT = BASE.parents[2]
REVISION = 'b31f942cd6e8d7407594b8ed4a8a9a1d87f2ae67'
OWNER = 'HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.3.1.2.2.5.5.2.3.1.2.2.3.2.15.7.3.12.4.1.3.4.4.5.1'
JOIN = BASE.with_name('native-proxy-release-close-join-20260913')
BOUNDARY = BASE.with_name('native-proxy-observation-archive-release-boundaries-20260911')
SELECTION = BASE.with_name('native-proxy-release-close-selection-20260912')
TRACE = BASE.with_name('native-proxy-observation-archive-release-20260911') / 'ReleaseTrace.pm'


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


def input_paths(version):
    paths = {r['path'] for r in load(JOIN / 'plan.json')['inputs']}
    prefix = str(JOIN.relative_to(ROOT)) + '/'
    paths.update(path for path in version if path.startswith(prefix))
    paths.add(str(TRACE.relative_to(ROOT)))
    return sorted(paths)


def build():
    assert load(BASE / 'source-pins.json') == [pin(BASE / n) for n in ('prepare.py', 'model.py', 'audit.py')]
    version = tree(REVISION); inputs = []
    for relative in input_paths(version):
        info = version[relative]
        assert info['kind'] == 'blob' and info['mode'] in ('100644', '100755')
        raw = safe_bytes(ROOT / relative)
        oid = hashlib.sha1(b'blob ' + str(len(raw)).encode() + b'\0' + raw).hexdigest()
        assert oid == info['oid'], relative
        inputs.append(dict(path=relative, size_bytes=len(raw), sha256=hashlib.sha256(raw).hexdigest(), git_blob=oid))
    prior = load(JOIN / 'result/join.json'); assert prior['success'] is True
    original = load(BOUNDARY / 'plan.json'); saved = load(BOUNDARY / 'result/qualification.json')
    model = module('omission_event_selection', BASE / 'model.py')
    profiles = []
    for index, (profile, row) in enumerate(zip(original['profiles'], saved['cases'], strict=True)):
        assert row['profile_id'] == profile['id'] and row['selection'] == profile['selection']
        profiles.append(dict(id=profile['id'], selection=profile['selection'],
            owner=OWNER.rsplit('.', 1)[0] + '.' + str(index + 2), cases=model.select(row)))
    previous = load(ROOT / prior['partitions'][0]['directory'] / 'plan.json')['previous_root_reports']
    previous = previous + [p['directory'] + '/result/qualification.json' for p in prior['partitions']]
    assert len(previous) == len(set(previous))
    return dict(schema='fsmgen.release_omission_selection.v1', owner=OWNER, source_revision=REVISION,
        inputs=inputs, profiles=profiles, previous_root_reports=previous,
        source_boundaries=original['source_boundaries'], sealed_symbols=list(original['sealed_continuations']),
        binding='Recompute the first normal close in the declared source cleanup scope from each current healthy flow. '
                'Scope and handle kind are portable selectors; baseline addresses, labels, paths and event/call numbers '
                'are historical witnesses and must never be copied as current targets.',
        omission_contract=dict(one_selected_handle=True, retain_exact_object=True, actual_close_executed=False,
            reported_return=1, reported_errno=0, mark_actual_success=False, preserve_real_unselected_closes=True,
            original_observer_closed=False, expected_public_success=True, preserve_healthy_effects=True),
        observation_contract=dict(original_verdict_first=True, alias_survives_observe_return=True,
            require_original_native_identity=True, require_native_open_after_return=True,
            source_and_lock_probe=['fileno', 'fstat', 'fcntl'], directory_probe=['fileno', 'duplicate_fstat', 'close_probe'],
            observer_duplicates_close=True, preserve_original_trace=True, original_auditor_must_reject=True),
        recovery_contract=dict(only_after_original_verdict_and_liveness=True, exact_original_object=True,
            selected_object_closes_once=True, source_and_lock_primitive='CORE::close', directory_primitive='CORE::closedir',
            preserve_actual_return_errno=True, require_native_closed=True, separate_receipt=True,
            recovery_is_implementation_closure=False, no_root_cleanup_before_recovery=True),
        retention_boundary='Strong retained aliases deliberately extend the selected counterimplementation lifetime. '
            'This does not infer ordinary lexical cleanup behavior without that retention. The original observer '
            'already holds handles through its snapshot but removes them from returned records; the omission '
            'counterimplementation must retain its selected object through later liveness and recovery.',
        coverage='One healthy control and one representative omission for every original source, directory and lock '
            'cleanup scope in each profile. This is prospective selection; all-occurrence, error-composition and '
            'operating-system close-failure claims are excluded.',
        execution_gate='Ordinary execution first qualifies current-input binding and pure order variations; equal, '
            'active and last profiles execute under their own leaves. A separate join must preserve original failed '
            'verdicts and prove complete selected coverage before closing genuine omission qualification.',
        scope='Pure retained-evidence selection and observer protocol only. No new fixture, omitted close, original '
            'producer/main, compiler, native process or collector. Actual omissions, final release applicability, '
            'native/lifetime and historical startup/parent/full CI/push remain separately gated.')


if __name__ == '__main__':
    plan = build()
    with (BASE / 'plan.json').open('x') as stream:
        stream.write(json.dumps(plan, sort_keys=True, indent=2) + '\n')
    print(json.dumps(dict(success=True, inputs=len(plan['inputs']), input_bytes=sum(r['size_bytes'] for r in plan['inputs']),
        proposed_cases=[len(p['cases']) for p in plan['profiles']], new_fixture_roots=0), sort_keys=True))
