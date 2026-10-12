"""Save each complete native guard terminal outside the guarded process tree."""
import argparse
import hashlib
import json
from pathlib import Path
import subprocess

BASE = Path('docs/audits/original-context-cause-consumer-prerequisites-20261012')


def pin(raw):
    return dict(bytes=len(raw), sha256=hashlib.sha256(raw).hexdigest())


def canonical(value):
    return (json.dumps(value, sort_keys=True, separators=(',', ':'), ensure_ascii=True, allow_nan=False) + '\n').encode()


def save(name, value):
    path = BASE / name
    if path.exists():
        raise ValueError('retain first complete recovery record: ' + name)
    path.write_bytes(canonical(value))


def instruments(command):
    names = {str(BASE / 'capture.py'), 'scripts/restore_record_value_gate_streams.py',
             't/python/test_record_value_gate_streams.py', 'scripts/check_record_value_publication.py',
             'scripts/record_value_raw_fact.py', 'scripts/record_value_consumer_fact.py', 'scripts/record_value_cause_fact.py', 't/python/test_record_value_current_publication.py'}
    plan = json.loads((BASE / 'plan.json').read_bytes())
    names.update(str(BASE / name) for name in ('plan.json', 'book-review.json', 'guide.txt',
        'integration-contract.json', 'cause-normal-commit.json', 'activation-task.gz',
        'activation-memory.gz', 'activation-index.gz', 'reader-contracts.json',
        'activation-task-first.gz', 'preparation-first.json', 'preparation-second.json',
        'preparation-first-source.txt', 'preparation-second-source.txt', 'preparation-partial-programmes.json', 'capture-input-expansion.json'))
    names.update(str(path) for path in BASE.glob('*.py'))
    for role in ('context', 'cause', 'consumer'):
        names.update(str(path) for path in Path(plan[role]).glob('*.py'))
    names.update(arg for arg in command if '\n' not in arg and len(arg) < 240 and Path(arg).is_file())
    result = {}
    for name in sorted(names):
        raw = Path(name).read_bytes()
        try:
            body = dict(body=raw.decode('utf-8'))
        except UnicodeDecodeError:
            body = dict(body_hex=raw.hex())
        result[name] = dict(**body, identity=pin(raw))
    return result


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--expect', type=int, choices=(0, 1), default=0)
    parser.add_argument('label')
    parser.add_argument('command', nargs=argparse.REMAINDER)
    args = parser.parse_args()
    if not args.command or not args.label or any(c not in 'abcdefghijklmnopqrstuvwxyz0123456789-' for c in args.label):
        raise ValueError('explicit ordinary recovery gate and command')
    command = ['scripts/run_with_ram_guard.sh', '--', *args.command]
    epoch = instruments(args.command)
    folder = Path('.artifacts') / BASE.name / 'checks' / args.label
    # The public boundary checker validates the output route without creating it.
    import importlib.util
    spec = importlib.util.spec_from_file_location('recovery', 'scripts/restore_record_value_gate_streams.py')
    recovery = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(recovery)
    recovery.local(folder)
    folder.mkdir(parents=True, exist_ok=False)
    stdout, stderr = folder / 'stdout.txt', folder / 'stderr.txt'
    started = dict(command=command, programmes=epoch, expected_status=args.expect,
        stdout_path=str(stdout), stderr_path=str(stderr),
        condition='Complete native terminal writer outside unchanged guard; an expected refusal is not successful original replay.')
    save(args.label + '-started.json', started)
    with stdout.open('xb', buffering=0) as out, stderr.open('xb', buffering=0) as err:
        result = subprocess.run(command, stdout=out, stderr=err)
    actual = dict(**started, status=result.returncode, stdout=stdout.read_text(), stderr=stderr.read_text(),
                  programmes_after=instruments(args.command))
    save(args.label + '-actual.json', actual)
    print(args.label, 'actual native status', result.returncode, flush=True)
    if type(result.returncode) is not int or result.returncode != args.expect or epoch != actual['programmes_after']:
        raise SystemExit(1)
