"""Retain read-only host samples using the documented occupied-capacity formula."""
from datetime import datetime, timezone
import json
from pathlib import Path
import re
import subprocess

BASE = Path('docs/audits/coordinate-original-hostile-independent-checks-20261009')


def run(command):
    result = subprocess.run(command, capture_output=True, text=True)
    if result.returncode != 0 or result.stderr:
        raise ValueError('complete read-only host sample: ' + repr(command))
    return {'command': command, 'status': result.returncode,
            'stdout': result.stdout, 'stderr': result.stderr}


def main():
    total = run(['sysctl', '-n', 'hw.memsize'])
    sample = run(['vm_stat'])
    page_size = int(re.search(r'page size of (\d+) bytes', sample['stdout'])[1])
    names = ['Pages active', 'Pages inactive', 'Pages speculative', 'Pages wired down',
             'Pages occupied by compressor', 'Pages purgeable', 'File-backed pages']
    values = [int(re.search(r'^' + re.escape(name) + r':\s+(\d+)\.$',
                           sample['stdout'], re.M)[1]) for name in names]
    occupied = (sum(values[:5]) - sum(values[5:])) * page_size
    capacity = int(total['stdout'])
    if not 0 <= occupied <= capacity:
        raise ValueError('valid occupied-capacity sample')
    row = {'captured_utc': datetime.now(timezone.utc).isoformat(),
           'total': total, 'vm_stat': sample, 'occupied_percent': occupied * 100 / capacity,
           'scope': 'Dated occupied capacity only; no attribution of pressure or future-headroom guarantee.'}
    with (BASE / 'headroom.jsonl').open('a') as stream:
        stream.write(json.dumps(row, sort_keys=True) + '\n')
    print(json.dumps(row, sort_keys=True))


if __name__ == '__main__':
    main()
