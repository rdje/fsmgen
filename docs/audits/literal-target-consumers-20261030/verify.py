#!/usr/bin/env python3
"""Verify a captured target-consumer diagnosis; no CLI/HDL run is started."""
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
    assert record['schema'] == 'fsmgen.literal_target_consumers.v1'
    assert digest(record['card_before']['text']) == record['card_before']['sha256']
    for path, source in record['sources'].items():
        assert not Path(path).is_absolute() and '..' not in Path(path).parts
        assert digest(source['text']) == source['sha256']
        if current:
            assert (ROOT / path).read_bytes() == source['text'].encode(), path
    for path, artifact in record['artifacts'].items():
        assert not Path(path).is_absolute() and '..' not in Path(path).parts
        assert digest(artifact['text']) == artifact['sha256'], path
    products = json.loads(record['artifacts']['source-products.json']['text'])
    assert set(products) == {'fixed-nested', 'mutable-direct', 'fixed-explicit'}
    inner = 'intermediate_or_A_B_1'
    parent = 'intermediate_xor_intermediate_or_A_B_1_C_2'
    for name, widths in [('fixed-nested', (1, 1)), ('fixed-explicit', (9, 9))]:
        case = products[name]
        assert set(case['signals']) == {inner, parent}
        assert case['source'] == record['artifacts'][name + '.fsm']['text']
        for signal, width in zip((inner, parent), widths):
            observed = case['signals'][signal]
            assert type(observed['width']) is int and observed['width'] == width
            assert observed['policy']['kind'] == 'source_literal_operand_max'
            expected = 9 if name == 'fixed-explicit' else None
            assert observed['policy']['selected_width'] == expected
    direct = products['mutable-direct']
    assert direct['source'] == record['artifacts']['mutable-direct.fsm']['text']
    assert set(direct['signals']) == {'intermediate_and_A_B_1'}
    assert direct['signals']['intermediate_and_A_B_1']['policy']['selected_width'] is None
    fixed = record['artifacts']['fixed-nested.sv']['text']
    explicit = record['artifacts']['fixed-explicit.sv']['text']
    assert '  wire [31:0] ' + inner + ';' in fixed
    assert '  wire [7:0] ' + parent + ';' in fixed
    assert '  assign ' + inner + ' = A | B | 256;' in fixed
    assert '  assign ' + parent + ' = ' + inner + ' ^ C;' in fixed
    assert '  wire [8:0] ' + inner + ';' in explicit
    assert '  wire [8:0] ' + parent + ';' in explicit
    assert ((0 | 0 | 256) ^ 0) != 0
    assert 256 & ((1 << 8) - 1) == 0
    assert 256 & ((1 << 9) - 1) == 256
    trace = record['artifacts']['fixed-nested.trace']['text']
    assert "Resolved width 8 for '" + parent + "' via defining_ast" in trace
    assert "Resolved width 32 for '" + inner + "' via defining_ast" in trace
    assert 'disagrees with observed source width or signedness' in record['artifacts']['mutable-direct.log']['text']
    assert record['exit_statuses'] == {'fixed-nested': 0, 'fixed-explicit': 0, 'mutable-direct': 1, 'source-probe': 0}
    return products


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--current', action='store_true', help='require the selected producer identities, not a complete current behavior watcher')
    parser.add_argument('--qualify', action='store_true', help='reject hostile saved evidence')
    args = parser.parse_args()
    record = json.loads(gzip.decompress(RECEIPT.read_bytes()))
    products = verify(record, args.current)
    if args.qualify:
        controls = []
        changed = copy.deepcopy(record)
        products = copy.deepcopy(products)
        products['fixed-nested']['signals']['intermediate_or_A_B_1']['width'] = True
        text = json.dumps(products, sort_keys=True)
        changed['artifacts']['source-products.json'].update(text=text, sha256=digest(text))
        controls.append(changed)
        changed = copy.deepcopy(record)
        artifact = changed['artifacts']['fixed-nested.sv']
        artifact['text'] = artifact['text'].replace('wire [7:0] intermediate_xor_', 'wire [31:0] intermediate_xor_')
        artifact['sha256'] = digest(artifact['text'])
        controls.append(changed)
        changed = copy.deepcopy(record)
        artifact = changed['artifacts']['fixed-explicit.sv']
        artifact['text'] = artifact['text'].replace('wire [8:0] intermediate_xor_', 'wire [7:0] intermediate_xor_')
        artifact['sha256'] = digest(artifact['text'])
        controls.append(changed)
        for changed in controls:
            try:
                verify(changed)
            except AssertionError:
                continue
            raise AssertionError('hostile saved evidence accepted')
        print('hostile Boolean-width, widened-parent and narrowed-explicit artifacts rejected')
    print('source-qualified captured CLI/trace, explicit floor and independent mask algebra verified; no HDL runtime or unconditional current watcher')


if __name__ == '__main__':
    main()
