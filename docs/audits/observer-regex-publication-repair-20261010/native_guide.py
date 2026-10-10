"""Requalify unchanged whole native guide bytes after copied-source repair."""
from pathlib import Path
from verify import BASE, CORE, canonical, need, pin, read

source=Path('docs/book/book/13k-isf-feature-support-matrix.html')
qualified=read(CORE/'book-native.json')
need(pin(source.read_bytes())==qualified['chapter'],'entire current native guide equals the qualified complete renderer output')
proof=dict(chapter=qualified['chapter'],original_guide=pin((CORE/'book-native.json').read_bytes()),
    scope='Whole native guide byte identity and its already qualified exact prose only; visual QA remains open.')
target=BASE/'native-proof.json'
if target.exists():
    need(read(target)==proof,'whole immutable repaired native guide proof')
else:
    target.write_bytes(canonical(proof))
print('PASS whole current native guide retains every already qualified byte after publication repair; visual QA stays open.')
