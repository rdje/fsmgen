"""Execute each precommitted fresh control once, retaining each complete result immediately."""
import datetime
import hashlib
import io
import json
import os
import shutil
import subprocess
import tarfile
from pathlib import Path

BASE = Path('docs/audits/record-value-coordinate-native-control-capture-20261008')
PLANS = Path('docs/audits/record-value-coordinate-native-control-plans-20261008')
CHECKS = Path('docs/audits/coordinate-native-control-plan-checks-20261008')
REVISION = 'ef5ab4b222a3d0c9a86d2d8431c9a6b62190a452'
SCOPE = 'Dated native control source/wire custody only; native semantic refusals and original/private/formatter/toolchain identities remain unqualified.'
METADATA = ['perl', '-MJSON::PP', '-MCarp', '-MTest::More', '-e',
            'print JSON::PP->new->canonical->encode({perl=>$^V."", '
            'json_pp=>$JSON::PP::VERSION, carp=>$Carp::VERSION, '
            'test_more=>$Test::More::VERSION}), "\\n";']


def need(value, cause):
    if not value:
        raise ValueError(cause)


def pin(raw):
    return dict(bytes=len(raw), sha256=hashlib.sha256(raw).hexdigest())


def save(name, value):
    path = BASE / name; temporary = BASE / (name + '.part')
    need(not path.exists() and not temporary.exists(), 'one new immutable native checkpoint required')
    raw = (json.dumps(value, sort_keys=True, indent=2) + '\n').encode()
    with temporary.open('xb') as file:
        file.write(raw); file.flush(); os.fsync(file.fileno())
    temporary.rename(path)


def binding():
    archive = subprocess.check_output(['git', 'archive', REVISION, str(PLANS), str(CHECKS)])
    with tarfile.open(fileobj=io.BytesIO(archive)) as source:
        fixed = {m.name: source.extractfile(m).read() for m in source.getmembers() if m.isfile()}
    current = {}
    for root in (PLANS, CHECKS):
        need(root.is_dir() and not root.is_symlink() and root.stat().st_dev == Path.cwd().stat().st_dev,
             'whole regular same-volume committed plan roots')
        for p in root.iterdir():
            need(p.is_file() and not p.is_symlink() and p.stat().st_dev == Path.cwd().stat().st_dev,
                 'whole regular same-volume committed plan members')
            current[str(p)] = p.read_bytes()
    need(current == fixed, 'whole fixed committed plan/source/programme/actual bytes')
    task = subprocess.check_output(['git', 'show', REVISION + ':docs/tasks/SEMANTIC-INTROSPECTION-MCP-FRONTIER.md'])
    owner = fixed[str(PLANS / 'scope.txt')].decode().splitlines()[0].removeprefix('Owner: ')
    text = task.decode(); a = text.index('- ID: `' + owner + '`'); b = text.index('\n- ID:', a + 1)
    need('\n  Status: `done`\n' in text[a:b], 'whole completed committed source-plan owner')
    return dict(revision=REVISION, members={p: pin(raw) for p, raw in fixed.items()},
                owner=text[a:b], task_identity=pin(task))


def census(work):
    members = {}
    for p in work.rglob('*'):
        need(not p.is_symlink() and p.stat().st_dev == Path.cwd().stat().st_dev,
             'whole native workspace remains regular and same-volume')
        need(p.is_file() or p.is_dir(), 'special native workspace member refused')
        if p.is_file():
            members[str(p.relative_to(work))] = pin(p.read_bytes())
    return members


def run(command, work, environment):
    result = subprocess.run(command, cwd=work, env=environment, capture_output=True)
    return dict(command=command, cwd=str(work), status=result.returncode,
                stdout=result.stdout.decode('utf-8'), stderr=result.stderr.decode('utf-8'),
                stdout_identity=pin(result.stdout), stderr_identity=pin(result.stderr))


def main():
    need(not any((BASE / name).exists() for name in ('started.json', 'wire.json', 'manifest.json')),
         'spent native control capture cannot execute again')
    admitted = binding(); plans = json.loads((PLANS / 'plans.json').read_bytes())['plans']
    for plan in plans:
        work = Path(plan['invocation']['root'])
        need(not work.exists(), 'fresh declared native control roots required')
        ancestor = Path.cwd()
        for part in work.parts:
            ancestor = ancestor / part
            need(not ancestor.is_symlink() and not (ancestor / '.git').exists(), 'native root symlink/repository boundary refused')
    save('started.json', dict(captured_utc=datetime.datetime.now(datetime.timezone.utc).isoformat(),
                             binding=admitted, capture_programme=pin(Path(__file__).read_bytes()),
                             planned_invocations=[p['invocation'] for p in plans], scope=SCOPE))
    runs = []; tools = None
    for plan in plans:
        invocation = plan['invocation']; work = Path(invocation['root']); work.mkdir(parents=True)
        need(work.resolve().is_relative_to(Path.cwd().resolve()) and work.stat().st_dev == Path.cwd().stat().st_dev,
             'native control root stays contained and same-volume')
        for destination, source in plan['source'].items():
            path = work / destination; path.parent.mkdir(parents=True, exist_ok=True); path.write_bytes(source.encode())
        temporary = work / '.tmp'; temporary.mkdir()
        env = dict(os.environ, PERL5OPT='', PERL5LIB='', TMPDIR=str(temporary.resolve()),
                   TMP=str(temporary.resolve()), TEMP=str(temporary.resolve()))
        before = census(work)
        if tools is None:
            executable = Path(shutil.which('perl')).resolve()
            tools = dict(executable_before=pin(executable.read_bytes()), version=run(['perl', '-V'], work, env),
                         modules=run(METADATA, work, env), executable_after=pin(executable.read_bytes()))
            save('tools.json', tools)
            need(tools['version']['status'] == 0 and tools['modules']['status'] == 0,
                 'retained public native metadata failure blocks fixture execution')
        actual = run(invocation['command'], work, env)
        after = census(work)
        row = dict(name=plan['name'], invocation=invocation, actual=actual, before=before, after=after,
                   source=plan['source'], environment=dict(PERL5OPT='', PERL5LIB='', temporary_root=str(temporary),
                                                         runtime_absolute_temporary_values=True))
        save('run-' + plan['name'] + '.json', row); runs.append(row)
        need(actual['status'] == 0, 'retained native fixture failure blocks subsequent captures')
        need(before == plan['source_pins'] and after == before, 'retained native source drift blocks subsequent captures')
    need(binding() == admitted, 'every complete committed plan member conserves after native execution')
    save('wire.json', dict(admission=json.loads((BASE / 'started.json').read_bytes()), tools=tools, runs=runs, scope=SCOPE))
    print('Captured every committed native control once with per-run complete checkpoints; semantic refusal selection remains pending.')


if __name__ == '__main__':
    main()
