"""Publish the deferred semantic partition from its current committed source."""
import hashlib
import json
import subprocess
from pathlib import Path

BASE = Path('docs/audits/record-value-helper-topic-publication-20261005')
PRIOR = Path('docs/audits/record-value-original-helper-join-20261005')
CORE = 'docs/knowledge/record-value-finite-copy-probe-reader.md'
DEST = 'docs/knowledge/record-value-original-observer-helper-paths.md'
REVISION = '49e46516b963057cae4f3e073a45ff794646cad3'


def write(path, data):
    path.write_text(json.dumps(data, sort_keys=True, indent=2) + '\n')


def run(command):
    result = subprocess.run(command, capture_output=True, text=True)
    return {'command': command, 'status': result.returncode, 'stdout': result.stdout, 'stderr': result.stderr}


def prepare():
    before = subprocess.check_output(['git', 'show', REVISION + ':' + CORE], text=True)
    assert before == Path(CORE).read_text() and not Path(DEST).exists(), 'exact current source and unused destination'
    old = json.loads((PRIOR / 'knowledge-transform.json').read_text())
    for path in (PRIOR / 'knowledge-transform.json', PRIOR / 'verify.py', PRIOR / 'proofs.json', PRIOR / 'manifest.json', PRIOR / 'scope.txt'):
        assert subprocess.check_output(['git', 'show', REVISION + ':' + str(path)]) == path.read_bytes(), 'complete committed source/model/template authority'
    start = before.index('Own\nobserver/callback source roles')
    end = before.index('Full observer/display/frame/coordinate/address', start)
    moved = before[start:end]
    current = before
    for question in old['moved_questions']:
        assert current.count(question + '\n') == 1
        current = current.replace(question + '\n', '')
    route = 'Own observer and helper source meanings are canonical in the\n[observer/helper path card](record-value-original-observer-helper-paths.md).\n'
    current = current.replace(moved, route)
    old_body = old['moved_body'].replace('Own\nobserver', 'Own observer')
    assert old['destination_after'].count(old_body) == 1
    destination = old['destination_after'].replace(old_body, moved.rstrip('\n').replace('Own\nobserver', 'Own observer') + '\n')
    original_open = before[end:before.index('\n\nReverify runs', end)]
    destination += '\nThe finite-copy core retains the original broader open boundary:\n\n' + original_open + '\n\nRelated: [[record-value-finite-copy-probe-reader]].\n'
    old_reader = '  docs/audits/record-value-original-helper-join-20261005/verify.py\n'
    new_reader = '  docs/audits/record-value-helper-topic-publication-20261005/verify.py --current\n'
    assert destination.count(old_reader) == 1
    destination = destination.replace(old_reader, new_reader)
    source = {'revision': REVISION, 'core_path': CORE, 'destination_path': DEST,
              'before': before, 'core_after': current, 'destination_after': destination,
              'moved_questions': old['moved_questions'], 'moved_body': moved,
              'normalized_moved_body': moved.rstrip('\n').replace('Own\nobserver', 'Own observer') + '\n',
              'route': route, 'original_open_boundary': original_open,
              'archived_template': (PRIOR / 'knowledge-transform.json').read_text(),
              'destination_reader_before': old_reader, 'destination_reader_after': new_reader,
              'whole_helper_source_pins': {str(p): {'bytes': p.stat().st_size, 'sha256': hashlib.sha256(p.read_bytes()).hexdigest()} for p in sorted(PRIOR.iterdir()) if p.is_file()}}
    write(BASE / 'transform.json', source)
    query = run(['knowledge-map/scripts/query_knowledge_map.sh', '--all', '--no-cache'])
    assert query['status'] == 0
    write(BASE / 'before-query.json', query)


def publish():
    source = json.loads((BASE / 'transform.json').read_text())
    assert Path(CORE).read_text() == source['before'] and not Path(DEST).exists()
    Path(CORE).write_text(source['core_after']); Path(DEST).write_text(source['destination_after'])


def after_queries():
    data = {'direct': run(['knowledge-map/scripts/query_knowledge_map.sh', '--all', '--no-cache']),
            'cached': run(['knowledge-map/scripts/query_knowledge_map.sh', '--all'])}
    write(BASE / 'after-query.json', data)
    assert all(row['status'] == 0 for row in data.values())


def book():
    path = Path('docs/book/src/13k-isf-feature-support-matrix.md')
    before = subprocess.check_output(['git', 'show', REVISION + ':' + str(path)], text=True)
    assert path.read_text() == before
    anchor = 'The complete semantic join and cold replay\nprecede the candidate-parent join and permanent test-copy and consumer repairs.\n'
    block = '''
The finite-copy core keeps its original fact ID and direct path. Its observer and
helper questions now route to a separate bounded semantic topic, with a return
route to the core. This separates copy-graph qualification from the original
helper allocation, supplied/default inputs, returned argument construction and
callback/refusal paths. The publication reader preserves the complete source
meaning and question ownership, checks actual direct and cached queries, and
rejects lost source roles, wrong routes and invented parser identity:

```bash
python3 -B docs/audits/record-value-helper-topic-publication-20261005/verify.py --current
```

This topic uses the capacity recovered by the admitted collection rollover.
Existing collection bounds remain in force; rollover debt remains open. The
separately owned subtest/require, framework/display, raw-coordinate and native
address/object-identity gaps remain explicit in both semantic topics.

'''
    assert before.count(anchor) == 1
    after = before.replace(anchor, anchor + block)
    paths = subprocess.check_output(['git', 'ls-tree', '-r', '--name-only', REVISION, '--', 'docs/book/src'], text=True).splitlines()
    paths = sorted(p for p in paths if p.endswith('.md'))
    originals = {p: subprocess.check_output(['git', 'show', REVISION + ':' + p]) for p in paths}
    updated = dict(originals); updated[str(path)] = after.encode()
    def aggregate(blobs):
        return {'files': len(blobs), 'lines_total': sum(raw.count(b'\n') for raw in blobs.values()), 'bytes_total': sum(map(len, blobs.values()))}
    old_surface = subprocess.check_output(['git', 'show', REVISION + ':doctrine/live_document_size/surfaces.jsonl'], text=True)
    assert Path('doctrine/live_document_size/surfaces.jsonl').read_text() == old_surface
    old_metrics = aggregate(originals); new_metrics = aggregate(updated)
    delta = {k: new_metrics[k]-old_metrics[k] for k in old_metrics}
    rows = list(map(json.loads, old_surface.splitlines()))
    target = next(r for r in rows if r.get('surface_id') == 'shipped_behavior')
    target['reference_contract']['aggregate_change'] = {
        'authority_id': 'HELPER-TOPIC-PUBLICATION-20261005-SHIPPED-BEHAVIOR',
        'baseline': old_metrics, 'delta': delta,
        'owner': 'SEMANTIC-INTROSPECTION-MCP-FRONTIER.72.3.2',
        'rationale': 'Explain distinct finite-copy and complete original-helper semantic topics, conserved source/question routes, and independent remaining qualification gaps.'}
    new_surface = ''.join(json.dumps(r, sort_keys=True, separators=(',', ':')) + '\n' for r in rows)
    authority = {'paths': paths, 'before': old_metrics, 'after': new_metrics, 'delta': delta,
                 'chapter_before': before, 'chapter_after': after, 'anchor': anchor, 'block': block,
                 'surface_before': old_surface, 'surface_after': new_surface}
    write(BASE / 'book-authority.json', authority)
    path.write_text(after); Path('doctrine/live_document_size/surfaces.jsonl').write_text(new_surface)


if __name__ == '__main__':
    import sys
    {'prepare': prepare, 'publish': publish, 'after-queries': after_queries, 'book': book}[sys.argv[1]]()
