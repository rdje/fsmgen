"""Independently derive close ownership from source flows, not event nesting."""
from collections import Counter
import copy
import hashlib
import itertools
import json
from pathlib import Path
import re
import sys

BASE = Path(__file__).resolve().parent
ROOT = BASE.parents[2]
LOG = ROOT / '.artifacts/logs' / BASE.name


def load(path):
    return json.loads(path.read_bytes())


def rejects(action):
    try:
        action()
    except (AssertionError, KeyError, TypeError, ValueError, IndexError):
        return True
    return False


def ownership(calls, context):
    """Enumerate the source forest's opening sites and original owning scopes."""
    counts = Counter(); expected = []
    for call in calls:
        name = call['name']; occurrence = counts[name]; counts[name] += 1
        if name.endswith('::_source'):
            assert name == 'NativeProxyImageCustody::_source'
            kind = 'source'; label = call['opens']
            owner = calls[call['parent']]['name']
            if owner.startswith('NativeProxyObservationRelease::'):
                assert owner.rsplit('::', 1)[1] in ('_prepare', '_retain_live_sources')
                owner = 'NativeProxyObservationRelease::_close_owned'
            else:
                assert owner in ('NativeProxyObservationArchive::_source_closure',
                    'NativeProxyImageCoordination::_census', 'NativeProxyReferenceCensus::_closure',
                    'NativeProxyReferenceCensus::_image', 'NativeProxyReferenceCensus::_inspect_locked',
                    'NativeProxyImageCustody::read_entry')
        elif name in ('NativeProxyImageCoordination::_names', 'NativeProxyImageCustody::_members'):
            kind = 'directory'; owner = name
            label = 'directory:' + str(sum(r['kind'] == 'directory' for r in expected))
        else:
            continue
        expected.append(dict(address=f'{kind}|{name}#{occurrence}', kind=kind, symbol=name,
            occurrence=occurrence, label=label, path=call['path'], open_call_id=call['id'],
            close_scope=owner, close_caller=owner.rsplit('::', 1)[0]))
    expected.append(dict(address='lock|NativeProxyImageCoordination::_transaction#0', kind='lock',
        symbol='NativeProxyImageCoordination::_transaction', occurrence=0, label='lock:0',
        path=context['acquired']['lock']['path'], open_call_id=None,
        close_scope='NativeProxyImageCoordination::_transaction', close_caller='NativeProxyImageCoordination'))
    return sorted(expected, key=lambda r: r['address'])


def domain(profile, expected, original):
    assert profile['id'] == original['id'] and profile['selection'] == original['selection']
    assert profile['selectors'] == expected
    cases = profile['cases']
    assert cases[0] == dict(index=0, name='healthy', reports=[], primary=None)
    assert len(cases) == len(expected) + 1
    for index, (row, selector) in enumerate(zip(cases[1:], expected, strict=True), 1):
        report = {k: selector[k] for k in ('address', 'kind', 'symbol', 'occurrence')}
        report['errno'] = 'EIO'
        assert row == dict(index=index, name='single:' + selector['address'], reports=[report], primary=None)
    assert len({c['name'] for c in cases}) == len(cases)


def source_contracts(prepare):
    contracts = {
        'NativeProxyObservationRelease::_close_owned': ('native-proxy-observation-archive-release-20260911/ObservationRelease.pm', 'cannot close retained release descriptor'),
        'NativeProxyObservationArchive::_source_closure': ('native-proxy-observation-archive-20260911/ObservationArchive.pm', 'cannot close archive reread descriptor'),
        'NativeProxyImageCoordination::_census': ('native-proxy-image-coordination-20260910/Coordination.pm', 'cannot close census reference'),
        'NativeProxyImageCoordination::_transaction': ('native-proxy-image-coordination-20260910/Coordination.pm', 'cannot close permanent lock'),
        'NativeProxyImageCoordination::_names': ('native-proxy-image-coordination-20260910/Coordination.pm', 'cannot close bounded namespace'),
        'NativeProxyReferenceCensus::_closure': ('native-proxy-runtime-census-20260910/ReferenceCensus.pm', 'cannot close fresh reference'),
        'NativeProxyReferenceCensus::_image': ('native-proxy-runtime-census-20260910/ReferenceCensus.pm', 'cannot close image input'),
        'NativeProxyReferenceCensus::_inspect_locked': ('native-proxy-runtime-census-20260910/ReferenceCensus.pm', 'cannot close '),
        'NativeProxyImageCustody::read_entry': ('native-proxy-image-custody-20260910/ImageCustody.pm', 'cannot close image descriptor'),
        'NativeProxyImageCustody::_members': ('native-proxy-image-custody-20260910/ImageCustody.pm', 'cannot close image directory'),
    }
    result = {}
    for scope, (relative, phrase) in contracts.items():
        path = BASE.parent / relative; raw = path.read_bytes()
        symbol = scope.rsplit('::', 1)[1]
        start = raw.index(('sub ' + symbol + ' {').encode())
        match = re.search(rb'^sub ', raw[start + 1:], re.M)
        body = raw[start:] if match is None else raw[start:start + 1 + match.start()]
        assert phrase.encode() in body and (b'close(' in body or b'closedir(' in body)
        result[scope] = dict(path=str(path.relative_to(ROOT)), body_sha256=hashlib.sha256(body).hexdigest(),
            error_prefix=phrase, source_pin=prepare.pin(path))
    return result


def main():
    assert sys.argv[1:] in ([], ['--verify-saved'])
    import importlib.util
    spec = importlib.util.spec_from_file_location('close_selection_prepare', BASE / 'prepare.py')
    prepare = importlib.util.module_from_spec(spec); spec.loader.exec_module(prepare)
    plan = load(BASE / 'plan.json'); assert plan == prepare.build()
    assert load(BASE / 'preflight-pins.json') == [prepare.pin(BASE / n)
        for n in ('prepare.py', 'model.py', 'audit.py', 'source-pins.json', 'plan.json')]
    prior = prepare.module('close_selection_boundary_audit', prepare.BOUNDARY / 'audit.py')
    original = load(prepare.BOUNDARY / 'plan.json'); saved = load(prepare.BOUNDARY / 'result/qualification.json')
    prior.authenticate(original); verified, _ = prior.verify(original, saved)
    before = prepare.module('close_selection_source_scope', prepare.BEFORE / 'expected_trace.py')
    alternates = prepare.module('close_selection_alternate_inputs', prepare.CALL_SELECTION / 'audit.py')
    alternate_plan = load(prepare.CALL_SELECTION / 'plan.json')
    alternates.authenticate(alternate_plan)
    contracts = source_contracts(prepare)
    assert {v['source_pin']['path'] for v in contracts.values()} <= {v['path'] for v in plan['inputs']}
    model = prepare.module('close_selection_bound_resolver', BASE / 'model.py')
    summaries, controls, alternative_count, all_scopes = [], [], 0, set()
    for profile, baseline, raw in zip(plan['profiles'], original['profiles'], saved['cases'], strict=True):
        spec, _ = prior.OLD.setup(raw)
        calls = prior.FLOW.derive(raw['context'], raw['operation']['before'], spec)
        expected = ownership(calls, raw['context'])
        trace = before.derive(calls, raw['context'], original['sealed_continuations'], None)
        without_calls = lambda events: [e for e in events if not e.startswith('call:')]
        assert without_calls(trace['events']) == without_calls(raw['operation']['events'])
        assert {h['label'] for h in trace['handles']} == {h['label'] for h in expected}
        actual = {h['label']: h for h in raw['operation']['handles']}
        selectors = []
        for item in expected:
            label = item['label']; h = actual[label]
            assert h['kind'] == item['kind'] and h['path'] == item['path'] and h['close_caller'] == item['close_caller']
            assert item['close_scope'] in contracts; all_scopes.add(item['close_scope'])
            events = raw['operation']['events']
            assert events.count('opened:' + label) == events.count('close:' + label + ':before') == events.count('close:' + label + ':after') == 1
            selectors.append(dict(address=item['address'], kind=item['kind'], symbol=item['symbol'], occurrence=item['occurrence'],
                baseline_handle=label, baseline_open_call_id=item['open_call_id'], baseline_path=item['path'],
                baseline_open_event=events.index('opened:' + label), baseline_close_event=events.index('close:' + label + ':before'),
                baseline_close_scope=item['close_scope'], baseline_close_caller=item['close_caller']))
        domain(profile, selectors, baseline)
        reports = [c['reports'][0] for c in profile['cases'][1:]]
        assert model.resolve(calls, raw['context'], reports) == expected
        names = [p for p in raw['operation']['before']['store'] if p.startswith('references/')]
        bindings = set()
        for order in itertools.permutations(range(len(names))):
            flow = alternates.alternate_flow(raw, spec, order)
            derived = ownership(flow, raw['context'])
            resolved = model.resolve(flow, raw['context'], reports)
            assert resolved == derived
            assert [r['address'] for r in derived] == [r['address'] for r in expected]
            bindings.add(hashlib.sha256(json.dumps(resolved, sort_keys=True).encode()).hexdigest())
            alternative_count += 1
        for mutation, change in (
            ('missing-close', lambda p: p['selectors'].pop()),
            ('duplicated-close', lambda p: p['selectors'].append(copy.deepcopy(p['selectors'][0]))),
            ('wrong-owner', lambda p: p['selectors'][0].update(baseline_close_scope='invented')),
            ('omitted-single', lambda p: p['cases'].pop()),
            ('successful-close-report', lambda p: p['cases'][1]['reports'][0].update(errno='SUCCESS')),
            ('invented-primary', lambda p: p['cases'][1].update(primary='invented')),
        ):
            changed = copy.deepcopy(profile); change(changed)
            assert rejects(lambda: domain(changed, selectors, baseline)); controls.append(profile['id'] + ':' + mutation)
        for mutation, change in (
            ('duplicate-report', lambda r: r.append(copy.deepcopy(r[0]))),
            ('wrong-kind', lambda r: r[0].update(kind='invented')),
            ('stale-id', lambda r: r[0].update(call_id=0)),
            ('negative-occurrence', lambda r: r[0].update(occurrence=-1)),
            ('boolean-occurrence', lambda r: r[0].update(occurrence=True)),
            ('unknown-address', lambda r: r[0].update(address='invented')),
        ):
            changed = copy.deepcopy(reports); change(changed)
            assert rejects(lambda: model.resolve(calls, raw['context'], changed)); controls.append(profile['id'] + ':' + mutation)
        summaries.append(dict(profile=profile['id'], selectors=len(selectors), proposed_cases=len(profile['cases']),
            kinds=dict(Counter(r['kind'] for r in selectors)), distinct_order_bindings=len(bindings)))
    assert all_scopes == set(contracts)
    result = dict(schema='fsmgen.release_close_selection_audit.v1', success=True, source_revision=plan['source_revision'],
        prospective_selectors=sum(r['selectors'] for r in summaries), proposed_cases=sum(r['proposed_cases'] for r in summaries),
        new_fixture_roots=0, close_controls_executed=0, original_healthy_verification=verified,
        profiles=summaries, pure_order_permutations=alternative_count, source_contracts=contracts,
        falsifiers=controls, scope=plan['scope'], binding=plan['binding'])
    if sys.argv[1:] == ['--verify-saved']:
        assert load(BASE / 'result/audit.json') == result
    else:
        with (LOG / 'audit.json').open('x') as output: output.write(json.dumps(result, sort_keys=True, indent=2) + '\n')
    print(json.dumps(result, sort_keys=True))


if __name__ == '__main__':
    main()
