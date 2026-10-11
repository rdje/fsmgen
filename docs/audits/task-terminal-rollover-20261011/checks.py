"""Save complete actual external checks before judging status or source currency."""
import fcntl
import json
import subprocess
import sys
from pathlib import Path
from common import BASE, SCRATCH, canonical, local, need, pin


if __name__ == '__main__':
    need(len(sys.argv) >= 3, 'named explicit check')
    name, command = sys.argv[1], sys.argv[2:]
    destination = BASE / 'checks.json'
    lock_path = local(SCRATCH / 'checks.lock', exists=False)
    lock_path.parent.mkdir(parents=True, exist_ok=True)
    inputs = {str(path): path.read_bytes() for path in sorted(BASE.glob('*.py'))}
    for arg in command:
        if Path(arg).is_file():
            inputs[arg] = local(arg).read_bytes()
    for arg in ('scripts/check_record_value_publication.py', 'scripts/record_value_observer_fact.py',
                'scripts/record_value_observer_namespace_fact.py', 'docs/book/src/13k-isf-feature-support-matrix.md',
                'docs/knowledge/record-value-original-observer-helper-paths.md'):
        inputs[arg] = local(arg).read_bytes()
    result = subprocess.run(command, capture_output=True)
    after = {name: pin(local(name).read_bytes()) for name in inputs}
    before = {name: pin(raw) for name, raw in inputs.items()}
    with lock_path.open('a+b') as lock:
        fcntl.flock(lock, fcntl.LOCK_EX)
        record = json.loads(destination.read_bytes()) if destination.exists() else {}
        need(name not in record, 'retain first actual command result')
        record[name] = dict(command=command, status=result.returncode, stdout=result.stdout.decode(),
            stderr=result.stderr.decode(), programmes={name: dict(identity=pin(raw), body=raw.decode())
                for name, raw in inputs.items()}, inputs_after=after, epoch_conserved=before == after)
        destination.write_bytes(canonical(record))
    print(name, result.returncode, result.stdout.decode()[-1800:], result.stderr.decode()[-1800:], flush=True)
    need(before == after, 'complete declared command input epoch conserved')
    need(type(result.returncode) is int and result.returncode == 0, 'actual external check success: ' + name)
