"""Inspect and remove only this slice's successfully rendered disposable book."""
from html.parser import HTMLParser
import json
from pathlib import Path
import re

BASE = Path(__file__).resolve().parent
ROOT = BASE.parents[2]
LOG = ROOT / '.artifacts/logs' / BASE.name
OUTPUT = ROOT / '.artifacts/tmp/native-proxy-lifetime-controls-final-admission-book-20260913/book'
PASSAGES = ['Final control admission now selects a corrected descriptor identity reader.', 'It follows recorded creation, writes and permission changes in call order, then joins each open to the independently observed object and final state.', 'These synthetic journals are reader tests and do not establish actual interruption effects.', 'An existing permit cannot be overwritten.', 'docs/audits/native-proxy-lifetime-controls-final-admission-20260913/audit_final.py --verify-saved']


class Text(HTMLParser):
    def __init__(self):
        super().__init__()
        self.fragments = []

    def handle_data(self, data):
        self.fragments.append(data)


def direct(path):
    for node in [path, *path.parents]:
        if node == ROOT:
            break
        assert not node.is_symlink() and node.stat().st_dev == ROOT.stat().st_dev


def main():
    assert (LOG / 'book.exit').read_bytes() == b'0\n'
    direct(OUTPUT)
    paths = list(OUTPUT.rglob('*'))
    for path in paths:
        direct(path)
        assert path.is_file() or path.is_dir()
    page = OUTPUT / '16dk-inactive-proxy-lifetimes.html'
    parser = Text()
    parser.feed(page.read_text())
    rendered = ' '.join(' '.join(parser.fragments).replace('\u2019', "'").split())
    for passage in PASSAGES:
        assert passage in rendered, passage
    files = [path for path in paths if path.is_file()]
    directories = [path for path in paths if path.is_dir()]
    review = dict(output=str(OUTPUT.relative_to(ROOT)), exit_code=0, checked_passages=PASSAGES,
        rendered_files=len(files), rendered_directories=len(directories),
        rendered_bytes=sum(path.stat().st_size for path in files), same_volume_direct_objects=True,
        renderer_warnings=re.findall(r'WARN[^\n]*', (LOG / 'book.stderr').read_text()))
    for path in files:
        path.unlink()
    for path in sorted(directories, key=lambda item: len(item.parts), reverse=True):
        path.rmdir()
    OUTPUT.rmdir()
    OUTPUT.parent.rmdir()
    review['exact_output_absent'] = not OUTPUT.exists() and not OUTPUT.is_symlink()
    with (BASE / 'book-review.json').open('x') as stream:
        stream.write(json.dumps(review, sort_keys=True, indent=2) + '\n')
    print(json.dumps(review, sort_keys=True))


if __name__ == '__main__':
    main()
