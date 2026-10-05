"""Check the atomic rollover and immutable retrieval; current mode watches its live cards."""
import copy
import hashlib
import json
import re
import subprocess
import sys
import uuid
from html.parser import HTMLParser
from pathlib import Path

BASE = Path('docs/audits/knowledge-card-rollover-20261005')
SELECT = Path('docs/audits/knowledge-card-rollover-selection-20261005')


def metadata(raw):
    lines = raw.decode().splitlines()
    if not lines or lines[0] != '---':
        return None
    front = lines[1:lines.index('---', 1)]
    ids = [line[4:].strip().strip('"') for line in front if line.startswith('id: ')]
    questions = []; active = False
    for line in front:
        if line.startswith('answers:'):
            rest = line[len('answers:'):].strip(); active = not rest
            if rest:
                questions.extend(json.loads(rest))
        elif active and line.startswith(' '):
            match = re.fullmatch(r' +\- +(.*)', line)
            assert match, 'source question-list grammar'
            questions.append(match[1].strip(' ').removeprefix('"').removesuffix('"'))
        elif not line.startswith(' '):
            active = False
    if not questions:
        return None
    assert len(ids) == 1
    return ids[0], questions


def git_blobs(revision, paths):
    output = subprocess.check_output(['git', 'cat-file', '--batch'], input=''.join(revision + ':' + p + '\n' for p in paths).encode())
    blobs = {}; position = 0
    for path in paths:
        end = output.index(b'\n', position); header = output[position:end].split()
        assert header[1] == b'blob'; size = int(header[2]); position = end + 1
        blobs[path] = output[position:position+size]; position += size + 1
    assert position == len(output)
    return blobs


def allocation(blobs):
    questions = {}; facts = 0; occurrences = 0
    for path, raw in blobs.items():
        fact = metadata(raw)
        if not fact:
            continue
        facts += 1; identifier, answers = fact; occurrences += len(answers)
        for question in answers:
            questions.setdefault(question, []).append((identifier, path))
    rows = ''.join(q + '\t' + ','.join(i for i, p in sorted(members)) + '\t' + ','.join(p for i, p in sorted(members)) + '\n' for q, members in sorted(questions.items()))
    return {'facts': facts, 'unique_questions': len(questions), 'answer_occurrences': occurrences, 'rows': rows}


def metrics(blobs):
    values = list(blobs.values())
    return {'files': len(values), 'lines_total': sum(v.count(b'\n') for v in values), 'bytes_total': sum(map(len, values)),
            'lines_each': max(v.count(b'\n') for v in values), 'bytes_each': max(map(len, values)),
            'line_bytes_each': max(len(line.rstrip(b'\r')) for v in values for line in v.split(b'\n'))}


def check(source, after, descriptors, proposals):
    for name, row in source['catalog']['sources'].items():
        assert after[row['path']].encode() == proposals[name], 'exact committed semantic proposal published'
        assert metadata(after[row['path']].encode()) == metadata(source['before'][row['path']].encode()), 'complete ordered ID/question ownership conserved'
    old = source['before']['doctrine/live_document_size/archive_descriptors.jsonl']
    expected = old + ''.join(json.dumps(r, sort_keys=True, separators=(',', ':')) + '\n' for r in descriptors)
    assert after['doctrine/live_document_size/archive_descriptors.jsonl'] == expected, 'only admitted complete-source descriptors append'
    assert len(descriptors) == len(source['catalog']['sources']), 'one retained predecessor per changed card'
    for descriptor, (name, row) in zip(descriptors, source['catalog']['sources'].items()):
        assert descriptor == {'record_type': 'descriptor', 'schema_version': 1,
                              'descriptor_id': 'knowledge-rollover-' + name + '-20261005',
                              'surface_id': 'exact_history', 'former_path': row['path'],
                              'range_id': 'complete-source-before-role-based-rollover', 'revision': source['catalog']['revision'],
                              'lines': row['lines'], 'bytes': row['bytes'], 'sha256': row['sha256'],
                              'retrieval_kind': 'file', 'retrieval_locator': row['locator'], 'current_pointer': row['path'],
                              'sealed_on': '2026-10-05', 'verifier': 'builtin:file'}, 'exact source identity and portable current/retrieval route'
    before_rows = list(map(json.loads, source['before']['doctrine/live_document_size/surfaces.jsonl'].splitlines()))
    after_rows = list(map(json.loads, after['doctrine/live_document_size/surfaces.jsonl'].splitlines()))
    before_card = next(r for r in before_rows if r.get('surface_id') == 'knowledge_cards')
    after_card = next(r for r in after_rows if r.get('surface_id') == 'knowledge_cards')
    assert before_card == after_card, 'whole card authority unchanged; rollover allowance cannot widen'
    book = json.loads((BASE / 'book-authority.json').read_text())
    assert after['docs/book/src/90-reference-map.md'] == book['chapter_after'] and book['chapter_before'] == source['before']['docs/book/src/90-reference-map.md']
    assert book['chapter_after'] == book['chapter_before'].replace('`CLAIM_VERIFICATION.md` defines what earns an actionable quantitative claim:', book['block'] + '`CLAIM_VERIFICATION.md` defines what earns an actionable quantitative claim:'), 'only meaningful public reader/allowance guidance added'
    assert book['surface_before'] == source['before']['doctrine/live_document_size/surfaces.jsonl'] and book['surface_after'] == after['doctrine/live_document_size/surfaces.jsonl']
    change = next(r for r in before_rows if r.get('surface_id') == 'shipped_behavior')['reference_contract']['aggregate_change']
    next_change = next(r for r in after_rows if r.get('surface_id') == 'shipped_behavior')['reference_contract']['aggregate_change']
    assert next_change['baseline'] == book['before'] and next_change['delta'] == book['delta'] and next_change['owner'] == 'SEMANTIC-INTROSPECTION-MCP-FRONTIER.72.3.1'
    change.update(next_change)
    assert before_rows == after_rows, 'only fresh book aggregate authority changes'
    return before_card


class Text(HTMLParser):
    def __init__(self):
        super().__init__(); self.data = []

    def handle_data(self, text):
        self.data.append(text)


def main():
    source = json.loads((BASE / 'source.json').read_text())
    subprocess.run([sys.executable, '-B', str(SELECT / 'verify.py')], check=True)
    after = json.loads((BASE / 'after.json').read_text())
    descriptors = json.loads((BASE / 'descriptors.json').read_text())
    proposals = {name: (SELECT / (name + '.proposed.txt')).read_bytes() for name in source['catalog']['sources']}
    for path, body in source['before'].items():
        assert subprocess.check_output(['git', 'show', source['revision'] + ':' + path]) == body.encode(), 'whole committed original publication source'
    surface = check(source, after, descriptors, proposals)
    names = subprocess.check_output(['git', 'ls-tree', '-r', '--name-only', source['revision'], '--', 'docs/knowledge', 'docs/decisions'], text=True).splitlines()
    paths = sorted(p for p in names if p.endswith('.md'))
    before_blobs = git_blobs(source['revision'], paths)
    expected_blobs = dict(before_blobs)
    for row in source['catalog']['sources'].values():
        expected_blobs[row['path']] = after[row['path']].encode()
    before_allocation = allocation(before_blobs); after_allocation = allocation(expected_blobs)
    assert before_allocation == after_allocation, 'complete independently reselected full source question-to-ID/path allocation'
    public_before = json.loads((BASE / 'before-query.json').read_text()); public_after = json.loads((BASE / 'after-query.json').read_text())
    assert public_before['status'] == public_after['direct']['status'] == public_after['cached']['status'] == 0
    assert public_before['stdout'] == public_after['direct']['stdout'] == public_after['cached']['stdout'] == before_allocation['rows'], 'actual complete public original/direct/cache row parity'
    direct_before = {p: raw for p, raw in before_blobs.items() if Path(p).parent == Path('docs/knowledge')}
    direct_after = {p: raw for p, raw in expected_blobs.items() if Path(p).parent == Path('docs/knowledge')}
    before_metrics = metrics(direct_before); after_metrics = metrics(direct_after)
    selection = json.loads((SELECT / 'proofs.json').read_text())
    assert before_metrics == selection['before'] and after_metrics == selection['proposed'], 'actual full physical rollover matches admitted independent projection'
    assert all(after_metrics[k] <= surface['baseline'][k] + surface['transition']['max_growth'][k] and after_metrics[k] <= surface['enforcement_ceilings'][k] for k in after_metrics), 'unchanged inclusive and owned collection bounds'
    controls = []
    for name in ('lost-current-rule', 'swapped-question', 'wrong-archive-locator', 'widened-rollover-allowance'):
        a = copy.deepcopy(after); d = copy.deepcopy(descriptors)
        if name == 'lost-current-rule':
            path = 'docs/knowledge/live-document-size-containment.md'; a[path] = a[path].replace('Coverage proves', 'Missing coverage rule', 1)
        elif name == 'swapped-question':
            path = 'docs/knowledge/knowledge-card-sizing-and-partition.md'; a[path] = a[path].replace('how big may one knowledge fact card be?', 'one replaced question?', 1)
        elif name == 'wrong-archive-locator':
            d[0]['retrieval_locator'] = 'missing.txt'
        else:
            rows = list(map(json.loads, a['doctrine/live_document_size/surfaces.jsonl'].splitlines())); next(r for r in rows if r.get('surface_id') == 'knowledge_cards')['transition']['max_growth']['bytes_total'] += 1
            a['doctrine/live_document_size/surfaces.jsonl'] = '\n'.join(map(json.dumps, rows)) + '\n'
        try:
            check(source, a, d, proposals)
        except AssertionError as error:
            controls.append({'control': name, 'refusal': str(error)})
        else:
            raise AssertionError('actual publication control accepted: ' + name)
    native = json.loads((BASE / 'native-archive-controls.json').read_text())
    assert [r['fixture'] for r in native] == ['valid', 'missing-source', 'changed-source-byte', 'wrong-digest']
    assert native[0]['result']['status'] == 0 and all(r['result']['status'] != 0 for r in native[1:]), 'real archive separating outcomes'
    for row in native:
        assert '--retention-contracts' in row['result']['command'] and 'Usage:' not in row['result']['stderr'], 'real full CLI reaches validation rather than usage'
        if row['fixture'] == 'missing-source':
            assert 'target is not a regular file' in row['result']['stderr'], 'actual missing archive boundary'
        elif row['fixture'] in ('changed-source-byte', 'wrong-digest'):
            assert 'retrieval digest changed' in row['result']['stderr'], 'actual archive identity boundary'
    if '--reexecute' in sys.argv:
        nonce = 'verify-' + uuid.uuid4().hex
        subprocess.run([sys.executable, '-B', str(BASE / 'produce.py'), 'fixtures', nonce], check=True)
        fresh = json.loads((Path('.artifacts/knowledge-card-rollover/rechecks') / nonce / 'native-archive-controls.json').read_text())
        for previous, current in zip(native, fresh):
            assert current['fixture'] == previous['fixture'] and current['surface'] == previous['surface'] and current['descriptors'] == previous['descriptors'], 'whole fresh public control inputs'
            assert {k: current['result'][k] for k in ('status', 'stdout', 'stderr')} == {k: previous['result'][k] for k in ('status', 'stdout', 'stderr')}, 'fresh actual public archive outcomes reproduce without overwriting sealed evidence'
    book = json.loads((BASE / 'book-authority.json').read_text())
    book_before = git_blobs(source['revision'], book['paths']); book_after = dict(book_before)
    book_after['docs/book/src/90-reference-map.md'] = book['chapter_after'].encode()
    def aggregate(blobs):
        return {k: v for k, v in metrics(blobs).items() if k in ('files', 'lines_total', 'bytes_total')}
    assert book['before'] == aggregate(book_before) and book['after'] == aggregate(book_after)
    assert book['delta'] == {k: book['after'][k]-book['before'][k] for k in book['before']}, 'whole exact fresh book delta'
    for name, row in source['catalog']['sources'].items():
        raw = Path(row['locator']).read_bytes()
        assert len(raw) == row['bytes'] and hashlib.sha256(raw).hexdigest() == row['sha256'] and raw == source['before'][row['path']].encode(), 'complete retained source immutable'
        assert Path(row['locator']).stat().st_dev == Path('.').stat().st_dev, 'same-volume archive'
        result = subprocess.run([sys.executable, '-B', str(SELECT / 'read_source.py'), name], capture_output=True)
        assert result.returncode == 0 and result.stdout == raw, 'actual exact authenticated predecessor reader'
    proof = {'source_revision': source['revision'], 'before': before_metrics, 'after': after_metrics,
             'allocation': {k: v for k, v in after_allocation.items() if k != 'rows'}, 'controls': controls,
             'scope': 'Complete source/ordered questions/current-rule homes/retrieval and physical rollover closure, with unchanged card authorities. Existing rollover debt remains; no semantic duplicate count or global healthy-state claim.'}
    file = BASE / 'proofs.json'
    if file.exists():
        assert json.loads(file.read_text()) == proof
    else:
        file.write_text(json.dumps(proof, sort_keys=True, indent=2) + '\n')
    if '--current' in sys.argv:
        for name, row in source['catalog']['sources'].items():
            assert Path(row['path']).read_bytes() == proposals[name], 'current owned card retains complete qualified rules and routes'
        current_descriptors = list(map(json.loads, Path('doctrine/live_document_size/archive_descriptors.jsonl').read_text().splitlines()))
        for descriptor in descriptors:
            assert [r for r in current_descriptors if r.get('descriptor_id') == descriptor['descriptor_id']] == [descriptor], 'unique current exact archive descriptor'
        assert book['block'] in Path('docs/book/src/90-reference-map.md').read_text(), 'current public retrieval guidance remains'
        html = Text(); html.feed(Path('docs/book/book/90-reference-map.html').read_text())
        expected_text = book['block'].replace('```sh\n', '').replace('```\n', '').replace('`', '')
        assert ' '.join(expected_text.split()) in ' '.join(''.join(html.data).split()), 'complete current native-rendered retrieval paragraph'
    manifest = BASE / 'manifest.json'
    if manifest.exists():
        for path, row in json.loads(manifest.read_text()).items():
            raw = Path(path).read_bytes(); assert row == {'bytes': len(raw), 'sha256': hashlib.sha256(raw).hexdigest()}, 'sealed atomic rollover evidence'
    print('PASS atomic source-preserving four-card rollover, complete public query conservation, unchanged collection authority and authenticated archive retrieval; genuine source/rule/question/route/allowance controls refuse.')


if __name__ == '__main__':
    main()
