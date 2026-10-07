"""Capture necessary public filename/remapping documentation; no implementation."""
import datetime
import hashlib
import json
import os
import subprocess
from pathlib import Path

BASE = Path('docs/audits/record-value-coordinate-public-hypotheses-20261007')
WORK = Path('.artifacts/public-coordinate-documentation/work')
COMMANDS = {'perlsyn': ['perldoc', '-T', 'perlsyn'],
            'require': ['perldoc', '-T', '-f', 'require'],
            'perlvar': ['perldoc', '-T', 'perlvar']}


def pin(raw):
    return dict(bytes=len(raw), sha256=hashlib.sha256(raw).hexdigest())


def main():
    destination = BASE / 'public-docs.json'
    assert not destination.exists() and not (BASE / 'manifest.json').exists()
    WORK.mkdir(parents=True, exist_ok=True)
    assert WORK.resolve().is_relative_to(Path.cwd()) and WORK.stat().st_dev == Path('.').stat().st_dev
    environment = {**os.environ, 'TMPDIR': str(WORK.resolve()), 'TMP': str(WORK.resolve()),
                   'TEMP': str(WORK.resolve()), 'PERLDOC_PAGER': 'cat', 'PAGER': 'cat'}
    record = dict(captured_at=datetime.datetime.now(datetime.timezone.utc).isoformat(),
                  workspace=str(WORK), commands={},
                  role='Necessary installed public Perl documentation only; no implementation or original/private identity measurement. Canonical project paths and all output/workspaces are repository-relative and same-volume.')
    for name, command in COMMANDS.items():
        run = subprocess.run(command, env=environment, capture_output=True)
        record['commands'][name] = dict(command=command, status=run.returncode,
            stdout=run.stdout.decode(), stderr=run.stderr.decode(),
            stdout_identity=pin(run.stdout), stderr_identity=pin(run.stderr))
        destination.write_text(json.dumps(record, sort_keys=True, indent=2) + '\n')
        assert run.returncode == 0, name
    print('PASS complete necessary public filename/remapping/load documentation captured; public coordinate fixtures remain unexecuted.')


if __name__ == '__main__':
    main()
