"""Authenticate complete actual producer/published-reader receipts and controls."""
import copy
import hashlib
import json
import re
import subprocess
from pathlib import Path

BASE = Path('docs/audits/coordinate-source-hypotheses-20261009')
CHECKS = Path('docs/audits/coordinate-source-hypothesis-checks-20261009')


def need(ok, cause):
    if not ok:
        raise ValueError(cause)


def pin(raw):
    return {'bytes': len(raw), 'sha256': hashlib.sha256(raw).hexdigest()}


def check(producer, reader):
    for receipt, programme in ((producer, BASE / 'qualify.py'), (reader, CHECKS / 'verify_hypotheses.py')):
        need(type(receipt['status']) is int and receipt['status'] == 0, 'discrete actual successful status')
        need(receipt['command'] == ['scripts/run_with_ram_guard.sh', '--', 'python3', '-B', str(programme)],
             'exact actual source-only hypothesis invocation')
        need(set(receipt['instruments']) == {str(programme), str(CHECKS / 'checks.py'), 'scripts/run_with_ram_guard.sh'},
             'complete actual hypothesis instrument domain')
        for path, identity in receipt['instruments'].items():
            need(identity == pin(Path(path).read_bytes()), 'complete actual hypothesis instrument identity')
        need(type(receipt['stdout']) is str and type(receipt['stderr']) is str, 'complete actual hypothesis stream kinds')
        need(re.fullmatch(r'ram-guard: PID [0-9]+; host [0-9]+(?:\.[0-9]+)?%; host cutoff 88%; '
                          r'descendant RSS cutoff 4096 MiB; poll 2s\n', receipt['stderr']) is not None,
             'complete actual unchanged RAM guard result')
    need(producer['stdout'] == 'PASS complete source-hypothesis publication and actual source-only readers; original coordinates remain unmeasured.\n',
         'whole actual source-only hypothesis producer result')
    replay = subprocess.run(['python3', '-B', str(CHECKS / 'verify_hypotheses.py')], capture_output=True, text=True)
    need(replay.returncode == 0 and not replay.stderr and replay.stdout == reader['stdout'],
         'whole actual independently regenerated hypothesis qualification')


def main():
    receipts = json.loads((CHECKS / 'checks.json').read_bytes())
    producer, reader = receipts['source-publication'], receipts['published-sealed']
    check(producer, reader)
    controls = {}
    for name, change, cause in (
        ('Boolean-status', lambda r:r.update(status=True), 'discrete actual successful status'),
        ('false-result', lambda r:r.update(stdout='PASS\n'), 'whole actual independently regenerated hypothesis qualification'),
        ('false-guard-result', lambda r:r.update(stderr='PASS\n'), 'complete actual unchanged RAM guard result'),
        ('borrowed-command', lambda r:r['command'].append('borrowed'), 'exact actual source-only hypothesis invocation'),
        ('borrowed-instrument', lambda r:r['instruments'][str(CHECKS / 'verify_hypotheses.py')].update(bytes=0), 'complete actual hypothesis instrument identity'),
        ('omitted-instrument', lambda r:r['instruments'].pop('scripts/run_with_ram_guard.sh'), 'complete actual hypothesis instrument domain'),
    ):
        bad = copy.deepcopy(reader)
        change(bad)
        try:
            check(producer, bad)
        except ValueError as error:
            need(str(error) == cause, 'intended actual hypothesis receipt refusal: ' + name)
            controls[name] = cause
        else:
            raise ValueError('false-green actual hypothesis receipt: ' + name)
    print(json.dumps({'result': 'PASS complete actual source-only hypothesis producer/reader results', 'controls': controls}, sort_keys=True))


if __name__ == '__main__':
    main()
