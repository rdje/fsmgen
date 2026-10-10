"""Retain the complete dated final source/query/native publication for snapshot replay."""
import hashlib
import json
import sys
from pathlib import Path

sys.path.insert(0, str(Path('scripts').resolve()))
import check_record_value_publication as current

BASE = Path('docs/audits/coordinate-current-closure-20261010')


def pin(raw):
    return {'bytes': len(raw), 'sha256': hashlib.sha256(raw).hexdigest()}


def main():
    if (BASE / 'snapshot.json').exists():
        raise ValueError('refuse to overwrite complete closure capture')
    prior = current.historical()
    canonical = current.sources()
    record = current.current_input(prior, canonical)
    current.check(record, canonical, prior, current.authority(prior))
    rows = current.plane.expected_rows()
    current.plane.check(rows, 'docs/book/book')
    native = {}
    for chapter in (prior['CHAPTER'], prior['TOOLING_CHAPTER']):
        path = Path('docs/book/book') / (chapter.stem + '.html')
        raw = current.plane.local_read(path.resolve(), current.plane.SOURCE_BYTES * 4)
        destination = BASE / (chapter.stem + '.html.txt')
        destination.write_bytes(raw)
        earlier = BASE / ('reader-' + chapter.stem + '.html.txt')
        if earlier.read_bytes() != raw:
            raise ValueError('whole native guidance conserves across final pointer rebuild')
        native[str(chapter)] = {'path': str(destination), **pin(raw)}
    copied = {}
    for row in rows:
        source = current.plane.source_bytes(row['source'])
        raw = current.plane.local_read((Path('docs/book/book') / row['asset']).resolve(), current.plane.SOURCE_BYTES)
        if raw != source:
            raise ValueError('complete actual copied-source bytes conserve')
        copied[row['source']] = pin(raw)
    programmes = ['scripts/check_record_value_publication.py', 'scripts/record_value_coordinate_fact.py',
                  'scripts/book_source_references.py', 't/python/test_record_value_current_publication.py',
                  str(BASE / 'capture.py')]
    result = {'record': record, 'native': native, 'copied_sources': copied, 'routes': rows,
              'programmes': {p: pin(Path(p).read_bytes()) for p in programmes},
              'registry': Path('doctrine/live_document_size/surfaces.jsonl').read_text(),
              'navigation_source': Path('MEMORY.md').read_text(),
              'role': 'Complete dated final coordinate publication; saved current inputs do not establish later currency.'}
    (BASE / 'task-final.md.txt').write_bytes(Path('docs/tasks/SEMANTIC-INTROSPECTION-MCP-FRONTIER.md').read_bytes())
    if canonical != current.sources():
        raise ValueError('whole closure capture source epoch conserves')
    (BASE / 'snapshot.json').write_text(json.dumps(result, sort_keys=True, indent=2) + '\n')
    print('PASS complete final source/query/native capture and every current copied canonical source.')


if __name__ == '__main__':
    main()
