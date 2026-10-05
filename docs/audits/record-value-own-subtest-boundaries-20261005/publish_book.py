"""Publish the qualified own-source scope without changing prior reader guidance."""
import json
import subprocess
from pathlib import Path

BASE = Path('docs/audits/record-value-own-subtest-boundaries-20261005')
REVISION = 'eaf93f672d437da104dc4e5ebac23713be9592a2'
OWNER = 'SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.4.3.3.5.2.1.5.2.2.3.1.2.1.3.1.2.3.2.3.3.3.3.2.3.2.3.3.2.3.2.2.2.3.4.1'
PATH = 'docs/book/src/13k-isf-feature-support-matrix.md'
MARKER = 'The finite-copy core keeps its original fact ID and direct path.'
BLOCK = '''The own subtest source model now assigns original refusals to their complete
authored named bodies. The observer saves the public subtest delegate, wraps the
callback with its helper observer and forwards callback and extra arguments.
The original authored bodies supply no extra arguments. Recorded headers agree
with empty visible body/callback arguments, the authored subtest name and a CODE
reference kind at the public delegate and own entry. Framework frames between
these own roles remain opaque; a CODE kind does not establish callback identity.

The original observer loads the test with do and captures its return/error state.
The recorded require marker agrees with the exact test file identifier; it does
not change the source operator or establish trace formatting. Captured installed
public POD supports the call/load interfaces for the current toolchain. The
original framework version remains unmeasured. Complete source and recorded-role
qualification is in docs/audits/record-value-own-subtest-boundaries-20261005;
publication to the semantic fact topic is the separately owned next slice.
Public framework/display, source-coordinate and native identity gaps remain open.

'''


def metrics(blobs):
    return {'files': len(blobs), 'lines_total': sum(raw.count(b'\n') for raw in blobs.values()),
            'bytes_total': sum(map(len, blobs.values()))}


def main():
    assert not (BASE / 'book-transform.json').exists()
    # Publication follows source qualification; a plausible paragraph is not evidence.
    assert (BASE / 'proofs.json').exists() and (BASE / 'public-proofs.json').exists()
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
                'authority_id': 'OWN-SUBTEST-20261005-SHIPPED-BEHAVIOR',
                'baseline': authority['before'], 'delta': authority['delta'], 'owner': OWNER,
                'rationale': 'Qualify own authored subtest/delegate/do-load roles while preserving opaque framework and original-version gaps.'}
            lines[index] = json.dumps(row, sort_keys=True)
    registry.write_text('\n'.join(lines) + '\n')
    print('PASS complete own-source book insertion, unchanged SUMMARY and measured aggregate authority.')


if __name__ == '__main__':
    main()
