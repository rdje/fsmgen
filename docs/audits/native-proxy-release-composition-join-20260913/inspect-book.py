"""Inspect this slice's generated book, then remove its exact owned output."""
import hashlib
from html.parser import HTMLParser
import json
from pathlib import Path
import shutil

BASE = Path(__file__).resolve().parent
ROOT = BASE.parents[2]
OUTPUT = Path('.artifacts/tmp/native-proxy-release-composition-join-book-20260913/book')
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
    phrases = ['The bounded release-composition join verifies 180 cases: 4 healthy controls, 80 grouped-close cases and 96 primary-error cases, with 2,440 original TAP assertions.', 'Every observed handle closes, and the earliest primary error survives later cleanup reports.', 'Actual reads and closes remain distinct from reported errors.', 'For each fault recipe, a pure comparison reverses declaration order on the same saved inputs.', 'This comparison adds no fixture execution or TAP assertions.', 'python3 -B docs/audits/native-proxy-release-composition-join-20260913/audit.py --verify-saved']
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
