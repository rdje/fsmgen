"""Encode observed repository-root coordinates without persisted machine paths."""
from pathlib import Path
root = str(Path.cwd())
for directory in ('prepared-reservation-helper-causes-20261003',
                  'prepared-reservation-helper-checks-20261003'):
    base = Path('docs/audits') / directory
    for path in base.rglob('*'):
        if path.is_file() and path.suffix in ('.json', '.txt'):
            path.write_text(path.read_text().replace(root, '${REPO_ROOT}'))
print('Encoded observed root coordinates as ${REPO_ROOT}; paths remain repository-derived.')
