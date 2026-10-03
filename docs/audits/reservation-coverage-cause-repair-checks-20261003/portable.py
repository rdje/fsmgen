import json
import subprocess
from pathlib import Path

base = Path('docs/audits/reservation-coverage-cause-repair-20261003')
root = subprocess.check_output(['git', 'rev-parse', '--show-toplevel'], text=True).strip()
def encode(value, key=None):
    if isinstance(value, dict):
        return {name: encode(child, name) for name, child in value.items()}
    if isinstance(value, list):
        return [encode(child) for child in value]
    if isinstance(value, str) and root in value:
        if key in ('error', 'incoming_error'):
            return value.replace(root, '${REPO_ROOT}')
        assert key == 'library_source' and value == root + '/isf/common/fifo.isf', key
        return '${REPO_ROOT}/isf/common/fifo.isf'
    return value
for name in ('current.json', 'prior.json', 'ordinary.json', 'bypass.json'):
    path = base / name
    value = encode(json.loads(path.read_text()))
    path.write_text(json.dumps(value, sort_keys=True, separators=(',', ':')) + '\n')
    assert root not in path.read_text()
print('PASS only native error/FIFO root coordinates encoded; primitive kinds and topology untouched.')
