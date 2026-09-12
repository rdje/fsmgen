"""Verify equal-reference composition reports with unchanged qualified row and identity oracles."""
from collections import Counter
import copy
import errno
import importlib.util
import json
import os
from pathlib import Path
import re
import sys

BASE = Path(__file__).resolve().parent
ROOT = BASE.parents[2]
LOG = ROOT / '.artifacts/logs' / BASE.name


def load(path):
    return json.loads(path.read_bytes())


def module(name, path):
    spec = importlib.util.spec_from_file_location(name, path)
    value = importlib.util.module_from_spec(spec); spec.loader.exec_module(value)
    return value


PREPARE = module('equal_composition_matrix_prepare', BASE / 'prepare.py')
CORE = module('equal_composition_qualified_row_audit', PREPARE.ORDINARY / 'audit.py')
EQUAL = module('equal_composition_original_identity_audit', PREPARE.EQUAL / 'audit.py')
ORACLE = module('equal_composition_baseline_preflight', BASE / 'oracle-preflight.py')
SUPPORT = CORE.SUPPORT
rejects = CORE.rejects
ERROR_TEXT = CORE.ERROR_TEXT
PIN_NAMES = ['plan.json', 'prepare.py', 'prepare-pin.json', 'qualify.t', 'qualifier-pin.json',
    'audit.py', 'oracle-preflight.py', 'oracle-pins.json', 'result/preflight/oracle.json',
    'result/preflight/oracle.stdout', 'result/preflight/oracle.stderr',
    'result/preflight/oracle.exit', 'result/preflight/recovery.json']


def domain(plan):
    original = load(PREPARE.SELECTION / 'plan.json'); selected = original['profiles'][1]
    assert plan['schema'] == 'fsmgen.release_equal_composition_plan.v1'
    assert plan['source_revision'] == PREPARE.REVISION and plan['component'] == BASE.name
    assert plan['owner'] == selected['owner'] and plan['profile_id'] == selected['id']
    assert plan['selection'] == selected['selection']
    assert plan['cases'] == [dict(index=c['index'], name=':'.join(str(c['recipe'][k]) for k in ('kind', 'scope', 'order')),
                                  recipe=c['recipe']) for c in selected['cases']]
    for field in ('report_contract', 'directory_contract', 'source_boundaries', 'sealed_symbols'):
        assert plan[field] == original[field]
    previous = load(PREPARE.ORDINARY / 'plan.json')['previous_root_reports']
    assert plan['previous_root_reports'] == previous + [str((PREPARE.ORDINARY / 'result/qualification.json').relative_to(ROOT))]


def authenticate(plan):
    assert PREPARE.build() == plan
    CORE.authenticate(load(PREPARE.ORDINARY / 'plan.json'))
    assert load(BASE / 'qualifier-pin.json') == PREPARE.pin(BASE / 'qualify.t')
    pins = load(BASE / 'preflight-pins.json')
    assert pins == [PREPARE.pin(BASE / n) for n in PIN_NAMES]
    return pins


def prerequisites(plan):
    directory = BASE / 'result/preflight'
    names = ['oracle.json', 'oracle.stdout', 'oracle.stderr', 'oracle.exit']
    copies = load(directory / 'recovery.json')
    assert [r['destination'] for r in copies] == [str((directory / n).relative_to(ROOT)) for n in names]
    assert [r['source'] for r in copies] == [str((LOG / n).relative_to(ROOT)) for n in names]
    for record in copies:
        assert {k: record[k] for k in ('size_bytes', 'sha256')} == {
            k: PREPARE.pin(ROOT / record['destination'])[k] for k in ('size_bytes', 'sha256')}
    assert (directory / 'oracle.exit').read_bytes() == b'0\n'
    predicted = ORACLE.evaluate(plan)
    assert load(directory / 'oracle.json') == predicted
    assert load(directory / 'oracle.stdout') == ORACLE.summary(predicted)
    assert (directory / 'oracle.stderr').read_bytes() == b''
    return dict(inherited=predicted['inherited'], baseline_predictions=len(predicted['predictions']),
        baseline_falsifiers=len(predicted['falsifiers']), copies=len(copies))

def header(plan, report, pins):
    assert set(report) == {'schema', 'success', 'prospective_pins', 'cases', 'case_files', 'allocated',
        'caller_controls', 'current_case', 'forbidden_process_attempts', 'errno_constants', 'errno_text'}
    assert report['schema'] == 'fsmgen.release_equal_composition_qualification.v1' and report['success'] is True
    assert report['prospective_pins'] == pins and report['forbidden_process_attempts'] == 0
    assert report['cases'] == [] and report['current_case'] is None
    assert report['errno_constants'] == {k: getattr(errno, k) for k in ERROR_TEXT} and report['errno_text'] == ERROR_TEXT
    SUPPORT.caller_controls(plan, report['caller_controls'])
    assert len(report['case_files']) == len(plan['cases'])
    for case, receipt in zip(plan['cases'], report['case_files'], strict=True):
        assert set(receipt) == {'index', 'name', 'path', 'size_bytes', 'sha256'}
        assert receipt['index'] == case['index'] and receipt['name'] == case['name']
        assert receipt['path'] == '.artifacts/logs/' + BASE.name + '/cases/case-%04d.json' % case['index']
        assert type(receipt['size_bytes']) is int and receipt['size_bytes'] > 0
        assert re.fullmatch('[0-9a-f]{64}', receipt['sha256'])


def verify_row(plan, case, row):
    counts, roots = CORE.verify_row(plan, case, row)
    EQUAL.equal_identities(row, SUPPORT)
    counts['equal_identity_cases'] = 1
    return counts, roots


def main():
    assert sys.argv[1:] in ([], ['--verify-saved'], ['--admit-only'])
    plan = load(BASE / 'plan.json'); domain(plan); pins = authenticate(plan)
    prerequisite = prerequisites(plan)
    previous = [r['path'] for p in plan['previous_root_reports'] for r in load(ROOT / p)['allocated']]
    assert len(previous) == len(set(previous))
    for path in previous:
        assert not Path(path).is_absolute() and '..' not in Path(path).parts
        assert not (ROOT / path).exists() and not (ROOT / path).is_symlink()
    if sys.argv[1:] == ['--admit-only']:
        print(json.dumps(dict(admitted=True, pins=len(pins), inputs=len(plan['inputs']),
            prerequisites=prerequisite, previous_roots_absent=len(previous), new_fixture_roots=0), sort_keys=True)); return
    saved = bool(sys.argv[1:]); storage = BASE / 'result' if saved else LOG
    report = load(storage / 'qualification.json'); header(plan, report, pins)
    totals = Counter(); roots = []; witnesses = {}
    for case, receipt in zip(plan['cases'], report['case_files'], strict=True):
        row = SUPPORT.read_case(storage, receipt); counts, allocated = verify_row(plan, case, row)
        totals.update(counts); roots.extend(allocated)
        witnesses.setdefault(case['recipe']['kind'], (case, row))
        if case['recipe']['kind'] == 'group':
            for kind in ('source', 'directory', 'lock'):
                if any(h['kind'] == kind and 'modeled_close_errno' in h for h in row['operation']['handles']):
                    witnesses.setdefault(kind, (case, row))
        if counts['post_unlink_failures']: witnesses['late'] = (case, row)
    assert report['allocated'] == roots
    assert [json.loads(r) for r in (storage / 'admission.jsonl').read_text().splitlines()] == roots
    paths = [r['path'] for r in roots]; assert len(paths) == len(set(paths)) and not set(paths) & set(previous)
    for path in paths:
        assert not Path(path).is_absolute() and '..' not in Path(path).parts
        assert not (ROOT / path).exists() and not (ROOT / path).is_symlink()
    assert {p.name for p in (storage / 'cases').iterdir()} == {'case-%04d.json' % c['index'] for c in plan['cases']}
    assertions = 25 + 13 * len(plan['cases']); SUPPORT.tap(storage / 'qualify.tap', assertions)
    assert (storage / 'qualify.exit').read_bytes() == b'0\n'
    def op(r): return r['operation']
    def modeled(r): return next(h for h in op(r)['handles'] if 'modeled_close_errno' in h)
    def read(r): return op(r)['directory_read_reports'][0]
    changes = [
        ('lost-actual-close', 'group', lambda r: modeled(r).update(actual_close_ok=0)),
        ('open-at-return', 'group', lambda r: modeled(r).update(closed_at_return=0)),
        ('open-lock', 'lock', lambda r: next(h for h in op(r)['handles'] if h['kind'] == 'lock').update(closed_after_call=0)),
        ('lost-directory-observer', 'directory', lambda r: next(h for h in op(r)['handles'] if h['kind'] == 'directory').update(observer_closed=0)),
        ('changed-inode', 'healthy', lambda r: op(r)['handles'][0].update(inode=7)),
        ('lost-modeled-hit', 'group', lambda r: op(r).update(modeled_close_hits=0)),
        ('lost-report-hit', 'group', lambda r: op(r)['reported_error_hits'].pop()),
        ('reversed-hit-order', 'group', lambda r: op(r)['reported_error_hits'].reverse()),
        ('missing-report', 'healthy', lambda r: op(r)['close_reports'].pop()),
        ('false-actual-return', 'group', lambda r: next(x for x in op(r)['close_reports'] if x['report_applied']).update(actual_return=0)),
        ('hidden-reported-error', 'group', lambda r: next(x for x in op(r)['close_reports'] if x['report_applied']).update(reported_return=1)),
        ('wrong-errno', 'group', lambda r: next(x for x in op(r)['close_reports'] if x['report_applied']).update(reported_errno=0)),
        ('invented-call-primary', 'group', lambda r: op(r).update(injected_hits=1)),
        ('lost-call-primary', 'source-primary', lambda r: op(r).update(injected_hits=0)),
        ('lost-close-event', 'healthy', lambda r: op(r)['events'].remove(next(e for e in op(r)['events'] if e.startswith('close:')))),
        ('wrong-caller', 'healthy', lambda r: op(r)['boundary_calls'][0].update(caller='Foreign')),
        ('lost-pending-scope', 'directory-primary', lambda r: op(r)['interrupted_boundary_ids'].clear()),
        ('wrong-current-owner', 'group', lambda r: r['prospective']['resolved']['resolved_reports'][0].update(close_scope='Foreign')),
        ('changed-input', 'healthy', lambda r: r.update(inputs_unchanged=0)),
        ('lost-other-owner', 'healthy', lambda r: op(r)['after']['store'].pop('coordination.lock')),
        ('lost-unlink', 'late', lambda r: op(r)['result'].update(unlink_completed=0)),
        ('lost-absence', 'late', lambda r: op(r)['result'].update(reference_absence_verified=0)),
        ('masked-primary', 'source-primary', lambda r: op(r)['result'].update(error='cleanup replaced primary\n')),
        ('false-success', 'group', lambda r: op(r)['result'].update(success=1)),
        ('native-authority', 'group', lambda r: op(r)['result'].update(runtime_authorized=1)),
        ('missing-directory-read', 'directory-primary', lambda r: op(r)['directory_read_reports'].clear()),
        ('missing-directory-hit', 'directory-primary', lambda r: op(r).update(directory_primary_hits=0)),
        ('foreign-directory-name', 'directory-primary', lambda r: read(r).update(actual_name='foreign/member')),
        ('wrong-directory-inode', 'directory-primary', lambda r: read(r).update(inode=7)),
        ('false-actual-read', 'directory-primary', lambda r: read(r).update(actual_name=None)),
        ('actual-read-error', 'directory-primary', lambda r: read(r).update(actual_errno=errno.EIO)),
        ('successful-reported-read', 'directory-primary', lambda r: read(r).update(reported_name='entry')),
        ('wrong-directory-errno', 'directory-primary', lambda r: read(r).update(reported_errno=errno.ENOSPC)),
        ('masked-directory-primary', 'directory-primary', lambda r: op(r)['result'].update(error='cleanup replaced directory primary\n')),
        ('private-read', 'healthy', lambda r: op(r)['reads'].append(r['context']['workspace']['path'] + '/rust-tool-resolution')),
        ('publication-attempt', 'healthy', lambda r: op(r).update(forbidden_mutation_attempts=1)),
        ('collapsed-equal-source', 'healthy', lambda r: r['archive_receipt']['source_bindings'][1].update(source=copy.deepcopy(r['archive_receipt']['source_bindings'][0]['source']))),
        ('lost-shared-archive', 'healthy', lambda r: r['archive_receipt']['source_bindings'][1]['archive'].update(inode=7)),
        ('ordinary-wrapper-claimed', 'healthy', lambda r: r['selection'].update(wrapper='ordinary')),
    ]
    for name, kind, mutate in changes:
        case, row = witnesses[kind]; changed = copy.deepcopy(row); mutate(changed)
        assert rejects(lambda: verify_row(plan, case, changed)), name
    domain_controls = []
    for name, mutate in [('missing-case', lambda p: p['cases'].pop()),
                         ('duplicate-case', lambda p: p['cases'].append(copy.deepcopy(p['cases'][1]))),
                         ('wrong-recipe', lambda p: p['cases'][1]['recipe'].update(order='foreign'))]:
        changed = copy.deepcopy(plan); mutate(changed); assert rejects(lambda: domain(changed)); domain_controls.append(name)
    header_controls = []
    for name, mutate in [('missing-pin', lambda r: r['prospective_pins'].pop()),
                         ('missing-receipt', lambda r: r['case_files'].pop()),
                         ('invented-process', lambda r: r.update(forbidden_process_attempts=1)),
                         ('wrong-errno', lambda r: r['errno_constants'].update(ENOSPC=0))]:
        changed = copy.deepcopy(report); mutate(changed); assert rejects(lambda: header(plan, changed, pins)); header_controls.append(name)
    result = dict(schema='fsmgen.release_equal_composition_audit.v1', success=True, totals=dict(totals),
        assertions=assertions, source_revision=plan['source_revision'], prospective_pins=pins, input_files=len(plan['inputs']),
        prerequisites=prerequisite, roots_absent=len(paths), prior_roots_absent=len(previous),
        case_bytes=sum(r['size_bytes'] for r in report['case_files']), row_falsifiers=[n for n, _, _ in changes],
        domain_falsifiers=domain_controls, header_falsifiers=header_controls, scope=plan['scope'])
    if saved: assert load(storage / 'audit.json') == result
    else:
        with (storage / 'audit.json').open('x') as stream: stream.write(json.dumps(result, sort_keys=True, indent=2) + '\n')
    print(json.dumps(result, sort_keys=True))


if __name__ == '__main__':
    main()
