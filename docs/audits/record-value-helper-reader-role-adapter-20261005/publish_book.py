"""Publish the historical adapter role without replacing live reader guidance."""
import json
import subprocess
from pathlib import Path

BASE = Path('docs/audits/record-value-helper-reader-role-adapter-20261005')
REVISION = 'ebd3df0c21d2e8383e179cf88a81f0c780568e14'
OWNER = 'SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.4.3.3.5.2.1.5.2.2.3.1.2.1.3.1.2.3.2.3.3.3.3.2.3.2.3.3.2.3.2.2.2.3.4.2.1'
PATH = 'docs/book/src/13k-isf-feature-support-matrix.md'
MARKER = 'The finite-copy core keeps its original fact ID and direct path.'
BLOCK = '''The original source-plane reader's historical replay also invoked the older
live helper reader. An actual source-qualified card extension exposed that
coupling: a new live fact obstructed replay of unchanged historical evidence.
The qualified adapter preserves the original plane predicates and products,
changing only that call to the helper's existing snapshot mode:

```bash
python3 -B docs/audits/record-value-helper-reader-role-adapter-20261005/adapter.py --snapshot
```

This command authenticates historical evidence. It does not qualify current
cards, queries, source assets or advertised reader guidance, and it rejects a
current-role flag. Current semantic/fact publication is the separately owned
next slice; the existing live reader remains required for its current epoch.
Original historical programmes and seals remain unchanged.

'''


def metrics(blobs):
    return {'files': len(blobs), 'lines_total': sum(raw.count(b'\n') for raw in blobs.values()),
            'bytes_total': sum(map(len, blobs.values()))}


def main():
    assert not (BASE / 'book-transform.json').exists()
    # Publication follows actual coupling and candidate/role qualification.
    assert (BASE / 'control-proofs.json').exists() and (BASE / 'candidate-adapter.json').exists()
    paths = subprocess.check_output(['git', 'ls-tree', '-r', '--name-only', REVISION, '--', 'docs/book/src'], text=True).splitlines()
    paths = [path for path in paths if path.endswith('.md') and Path(path).parent == Path('docs/book/src')]
    before = {path: subprocess.check_output(['git', 'show', REVISION + ':' + path]) for path in paths}
    assert all(Path(path).read_bytes() == raw for path, raw in before.items())
    body = before[PATH].decode()
    assert body.count(MARKER) == 1
    after = {**before, PATH: body.replace(MARKER, BLOCK + MARKER).encode()}
    authority = {'before': metrics(before), 'after': metrics(after)}
    authority['delta'] = {key: authority['after'][key] - authority['before'][key] for key in authority['before']}
    transform = {'revision': REVISION, 'path': PATH, 'paths': paths, 'before': body,
                 'after': after[PATH].decode(), 'block': BLOCK, 'marker': MARKER,
                 'summary': before['docs/book/src/SUMMARY.md'].decode(), 'authority': authority}
    (BASE / 'book-transform.json').write_text(json.dumps(transform, sort_keys=True, indent=2) + '\n')
    Path(PATH).write_bytes(after[PATH])
    registry = Path('doctrine/live_document_size/surfaces.jsonl')
    lines = registry.read_text().splitlines()
    for index, line in enumerate(lines):
        row = json.loads(line)
        if row.get('surface_id') == 'shipped_behavior':
            row['reference_contract']['aggregate_change'] = {
                'authority_id': 'HISTORICAL-READER-ROLE-20261005-SHIPPED-BEHAVIOR',
                'baseline': authority['before'], 'delta': authority['delta'], 'owner': OWNER,
                'rationale': 'Document the historical helper snapshot role without substituting it for current semantic and source-plane qualification.'}
            lines[index] = json.dumps(row, sort_keys=True)
    registry.write_text('\n'.join(lines) + '\n')
    print('PASS complete historical-role book insertion, unchanged SUMMARY and measured aggregate authority.')


if __name__ == '__main__':
    main()
