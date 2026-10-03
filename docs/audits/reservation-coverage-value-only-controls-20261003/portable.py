import json
import subprocess
from pathlib import Path

base = Path('docs/audits/reservation-coverage-value-only-controls-20261003')
root = subprocess.check_output(['git', 'rev-parse', '--show-toplevel'], text=True).strip()
ledger = {}

def encode(value, path='', key=None):
    if isinstance(value, dict):
        return {name: encode(child, path + '/' + name, name) for name, child in value.items()}
    if isinstance(value, list):
        return [encode(child, path + '/' + str(index)) for index, child in enumerate(value)]
    if isinstance(value, str) and root in value:
        assert key == 'library_source', path
        assert value == root + '/isf/common/fifo.isf', path
        coordinates.append(path)
        return '${REPO_ROOT}/isf/common/fifo.isf'
    return value

for mode in ('ordinary', 'success', 'refusal'):
    coordinates = []
    path = base / (mode + '.json')
    data = encode(json.loads(path.read_text()))
    path.write_text(json.dumps(data, sort_keys=True, separators=(',', ':')) + '\n')
    assert root not in path.read_text()
    ledger[mode] = coordinates
(base / 'coordinates.json').write_text(json.dumps(ledger, sort_keys=True, indent=2) + '\n')
print('PASS only observed FIFO library-source coordinates encoded; all scalar kinds retained.')
