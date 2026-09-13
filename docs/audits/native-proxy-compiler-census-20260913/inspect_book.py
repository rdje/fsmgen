"""Inspect and remove only this slice's successfully rendered disposable book."""
from html.parser import HTMLParser
import json
from pathlib import Path
import re

BASE = Path(__file__).resolve().parent
ROOT = BASE.parents[2]
LOG = ROOT / '.artifacts/logs/native-proxy-compiler-census-execution-20260913'
OUTPUT = ROOT / '.artifacts/tmp/native-proxy-compiler-preflight-book-20260913/book'
PASSAGES = ['The first invocation stopped at Git preflight, before permit consumption, workspace creation or compiler launch.', 'Ordinary Git used a personal ignore rule for .claude/settings.local.json; the closed environment exposed that file as untracked work.', 'A repository-only ignore check reproduced the difference.', 'The original permit and failed output remain preserved.', 'No authentic compiler-workspace profile has been collected.', 'docs/audits/native-proxy-compiler-census-20260913/audit.py --verify-saved']
RUNTIME_PASSAGES = ['observer lifetimes and selected empty-store coordination are qualified below; native behavior and populated-worker qualification remain open.', 'real receipt transport and native behavior remain open.']


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
    rendered = ' '.join(''.join(parser.fragments).replace('\u2019', "'").split())
    for passage in PASSAGES:
        assert passage in rendered, passage
    runtime = Text()
    runtime.feed((OUTPUT / '16dc-vial-portable-verilator-runtime-measurement.html').read_text())
    runtime_text = ' '.join(' '.join(runtime.fragments).replace('\u2019', "'").split())
    for passage in RUNTIME_PASSAGES:
        assert passage in runtime_text, passage
    files = [path for path in paths if path.is_file()]
    directories = [path for path in paths if path.is_dir()]
    review = dict(output=str(OUTPUT.relative_to(ROOT)), exit_code=0, checked_passages=PASSAGES,
        checked_runtime_passages=RUNTIME_PASSAGES,
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
