"""Verify equal-reference identities, original omission verdicts and separate recovery."""
from collections import Counter
import copy
import errno
import json
import os
from pathlib import Path
import re
import sys
import importlib.util

BASE = Path(__file__).resolve().parent
ROOT = BASE.parents[2]
LOG = ROOT / '.artifacts/logs' / BASE.name


def module(name, path):
    spec = importlib.util.spec_from_file_location(name, path)
    value = importlib.util.module_from_spec(spec); spec.loader.exec_module(value)
    return value


PREPARE = module('equal_omission_prepare', BASE / 'prepare.py')
# The qualified ordinary auditor imports its adjacent model. Bind that exact
# committed directory before loading it; no original command entrypoint runs.
sys.path.insert(0, str(PREPARE.ORDINARY))
ORDINARY = module('equal_omission_qualified_rows', PREPARE.ORDINARY / 'audit.py')
CORE = ORDINARY.CORE
SUPPORT = ORDINARY.SUPPORT
EQUAL = module('equal_omission_source_identities', PREPARE.EQUAL / 'audit.py')
original_digest = ORDINARY.original_digest
MAIN_NAMES = ['prepare.py', 'source-pins.json', 'plan.json', 'qualify.t', 'audit.py',
    'recover.py', 'recovery-pins.json']


def load(path):
    return json.loads(path.read_bytes())


def verify_row(plan, case, row):
    counts, roots = ORDINARY.verify_row(plan, case, row)
    EQUAL.equal_identities(row, SUPPORT)
    counts['equal_identity_cases'] = 1
    return counts, roots


def domain(plan):
    selection = load(PREPARE.SELECTION / 'plan.json'); profile = selection['profiles'][1]
    assert plan['schema'] == 'fsmgen.release_equal_omission_plan.v1'
    assert plan['owner'] == PREPARE.OWNER == profile['owner']
    assert plan['component'] == BASE.name and plan['source_revision'] == PREPARE.REVISION
    assert plan['profile_id'] == profile['id'] and plan['selection'] == profile['selection']
    assert plan['cases'] == profile['cases']
    for field in ('source_boundaries', 'sealed_symbols', 'omission_contract', 'observation_contract', 'recovery_contract'):
        assert plan[field] == selection[field]
    assert plan['previous_root_reports'] == selection['previous_root_reports'] + [
        str((PREPARE.ORDINARY / 'result/qualification.json').relative_to(ROOT))]


def prerequisites(plan):
    original = load(PREPARE.ORDINARY / 'plan.json')
    ORDINARY.domain(original)
    pins = load(PREPARE.ORDINARY / 'preflight-pins.json')
    assert pins == [PREPARE.pin(PREPARE.ORDINARY / name) for name in ORDINARY.MAIN_NAMES]
    inherited = ORDINARY.prerequisites(original)
    recovery = module('equal_omission_ordinary_recovery', PREPARE.ORDINARY / 'recover.py')
    records = load(PREPARE.ORDINARY / 'result/recovery-copies.json')
    assert records == load(PREPARE.ORDINARY / 'result/recovery-plan.json')
    recovery.verify(records)
    assert load(PREPARE.ORDINARY / 'result/audit.json')['success'] is True
    assert load(PREPARE.ORDINARY / 'result/qualification.json')['success'] is True
    return dict(binding=inherited, ordinary_copies=len(records), ordinary_pins=len(pins))


def header(plan, report, pins):
    assert set(report) == {'schema', 'success', 'prospective_pins', 'cases', 'case_files', 'allocated',
        'caller_controls', 'current_case', 'forbidden_process_attempts', 'errno_constants', 'errno_text'}
    assert report['schema'] == 'fsmgen.release_equal_omission_qualification.v1' and report['success'] is True
    assert report['prospective_pins'] == pins and report['forbidden_process_attempts'] == 0
    assert report['cases'] == [] and report['current_case'] is None
    assert report['errno_constants'] == dict(EIO=errno.EIO) and report['errno_text'] == dict(EIO=os.strerror(errno.EIO))
    SUPPORT.caller_controls(plan, report['caller_controls'])
    assert len(report['case_files']) == len(plan['cases'])
    for case, receipt in zip(plan['cases'], report['case_files'], strict=True):
        assert set(receipt) == {'index', 'name', 'path', 'size_bytes', 'sha256'}
        assert receipt['index'] == case['index'] and receipt['name'] == case['name']
        assert receipt['path'] == '.artifacts/logs/' + BASE.name + '/cases/case-%04d.json' % case['index']
        assert type(receipt['size_bytes']) is int and receipt['size_bytes'] > 0
        assert re.fullmatch('[0-9a-f]{64}', receipt['sha256'])


def main():
    assert sys.argv[1:] in ([], ['--verify-saved'], ['--admit-only'])
    plan = load(BASE / 'plan.json'); domain(plan); assert plan == PREPARE.build()
    pins = load(BASE / 'preflight-pins.json'); assert pins == [PREPARE.pin(BASE / n) for n in MAIN_NAMES]
    prerequisite = prerequisites(plan)
    if sys.argv[1:] == ['--admit-only']:
        print(json.dumps(dict(admitted=True, pins=len(pins), inputs=len(plan['inputs']), prerequisites=prerequisite, new_fixture_roots=0), sort_keys=True)); return
    storage = BASE / 'result' if sys.argv[1:] else LOG
    report = load(storage / 'qualification.json'); header(plan, report, pins)
    totals = Counter(); roots = []; witnesses = {}
    for case, receipt in zip(plan['cases'], report['case_files'], strict=True):
        row = SUPPORT.read_case(storage, receipt); counts, allocated = verify_row(plan, case, row)
        totals.update(counts); roots.extend(allocated)
        kind = case['recipe']['handle_kind'] if case['recipe']['kind'] == 'omit' else 'healthy'
        witnesses.setdefault(kind, (case, row))
    assert report['allocated'] == roots
    assert [json.loads(r) for r in (storage / 'admission.jsonl').read_text().splitlines()] == roots
    paths = [r['path'] for r in roots]; assert len(paths) == len(set(paths))
    previous = [r['path'] for path in plan['previous_root_reports'] for r in load(ROOT / path)['allocated']]
    assert len(previous) == len(set(previous)) and not set(paths) & set(previous)
    for path in paths + previous:
        relative = Path(path); assert not relative.is_absolute() and '..' not in relative.parts and path.startswith('.artifacts/')
        assert not (ROOT / path).exists() and not (ROOT / path).is_symlink()
    assert {p.name for p in (storage / 'cases').iterdir()} == {'case-%04d.json' % c['index'] for c in plan['cases']}
    assertions = 25 + 14 * len(plan['cases']); SUPPORT.tap(storage / 'qualify.tap', assertions)
    assert (storage / 'qualify.exit').read_bytes() == b'0\n'
    controls = []
    def omitted(row):
        return next(h for h in row['operation']['handles'] if 'actual_close_performed' in h)
    changes = [
        ('source-closure-rewritten', 'source', lambda r: omitted(r).update(closed_at_return=1)),
        ('lock-closure-rewritten', 'lock', lambda r: omitted(r).update(actual_close_ok=1)),
        ('directory-closure-rewritten', 'directory', lambda r: omitted(r).update(actual_close_performed=1)),
        ('missing-native-witness', 'source', lambda r: r['omission']['open_witnesses'].clear()),
        ('wrong-native-inode', 'source', lambda r: r['omission']['open_witnesses'][0].update(inode=7)),
        ('wrong-retained-object', 'lock', lambda r: r['omission']['open_witnesses'][0].update(object_address=7)),
        ('unclosed-observer-duplicate', 'directory', lambda r: r['omission']['open_witnesses'][0].update(observer_closed=0)),
        ('duplicate-recovery', 'source', lambda r: r['omission']['observer_recovery'].append(copy.deepcopy(r['omission']['observer_recovery'][0]))),
        ('wrong-recovery-object', 'source', lambda r: r['omission']['observer_recovery'][0].update(object_address=7)),
        ('wrong-recovery-primitive', 'directory', lambda r: r['omission']['observer_recovery'][0].update(primitive='CORE::close')),
        ('failed-recovery-return', 'lock', lambda r: r['omission']['observer_recovery'][0].update(actual_return=0)),
        ('recovery-still-open', 'source', lambda r: r['omission']['observer_recovery'][0].update(closed_after=0)),
        ('lost-original-snapshot', 'source', lambda r: r['omission'].update(original_sha256_after_recovery='0'*64)),
        ('hidden-observer-error', 'source', lambda r: r['omission']['observer_errors'].append('failed witness')),
        ('wrong-current-binding', 'source', lambda r: r['prospective']['resolved'][0].update(label='source:99999')),
        ('missing-call', 'healthy', lambda r: r['operation']['boundary_calls'].pop()),
        ('lost-original-unlink', 'source', lambda r: r['operation']['result'].update(unlink_completed=0)),
        ('changed-other-owner', 'healthy', lambda r: r['operation']['after']['store'].pop('coordination.lock')),
        ('native-authority', 'source', lambda r: r['operation']['result'].update(runtime_authorized=1)),
        ('collapsed-equal-source', 'healthy', lambda r: r['archive_receipt']['source_bindings'][1].update(source=copy.deepcopy(r['archive_receipt']['source_bindings'][0]['source']))),
        ('lost-shared-archive', 'healthy', lambda r: r['archive_receipt']['source_bindings'][1]['archive'].update(inode=7)),
        ('ordinary-wrapper-claimed', 'healthy', lambda r: r['selection'].update(wrapper='ordinary')),
    ]
    for name, kind, change in changes:
        case, original = witnesses[kind]; changed = copy.deepcopy(original); change(changed)
        # Structural native-closure controls remain bad even with coherent
        # snapshot digests; their rejection cannot rely on a stale checksum.
        if name.endswith('closure-rewritten'):
            digest = original_digest(changed['operation'])
            changed['omission'].update(original_sha256_before_recovery=digest, original_sha256_after_recovery=digest)
        assert CORE.rejects(lambda: verify_row(plan, case, changed)), name
        controls.append(name)
    domain_controls = []
    for name, mutate in [('missing-case', lambda p: p['cases'].pop()),
                         ('repeated-case', lambda p: p['cases'].append(copy.deepcopy(p['cases'][1]))),
                         ('foreign-scope', lambda p: p['cases'][1]['recipe'].update(scope='foreign'))]:
        changed = copy.deepcopy(plan); mutate(changed); assert CORE.rejects(lambda: domain(changed)); domain_controls.append(name)
    header_controls = []
    for name, mutate in [('missing-pin', lambda r: r['prospective_pins'].pop()),
                         ('missing-case-receipt', lambda r: r['case_files'].pop()),
                         ('invented-process', lambda r: r.update(forbidden_process_attempts=1))]:
        changed = copy.deepcopy(report); mutate(changed); assert CORE.rejects(lambda: header(plan, changed, pins)); header_controls.append(name)
    result = dict(schema='fsmgen.release_equal_omission_audit.v1', success=True, totals=dict(totals), assertions=assertions,
        source_revision=plan['source_revision'], prospective_pins=pins, prerequisites=prerequisite,
        row_falsifiers=controls, domain_falsifiers=domain_controls, header_falsifiers=header_controls,
        new_roots_absent=len(paths), prior_roots_absent=len(previous), scope=plan['scope'])
    if sys.argv[1:]:
        assert result == load(storage / 'audit.json')
    else:
        with (LOG / 'audit.json').open('x') as stream:
            stream.write(json.dumps(result, sort_keys=True, indent=2) + '\n')
    print(json.dumps({k:v for k,v in result.items() if k != 'prospective_pins'}, sort_keys=True))


if __name__ == '__main__':
    main()
