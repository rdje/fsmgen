"""Join the last-observation book counts to exact saved cases and TAP.

The behavioral audit independently verifies those cases. This watcher recounts
their actual outcomes and rejects altered numbers, including a redistribution
that conserves the total. No fixture or earlier producer is executed.
"""
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
    return (f"The last-observation partition passes {counts['primary_cases']} primary cases and "
            f"{counts['assertions']:,} assertions: {counts['primary_successes']} releases succeed "
            f"and {counts['primary_rejections']} attempts reject.")


def check_text(text, counts):
    assert ' '.join(text.split()).count(phrase(counts)) == 1


def main():
    pins = load(BASE / 'book-claim-pins.json')
    assert [p['path'] for p in pins] == [str((BASE / n).relative_to(ROOT))
        for n in ('verify_book_claims.py', 'book-claim-selection.json')]
    for pin in pins:
        path = ROOT / pin['path']
        assert not path.is_symlink() and path.stat().st_dev == ROOT.stat().st_dev
        raw = path.read_bytes()
        assert pin == dict(path=pin['path'], size_bytes=len(raw), sha256=hashlib.sha256(raw).hexdigest())
    spec = importlib.util.spec_from_file_location('last_book_behavior_audit', BASE / 'audit.py')
    audit = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(audit)
    plan = load(BASE / 'plan.json')
    audit.domain(plan)
    audit.authenticate(plan)
    report = load(BASE / 'result/qualification.json')
    result = load(BASE / 'result/audit.json')
    assert report['success'] is result['success'] is True
    assert len(report['case_files']) == len(plan['cases'])
    counts = Counter()
    for selected, receipt in zip(plan['cases'], report['case_files'], strict=True):
        path = BASE / 'result/cases' / ('case-%04d.json' % receipt['index'])
        assert not path.is_symlink() and path.stat().st_dev == ROOT.stat().st_dev
        raw = path.read_bytes()
        assert len(raw) == receipt['size_bytes'] and hashlib.sha256(raw).hexdigest() == receipt['sha256']
        row = json.loads(raw)
        assert row['matrix_case'] == selected and row['roots_absent'] is True
        assert selected['role'] == 'primary'
        success = row['operation']['result']['success']
        assert type(success) is int and success in (0, 1)
        counts['primary_cases'] += 1
        counts['primary_successes'] += success
        counts['primary_rejections'] += 1 - success
    tap = (BASE / 'result/qualify.tap').read_text()
    terminal, = re.findall(r'^1\.\.([0-9]+)$', tap, re.M)
    counts['assertions'] = int(terminal)
    assert re.findall(r'^ok ([0-9]+) - ', tap, re.M) == [str(i) for i in range(1, counts['assertions'] + 1)]
    assert (BASE / 'result/qualify.exit').read_bytes() == b'0\n'
    assert all(value == result[key] for key, value in counts.items())
    text = BOOK.read_text()
    check_text(text, counts)
    selection, = load(BASE / 'book-claim-selection.json')
    assert selection['path'] == str(BOOK.relative_to(ROOT)) and selection['excerpt'] == phrase(counts)
    assert hashlib.sha256(selection['excerpt'].encode()).hexdigest() == selection['source_line_sha256']
    dispositions = {d['candidate_id']: d for d in map(json.loads,
        (ROOT / 'doctrine/claim_verification/dispositions.jsonl').read_text().splitlines()[1:])}
    declared = dispositions[selection['candidate_id']]
    assert declared['disposition'] == 'derived_gate'
    assert str((BASE / 'verify_book_claims.py').relative_to(ROOT)) in declared['durability']['watcher_paths']
    falsifiers = []
    for key in counts:
        altered = copy.deepcopy(counts)
        altered[key] += 1
        assert audit.rejects(lambda: check_text(text, altered)), key
        falsifiers.append('changed ' + key)
    altered = copy.deepcopy(counts)
    altered['primary_successes'] += 1
    altered['primary_rejections'] -= 1
    assert audit.rejects(lambda: check_text(text, altered))
    falsifiers.append('conserved total with success/rejection redistribution')
    print(json.dumps(dict(schema='fsmgen.release_readback_last_book_claims.v1', success=True,
        counts=dict(counts), source_candidates=1, prospective_watcher_pins=len(pins), falsifiers=falsifiers,
        scope='Current last-observation book counts from exact saved observations and TAP, joined to the independent behavioral audit. No fixture, prior producer or native execution.'), sort_keys=True))


if __name__ == '__main__':
    main()
