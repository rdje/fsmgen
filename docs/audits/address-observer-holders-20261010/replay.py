"""Fresh source-prefix witnesses through the unchanged public test interface."""
import hashlib
import json
import subprocess
from pathlib import Path

BASE = Path('docs/audits/address-observer-holders-20261010')


def pin(path):
    raw = path.read_bytes()
    return {'bytes': len(raw), 'sha256': hashlib.sha256(raw).hexdigest()}


def main():
    receipt = BASE / 'replay.json'
    if receipt.exists():
        raise ValueError('one retained fresh replay receipt; never overwrite')
    historical = json.loads(Path('docs/audits/record-value-original-candidate-20261004/execution.json').read_bytes())
    expected = {row['mode']: row['status'] for row in historical['modes']}
    outcomes = json.loads((BASE / 'first-replay.json.txt').read_bytes())
    first_programme = pin(BASE / 'first-replay.py.txt')
    if [row['mode'] for row in outcomes] != ['ordinary', 'storable']:
        raise ValueError('whole first runner outcome population')
    for row in outcomes:
        if row['status'] != expected[row['mode']] or row['programme'] != pin(BASE / 'probe.pl'):
            raise ValueError('actual historical mode status; do not promote nonzero')
        if row['product'] != pin(BASE / (row['mode'] + '.json')):
            raise ValueError('whole first source prefix witness custody')
    for mode in ('ordinary', 'storable', 'controls'):
        target = BASE / (mode + '.json')
        if target.exists():
            continue
        command = ['perl', '-Iperl', str(BASE / 'probe.pl'), mode, str(target)]
        result = subprocess.run(command, capture_output=True, text=True)
        outcome = {'mode': mode, 'command': command, 'status': result.returncode,
                   'stdout': result.stdout, 'stderr': result.stderr,
                   'programme': pin(BASE / 'probe.pl')}
        if target.exists():
            outcome['product'] = pin(target)
        outcomes.append(outcome)
        receipt.write_text(json.dumps(outcomes, sort_keys=True, indent=2) + '\n')
        if result.returncode != expected[mode]:
            raise ValueError('fresh source prefix replay failed: ' + mode)
    receipt.write_text(json.dumps({'modes': outcomes, 'first_programme': first_programme,
        'scope': 'Nonzero historical provider/control outcomes remain actual non-successes; source caller membership alone qualifies.'},
        sort_keys=True, indent=2) + '\n')
    print('PASS fresh complete caller-bearing headers and refusal prefix snapshots; every historical nonzero status conserved.')


if __name__ == '__main__':
    main()
