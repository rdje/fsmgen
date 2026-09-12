"""Inspect this slice's generated book, then remove its exact owned output."""
import hashlib
from html.parser import HTMLParser
import json
from pathlib import Path
import shutil

BASE = Path(__file__).resolve().parent
ROOT = BASE.parents[2]
OUTPUT = Path('.artifacts/tmp/native-proxy-release-close-last-book-20260912/book')
LOG = ROOT / '.artifacts/logs' / BASE.name


class PlainText(HTMLParser):
    def __init__(self):
        super().__init__()
        self.chunks = []

    def handle_data(self, data):
        self.chunks.append(data)


def main():
    raw = (BASE / 'inspect-book.py').read_bytes()
    assert json.loads((BASE / 'book-review-pins.json').read_bytes()) == [dict(
        path=str((BASE / 'inspect-book.py').relative_to(ROOT)), size_bytes=len(raw),
        sha256=hashlib.sha256(raw).hexdigest())]
    assert (LOG / 'book.exit').read_bytes() == b'0\n'
    output = ROOT / OUTPUT
    nodes = [output, *output.rglob('*')]
    assert all(not p.is_symlink() and p.stat().st_dev == ROOT.stat().st_dev
               and (p.is_file() or p.is_dir()) for p in nodes)
    parser = PlainText()
    parser.feed((output / '16dc-vial-portable-verilator-runtime-measurement.html').read_text())
    text = ' '.join(' '.join(parser.chunks).split()).replace('\u2019', "'")
    phrases = ['Last-observation release close qualification covers 149 cases: 1 healthy control and 148 single EIO reports, with 1813 TAP assertions.', 'The observed release begins with only the selected hold referencing the image.', 'An early close error leaves that hold intact.', 'The canonical image directory, source, executable bytes and metadata keep their original identities and contents.', 'The auditor counts image references from the stored reference records and checks the entire original image subtree.', 'python3 -B docs/audits/native-proxy-observation-archive-release-close-last-20260912/audit.py --verify-saved']
    for phrase in phrases:
        assert phrase in text, phrase
    files = [p for p in nodes if p.is_file()]
    report = dict(exit_code=0, output=str(OUTPUT), checked_passages=phrases,
        rendered_files=len(files), rendered_directories=sum(p.is_dir() for p in nodes),
        rendered_bytes=sum(p.stat().st_size for p in files), same_volume_direct_objects=True,
        renderer_warnings=[l.strip() for l in (LOG / 'book.stderr').read_text().splitlines() if 'WARN' in l])
    shutil.rmtree(output)
    output.parent.rmdir()
    for name in ('book.stdout', 'book.stderr'):
        (LOG / name).unlink()
    report['exact_output_absent'] = not output.exists()
    with (BASE / 'book-review.json').open('x') as stream:
        stream.write(json.dumps(report, sort_keys=True, indent=2) + '\n')
    print(json.dumps(report, sort_keys=True))


if __name__ == '__main__':
    main()
