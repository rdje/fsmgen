import subprocess
from pathlib import Path

root = subprocess.check_output(['git', 'rev-parse', '--show-toplevel'], text=True).strip()
base = Path('docs/audits/reservation-coverage-cause-repair-checks-20261003')
for name in ('trust-prior-red.txt', 'trust-bypass-red.txt', 'book.txt'):
    path = base / name
    path.write_text(path.read_text().replace(root, '${REPO_ROOT}'))
print('PASS reader/build root coordinates encoded; actual statuses/reasons unchanged.')
