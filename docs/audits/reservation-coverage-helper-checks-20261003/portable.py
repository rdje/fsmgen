import json
import subprocess
from pathlib import Path

root = subprocess.check_output(['git', 'rev-parse', '--show-toplevel'], text=True).strip()
base = Path('docs/audits/reservation-coverage-helper-causes-20261003')
sample = base / 'initial-observations-unqualified.json'
rows = json.loads(sample.read_text())
for group in ('api', 'consumers'):
    for row in rows[group]:
        row['error'] = row['error'].replace(root, '${REPO_ROOT}')
coordinates = []
def library_coordinates(value, path=''):
    if isinstance(value, dict):
        for key, child in value.items():
            location = path + '/' + key.replace('~', '~0').replace('/', '~1')
            if key == 'library_source' and isinstance(child, str) and root in child:
                assert child == root + '/isf/common/fifo.isf', location
                value[key] = '${REPO_ROOT}/isf/common/fifo.isf'
                coordinates.append(location)
            else:
                library_coordinates(child, location)
    elif isinstance(value, list):
        for index, child in enumerate(value):
            library_coordinates(child, path + '/' + str(index))
library_coordinates(rows)
assert coordinates
sample.write_text(json.dumps(rows, sort_keys=True, separators=(',', ':')) + '\n')
checks = Path('docs/audits/reservation-coverage-helper-checks-20261003')
for name in ('profile-draft-unqualified.txt', 'value-control-draft-unqualified.txt',
             'portable-draft-unqualified.txt', 'root-fields-unqualified.txt'):
    path = checks / name
    path.write_text(path.read_text().replace(root, '${REPO_ROOT}'))
assert root not in sample.read_text()
(checks / 'coordinate-fields.json').write_text(json.dumps(coordinates, indent=2) + '\n')
print('PASS only native error/rooted FIFO source coordinates portable-encoded; scalar kinds and graph topology untouched. Current-root spelling does not qualify moved-root behavior.')
