"""Publish a bounded original source inventory with separate current scope."""
import argparse
import json
import re
import subprocess
from html.parser import HTMLParser
from pathlib import Path
import importlib.util

BASE = Path('docs/audits/record-value-original-parser-sources-20261005')
REVISION = 'e11d97f0c79c22c240243350a27e000a13bc6243'
OWNER = 'SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.4.3.3.5.2.1.5.2.2.3.1.2.1.3.1.2.3.2.3.3.3.3.2.3.2.3.3.2.3.2.2.2.4.1'
CARD = 'docs/knowledge/record-value-original-parser-source-inventory.md'
CHAPTER = 'docs/book/src/13k-isf-feature-support-matrix.md'
MARKER = '[portable replay repair]'
QUESTIONS = ['what inventories original parser refusal source bodies?', 'does the original parser source inventory qualify active native paths?']
BLOCK = '''The original parser source inventory now binds complete own facade, parser and
record-context source units, their lexical declarations, selected function bodies,
parameter roles and ordered call/guard statements. Output-field source admission
and aggregate actor-port admission have distinct source boundaries. This inventory
does not establish active failure paths or native argument meanings; independent
path models and complete API/helper/frame joins remain subsequent work.

```bash
python3 -B docs/audits/record-value-original-parser-sources-20261005/verify.py --current
```

The default reader authenticates the original source inventory and its historical
publication. The current flag additionally checks its live fact, question ownership
and this reader guidance. Framework/display, coordinates, native reference identity
and broader consumer/alias/cold meanings remain separately owned. Visual QA is pending.

'''
CARD_TEXT = '''---
id: record-value-original-parser-source-inventory
title: Original parser refusal source boundaries have a finite inventory
answers:
  - "what inventories original parser refusal source bodies?"
  - "does the original parser source inventory qualify active native paths?"
date: 2026-10-05
status: current
tags: [isf, record, parser, source, qualification]
evidence: >-
  docs/audits/record-value-original-parser-sources-20261005/scope.txt;
  docs/tasks/SEMANTIC-INTROSPECTION-MCP-FRONTIER.md
reverify: >-
  scripts/run_with_ram_guard.sh -- python3 -B
  docs/audits/record-value-original-parser-sources-20261005/verify.py --current
---

The finite original source inventory binds whole own facade, parser and
record-context texts. Their lexical declarations, selected complete function
bodies, supplied parameter roles and ordered source call/guard statements
are independently regenerated. Exact committed prerequisites qualify source
inputs, primary causes, API/parser boundaries and helper context separately.

Output-field source writes and aggregate actor-port type admission have distinct
source guards. Source order records provenance; it does not establish which
branches ran or whether a returned call remained active. No native trace supplies
the intended source selection. Missing or borrowed source bodies, statements,
parameters, declaration membership and JSON kinds reject.

The default replay authenticates original source and historical publication.
Explicit current replay also checks this whole fact, actual direct/cache question
ownership and the scoped book command and guidance. Independent active path and
argument models, complete native/API/helper joins, framework/display contracts,
raw coordinates, reference/address lifetimes, consumer/alias/cold meanings and
permanent/native repairs remain separate owners. Visual mdBook QA is pending.

Related: [[record-value-original-observer-helper-paths]].
'''


def reader():
    spec = importlib.util.spec_from_file_location('parser_source_publication_reader', BASE / 'verify.py')
    result = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(result)
    return result


def git(path):
    return subprocess.check_output(['git', 'show', REVISION + ':' + path])


def metrics(blobs):
    return {'files': len(blobs), 'lines_total': sum(raw.count(b'\n') for raw in blobs.values()),
            'bytes_total': sum(map(len, blobs.values()))}


def expected():
    paths = subprocess.check_output(['git', 'ls-tree', '-r', '--name-only', REVISION, 'docs/book/src'], text=True).splitlines()
    paths = [path for path in paths if path.endswith('.md')]
    before = {path: git(path) for path in paths}
    chapter = before[CHAPTER].decode()
    assert chapter.count(MARKER) == 1
    after = {**before, CHAPTER: chapter.replace(MARKER, BLOCK + MARKER).encode()}
    old, new = metrics(before), metrics(after)
    return {'revision': REVISION, 'paths': paths, 'before': chapter, 'after': after[CHAPTER].decode(),
            'summary': before['docs/book/src/SUMMARY.md'].decode(), 'card': CARD_TEXT, 'block': BLOCK,
            'authority': {'before': old, 'after': new, 'delta': {k: new[k] - old[k] for k in old}}}


def check_current(card, chapter, queries):
    r = reader()
    r.require(card == CARD_TEXT, 'whole current parser inventory fact/source/question/reader')
    r.require(chapter.count(BLOCK) == 1, 'unique complete current parser source reader guidance')
    r.require(set(queries) == {'direct', 'cached'}, 'complete parser inventory current query roles')
    target = 'record-value-original-parser-source-inventory'
    expected_rows = sorted(question + '\t' + target + '\t' + CARD for question in QUESTIONS)
    for result in queries.values():
        r.require(type(result['status']) is int and result['status'] == 0, 'parser inventory actual query integer status')
        rows = []
        for row in result['stdout'].splitlines():
            fields = row.split('\t')
            r.require(len(fields) == 3, 'whole parser inventory query row grammar')
            if target in fields[1].split(',') or fields[0] in QUESTIONS:
                rows.append(row)
        r.require(sorted(rows) == expected_rows, 'complete unique parser inventory question ownership')


def current_controls(card, chapter, queries):
    r = reader()
    controls = []
    for name, bad_card, bad_chapter, bad_queries, cause in [
        ('lost-source-scope', card.replace('does not establish', 'establishes'), chapter, queries, 'whole current parser inventory fact/source/question/reader'),
        ('lost-reader-scope', card, chapter.replace('does not establish active failure paths', 'establishes active failure paths'), queries, 'unique complete current parser source reader guidance'),
        ('borrowed-question', card, chapter, {**queries, 'direct': {**queries['direct'], 'stdout': queries['direct']['stdout'].replace(QUESTIONS[0] + '\t', 'borrowed question\t')}}, 'complete unique parser inventory question ownership'),
        ('Boolean-query-status', card, chapter, {**queries, 'direct': {**queries['direct'], 'status': False}}, 'parser inventory actual query integer status'),
    ]:
        r.require(not r.same([card, chapter, queries], [bad_card, bad_chapter, bad_queries]), 'genuine parser inventory publication control: ' + name)
        try:
            check_current(bad_card, bad_chapter, bad_queries)
        except ValueError as error:
            r.require(str(error) == cause, 'intended parser source publication control: ' + name)
            controls.append({'control': name, 'status': 1, 'cause': str(error)})
        else:
            raise ValueError('false-green parser source publication control: ' + name)
    return controls


class Text(HTMLParser):
    def __init__(self):
        super().__init__()
        self.parts = []

    def handle_data(self, data):
        self.parts.append(data)


def check_rendered(html):
    mains = re.findall(r'<main\b[^>]*>(.*?)</main>', html, re.S)
    assert len(mains) == 1, 'unique rendered parser inventory chapter body'
    text = Text(); text.feed(mains[0])
    visible = ' '.join(' '.join(text.parts).split())
    block = BLOCK.replace('```bash\n', '').replace('```\n', '')
    paragraphs = [' '.join(p.split()) for p in block.strip().split('\n\n')]
    assert all(visible.count(p) == 1 for p in paragraphs), 'complete exact rendered parser inventory scope/command'
    return paragraphs


def rendered_proof(html):
    paragraphs = check_rendered(html)
    controls = []
    for name, old, new in [('wrong-current-command', 'parser-sources-20261005/verify.py --current', 'parser-sources-20261005/verify.py --snapshot'),
                           ('lost-open-boundary', 'does not establish active failure paths', 'establishes active failure paths')]:
        altered = html.replace(old, new)
        assert altered != html, 'genuine rendered parser source control'
        try:
            check_rendered(altered)
        except AssertionError as error:
            controls.append({'control': name, 'status': 1, 'cause': str(error)})
        else:
            raise AssertionError('false-green rendered parser source control')
    return {'paragraphs': paragraphs, 'controls': controls,
                              'scope': 'Whole source/aggregate and scoped exact native rendered text; visual QA remains pending.'}


def verify(current=False, build=None):
    r = reader()
    publication = expected()
    r.save('publication.json', publication)
    if current:
        queries = {}
        for role, options in (('direct', ['--all', '--no-cache']), ('cached', ['--all'])):
            result = subprocess.run(['knowledge-map/scripts/query_knowledge_map.sh', *options], capture_output=True, text=True)
            queries[role] = {'status': result.returncode, 'stdout': result.stdout, 'stderr': result.stderr}
        card, chapter = Path(CARD).read_text(), Path(CHAPTER).read_text()
        check_current(card, chapter, queries)
        # Save the actual first current input in an unsealed archive. On future
        # reads validate it independently; unrelated global progress is allowed.
        path = BASE / 'current-input.json'
        if path.exists():
            saved = r.load(path)
            check_current(saved['card'], saved['chapter'], saved['queries'])
        else:
            r.save('current-input.json', {'card': card, 'chapter': chapter, 'queries': queries})
        r.save('current-controls.json', current_controls(card, chapter, queries))
    elif (BASE / 'manifest.json').exists():
        saved = r.load(BASE / 'current-input.json')
        check_current(saved['card'], saved['chapter'], saved['queries'])
        r.save('current-controls.json', current_controls(saved['card'], saved['chapter'], saved['queries']))
    if build is not None:
        before = {path: git(path) for path in publication['paths']}
        after = {**before, CHAPTER: publication['after'].encode()}
        assert all(Path(path).read_bytes() == raw for path, raw in after.items()), 'whole current book source at inventory publication boundary'
        surface = next(row for row in map(json.loads, Path('doctrine/live_document_size/surfaces.jsonl').read_text().splitlines()) if row.get('surface_id') == 'shipped_behavior')
        assert surface['reference_contract']['aggregate_change']['baseline'] == publication['authority']['before']
        assert surface['reference_contract']['aggregate_change']['delta'] == publication['authority']['delta']
        html = (Path(build) / (Path(CHAPTER).stem + '.html')).read_text()
        raw_path = BASE / 'book-input.html'
        if raw_path.exists():
            assert raw_path.read_text() == html, 'exact first native inventory render input'
        else:
            assert not (BASE / 'manifest.json').exists()
            raw_path.write_text(html)
        r.save('book-proofs.json', rendered_proof(html))
    elif (BASE / 'manifest.json').exists():
        r.save('book-proofs.json', rendered_proof((BASE / 'book-input.html').read_text()))
    print('PASS historical parser source publication; explicit current role qualifies live fact/query/reader scope.')


def publish():
    r = reader()
    publication = expected()
    assert not Path(CARD).exists() and Path(CHAPTER).read_text() == publication['before']
    assert not (BASE / 'manifest.json').exists()
    r.save('publication.json', publication)
    Path(CARD).write_text(CARD_TEXT)
    Path(CHAPTER).write_text(publication['after'])
    path = Path('doctrine/live_document_size/surfaces.jsonl')
    rows = [json.loads(line) for line in path.read_text().splitlines()]
    surface = next(row for row in rows if row.get('surface_id') == 'shipped_behavior')
    surface['reference_contract']['aggregate_change'] = {
        'authority_id': 'PARSER-SOURCE-INVENTORY-20261005-SHIPPED-BEHAVIOR', 'owner': OWNER,
        'baseline': publication['authority']['before'], 'delta': publication['authority']['delta'],
        'rationale': 'Publish finite original parser source inventory with active/native path meanings explicitly open.',
    }
    path.write_text(''.join(json.dumps(row, separators=(',', ':')) + '\n' for row in rows))
    print('PASS exact new source fact and whole book transform published under unchanged collection limits.')


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--publish', action='store_true', required=True)
    parser.parse_args()
    publish()
