#!/usr/bin/env python3
"""Read saved numeric-inference evidence; never start source or HDL execution."""
import argparse
import copy
import gzip
import hashlib
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
RECEIPT = Path(__file__).with_name('receipt.json.gz')


def digest(text):
    return hashlib.sha256(text.encode()).hexdigest()


def verify(record, current=False):
    assert record['kind'] == 'literal_numeric_inference_20261030'
    for group in ('artifacts', 'producers'):
        for name, value in record[group].items():
            assert not Path(name).is_absolute() and '..' not in Path(name).parts
            assert digest(value['text']) == value['sha256']
            if current and group == 'producers':
                assert digest((ROOT / name).read_text()) == value['sha256'], name
    a = {key: value['text'] for key, value in record['artifacts'].items()}
    inner = 'intermediate_or_A_B_1'
    parent = 'intermediate_xor_intermediate_or_A_B_1_C_2'
    for name, child, outer in [('fixed', 32, 32), ('explicit', 9, 16)]:
        assert f'  wire [{child-1}:0] {inner};' in a[name + '.sv']
        assert f'  wire [{outer-1}:0] {parent};' in a[name + '.sv']
        assert f'  assign {parent} = {inner} ^ C;' in a[name + '.sv']
        assert f"Resolved width {outer} for '{parent}' via source_literal_intent" in a[name + '.trace']
        assert 256 & ((1 << outer) - 1) == 256
    assert 'disagrees with observed source width or signedness' in a['mutable.log']
    statuses = json.loads(a['native.json'])
    assert {key: value['status'] for key, value in statuses.items()} == {'fixed': 0, 'explicit': 0, 'mutable': 1}
    assert all(type(value['status']) is int for value in statuses.values())
    assert 'All tests successful.' in a['focused.log'] and 'Files=3, Tests=14' in a['focused.log']
    assert 'All tests successful.' in a['final-focused.log']
    assert 'not ok 1 - actual fixed helpers' in a['final-predecessor.log']
    assert 'not ok' in a['final-without-target-barrier.log']
    assert '- target constraint added at the last source recheck withholds' in a['final-without-target-barrier.log']
    base = 'perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/'
    for module in ('SourceLiteralWidthSupport.pm', 'IntermediateSignalWidthSupport.pm'):
        for label, log in [('predecessor', 'final-predecessor.log'), ('without-target-barrier', 'final-without-target-barrier.log')]:
            path = label + '/' + base + module
            assert path in a
            assert '.artifacts/literal-numeric-inference/' + path in a[log]
    assert 'no HDL execution' in record['scope']


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--current', action='store_true', help='check named producer identities, not future behavior')
    parser.add_argument('--qualify', action='store_true', help='reject hostile saved products')
    args = parser.parse_args()
    record = json.loads(gzip.decompress(RECEIPT.read_bytes()))
    verify(record, args.current)
    if args.qualify:
        for key, old, new in [('fixed.sv', 'wire [31:0] intermediate_xor_', 'wire [7:0] intermediate_xor_'),
                              ('explicit.sv', 'wire [8:0] intermediate_or_', 'wire [31:0] intermediate_or_'),
                              ('mutable.log', 'disagrees with observed source width or signedness', 'accepted')]:
            changed = copy.deepcopy(record)
            value = changed['artifacts'][key]
            assert old in value['text']
            value['text'] = value['text'].replace(old, new)
            value['sha256'] = digest(value['text'])
            try:
                verify(changed)
            except AssertionError:
                continue
            raise AssertionError('hostile saved product accepted: ' + key)
        print('narrowed parent, widened explicit floor and erased refusal controls rejected')
    print('saved numeric/source/CLI and independent mask checks pass; no HDL or final-declaration qualification')


if __name__ == '__main__':
    main()
