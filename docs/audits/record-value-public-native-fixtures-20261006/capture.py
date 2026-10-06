"""Run only own fixtures through published Perl/Test/Carp interfaces."""
import hashlib
import json
import os
import subprocess
from pathlib import Path

BASE = Path('docs/audits/record-value-public-native-fixtures-20261006')
WORK = Path('.artifacts/public-native-fixtures/work')
COMMAND = ['perl', str(BASE / 'fixtures.pl')]


def identity(raw):
    return dict(bytes=len(raw), sha256=hashlib.sha256(raw).hexdigest())


def run(command=COMMAND):
    WORK.mkdir(parents=True, exist_ok=True)
    assert WORK.resolve().is_relative_to(Path.cwd())
    assert WORK.stat().st_dev == Path('.').stat().st_dev
    env = {**os.environ, 'TMPDIR': str(WORK.resolve()), 'TMP': str(WORK.resolve()),
           'TEMP': str(WORK.resolve()), 'PERLDOC_PAGER': 'cat', 'PAGER': 'cat'}
    p = subprocess.run(command, env=env, capture_output=True)
    return dict(command=command, status=p.returncode, stdout=p.stdout.decode(),
        stderr=p.stderr.decode(), stdout_identity=identity(p.stdout),
        stderr_identity=identity(p.stderr), pre_native=identity((BASE / 'pre-native.json').read_bytes()),
        workspace=str(WORK), role='Own current installed public fixtures only; historical/original/private identities remain unmeasured.')


if __name__ == '__main__':
    assert not (BASE / 'native.json').exists()
    record = run()
    (BASE / 'native.json').write_text(json.dumps(record, sort_keys=True, indent=2) + '\n')
    print('Captured complete public fixture streams; semantic qualification remains separate.')
    raise SystemExit(record['status'])
