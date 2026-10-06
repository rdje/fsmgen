"""Qualify the real native retention guide and retain its complete input."""
from pathlib import Path

base = Path('docs/audits/record-value-class-frame-retention-20261006')
source = base / 'book.py'
ns = {'__name__': 'native_publication_admission_guide'}
exec(compile(source.read_bytes(), str(source), 'exec'), ns)
raw = Path('.artifacts/class-frame-retention-book/13k-isf-feature-support-matrix.html').read_bytes()
ns['proof'](raw.decode())
output = base / 'book-input.html'
if output.exists():
    assert output.read_bytes() == raw
else:
    assert not (base / 'manifest.json').exists()
    output.write_bytes(raw)
print('PASS native semantic-retention guide and genuine scope controls; complete rendered input retained.')
