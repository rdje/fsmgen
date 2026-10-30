#!/usr/bin/env python3
"""Read saved literal generic range evidence; never start source or HDL execution."""
import argparse
import copy
import gzip
import hashlib
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
RECEIPT = Path(__file__).with_name('receipt.json.gz')


def verify(record, current=False):
    assert record['kind'] == 'literal_generic_range_20261030'
    for path, expected in record['retained_first'].items():
        assert hashlib.sha256(RECEIPT.with_name(path).read_bytes()).hexdigest() == expected
    for family in ('producers', 'artifacts'):
        for path, value in record[family].items():
            assert not Path(path).is_absolute() and '..' not in Path(path).parts
            assert hashlib.sha256(value['text'].encode()).hexdigest() == value['sha256']
            if current and family == 'producers':
                assert hashlib.sha256((ROOT / path).read_bytes()).hexdigest() == value['sha256'], path
    expected = {'focused': 0, 'without-source-barrier': 1, 'selected-literal-floor': 1}
    assert set(record['runs']) == set(expected)
    for label, status in expected.items():
        assert type(record['runs'][label]['status']) is int
        assert record['runs'][label]['status'] == status
    artifacts = record['artifacts']
    assert 'All tests successful.' in artifacts['focused.log']['text']
    assert 'Files=2, Tests=7' in artifacts['focused.log']['text']
    for label, message in (
        ('without-source-barrier', 'late parameter change after the numeric recheck withholds'),
        ('selected-literal-floor', 'mutable leaves, fixed leaf and literal floor remain independent and ordered'),
    ):
        path = label + '/perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/SourceLiteralWidthSupport.pm'
        log = artifacts[label + '.log']['text']
        assert path in artifacts
        assert 'loaded producer=.artifacts/literal-generic-range/' + path in log
        assert "Failed test '" + message + "'" in log
    assert "Failed test 'literal generic range preparation exists'" in artifacts['red.log']['text']
    assert "Failed test 'changed source namespace or target cannot reuse saved range'" in artifacts['namespace-copy-red.log']['text']
    assert 'source_state_digest' in record['source_currentness_repair']
    assert 'no selected declaration/expression ledger' in record['scope']


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--current', action='store_true', help='check named producer identities only')
    parser.add_argument('--qualify', action='store_true', help='reject hostile saved result records')
    args = parser.parse_args()
    record = json.loads(gzip.decompress(RECEIPT.read_bytes()))
    verify(record, args.current)
    if args.qualify:
        for value in (0, True):
            changed = copy.deepcopy(record)
            changed['runs']['without-source-barrier']['status'] = value
            try:
                verify(changed)
            except AssertionError:
                continue
            raise AssertionError('hostile source-barrier status accepted')
        print('false-success and Boolean source-barrier status controls rejected')
    print('saved generic range/source/variant evidence authenticated; no source or HDL execution')


if __name__ == '__main__':
    main()
