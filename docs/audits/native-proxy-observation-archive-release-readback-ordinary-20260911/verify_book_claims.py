"""Re-derive the ordinary readback book measurements from saved case bodies.

The fixture and initial auditor are never executed. Exact source excerpts join
the declaration IDs; independent saved-case auditing owns behavioral truth.
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


def phrases(counts):
    words = 'zero one two three four five six seven eight nine ten eleven twelve thirteen fourteen fifteen sixteen seventeen eighteen nineteen'.split()
    return [
        f"The ordinary retired partition now exercises all {counts['primary_cases']} primary cases: {words[counts['primary_successes']]}",
        f"successful releases and {counts['primary_rejections']} rejections. The first integrated run passes {counts['assertions']:,}",
        f"EOF fails before a source handle returns. All {counts['unreturned_reader_lexical_closes']} primary failed readers close",
        f"weak alias is retained, so observation does not extend that lifetime. The {counts['returned_reader_calls']}",
        f"implementation cleanup. All {counts['roots']:,} new roots are absent and disjoint from the",
        f"{counts['prior_disjoint_absent_roots']:,} roots in the selected predecessor reports.",
        f"{words[counts['structural_body_successes']].capitalize()} structural census alterations finish successfully; content-sensitive consumers reject the",
    ]


def check_text(text, counts):
    text = ' '.join(text.split())
    for phrase in phrases(counts):
        assert text.count(phrase) == 1, phrase


def main():
    pins = load(BASE / 'book-claim-pins.json')
    assert [p['path'] for p in pins] == [str((BASE / n).relative_to(ROOT))
        for n in ('verify_book_claims.py', 'book-claim-selection.json')]
    for pin in pins:
        path = ROOT / pin['path']
        assert not path.is_symlink() and path.stat().st_dev == ROOT.stat().st_dev
        raw = path.read_bytes()
        assert pin == dict(path=pin['path'], size_bytes=len(raw), sha256=hashlib.sha256(raw).hexdigest())
    spec = importlib.util.spec_from_file_location('book_readback_audit', BASE / 'audit-corrected.py')
    audit = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(audit)
    plan = load(BASE / 'plan.json')
    audit.domain(plan)
    audit.authenticate(plan)
    audit.authenticate_correction()
    report = load(BASE / 'result/qualification.json')
    result = load(BASE / 'result/audit.json')
    assert report['success'] is result['success'] is True
    counts, roots = Counter(), []
    for selected, receipt in zip(plan['cases'], report['case_files'], strict=True):
        path = BASE / 'result/cases' / ('case-%04d.json' % receipt['index'])
        assert not path.is_symlink() and path.stat().st_dev == ROOT.stat().st_dev
        raw = path.read_bytes()
        assert len(raw) == receipt['size_bytes'] and hashlib.sha256(raw).hexdigest() == receipt['sha256']
        row = json.loads(raw)
        assert row['matrix_case'] == selected and row['roots_absent'] is True
        op = row['operation']
        primary = selected['role'] == 'primary'
        success = op['result']['success']
        assert type(success) is int and success in (0, 1)
        counts['primary_cases'] += int(primary)
        counts['primary_successes'] += int(primary) * success
        counts['primary_rejections'] += int(primary) * (1 - success)
        reader = op['readback']
        if reader is not None:
            counts['returned_reader_calls'] += reader['reader_returned']
            if primary and not reader['reader_returned']:
                assert reader['weak_open_at_return'] == 0 and reader['recovery'] == []
                assert reader['at_reader_return']['duplicate'] is None
                counts['unreturned_reader_lexical_closes'] += 1
            if primary and selected['selector']['control'] == 'body-xor' and success:
                source = op['boundary_calls'][row['prospective']['resolved']['call_id']]
                assert op['boundary_calls'][source['parent']]['name'] == 'NativeProxyImageCoordination::_census'
                counts['structural_body_successes'] += 1
        roots.extend(row['context'][k]['path'] for k in ('store', 'workspace', 'other_workspace', 'evidence'))
    counts['roots'] = len(roots)
    assert len(set(roots)) == len(roots)
    prior = [r['path'] for p in plan['previous_root_reports'] for r in load(ROOT / p)['allocated']]
    counts['prior_disjoint_absent_roots'] = len(prior)
    assert len(set(prior)) == len(prior) and not set(prior) & set(roots)
    for path in roots + prior:
        assert not (ROOT / path).exists() and not (ROOT / path).is_symlink()
    tap = (BASE / 'result/qualify.tap').read_text()
    terminal, = re.findall(r'^1\.\.([0-9]+)$', tap, re.M)
    counts['assertions'] = int(terminal)
    assert re.findall(r'^ok ([0-9]+) - ', tap, re.M) == [str(i) for i in range(1, counts['assertions'] + 1)]
    assert (BASE / 'result/qualify.exit').read_bytes() == b'0\n'
    assert all(value == result[key] for key, value in counts.items() if key != 'structural_body_successes')
    text = BOOK.read_text()
    check_text(text, counts)
    selections = load(BASE / 'book-claim-selection.json')
    assert [s['excerpt'] for s in selections] == phrases(counts)[:6]
    dispositions = {d['candidate_id']: d for d in map(json.loads,
        (ROOT / 'doctrine/claim_verification/dispositions.jsonl').read_text().splitlines()[1:])}
    for selection in selections:
        assert selection['path'] == str(BOOK.relative_to(ROOT))
        assert hashlib.sha256(selection['excerpt'].encode()).hexdigest() == selection['source_line_sha256']
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
    print(json.dumps(dict(schema='fsmgen.release_readback_book_claims.v1', success=True, counts=dict(counts),
        source_candidates=len(selections), prospective_watcher_pins=len(pins), falsifiers=falsifiers,
        scope='Current ordinary book clauses against exact saved observations and independent audit totals. No fixture, prior producer or native execution.'), sort_keys=True))


if __name__ == '__main__':
    main()
