"""Separate immutable source-publication evidence from current book currency."""
import argparse
import json
import subprocess
from html.parser import HTMLParser
from pathlib import Path

BASE = Path('docs/audits/record-value-own-subtest-boundaries-20261005')


class Text(HTMLParser):
    def __init__(self):
        super().__init__()
        self.parts = []

    def handle_data(self, data):
        self.parts.append(data)


def metrics(blobs):
    return {'files': len(blobs), 'lines_total': sum(raw.count(b'\n') for raw in blobs.values()),
            'bytes_total': sum(map(len, blobs.values()))}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--current', action='store_true')
    parser.add_argument('--build', default='docs/book/book')
    args = parser.parse_args()
    transform = json.loads((BASE / 'book-transform.json').read_text())
    before = {path: subprocess.check_output(['git', 'show', transform['revision'] + ':' + path]) for path in transform['paths']}
    assert before[transform['path']].decode() == transform['before'], 'whole prior committed book source'
    assert transform['before'].count(transform['marker']) == 1
    assert transform['before'].replace(transform['marker'], transform['block'] + transform['marker']) == transform['after']
    after = {**before, transform['path']: transform['after'].encode()}
    authority = {'before': metrics(before), 'after': metrics(after)}
    authority['delta'] = {key: authority['after'][key] - authority['before'][key] for key in authority['before']}
    assert authority == transform['authority'], 'whole historical aggregate derivation'
    assert transform['summary'] == before['docs/book/src/SUMMARY.md'].decode()
    if args.current:
        assert all(Path(path).read_bytes() == raw for path, raw in after.items()), 'whole current book publication boundary'
        surface = next(row for row in map(json.loads, Path('doctrine/live_document_size/surfaces.jsonl').read_text().splitlines())
                       if row.get('surface_id') == 'shipped_behavior')
        assert surface['reference_contract']['aggregate_change']['baseline'] == authority['before']
        assert surface['reference_contract']['aggregate_change']['delta'] == authority['delta']
        rendered = Path(args.build) / (Path(transform['path']).stem + '.html')
        text = Text(); text.feed(rendered.read_text())
        visible = ' '.join(' '.join(text.parts).split())
        for paragraph in transform['block'].strip().split('\n\n'):
            assert ' '.join(paragraph.split()) in visible, 'complete rendered own-source guidance'
    print('PASS whole book source transform/aggregate; current mode also checks rendered text. Visual QA remains pending.')


if __name__ == '__main__':
    main()
