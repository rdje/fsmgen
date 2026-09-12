"""Recount the published active-runtime coverage from saved per-case observations."""
import hashlib
import importlib.util
import json
from pathlib import Path
import re

BASE = Path(__file__).resolve().parent
ROOT = BASE.parents[2]
BOOK = ROOT / 'docs/book/src/16dc-vial-portable-verilator-runtime-measurement.md'


def phrase(cases, healthy, failures, assertions):
    return (f'Active-runtime release close qualification covers {cases} cases: {healthy} healthy control '
            f'and {failures} single EIO reports, with {assertions} TAP assertions.')


def main():
    load = lambda path: json.loads(path.read_bytes())
    spec = importlib.util.spec_from_file_location('active_close_book_audit', BASE / 'audit.py')
    audit = importlib.util.module_from_spec(spec); spec.loader.exec_module(audit)
    assert load(BASE / 'book-claim-pins.json') == [audit.PREPARE.pin(BASE / n)
        for n in ('verify_book_claims.py', 'book-claim-selection.json')]
    plan = load(BASE / 'plan.json'); audit.domain(plan)
    pins = audit.authenticate(plan)
    report = load(BASE / 'result/qualification.json'); audit.header(plan, report, pins)
    healthy = failures = 0
    for case, receipt in zip(plan['cases'], report['case_files'], strict=True):
        row = audit.SUPPORT.read_case(BASE / 'result', receipt)
        audit.ACTIVE.active_state(row)
        operation = row['operation']
        assert row['matrix_case'] == case and row['roots_absent'] is True
        assert operation['result']['success'] == int(not case['reports'])
        assert operation['modeled_close_hits'] == len(case['reports'])
        assert all(h['actual_close_ok'] == h['closed_after_call'] == h['closed_at_return'] == 1
                   for h in operation['handles'])
        healthy += operation['result']['success']
        failures += 1 - operation['result']['success']
    tap = (BASE / 'result/qualify.tap').read_text()
    assertions = len(re.findall(r'^ok [0-9]+(?: |$)', tap, re.M))
    audit.SUPPORT.tap(BASE / 'result/qualify.tap', assertions)
    result = load(BASE / 'result/audit.json')
    counts = (len(plan['cases']), healthy, failures, assertions)
    assert result['success'] is True
    assert counts == (result['totals']['cases'], result['totals']['healthy'],
                      result['totals']['failures'], result['assertions'])
    text = ' '.join(BOOK.read_text().split()); expected = phrase(*counts)
    assert text.count(expected) == 1
    selected, = load(BASE / 'book-claim-selection.json')
    assert selected['excerpt'] == expected and selected['path'] == str(BOOK.relative_to(ROOT))
    assert selected['source_line_sha256'] == hashlib.sha256(expected.encode()).hexdigest()
    records = [json.loads(r) for r in
        (ROOT / 'doctrine/claim_verification/dispositions.jsonl').read_text().splitlines()[1:]]
    disposition, = [r for r in records if r['candidate_id'] == selected['candidate_id']]
    assert disposition['disposition'] == 'derived_gate'
    assert str((BASE / 'verify_book_claims.py').relative_to(ROOT)) in disposition['durability']['watcher_paths']
    controls = []
    for index, name in enumerate(('changed-cases', 'changed-healthy', 'changed-failures', 'changed-assertions')):
        changed = list(counts); changed[index] += 1
        assert phrase(*changed) not in text
        controls.append(name)
    assert phrase(counts[0], healthy + 1, failures - 1, assertions) not in text
    controls.append('conserved-total-redistribution')
    print(json.dumps(dict(success=True, cases=counts[0], healthy=healthy, failures=failures,
        assertions=assertions, falsifiers=controls), sort_keys=True))


if __name__ == '__main__':
    main()
