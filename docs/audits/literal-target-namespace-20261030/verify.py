#!/usr/bin/env python3
"""Read saved namespace extraction evidence; never start source or HDL execution."""
import argparse
import copy
import gzip
import hashlib
import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
RECEIPT = Path(__file__).with_name('receipt.json.gz')


def verify(record, current=False):
    assert record['kind'] == 'literal_target_namespace_20261030'
    assert set(record['runs']) == {'red', 'focused', 'final-focused'}
    for label, status in (('red', 1), ('focused', 0), ('final-focused', 0)):
        assert type(record['runs'][label]) is int and record['runs'][label] == status
    for family in ('producers', 'artifacts'):
        for path, value in record[family].items():
            assert not Path(path).is_absolute() and '..' not in Path(path).parts
            assert hashlib.sha256(value['text'].encode()).hexdigest() == value['sha256']
            if current and family == 'producers':
                assert hashlib.sha256((ROOT / path).read_bytes()).hexdigest() == value['sha256'], path
    logs = record['artifacts']
    assert "Failed test 'separate canonical target namespace preparation exists'" in logs['red.log']['text']
    assert 'Global symbol "%claimed"' in logs['syntax-first.log']['text']
    assert 'All tests successful.' in logs['final-focused.log']['text']
    assert 'Files=2, Tests=9' in logs['final-focused.log']['text']
    assert record['scope'].startswith('Structural namespace only;')
    assert record['syntax_status_gap']
    consolidation = record['card_consolidation']
    for value in consolidation.values():
        if not isinstance(value, dict):
            continue
        assert hashlib.sha256(value['text'].encode()).hexdigest() == value['sha256']
    before = consolidation['before']['text']
    after = consolidation['after']['text']
    questions = lambda text: re.search(r'answers:\n(.*?)\ndate:', text, re.S).group(1)
    assert questions(before) == questions(after)
    commands = [line for line in before.splitlines()
                if line.startswith(('reverify:', '`prove ', '`python3 '))]
    assert all(line in after.splitlines() for line in commands)
    assert consolidation['routed_paragraph']['text'] in consolidation['canonical_book']['text']
    assert 'transition debt exceeded its owned allowance' in logs['first-hook-refusal.log']['text']


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--current', action='store_true', help='check only named current producer identities')
    parser.add_argument('--qualify', action='store_true', help='reject loss of original question or canonical paragraph')
    args = parser.parse_args()
    record = json.loads(gzip.decompress(RECEIPT.read_bytes()))
    verify(record, args.current)
    if args.qualify:
        for key in ('after', 'canonical_book'):
            changed = copy.deepcopy(record)
            value = changed['card_consolidation'][key]
            if key == 'after':
                value['text'] = value['text'].replace('where do direct symbolic', 'lost original question', 1)
            else:
                value['text'] = value['text'].replace(changed['card_consolidation']['routed_paragraph']['text'], '', 1)
            value['sha256'] = hashlib.sha256(value['text'].encode()).hexdigest()
            try:
                verify(changed)
            except AssertionError:
                continue
            raise AssertionError('lost original question or canonical paragraph accepted')
        print('original-question and canonical-paragraph loss controls rejected')
    print('saved namespace/source/refusal evidence authenticated; no source or HDL execution')


if __name__ == '__main__':
    main()
