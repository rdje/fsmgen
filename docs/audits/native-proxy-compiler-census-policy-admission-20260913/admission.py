"""One-use compiler census admission. Qualification imports never emit a permit."""
import argparse
import hashlib
import importlib.util
import json
import os
from pathlib import Path
import stat
import subprocess

if not __debug__:
    raise RuntimeError('admission checks require Python assertions enabled')

BASE = Path(__file__).resolve().parent
ROOT = BASE.parents[2]
PLAN = json.loads((BASE / 'plan.json').read_bytes())
OUTPUT = ROOT / PLAN['output']
TASK = 'docs/tasks/HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.md'
EPOCH = BASE.parent / 'native-proxy-compiler-profile-admission-20260913'


def digest(raw):
    return hashlib.sha256(raw).hexdigest()


def save(path, value):
    raw = (json.dumps(value, sort_keys=True, indent=2) + '\n').encode()
    fd = os.open(path, os.O_WRONLY | os.O_CREAT | os.O_EXCL | os.O_NOFOLLOW, 0o600)
    with os.fdopen(fd, 'wb') as stream:
        stream.write(raw)
        stream.flush()
        os.fsync(stream.fileno())


def git(*args):
    # Issuer and isolated runner must see the same repository policy. Do not
    # inherit personal ignore/configuration or GIT_* environment overrides.
    return subprocess.check_output(['/usr/bin/git', '-c', 'core.excludesFile=.gitignore', *args],
        cwd=ROOT, env=dict(PATH='/usr/bin:/bin', LC_ALL='C', LANG='C', TMPDIR=str(ROOT/'.artifacts/tmp')))


def owner_status(raw, owner):
    marker = '- ID: `' + owner + '`\n'
    text = raw.decode()
    assert text.count(marker) == 1
    return text.split(marker, 1)[1].splitlines()[0].strip()


def validate_permit(value, expected):
    # Exact equality rejects extra permissions as well as missing fields.
    if value != expected:
        raise ValueError('permit does not match the fixed committed admission')


def local_file(path, limit):
    assert path.is_relative_to(ROOT)
    for parent in reversed(path.parents):
        if parent == ROOT or parent.is_relative_to(ROOT):
            s = parent.lstat()
            assert stat.S_ISDIR(s.st_mode) and s.st_dev == ROOT.stat().st_dev and s.st_uid == os.getuid()
    before = path.lstat()
    assert stat.S_ISREG(before.st_mode) and before.st_nlink == 1
    assert before.st_dev == ROOT.stat().st_dev and before.st_uid == os.getuid() and before.st_size <= limit
    identity = lambda s: (s.st_dev, s.st_ino, s.st_mode, s.st_nlink, s.st_uid, s.st_size, s.st_mtime_ns, s.st_ctime_ns)
    fd = os.open(path, os.O_RDONLY | os.O_NOFOLLOW | os.O_NONBLOCK)
    with os.fdopen(fd, 'rb') as stream:
        assert identity(os.fstat(stream.fileno())) == identity(before)
        raw = stream.read(limit + 1)
        assert identity(os.fstat(stream.fileno())) == identity(before) == identity(path.lstat())
    assert len(raw) == before.st_size and len(raw) <= limit
    return raw


def interpreter_pin(name):
    path = Path(name)
    assert path.is_absolute() and not path.is_relative_to(ROOT) and path.resolve(strict=True) == path
    before = path.lstat()
    assert stat.S_ISREG(before.st_mode) and before.st_uid in {0, os.getuid()} and before.st_size <= 1048576
    identity = lambda s: dict(device=s.st_dev, inode=s.st_ino, mode=stat.S_IMODE(s.st_mode),
        uid=s.st_uid, size_bytes=s.st_size, mtime_ns=s.st_mtime_ns, ctime_ns=s.st_ctime_ns)
    fd = os.open(path, os.O_RDONLY | os.O_NOFOLLOW | os.O_NONBLOCK)
    with os.fdopen(fd, 'rb') as stream:
        assert identity(os.fstat(stream.fileno())) == identity(before)
        raw = stream.read(1048577)
        assert identity(os.fstat(stream.fileno())) == identity(before) == identity(path.lstat())
    assert len(raw) == before.st_size
    return dict(path=name, identity=identity(before), sha256=digest(raw), access='read_only')


def sources():
    pins = json.loads(local_file(BASE / 'implementation-pins.json', 65536))
    revision = git('log', '-1', '--format=%H', '--', str((BASE / 'plan.json').relative_to(ROOT))).decode().strip()
    assert owner_status(git('show', revision + ':' + TASK), PLAN['owner']) == 'Status: `done`'
    assert PLAN['owner'] in git('show', '-s', '--format=%B', revision).decode()
    for pin in PLAN['inputs'] + pins:
        raw = local_file(ROOT / pin['path'], 1048576)
        assert len(raw) == pin['size_bytes'] and digest(raw) == pin['sha256']
        assert git('show', revision + ':' + pin['path']) == raw
    pin_path = str((BASE / 'implementation-pins.json').relative_to(ROOT))
    assert git('show', revision + ':' + pin_path) == local_file(BASE / 'implementation-pins.json', 65536)
    assert owner_status(local_file(ROOT / TASK, 2097152), PLAN['execution_owner']) == 'Status: `active`'
    allowed = {'MEMORY.md', 'docs/TASK_TREE.md', TASK}
    dirty = git('status', '--porcelain=v1', '-z').decode().split('\0')
    assert all(row[3:] in allowed or row[3:].startswith(PLAN['execution_evidence'] + '/') for row in dirty if row)
    return revision, digest(local_file(BASE / 'implementation-pins.json', 65536))


def epoch_now():
    spec = importlib.util.spec_from_file_location('compiler_census_epoch', EPOCH / 'epoch.py')
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    saved = json.loads((EPOCH / 'epoch-first.json').read_bytes())
    # The retained older SDK is historical evidence, not a new compiler input.
    files = [r for r in saved['files'] if '/MacOSX26.5.sdk/' not in r['path']]
    entries = [r for r in saved['sdk_entries'] if not r['path'].endswith('/MacOSX26.5.sdk')]
    observed = dict(files=[module.external_pin(r['path']) for r in files],
                    sdk_entries=[module.sdk_entry(r['path']) for r in entries],
                    interpreters=[interpreter_pin(r['path']) for r in PLAN['interpreters']],
                    git_launcher=interpreter_pin(PLAN['git_policy']['executable']))
    assert observed == dict(files=files, sdk_entries=entries, interpreters=PLAN['interpreters'],
                           git_launcher=PLAN['git_policy']['pin'])
    assert os.uname().sysname == 'Darwin' and os.uname().machine == 'arm64' and os.getuid() > 0
    return observed


def expected_permit(revision, pins_hash):
    assert os.getuid() == PLAN['normal_user']['uid'] and ROOT.stat().st_dev == PLAN['normal_user']['project_device']
    return dict(schema='fsmgen.compiler_census_permit.v1', admission_revision=revision,
                implementation_pins_sha256=pins_hash, plan_sha256=digest((BASE / 'plan.json').read_bytes()),
                owner=PLAN['execution_owner'], uid=os.getuid(), device=ROOT.stat().st_dev,
                cases=PLAN['cases'], output=PLAN['output'], compiler=PLAN['compiler'],
                native_proxy_execution=False, wrapper_execution=False, reusable=False)


def preflight(action):
    epoch = epoch_now()
    revision, pins_hash = sources()
    expected = expected_permit(revision, pins_hash)
    for case in PLAN['cases']:
        parent = (ROOT / case['workspace']).parent
        for path in [parent, *parent.parents]:
            if path == ROOT or path.is_relative_to(ROOT):
                s = path.lstat()
                assert stat.S_ISDIR(s.st_mode) and s.st_dev == ROOT.stat().st_dev and s.st_uid == os.getuid()
        assert not os.path.lexists(ROOT / case['workspace'])
    assert not os.path.lexists(OUTPUT / 'run-start.json')
    if action == 'emit':
        assert not os.path.lexists(OUTPUT)
        parent = OUTPUT.parent.lstat()
        assert stat.S_ISDIR(parent.st_mode) and parent.st_uid == os.getuid() and parent.st_dev == ROOT.stat().st_dev
        OUTPUT.mkdir(mode=0o700)
        save(OUTPUT / 'epoch-before.json', epoch)
        save(OUTPUT / 'permit.json', expected)
    else:
        assert set(os.listdir(OUTPUT)) == {'epoch-before.json', 'permit.json', 'runner.stdout', 'runner.stderr'}
        assert local_file(OUTPUT / 'runner.stdout', 4096) == local_file(OUTPUT / 'runner.stderr', 32768) == b''
        validate_permit(json.loads(local_file(OUTPUT / 'permit.json', 65536)), expected)
        assert json.loads(local_file(OUTPUT / 'epoch-before.json', 262144)) == epoch
    return dict(action=action, admission_revision=revision, qualified=True, compiler_invocations=0)


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('action', choices=['emit', 'check-run'])
    args = parser.parse_args()
    print(json.dumps(preflight(args.action), sort_keys=True))
