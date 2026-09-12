"""Recount joined book claims from immutable cases, independently of totals."""
from collections import Counter
import copy
import hashlib
import importlib.util
import json
from pathlib import Path
import re

BASE = Path(__file__).resolve().parent
ROOT = BASE.parents[2]
BOOK = ROOT / 'docs/book/src/16dc-vial-portable-verilator-runtime-measurement.md'


def load(path):
    return json.loads(path.read_bytes())


def phrase(counts):
    return (f"The bounded release-composition join verifies {counts['cases']} cases: "
            f"{counts['healthy']} healthy controls, {counts['grouped']} grouped-close cases and "
            f"{counts['primary']} primary-error cases, with {counts['assertions']:,} original TAP assertions.")


def check(text, counts):
    assert ' '.join(text.split()).count(phrase(counts)) == 1


def main():
    spec = importlib.util.spec_from_file_location('book_join_preparation', BASE / 'prepare.py')
    prepare = importlib.util.module_from_spec(spec); spec.loader.exec_module(prepare)
    assert load(BASE / 'book-claim-pins.json') == [prepare.pin(BASE / n)
        for n in ('verify_book_claims.py', 'book-claim-selection.json')]
    plan = load(BASE / 'plan.json'); assert plan == prepare.build()
    counts = Counter()
    for partition in plan['partitions']:
        directory = ROOT / partition['directory']; current = load(directory / 'plan.json')
        report = load(directory / 'result/qualification.json')
        assert report['success'] is True and report['cases'] == [] and report['current_case'] is None
        for case, receipt in zip(current['cases'], report['case_files'], strict=True):
            raw = prepare.safe_bytes(directory / 'result/cases' / ('case-%04d.json' % receipt['index']))
            assert len(raw) == receipt['size_bytes'] and hashlib.sha256(raw).hexdigest() == receipt['sha256']
            row = json.loads(raw); assert row['matrix_case'] == case and row['roots_absent'] is True
            success = row['operation']['result']['success']; assert type(success) is int and success in (0, 1)
            assert report['forbidden_process_attempts'] == 0
            kind = case['recipe']['kind']
            assert kind in ('healthy', 'group', 'source-primary', 'directory-primary', 'milestone-primary')
            assert success == int(kind == 'healthy')
            assert all(h['actual_close_ok'] == h['closed_after_call'] == h['closed_at_return'] == 1
                       for h in row['operation']['handles'])
            counts['cases'] += 1
            counts['healthy'] += int(kind == 'healthy')
            counts['grouped'] += int(kind == 'group')
            counts['primary'] += int(kind.endswith('-primary'))
        tap = (directory / 'result/qualify.tap').read_text()
        terminal, = re.findall(r'^1\.\.([0-9]+)$', tap, re.M)
        assert re.findall(r'^ok ([0-9]+) - ', tap, re.M) == [str(i) for i in range(1, int(terminal) + 1)]
        assert (directory / 'result/qualify.exit').read_bytes() == b'0\n'
        counts['assertions'] += int(terminal)
    joined = load(BASE / 'result/join.json')
    assert joined['success'] is True and joined['cases'] == counts['cases']
    assert joined['assertions'] == counts['assertions'] and joined['totals']['healthy'] == counts['healthy']
    assert joined['totals']['call_primaries'] + joined['totals']['directory_primaries'] == counts['primary']
    assert counts['cases'] == counts['healthy'] + counts['grouped'] + counts['primary']
    text = BOOK.read_text(); check(text, counts)
    selection, = load(BASE / 'book-claim-selection.json')
    assert selection['excerpt'] == phrase(counts) and selection['path'] == str(BOOK.relative_to(ROOT))
    assert selection['source_line_sha256'] == hashlib.sha256(selection['excerpt'].encode()).hexdigest()
    records = [json.loads(line) for line in (ROOT / 'doctrine/claim_verification/dispositions.jsonl').read_text().splitlines()[1:]]
    disposition, = [r for r in records if r['candidate_id'] == selection['candidate_id']]
    assert disposition['disposition'] == 'derived_gate'
    assert str((BASE / 'verify_book_claims.py').relative_to(ROOT)) in disposition['durability']['watcher_paths']
    falsifiers = []
    for key in counts:
        changed = copy.deepcopy(counts); changed[key] += 1
        assert phrase(changed) not in ' '.join(text.split()); falsifiers.append('changed-' + key)
    changed = copy.deepcopy(counts); changed['grouped'] += 1; changed['primary'] -= 1
    assert phrase(changed) not in ' '.join(text.split()); falsifiers.append('conserved-total-redistribution')
    print(json.dumps(dict(success=True, counts=dict(counts), falsifiers=falsifiers,
        scope='Counts rederived from original saved cases and TAP; no new fixture assertions or old main execution.'), sort_keys=True))


if __name__ == '__main__':
    main()
