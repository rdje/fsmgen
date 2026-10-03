import json
import subprocess
from pathlib import Path

base = Path('docs/audits/reservation-coverage-cause-diagnosis-20261003')
root = subprocess.check_output(['git', 'rev-parse', '--show-toplevel'], text=True).strip()
path = base / 'observations-unqualified.json'
data = json.loads(path.read_text())
for row in data['rows']:
    for field in ('error', 'incoming_error'):
        row[field] = row[field].replace(root, '${REPO_ROOT}')
path.write_text(json.dumps(data, sort_keys=True, separators=(',', ':')) + '\n')
assert root not in path.read_text()
print('PASS native trace root coordinates encoded; native inputs/kinds/topology unchanged.')
