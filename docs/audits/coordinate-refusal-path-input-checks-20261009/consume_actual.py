"""Consume retained actual source-only producer and independent reader results."""
import copy
import hashlib
import json
import subprocess
from pathlib import Path

BASE = Path('docs/audits/coordinate-refusal-path-inputs-20261009')
CHECKS = Path('docs/audits/coordinate-refusal-path-input-checks-20261009')


def need(ok, cause):
    if not ok:
        raise ValueError(cause)


def pin(raw):
    return {'bytes': len(raw), 'sha256': hashlib.sha256(raw).hexdigest()}


def check(producer, reader):
    for receipt, name in ((producer, 'paths.py'), (reader, 'verify.py')):
        need(type(receipt['status']) is int and receipt['status'] == 0, 'discrete actual successful status')
        need(receipt['command'] == ['scripts/run_with_ram_guard.sh', '--', 'python3', '-B', str(BASE / name)],
             'exact actual owned source-only invocation')
        for path in ('scripts/run_with_ram_guard.sh', str(BASE / name), str(CHECKS / 'checks.py')):
            need(receipt['instruments'][path] == pin(Path(path).read_bytes()), 'complete actual instrument identity')
        need(type(receipt['stdout']) is str and type(receipt['stderr']) is str, 'complete actual stream kinds')
    need(producer['stdout'] == 'PASS complete source-only path input allocation; statement hypotheses and original coordinate selection remain pending.\n',
         'whole actual source-only producer result')
    replay = subprocess.run(['python3', '-B', str(BASE / 'verify.py')], capture_output=True, text=True)
    need(type(replay.returncode) is int and replay.returncode == 0 and not replay.stderr
         and replay.stdout == reader['stdout'], 'whole actual independently regenerated qualification result')


def main():
    checks = json.loads((CHECKS / 'checks.json').read_bytes())
    producer, reader = checks['path-inputs-domain'], checks['independent-path-inputs']
    check(producer, reader)
    for name, bad, cause in (
        ('Boolean-status', dict(reader, status=True), 'discrete actual successful status'),
        ('false-result', dict(reader, stdout='PASS\n'), 'whole actual independently regenerated qualification result'),
    ):
        try:
            check(producer, bad)
        except ValueError as error:
            need(str(error) == cause, 'intended actual receipt refusal: ' + name)
        else:
            raise ValueError('false-green actual receipt: ' + name)
    bad = copy.deepcopy(reader)
    bad['instruments'][str(BASE / 'verify.py')]['bytes'] += 1
    try:
        check(producer, bad)
    except ValueError as error:
        need(str(error) == 'complete actual instrument identity', 'intended actual instrument refusal')
    else:
        raise ValueError('false-green actual instrument identity')
    print('PASS whole actual source-only producer/reader results and genuine status/result/instrument controls.')


if __name__ == '__main__':
    main()
