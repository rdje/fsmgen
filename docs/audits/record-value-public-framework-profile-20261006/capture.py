"""Capture only necessary installed public POD and version/location accessors."""
import datetime
import hashlib
import json
import os
import subprocess
from pathlib import Path

BASE = Path('docs/audits/record-value-public-framework-profile-20261006')
WORK = Path('.artifacts/public-framework-profile/work')
COMMANDS = {
    'caller': ['perldoc', '-T', '-f', 'caller'],
    'eval': ['perldoc', '-T', '-f', 'eval'],
    'Carp': ['perldoc', '-T', 'Carp'],
    'Test::More': ['perldoc', '-T', 'Test::More'],
    'Test::Builder': ['perldoc', '-T', 'Test::Builder'],
    'versions': ['perl', '-MJSON::PP', '-MCarp', '-MTest::More', '-MTest::Builder', '-e',
        'print JSON::PP->new->canonical->encode({perl=>"$^V",Carp=>"".Carp->VERSION, '
        '"Test::More"=>"".Test::More->VERSION,"Test::Builder"=>"".Test::Builder->VERSION}),chr(10);'],
    'Carp_documentation_path': ['perldoc', '-l', 'Carp'],
    'Test::More_documentation_path': ['perldoc', '-l', 'Test::More'],
    'Test::Builder_documentation_path': ['perldoc', '-l', 'Test::Builder'],
}


def identity(raw):
    return dict(bytes=len(raw), sha256=hashlib.sha256(raw).hexdigest())


def main():
    target = BASE / 'public-profile.json'
    assert not target.exists() and not (BASE / 'manifest.json').exists()
    WORK.mkdir(parents=True, exist_ok=True)
    assert WORK.resolve().is_relative_to(Path.cwd()) and WORK.stat().st_dev == Path('.').stat().st_dev
    env = {**os.environ, 'TMPDIR': str(WORK.resolve()), 'TMP': str(WORK.resolve()),
           'TEMP': str(WORK.resolve()), 'PERLDOC_PAGER': 'cat', 'PAGER': 'cat'}
    record = dict(captured_at=datetime.datetime.now(datetime.timezone.utc).isoformat(),
        environment=dict(temporary_workspace=str(WORK), pager='cat',
                         role='Absolute temporary paths derive at runtime from the repository root; installed tools/docs are necessary read-only dependencies.'),
        commands={},
        scope='Dated installed public documentation and runtime accessor profile only. Original framework/provider identity, private implementation and universal/native trace meanings remain unmeasured. No foreign implementation or submodule source is read; all project outputs and scratch remain repository-local.')
    for name, command in COMMANDS.items():
        result = subprocess.run(command, env=env, capture_output=True, text=True)
        record['commands'][name] = dict(command=command, status=result.returncode,
            stdout=result.stdout, stderr=result.stderr, identity=identity(result.stdout.encode()),
            stderr_identity=identity(result.stderr.encode()))
        target.write_text(json.dumps(record, sort_keys=True, indent=2) + '\n')
        assert result.returncode == 0, (name, result.returncode, result.stderr)
    print('PASS necessary installed public caller/eval/Carp/subtest POD and runtime accessors captured; original historical identity remains open.')


if __name__ == '__main__':
    main()
