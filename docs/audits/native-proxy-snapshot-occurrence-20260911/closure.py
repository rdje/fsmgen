"""Authenticate and rederive prerequisite receipts without rerunning old fixtures."""
from __future__ import annotations

import hashlib
import json

from audit import BASE, ROOT, LOG, PLAN, FRESH, module, equal, validate

CLOSE = module('occurrence_prior_close', BASE.parent/'native-proxy-observation-semantic-close-20260911/audit.py')
SEM, COORD, SNAPSHOT = CLOSE.SEM, CLOSE.COORD, CLOSE.SNAPSHOT


def authenticate(base, names: list[str]) -> int:
    manifest = json.loads((base/'result/recovery-copies.json').read_bytes())
    records = {row['destination']: row for row in manifest['files']}
    for name in names:
        path = base/'result'/name; row = records[str(path.relative_to(ROOT))]
        raw = path.read_bytes()
        assert len(raw) == row['size_bytes'] and hashlib.sha256(raw).hexdigest() == row['sha256']
    return len(names)


def main() -> None:
    current = json.loads((LOG/'qualification.json').read_bytes())
    validate(current, PLAN.build())
    assert FRESH.RUNTIME.tap_count((LOG/'qualify.tap').read_text()) == 345
    pins = json.loads((LOG/'preflight-pins.json').read_bytes())
    for pin in pins:
        raw = (ROOT/pin['path']).read_bytes()
        assert len(raw) == pin['size_bytes'] and hashlib.sha256(raw).hexdigest() == pin['sha256']
    paths = [row['path'] for row in current['allocated']]
    prior = {}; authenticated = 0
    names = ['qualification.json', 'admission.jsonl', 'rows.jsonl', 'progress.json',
             'qualify.tap', 'qualify.stderr', 'closure.json']
    authenticated += authenticate(CLOSE.BASE, names)
    CLOSE.LOG = CLOSE.BASE/'result'
    close_reports = json.loads((CLOSE.LOG/'qualification.json').read_bytes())
    CLOSE.validate(close_reports, CLOSE.PLAN.build())
    equal([json.loads(line) for line in (CLOSE.LOG/'rows.jsonl').read_text().splitlines()],
          [dict(category=c, row=r) for c in ('cases', 'mutants') for r in close_reports[c]])
    equal(json.loads((CLOSE.LOG/'progress.json').read_bytes()),
          dict(schema='fsmgen.inactive_semantic_close_progress.v1', success=True,
               allocations=len(close_reports['allocated']), cases=len(close_reports['cases']),
               mutants=len(close_reports['mutants']), forbidden_process_attempts=0))
    assert FRESH.RUNTIME.tap_count((CLOSE.LOG/'qualify.tap').read_text()) == 323
    paths.extend(row['path'] for row in close_reports['allocated'])
    prior['semantic_close'] = dict(executed=False, archived_assertions=323, allocations=len(close_reports['allocated']))
    authenticated += authenticate(SEM.BASE, names)
    SEM.LOG = SEM.BASE/'result'
    semantic = json.loads((SEM.LOG/'qualification.json').read_bytes())
    SEM.validate(semantic, SEM.PLAN.build())
    equal([json.loads(line) for line in (SEM.LOG/'rows.jsonl').read_text().splitlines()],
          [dict(category=c, row=r) for c in ('cases', 'mutants') for r in semantic[c]])
    equal(json.loads((SEM.LOG/'progress.json').read_bytes()),
          dict(schema='fsmgen.inactive_semantic_cut_progress.v1', success=True,
               allocations=len(semantic['allocated']), cases=len(semantic['cases']),
               mutants=len(semantic['mutants']), forbidden_process_attempts=0))
    assert FRESH.RUNTIME.tap_count((SEM.LOG/'qualify.tap').read_text()) == 655
    paths.extend(row['path'] for row in semantic['allocated'])
    prior['semantic_calls'] = dict(executed=False, archived_assertions=655, allocations=len(semantic['allocated']))
    authenticated += authenticate(COORD.BASE, names)
    COORD.LOG = COORD.BASE/'result'
    coordinator = json.loads((COORD.LOG/'qualification.json').read_bytes())
    COORD.validate(coordinator, COORD.PLAN.build())
    equal([json.loads(line) for line in (COORD.LOG/'rows.jsonl').read_text().splitlines()],
          [dict(category=c, row=r) for c in ('cases', 'mutants') for r in coordinator[c]])
    equal(json.loads((COORD.LOG/'progress.json').read_bytes()),
          dict(schema='fsmgen.inactive_coordinator_cut_progress.v1', success=True,
               allocations=len(coordinator['allocated']), cases=len(coordinator['cases']),
               mutants=len(coordinator['mutants']), forbidden_process_attempts=0))
    assert FRESH.RUNTIME.tap_count((COORD.LOG/'qualify.tap').read_text()) == 249
    paths.extend(row['path'] for row in coordinator['allocated'])
    prior['coordinator'] = dict(executed=False, archived_assertions=249, allocations=len(coordinator['allocated']))
    for short, directory in [('namespace', 'native-proxy-namespace-reader-20260911'),
                             ('members', 'native-proxy-image-members-20260911')]:
        oracle = module('coordinator_prior_'+short, BASE.parent/directory/'audit.py')
        oracle.LOG = oracle.BASE/'result'
        authenticated += authenticate(oracle.BASE,
            ['qualification.json', 'qualification-admission.jsonl', 'qualification.tap'])
        raw = (oracle.BASE/'plan.json').read_bytes()
        assert hashlib.sha256(raw).hexdigest() == oracle.PLAN_SHA
        result = json.loads((oracle.LOG/'qualification.json').read_bytes())
        oracle.validate(result, json.loads(raw), 'qualification')
        assert FRESH.RUNTIME.tap_count((oracle.LOG/'qualification.tap').read_text()) == 29
        paths.extend(row['path'] for row in result['allocated'])
        prior[short] = dict(executed=False, archived_assertions=29, allocations=len(result['allocated']))
    latest = BASE.parent/'native-proxy-image-members-20260911'
    names = ['qualification.json', 'admission.jsonl', 'rows.jsonl', 'progress.json',
             'qualify.tap', 'qualify.stderr', 'execution.json']
    authenticated += authenticate(latest, ['snapshot-regression/'+name for name in names])
    SNAPSHOT.LOG = latest/'result/snapshot-regression'
    result = json.loads((SNAPSHOT.LOG/'qualification.json').read_bytes())
    SNAPSHOT.validate(result, SNAPSHOT.PLAN.build())
    equal([json.loads(line) for line in (SNAPSHOT.LOG/'rows.jsonl').read_text().splitlines()],
          [dict(category=c, row=r) for c in ('cases', 'mutants') for r in result[c]])
    equal(json.loads((SNAPSHOT.LOG/'progress.json').read_bytes()),
          dict(schema='fsmgen.inactive_snapshot_cut_progress.v1', success=True,
               allocations=len(result['allocated']), cases=len(result['cases']),
               mutants=len(result['mutants']), forbidden_process_attempts=0))
    assert json.loads((SNAPSHOT.LOG/'execution.json').read_bytes())['exit_code'] == 0
    assert FRESH.RUNTIME.tap_count((SNAPSHOT.LOG/'qualify.tap').read_text()) == 345
    paths.extend(row['path'] for row in result['allocated'])
    prior['snapshot'] = dict(executed=False, archived_assertions=345, allocations=len(result['allocated']))
    assert len(paths) == len(set(paths))
    assert all(not (ROOT/path).exists() and not (ROOT/path).is_symlink() for path in paths)
    report = dict(schema='fsmgen.inactive_observation_snapshot_occurrence_closure.v1', success=True,
        current_assertions=345, current_allocations=len(current['allocated']),
        prospective_inputs_unchanged=len(pins), authenticated_prerequisite_copies=authenticated,
        prior=prior, total_roots=len(paths), all_rosters_disjoint_and_absent=True,
        limits='Prerequisites are authenticated and rederived from their committed receipts without rerunning fixtures or rewriting ignored results. Current snapshot selectors uniquely distinguish initial and closure directory checks, covering the four previously untested later occurrences. The archived snapshot pass is rederived only under its authentic weaker historical oracle; history.json explicitly records its selector aliases and reduced coverage. Remaining close reports, the final acquisition join, aggregate-reader internals, asynchronous crashes and native ownership remain unqualified.')
    (LOG/'closure.json').write_text(json.dumps(report, sort_keys=True, indent=2)+'\n')
    print(json.dumps(report, sort_keys=True))


if __name__ == '__main__':
    main()
