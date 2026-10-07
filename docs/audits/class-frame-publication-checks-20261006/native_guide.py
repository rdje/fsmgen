"""Qualify and retain the actual complete current/retained native guide."""
from pathlib import Path

base = Path('docs/audits/record-value-class-frame-publication-20261006')
p = base / 'book.py'; ns = {'__name__':'native_current_guide','__file__':str(p)}
exec(compile(p.read_bytes(),str(p),'exec'),ns)
raw = Path('.artifacts/class-frame-publication-book/13k-isf-feature-support-matrix.html').read_bytes()
ns['proof'](raw.decode())
target = base / 'native-input.html'
if target.exists(): assert target.read_bytes() == raw
else:
    assert not (base / 'manifest.json').exists(); target.write_bytes(raw)
print('PASS native complete class/frame current retained guide and genuine scope controls; whole rendered input retained.')
