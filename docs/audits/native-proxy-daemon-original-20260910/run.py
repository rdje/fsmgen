"""One admitted daemon-only original; production callers retain all lifecycle policy."""
import hashlib
import json
import os
from pathlib import Path
import runpy
import stat
import subprocess
import sys
import time
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[3]
sys.path.insert(0, str(ROOT / 'scripts'))
import run_fixture_startup_policy_observation as caller

launch = caller.launcher
observer = launch.observer
REVISION = '890ee5495f50806edfd4ee81b1148e872640a706'
ENTRY = ROOT / 'scripts/run_fixture_startup_daemon_observation.py'
OUT = ROOT / '.artifacts/logs/native-proxy-daemon-original-20260910'
PLAN_PATH = Path(__file__).resolve().with_name('admission.json')
DURABLE = 'docs/audits/native-proxy-daemon-original-20260910'
SOURCE_LIMIT = 1048576
RECORD_LIMIT = 65536


def bounded_bytes(path, limit):
    path = path if path.is_absolute() else ROOT / path
    before = path.lstat()
    if (path.resolve() != path or before.st_dev != ROOT.stat().st_dev
            or not stat.S_ISREG(before.st_mode) or before.st_size > limit):
        raise ValueError('input exceeds its fixed file bound')
    data = observer.read_local_file(path, ROOT, limit)
    after = path.lstat()
    fields = ('st_dev', 'st_ino', 'st_size', 'st_mtime_ns', 'st_ctime_ns')
    if len(data) > limit or len(data) != before.st_size or any(
            getattr(before, key) != getattr(after, key) for key in fields):
        raise ValueError('input changed during bounded read')
    return data


def pin(data):
    return {'bytes': len(data), 'sha256': hashlib.sha256(data).hexdigest()}


def bounds():
    return {'original_seconds': launch.TEST_SECONDS, 'original_output_bytes_per_file': launch.OUTPUT_BYTES,
            'ready_seconds': launch.READY_SECONDS, 'exec_seconds': launch.EXEC_SECONDS,
            'original_reap_seconds': launch.REAP_SECONDS,
            'collector_start_seconds': launch.policy_log.START_SECONDS,
            'collector_seconds': launch.policy_log.LIFETIME_SECONDS,
            'collector_reap_seconds': launch.policy_log.REAP_SECONDS,
            'collector_output_bytes_per_file': launch.policy_log.OUTPUT_BYTES,
            'fixture_settle_seconds': observer.SETTLE_SECONDS,
            'journal_events': observer.MAX_EVENTS, 'journal_event_bytes': observer.MAX_EVENT_BYTES,
            'journal_bytes': observer.MAX_LOG_BYTES, 'source_files': observer.MAX_SOURCE_FILES,
            'source_bytes': observer.MAX_SOURCE_BYTES}


def inputs():
    selected = subprocess.check_output(['git', 'ls-files',
        't/1669-task-acceptance-fixture-runtime.t', 't/lib/FSM/Test/*.pm',
        't/fixtures/rust-tool-proxy.c', 'perl/FSM/Support/ProcessSupervisor*',
        'perl/FSM/ProjectDataLocality.pm', 'scripts/run_fixture_startup_daemon_observation.py'],
        cwd=ROOT, text=True, timeout=10).splitlines()
    for module in tuple(sys.modules.values()):
        filename = getattr(module, '__file__', None)
        if filename:
            path = Path(filename).resolve()
            if path.parent == ROOT / 'scripts' and path.suffix == '.py':
                selected.append(str(path.relative_to(ROOT)))
    result = {}
    for relative in sorted(set(selected)):
        data = bounded_bytes(ROOT / relative, SOURCE_LIMIT)
        expected = subprocess.check_output(['git', 'show', REVISION + ':' + relative], cwd=ROOT, timeout=10)
        if data != expected:
            raise ValueError('input differs from admitted revision: ' + relative)
        result[relative] = pin(data)
    return result


def selection_context():
    compiler = Path('/Library/Developer/CommandLineTools/usr/bin/clang').resolve()
    sdk = Path('/Library/Developer/CommandLineTools/SDKs/MacOSX.sdk').resolve()
    before = compiler.stat()
    if not compiler.is_file() or not os.access(compiler, os.X_OK) or before.st_size > 536870912 or not sdk.is_dir():
        raise ValueError('required read-only native toolchain is unavailable')
    digest = hashlib.sha256()
    with compiler.open('rb') as stream:
        remaining = before.st_size
        while remaining:
            chunk = stream.read(min(1048576, remaining))
            if not chunk:
                raise ValueError('compiler read ended early')
            digest.update(chunk)
            remaining -= len(chunk)
        if stream.read(1):
            raise ValueError('compiler grew during read')
    after = compiler.stat()
    fields = ('st_dev', 'st_ino', 'st_size', 'st_mtime_ns', 'st_ctime_ns')
    if any(getattr(before, key) != getattr(after, key) for key in fields):
        raise ValueError('compiler identity changed during read')
    sdk_stat = sdk.stat()
    return {'sysname': os.uname().sysname, 'machine': os.uname().machine,
            'compiler': {'path': str(compiler), 'bytes': before.st_size, 'sha256': digest.hexdigest()},
            'sdk': {'path': str(sdk), 'device': sdk_stat.st_dev, 'inode': sdk_stat.st_ino,
                    'contents': 'not_fully_censused'}}


def load_plan():
    raw = bounded_bytes(PLAN_PATH, 16384)
    plan = json.loads(raw)
    if (plan['schema'] != 'fsmgen.native_proxy_daemon_admission.v1' or plan['source_revision'] != REVISION or plan['driver'] != pin(bounded_bytes(Path(__file__), SOURCE_LIMIT))
            or plan['entrypoint'] != str(ENTRY.relative_to(ROOT))
            or plan['argv'] != list(launch.TEST_ARGV) or plan['bounds'] != bounds()
            or type(plan['original_limit']) is not int or plan['original_limit'] != 1 or plan['scope'] != 'daemon_context'
            or plan['capsule'] != str(OUT.relative_to(ROOT))):
        raise ValueError('prospective plan differs from the fixed driver')
    return plan, pin(raw)


def verify_committed_plan():
    for name, path in [('run.py', Path(__file__)), ('admission.json', PLAN_PATH)]:
        committed = subprocess.check_output(['git', 'show', 'HEAD:' + DURABLE + '/' + name],
                                             cwd=ROOT, timeout=10)
        if committed != bounded_bytes(path, SOURCE_LIMIT):
            raise ValueError('admission driver or plan differs from committed checkpoint')


def verify_inputs(plan):
    if inputs() != plan['source_pins'] or selection_context() != plan['host_selection_inputs']:
        raise ValueError('admitted source or selection inputs changed')


def make_gate(base, check, record):
    state = {'constructor_attempts': 0, 'release_attempts': 0, 'original': None}

    class AdmittedGate(base):
        def __init__(self, *args, **kwargs):
            if state['constructor_attempts']:
                raise ValueError('single original reservation already consumed')
            state['constructor_attempts'] = 1
            record('original-reservation-attempt.json', {'attempt': 1})
            check()
            state['original'] = self
            super().__init__(*args, **kwargs)
            record('original-identity.json', self.identity)

        def release(self, prepare):
            if state['release_attempts']:
                raise ValueError('single original release already consumed')
            state['release_attempts'] = 1
            def checked_ready():
                check()
                ready = prepare()
                record('release-admitted.json', {'ready_ns': ready, 'pid': self.pid})
                return ready
            witness = super().release(checked_ready)
            record('release.json', witness)
            return witness

    return AdmittedGate, state


def census():
    result = {}
    for relative in ('.artifacts/tmp/process-supervisor-tests', '.artifacts/tmp/task-acceptance-tests',
                     '.artifacts/build/rust-parity'):
        parent = ROOT / relative
        entries = list(parent.iterdir()) if parent.exists() else []
        if len(entries) > 4096:
            raise ValueError('fixture census exceeds its fixed bound')
        result[relative] = {p.name: {'device': p.lstat().st_dev, 'inode': p.lstat().st_ino}
                            for p in sorted(entries)}
    return result


def error_record(error):
    message = str(error).replace(str(ROOT), '<repo>').encode()
    return {'type': type(error).__name__, 'message': message[:1024].decode(errors='replace'),
            'message_truncated': len(message) > 1024}


def main():
    if os.environ.get('FSMGEN_RAM_GUARD_ACTIVE') != '1' or sys.platform != 'darwin' or os.getuid() == 0 or os.geteuid() == 0:
        raise ValueError('guarded normal-user Darwin execution is required')
    plan, plan_identity = load_plan()
    verify_committed_plan()
    verify_inputs(plan)
    before = census()
    if any(before.values()):
        raise ValueError('prospective fixture roots are not empty')
    if OUT.parent.resolve() != OUT.parent or OUT.parent.stat().st_dev != ROOT.stat().st_dev:
        raise ValueError('admission capsule parent is not repository-local')
    previous_umask = os.umask(0o077)
    try:
        OUT.mkdir(mode=0o700)  # Nonce: even a partial attempt cannot be silently repeated.
        def record(name, value):
            raw = (json.dumps(value, sort_keys=True, indent=2) + '\n').encode()
            if len(raw) > RECORD_LIMIT:
                raise ValueError('admission record exceeds its fixed bound')
            with (OUT / name).open('xb') as stream:
                stream.write(raw)

        record('admission.json', {'source_revision': REVISION, 'plan': plan_identity,
            'driver': plan['driver'], 'source_pins': plan['source_pins'], 'bounds': bounds(),
            'host_selection_inputs': plan['host_selection_inputs'], 'fixture_census_before': before,
            'scope': 'daemon_context', 'kernel_sample': 'not_collected', 'original_limit': 1,
            'host_isolation': 'not_proved', 'calibration_publication': 'not_selected'})
        gate, state = make_gate(launch.GatedTest, lambda: verify_inputs(plan), record)
        evidence_state = {'count': 0, 'evidence': None}
        actual_evidence = observer.Evidence
        def admitted_evidence(root):
            if root != ROOT or evidence_state['count']:
                raise ValueError('single evidence root already consumed or changed')
            evidence_state['count'] = 1
            evidence = actual_evidence(root)
            evidence_state['evidence'] = evidence
            record('observation.json', {'directory': str(evidence.directory.relative_to(ROOT))})
            return evidence

        errors = []
        cli_status = None
        started = time.monotonic_ns()
        try:
            with patch.object(launch, 'GatedTest', gate), patch.object(observer, 'Evidence', admitted_evidence), \
                    patch.object(sys, 'argv', [str(ENTRY.relative_to(ROOT))]):
                runpy.run_path(str(ENTRY), run_name='__main__')
        except SystemExit as result:
            cli_status = result.code
        except BaseException as error:
            errors.append(error_record(error))
        finally:
            original = state['original']
            if original is not None and getattr(original, 'pid', None) is not None and original.status is None:
                try:
                    original.finish(cancel=True)
                except BaseException as error:
                    errors.append(error_record(error))
            evidence = evidence_state['evidence']
            if evidence is not None and not evidence.stream.closed:
                try:
                    evidence.stream.close()
                except BaseException as error:
                    errors.append(error_record(error))

        result = absent = after = stable = None
        original = state['original']
        if original is not None and getattr(original, 'status', None) is not None:
            try:
                result = original.result()
                record('original-result.json', result)
            except BaseException as error:
                errors.append(error_record(error))
        if original is not None and getattr(original, 'identity', None) is not None:
            try:
                absent = not observer.still_live(observer.Processes(), original.identity)
            except BaseException as error:
                errors.append(error_record(error))
        try:
            verify_inputs(plan)
            stable = True
        except BaseException as error:
            stable = False
            errors.append(error_record(error))
        try:
            after = census()
        except BaseException as error:
            errors.append(error_record(error))
        outcome = {'started_monotonic_ns': started, 'finished_monotonic_ns': time.monotonic_ns(),
            'cli_status': cli_status, 'errors': errors, 'original': result, 'original_birth_absent': absent,
            'constructor_attempts': state['constructor_attempts'], 'release_attempts': state['release_attempts'],
            'evidence_directory': str(evidence.directory.relative_to(ROOT)) if evidence is not None else None,
            'inputs_unchanged': stable, 'fixture_census_after': after,
            'kernel_sample': 'not_collected', 'unobserved_descendants': 'unknown', 'qualification': 'pending_independent_audit'}
        record('outcome.json', outcome)
        print(json.dumps({'capsule': str(OUT.relative_to(ROOT)), 'outcome': outcome}, sort_keys=True))
        return 0 if (type(cli_status) is int and cli_status == 0 and not errors and result is not None
                     and result['returncode'] == 0 and result['leader_reaped'] and result['released']
                     and not result['timeout'] and absent and stable and after is not None and not any(after.values())) else 1
    finally:
        os.umask(previous_umask)


if __name__ == '__main__':
    raise SystemExit(main())
