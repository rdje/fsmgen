#!/usr/bin/env python3
"""Authenticate saved prepared-range evidence without executing Perl or HDL."""
import argparse
import copy
import gzip
import hashlib
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
RECEIPT = Path(__file__).with_name('receipt.json.gz')


def verify(record, current=False):
    assert record['kind'] == 'prepared_width_maximum_20261030'
    for family in ('producers', 'artifacts'):
        for path, value in record[family].items():
            assert not Path(path).is_absolute() and '..' not in Path(path).parts
            assert hashlib.sha256(value['text'].encode()).hexdigest() == value['sha256']
            if current and family == 'producers':
                assert hashlib.sha256((ROOT / path).read_bytes()).hexdigest() == value['sha256'], path
    expected = {'focused': 0, 'default-pruned': 3, 'missing-observed-check': 1}
    assert set(record['runs']) == set(expected)
    for label, status in expected.items():
        assert type(record['runs'][label]['status']) is int
        assert record['runs'][label]['status'] == status
    artifacts = record['artifacts']
    assert 'All tests successful.' in artifacts['focused-final.log']['text']
    assert 'Files=2, Tests=8' in artifacts['focused-final.log']['text']
    for label in ('default-pruned', 'missing-observed-check'):
        path = label + '/perl/FSM/Backend/VerilogFamily/WidthExpressionEmitter.pm'
        log = artifacts[label + '-final.log']['text']
        assert path in artifacts
        assert 'loaded producer=.artifacts/literal-maximum-range/' + path in log
        assert 'Failed test' in log
    assert "Failed test 'prepared maximum range exists'" in artifacts['red-admitted.log']['text']
    assert 'no literal source join' in record['scope']
    def questions(text):
        return text.split('answers:\n', 1)[1].split('date:', 1)[0]
    assert questions(artifacts['prior-card.md']['text']) == questions(artifacts['consolidated-card.md']['text'])
    for key in record['card_consolidation']['duplicate_topic_keys']:
        assert key in artifacts['rejected-card.md']['text']
        assert key in artifacts['canonical-target-excerpt.md']['text']


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
            changed['runs']['default-pruned']['status'] = value
            try:
                verify(changed)
            except AssertionError:
                continue
            raise AssertionError('hostile counterfactual status accepted')
        print('false-success and Boolean counterfactual status controls rejected')
    print('saved prepared-maximum and variant evidence authenticated; no source or HDL execution')


if __name__ == '__main__':
    main()
