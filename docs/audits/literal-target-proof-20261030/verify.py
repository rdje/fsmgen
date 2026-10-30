#!/usr/bin/env python3
"""Read saved target proof and counterfactuals; never run source or HDL."""
import argparse
import base64
import copy
import gzip
import hashlib
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]


def unpack(value):
    raw = base64.b64decode(value['data_base64'], validate=True)
    assert type(value['bytes']) is int and len(raw) == value['bytes']
    assert hashlib.sha256(raw).hexdigest() == value['sha256']
    return raw


def verify(record, current=False):
    assert record['kind'] == 'literal_target_proof_20261030'
    expected = {'red': 1, 'first-implementation': 1, 'second-implementation': 1,
                'focused': 0, 'no-target-fence': 1, 'book': 0, 'final-focused': 0}
    assert record['runs'] == expected
    assert all(type(value) is int for value in record['runs'].values())
    for family in ('producers', 'artifacts'):
        for path, value in record[family].items():
            assert not Path(path).is_absolute() and '..' not in Path(path).parts
            raw = unpack(value)
            if current and family == 'producers':
                assert (ROOT / path).read_bytes() == raw, path
    original = unpack(record['original_source'])
    assert b'sub prepare_targets {' not in original
    logs = {path: unpack(value).decode() for path, value in record['artifacts'].items() if path.endswith('.log')}
    assert "Failed test 'complete literal selected target proof exists'" in logs['red.log']
    assert 'All tests successful.' in logs['focused.log'] and 'Files=2, Tests=6' in logs['focused.log']
    assert 'All tests successful.' in logs['final-focused.log'] and 'Files=1, Tests=3' in logs['final-focused.log']
    assert 'loaded=.artifacts/literal-target-proof-20261030/no-target-fence/' in logs['no-target-fence.log']
    variant = 'no-target-fence/FSM/HDL/FlattenedDT/Backend/SystemVerilog/SourceLiteralWidthSupport.pm'
    assert record['artifacts'][variant]['sha256'] in logs['no-target-fence.log']
    assert logs['no-target-fence.log'].count("Failed test 'late mutation withholds complete physical proof'") == 3
    assert 'Result: FAIL' in logs['first-implementation.log']
    assert 'Result: FAIL' in logs['second-implementation.log']
    assert 'disagrees with observed source width or signedness' in logs['probe-corrected.log']
    assert record['scope'].startswith('Private complete literal target-record proof;')
    assert record['gaps']


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--current', action='store_true', help='check named current producer identities only')
    parser.add_argument('--qualify', action='store_true', help='reject altered status or removed counterfactual failures')
    args = parser.parse_args()
    record = json.loads(gzip.decompress(Path(__file__).with_name('receipt.json.gz').read_bytes()))
    verify(record, args.current)
    if args.qualify:
        for change in ('status', 'boolean', 'counterfactual'):
            bad = copy.deepcopy(record)
            if change == 'status':
                bad['runs']['no-target-fence'] = 0
            elif change == 'boolean':
                bad['runs']['final-focused'] = False
            else:
                value = bad['artifacts']['no-target-fence.log']
                raw = unpack(value).replace(b"Failed test 'late mutation", b"Erased test 'late mutation")
                value.update(data_base64=base64.b64encode(raw).decode(), bytes=len(raw), sha256=hashlib.sha256(raw).hexdigest())
            try:
                verify(bad)
            except AssertionError:
                continue
            raise AssertionError('hostile saved evidence accepted: ' + change)
        print('altered-status, Boolean-status and rehashed erased-counterfactual controls rejected')
    print('saved literal-target proof/source/refusal evidence authenticated; no source or HDL execution')


if __name__ == '__main__':
    main()
