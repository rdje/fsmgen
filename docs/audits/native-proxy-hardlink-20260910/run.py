"""Finite isolated hard-link experiment; production fixture execution is excluded."""
import hashlib
import json
import os
from pathlib import Path
import shutil
import signal
import stat
import struct
import subprocess
import sys
import time
from types import SimpleNamespace
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[3]
BASE = Path(__file__).resolve().parent
DURABLE = 'docs/audits/native-proxy-hardlink-20260910'
REVISION = 'dd7d2b5370326380b7b84846a09dfa969c7e6605'
OUT = ROOT / '.artifacts/logs/native-proxy-hardlink-20260910'
PARENT = ROOT / '.artifacts/tmp/process-supervisor-tests'
WORKSPACES = {name: PARENT / ('fsmgen-Hardlink' + label + '20260910')
              for name, label in [('base', 'Base'), ('a', 'A'), ('b', 'B')]}
GIT = str(Path(shutil.which('git')).resolve())
sys.path.insert(0, str(ROOT / 'scripts'))
import run_fixture_startup_observation as launch

observer = launch.observer
PRODUCERS = ('run.py', 'build.pl', 'held.c')
MARKER = b'CONTROL_READY\n'
SOURCE_LIMIT = 1048576
FILE_LIMIT = 65536
RECORD_LIMIT = 65536
LIMITATIONS = {'host_isolation': 'unproved', 'cold_host_state': 'unproved',
               'complete_policy_delivery': 'unproved', 'loaded_image_attestation': 'not_provided',
               'scan_avoidance': 'not_claimed', 'historical_startup_repair': 'unproved',
               'fixture': 'distinct held control; original and shipped fixture are not executed',
               'image_store': 'not_implemented', 'unobserved_descendants': 'unknown'}
DEPENDENCIES = 'Installed Perl/Python/Git, CLT compiler/SDK, libproc and OS log service are required read-only external dependencies; all project data stays on the repository volume.'


def read(path, limit=SOURCE_LIMIT):
    return observer.read_local_file(path, ROOT, limit)


def pin(raw):
    return {'bytes': len(raw), 'sha256': hashlib.sha256(raw).hexdigest()}


def relative(path):
    return str(path.relative_to(ROOT))


def source_pins():
    paths = subprocess.check_output([GIT, 'ls-files',
        't/1669-task-acceptance-fixture-runtime.t', 't/lib/FSM/Test/*.pm',
        't/fixtures/rust-tool-proxy.c', 'perl/FSM/Support/ProcessSupervisor*',
        'perl/FSM/ProjectDataLocality.pm', 'scripts/run_with_ram_guard.sh',
        'scripts/project_data_locality_env.sh'], cwd=ROOT, text=True, timeout=10).splitlines()
    for module in tuple(sys.modules.values()):
        name = getattr(module, '__file__', None)
        if name:
            path = Path(name).resolve()
            if path.parent == ROOT / 'scripts' and path.suffix == '.py':
                paths.append(relative(path))
    result = {}
    for name in sorted(set(paths)):
        raw = read(ROOT / name)
        if raw != subprocess.check_output([GIT, 'show', REVISION + ':' + name], cwd=ROOT, timeout=10):
            raise ValueError('production input differs from the admitted revision')
        result[name] = pin(raw)
    return result


def selection_context():
    compiler = Path('/Library/Developer/CommandLineTools/usr/bin/clang').resolve()
    sdk = Path('/Library/Developer/CommandLineTools/SDKs/MacOSX.sdk').resolve()
    before = compiler.stat()
    if not stat.S_ISREG(before.st_mode) or not os.access(compiler, os.X_OK) or before.st_size > 536870912:
        raise ValueError('admitted read-only compiler is unavailable')
    digest = hashlib.sha256()
    with compiler.open('rb') as stream:
        remaining = before.st_size
        while remaining:
            block = stream.read(min(1048576, remaining))
            if not block:
                raise ValueError('compiler read ended early')
            digest.update(block)
            remaining -= len(block)
        if stream.read(1):
            raise ValueError('compiler grew during its bounded read')
    after = compiler.stat()
    if any(getattr(before, key) != getattr(after, key) for key in
           ('st_dev', 'st_ino', 'st_size', 'st_mtime_ns', 'st_ctime_ns')):
        raise ValueError('compiler changed during its bounded read')
    info = sdk.stat()
    if not stat.S_ISDIR(info.st_mode):
        raise ValueError('admitted read-only SDK is unavailable')
    return {'sysname': os.uname().sysname, 'machine': os.uname().machine,
            'compiler': {'path': str(compiler), 'bytes': before.st_size, 'sha256': digest.hexdigest()},
            'sdk': {'path': str(sdk), 'device': info.st_dev, 'inode': info.st_ino,
                    'contents': 'not_fully_censused'}}


def producers():
    return {name: pin(read(BASE / name)) for name in PRODUCERS}


def bounds():
    return {'preparation_owner_seconds': 40, 'native_owner_seconds': 10,
            'owner_output_bytes_per_file': FILE_LIMIT, 'native_control_limit': 2,
            'preparation_owner_limit': 1, 'collector_limit': 1, 'original_limit': 0,
            'ready_seconds': launch.READY_SECONDS, 'reap_seconds': launch.REAP_SECONDS,
            'compiler_seconds': 10, 'compiler_capture_bytes': 4096,
            'collector_start_seconds': launch.policy_log.START_SECONDS,
            'collector_seconds': launch.policy_log.LIFETIME_SECONDS,
            'collector_reap_seconds': launch.policy_log.REAP_SECONDS,
            'collector_output_bytes_per_file': launch.policy_log.OUTPUT_BYTES,
            'native_path_observation_seconds': 5, 'held_body_seconds': 1}


def load_plan():
    raw = read(BASE / 'admission.json', 16384)
    plan = json.loads(raw)
    expected = {'schema': 'fsmgen.native_hardlink_admission.v1', 'source_revision': REVISION,
                'producers': producers(), 'bounds': bounds(), 'scope': 'daemon_context',
                'capsule': relative(OUT), 'workspaces': {name: relative(path) for name, path in WORKSPACES.items()},
                'roles': ['prepare', 'a', 'b'], 'control': 'held_path_observation_only',
                'limitations': LIMITATIONS, 'read_only_external_dependencies': DEPENDENCIES}
    if not isinstance(plan, dict) or set(plan) != set(expected) | {'source_pins', 'selection_context'} or any(plan.get(key) != value for key, value in expected.items()):
        raise ValueError('plan differs from the fixed experiment')
    if any(type(plan['bounds'][key]) is not int for key in bounds()):
        raise ValueError('bounds must retain exact integer types')
    return plan, pin(raw)


def verify_inputs(plan):
    if source_pins() != plan['source_pins'] or selection_context() != plan['selection_context'] or producers() != plan['producers']:
        raise ValueError('admitted production, control or toolchain inputs changed')


def verify_committed():
    if BASE != ROOT / DURABLE:
        raise ValueError('execute only the committed recovery driver')
    for name in (*PRODUCERS, 'admission.json'):
        raw = subprocess.check_output([GIT, 'show', 'HEAD:' + DURABLE + '/' + name], cwd=ROOT, timeout=10)
        if raw != read(BASE / name):
            raise ValueError('admission differs from its committed checkpoint')


def directory_identity(path):
    info = path.lstat()
    if path.resolve() != path or not stat.S_ISDIR(info.st_mode) or info.st_dev != ROOT.stat().st_dev or info.st_uid != os.getuid() or stat.S_IMODE(info.st_mode) != 0o700:
        raise ValueError('workspace is not an owned private repository directory')
    return {'path': relative(path), 'device': info.st_dev, 'inode': info.st_ino}


def source_identity(path, mode):
    before = path.lstat()
    raw = read(path, FILE_LIMIT)
    info = path.lstat()
    if not stat.S_ISREG(info.st_mode) or stat.S_IMODE(info.st_mode) != mode or any(
            getattr(before, key) != getattr(info, key) for key in
            ('st_dev', 'st_ino', 'st_size', 'st_mode', 'st_mtime_ns', 'st_ctime_ns')):
        raise ValueError('source type, permissions or identity changed during its read')
    return {'path': relative(path), 'device': info.st_dev, 'inode': info.st_ino,
            'size_bytes': len(raw), 'sha256': hashlib.sha256(raw).hexdigest()}, raw


def validate_preparation(envelope, workspace, context):
    if envelope.get('schema') != 'fsmgen.hardlink_control_preparation.v1' or envelope.get('control') != 'held_path_observation_only':
        raise ValueError('preparation does not identify the distinct held control')
    original = read(ROOT / 't/fixtures/rust-tool-proxy.c')
    held = read(BASE / 'held.c')
    if envelope.get('original_source_sha256') != hashlib.sha256(original).hexdigest() or envelope.get('control_source_sha256') != hashlib.sha256(held).hexdigest():
        raise ValueError('control preparation source witnesses changed')
    prepared = envelope['prepared']
    compiler = prepared['compilation']
    cleanup = compiler['cleanup']
    if prepared['schema'] != 'fsmgen.test.rust_proxy_fixture.v1' or type(prepared['ok']) is not int or prepared['ok'] != 1 or prepared['implementation'] != 'native' or prepared['status'] != 'success' or prepared['failure_stage'] is not None:
        raise ValueError('native control preparation failed')
    if compiler['ok'] != 1 or compiler['exit_code'] != 0 or compiler['signal'] != 0 or compiler['timed_out'] or compiler['output_limited']:
        raise ValueError('control compiler failed')
    if compiler['schema'] != 'fsmgen.test.rust_proxy_compilation.v1' or compiler['status'] != 'success' or compiler['exec_failed'] != 0 or compiler['exec_error'] is not None or cleanup['containment'] != 'rust_proxy_compiler_group' or cleanup['surviving_descendants'] != 0:
        raise ValueError('compiler execution or descendant cleanup is incomplete')
    if compiler['timeout_seconds'] != 10 or compiler['capture_limit_bytes'] != 4096 or any(type(cleanup.get(key)) is not int or cleanup[key] != 1 for key in ('leader_started', 'leader_reaped', 'group_gone')):
        raise ValueError('compiler policy or cleanup is incomplete')
    executable = workspace / 'rust-tools/rustup'
    c_source = executable.with_name('rustup.c')
    c_identity, c_bytes = source_identity(c_source, 0o400)
    executable_identity, binary = source_identity(executable, 0o500)
    if c_bytes != b'#define PROXY_NONZERO 1\n' + held:
        raise ValueError('compiled source is not the admitted held control')
    if len(binary) < 32 or struct.unpack('<IIII', binary[:16]) != (0xfeedfacf, 0x0100000c, 0, 2):
        raise ValueError('control output is not the admitted arm64 executable shape')
    expected_argv = [context['compiler']['path'], '--no-default-config', '-isysroot', context['sdk']['path'],
        '-arch', 'arm64', '-mmacosx-version-min=11.0', '-O2', '-Wall', '-Wextra', '-Werror',
        '-fno-builtin', '-fno-modules', relative(c_source), '-o', relative(executable)]
    if prepared['executable'] != relative(executable) or prepared['sources'] != [c_identity, executable_identity] or prepared['compilation_argv'] != expected_argv:
        raise ValueError('prepared source, executable or compiler invocation changed')
    return {'c': c_identity, 'binary': executable_identity}


def error_record(error):
    text = str(error).replace(str(ROOT), '<repo>').encode()
    return {'type': type(error).__name__, 'message': text[:1024].decode(errors='replace'),
            'message_truncated': len(text) > 1024}


class Experiment:
    def __init__(self, plan, native, record):
        self.plan, self.native, self.record = plan, native, record
        self.roles = []
        self.owners = []
        self.workspaces = {}
        self.bin_directories = {}
        self.collection = None
        self.sources = None
        self.results = {}
        self.errors = []
        self.compiler_settled = False
        self.failed = False

    def workspace(self, name):
        if name in self.workspaces:
            raise ValueError('workspace reservation already consumed')
        path = WORKSPACES[name]
        self.record('workspace-' + name + '-attempt.json', {'path': relative(path)})
        path.mkdir(mode=0o700)
        self.workspaces[name] = directory_identity(path)
        self.record('workspace-' + name + '.json', self.workspaces[name])
        return path

    def verify_workspace(self, name):
        if directory_identity(WORKSPACES[name]) != self.workspaces[name]:
            raise ValueError('workspace identity changed')
        if name in self.bin_directories and directory_identity(WORKSPACES[name] / 'rust-tools') != self.bin_directories[name]:
            raise ValueError('proxy directory identity changed')

    def verify_sources(self):
        self.verify_workspace('base')
        for name, filename, mode in [('c', 'rustup.c', 0o400), ('binary', 'rustup', 0o500)]:
            identity, _ = source_identity(WORKSPACES['base'] / 'rust-tools' / filename, mode)
            if identity != self.sources[name]:
                raise ValueError('prepared image identity or bytes changed')

    def alias(self, name):
        self.verify_sources()
        path = self.workspace(name) / 'rust-tools'
        path.mkdir(mode=0o700)
        self.bin_directories[name] = directory_identity(path)
        for filename in ('rustup', 'rustup.c'):
            os.link(WORKSPACES['base'] / 'rust-tools' / filename, path / filename)
        self.verify_alias(name)
        self.record('alias-' + name + '.json', {'workspace': self.workspaces[name],
                    'sources': self.alias_sources(name)})

    def alias_sources(self, name):
        return {key: source_identity(WORKSPACES[name] / 'rust-tools' / filename, mode)[0]
                for key, filename, mode in [('c', 'rustup.c', 0o400), ('binary', 'rustup', 0o500)]}

    def verify_alias(self, name):
        self.verify_workspace(name)
        self.verify_sources()
        for key, observed in self.alias_sources(name).items():
            expected = dict(self.sources[key], path=observed['path'])
            if observed != expected:
                raise ValueError('alias does not preserve the exact prepared inode and bytes')

    def ready(self, role):
        verify_inputs(self.plan)
        if role != 'prepare':
            self.collection.check()
            self.verify_alias(role)
        return time.monotonic_ns()

    def run_owner(self, role, on_live=None):
        if self.failed:
            raise ValueError('first failure permanently closed experiment admission')
        try:
            return self._run_owner(role, on_live)
        except BaseException:
            self.failed = True
            self.stop_owners()
            raise

    def _run_owner(self, role, on_live=None):
        expected = ['prepare', 'a', 'b']
        if len(self.roles) >= len(expected) or role != expected[len(self.roles)]:
            raise ValueError('fixed owner sequence already consumed or out of order')
        self.roles.append(role)
        self.record('owner-' + role + '-attempt.json', {'role': role, 'attempt': len(self.roles)})
        directory = OUT / role
        directory.mkdir(mode=0o700)
        argv = ('/usr/bin/perl', str(BASE / 'build.pl')) if role == 'prepare' else (str(WORKSPACES[role] / 'rust-tools/rustup'), 'which', 'cargo')
        seconds = 40 if role == 'prepare' else 10
        owner = None
        operation_error = None
        experiment = self

        class TrackedOwner(launch.GatedTest):
            def __init__(self, *args):
                self.role = role
                experiment.owners.append(self)
                super().__init__(*args)

        environment = {'PATH': '/usr/bin:/bin', 'LANG': 'C', 'LC_ALL': 'C',
                       'TMPDIR': str(ROOT / '.artifacts/tmp'), 'TMP': str(ROOT / '.artifacts/tmp'),
                       'TEMP': str(ROOT / '.artifacts/tmp'), 'FSMGEN_RAM_GUARD_ACTIVE': '1'}
        with patch.multiple(launch, TEST_ARGV=argv, TEST_SECONDS=seconds, OUTPUT_BYTES=FILE_LIMIT), patch.dict(os.environ, environment, clear=True):
            try:
                owner = TrackedOwner(self.native, ROOT, directory)
                self.record('owner-' + role + '-identity.json', owner.identity)
                self.record('owner-' + role + '-release.json', owner.release(lambda: self.ready(role)))
                if on_live is not None:
                    on_live(owner, directory)
            except BaseException as error:
                operation_error = error
                self.errors.append({'role': role, 'operation': error_record(error)})
            finally:
                if owner is not None:
                    try:
                        result = owner.finish(cancel=isinstance(operation_error, KeyboardInterrupt) or not owner.released)
                        self.results[role] = result
                        self.record('owner-' + role + '-result.json', result)
                    except BaseException as error:
                        self.errors.append({'role': role, 'cleanup_or_retention': error_record(error)})
                        if operation_error is None:
                            operation_error = error
        if operation_error is not None:
            raise operation_error
        result = self.results[role]
        if result['timeout'] or result['leader_reaped'] is not True or result['released'] is not True or observer.still_live(self.native, owner.identity):
            raise ValueError('owned control execution or independent absence failed')
        stdout, stderr = read(directory / 'test.tap', FILE_LIMIT), read(directory / 'test.stderr', FILE_LIMIT)
        expected_code = 0 if role == 'prepare' else 9
        if result['returncode'] != expected_code or result['native_wait_status'] != expected_code << 8 or stderr:
            raise ValueError('first owned execution has unexpected native status or stderr')
        if role != 'prepare' and stdout != MARKER:
            raise ValueError('held native control did not retain its exact main-entry marker')
        return stdout

    def observe_path(self, role, owner, label):
        if owner.poll() is not None or self.native.identity(owner.pid) != owner.identity:
            raise ValueError('held control disappeared before native path observation')
        executable = self.native.executable(owner.pid)
        expected = WORKSPACES[role] / 'rust-tools/rustup'
        if executable != expected:
            # Even a different same-inode alias is counterevidence to the exact
            # executable-path assumption being tested. Do not normalize it away.
            shown = relative(executable) if ROOT in executable.parents else '<external executable>'
            self.record(label + '-unexpected.json', {'identity': owner.identity,
                        'expected': relative(expected), 'observed': shown})
            raise ValueError('native executable path differs from the invoked private alias')
        if self.native.identity(owner.pid) != owner.identity or owner.poll() is not None:
            raise ValueError('held control birth changed during path observation')
        self.record(label + '.json', {'identity': owner.identity, 'executable': relative(executable),
                    'monotonic_ns': time.monotonic_ns(), 'source_identity': self.alias_sources(role)})

    def observe_control(self, role, owner, directory):
        deadline = min(owner.deadline, time.monotonic() + 5)
        inherited_executable = self.native.executable(os.getpid())
        while time.monotonic() < deadline:
            self.collection.check()
            if owner.poll() is not None or self.native.identity(owner.pid) != owner.identity:
                raise ValueError('held control exited before observable main entry')
            executable = self.native.executable(owner.pid)
            if executable != inherited_executable:
                self.observe_path(role, owner, role + '-exec')
                break
            time.sleep(0.002)
        else:
            raise TimeoutError('native executable path observation expired')
        while time.monotonic() < deadline:
            self.collection.check()
            if owner.poll() is not None:
                raise ValueError('held control exited before its marker was observed')
            marker = read(directory / 'test.tap', FILE_LIMIT)
            if marker == MARKER:
                break
            if marker and not MARKER.startswith(marker):
                raise ValueError('held control emitted an unexpected marker')
            time.sleep(0.002)
        else:
            raise TimeoutError('held native main-entry observation expired')
        self.record(role + '-main-entry.json', {'identity': owner.identity, 'marker': MARKER.decode(),
                    'observed_monotonic_ns': time.monotonic_ns()})
        self.verify_alias(role)
        if role == 'a':
            # This controlled mutation tests the shared-inode path assumption
            # while the first process still lives. It is not another execution.
            if owner.poll() is not None:
                raise ValueError('first control ended before alternate-link creation')
            self.alias('b')
            self.verify_alias('a')
            self.verify_alias('b')
            self.observe_path('a', owner, 'a-after-alias-b-access')
        else:
            self.verify_sources()
            self.observe_path('b', owner, 'b-after-base-access')

    def retire_alias(self, name):
        if name not in self.results or self.results[name]['leader_reaped'] is not True:
            raise ValueError('alias cannot retire before its owner is reaped')
        self.verify_alias(name)
        path = WORKSPACES[name]
        if {item.name for item in path.iterdir()} != {'rust-tools'} or {item.name for item in (path / 'rust-tools').iterdir()} != {'rustup', 'rustup.c'}:
            raise ValueError('alias contains an unexpected entry')
        for filename in ('rustup', 'rustup.c'):
            (path / 'rust-tools' / filename).unlink()
        (path / 'rust-tools').rmdir()
        path.rmdir()
        if path.exists() or path.is_symlink():
            raise ValueError('retired alias still exists')
        self.verify_sources()
        self.record('alias-' + name + '-retired.json', {'path': relative(path), 'absent': True,
                    'surviving_base_sources': self.sources})

    def archive_sources(self):
        directory = OUT / 'sources'
        directory.mkdir(mode=0o700)
        for name in ('c', 'binary'):
            expected = self.sources[name]
            raw = read(ROOT / expected['path'], FILE_LIMIT)
            if pin(raw) != {'bytes': expected['size_bytes'], 'sha256': expected['sha256']}:
                raise ValueError('prepared source changed before archival')
            path = directory / (expected['sha256'] + '.source')
            with path.open('xb') as stream:
                stream.write(raw)
            path.chmod(0o400)
            if read(path, FILE_LIMIT) != raw:
                raise ValueError('source archive differs from its input')
        self.record('source-archive.json', self.sources)

    def prepare(self):
        self.workspace('base')
        raw = self.run_owner('prepare')
        envelope = json.loads(raw)
        self.record('preparation.json', envelope)
        self.sources = validate_preparation(envelope, WORKSPACES['base'], self.plan['selection_context'])
        self.bin_directories['base'] = directory_identity(WORKSPACES['base'] / 'rust-tools')
        self.compiler_settled = True
        self.archive_sources()
        self.alias('a')

    def stop_owners(self):
        for owner in self.owners:
            if getattr(owner, 'pid', None) is not None and getattr(owner, 'status', None) is None:
                try:
                    result = owner.finish(cancel=True)
                    self.results[owner.role] = result
                    self.record('owner-' + owner.role + '-deferred-cleanup.json', result)
                except BaseException as error:
                    self.errors.append({'owner_cleanup': error_record(error)})

    def absent_owners(self):
        absent = []
        for owner in self.owners:
            identity = getattr(owner, 'identity', None)
            if identity is not None:
                if getattr(owner, 'status', None) is None or observer.still_live(self.native, identity):
                    raise ValueError('owned native birth is not independently absent')
                absent.append(identity)
        if self.collection is not None and self.collection.identity is not None:
            if observer.still_live(self.native, self.collection.identity):
                raise ValueError('collector native birth is not independently absent')
            absent.append(self.collection.identity)
        return absent

    def retire_base(self):
        if not self.compiler_settled or any(WORKSPACES[name].exists() for name in ('a', 'b')):
            raise ValueError('base image still has an unretired or unproved owner')
        self.absent_owners()
        self.verify_sources()
        path = WORKSPACES['base']
        pending, count = [path], 0
        while pending:
            with os.scandir(pending.pop()) as entries:
                for entry in entries:
                    count += 1
                    info = entry.stat(follow_symlinks=False)
                    if count > 256 or info.st_dev != ROOT.stat().st_dev or info.st_uid != os.getuid() or not (stat.S_ISREG(info.st_mode) or stat.S_ISDIR(info.st_mode)):
                        raise ValueError('base workspace cleanup census is unsafe or exceeds its bound')
                    if stat.S_ISDIR(info.st_mode):
                        pending.append(Path(entry.path))
        if {item.name for item in path.iterdir()} != {'rust-tools'} or {item.name for item in (path / 'rust-tools').iterdir()} != {'rustup', 'rustup.c', 'compiler-temp', 'compiler-cache'}:
            raise ValueError('base workspace contains an unexpected entry')
        shutil.rmtree(path)
        if path.exists() or path.is_symlink():
            raise ValueError('base workspace remains after owned cleanup')
        self.record('base-retired.json', {'path': relative(path), 'absent': True})


def execute_controls(experiment):
    experiment.prepare()
    policy_directory = OUT / 'policy'
    policy_directory.mkdir(mode=0o700)
    experiment.collection = launch.policy_log.PolicyLog(ROOT, policy_directory, experiment.native, scope='daemon_context')
    readiness = experiment.collection.prepare()
    if not isinstance(readiness, dict) or readiness.get('scope') != 'daemon_context':
        raise ValueError('collector readiness has the wrong fixed scope')
    experiment.record('policy-readiness.json', readiness)
    experiment.run_owner('a', lambda owner, directory: experiment.observe_control('a', owner, directory))
    experiment.retire_alias('a')
    experiment.verify_alias('b')
    experiment.run_owner('b', lambda owner, directory: experiment.observe_control('b', owner, directory))
    experiment.retire_alias('b')


def main():
    if len(sys.argv) != 1 or os.environ.get('FSMGEN_RAM_GUARD_ACTIVE') != '1' or sys.platform != 'darwin' or os.getuid() == 0 or os.geteuid() == 0:
        raise ValueError('fixed guarded normal-user Darwin execution is required')
    plan, plan_identity = load_plan()
    verify_committed()
    verify_inputs(plan)
    if any(path.exists() or path.is_symlink() for path in WORKSPACES.values()):
        raise ValueError('an admitted workspace already exists')
    observer.sampler.local_directory(OUT.parent, ROOT)
    observer.sampler.local_directory(PARENT, ROOT)
    previous_umask = os.umask(0o077)
    previous_signal = signal.getsignal(signal.SIGTERM)

    def interrupted(_signal, _frame):
        raise KeyboardInterrupt

    signal.signal(signal.SIGTERM, interrupted)
    experiment = None
    try:
        OUT.mkdir(mode=0o700)  # A partial attempt consumes the entire experiment.

        def record(name, value):
            raw = (json.dumps(value, sort_keys=True, indent=2) + '\n').encode()
            if len(raw) > RECORD_LIMIT:
                raise ValueError('experiment record exceeds its fixed byte bound')
            with (OUT / name).open('xb') as stream:
                stream.write(raw)

        record('admission.json', {'plan': plan_identity, 'producers': producers(),
               'source_revision': REVISION, 'source_pins': plan['source_pins'],
               'selection_context': plan['selection_context'], 'bounds': bounds(),
               'original_invocations': 0, 'host_isolation': 'unproved',
               'first_use': 'first_experiment_use_only; cold_host_state_unproved'})
        native = observer.Processes()
        experiment = Experiment(plan, native, record)
        policy_result = None
        absent = []
        complete = False
        try:
            execute_controls(experiment)
            complete = True
        except BaseException as error:
            experiment.errors.append({'experiment': error_record(error)})
        finally:
            experiment.stop_owners()
            if experiment.collection is not None:
                try:
                    policy_result = experiment.collection.finish()
                    retained = launch.retained_policy_result(SimpleNamespace(root=ROOT, directory=OUT / 'policy'), scope='daemon_context')
                    if retained != policy_result:
                        raise ValueError('collector result changed after publication')
                except BaseException as error:
                    experiment.errors.append({'collector_cleanup_or_retention': error_record(error)})
        try:
            absent = experiment.absent_owners()
            verify_inputs(plan)
            if complete and not experiment.errors:
                experiment.retire_base()
        except BaseException as error:
            experiment.errors.append({'postcheck': error_record(error)})
        outcome = {'roles_reserved': experiment.roles, 'results': experiment.results,
            'errors': experiment.errors, 'completed_sequence': complete,
            'independently_absent_identities': absent,
            'workspaces_remaining': {name: relative(path) for name, path in WORKSPACES.items() if path.exists() or path.is_symlink()},
            'collector_result': policy_result, 'original_invocations': 0,
            'control': 'held_path_observation_only', 'qualification': 'pending_independent_audit',
            'policy_delivery': 'unproved', 'scan_avoidance': 'not_claimed',
            'cold_host_state': 'unproved', 'historical_startup_repair': 'unproved',
            'unobserved_descendants': 'unknown'}
        record('outcome.json', outcome)
        print(json.dumps({'capsule': relative(OUT), 'outcome': outcome}, sort_keys=True))
        return 0 if complete and not experiment.errors and not outcome['workspaces_remaining'] else 1
    finally:
        if experiment is not None:
            experiment.stop_owners()
        signal.signal(signal.SIGTERM, previous_signal)
        os.umask(previous_umask)


if __name__ == '__main__':
    raise SystemExit(main())
