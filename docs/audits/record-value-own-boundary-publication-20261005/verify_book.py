"""Qualify current complete source/aggregate and the scoped native reader text."""
import argparse
import json
import re
import subprocess
from html.parser import HTMLParser
from pathlib import Path

BASE = Path('docs/audits/record-value-own-boundary-publication-20261005')


class Text(HTMLParser):
    def __init__(self):
        super().__init__(); self.parts = []

    def handle_data(self, data):
        self.parts.append(data)


def check_rendered(html, publication):
    mains = re.findall(r'<main\b[^>]*>(.*?)</main>', html, re.S)
    assert len(mains) == 1, 'unique native publication chapter body'
    parser = Text(); parser.feed(mains[0]); visible = ' '.join(' '.join(parser.parts).split())
    section = publication['reader_section'].replace('```bash\n', '').replace('```\n', '')
    paragraphs = [' '.join(paragraph.split()) for paragraph in section.strip().split('\n\n')]
    paragraphs += ['the semantic fact topic now publishes these qualified own source boundaries.',
                   'current-role flag. Current semantic/fact/source qualification uses the publication reader below; its historical leg remains separate.']
    assert all(visible.count(paragraph) == 1 for paragraph in paragraphs), 'complete unique rendered source/current/historical guidance'
    return paragraphs


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--current', action='store_true')
    parser.add_argument('--build', default='.artifacts/own-boundary-publication/book')
    args = parser.parse_args()
    publication = json.loads((BASE / 'publication.json').read_text())
    # Source and aggregate authority is independently recomputed from the recorded Git boundary.
    before = {path: subprocess.check_output(['git', 'show', publication['revision'] + ':' + path]) for path in publication['book_paths']}
    path = 'docs/book/src/13k-isf-feature-support-matrix.md'
    assert before[path].decode() == publication['before'][path]
    after = {**before, path: publication['after'][path].encode()}
    def metrics(blobs):
        return {'files': len(blobs), 'lines_total': sum(raw.count(b'\n') for raw in blobs.values()), 'bytes_total': sum(map(len, blobs.values()))}
    authority = publication['book_authority']
    assert metrics(before) == authority['before'] and metrics(after) == authority['after']
    assert authority['delta'] == {key: authority['after'][key]-authority['before'][key] for key in authority['before']}
    assert before['docs/book/src/SUMMARY.md'].decode() == publication['summary']
    if args.current:
        assert all(Path(name).read_bytes() == raw for name, raw in after.items()), 'whole current native publication source boundary'
        surface = next(row for row in map(json.loads, Path('doctrine/live_document_size/surfaces.jsonl').read_text().splitlines()) if row.get('surface_id') == 'shipped_behavior')
        assert surface['reference_contract']['aggregate_change']['baseline'] == authority['before']
        assert surface['reference_contract']['aggregate_change']['delta'] == authority['delta']
        rendered = Path(args.build) / (Path(path).stem + '.html')
        html = rendered.read_text(); paragraphs = check_rendered(html, publication)
        controls = []
        for name, old, new in [('wrong-current-command', 'own-boundary-publication-20261005/verify.py --current', 'own-boundary-publication-20261005/verify.py --snapshot'),
                               ('lost-historical-scope', 'Snapshot\nsuccess does not supply current semantic currency.', 'Snapshot\nsuccess supplies current semantic currency.')]:
            changed = html.replace(old, new)
            assert changed != html, 'genuine rendered publication mutation'
            try:
                check_rendered(changed, publication)
            except AssertionError as error:
                controls.append({'control': name, 'status': 1, 'cause': str(error)})
            else:
                raise AssertionError('false-green rendered publication control')
        proof = {'paragraphs': paragraphs, 'controls': controls, 'scope': 'Whole current source/SUMMARY/aggregate and exact rendered reader scope/commands; visual QA remains pending.'}
        target = BASE / 'book-proofs.json'
        if target.exists():
            assert json.loads(target.read_text()) == proof
        else:
            assert not (BASE / 'manifest.json').exists()
            target.write_text(json.dumps(proof, sort_keys=True, indent=2)+'\n')
    print('PASS whole book source/SUMMARY/aggregate and scoped rendered publication guidance; visual QA remains pending.')


if __name__ == '__main__':
    main()
