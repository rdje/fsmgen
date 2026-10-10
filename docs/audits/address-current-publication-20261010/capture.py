"""Retain complete actual current inputs and their original qualification epoch."""
import hashlib
import json
import sys
from pathlib import Path

sys.path.insert(0, str(Path('scripts').resolve()))
import check_record_value_publication as current

BASE = Path('docs/audits/address-current-publication-20261010')


def main():
    destination = BASE / 'current-input-final.json'
    if destination.exists():
        raise ValueError('refuse to overwrite retained actual current inputs')
    prior = current.historical()
    canonical = current.sources()
    record = current.current_input(prior, canonical)
    current.check(record, canonical, prior, current.authority(prior))
    qualification = current.address_fact.authenticate()
    if canonical != current.sources():
        raise ValueError('complete current source epoch conserves during capture')
    programmes = ['scripts/check_record_value_publication.py', 'scripts/record_value_coordinate_fact.py', 'scripts/record_value_address_fact.py',
                  't/python/test_record_value_current_publication.py', str(BASE / 'capture.py')]
    pins = {p: current.identity(Path(p).read_bytes()) for p in programmes}
    product = {'record': record, 'qualification': qualification, 'programmes': pins,
               'role': 'actual complete current source/query input; no original recapture'}
    destination.write_text(json.dumps(product, sort_keys=True, indent=2) + '\n')
    print('PASS retained complete actual current source/query inputs, programme epoch and original qualification authentication.')


if __name__ == '__main__':
    main()
