"""Parse every owned Python programme without creating bytecode artifacts."""
import ast
from pathlib import Path

roots = (Path('docs/audits/record-value-class-frame-publication-admission-20261006'),
         Path('docs/audits/class-frame-publication-admission-checks-20261006'))
for root in roots:
    for source in sorted(root.glob('*.py')):
        assert source.is_file() and not source.is_symlink() and source.stat().st_dev == Path.cwd().stat().st_dev
        ast.parse(source.read_bytes(), filename=str(source))
        print('Parsed: ' + str(source))
print('PASS every owned programme parses; no bytecode artifact is produced.')
