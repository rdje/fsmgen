"""Retain one whole public native epoch and all exact invocation sources."""
import hashlib
import json
import subprocess
import sys
from pathlib import Path

BASE = Path('docs/audits/observer-display-contract-20261010')


def pin(raw):
    return {'bytes': len(raw), 'sha256': hashlib.sha256(raw).hexdigest()}


def main():
    phase = 'relative'
    assert len(sys.argv) == 1
    catalogue = BASE / 'qualify-catalogue.json'
    destination = BASE / (phase + '-native.json')
    assert not destination.exists(), 'retain first native epoch'
    inputs = [BASE / 'fixtures.pl', catalogue, Path(__file__).resolve().relative_to(Path.cwd().resolve())]
    before = {str(p): pin(p.read_bytes()) for p in inputs}
    command = ['perl', '-Iperl', str(BASE / 'fixtures.pl'), str(catalogue)]
    r = subprocess.run(command, capture_output=True)
    after = {str(p): pin(p.read_bytes()) for p in inputs}
    assert before == after, 'whole public invocation inputs conserve'
    record = {'phase': phase, 'command': command, 'status': r.returncode,
              'stdout': r.stdout.decode('utf-8'), 'stderr': r.stderr.decode('utf-8'),
              'stdout_identity': pin(r.stdout), 'stderr_identity': pin(r.stderr),
              'inputs': before, 'role': 'Own current public native observations only; original execution and provider identity are not measured.'}
    destination.write_text(json.dumps(record, sort_keys=True, indent=2) + '\n')
    print(phase, r.returncode, pin(r.stdout), pin(r.stderr))
    raise SystemExit(r.returncode)


if __name__ == '__main__':
    main()
