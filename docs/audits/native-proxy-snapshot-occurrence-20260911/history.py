"""Authenticate the historical pass and independently expose occurrence aliases."""
from __future__ import annotations

from collections import Counter
import hashlib
import json
import subprocess

from audit import BASE, ROOT, LOG, FRESH, module, equal


def main():
    old = BASE.parent/'native-proxy-observation-snapshot-cuts-20260910'
    latest = BASE.parent/'native-proxy-image-members-20260911'
    manifest = json.loads((latest/'result/recovery-copies.json').read_bytes())
    by_path = {row['destination']:row for row in manifest['files']}
    copies = []
    for name in ('qualification.json', 'admission.jsonl', 'rows.jsonl', 'progress.json',
                 'qualify.tap', 'qualify.stderr', 'execution.json'):
        path = latest/'result/snapshot-regression'/name
        row = by_path[str(path.relative_to(ROOT))]; raw = path.read_bytes()
        assert len(raw) == row['size_bytes'] and hashlib.sha256(raw).hexdigest() == row['sha256']
        copies.append(row)
    pins = []
    for name in ('plan.py', 'plan.json', 'qualify.t', 'audit.py'):
        path = old/name; raw = path.read_bytes(); relative = str(path.relative_to(ROOT))
        assert raw == subprocess.check_output(['git', 'show', '407851bf7b30d4977dd49518fc2d350c4269d02e:'+relative], cwd=ROOT)
        pins.append(dict(path=relative, size_bytes=len(raw), sha256=hashlib.sha256(raw).hexdigest()))
    oracle = module('historical_snapshot_occurrences', old/'audit.py')
    oracle.LOG = latest/'result/snapshot-regression'
    plan = json.loads((old/'plan.json').read_bytes())
    result = json.loads((oracle.LOG/'qualification.json').read_bytes())
    equal(plan, oracle.PLAN.build()); oracle.validate(result, plan)
    equal([json.loads(line) for line in (oracle.LOG/'rows.jsonl').read_text().splitlines()],
          [dict(category=c, row=r) for c in ('cases','mutants') for r in result[c]])
    assert FRESH.RUNTIME.tap_count((oracle.LOG/'qualify.tap').read_text()) == 345
    assert json.loads((oracle.LOG/'execution.json').read_bytes())['exit_code'] == 0
    observations = {}
    for route in ('fresh','reuse'):
        events = plan['traces'][route]
        aliases = {name:[i for i,event in enumerate(events) if event == name]
                   for name,count in Counter(events).items() if count > 1}
        assert set(aliases) == {'admit:directory:tools','admit:directory:image'}
        rows = [row for row in result['cases'] if row['route'] == route]
        assert len(rows)-len({row['id'] for row in rows}) == 2
        details = []
        for event,positions in sorted(aliases.items()):
            recorded = [row for row in rows if row['id'] == route+':'+event]
            assert len(positions) == len(recorded) == 2
            for row in recorded:
                equal(row['trace'], events[:positions[0]+1])
                assert 'admit:directories:enter' not in row['trace']
            assert 'admit:directories:enter' in events[:positions[1]+1]
            details.append(dict(event=event, positions_zero_based=positions,
                actual_prefix_lengths=[len(row['trace']) for row in recorded],
                missing_later_prefix_length=positions[1]+1))
        observations[route] = dict(declared_positions=len(events), unique_selectors=len(set(events)),
                                  duplicate_case_ids=2, aliases=details)
    report = dict(schema='fsmgen.snapshot_occurrence_history_audit.v1', success=True,
        historical_assertions=345, historical_allocations=len(result['allocated']),
        historical_all_occurrences_qualified=False, unqualified_later_occurrences=4,
        original_oracle_accepts_historical_result=True, observations=observations,
        authenticated_copies=copies, unchanged_historical_sources=pins,
        limits='The historical TAP pass is authentic but repeats the initial tools/image cut on both routes. Four later directory-closure occurrences lack independent interruption coverage. This diagnoses a test/claim defect, not a reproduced product failure. The original sources and results remain untouched.')
    (LOG/'history.json').write_text(json.dumps(report,indent=2,sort_keys=True)+'\n')
    print(json.dumps(report,sort_keys=True))


if __name__ == '__main__':
    main()
