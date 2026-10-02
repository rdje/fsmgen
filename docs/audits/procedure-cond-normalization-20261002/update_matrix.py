from pathlib import Path
p=Path('docs/book/src/13k-isf-feature-support-matrix.md')
s=p.read_text()
old='Inline procedure `cond` remains unexpanded and refuses, with normalization owned by `.5.4` next.'
new='Inline procedure `cond` remains unexpanded and refuses; explicit source intent `.5.2` must precede safe normalization `.5.4.2`, since a standalone candidate newly admits first sample bodies as activation.'
assert s.count(old)==1
p.write_text(s.replace(old,new))
