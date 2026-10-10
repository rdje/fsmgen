"""Capture only the preselected source-neutral public scalar constructors."""
import subprocess
from pathlib import Path
from common import BASE, SCOPE, load, need, pin, save


def main():
    pre = load('pre-observation.json')
    need(pre['native_present'] is False and pre['scope'] == SCOPE, 'source selection predates native observation')
    for name, identity in pre['inputs'].items():
        need(pin(Path(name).read_bytes()) == identity,
             'whole selected pre-observation source epoch')
    command = ['perl', '-Iperl', str(BASE / 'native.pl')]
    result = subprocess.run(command, capture_output=True, text=True)
    save('native.json', dict(command=command, status=result.returncode,
         stdout=result.stdout, stderr=result.stderr,
         inputs={str(BASE / name):pin((BASE / name).read_bytes()) for name in ('native.pl','plan.json')}))
    need(result.returncode == 0 and not result.stderr, 'actual complete public native scalar capture')
    print('PASS preselected complete public scalar constructor capture; original execution is not recaptured.')


if __name__ == '__main__':
    main()
