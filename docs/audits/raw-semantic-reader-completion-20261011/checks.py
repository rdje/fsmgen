"""Capture every external guard terminal outside its process tree; retain full streams."""
import subprocess
import sys
from common import *
from verify import instruments


def update(name, row, replace=False):
    records = load('checks.json') if (BASE / 'checks.json').exists() else {}
    need((name in records) == replace, 'retain first complete external gate result')
    records[name] = row
    local(BASE / 'checks.json', exists=False).write_bytes(canonical(records))


if __name__ == '__main__':
    need(len(sys.argv) >= 3, 'named explicit external gate command')
    name, inner = sys.argv[1], sys.argv[2:]
    need(name and all(c.isalnum() or c == '-' for c in name), 'plain external gate label')
    folder = local(Path('.artifacts/raw-semantic-reader-completion-20261011/checks') / name, exists=False)
    need(not folder.exists(), 'fresh first external stream directory')
    folder.mkdir(parents=True)
    command = ['scripts/run_with_ram_guard.sh', '--', *inner]
    epoch = instruments()
    inputs = {p: row['identity'] for p, row in epoch.items()}
    for arg in inner:
        if '\n' not in arg and len(arg) < 240 and Path(arg).is_file():
            inputs[arg] = pin(local(arg).read_bytes())
    for path in ('scripts/check_record_value_publication.py', 'scripts/record_value_observer_fact.py',
                 'scripts/record_value_observer_namespace_fact.py',
                 'docs/knowledge/record-value-original-observer-helper-paths.md',
                 'docs/book/src/13k-isf-feature-support-matrix.md'):
        inputs[path] = pin(local(path).read_bytes())
    stdout, stderr = folder / 'stdout.txt', folder / 'stderr.txt'
    started = dict(command=command, programmes=epoch, inputs=inputs,
        stdout_path=str(stdout), stderr_path=str(stderr),
        outcome='started; a missing terminal is non-success; this writer is outside the guard')
    update(name, started)
    with stdout.open('xb', buffering=0) as out, stderr.open('xb', buffering=0) as err:
        result = subprocess.run(command, stdout=out, stderr=err)
    after = {p: pin(local(p).read_bytes()) for p in inputs}
    after_epoch = instruments()
    actual = dict(**started, status=result.returncode, stdout=stdout.read_text(), stderr=stderr.read_text(),
        inputs_after=after, programmes_after=after_epoch, epoch_conserved=inputs == after and epoch == after_epoch)
    update(name, actual, replace=True)
    print(name, 'actual status', result.returncode, flush=True)
    need(actual['epoch_conserved'] is True, 'whole unchanged external programme/source epoch')
    need(type(result.returncode) is int and result.returncode == 0, 'actual successful external gate: ' + name)
