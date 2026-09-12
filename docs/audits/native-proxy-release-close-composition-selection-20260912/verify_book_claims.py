"""Independently count the prospectively selected book claim and reject drift."""
from collections import Counter
import copy
import hashlib
import json
from pathlib import Path

BASE = Path(__file__).resolve().parent
ROOT = BASE.parents[2]
BOOK = ROOT / 'docs/book/src/16dc-vial-portable-verilator-runtime-measurement.md'


def phrase(total, healthy, grouped, primary):
    return (f'The release composition plan selects {total} cases: {healthy} healthy controls, '
            f'{grouped} grouped-close cases and {primary} primary-error cases; execution remains pending.')


def count(plan):
    counts = Counter()
    for profile in plan['profiles']:
        assert len({json.dumps(c['recipe'], sort_keys=True) for c in profile['cases']}) == len(profile['cases'])
        for case in profile['cases']:
            kind = case['recipe']['kind']; baseline = case['baseline']
            if kind == 'healthy':
                assert baseline['reports'] == [] and baseline['primary'] is None and baseline['winner'] is None
                counts['healthy'] += 1
            elif kind == 'group':
                assert len(baseline['reports']) > 1 and baseline['primary'] is None
                assert {r['errno'] for r in baseline['reports']} == {'EIO', 'ENOSPC'}
                counts['grouped'] += 1
            else:
                assert kind in ('source-primary', 'directory-primary', 'milestone-primary')
                assert baseline['primary'] is not None and baseline['reports']
                counts['primary'] += 1
            counts['total'] += 1
    assert counts['total'] == counts['healthy'] + counts['grouped'] + counts['primary']
    return dict(counts)


def main():
    load = lambda p: json.loads(p.read_bytes())
    expected_pins = []
    for name in ('verify_book_claims.py', 'book-claim-selection.json'):
        path = BASE / name; raw = path.read_bytes()
        expected_pins.append(dict(path=str(path.relative_to(ROOT)), size_bytes=len(raw), sha256=hashlib.sha256(raw).hexdigest()))
    assert load(BASE / 'book-claim-pins.json') == expected_pins
    plan = load(BASE / 'plan.json'); result = load(BASE / 'result/audit.json')
    counts = count(plan)
    assert result['success'] is True and result['proposed_cases'] == counts['total']
    assert result['close_controls_executed'] == result['directory_controls_executed'] == result['new_fixture_roots'] == 0
    for category, kinds in [('healthy', ['healthy']), ('grouped', ['group']),
                            ('primary', ['source-primary', 'directory-primary', 'milestone-primary'])]:
        assert counts[category] == sum(p['recipes'].get(k, 0) for p in result['profiles'] for k in kinds)
    text = ' '.join(BOOK.read_text().split()); expected = phrase(**counts)
    assert text.count(expected) == 1
    selection, = load(BASE / 'book-claim-selection.json')
    assert selection['excerpt'] == expected and selection['path'] == str(BOOK.relative_to(ROOT))
    assert selection['source_line_sha256'] == hashlib.sha256(expected.encode()).hexdigest()
    records = [json.loads(line) for line in (ROOT / 'doctrine/claim_verification/dispositions.jsonl').read_text().splitlines()[1:]]
    disposition, = [r for r in records if r['candidate_id'] == selection['candidate_id']]
    assert disposition['disposition'] == 'derived_gate'
    assert str((BASE / 'verify_book_claims.py').relative_to(ROOT)) in disposition['durability']['watcher_paths']
    controls = []
    for key in ('total', 'healthy', 'grouped', 'primary'):
        changed = dict(counts); changed[key] += 1
        assert phrase(**changed) not in text; controls.append('changed-' + key)
    changed = dict(counts); changed['grouped'] -= 1; changed['primary'] += 1
    assert phrase(**changed) not in text; controls.append('conserved-total-redistribution')
    print(json.dumps(dict(success=True, planned=counts, executed_controls=0, falsifiers=controls), sort_keys=True))


if __name__ == '__main__':
    main()
