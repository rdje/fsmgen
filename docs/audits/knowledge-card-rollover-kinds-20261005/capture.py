"""Pin the complete original audit boundary before superseding its current reader routes."""
import hashlib
import json
import subprocess
from pathlib import Path

BASE = Path('docs/audits/knowledge-card-rollover-kinds-20261005')
REVISION = '193fb44f80c9ea78f55ecc5086c5d1e40405f67e'
ROOTS = ['docs/audits/knowledge-card-rollover-selection-20261005',
         'docs/audits/knowledge-card-rollover-selection-checks-20261005',
         'docs/audits/knowledge-card-rollover-source-20261005',
         'docs/audits/knowledge-card-rollover-20261005',
         'docs/audits/knowledge-card-rollover-checks-20261005']
OLD_COMMAND = 'python3 -B docs/audits/knowledge-card-rollover-20261005/verify.py --current'
NEW_COMMAND = 'python3 -B docs/audits/knowledge-card-rollover-kinds-20261005/verify.py --current'


def main():
    paths = subprocess.check_output(['git', 'ls-tree', '-r', '--name-only', REVISION, '--', *ROOTS], text=True).splitlines()
    pins = {}
    for path in paths:
        raw = subprocess.check_output(['git', 'show', REVISION + ':' + path])
        assert Path(path).read_bytes() == raw, 'complete original programme/proof/source/receipt bytes unchanged'
        pins[path] = {'bytes': len(raw), 'sha256': hashlib.sha256(raw).hexdigest()}
    (BASE / 'original-pins.json').write_text(json.dumps({'revision': REVISION, 'roots': ROOTS, 'pins': pins}, indent=2, sort_keys=True) + '\n')
    source = json.loads(Path('docs/audits/knowledge-card-rollover-selection-20261005/source.json').read_text())
    transform = {}
    for row in source['sources'].values():
        path = row['path']; before = Path(path).read_text()
        assert subprocess.check_output(['git', 'show', REVISION + ':' + path]) == before.encode()
        assert before.count(OLD_COMMAND) == 1, 'one owned current reader route'
        transform[path] = {'before': before, 'after': before.replace(OLD_COMMAND, NEW_COMMAND)}
    (BASE / 'current-transform.json').write_text(json.dumps({'old': OLD_COMMAND, 'new': NEW_COMMAND, 'cards': transform}, indent=2, sort_keys=True) + '\n')
    command = ['git', 'log', '-1', '--format=%H %s', '-S', 'whole card authority unchanged', '--', 'docs/audits/knowledge-card-rollover-20261005/verify.py']
    result = subprocess.run(command, capture_output=True, text=True)
    assert result.returncode == 0 and result.stdout.strip()
    (BASE / 'root-cause.json').write_text(json.dumps({'command': command, 'status': result.returncode, 'stdout': result.stdout, 'stderr': result.stderr}, indent=2) + '\n')


if __name__ == '__main__':
    main()
