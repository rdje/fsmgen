"""Single admitted original; existing GatedTest owns release, bounds and reaping."""
import hashlib
import json
import os
from pathlib import Path
import signal
import subprocess
import sys
import time

ROOT = Path(__file__).resolve().parents[3]
sys.path.insert(0, str(ROOT / 'scripts'))
import run_fixture_startup_observation as launch
import observe_fixture_startup as observer

REVISION = 'e27b609d3fdc6ef823584f7726be9715ec28f535'
OUT = ROOT / '.artifacts/logs/native-proxy-original-20260910'
PLAN_PATH = ROOT / '.artifacts/tmp/native-proxy-original-20260910/admission.json'
raw_plan = PLAN_PATH.read_bytes()
if len(raw_plan) > 16384:
    raise ValueError('prospective admission exceeds its fixed bound')
PLAN = json.loads(raw_plan)
if (PLAN['source_revision'] != REVISION or PLAN['driver']['sha256'] != hashlib.sha256(Path(__file__).read_bytes()).hexdigest()
        or PLAN['argv'] != list(launch.TEST_ARGV) or PLAN['whole_test_seconds'] != launch.TEST_SECONDS
        or PLAN['output_bytes'] != launch.OUTPUT_BYTES or PLAN['original_limit'] != 1):
    raise ValueError('prospective admission differs from the fixed executable plan')


def selection_context_matches():
    expected = PLAN['host_selection_inputs']
    compiler = Path('/Library/Developer/CommandLineTools/usr/bin/clang').resolve()
    sdk = Path('/Library/Developer/CommandLineTools/SDKs/MacOSX.sdk').resolve()
    if (os.uname().sysname != expected['sysname'] or os.uname().machine != expected['machine']
            or str(compiler) != expected['compiler']['path'] or not os.access(compiler, os.X_OK)
            or str(sdk) != expected['sdk']['path'] or not sdk.is_dir()):
        return False
    before = compiler.stat()
    if before.st_size != expected['compiler']['bytes']:
        return False
    digest = hashlib.sha256()
    with compiler.open('rb') as stream:
        remaining = before.st_size
        while remaining:
            chunk = stream.read(min(1024 * 1024, remaining))
            if not chunk:
                return False
            digest.update(chunk)
            remaining -= len(chunk)
        if stream.read(1):
            return False
    after = compiler.stat()
    fields = ('st_dev', 'st_ino', 'st_size', 'st_mtime_ns', 'st_ctime_ns')
    return (all(getattr(before, key) == getattr(after, key) for key in fields)
            and before.st_size == expected['compiler']['bytes']
            and digest.hexdigest() == expected['compiler']['sha256']
            and sdk.stat().st_dev == expected['sdk']['device']
            and sdk.stat().st_ino == expected['sdk']['inode'])


if not selection_context_matches():
    raise ValueError('native selection context differs from prospective admission')
assert os.environ.get('FSMGEN_RAM_GUARD_ACTIVE') == '1', 'RAM guard required'
assert launch.TEST_ARGV == ('/usr/bin/perl', 't/1669-task-acceptance-fixture-runtime.t')
assert (launch.TEST_SECONDS, launch.OUTPUT_BYTES) == (200, 16 * 1024 * 1024)
OUT.mkdir(mode=0o700)  # Exclusive admission: an accidental rerun fails before launch.
assert OUT.stat().st_dev == ROOT.stat().st_dev


def write(name, value):
    with (OUT / name).open('x') as stream:
        json.dump(value, stream, sort_keys=True, indent=2)
        stream.write('\n')


def census():
    result = {}
    for relative in ('.artifacts/tmp/process-supervisor-tests',
                     '.artifacts/tmp/task-acceptance-tests',
                     '.artifacts/build/rust-parity'):
        parent = ROOT / relative
        entries = list(parent.iterdir()) if parent.exists() else []
        if len(entries) > 4096:
            raise ValueError('fixture-directory census exceeds its bound')
        result[relative] = {p.name: dict(device=p.lstat().st_dev, inode=p.lstat().st_ino)
                            for p in sorted(entries)}
    return result


def inputs():
    paths = subprocess.check_output(['git', 'ls-files', 't/1669-task-acceptance-fixture-runtime.t',
        't/lib/FSM/Test/*.pm', 't/fixtures/rust-tool-proxy.c', 'perl/FSM/Support/ProcessSupervisor*',
        'perl/FSM/ProjectDataLocality.pm', 'scripts/observe_fixture_startup.py',
        'scripts/run_fixture_startup_observation.py', 'scripts/fixture_kernel_sampler.py'],
        cwd=ROOT, text=True).splitlines()
    result = {}
    for relative in paths:
        data = (ROOT / relative).read_bytes()
        expected = subprocess.check_output(['git', 'show', REVISION+':'+relative], cwd=ROOT)
        if data != expected:
            raise ValueError('qualification input differs from admitted revision: '+relative)
        result[relative] = dict(bytes=len(data), sha256=hashlib.sha256(data).hexdigest())
    return result


native = launch.OwnedProcesses()
prior = census()
source_pins = inputs()
if source_pins != PLAN['source_pins']:
    raise ValueError('tracked input pins differ from prospective admission')
write('admission.json', dict(revision=REVISION, argv=list(launch.TEST_ARGV),
    host_isolation='not_proved', source_pins=source_pins,
    prospective_admission_sha256=hashlib.sha256(raw_plan).hexdigest(),
    host_selection_inputs=PLAN['host_selection_inputs'],
    implementation_inference='native from qualified host/toolchain selection inputs; producer image not observed',
    native_producer_identity_and_generated_bytes='not_observed_by_this_owner',
    whole_test_seconds=launch.TEST_SECONDS, output_bytes=launch.OUTPUT_BYTES,
    fixture_census=prior, new_original_limit=1, helper=False, collector=False))
original = None
result = None
errors = []
started = time.monotonic_ns()


def interrupted(signum, frame):
    raise InterruptedError('qualification interrupted by signal '+str(signum))


signal.signal(signal.SIGINT, interrupted)
signal.signal(signal.SIGTERM, interrupted)
try:
    original = launch.GatedTest(native, ROOT, OUT)
    native.test = original
    write('original-identity.json', original.identity)
    def ready():
        if inputs() != source_pins or not selection_context_matches():
            raise ValueError('input identity changed before exec release')
        return time.monotonic_ns()
    release = original.release(ready)
    write('release.json', release)
    result = original.finish()
except BaseException as error:
    errors.append(dict(type=type(error).__name__, message=str(error).replace(str(ROOT), '<repo>')))
finally:
    if original is not None and original.status is None:
        try:
            result = original.finish(cancel=True)
        except BaseException as error:
            errors.append(dict(type=type(error).__name__, message=str(error).replace(str(ROOT), '<repo>')))
    elif original is not None:
        result = original.finish()
finished = time.monotonic_ns()
if result is not None:
    write('test-result.json', result)
if original is not None and original.identity is not None:
    # Use the real native API, independent of OwnedProcesses' reaped-child shortcut.
    check_native = observer.Processes()
    original_absent = not observer.still_live(check_native, original.identity)
else:
    original_absent = None
post = census()
new_entries = {key: sorted(set(post[key]) - set(prior[key])) for key in prior}
outputs = {}
for name in ('test.tap', 'test.stderr'):
    data = (OUT / name).read_bytes() if (OUT / name).exists() else b''
    outputs[name] = dict(bytes=len(data), sha256=hashlib.sha256(data).hexdigest())
source_unchanged = inputs() == source_pins
selection_unchanged = selection_context_matches()
record = dict(started_monotonic_ns=started, finished_monotonic_ns=finished,
    result=result, errors=errors, original_native_birth_absent=original_absent,
    fixture_census_after=post, new_fixture_entries=new_entries,
    input_bytes_unchanged=source_unchanged, selection_context_unchanged=selection_unchanged, outputs=outputs,
    unobserved_descendants='unknown', host_isolation='not_proved')
write('qualification.json', record)
print(json.dumps(record, sort_keys=True))
ok = (not errors and result is not None and result['returncode'] == 0
      and result['released'] and result['leader_reaped'] and not result['timeout']
      and original_absent and source_unchanged and selection_unchanged and not any(new_entries.values()))
raise SystemExit(0 if ok else 1)
