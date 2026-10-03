from pathlib import Path
root = str(Path.cwd())
for name in ('prepared-reservation-snapshot-diagnosis-20261003', 'prepared-reservation-snapshot-checks-20261003'):
    for path in (Path('docs/audits')/name).rglob('*'):
        if path.is_file() and path.suffix in ('.json', '.txt'):
            path.write_text(path.read_text().replace(root, '${REPO_ROOT}'))
print('Encoded only recorded root-coordinate spelling; scalar and reference kinds are unchanged.')
