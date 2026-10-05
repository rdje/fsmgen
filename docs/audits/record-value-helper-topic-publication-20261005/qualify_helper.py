"""Bind a fresh helper-model execution to its exact programme and sealed products."""
import hashlib
import json
import subprocess
import sys
from pathlib import Path

BASE = Path('docs/audits/record-value-helper-topic-publication-20261005')
PRIOR = Path('docs/audits/record-value-original-helper-join-20261005')


def identity():
    return {str(p): {'bytes': p.stat().st_size, 'sha256': hashlib.sha256(p.read_bytes()).hexdigest()}
            for p in (PRIOR / 'verify.py', PRIOR / 'proofs.json', PRIOR / 'manifest.json')}


def main():
    before = identity()
    command = [sys.executable, '-B', str(PRIOR / 'verify.py')]
    result = subprocess.run(command, capture_output=True, text=True)
    after = identity()
    assert before == after, 'unchanged exact invoked reader/proof/seal'
    record = {'command': command, 'before': before, 'after': after,
              'status': result.returncode, 'stdout': result.stdout, 'stderr': result.stderr}
    (BASE / 'helper-receipt.json').write_text(json.dumps(record, sort_keys=True, indent=2) + '\n')
    print(result.stdout[-1600:]); print(result.stderr[-400:], file=sys.stderr)
    raise SystemExit(result.returncode)


if __name__ == '__main__':
    main()
