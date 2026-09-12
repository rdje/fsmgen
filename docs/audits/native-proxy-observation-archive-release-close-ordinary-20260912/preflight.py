"""Compare the recursive close oracle with a healthy-prefix/remaining-owner oracle."""
from collections import Counter
import copy
import errno
import hashlib
import importlib.util
import json
import os
from pathlib import Path
import re

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


def reject(action):
    try:
        action()
    except (AssertionError, KeyError, TypeError, ValueError, IndexError):
        return True
    return False


def reference(calls, sealed, healthy, bindings, selected):
    """Stop at the selected real close and discharge only already-open owners."""
    by_label = {b['label']: b for b in bindings}
    events = healthy['events']; pending = []
    if selected is None:
        prefix = events[:-1]
    else:
        target = selected['label']; cut = events.index('close:' + target + ':after')
        prefix = events[:cut + 1]
        remaining = {e[len('opened:'):] for e in prefix if e.startswith('opened:')}
        remaining -= {e[len('close:'):-len(':after')] for e in prefix if e.startswith('close:') and e.endswith(':after')}
        for event in events[cut + 1:]:
            if event.startswith('close:') and event.endswith(':before'):
                label = event[len('close:'):-len(':before')]
                if label in remaining:
                    prefix += ['close:' + label + ':before', 'close:' + label + ':after']
                    remaining.remove(label)
        assert not remaining
        scope = selected['close_scope']
        if scope not in ('NativeProxyObservationRelease::_close_owned', 'NativeProxyImageCoordination::_transaction'):
            ident = selected['open_call_id']
            if selected['kind'] == 'source': ident = calls[ident]['parent']
            assert calls[ident]['name'] == scope
            while ident is not None:
                pending.append(ident); ident = calls[ident]['parent']
            pending.reverse()
    entered = {int(e.split(':')[1]) for e in prefix if e.startswith('call:') and e.endswith(':before')}
    frames = []
    for frame in healthy['calls']:
        if frame['id'] not in entered: continue
        frame = copy.deepcopy(frame)
        if frame['id'] in pending:
            frame.pop('completion', None); frame.pop('continuation', None)
        frames.append(frame)
    opened = {e[len('opened:'):] for e in prefix if e.startswith('opened:')}
    handles = [dict(h, close_scope=by_label[h['label']]['close_scope']) for h in healthy['handles'] if h['label'] in opened]
    reports = [dict(label=e[len('close:'):-len(':before')],
        applied=selected is not None and e == 'close:' + selected['label'] + ':before')
        for e in prefix if e.startswith('close:') and e.endswith(':before')]
    unlinked = int('unlink:0:after' in prefix)
    checks = [c for c in calls if c['name'] == 'NativeProxyObservationRelease::_assert_absent' and c['id'] in entered]
    historical = any('call:' + str(c['id']) + ':after' in prefix for c in checks)
    last = None
    if checks:
        c = checks[-1]
        last = dict(phase=c['phase'], state='absent' if 'call:' + str(c['id']) + ':after' in prefix else 'unknown')
    prefixes = {
        'NativeProxyObservationRelease::_close_owned': 'cannot close retained release descriptor',
        'NativeProxyImageCoordination::_transaction': 'cannot close permanent lock',
        'NativeProxyImageCoordination::_names': 'cannot close bounded namespace',
        'NativeProxyImageCoordination::_census': 'cannot close census reference',
        'NativeProxyImageCustody::_members': 'cannot close image directory',
        'NativeProxyImageCustody::read_entry': 'cannot close image descriptor',
        'NativeProxyObservationArchive::_source_closure': 'cannot close archive reread descriptor',
        'NativeProxyReferenceCensus::_image': 'cannot close image input',
        'NativeProxyReferenceCensus::_closure': 'cannot close fresh reference',
        'NativeProxyReferenceCensus::_inspect_locked': 'cannot close reference',
    }
    return dict(events=prefix + ['operation:end'], calls=frames, handles=handles, reports=reports,
        interrupted_boundary_ids=pending, injected_hits=0, reported_error_hits=int(selected is not None),
        effects=dict(unlink_attempted=unlinked, unlink_completed=unlinked,
            reference_absence_verified=int(historical), last_reference_check=last),
        success=int(selected is None),
        error='' if selected is None else prefixes[selected['close_scope']] + ': ' + os.strerror(errno.EIO) + '\n')


def main():
    prepare = module('ordinary_close_preflight_prepare', BASE / 'prepare.py')
    plan = load(BASE / 'plan.json'); vectors = load(BASE / 'flow-vectors.json')
    assert prepare.build() == (plan, vectors)
    pins = load(BASE / 'flow-preflight-pins.json')
    names = ['ClosePlan.pm', 'expected_trace.py', 'prepare.py', 'prepare-pin.json', 'plan.json', 'flow-vectors.json', 'flow-qualify.t', 'preflight.py']
    assert pins == [prepare.pin(BASE / n) for n in names]
    first = load(BASE / 'prepare-pin.json'); assert first == prepare.pin(BASE / 'prepare.py')
    report = load(LOG / 'flow-qualification.json')
    assert set(report) == {'schema', 'success', 'prospective_pins', 'variants', 'controls', 'allocated', 'forbidden_process_attempts'}
    assert report['schema'] == 'fsmgen.release_close_binding_qualification.v1' and report['success'] is True
    assert report['prospective_pins'] == pins and report['allocated'] == [] and report['forbidden_process_attempts'] == 0
    old = module('ordinary_close_prior_healthy_scope', prepare.CALLS / 'expected_trace.py')
    trace = module('ordinary_close_recursive_scope', BASE / 'expected_trace.py')
    selection = module('ordinary_close_independent_binding', prepare.SELECTION / 'audit.py')
    summaries, observed_variants = [], []
    witness = None
    for profile in vectors['profiles']:
        for variant in profile['variants']:
            calls = variant['calls']; bindings = selection.ownership(calls, profile['context'])
            assert variant['expected'] == bindings
            observed_variants.append(dict(profile=profile['profile'], name=variant['name'],
                resolved=len(bindings), resolution_sha256=signature(bindings), inputs_unchanged=1))
            healthy = old.derive(calls, profile['context'], plan['sealed_symbols'], None)
            results = []
            for selected in [None, *bindings]:
                observed = trace.derive(calls, profile['context'], plan['sealed_symbols'],
                    [] if selected is None else [selected], os.strerror(errno.EIO))
                expected = reference(calls, plan['sealed_symbols'], healthy, bindings, selected)
                assert observed == expected, (profile['profile'], variant['name'], None if selected is None else selected['address'])
                results.append(dict(address=None if selected is None else selected['address'], signature=signature(observed)))
                if selected is not None and selected['close_scope'] == 'NativeProxyObservationRelease::_close_owned':
                    witness = (observed, expected)
            summaries.append(dict(profile=profile['profile'], variant=variant['name'], predictions=len(results), signature=signature(results)))
    assert report['variants'] == observed_variants
    diagnostics = [('missing errno', 'close-report fields differ from the pinned contract'),
        ('stale numeric call', 'close-report fields differ from the pinned contract'),
        ('unknown errno', 'unsupported close-report errno'),
        ('negative occurrence', 'invalid close-report occurrence'), ('string occurrence', 'invalid close-report occurrence'),
        ('boolean occurrence', 'invalid close-report occurrence'), ('structured occurrence', 'invalid close-report occurrence'),
        ('wrong address', 'close-report address differs from its fields'),
        ('unknown opening', 'duplicate or unknown close report'),
        ('multiple reports', 'expected prospective flow, context and single close reports')]
    assert report['controls'] == [dict(name=n, returned=0, error=e + '\n') for n, e in diagnostics]
    assertions = len(observed_variants) * 3 + len(diagnostics) * 2 + 1
    tap = (LOG / 'flow-qualify.tap').read_text()
    assert re.findall(r'^ok ([0-9]+) - ', tap, re.M) == [str(i) for i in range(1, assertions + 1)]
    assert re.findall(r'^1\.\.([0-9]+)$', tap, re.M) == [str(assertions)]
    assert not re.search(r'^(not ok|Bail out!)|#\s*(skip|todo)\b', tap, re.M | re.I)
    assert (LOG / 'flow-qualify.exit').read_bytes() == b'0\n'
    observed, expected = witness
    controls = []
    for name, change in (
        ('lost-close', lambda r: r['events'].pop(-2)),
        ('wrong-primary-error', lambda r: r.update(error='different\n')),
        ('false-success', lambda r: r.update(success=1)),
        ('invented-pending-frame', lambda r: r['interrupted_boundary_ids'].append(0)),
        ('lost-unlink', lambda r: r['effects'].update(unlink_completed=0)),
        ('lost-absence', lambda r: r['effects'].update(reference_absence_verified=0)),
        ('missing-handle', lambda r: r['handles'].pop()),
        ('wrong-owner', lambda r: r['handles'][0].update(close_scope='foreign')),
        ('lost-report-hit', lambda r: r.update(reported_error_hits=0)),
    ):
        changed = copy.deepcopy(observed); change(changed)
        assert changed != expected, name; controls.append(name)
    result = dict(schema='fsmgen.release_ordinary_close_preflight.v1', success=True, prospective_pins=pins,
        variants=summaries, pure_assertions=assertions, resolved_singles=sum(r['resolved'] for r in observed_variants),
        predictions=sum(r['predictions'] for r in summaries), falsifiers=controls,
        errno_constants=dict(EIO=errno.EIO), errno_text=dict(EIO=os.strerror(errno.EIO)),
        scope='Current-flow Perl resolution and recursive close-error predictions match independent source ownership and healthy-prefix/remaining-owner reconstruction. No fixture or close control executes.')
    with (LOG / 'preflight.json').open('x') as output: output.write(json.dumps(result, sort_keys=True, indent=2) + '\n')
    print(json.dumps({k: v for k, v in result.items() if k not in ('prospective_pins', 'variants')}, sort_keys=True))


if __name__ == '__main__':
    main()
