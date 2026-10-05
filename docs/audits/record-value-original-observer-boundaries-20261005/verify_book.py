"""Whole source transformation, aggregate and rendered-text check for this slice."""
import json
import re
import subprocess
from html.parser import HTMLParser
from pathlib import Path

BASE = Path('docs/audits/record-value-original-observer-boundaries-20261005')


class Text(HTMLParser):
    def __init__(self):
        super().__init__()
        self.parts = []

    def handle_data(self, data):
        self.parts.append(data)


def census(raws):
    return {'files': len(raws), 'bytes_total': sum(len(raw) for raw in raws),
            'lines_total': sum(len(raw.splitlines()) for raw in raws)}


def main():
    transform = json.loads((BASE / 'book-transform.json').read_text())
    authority = json.loads((BASE / 'book-authority.json').read_text())
    original = subprocess.check_output(['git', 'show', transform['revision'] + ':' + transform['path']]).decode()
    assert original == transform['before'], 'whole prior committed book source'
    expected = original
    for old, new in transform['replacements']:
        assert expected.count(old) == 1, 'unique authored replacement'
        expected = expected.replace(old, new)
    assert expected == transform['after'] == Path(transform['path']).read_text(), 'whole current book source transformation'
    paths = sorted(Path('docs/book/src').glob('*.md'))
    before = census([subprocess.check_output(['git', 'show', transform['revision'] + ':' + str(path)]) for path in paths])
    after = census([path.read_bytes() for path in paths])
    assert authority == {'before': before, 'after': after, 'delta': {key: after[key] - before[key] for key in before}}, 'whole aggregate authority'
    surface = next(row for row in map(json.loads, Path('doctrine/live_document_size/surfaces.jsonl').read_text().splitlines()) if row.get('surface_id') == 'shipped_behavior')
    assert surface['reference_contract']['aggregate_change']['baseline'] == before
    assert surface['reference_contract']['aggregate_change']['delta'] == authority['delta']
    rendered = Path('docs/book/book') / (Path(transform['path']).stem + '.html')
    parser = Text(); parser.feed(rendered.read_text())
    visible = ' '.join(' '.join(parser.parts).split())
    for _, new in transform['replacements']:
        plain = re.sub(r'\[([^\]]+)\]\([^)]+\)', r'\1', new)
        assert ' '.join(plain.split()) in visible, 'complete rendered new paragraph text'
    print('PASS whole book source/replacement/aggregate and rendered observer-boundary/open-trace guidance; visual QA remains pending.')


if __name__ == '__main__':
    main()
