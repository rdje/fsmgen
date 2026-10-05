"""Verify live checklist policy routing and exact completed-history preservation."""
import json
import hashlib
import re
import subprocess
from html.parser import HTMLParser
from pathlib import Path

BASE = Path('docs/audits/isf-sync-checklist-qualified-20261005')


def contract(block):
    assert not any(name in block for name in ('ROADMAP_STATUS.md', 'CHANGES.md', 'LIVE_ACHIEVEMENT_STATUS.md')), 'retired journals cannot be current update targets'
    assert 'Update\n  `DEVELOPMENT_NOTES.md` only' in block and 'add no placeholder' in block, 'conditional engineering rationale'
    assert 'Update `README.md` only when the project objective, first-use path' in block, 'bounded README maintenance'
    assert 'derive the current\n  repository revision from Git' in block, 'derive repository revision on read'
    assert 'sole commit-policy authority' in block and '`COMMIT.md`' in block, 'single canonical commit policy'
    assert 'historical evidence; they need no per-slice\n  backfill' in block, 'optional task views stay historical'


def source_check(record, actual):
    before = subprocess.check_output(['git', 'show', record['revision'] + ':' + record['source_path']], text=True)
    assert before == record['source_before'], 'whole committed checklist predecessor'
    assert before.count(record['old_block']) == 1, 'unique live checklist block'
    assert actual == record['source_after'] == before.replace(record['old_block'], record['new_block']), 'whole source transformation and historical preservation'
    contract(record['new_block'])
    # This independently selects the complete authoritative node block, rather
    # than treating the document's aggregate equality as task-graph evidence.
    pattern = r'## Task Tree\n(.*?)\n## Current Frontier\n'
    assert re.search(pattern, actual, re.S).group(1) == re.search(pattern, before, re.S).group(1), 'complete finished task graph preservation'


class Text(HTMLParser):
    def __init__(self):
        super().__init__(); self.parts = []

    def handle_data(self, data):
        self.parts.append(data)


def census(raws):
    return {'files': len(raws), 'lines_total': sum(len(raw.splitlines()) for raw in raws), 'bytes_total': sum(len(raw) for raw in raws)}


def main():
    supersedes = json.loads((BASE / 'supersedes.json').read_text())
    initial = Path(supersedes['predecessor_path'])
    expected = supersedes['predecessor_manifest']
    actual_initial = {p.name: {'bytes': len(p.read_bytes()), 'sha256': hashlib.sha256(p.read_bytes()).hexdigest()}
                      for p in initial.iterdir() if p.name != 'manifest.json'}
    assert actual_initial == expected == json.loads((initial / 'manifest.json').read_text()), 'whole superseded reader/source seal'
    record = json.loads((BASE / 'transform.json').read_text())
    actual = Path(record['source_path']).read_text()
    source_check(record, actual)
    try:
        contract(record['old_block'])
    except AssertionError as error:
        assert str(error) == 'retired journals cannot be current update targets', 'actual original contrary-guidance cause'
    else:
        raise AssertionError('false-green original stale checklist')
    bad_history = actual.replace('Status: `done`', 'Status: `pending`', 1)
    try:
        source_check(record, bad_history)
    except AssertionError as error:
        assert str(error) == 'whole source transformation and historical preservation', 'actual history-loss control'
    else:
        raise AssertionError('false-green rewritten historical task')
    for old, new, cause in (
        ('`DEVELOPMENT_NOTES.md` only', '`DEVELOPMENT_NOTES.md` always', 'conditional engineering rationale'),
        ('Update `README.md` only', 'Update `README.md` always', 'bounded README maintenance'),
        ('sole commit-policy authority', 'secondary commit-policy authority', 'single canonical commit policy'),
    ):
        mutated = record['new_block'].replace(old, new)
        assert mutated != record['new_block'], 'actual current guidance mutation'
        try:
            contract(mutated)
        except AssertionError as error:
            assert str(error) == cause, 'intended contrary-guidance control'
        else:
            raise AssertionError('false-green contrary current guidance')
    intake = json.loads((BASE / 'reader-census.json').read_text())
    result = subprocess.run(intake['command'], capture_output=True, text=True)
    assert result.returncode == intake['status'] == 0 and result.stdout == intake['stdout'] and result.stderr == intake['stderr'], 'complete scoped current reader census'
    assert record['source_path'] in Path('docs/TASK_TREE.md').read_text(), 'task index selects this live reference'
    book_before = subprocess.check_output(['git', 'show', record['revision'] + ':' + record['book_path']], text=True)
    old, new = record['book_replacement']
    assert book_before == record['book_before'] and book_before.count(old) == 1
    assert record['book_after'] == Path(record['book_path']).read_text() == book_before.replace(old, new), 'whole book transformation'
    paths = sorted(Path('docs/book/src').glob('*.md'))
    before = census([subprocess.check_output(['git', 'show', record['revision'] + ':' + str(path)]) for path in paths])
    after = census([path.read_bytes() for path in paths])
    authority = json.loads((BASE / 'book-authority.json').read_text())
    assert authority == {'before': before, 'after': after, 'delta': {key: after[key] - before[key] for key in before}}, 'whole book aggregate authority'
    surface = next(row for row in map(json.loads, Path('doctrine/live_document_size/surfaces.jsonl').read_text().splitlines()) if row.get('surface_id') == 'shipped_behavior')
    assert surface['reference_contract']['aggregate_change']['baseline'] == before and surface['reference_contract']['aggregate_change']['delta'] == authority['delta'], 'declared exact book delta'
    rendered = Path('docs/book/book/90-reference-map.html')
    parser = Text(); parser.feed(rendered.read_text())
    assert ' '.join(new.replace('`', '').split()) in ' '.join(''.join(parser.parts).split()), 'whole rendered maintainer guidance'
    print('PASS current live checklist routing, entire historical task/source preservation, actual stale/contrary/history-loss controls, scoped reader census and whole source/aggregate/rendered book guidance.')


if __name__ == '__main__':
    main()
