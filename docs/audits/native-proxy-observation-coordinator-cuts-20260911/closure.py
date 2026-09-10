"""Authenticate and rederive prerequisite receipts without rerunning old fixtures."""
from __future__ import annotations

import hashlib
import json

from audit import BASE, ROOT, LOG, PLAN, SNAPSHOT, FRESH, module, equal, validate


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
    assert FRESH.RUNTIME.tap_count((LOG/'qualify.tap').read_text()) == 249
    pins = json.loads((LOG/'preflight-pins.json').read_bytes())
    for pin in pins:
        raw = (ROOT/pin['path']).read_bytes()
        assert len(raw) == pin['size_bytes'] and hashlib.sha256(raw).hexdigest() == pin['sha256']
    paths = [row['path'] for row in current['allocated']]
    prior = {}; authenticated = 0
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
    report = dict(schema='fsmgen.inactive_observation_coordinator_cut_closure.v1', success=True,
        current_assertions=249, current_allocations=len(current['allocated']),
        prospective_inputs_unchanged=len(pins), authenticated_prerequisite_copies=authenticated,
        prior=prior, total_roots=len(paths), all_rosters_disjoint_and_absent=True,
        limits='Prerequisites are authenticated and rederived from their committed receipts without rerunning fixtures or rewriting ignored results. Current coordinator cuts execute both full routes but do not qualify semantic-census internal cuts, target/lock close reports, asynchronous crashes or native ownership.')
    (LOG/'closure.json').write_text(json.dumps(report, sort_keys=True, indent=2)+'\n')
    print(json.dumps(report, sort_keys=True))


if __name__ == '__main__':
    main()
