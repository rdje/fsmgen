"""Independently check composition coverage, live intervals and error precedence.

The selector scans live-handle sets. This oracle uses opening/closing intervals,
original source-scope single-failure interpreters, and separate recipe coverage.
No original producer main or fixture is executed.
"""
from collections import Counter
import copy
import errno
import hashlib
import importlib.util
import itertools
import json
import os
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


def signature(value):
    return hashlib.sha256(json.dumps(value, sort_keys=True, separators=(',', ':')).encode()).hexdigest()


def rejects(action):
    try:
        action()
    except (AssertionError, KeyError, ValueError, TypeError, IndexError, StopIteration):
        return True
    return False


P = module('composition_audit_prepare', BASE / 'prepare.py')
BOUNDARY = module('composition_audit_boundary', P.BOUNDARY / 'audit.py')
OWNERS = module('composition_audit_owners', P.SELECTION / 'audit.py')
CALL = module('composition_audit_call_scope', P.CALLS / 'expected_trace.py')
CLOSE = module('composition_audit_close_scope', P.ORDINARY / 'expected_trace.py')
ALTERNATE = module('composition_audit_order', BASE.with_name('native-proxy-release-call-selection-20260911') / 'audit.py')
RELEASE = 'NativeProxyObservationRelease'
COORD = 'NativeProxyImageCoordination'
CUSTODY = 'NativeProxyImageCustody'


def expected_recipes(bindings):
    scopes = {b['close_scope'] for b in bindings}
    source_scopes = {b['close_scope'] for b in bindings if b['kind'] == 'source'}
    directory_scopes = {b['close_scope'] for b in bindings if b['kind'] == 'directory'}
    assert scopes == set(CLOSE.ERRORS)
    assert scopes - source_scopes - directory_scopes == {COORD + '::_transaction'}
    recipes = [dict(kind='healthy', scope=None, order='none')]
    families = [('group', sorted(scopes)), ('source-primary', sorted(source_scopes)),
                ('directory-primary', sorted(directory_scopes)),
                ('milestone-primary', ['before-unlink', 'after-unlink-unknown', 'final-lock-identity'])]
    for kind, targets in families:
        for scope in targets:
            recipes.extend(dict(kind=kind, scope=scope, order=order) for order in ('observed', 'reversed'))
    return recipes


def reference(calls, context, sealed, bindings, recipe):
    assert recipe in expected_recipes(bindings)
    healthy = CALL.derive(calls, context, sealed, None)
    events = healthy['events']; positions = {e: i for i, e in enumerate(events)}
    assert len(positions) == len(events)
    by_label = {b['label']: b for b in bindings}
    intervals = {label: (positions['opened:' + label], positions['close:' + label + ':after'])
                 for label in by_label}
    close_order = sorted(by_label, key=lambda label: intervals[label][1])
    def live_at(index):
        return [label for label in close_order if intervals[label][0] <= index < intervals[label][1]]
    kind = recipe['kind']; scope = recipe['scope']; target = None; primary = None
    call_primary = None; prediction = healthy
    if kind == 'group':
        target = next(label for label in close_order if by_label[label]['close_scope'] == scope
            and live_at(intervals[label][1]))
        position = intervals[target][1]
        prediction = CLOSE.derive(calls, context, sealed, [by_label[target]], os.strerror(errno.EIO))
    elif kind == 'directory-primary':
        target_directory = next(label for label in close_order if by_label[label]['close_scope'] == scope)
        position = intervals[target_directory][0]
        primary = dict(kind='directory-read', address=by_label[target_directory]['address'], errno='EIO',
            error_prefix={COORD + '::_names': 'cannot read bounded namespace',
                          CUSTODY + '::_members': 'cannot read image members'}[scope])
    elif kind in ('source-primary', 'milestone-primary'):
        if kind == 'source-primary':
            eligible = [c for c in calls if c['name'] == CUSTODY + '::_recheck_source'
                and by_label[c['source_handle']]['close_scope'] == scope
                and len(live_at(positions['call:' + str(c['id']) + ':before'])) > 1]
        elif scope == 'before-unlink':
            eligible = [c for c in calls if c['name'] == RELEASE + '::_unlink_exact']
        elif scope == 'after-unlink-unknown':
            after_unlink = next(c for c in calls if c['name'] == RELEASE + '::_assert_absent'
                                and c['phase'] == 'after_unlink')
            eligible = [c for c in calls if c['parent'] == after_unlink['id']
                        and c['name'] == 'NativeProxyPrivateWorkspace::_absent']
        else:
            eligible = [c for c in reversed(calls) if c['name'] == COORD + '::_lock_identity']
        assert eligible
        c = eligible[0]
        ordinal = sum(other['name'] == c['name'] for other in calls[:c['id']])
        primary = dict(kind='call', symbol=c['name'], occurrence=ordinal, phase='before',
                       address=f"{c['name']}#{ordinal}:before")
        call_primary = {k: v for k, v in primary.items() if k != 'kind'}
        call_primary['call_id'] = c['id']
        position = positions['call:' + str(c['id']) + ':before']
        prediction = CALL.derive(calls, context, sealed, call_primary)
    else:
        position = len(events) - 2
    suffix = ([target] if target else []) + live_at(position)
    if kind == 'group': assert len(suffix) > 1
    if primary: assert suffix
    if kind in ('group', 'source-primary', 'milestone-primary'):
        actual_suffix = [event[len('close:'):-len(':after')]
            for event in prediction['events'][position + (0 if target else 1):]
            if event.startswith('close:') and event.endswith(':after')]
        assert actual_suffix == suffix, (recipe, actual_suffix, suffix)
    reports = []
    for i, label in enumerate(suffix):
        bound = by_label[label]
        value = 'EIO' if (i + int(primary is not None)) % 2 == 0 else 'ENOSPC'
        reports.append(dict(address=bound['address'], kind=bound['kind'], symbol=bound['symbol'],
                            occurrence=bound['occurrence'], errno=value))
    winner = None
    if primary is not None:
        winner = dict(kind=primary['kind'], value=primary.get('error_prefix', primary['address']),
                      errno=primary.get('errno'))
    elif target:
        winner = dict(kind='close', value=CLOSE.ERRORS[by_label[target]['close_scope']], errno='EIO')
    if recipe['order'] == 'reversed': reports = list(reversed(reports))
    unlink = positions['unlink:0:after'] <= position
    checks = [c for c in calls if c['name'] == RELEASE + '::_assert_absent'
              and positions['call:' + str(c['id']) + ':before'] <= position]
    completed = [c for c in checks if positions['call:' + str(c['id']) + ':after'] <= position]
    last = None if not checks else dict(phase=checks[-1]['phase'], state='absent' if checks[-1] in completed else 'unknown')
    return dict(primary=primary, reports=reports, cut_event=events[position], winner=winner,
        cleanup_order=[by_label[label]['address'] for label in suffix],
        effects=dict(unlink_attempted=int(unlink), unlink_completed=int(unlink),
                     reference_absence_verified=int(bool(completed)), last_reference_check=last))


def domain(profile, original, calls, context, sealed):
    assert set(profile) == {'id', 'selection', 'owner', 'cases'}
    assert profile['id'] == original['id'] and profile['selection'] == original['selection']
    bindings = OWNERS.ownership(calls, context)
    recipes = expected_recipes(bindings)
    assert [r['recipe'] for r in profile['cases']] == recipes
    for i, (case, recipe) in enumerate(zip(profile['cases'], recipes, strict=True)):
        assert case == dict(index=i, recipe=recipe, baseline=reference(calls, context, sealed, bindings, recipe))
    for a, b in zip(profile['cases'][1::2], profile['cases'][2::2], strict=True):
        left, right = copy.deepcopy(a['baseline']), copy.deepcopy(b['baseline'])
        assert left.pop('reports') == list(reversed(right.pop('reports')))
        assert left == right
    return bindings


def main():
    assert sys.argv[1:] in ([], ['--verify-saved'])
    plan = load(BASE / 'plan.json'); assert plan == P.build()
    names = ('prepare.py', 'model.py', 'audit.py', 'source-pins.json', 'plan.json')
    pins = load(BASE / 'preflight-pins.json'); assert pins == [P.pin(BASE / n) for n in names]
    original = load(P.BOUNDARY / 'plan.json'); saved = load(P.BOUNDARY / 'result/qualification.json')
    BOUNDARY.authenticate(original); original_counts, _ = BOUNDARY.verify(original, saved)
    contracts = OWNERS.source_contracts(P)
    for scope in (COORD + '::_names', CUSTODY + '::_members'):
        raw = (ROOT / contracts[scope]['path']).read_text()
        start = raw.index('sub ' + scope.rsplit('::', 1)[1] + ' {')
        body = raw[start:raw.index('\nsub ', start + 1)]
        assert body.index('my $ok = eval') < body.index('my $name = readdir($directory)')
        assert body.index('my $error = $@') < body.index('closedir($directory)') < body.index('die $error unless $ok')
    model = P.module('composition_actual_selector', BASE / 'model.py')
    summaries = []; controls = []; order_predictions = []; permutations = 0
    for i, (profile, prior_profile, row) in enumerate(zip(plan['profiles'], original['profiles'], saved['cases'], strict=True)):
        assert profile['owner'] == P.OWNER.rsplit('.', 1)[0] + '.' + str(i + 2)
        spec, _ = BOUNDARY.OLD.setup(row)
        calls = BOUNDARY.FLOW.derive(row['context'], row['operation']['before'], spec)
        bindings = domain(profile, prior_profile, calls, row['context'], plan['sealed_symbols'])
        summaries.append(dict(profile=profile['id'], cases=len(profile['cases']),
            recipes=dict(Counter(c['recipe']['kind'] for c in profile['cases'])),
            selected_report_occurrences=sum(len(c['baseline']['reports']) for c in profile['cases']),
            domain_sha256=signature(profile['cases'])))
        names = [p for p in row['operation']['before']['store'] if p.startswith('references/')]
        for order in itertools.permutations(range(len(names))):
            flow = ALTERNATE.alternate_flow(row, spec, order)
            healthy = CALL.derive(flow, row['context'], plan['sealed_symbols'], None)
            owners = OWNERS.ownership(flow, row['context'])
            vectors = []
            for recipe in expected_recipes(owners):
                actual = model.resolve(flow, healthy, owners, recipe)
                expected = reference(flow, row['context'], plan['sealed_symbols'], owners, recipe)
                assert actual == expected, (profile['id'], order, recipe)
                vectors.append(actual)
            permutations += 1
            order_predictions.append(dict(profile=profile['id'], order=list(order),
                predictions=len(vectors), sha256=signature(vectors)))
        def checked(changed):
            domain(changed, prior_profile, calls, row['context'], plan['sealed_symbols'])
        mutations = (
            ('missing-case', lambda p: p['cases'].pop()),
            ('duplicate-case', lambda p: p['cases'].append(copy.deepcopy(p['cases'][0]))),
            ('foreign-owner-scope', lambda p: p['cases'][1]['recipe'].update(scope='foreign')),
            ('lost-primary', lambda p: next(c for c in p['cases'] if c['baseline']['primary'])['baseline'].update(primary=None)),
            ('successful-error-report', lambda p: p['cases'][1]['baseline']['reports'][0].update(errno='SUCCESS')),
            ('same-group-errno', lambda p: p['cases'][1]['baseline']['reports'][1].update(errno='EIO')),
            ('lost-actual-close', lambda p: p['cases'][1]['baseline']['cleanup_order'].pop()),
            ('wrong-winner', lambda p: p['cases'][1]['baseline']['winner'].update(errno='ENOSPC')),
            ('wrong-cut', lambda p: p['cases'][1]['baseline'].update(cut_event='operation:begin')),
            ('lost-unlink', lambda p: p['cases'][0]['baseline']['effects'].update(unlink_completed=0)),
            ('lost-absence', lambda p: p['cases'][0]['baseline']['effects'].update(last_reference_check=None)),
            ('wrong-declaration-order', lambda p: p['cases'][2]['baseline']['reports'].reverse()),
            ('stale-numeric-call', lambda p: p['cases'][1]['baseline']['reports'][0].update(call_id=0)),
            ('changed-profile', lambda p: p.update(selection={})),
        )
        for name, mutate in mutations:
            changed = copy.deepcopy(profile); mutate(changed)
            assert rejects(lambda: checked(changed)), name
            controls.append(profile['id'] + ':' + name)
    roots = []
    for relative in plan['previous_root_reports']:
        for record in load(ROOT / relative)['allocated']:
            path = record['path']; assert not Path(path).is_absolute() and '..' not in Path(path).parts
            assert not (ROOT / path).exists() and not (ROOT / path).is_symlink()
            roots.append(path)
    assert len(roots) == len(set(roots))
    result = dict(schema='fsmgen.release_close_composition_selection_audit.v1', success=True,
        source_revision=plan['source_revision'], prospective_pins=pins, profiles=summaries,
        proposed_cases=sum(p['cases'] for p in summaries), order_permutations=permutations,
        pure_order_predictions=sum(p['predictions'] for p in order_predictions),
        order_vectors=order_predictions, falsifiers=controls, original_healthy_verification=original_counts,
        source_contracts=contracts, previous_roots_absent=len(roots),
        new_fixture_roots=0, close_controls_executed=0, directory_controls_executed=0, scope=plan['scope'])
    if sys.argv[1:]:
        assert load(BASE / 'result/audit.json') == result
    else:
        with (LOG / 'audit.json').open('x') as stream:
            stream.write(json.dumps(result, indent=2, sort_keys=True) + '\n')
    print(json.dumps({k: v for k, v in result.items() if k not in
        ('prospective_pins', 'order_vectors', 'source_contracts', 'original_healthy_verification')}, sort_keys=True))


if __name__ == '__main__':
    main()
