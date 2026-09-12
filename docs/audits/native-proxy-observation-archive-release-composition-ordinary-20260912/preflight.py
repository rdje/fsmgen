"""Check Perl composition binding and independent full-trace predictions."""
import copy
import errno
import hashlib
import importlib.util
import json
import os
from pathlib import Path
import re
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


PREPARE = module('composition_preflight_prepare', BASE / 'prepare.py')
SELECTION = PREPARE.SELECTION_AUDIT
TRACE = module('composition_recursive_trace', BASE / 'expected_trace.py')


def reference(calls, context, sealed, resolved):
    """Use unchanged single/call interpreters or a directory lifetime cut.

Cleanup reports cannot change the unwind suffix after its first failure. The
selected recipes report only on handles that already belong to that suffix.
"""
    witness = resolved['witness']; primary = resolved['resolved_primary']
    bindings = SELECTION.OWNERS.ownership(calls, context)
    by_label = {b['label']: b for b in bindings}
    by_address = {b['address']: b for b in bindings}
    targets = {r['label']: r for r in resolved['resolved_reports']}
    healthy = SELECTION.CALL.derive(calls, context, sealed, None)
    if primary is not None and primary['kind'] == 'call':
        selected = {k: v for k, v in primary.items() if k != 'kind'}
        source = SELECTION.CALL.derive(calls, context, sealed, selected)
    elif primary is not None:
        assert primary['kind'] == 'directory-read'
        bound = primary['binding']; events = healthy['events']
        cut = events.index('opened:' + bound['label'])
        prefix = events[:cut + 1]
        still_open = {label for label in by_label if 'opened:' + label in prefix
                      and 'close:' + label + ':after' not in prefix}
        suffix = [e for e in events[cut + 1:] if e.startswith('close:')
                  and e[len('close:'):e.rfind(':')] in still_open]
        pending = []; ident = bound['open_call_id']
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
        source = dict(events=prefix + suffix + ['operation:end'], calls=frames,
            handles=[h for h in healthy['handles'] if 'opened:' + h['label'] in prefix],
            interrupted_boundary_ids=pending, injected_hits=0)
    elif targets:
        first = by_address[witness['cleanup_order'][0]]
        source = SELECTION.CLOSE.derive(calls, context, sealed, [first], os.strerror(errno.EIO))
    else:
        source = healthy
    events = source['events']
    report_order = [e[len('close:'):-len(':after')] for e in events
                    if e.startswith('close:') and e.endswith(':after')]
    hits = [targets[label]['address'] for label in report_order if label in targets]
    assert hits == witness['cleanup_order']
    reports = [dict(label=label, applied=label in targets,
                    errno=targets[label]['errno'] if label in targets else None) for label in report_order]
    winner = witness['winner']; error = ''
    if winner is not None:
        error = ('injected release call: ' + winner['value'] + '\n') if winner['kind'] == 'call' else (
            winner['value'] + ': ' + os.strerror(getattr(errno, winner['errno'])) + '\n')
    handles = [dict(h, close_scope=by_label[h['label']]['close_scope']) for h in source['handles']]
    return dict(events=events, calls=source['calls'], handles=handles, reports=reports,
        interrupted_boundary_ids=source['interrupted_boundary_ids'],
        injected_hits=int(primary is not None and primary['kind'] == 'call'),
        directory_primary_hits=int(primary is not None and primary['kind'] == 'directory-read'),
        reported_error_hits=len(hits), reported_error_addresses=hits,
        effects=witness['effects'], success=int(winner is None), error=error)


def main():
    assert sys.argv[1:] in ([], ['--verify-saved'])
    plan, vectors = PREPARE.build()
    assert plan == load(BASE / 'plan.json') and vectors == load(BASE / 'flow-vectors.json')
    names = ('CompositionPlan.pm', 'DirectoryRead.pm', 'CompositionReports.pm', 'expected_trace.py',
             'prepare.py', 'prepare-pin.json', 'plan.json', 'flow-vectors.json', 'flow-qualify.t', 'preflight.py')
    pins = load(BASE / 'flow-preflight-pins.json'); assert pins == [PREPARE.pin(BASE / n) for n in names]
    storage = BASE / 'result/preflight' if sys.argv[1:] else LOG
    report = load(storage / 'flow-qualification.json')
    assert set(report) == {'schema', 'success', 'prospective_pins', 'variants', 'controls', 'allocated', 'forbidden_process_attempts'}
    assert report['schema'] == 'fsmgen.release_composition_binding_qualification.v1' and report['success'] is True
    assert report['prospective_pins'] == pins and report['allocated'] == [] and report['forbidden_process_attempts'] == 0
    observed = []; predictions = []; witnesses = {}
    error_text = {k: os.strerror(getattr(errno, k)) for k in ('EIO', 'ENOSPC')}
    for profile in vectors['profiles']:
        for variant in profile['variants']:
            summaries = []
            for recipe, resolved in zip(profile['recipes'], variant['expected'], strict=True):
                assert resolved == PREPARE.resolve(variant['calls'], profile['context'], plan['sealed_symbols'], recipe)
                actual = TRACE.derive(variant['calls'], profile['context'], plan['sealed_symbols'], resolved, error_text)
                expected = reference(variant['calls'], profile['context'], plan['sealed_symbols'], resolved)
                assert actual == expected, (profile['profile'], variant['name'], recipe)
                summaries.append(signature(actual))
                witnesses.setdefault(recipe['kind'], (actual, expected))
            observed.append(dict(profile=profile['profile'], name=variant['name'], resolved=len(variant['expected']),
                resolution_sha256=signature(variant['expected']), inputs_unchanged=1))
            predictions.append(dict(profile=profile['profile'], variant=variant['name'],
                predictions=len(summaries), sha256=signature(summaries)))
    assert report['variants'] == observed
    diagnostics = [('missing kind', 'composition recipe fields differ'),
        ('stale numeric call', 'composition recipe fields differ'),
        ('structured kind', 'composition recipe text is missing or structured'),
        ('missing order', 'composition recipe text is missing or structured'),
        ('unknown order', 'unknown composition declaration order'),
        ('missing scope', 'composition scope is missing or structured'),
        ('structured scope', 'composition scope is missing or structured'),
        ('foreign scope', 'unknown composition kind or scope'),
        ('foreign kind', 'unknown composition kind or scope'),
        ('scoped healthy', 'healthy composition carries a scope or order')]
    assert report['controls'] == [dict(name=n, returned=0, error=e + '\n') for n, e in diagnostics]
    assertions = 2 * len(observed) + 2 * len(diagnostics) + 1
    tap = (storage / 'flow-qualify.tap').read_text()
    assert re.findall(r'^ok ([0-9]+) - ', tap, re.M) == [str(i) for i in range(1, assertions + 1)]
    assert re.findall(r'^1\.\.([0-9]+)$', tap, re.M) == [str(assertions)]
    assert not re.search(r'^(not ok|Bail out!)|#\s*(skip|todo)\b', tap, re.M | re.I)
    assert (storage / 'flow-qualify.exit').read_bytes() == b'0\n'
    controls = []
    for name, kind, mutate in (
        ('lost-close', 'group', lambda r: r['events'].pop(-2)),
        ('declaration-order-winner', 'group', lambda r: r.update(error='wrong winner\n')),
        ('masked-primary', 'source-primary', lambda r: r.update(error='cleanup replaced primary\n')),
        ('lost-directory-primary', 'directory-primary', lambda r: r.update(directory_primary_hits=0)),
        ('invented-primary', 'healthy', lambda r: r.update(injected_hits=1)),
        ('lost-owner', 'group', lambda r: r['handles'].pop()),
        ('wrong-errno', 'group', lambda r: next(x for x in r['reports'] if x['applied']).update(errno='SUCCESS')),
        ('lost-unlink', 'healthy', lambda r: r['effects'].update(unlink_completed=0)),
        ('lost-absence', 'healthy', lambda r: r['effects'].update(last_reference_check=None)),
        ('lost-report-hit', 'group', lambda r: r['reported_error_addresses'].pop()),
        ('false-success', 'source-primary', lambda r: r.update(success=1)),
    ):
        actual, expected = witnesses[kind]; changed = copy.deepcopy(actual); mutate(changed)
        assert changed != expected, name; controls.append(name)
    result = dict(schema='fsmgen.release_ordinary_composition_preflight.v1', success=True,
        prospective_pins=pins, variants=predictions, pure_assertions=assertions,
        predictions=sum(p['predictions'] for p in predictions), falsifiers=controls,
        errno_constants={k: getattr(errno, k) for k in error_text}, errno_text=error_text,
        scope='Pure current-flow Perl resolution and recursive error/cleanup predictions match independent '
              'interval selection and unchanged call/single-close interpreters or directory lifetime cuts. '
              'No fixture or actual read/close control executes.')
    if sys.argv[1:]:
        assert load(BASE / 'result/preflight/preflight.json') == result
    else:
        with (LOG / 'preflight.json').open('x') as stream:
            stream.write(json.dumps(result, sort_keys=True, indent=2) + '\n')
    print(json.dumps({k: v for k, v in result.items() if k not in ('prospective_pins', 'variants')}, sort_keys=True))


if __name__ == '__main__':
    main()
