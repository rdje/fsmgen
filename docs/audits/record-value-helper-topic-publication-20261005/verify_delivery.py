"""Validate rendered guidance and whole query allocations, including separating controls."""
import copy
import hashlib
import json
import re
import sys
from html.parser import HTMLParser
from pathlib import Path

BASE = Path('docs/audits/record-value-helper-topic-publication-20261005')


class Text(HTMLParser):
    def __init__(self):
        super().__init__(); self.parts = []

    def handle_data(self, data):
        self.parts.append(data)


def normalize(text):
    return re.sub(r'\s+', ' ', text).strip()


def check_rendered(html, block):
    parser = Text(); parser.feed(html)
    expected = block.replace('```bash\n', '').replace('```\n', '')
    assert normalize(expected) in normalize(' '.join(parser.parts)), 'whole rendered helper topic guidance'


def check_queries(before, after, old_rows, new_rows):
    for row in (before, after['direct'], after['cached']):
        assert type(row['status']) is int and row['status'] == 0, 'exact executed successful query status'
    assert before['stdout'] == old_rows and after['direct']['stdout'] == after['cached']['stdout'] == new_rows, 'whole source-derived question-to-ID/path allocations'


def main(old_rows=None, new_rows=None):
    authority = json.loads((BASE / 'book-authority.json').read_text())
    captured = BASE / 'rendered-chapter.txt'
    live = Path('docs/book/book/13k-isf-feature-support-matrix.html')
    if '--capture' in sys.argv:
        assert not captured.exists(), 'retain first complete rendered capture'
        captured.write_bytes(live.read_bytes())
    html = captured.read_text(); check_rendered(html, authority['block'])
    if '--current' in sys.argv:
        check_rendered(live.read_text(), authority['block'])
    controls = []
    bad = html.replace('rollover debt remains open', 'rollover debt is closed')
    assert bad != html
    try:
        check_rendered(bad, authority['block'])
    except AssertionError as error:
        controls.append({'control': 'false-rendered-debt-closure', 'refusal': str(error)})
    else:
        raise AssertionError('false-green rendered meaning')
    before = json.loads((BASE / 'before-query.json').read_text())
    after = json.loads((BASE / 'after-query.json').read_text())
    if old_rows is not None:
        check_queries(before, after, old_rows, new_rows)
        bad = copy.deepcopy(after)
        question = 'what inventories original observer and callback source roles?'
        old = question + '\trecord-value-original-observer-helper-paths\tdocs/knowledge/record-value-original-observer-helper-paths.md'
        wrong = question + '\trecord-value-finite-copy-probe-reader\tdocs/knowledge/record-value-finite-copy-probe-reader.md'
        for row in bad.values():
            assert row['stdout'].count(old) == 1
            row['stdout'] = row['stdout'].replace(old, wrong)
        try:
            check_queries(before, bad, old_rows, new_rows)
        except AssertionError as error:
            controls.append({'control': 'same-count-wrong-question-owner', 'refusal': str(error)})
        else:
            raise AssertionError('false-green question allocation')
        bad = copy.deepcopy(after); bad['direct']['status'] = False
        try:
            check_queries(before, bad, old_rows, new_rows)
        except AssertionError as error:
            controls.append({'control': 'Boolean-query-status', 'refusal': str(error)})
        else:
            raise AssertionError('false-green query status kind')
        proof = {'rendered_bytes': captured.stat().st_size, 'rendered_sha256': hashlib.sha256(captured.read_bytes()).hexdigest(), 'controls': controls}
        path = BASE / 'delivery-proof.json'
        if path.exists():
            assert path.read_text() == json.dumps(proof, sort_keys=True, indent=2) + '\n'
        else:
            path.write_text(json.dumps(proof, sort_keys=True, indent=2) + '\n')


if __name__ == '__main__':
    main()
