"""Independently qualify omission selection without executing an omitted close."""
from collections import Counter
import copy
import importlib.util
import json
from pathlib import Path
import sys

BASE = Path(__file__).resolve().parent
ROOT = BASE.parents[2]
LOG = ROOT / '.artifacts/logs' / BASE.name


def module(name, path):
    spec = importlib.util.spec_from_file_location(name, path)
    value = importlib.util.module_from_spec(spec); spec.loader.exec_module(value)
    return value


def load(path):
    return json.loads(path.read_bytes())


def rejects(action):
    try:
        action()
    except (AssertionError, KeyError, TypeError, ValueError, IndexError):
        return True
    return False


def expected_cases(selectors):
    """Select by scope-owned closing positions, independently of the event stack."""
    scopes = sorted({s['baseline_close_scope'] for s in selectors})
    cases = [dict(index=0, name='healthy', recipe=dict(kind='healthy', scope=None, handle_kind=None), baseline=None)]
    for scope in scopes:
        selected = min((s for s in selectors if s['baseline_close_scope'] == scope), key=lambda s: s['baseline_close_event'])
        cases.append(dict(index=len(cases), name='omit:' + scope,
            recipe=dict(kind='omit', scope=scope, handle_kind=selected['kind']), baseline=selected))
    return cases


def domain(profile, original, cases, owner):
    assert set(profile) == {'id', 'selection', 'owner', 'cases'}
    assert profile['id'] == original['id'] and profile['selection'] == original['selection']
    assert profile['owner'] == owner and profile['cases'] == cases
    assert [case['index'] for case in profile['cases']] == list(range(len(cases)))
    assert all(type(case['index']) is int for case in profile['cases'])
    assert len({case['name'] for case in cases}) == len(cases)
    assert {case['recipe']['handle_kind'] for case in cases[1:]} == {'source', 'directory', 'lock'}


def protocol(plan):
    assert plan['omission_contract'] == dict(one_selected_handle=True, retain_exact_object=True,
        actual_close_executed=False, reported_return=1, reported_errno=0, mark_actual_success=False,
        preserve_real_unselected_closes=True, original_observer_closed=False,
        expected_public_success=True, preserve_healthy_effects=True)
    assert type(plan['omission_contract']['reported_return']) is int
    assert type(plan['omission_contract']['reported_errno']) is int
    assert all(type(value) is bool for key, value in plan['omission_contract'].items()
               if key not in ('reported_return', 'reported_errno'))
    assert plan['observation_contract'] == dict(original_verdict_first=True, alias_survives_observe_return=True,
        require_original_native_identity=True, require_native_open_after_return=True,
        source_and_lock_probe=['fileno', 'fstat', 'fcntl'],
        directory_probe=['fileno', 'duplicate_fstat', 'close_probe'], observer_duplicates_close=True,
        preserve_original_trace=True, original_auditor_must_reject=True)
    assert plan['recovery_contract'] == dict(only_after_original_verdict_and_liveness=True,
        exact_original_object=True, selected_object_closes_once=True, source_and_lock_primitive='CORE::close',
        directory_primitive='CORE::closedir', preserve_actual_return_errno=True, require_native_closed=True,
        separate_receipt=True, recovery_is_implementation_closure=False, no_root_cleanup_before_recovery=True)


def original_observer(prepare):
    raw = prepare.safe_bytes(prepare.TRACE).decode()
    handle = raw[raw.index('sub _handle {'):raw.index('sub _close {')]
    observe = raw[raw.index('sub observe {'):]
    assert 'handle => $handle' in handle
    assert '$HANDLES{$address} = $row; push @HELD, $row;' in handle
    assert observe.index('local (%HANDLES, %COUNTERS, @HELD);') < observe.index('my $ok = eval')
    snapshot = observe.index('$ROW->{handles} = [map {')
    assert snapshot > observe.index('my $error = $@;')
    assert 'my %copy = %$_; delete $copy{handle};' in observe[snapshot:]
    assert '$copy{closed_at_return} = defined(fileno($_->{handle})) ? 0 : 1;' in observe[snapshot:]
    assert observe.index('$ROW->{all_observed_handles_closed}', snapshot) < observe.index('return $ROW;', snapshot)
    review = load(BASE / 'observer-source-review.json')
    assert review['observer'] == prepare.pin(prepare.TRACE)
    assert review['owner'] == prepare.OWNER and review['source_revision'] == prepare.REVISION
    return dict(source=prepare.pin(prepare.TRACE), holds_through_original_snapshot=True,
        returned_records_exclude_handles=True, explicit_alias_needed_after_return=True)


def previous_roots(plan, prepare):
    joined = load(prepare.JOIN / 'result/join.json')
    original = load(ROOT / joined['partitions'][0]['directory'] / 'plan.json')['previous_root_reports']
    expected = original + [p['directory'] + '/result/qualification.json' for p in joined['partitions']]
    assert plan['previous_root_reports'] == expected
    roots = [r['path'] for path in expected for r in load(ROOT / path)['allocated']]
    assert len(roots) == len(set(roots))
    assert len(roots) == joined['prior_roots_absent'] + joined['selected_roots_absent']
    for relative in roots:
        path = Path(relative)
        assert not path.is_absolute() and '..' not in path.parts and relative.startswith('.artifacts/')
        assert not (ROOT / path).exists() and not (ROOT / path).is_symlink()
    return len(roots)


def main():
    assert sys.argv[1:] in ([], ['--verify-saved'])
    prepare = module('omission_audit_preparation', BASE / 'prepare.py')
    plan = load(BASE / 'plan.json'); assert plan == prepare.build()
    names = ['prepare.py', 'model.py', 'audit.py', 'source-pins.json', 'plan.json', 'continuity.py', 'observer-source-review.json']
    pins = load(BASE / 'preflight-pins.json'); assert pins == [prepare.pin(BASE / n) for n in names]
    protocol(plan); observer = original_observer(prepare)
    boundary = module('omission_original_boundary', prepare.BOUNDARY / 'audit.py')
    original = load(prepare.BOUNDARY / 'plan.json'); saved = load(prepare.BOUNDARY / 'result/qualification.json')
    boundary_counts, _ = boundary.verify(original, saved)
    prior_join = module('omission_qualified_selector_adapter', prepare.JOIN / 'audit-corrected.py')
    core = module('omission_original_source_ownership', BASE.with_name('native-proxy-observation-archive-release-close-ordinary-20260912') / 'audit.py')
    correction = module('omission_retained_adapter_proof', prepare.JOIN / 'correction-preflight.py')
    correction.verify_saved()
    contracts = core.SELECT.source_contracts(prepare)
    summaries, controls = [], []
    totals = Counter()
    for index, (profile, original_profile, row) in enumerate(zip(plan['profiles'], original['profiles'], saved['cases'], strict=True)):
        spec, _ = core.OLD.setup(row)
        calls = core.FLOW.derive(row['context'], row['operation']['before'], spec)
        selectors = prior_join.single_selectors(core, calls, row, contracts)
        cases = expected_cases(selectors)
        assert {c['recipe']['scope'] for c in cases[1:]} == set(contracts)
        owner = prepare.OWNER.rsplit('.', 1)[0] + '.' + str(index + 2)
        domain(profile, original_profile, cases, owner)
        counts = Counter(prospective_cases=len(cases), healthy_controls=1)
        counts.update(c['recipe']['handle_kind'] + '_omissions' for c in cases[1:])
        totals.update(counts)
        summaries.append(dict(profile=profile['id'], counts=dict(counts),
            selected_scopes=[c['recipe']['scope'] for c in cases[1:]],
            original_normal_closes=len(selectors), owner=owner))
        for name, mutate in (
            ('missing-case', lambda p: p['cases'].pop()),
            ('duplicate-case', lambda p: p['cases'].append(copy.deepcopy(p['cases'][1]))),
            ('wrong-scope', lambda p: p['cases'][1]['recipe'].update(scope='foreign')),
            ('wrong-kind', lambda p: p['cases'][1]['recipe'].update(handle_kind='foreign')),
            ('changed-close-event', lambda p: p['cases'][1]['baseline'].update(baseline_close_event=-1)),
            ('changed-native-source-path', lambda p: p['cases'][1]['baseline'].update(baseline_path='foreign')),
            ('boolean-case-index', lambda p: p['cases'][1].update(index=True)),
            ('foreign-profile', lambda p: p.update(id='foreign')),
        ):
            changed = copy.deepcopy(profile); mutate(changed)
            assert rejects(lambda: domain(changed, original_profile, cases, owner)), name
            controls.append(profile['id'] + ':' + name)
    protocol_controls = []
    for field, key, value in (
        ('omission_contract', 'retain_exact_object', False),
        ('omission_contract', 'actual_close_executed', True),
        ('omission_contract', 'mark_actual_success', True),
        ('omission_contract', 'reported_return', True),
        ('omission_contract', 'original_observer_closed', True),
        ('observation_contract', 'alias_survives_observe_return', False),
        ('observation_contract', 'require_native_open_after_return', False),
        ('observation_contract', 'preserve_original_trace', False),
        ('observation_contract', 'observer_duplicates_close', False),
        ('recovery_contract', 'only_after_original_verdict_and_liveness', False),
        ('recovery_contract', 'exact_original_object', False),
        ('recovery_contract', 'directory_primitive', 'CORE::close'),
        ('recovery_contract', 'recovery_is_implementation_closure', True),
        ('recovery_contract', 'no_root_cleanup_before_recovery', False),
    ):
        changed = copy.deepcopy(plan); changed[field][key] = value
        assert rejects(lambda: protocol(changed)), (field, key)
        protocol_controls.append(field + ':' + key)
    absent = previous_roots(plan, prepare)
    root_controls = []
    for name, mutate in [('missing-root-domain', lambda p: p['previous_root_reports'].pop()),
                         ('repeated-root-domain', lambda p: p['previous_root_reports'].append(p['previous_root_reports'][0]))]:
        changed = copy.deepcopy(plan); mutate(changed)
        assert rejects(lambda: previous_roots(changed, prepare)); root_controls.append(name)
    result = dict(schema='fsmgen.release_omission_selection_audit.v1', success=True, source_revision=prepare.REVISION,
        prospective_pins=pins, input_files=len(plan['inputs']), input_bytes=sum(r['size_bytes'] for r in plan['inputs']),
        profiles=summaries, totals=dict(totals), original_boundary=boundary_counts, original_observer=observer,
        source_contracts=contracts, predecessor_roots_absent=absent, case_falsifiers=controls,
        protocol_falsifiers=protocol_controls, root_falsifiers=root_controls,
        new_fixture_roots=0, executed_omissions=0, native_executions=0, scope=plan['scope'])
    if sys.argv[1:]:
        assert result == load(BASE / 'result/audit.json')
    else:
        with (LOG / 'audit.json').open('x') as stream:
            stream.write(json.dumps(result, sort_keys=True, indent=2) + '\n')
    print(json.dumps({k:v for k,v in result.items() if k not in ('prospective_pins','profiles','source_contracts','original_observer','original_boundary')},sort_keys=True))


if __name__ == '__main__':
    main()
