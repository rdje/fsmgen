"""Verify the fresh qualification without promoting any historical failure."""
from pathlib import Path
import gzip
import json
import sys

if not __debug__:
    raise SystemExit('Verification assertions must be enabled.')

ROOT = Path(__file__).resolve().parents[3]
AUDIT = Path('docs/audits/task-acceptance-index-prospective-20261018')
ORIGINAL = Path('docs/audits/task-acceptance-index-observer-20261017')
sys.path.insert(0, str(ROOT / ORIGINAL))
from verify import verify, falsify, unblob, qualified_sources
from verify_failure import validate_failure


def verify_intake(record):
    verify(record)
    required = {str(AUDIT / name) for name in
                ('ProspectiveIndexObserver.pm', 'observe.pl', 'run.py', 'verify.py', 'verify_failure.py', 'preflight.t', 'preflight.py', 'contract.json', 'corrected-contract.json')}
    required.add(str(ORIGINAL / 'verify_failure.py'))
    assert required <= set(record['sources_after'])
    assert record['rows']
    for row in record['rows']:
        assert str(AUDIT / 'observe.pl') in ' '.join(row['command'])
    return True


if __name__ == '__main__':
    assert sys.argv[1:] in (['controls'], ['regression'])
    action = sys.argv[1]
    record = json.loads(gzip.decompress((ROOT / AUDIT / ('corrected-' + action + '.json.gz')).read_bytes()))
    verify_intake(record)
    if action == 'controls':
        falsify(record)
    # This is an immutable historical observation; its causal status never
    # depends on the outcome of the current qualification.
    failed = json.loads(gzip.decompress((ROOT / ORIGINAL / 'controls.json.gz').read_bytes()))
    assert validate_failure(failed)
    print('Prospective index observer qualifies; historical native failure remains failed and P1-open:', action)
