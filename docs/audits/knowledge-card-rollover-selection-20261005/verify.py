"""Independently qualify the selected topology, source retention and question routes."""
import copy
import hashlib
import json
import re
import subprocess
import sys
from pathlib import Path
from select_homes import expected as expected_homes

BASE = Path('docs/audits/knowledge-card-rollover-selection-20261005')


def identity(raw):
    return {'bytes': len(raw), 'sha256': hashlib.sha256(raw).hexdigest()}


def metadata(raw):
    front = raw.decode().split('---\n', 2)[1]
    identifier = re.findall(r'^id: (.+)$', front, re.M)
    answers = re.search(r'^answers:\n((?:  - .*\n)+)', front, re.M)
    assert len(identifier) == 1 and answers, 'explicit existing ID and question list'
    return identifier[0], [json.loads(line[4:]) for line in answers[1].splitlines()]


def metrics(blobs):
    return {'files': len(blobs), 'lines_total': sum(v.count(b'\n') for v in blobs),
            'bytes_total': sum(map(len, blobs)), 'lines_each': max(v.count(b'\n') for v in blobs),
            'bytes_each': max(map(len, blobs)),
            'line_bytes_each': max(len(line.rstrip(b'\r')) for v in blobs for line in v.split(b'\n'))}


def check(source, coverage, originals, proposals, registry):
    routes = []
    for name, row in source['sources'].items():
        raw = originals[name]
        assert {k: row[k] for k in ('bytes', 'sha256')} == identity(raw), 'complete source identity'
        assert row['lines'] == raw.count(b'\n'), 'source completed-newline units'
        start = 0
        for unit in coverage[name]:
            assert type(unit['start']) is int and type(unit['end']) is int, 'exact integer source interval'
            assert unit['start'] == start and unit['end'] > start, 'contiguous complete source coverage'
            assert unit['sha256'] == hashlib.sha256(raw[start:unit['end']]).hexdigest(), 'whole source unit digest'
            start = unit['end']
        assert start == len(raw), 'zero unretained source residue'
        old_id, old_questions = metadata(raw)
        new_id, new_questions = metadata(proposals[name])
        assert (new_id, new_questions) == (old_id, old_questions), 'complete unchanged ordered question ownership'
        assert new_id == name, 'stable original identity'
        command = 'python3 -B ' + str(BASE / 'read_source.py') + ' ' + name
        assert command.encode() in proposals[name], 'in-place exact historical retrieval route'
        assert b'docs/audits/knowledge-card-rollover-20261005/verify.py --current' in proposals[name], 'planned current watcher route'
        lines = proposals[name].split(b'\n')
        assert len(lines) - int(proposals[name].endswith(b'\n')) <= 512 and len(proposals[name]) <= 32768 and max(map(len, lines)) <= 819, 'public default per-card bounds'
        routes.extend({'question': q, 'id': new_id, 'current': row['path'], 'historical': row['locator']} for q in old_questions)
    main = proposals['live-document-size-containment'].decode()
    old = originals['live-document-size-containment'].decode().split('---\n', 2)[2]
    prefix = old[:old.index("T1554's recovery run")]
    assert main.split('---\n', 2)[2].startswith(prefix), 'whole existing current-rule prefix retained'
    for marker in ['Decision 0064 supersedes', 'decision 0070', 'Coverage proves',
                   '`core:`', '`adapter:`', '`external:`', 'Currency is', 'Author-overflow',
                   'literal membership', 'semantic\nclosure', 'Version objects require',
                   '`maintained_reference`', 'Rolling ledgers', 'full node graph',
                   'Shared questions', 'direct/cache parity', 'T1569 checks current structure',
                   'Utility review precedes', 'Decisions 0046-0049', 'historical evidence']:
        assert marker in main, 'reviewed current semantic obligation: ' + marker
    growth = proposals['live-document-surface-growth-procedure'].decode()
    assert 'plus one declared' in growth and '`rollover_debt` surface is never widened' in growth, 'later allowance authority preserved'
    sizing = proposals['knowledge-card-sizing-and-partition'].decode()
    assert 'independently' in sizing and 'totals alone cannot expose swapped ownership' in sizing and 'healthy resting' not in sizing, 'independent pressure and complete query proof'
    headroom = proposals['live-document-transition-allowance-headroom'].decode()
    assert 'dated\n  adoption observation' in headroom and 'historical, not a current count' in headroom, 'dated examples cannot masquerade as current census'
    surface = next(r for r in map(json.loads, registry.splitlines()) if r.get('surface_id') == 'knowledge_cards')
    assert surface['state'] == 'rollover_debt', 'existing collection debt retained'
    return routes, surface


def main():
    source = json.loads((BASE / 'source.json').read_text())
    coverage = json.loads((BASE / 'coverage.json').read_text())
    originals = {}; proposals = {}
    for name, row in source['sources'].items():
        raw = Path(row['locator']).read_bytes()
        assert raw == subprocess.check_output(['git', 'show', source['revision'] + ':' + row['path']]), 'independent exact Git source'
        originals[name] = raw
        proposals[name] = (BASE / (name + '.proposed.txt')).read_bytes()
        actual = subprocess.run([sys.executable, '-B', str(BASE / 'read_source.py'), name], capture_output=True)
        assert actual.returncode == 0 and actual.stdout == raw, 'actual complete public retrieval'
    unknown = subprocess.run([sys.executable, '-B', str(BASE / 'read_source.py'), '../unknown'], capture_output=True)
    assert unknown.returncode != 0 and b'unknown archived card ID' in unknown.stderr, 'actual unsafe/unknown reader refusal'
    registry = subprocess.check_output(['git', 'show', source['revision'] + ':doctrine/live_document_size/surfaces.jsonl'], text=True)
    routes, surface = check(source, coverage, originals, proposals, registry)
    assert json.loads((BASE / 'question-homes.json').read_text()) == expected_homes(), 'reviewed complete question-to-information-role coverage'
    paths = subprocess.check_output(['git', 'ls-tree', '-r', '--name-only', source['revision'], '--', 'docs/knowledge'], text=True).splitlines()
    paths = sorted(p for p in paths if Path(p).parent == Path('docs/knowledge') and p.endswith('.md'))
    response = subprocess.check_output(['git', 'cat-file', '--batch'], input=''.join(source['revision'] + ':' + p + '\n' for p in paths).encode())
    blobs = {}; position = 0
    for path in paths:
        end = response.index(b'\n', position); header = response[position:end].split()
        assert header[1] == b'blob'; size = int(header[2]); position = end + 1
        blobs[path] = response[position:position+size]; position += size + 1
    assert position == len(response), 'complete independent physical source census'
    projected = dict(blobs)
    for name, row in source['sources'].items():
        projected[row['path']] = proposals[name]
    before = metrics(list(blobs.values())); after = metrics(list(projected.values()))
    authorized = {k: surface['baseline'][k] + surface['transition']['max_growth'][k] for k in before}
    assert all(after[k] <= authorized[k] and after[k] <= surface['enforcement_ceilings'][k] for k in after), 'projected rollover fits unchanged collection bounds'
    assert after['bytes_total'] < before['bytes_total'] and after['lines_total'] < before['lines_total'], 'actual role-based reduction without deleting members'
    controls = []
    for name in ['lost-source-tail', 'gapped-source-coverage', 'lost-question-owner', 'false-normal-state', 'lost-rollover-rule']:
        s, c, o, p = map(copy.deepcopy, (source, coverage, originals, proposals)); r = registry
        if name == 'lost-source-tail':
            o[next(iter(o))] = o[next(iter(o))][:-1]
        elif name == 'gapped-source-coverage':
            c[next(iter(c))].pop()
        elif name == 'lost-question-owner':
            key = 'knowledge-card-sizing-and-partition'; p[key] = p[key].replace(b'how big may one knowledge fact card be?', b'a replaced question?', 1)
        elif name == 'false-normal-state':
            rows = list(map(json.loads, r.splitlines())); next(x for x in rows if x.get('surface_id') == 'knowledge_cards')['state'] = 'normal'; r = '\n'.join(map(json.dumps, rows))
        else:
            key = 'live-document-surface-growth-procedure'; p[key] = p[key].replace(b'`rollover_debt` surface is never widened', b'`rollover_debt` surface may be widened')
        try:
            check(s, c, o, p, r)
        except AssertionError as error:
            controls.append({'control': name, 'refusal': str(error)})
        else:
            raise AssertionError('genuine selection control accepted: ' + name)
    proof = {'revision': source['revision'], 'before': before, 'proposed': after,
             'authorized': authorized, 'remaining_after_selection': {k: authorized[k]-after[k] for k in after},
             'question_routes': routes, 'controls': controls,
             'scope': 'Projected selection only. Complete original source bytes and ordered query ownership retain; current semantic homes reviewed against canonical doctrine and later decisions. Existing rollover debt remains and no aggregate allowance changes.'}
    path = BASE / 'proofs.json'
    if path.exists():
        assert json.loads(path.read_text()) == proof, 'whole independently regenerated selection proof'
    else:
        path.write_text(json.dumps(proof, indent=2, sort_keys=True) + '\n')
    if '--current-source' in sys.argv:
        for name, row in source['sources'].items():
            assert Path(row['path']).read_bytes() == originals[name], 'production source still unchanged before implementation'
        current_rows = list(map(json.loads, Path('doctrine/live_document_size/surfaces.jsonl').read_text().splitlines()))
        assert next(r for r in current_rows if r.get('surface_id') == 'knowledge_cards') == surface, 'complete unchanged card allowance/ceiling authority before publication'
    authority = json.loads((BASE / 'authority.json').read_text())
    for path, body in authority.items():
        assert subprocess.check_output(['git', 'show', source['revision'] + ':' + path]) == body.encode(), 'whole canonical authority inspected before demotion'
    book = json.loads((BASE / 'book-authority.json').read_text())
    assert book['revision'] == source['revision'], 'same selected source and book boundary'
    assert book['chapter_after'] == book['chapter_before'].replace('`CLAIM_VERIFICATION.md` defines what earns an actionable quantitative claim:', book['block'] + '\n`CLAIM_VERIFICATION.md` defines what earns an actionable quantitative claim:'), 'only meaningful reader contract added'
    def book_metrics(raws):
        return {'files': len(raws), 'lines_total': sum(r.count(b'\n') for r in raws), 'bytes_total': sum(map(len, raws))}
    originals_book = {p: subprocess.check_output(['git', 'show', source['revision'] + ':' + p]) for p in book['paths']}
    assert book['before'] == book_metrics(list(originals_book.values()))
    after_book = dict(originals_book); after_book['docs/book/src/90-reference-map.md'] = book['chapter_after'].encode()
    assert book['after'] == book_metrics(list(after_book.values()))
    assert book['delta'] == {k: book['after'][k]-book['before'][k] for k in book['before']}, 'fresh exact book aggregate'
    assert book['surface_before'] == registry, 'whole original registry authority'
    expected_rows = list(map(json.loads, registry.splitlines()))
    change = next(r for r in expected_rows if r.get('surface_id') == 'shipped_behavior')['reference_contract']['aggregate_change']
    actual_rows = list(map(json.loads, book['surface_after'].splitlines()))
    actual_change = next(r for r in actual_rows if r.get('surface_id') == 'shipped_behavior')['reference_contract']['aggregate_change']
    assert actual_change['baseline'] == book['before'] and actual_change['delta'] == book['delta'] and actual_change['owner'] == 'SEMANTIC-INTROSPECTION-MCP-FRONTIER.72.2'
    change.update(actual_change)
    assert expected_rows == actual_rows, 'only fresh book publication authority changes; no card bounds or allowances widened'
    if '--current-source' in sys.argv:
        assert Path('docs/book/src/90-reference-map.md').read_text() == book['chapter_after']
        assert Path('doctrine/live_document_size/surfaces.jsonl').read_text() == book['surface_after']
    seal = BASE / 'manifest.json'
    if seal.exists():
        for path, record in json.loads(seal.read_text()).items():
            assert identity(Path(path).read_bytes()) == record, 'sealed selection evidence: ' + path
    print('PASS selected exact-source rollover, complete ordered question routes and independent aggregate projection; genuine source/coverage/question/debt/rule controls refuse.')


if __name__ == '__main__':
    main()
