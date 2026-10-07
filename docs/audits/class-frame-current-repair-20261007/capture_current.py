"""Retain a fresh whole current/native execution and its stable input epoch."""
import json
import subprocess
import sys
from pathlib import Path

sys.path.insert(0, 'scripts')
import check_record_value_publication as current

BASE = Path('docs/audits/class-frame-current-repair-20261007')
BUILD = '.artifacts/class-frame-current-book'


def main():
    products = [BASE / name for name in ('current-input.json', 'current-actual.json', 'current-checker.py.txt', 'native-input.html')]
    current.require(not any(p.exists() for p in products), 'fresh current capture cannot overwrite evidence')
    prior = current.historical()
    canonical = current.sources()
    record = current.current_input(prior, canonical)
    programme = Path('scripts/check_record_value_publication.py').read_bytes()
    command = ['python3', '-B', 'scripts/check_record_value_publication.py', '--build', BUILD]
    execution = subprocess.run(command, text=True, capture_output=True)
    products[0].write_text(json.dumps(record, sort_keys=True, indent=2) + '\n')
    products[2].write_bytes(programme)
    products[1].write_text(json.dumps(dict(command=command, status=execution.returncode,
        stdout=execution.stdout, stderr=execution.stderr, input_identity=current.identity(products[0].read_bytes()),
        programme=current.identity(programme)), sort_keys=True, indent=2) + '\n')
    current.require(execution.returncode == 0 and execution.stdout == current.SUCCESS and execution.stderr == '',
                    'whole actual current/native command status and streams')
    current.require(canonical == current.sources() and current.same(record, current.current_input(prior, canonical))
        and Path('scripts/check_record_value_publication.py').read_bytes() == programme,
        'complete current source/query/input/programme epoch conserved across actual execution')
    native = Path(BUILD) / (prior['CHAPTER'].stem + '.html')
    products[3].write_bytes(native.read_bytes())
    current.check_native(products[3].read_text(), prior)
    print('PASS retained complete actual current/native execution and stable source/query/programme epoch; no original recapture.')


if __name__ == '__main__':
    main()
