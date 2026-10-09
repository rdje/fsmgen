"""Consume actual census/reader results separately from their immutable seal."""
import copy
import hashlib
import json
import subprocess
from pathlib import Path

BASE = Path('docs/audits/artifact-sweep-due-20261009')
CHECKS = Path('docs/audits/artifact-sweep-due-checks-20261009')


def require(ok, cause):
    if not ok:
        raise ValueError(cause)


def check(capture, reader):
    for receipt, programme in [(capture, 'census.py'), (reader, 'verify.py')]:
        require(type(receipt['status']) is int and receipt['status'] == 0, 'actual discrete successful status')
        require(receipt['command'] == ['scripts/run_with_ram_guard.sh', '--', 'python3', '-B', str(BASE / programme)], 'actual exact owned command')
        require(type(receipt['stdout']) is str and type(receipt['stderr']) is str, 'whole actual stream kinds')
    report = json.loads((BASE / 'census.json').read_bytes())
    expected = {'status': 0, 'artifact_members': len(report['artifacts']), 'removed': [], 'utc': report['utc']}
    require(capture['stdout'] == json.dumps(expected, sort_keys=True) + '\n', 'complete actual census result membership/time')
    replay = subprocess.run(['python3', '-B', str(BASE / 'verify.py')], capture_output=True, text=True)
    require(replay.returncode == 0 and replay.stdout == reader['stdout'], 'actual sealed reader complete regenerated result')


def main():
    capture = json.loads((BASE / 'actual-census.json').read_bytes())
    reader = json.loads((CHECKS / 'sealed-reader.json').read_bytes())
    before = {p.name: hashlib.sha256(p.read_bytes()).hexdigest() for p in BASE.iterdir()}
    check(capture, reader)
    for value in (True, 0.0, 1):
        for target in ('capture', 'reader'):
            bad = copy.deepcopy(capture if target == 'capture' else reader)
            bad['status'] = value
            try:
                check(bad if target == 'capture' else capture, bad if target == 'reader' else reader)
            except ValueError as error:
                require(str(error) == 'actual discrete successful status', 'intended actual receipt status refusal')
            else:
                raise ValueError('false-green actual receipt status')
    changed = copy.deepcopy(capture)
    changed['stdout'] = changed['stdout'].replace(report_time(capture), 'borrowed-time')
    require(changed['stdout'] != capture['stdout'], 'genuine actual result intervention')
    try:
        check(changed, reader)
    except ValueError as error:
        require(str(error) == 'complete actual census result membership/time', 'intended actual result refusal')
    else:
        raise ValueError('false-green actual census result')
    require(before == {p.name: hashlib.sha256(p.read_bytes()).hexdigest() for p in BASE.iterdir()}, 'immutable census members conserve')
    print('PASS complete actual census/reader results, typed status/result controls and immutable member conservation.')


def report_time(capture):
    return json.loads(capture['stdout'])['utc']


if __name__ == '__main__':
    main()
