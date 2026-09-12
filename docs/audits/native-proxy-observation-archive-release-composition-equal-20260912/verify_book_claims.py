"""Recount the equal-reference composition book claim from immutable observed cases."""
from collections import Counter
import hashlib
import json
from pathlib import Path
import re

BASE = Path(__file__).resolve().parent
ROOT = BASE.parents[2]
BOOK = ROOT / 'docs/book/src/16dc-vial-portable-verilator-runtime-measurement.md'


def phrase(cases, healthy, grouped, primary, assertions):
    return (f'Equal-reference release composition qualification covers {cases} cases: {healthy} healthy control, '
            f'{grouped} grouped-close cases and {primary} primary-error cases, with {assertions} TAP assertions.')


def read(path):
    assert path.is_relative_to(ROOT)
    for node in [path, *path.parents]:
        if node == ROOT: break
        assert not node.is_symlink() and node.stat().st_dev == ROOT.stat().st_dev
    assert path.is_file()
    return path.read_bytes()


def pin(path):
    raw = read(path)
    return dict(path=str(path.relative_to(ROOT)), size_bytes=len(raw), sha256=hashlib.sha256(raw).hexdigest())


def main():
    load = lambda p: json.loads(read(p))
    assert load(BASE / 'book-claim-pins.json') == [pin(BASE / n)
        for n in ('verify_book_claims.py', 'book-claim-selection.json')]
    pins = load(BASE / 'preflight-pins.json')
    assert next(p for p in pins if p['path'] == str((BASE / 'plan.json').relative_to(ROOT))) == pin(BASE / 'plan.json')
    plan = load(BASE / 'plan.json'); result = load(BASE / 'result/qualification.json')
    assert result['success'] is True and result['prospective_pins'] == pins
    copies = {r['destination']: r for r in load(BASE / 'result/recovery-copies.json')}
    counts = Counter(); counts['cases'] = len(plan['cases'])
    for case, receipt in zip(plan['cases'], result['case_files'], strict=True):
        path = BASE / 'result/cases' / ('case-%04d.json' % case['index']); raw = read(path)
        identity = dict(size_bytes=len(raw), sha256=hashlib.sha256(raw).hexdigest())
        assert identity == {k: receipt[k] for k in identity}
        copy = copies[str(path.relative_to(ROOT))]; assert identity == {k: copy[k] for k in identity}
        row = json.loads(raw); assert row['matrix_case'] == case and row['roots_absent'] is True
        assert row['profile_id'] == plan['profile_id'] and row['selection'] == plan['selection']
        op = row['operation']; kind = case['recipe']['kind']
        assert op['returned'] == 1 and op['all_observed_handles_closed'] == 1
        assert all(h['actual_close_ok'] == h['closed_after_call'] == h['closed_at_return'] == 1 for h in op['handles'])
        if kind == 'healthy':
            assert op['result']['success'] == 1 and op['reported_error_hits'] == []
            counts['healthy'] += 1
        elif kind == 'group':
            assert op['result']['success'] == 0 and len(op['reported_error_hits']) > 1
            assert op['injected_hits'] == op['directory_primary_hits'] == 0
            counts['grouped'] += 1
        else:
            assert kind in ('source-primary', 'directory-primary', 'milestone-primary')
            assert op['result']['success'] == 0 and op['reported_error_hits']
            assert op['injected_hits'] + op['directory_primary_hits'] == 1
            counts['primary'] += 1
    tap = read(BASE / 'result/qualify.tap').decode()
    actual = re.findall(r'^ok ([0-9]+) - ', tap, re.M)
    assert actual == [str(i) for i in range(1, len(actual) + 1)]
    assert re.findall(r'^1\.\.([0-9]+)$', tap, re.M) == [str(len(actual))]
    assert not re.search(r'^(not ok|Bail out!)|#\s*(skip|todo)\b', tap, re.M | re.I)
    counts['assertions'] = len(actual)
    assert read(BASE / 'result/qualify.exit') == b'0\n'
    audit = load(BASE / 'result/audit.json'); assert audit['success'] is True
    assert audit['assertions'] == counts['assertions'] and audit['totals']['cases'] == counts['cases']
    assert audit['totals']['healthy'] == counts['healthy']
    assert audit['totals']['failures'] == counts['grouped'] + counts['primary']
    text = ' '.join(BOOK.read_text().split()); expected = phrase(**counts)
    assert text.count(expected) == 1
    selection, = load(BASE / 'book-claim-selection.json')
    assert selection['path'] == str(BOOK.relative_to(ROOT)) and selection['excerpt'] == expected
    assert selection['source_line_sha256'] == hashlib.sha256(expected.encode()).hexdigest()
    dispositions = [json.loads(l) for l in read(ROOT / 'doctrine/claim_verification/dispositions.jsonl').splitlines()[1:]]
    disposition, = [r for r in dispositions if r['candidate_id'] == selection['candidate_id']]
    assert disposition['disposition'] == 'derived_gate'
    assert str((BASE / 'verify_book_claims.py').relative_to(ROOT)) in disposition['durability']['watcher_paths']
    controls = []
    for key in counts:
        changed = dict(counts); changed[key] += 1
        assert phrase(**changed) not in text; controls.append('changed-' + key)
    changed = dict(counts); changed['grouped'] -= 1; changed['primary'] += 1
    assert phrase(**changed) not in text; controls.append('conserved-total-redistribution')
    print(json.dumps(dict(success=True, observed=dict(counts), falsifiers=controls), sort_keys=True))


if __name__ == '__main__':
    main()
