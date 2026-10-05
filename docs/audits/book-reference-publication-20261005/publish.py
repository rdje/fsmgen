"""Apply only the qualified reference destinations and declared reader guidance."""
import json
import subprocess
from pathlib import Path

BASE = Path('docs/audits/book-reference-publication-20261005')
REVISION = '7b67fa41e7961ea74f51c42680aaf6e610c5ba76'
SELECTED = 'docs/audits/book-reference-selection-20261005/selected-routes.json'
CLASSIFIED = 'docs/audits/book-reference-classification-20261005/classification.json'
OLD_GUIDANCE = """The asset plane is available; this chapter's reference-link transition remains
pending. The next publication will point its selected references to those
views. Native source refresh requires the source and its endpoint to be
admitted by the ignore policy; build success alone does not establish that."""
NEW_GUIDANCE = """The selected references in this chapter and the feature-support matrix open
these source views. Their labels identify the canonical repository documents;
the served text reflects the latest book build. Native source refresh requires
the source and its endpoint to be admitted by the ignore policy; build success
alone does not establish that. Links inside a raw source view remain text."""


def transformed(before, rows, classifications):
    after = dict(before)
    for row in rows:
        original = next(item for item in classifications
                        if item['chapter'] == row['chapter'] and item['source']['canonical'] == row['source'])
        assert original['rendered_href'] == row['old_href'] and original['role'] == row['role']
        path = 'docs/book/src/' + row['chapter'] + '.md'
        old = '](' + original['source']['href'] + ')'
        assert after[path].count(old) == 1, 'unique source-associated classified destination'
        after[path] = after[path].replace(old, '](' + row['asset'] + ')')
    path = 'docs/book/src/90-reference-map.md'
    assert after[path].count(OLD_GUIDANCE) == 1
    after[path] = after[path].replace(OLD_GUIDANCE, NEW_GUIDANCE)
    return after


def metrics(blobs):
    return {'files': len(blobs), 'lines_total': sum(raw.count(b'\n') for raw in blobs.values()),
            'bytes_total': sum(len(raw) for raw in blobs.values())}


def main():
    assert not (BASE / 'source-boundary.json').exists()
    rows = json.loads(Path(SELECTED).read_text())['routes']
    classifications = json.loads(Path(CLASSIFIED).read_text())['classified_links']
    assert len(rows) == len(classifications)
    before = {p: subprocess.check_output(['git', 'show', REVISION + ':' + p]).decode()
              for p in sorted({'docs/book/src/' + row['chapter'] + '.md' for row in rows})}
    assert all(Path(path).read_bytes().decode() == body for path, body in before.items())
    after = transformed(before, rows, classifications)
    all_before = {str(p): subprocess.check_output(['git', 'show', REVISION + ':' + str(p)])
                  for p in Path('docs/book/src').glob('*.md')}
    all_after = dict(all_before)
    all_after.update({p: text.encode() for p, text in after.items()})
    authority = {'before': metrics(all_before), 'after': metrics(all_after)}
    authority['delta'] = {key: authority['after'][key] - authority['before'][key] for key in authority['before']}
    record = {'revision': REVISION, 'before': before, 'after': after, 'authority': authority,
              'summary': all_before['docs/book/src/SUMMARY.md'].decode()}
    (BASE / 'source-boundary.json').write_text(json.dumps(record, sort_keys=True, indent=2) + '\n')
    for path, body in after.items():
        Path(path).write_bytes(body.encode())
    registry = Path('doctrine/live_document_size/surfaces.jsonl')
    lines = registry.read_text().splitlines()
    for index, line in enumerate(lines):
        row = json.loads(line)
        if row.get('surface_id') == 'shipped_behavior':
            row['reference_contract']['aggregate_change'] = {
                'authority_id': 'BOOK-REFERENCE-PUBLICATION-20261005-SHIPPED-BEHAVIOR',
                'baseline': authority['before'], 'delta': authority['delta'],
                'owner': 'SEMANTIC-INTROSPECTION-MCP-FRONTIER.73.2.3.3',
                'rationale': 'Deliver classified canonical references through exact native source views and document literal-source/build boundaries.'}
            lines[index] = json.dumps(row, sort_keys=True)
    registry.write_text('\n'.join(lines) + '\n')
    print('PASS exact classified destination replacement, complete source boundary, unchanged SUMMARY and measured aggregate.')


if __name__ == '__main__':
    main()
