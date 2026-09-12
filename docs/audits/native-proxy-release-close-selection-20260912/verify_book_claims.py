"""Watch prospective book counts against the original healthy handle roster."""
import copy
import hashlib
import importlib.util
import json
from pathlib import Path

BASE = Path(__file__).resolve().parent
ROOT = BASE.parents[2]
BOOK = ROOT / 'docs/book/src/16dc-vial-portable-verilator-runtime-measurement.md'


def phrase(reports, healthy):
    return f'The release close-report plan selects {reports} individual close reports and {healthy} healthy controls across the existing profiles; fault execution remains pending.'


def main():
    load = lambda path: json.loads(path.read_bytes())
    spec = importlib.util.spec_from_file_location('close_claim_preparation', BASE / 'prepare.py')
    prepare = importlib.util.module_from_spec(spec); spec.loader.exec_module(prepare)
    assert load(BASE / 'book-claim-pins.json') == [prepare.pin(BASE / n)
        for n in ('verify_book_claims.py', 'book-claim-selection.json')]
    plan = load(BASE / 'plan.json'); assert plan == prepare.build()
    original = load(prepare.BOUNDARY / 'result/qualification.json')
    reports = 0
    for row in original['cases']:
        op = row['operation']; labels = [h['label'] for h in op['handles']]
        assert len(labels) == len(set(labels))
        for h in op['handles']:
            assert h['actual_close_ok'] == h['closed_after_call'] == h['closed_at_return'] == 1
            assert op['events'].count('close:' + h['label'] + ':before') == 1
            reports += 1
    healthy = len(original['cases'])
    assert sum(len(p['selectors']) for p in plan['profiles']) == reports
    assert sum(c['name'] == 'healthy' for p in plan['profiles'] for c in p['cases']) == healthy
    audit = load(BASE / 'result/audit.json')
    assert audit['success'] is True and audit['prospective_selectors'] == reports
    assert audit['proposed_cases'] == reports + healthy and audit['close_controls_executed'] == 0
    text = ' '.join(BOOK.read_text().split()); expected = phrase(reports, healthy)
    assert text.count(expected) == 1
    selected, = load(BASE / 'book-claim-selection.json')
    assert selected['excerpt'] == expected and selected['path'] == str(BOOK.relative_to(ROOT))
    assert selected['source_line_sha256'] == hashlib.sha256(expected.encode()).hexdigest()
    records = [json.loads(r) for r in (ROOT / 'doctrine/claim_verification/dispositions.jsonl').read_text().splitlines()[1:]]
    disposition, = [r for r in records if r['candidate_id'] == selected['candidate_id']]
    assert disposition['disposition'] == 'derived_gate'
    assert str((BASE / 'verify_book_claims.py').relative_to(ROOT)) in disposition['durability']['watcher_paths']
    for r, h in ((reports + 1, healthy), (reports, healthy + 1), (reports - 1, healthy + 1)):
        assert phrase(r, h) not in text
    print(json.dumps(dict(success=True, planned_reports=reports, planned_healthy_controls=healthy,
        executed_close_controls=0, falsifiers=['changed-reports', 'changed-healthy', 'conserved-total-redistribution']), sort_keys=True))


if __name__ == '__main__':
    main()
