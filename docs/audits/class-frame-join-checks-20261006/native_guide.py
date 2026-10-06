"""Qualify actual rendered scope; legacy mode reproduces first glyph mismatch."""
import argparse
from pathlib import Path

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--legacy', action='store_true')
args = parser.parse_args()
base = Path('docs/audits/record-value-class-frame-join-20261006')
checks = Path('docs/audits/class-frame-join-checks-20261006')
source = checks / 'first-book.py.txt' if args.legacy else base / 'book.py'
ns = {'__name__': 'native_class_frame_guide'}
exec(compile(source.read_bytes(), str(source), 'exec'), ns)
raw = Path('.artifacts/class-frame-join-book/13k-isf-feature-support-matrix.html').read_bytes()
ns['proof'](raw.decode())
output = base / 'book-input.html'
if output.exists():
    assert output.read_bytes() == raw
else:
    assert not (base / 'manifest.json').exists()
    output.write_bytes(raw)
print('PASS native class/frame guide and genuine scope controls; complete rendered input retained.')
