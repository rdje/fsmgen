"""Cold exact source-family membership and actual helper outcome qualification."""
import copy
import hashlib
import json
import re
import subprocess
import sys
from pathlib import Path

BASE = Path(__file__).parent
data = json.loads((BASE / 'inventory.json').read_text())
reviews = json.loads((BASE / 'reviews.json').read_text())


def inventory(value, classified):
    tracked = subprocess.check_output([
        'git', 'ls-tree', '-r', '--name-only', value['baseline'], '--', 't']).decode().splitlines()
    family = {name for name in tracked if re.match(r'\At/(?:204[3-8]|2052)-[^/]+\.t\Z', name)}
    assert len(family) == 7 and set(value['sources']) == family
    sites = []
    for name, source in value['sources'].items():
        raw = subprocess.check_output(['git', 'show', value['baseline'] + ':' + name])
        assert source['source'].encode() == raw
        assert source['bytes'] == len(raw) and source['sha256'] == hashlib.sha256(raw).hexdigest()
        offset = 0
        for number, line in enumerate(raw.splitlines(keepends=True), 1):
            pattern = (rb'\b(?:like|unlike|diagnostic_matches)\s*\('
                       rb'|\bis\s*\(\s*(?:first_line|diagnostic_line)\s*\(')
            for match in re.finditer(pattern, line):
                sites.append((name, number, offset + match.start()))
            offset += len(line)
    assert sites == [(s['path'], s['line'], s['offset']) for s in value['sites']]
    assert sites == [(s['path'], s['line'], s['offset']) for s in classified]
    assert all(s['review'] != 'unclassified lexical site' for s in classified)
    assert {kind: sum(s['review'] == kind for s in classified) for kind in
            {s['review'] for s in classified}} == {
        'confirmed full-trace helper cause vulnerability': 1,
        'first-line cause or delegated echo control/capture (default matcher)': 11,
        'full-trace cause candidate; additional wrong-source runtime control remains owned': 17,
        'intentional trace echo evidence': 2}


inventory(data, reviews)
products = json.loads((BASE / 'helper-products.json').read_text())
for bound in products['bindings']:
    source = data['sources'][bound['path']]
    assert bound['source_sha256'] == source['sha256']
    assert all(body in source['source'] for body in bound['bodies'])
rows = {(r['kind'], r['mode']): r for r in products['results']}
assert set(rows) == {(kind, mode) for kind in ('library', 'file') for mode in ('wrong_echo', 'correct')}
for (kind, mode), row in rows.items():
    assert row['error'].splitlines()[0] == row['first_line'] == 'library origin independent document set required'
    assert ' at t/lib/FSM/Test/LibraryDocumentOriginAuthority.pm line 16' in row['error']
    expected = 'source_review_reason_only_in_caller' if mode == 'wrong_echo' else row['first_line']
    assert row['full_trace_matches'] == int(expected in row['error']) == 1
    assert row['first_line_matches'] == int(expected in row['first_line']) == (0 if mode == 'wrong_echo' else 1)
    if mode == 'wrong_echo':
        subject = row['error'] if '--full-stack' in sys.argv else row['first_line']
        assert expected not in subject, 'actual caller echo is not the producer reason'
    if kind == 'file':
        assert row['controls'] == [{'name': kind + '-' + mode, 'accepted': 0,
                                    'diagnostic': row['first_line']}]
    else:
        assert row['controls'] == []
tap = (BASE / 'helper-probe.txt').read_text()
assert 'ok 2 - precise authority refusal' in tap
assert 'not ok 6 - precise actual file authority refusal' in tap
assert 'failed 1 test of 8' in tap
for label in ('source', 'site', 'review', 'family'):
    bad, classified = copy.deepcopy(data), copy.deepcopy(reviews)
    if label == 'source':
        bad['sources'][next(iter(bad['sources']))]['source'] += ' '
    elif label == 'site':
        bad['sites'].pop()
    elif label == 'review':
        classified.pop()
    else:
        name = next(iter(bad['sources']))
        del bad['sources'][name]
        bad['sites'] = [s for s in bad['sites'] if s['path'] != name]
        classified = [s for s in classified if s['path'] != name]
    try:
        inventory(bad, classified)
    except AssertionError:
        pass
    else:
        raise AssertionError('corruption accepted: ' + label)
counts = {kind: sum(r['review'] == kind for r in reviews) for kind in sorted({r['review'] for r in reviews})}
print(json.dumps({'files': len(data['sources']), 'lexical_sites': len(reviews), 'classes': counts,
                  'actual_library_helper': 'vulnerable; immediate repair owned',
                  'actual_file_helper': 'rejects wrong first cause',
                  'corruptions_rejected': 4, 'all_repository_semantic_qualification': False}, sort_keys=True))
