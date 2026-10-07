"""Capture the committed public fixtures once in their two declared roots."""
import datetime
import hashlib
import json
import os
import shutil
import subprocess
from pathlib import Path

BASE = Path('docs/audits/record-value-coordinate-public-capture-20261007')
SOURCE = Path('docs/audits/record-value-coordinate-public-hypotheses-20261007')
FILES = {'fixture.pl': 'fixture.pl', 'dependency.pm': 'lib/CoordinateDependency.pm',
         'load-body.pl': 'load-body.pl', 'require-body.pl': 'require-body.pl'}
METADATA = ['perl', '-MJSON::PP', '-MCarp', '-MTest::More', '-e',
            'print JSON::PP->new->canonical->encode({perl=>$^V."", '
            'json_pp=>$JSON::PP::VERSION, carp=>$Carp::VERSION, '
            'test_more=>$Test::More::VERSION}), "\\n";']


def pin(raw):
    return dict(bytes=len(raw), sha256=hashlib.sha256(raw).hexdigest())


def census(work):
    paths = list(work.rglob('*'))
    if any(p.is_symlink() for p in paths):
        raise ValueError('native fixture symlink refused')
    return {str(p.relative_to(work)): pin(p.read_bytes()) for p in paths if p.is_file()}


def run(command, work, env):
    result = subprocess.run(command, cwd=work, env=env, capture_output=True)
    streams = {field: getattr(result, field).decode('utf-8') for field in ('stdout', 'stderr')}
    return dict(command=command, cwd=str(work), status=result.returncode, **streams,
                stdout_identity=pin(result.stdout), stderr_identity=pin(result.stderr))


def main():
    if (BASE / 'wire.json').exists() or (BASE / 'manifest.json').exists():
        raise ValueError('spent native public capture cannot execute again')
    inputs = json.loads((SOURCE / 'inputs.json').read_bytes())
    sources = {destination: (SOURCE / name).read_bytes() for name, destination in FILES.items()}
    if {p: pin(raw) for p, raw in sources.items()} != inputs['source_pins']:
        raise ValueError('complete committed public source identity required')
    roots = [Path(row['root']) for row in inputs['invocations']]
    if any(root.exists() for root in roots):
        raise ValueError('fresh declared native invocation roots required')
    runs = []
    tools = None
    for invocation in inputs['invocations']:
        work = Path(invocation['root'])
        work.mkdir(parents=True)
        if not work.resolve().is_relative_to(Path.cwd().resolve()) or work.stat().st_dev != Path.cwd().stat().st_dev:
            raise ValueError('native fixture must stay contained on the repository volume')
        for destination, raw in sources.items():
            path = work / destination
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_bytes(raw)
        temporary = work / '.tmp'
        temporary.mkdir()
        env = dict(os.environ, PERL5OPT='', PERL5LIB='',
                   TMPDIR=str(temporary.resolve()), TMP=str(temporary.resolve()), TEMP=str(temporary.resolve()))
        before = census(work)
        if tools is None:
            executable = Path(shutil.which('perl')).resolve()
            tools = dict(executable_identity=pin(executable.read_bytes()),
                         version=run(['perl', '-V'], work, env), modules=run(METADATA, work, env))
        actual = run(invocation['command'], work, env)
        after = census(work)
        runs.append(dict(invocation=invocation, actual=actual, before=before, after=after,
                         source={p: raw.decode('utf-8') for p, raw in sources.items()},
                         environment=dict(PERL5OPT='', PERL5LIB='',
                             temporary_root=str(temporary), runtime_absolute_temporary_values=True)))
    result = dict(captured_utc=datetime.datetime.now(datetime.timezone.utc).isoformat(),
                  capture_programme=pin(Path(__file__).read_bytes()), tools=tools, runs=runs,
                  scope='Dated current public fixture wire only; line/filename recipes and original-coordinate identity remain unqualified.')
    (BASE / 'wire.json').write_text(json.dumps(result, sort_keys=True, indent=2) + '\n')
    print('Captured complete public fixtures in both declared roots; selection remains pending.')


if __name__ == '__main__':
    main()
