"""Compile complete own fixtures without running their observation cases."""
import hashlib
import json
import os
import subprocess
from pathlib import Path

BASE = Path('docs/audits/record-value-coordinate-public-hypotheses-20261007')
CHECKS = Path('docs/audits/coordinate-public-hypotheses-checks-20261007')
WORK = Path('.artifacts/public-coordinate-hypotheses/syntax')
FILES = {'fixture.pl': 'fixture.pl', 'dependency.pm': 'lib/CoordinateDependency.pm',
         'load-body.pl': 'load-body.pl', 'require-body.pl': 'require-body.pl'}


def pin(raw):
    return dict(bytes=len(raw), sha256=hashlib.sha256(raw).hexdigest())


def main():
    target = CHECKS / 'syntax-actual.json'
    assert not target.exists() and not WORK.exists()
    WORK.mkdir(parents=True)
    assert WORK.resolve().is_relative_to(Path.cwd()) and WORK.stat().st_dev == Path('.').stat().st_dev
    before = {}
    for name, destination in FILES.items():
        raw = (BASE / name).read_bytes(); before[destination] = pin(raw)
        path = WORK / destination; path.parent.mkdir(parents=True, exist_ok=True); path.write_bytes(raw)
    env = {**os.environ, 'TMPDIR': str(WORK.resolve()), 'TMP': str(WORK.resolve()),
           'TEMP': str(WORK.resolve()), 'PERL5OPT': '', 'PERL5LIB': ''}
    command = ['perl', '-c', 'fixture.pl']
    run = subprocess.run(command, cwd=WORK, env=env, capture_output=True)
    after = {str(p.relative_to(WORK)): pin(p.read_bytes()) for p in WORK.rglob('*') if p.is_file()}
    record = dict(command=command, cwd=str(WORK), status=run.returncode,
        stdout=run.stdout.decode(), stderr=run.stderr.decode(), before=before, after=after,
        role='Syntax compilation only: -c does not execute own observation cases. Four complete same-volume source copies conserve; no coordinate fixture observations are captured.')
    target.write_text(json.dumps(record, sort_keys=True, indent=2) + '\n')
    assert run.returncode == 0 and run.stdout == b'' and run.stderr == b'fixture.pl syntax OK\n' and before == after
    print('PASS complete own public fixture syntax with source conservation and no coordinate observation capture.')


if __name__ == '__main__':
    main()
