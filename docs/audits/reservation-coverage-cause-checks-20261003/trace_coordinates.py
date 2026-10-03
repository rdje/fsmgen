import subprocess
from pathlib import Path

root = subprocess.check_output(['git', 'rev-parse', '--show-toplevel'], text=True).strip()
base = Path('docs/audits/reservation-coverage-cause-checks-20261003')
for name in ('trust-current-red.txt', 'book.txt'):
    path = base / name
    if path.exists():
        path.write_text(path.read_text().replace(root, '${REPO_ROOT}'))
print('PASS reader/build trace root coordinates encoded; statuses and reasons untouched.')
