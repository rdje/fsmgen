"""Exercise the unchanged sealed source-plane reader against valid fact progress."""
import hashlib
import json
import subprocess
from pathlib import Path

BASE = Path('docs/audits/record-value-helper-reader-role-adapter-20261005')
REVISION = 'ebd3df0c21d2e8383e179cf88a81f0c780568e14'
TOPIC = 'docs/knowledge/record-value-original-observer-helper-paths.md'
PLANE = 'docs/audits/book-source-plane-20261005/verify.py'
HELPER = 'docs/audits/record-value-current-helper-reader-20261005/verify.py'
SOURCE = Path('docs/audits/record-value-own-subtest-boundaries-20261005')


def pin(raw):
    return {'bytes': len(raw), 'sha256': hashlib.sha256(raw).hexdigest()}


def main():
    target = BASE / 'coupling.json'
    assert not target.exists()
    before = Path(TOPIC).read_bytes()
    assert before == subprocess.check_output(['git', 'show', REVISION + ':' + TOPIC])
    proposal = (SOURCE / 'pending-fact.txt').read_text()
    assert (SOURCE / 'proofs.json').exists()
    # Source-qualified factual progress changes no question or existing meaning.
    addition = '\n## Qualified own source boundaries\n\n' + proposal.split('\n\n', 1)[1]
    candidate = before + addition.encode()
    pins = {path: pin(Path(path).read_bytes()) for path in (PLANE, HELPER)}
    assert all(subprocess.check_output(['git', 'show', REVISION + ':' + path]) == Path(path).read_bytes() for path in pins)
    command = ['python3', '-B', PLANE]
    try:
        Path(TOPIC).write_bytes(candidate)
        result = subprocess.run(command, capture_output=True, text=True)
    finally:
        Path(TOPIC).write_bytes(before)
    record = {'revision': REVISION, 'topic': TOPIC, 'before': before.decode(), 'candidate': candidate.decode(),
              'addition': addition, 'programme_pins': pins, 'command': command, 'status': result.returncode,
              'stdout': result.stdout, 'stderr': result.stderr, 'restored': Path(TOPIC).read_bytes() == before,
              'source_proposal': proposal}
    target.write_text(json.dumps(record, sort_keys=True, indent=2) + '\n')
    assert result.returncode == 1 and 'whole current helper/core source, roles, questions and reader routes' in result.stderr
    assert record['restored'] and all(pin(Path(path).read_bytes()) == expected for path, expected in pins.items())
    print('CONFIRMED sealed source-plane default couples historical replay to the old whole live helper card; source-qualified progress refuses. Exact live bytes restored; all prior programmes unchanged.')


if __name__ == '__main__':
    main()
