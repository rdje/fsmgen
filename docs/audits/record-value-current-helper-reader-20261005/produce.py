"""Adapt only the live reader and its public guidance; preserve sealed publication."""
import json
import subprocess
from pathlib import Path

BASE = Path('docs/audits/record-value-current-helper-reader-20261005')
CORE = 'docs/knowledge/record-value-finite-copy-probe-reader.md'
TOPIC = 'docs/knowledge/record-value-original-observer-helper-paths.md'
CHAPTER = 'docs/book/src/13k-isf-feature-support-matrix.md'
SURFACE = 'doctrine/live_document_size/surfaces.jsonl'


def main():
    source = json.loads((BASE / 'source.json').read_text()); before = source['before']
    assert all(Path(p).read_text() == body for p, body in before.items())
    old = '  docs/audits/record-value-helper-topic-publication-20261005/verify.py --current\n'
    new = '  docs/audits/record-value-current-helper-reader-20261005/verify.py --current\n'
    assert before[TOPIC].count(old) == 1
    topic = before[TOPIC].replace(old, new)
    old_command = 'python3 -B docs/audits/record-value-helper-topic-publication-20261005/verify.py --current'
    new_command = 'python3 -B docs/audits/record-value-current-helper-reader-20261005/verify.py --current'
    assert before[CHAPTER].count(old_command) == 1
    anchor = 'separately owned subtest/require, framework/display, raw-coordinate and native\naddress/object-identity gaps remain explicit in both semantic topics.\n'
    block = '''
The live helper reader checks the current core and topic, their complete question
ownership and source routes, and this reader guidance. It also authenticates the
original sealed publication at its recorded boundary. That historical census and
whole-book authority remain snapshot evidence; an unrelated chapter edit does
not change the helper source meanings or require a new helper capture. Relevant
source, role, question and route changes still require qualification.
'''
    assert before[CHAPTER].count(anchor) == 1
    chapter = before[CHAPTER].replace(old_command, new_command).replace(anchor, anchor + block)
    paths = sorted(p for p in subprocess.check_output(['git', 'ls-tree', '-r', '--name-only', source['revision'], '--', 'docs/book/src'], text=True).splitlines() if p.endswith('.md'))
    blobs = {p: subprocess.check_output(['git', 'show', source['revision'] + ':' + p]) for p in paths}
    def aggregate(values):
        return {'files': len(values), 'lines_total': sum(v.count(b'\n') for v in values.values()), 'bytes_total': sum(map(len, values.values()))}
    baseline = aggregate(blobs); blobs[CHAPTER] = chapter.encode(); after_metrics = aggregate(blobs)
    delta = {k: after_metrics[k]-baseline[k] for k in baseline}
    rows = list(map(json.loads, before[SURFACE].splitlines()))
    next(r for r in rows if r.get('surface_id') == 'shipped_behavior')['reference_contract']['aggregate_change'] = {
        'authority_id': 'CURRENT-HELPER-READER-20261005-SHIPPED-BEHAVIOR', 'baseline': baseline, 'delta': delta,
        'owner': 'SEMANTIC-INTROSPECTION-MCP-FRONTIER.73.2.3.1',
        'rationale': 'Separate live helper source/question/route qualification from immutable publication census and whole-book authority, preserving all historical proofs.'}
    registry = ''.join(json.dumps(r, sort_keys=True, separators=(',', ':'))+'\n' for r in rows)
    after = {CORE: before[CORE], TOPIC: topic, CHAPTER: chapter, SURFACE: registry}
    data = {'before': before, 'after': after, 'old_reader': old, 'new_reader': new,
            'old_command': old_command, 'new_command': new_command, 'anchor': anchor, 'block': block,
            'book_paths': paths, 'book_before': baseline, 'book_after': after_metrics, 'book_delta': delta}
    marker = 'The finite-copy core keeps its original fact ID and direct path.'
    data['reader_marker'] = marker
    data['reader_section'] = chapter[chapter.index(marker):chapter.index(block)+len(block)]
    target = BASE / 'transform.json'; assert not target.exists()
    target.write_text(json.dumps(data, sort_keys=True, indent=2)+'\n')
    for p, body in after.items(): Path(p).write_text(body)


if __name__ == '__main__':
    main()
