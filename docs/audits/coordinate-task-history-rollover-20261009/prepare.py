"""Retire only the exact committed historical suffix under unchanged bounds."""
import hashlib
import json
from pathlib import Path
import subprocess

BASE = Path('docs/audits/coordinate-task-history-rollover-20261009')
REVISION = 'fc60d62ad51d844481cd4b9e6ae78eefa31c0b11'
TASK = Path('docs/tasks/SEMANTIC-INTROSPECTION-MCP-FRONTIER.md')
HISTORY = Path('docs/tasks/history/SEMANTIC-INTROSPECTION-MCP-FRONTIER/acceptance-history.jsonl')
BOOK = Path('docs/book/src/90-reference-map.md')
SURFACES = Path('doctrine/live_document_size/surfaces.jsonl')
BOUNDARY = b'## Completed Historical Implementation Notes\n'
VIEW = b'## Version-Retrievable Historical Views\n'
OLD = '''The next rollover boundary precedes the completed implementation notes. Its
preparatory commit preserves those notes; a separate rollover will authenticate
their exact committed source. The independent coordinate reader remains
required before whole coordinate qualification. Verify the boundary checkpoint:
'''
NEW = '''The completed implementation notes now resolve through the bounded history
manifest. Its exact predecessor preserves their complete source and prior
history chain; every task node remains live. Independent coordinate
qualification is still required. Replay the boundary and rollover proofs:
'''


def git(*args):
    return subprocess.check_output(['git', '--no-replace-objects', *args])


def main():
    assert git('rev-parse', 'HEAD').decode().strip() == REVISION
    assert not (BASE / 'book-transform.json').exists()
    source = git('show', REVISION + ':' + str(TASK))
    assert source.count(BOUNDARY) == 1
    suffix = source[source.index(BOUNDARY):]
    old_manifest = git('show', REVISION + ':' + str(HISTORY))
    assert HISTORY.read_bytes() == old_manifest
    registry, _ = list(map(json.loads, old_manifest.splitlines()))
    record = {'record_type': 'acceptance_history', 'schema_version': 1,
        'history_id': 'through_' + REVISION[:12], 'source_revision': REVISION,
        'source_path': str(TASK), 'source_sha256': hashlib.sha256(source).hexdigest(),
        'source_lines': source.count(b'\n'), 'source_bytes': len(source),
        'start_heading': 'Completed Historical Implementation Notes',
        'history_sha256': hashlib.sha256(suffix).hexdigest(),
        'history_lines': suffix.count(b'\n'), 'history_bytes': len(suffix),
        'history_sections': sum(line.startswith(b'## ') for line in suffix.splitlines()),
        'live_heading': 'Version-Retrievable Historical Views',
        'retention_contract': 'fsmgen_required_history'}
    current = TASK.read_bytes()
    assert current[current.index(BOUNDARY):] == suffix
    tail = source[source.index(VIEW):].replace(b'scripts/check_task_tree_integrity.pl\n',
        b'scripts/check_task_tree_integrity.pl\npython3 -B docs/audits/coordinate-task-history-rollover-20261009/verify.py\n', 1)
    TASK.write_bytes(current[:current.index(BOUNDARY)] + tail)
    HISTORY.write_text(''.join(json.dumps(row, sort_keys=True) + '\n' for row in (registry, record)))
    assert BOOK.read_bytes() == git('show', REVISION + ':' + str(BOOK))
    book = BOOK.read_text()
    assert book.count(OLD) == 1
    book = book.replace(OLD, NEW, 1)
    command = 'python3 -B docs/audits/coordinate-task-history-boundary-20261009/verify.py\n'
    assert book.count(command) == 1
    book = book.replace(command, command + 'python3 -B docs/audits/coordinate-task-history-rollover-20261009/verify.py\n', 1)
    BOOK.write_text(book)
    (BASE / 'book-transform.json').write_text(json.dumps({'old': OLD + '\n```sh\n' + command,
        'new': NEW + '\n```sh\n' + command + 'python3 -B docs/audits/coordinate-task-history-rollover-20261009/verify.py\n'}, sort_keys=True, indent=2) + '\n')
    print('PASS exact committed source/suffix manifest and reversible book transform; no live node retired.')


if __name__ == '__main__':
    main()
