"""Mutable external gate receipts with durable streams and complete programme epochs."""
import fcntl
import json
import subprocess
import sys
from pathlib import Path
from common import *


def update(name, row, replace=False):
    lock_path = local(Path('.artifacts/raw-association-acceptance-20261011/checks.lock'), exists=False)
    lock_path.parent.mkdir(parents=True, exist_ok=True)
    with lock_path.open('a+b') as lock:
        fcntl.flock(lock, fcntl.LOCK_EX)
        records = load('checks.json') if (BASE / 'checks.json').exists() else {}
        need((name in records) == replace, 'retain first complete gate receipt')
        records[name] = row
        (BASE / 'checks.json').write_bytes(canonical(records))


if __name__ == '__main__':
    need(len(sys.argv) >= 3, 'named explicit gate command')
    name, command = sys.argv[1], sys.argv[2:]
    need(name and all(c.isalnum() or c == '-' for c in name), 'closed gate receipt label')
    folder = local(Path('.artifacts/raw-association-acceptance-20261011/checks') / name, exists=False)
    need(not folder.exists(), 'fresh complete gate stream directory')
    folder.mkdir(parents=True)
    epoch = programs()
    inputs = {path: row['identity'] for path, row in epoch.items()}
    for arg in command:
        if '\n' not in arg and len(arg) < 240 and Path(arg).is_file():
            inputs[arg] = pin(local(arg).read_bytes())
    for path in ('scripts/check_record_value_publication.py', 'scripts/record_value_observer_fact.py',
                 'scripts/record_value_observer_namespace_fact.py',
                 'docs/knowledge/record-value-original-observer-helper-paths.md'):
        inputs[path] = pin(local(path).read_bytes())
    if name != 'publication':
        inputs['docs/book/src/13k-isf-feature-support-matrix.md'] = pin(local('docs/book/src/13k-isf-feature-support-matrix.md').read_bytes())
    else:
        need(command == ['python3', '-B', str(BASE / 'publish.py')], 'explicit owned publication mutation role')
    stdout, stderr = folder / 'stdout.txt', folder / 'stderr.txt'
    started = dict(command=command, programmes=epoch, inputs=inputs, stdout_path=str(stdout), stderr_path=str(stderr),
                   outcome='started; missing terminal result is non-success')
    update(name, started)
    with stdout.open('xb', buffering=0) as out, stderr.open('xb', buffering=0) as err:
        result = subprocess.run(command, stdout=out, stderr=err)
    after = {path: pin(local(path).read_bytes()) for path in inputs}
    after_epoch = programs()
    record = dict(**started, status=result.returncode, stdout=stdout.read_bytes().decode(), stderr=stderr.read_bytes().decode(),
                  inputs_after=after, programmes_after=after_epoch, epoch_conserved=inputs == after and epoch == after_epoch)
    update(name, record, replace=True)
    print(name, result.returncode, record['stdout'][-1800:], record['stderr'][-1800:], flush=True)
    need(after == inputs and after_epoch == epoch, 'whole gate programme/source epoch conserved')
    need(type(result.returncode) is int and result.returncode == 0, 'actual successful external gate: ' + name)
