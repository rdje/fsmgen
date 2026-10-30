#!/usr/bin/env python3
"""Read saved selected-expression evidence without starting source or HDL execution."""
import argparse
import copy
import gzip
import hashlib
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
RECEIPT = Path(__file__).with_name('receipt.json.gz')


def verify(record, current=False):
    assert record['kind'] == 'literal_selected_expressions_20261030'
    expected = {'guard-refusal': 2, 'red': 1, 'first': 1, 'focused': 0,
                'final-focused': 0, 'final-guard': 0, 'without-fresh-render': 1, 'without-target-barrier': 1}
    assert set(record['runs']) == set(expected)
    for label, status in expected.items():
        assert type(record['runs'][label]['status']) is int
        assert record['runs'][label]['status'] == status
    for family in ('producers', 'artifacts'):
        for path, artifact in record[family].items():
            assert not Path(path).is_absolute() and '..' not in Path(path).parts
            assert hashlib.sha256(artifact['text'].encode()).hexdigest() == artifact['sha256']
            if current and family == 'producers':
                assert hashlib.sha256((ROOT / path).read_bytes()).hexdigest() == artifact['sha256'], path
    artifacts = record['artifacts']
    assert 'session inspection is unavailable' in artifacts['guard-refusal.log']['text']
    assert "Failed test 'actual literal selected expression preparation exists'" in artifacts['red.log']['text']
    assert 'Odd name/value argument' in artifacts['first.log']['text']
    assert 'All tests successful.' in artifacts['final-focused.log']['text']
    assert 'Files=2, Tests=6' in artifacts['final-focused.log']['text']
    assert 'All tests successful.' in artifacts['final-guard.log']['text']
    assert 'Files=1, Tests=3' in artifacts['final-guard.log']['text']
    for label, message in (
        ('without-fresh-render', 'fresh typed rendering refuses matching cached-only selection'),
        ('without-target-barrier', 'late earlier child cache or source mutation withholds the selection'),
    ):
        log = artifacts[label + '.log']['text']
        module = label + '/perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/SourceLiteralWidthSupport.pm'
        assert module in artifacts
        assert 'loaded producer=.artifacts/literal-selected-expressions-20261030/' + module in log
        assert "Failed test '" + message + "'" in log
    assert 'no physical declaration/event or live emitted-ledger proof' in record['scope']
    assert record['initial_implementation_gap']


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--current', action='store_true', help='check named producer identities only')
    parser.add_argument('--qualify', action='store_true', help='reject hostile saved success records')
    args = parser.parse_args()
    record = json.loads(gzip.decompress(RECEIPT.read_bytes()))
    verify(record, args.current)
    if args.qualify:
        for status in (0, True):
            changed = copy.deepcopy(record)
            changed['runs']['without-target-barrier']['status'] = status
            try:
                verify(changed)
            except AssertionError:
                continue
            raise AssertionError('hostile target-barrier status accepted')
        print('false-success and Boolean target-barrier controls rejected')
    print('saved selected-expression sources and observed controls authenticated; no source or HDL execution')


if __name__ == '__main__':
    main()
