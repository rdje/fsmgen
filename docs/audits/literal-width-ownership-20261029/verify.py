#!/usr/bin/env python3
"""Authenticate the revision-bound literal ownership diagnosis; this is not a fix gate."""
import argparse
import copy
import gzip
import hashlib
import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
RECEIPT = Path(__file__).with_name('receipt.json.gz')


def encoded(value):
    return json.dumps(value, sort_keys=True, separators=(',', ':'))


def verify(record, current=False):
    assert record['schema'] == 'fsmgen.literal_width_ownership.v1'
    for path, source in record['sources'].items():
        assert not Path(path).is_absolute() and '..' not in Path(path).parts
        raw = source['text'].encode()
        assert hashlib.sha256(raw).hexdigest() == source['sha256']
        if current:
            assert (ROOT / path).read_bytes() == raw, 'current producer changed: ' + path
    for path, artifact in record['files'].items():
        assert hashlib.sha256(artifact['text'].encode()).hexdigest() == artifact['sha256'], path
    products = json.loads(record['files']['products.json']['text'])
    for name, loaded in products['loaded'].items():
        assert loaded['path'] == 'perl/' + name
        assert loaded['sha256'] == record['sources'][loaded['path']]['sha256']
    cases = products['cases']
    expected = {(bits, mutable, kind) for bits in (1, 8) for mutable in (0, 1)
                for kind in ('direct', 'nested', 'explicit')}
    seen = set()
    expressions = {'direct': '(& A B 3)', 'nested': '(^ (| A B 256) C)', 'explicit': "(& A B 8'd3)"}
    for case in cases:
        assert type(case['bits']) is int and type(case['mutable']) is int
        key = case['bits'], case['mutable'], case['kind']
        assert key in expected and key not in seen
        seen.add(key)
        bits, mutable, kind = key
        params = f'(+params (W {bits}))' if mutable else ''
        slot = '(param W)' if mutable else str(bits)
        source = (f'(?fsm:literal_ownership {params} (+size (A {slot}) (B {slot}) (C {slot}) (DATA 1) (OTHER 1))'
                  f' (idle (<{expressions[kind]} (= (DATA 1)) (= (OTHER 1))) (-> idle)))')
        assert case['source'] == source
        before = case['source_before']
        after = case['source_after_matching_width_write']
        inner = 'intermediate_or_A_B_1' if kind == 'nested' else 'intermediate_and_A_B_1'
        assert before[inner]['width'] == (8 if kind == 'explicit' else 1)
        assert before[inner]['exact_width'] == (8 if kind == 'explicit' else None)
        assert before[inner]['allocation'] is None and before[inner]['tree_allocation'] is None
        if kind == 'direct':
            assert encoded(before) == encoded(after), 'untracked placeholder can distinguish the matching write'
            assert before[inner]['tracked_revision'] is False
        if kind == 'nested':
            parent = 'intermediate_xor_intermediate_or_A_B_1_C_2'
            assert before[parent]['width'] == before[parent]['exact_width'] == bits
            assert before[parent]['allocation'] == {'kind': 'binary_operand_max', 'operator': '^',
                'selected_width': bits, 'source_names': [inner, 'C']}
            assert after[parent]['allocation'] is None
            assert after[parent]['revision'] > before[parent]['revision']
        if mutable and kind != 'explicit':
            assert case['plain_hdl'] is None
            diagnostic = 'disagrees with observed source width' if kind == 'direct' else 'actual current completed source allocation'
            assert diagnostic in case['plain_error']
        else:
            assert case['plain_error'] == '' and case['plain_hdl']
        if not mutable and kind == 'nested':
            hdl = case['plain_hdl']
            assert f'  wire [31:0] {inner};' in hdl
            declaration = f'  wire {parent};' if bits == 1 else f'  wire [7:0] {parent};'
            assert declaration in hdl
            assert f'  assign {inner} = A | B | 256;' in hdl
            assert f'  assign {parent} = {inner} ^ C;' in hdl
            # Independent literal algebra at A=B=C=0, followed by the actual
            # emitted destination width. This is text semantics, not HDL execution.
            assert ((0 | 0 | 256) ^ 0) != 0
            assert (256 & ((1 << bits) - 1)) == 0
            assert case['hdl'] is None and 'exact declared operand maximum' in case['error']
            assert case['snapshot'] is None and 'completed declaration generation' in case['snapshot_error']
    assert seen == expected
    trace = record['files']['nested8.trace']['text']
    assert "Resolved width 8 for 'intermediate_xor_intermediate_or_A_B_1_C_2' via native_signal_metadata" in trace
    assert "Resolved width 32 for 'intermediate_or_A_B_1' via defining_ast" in trace
    cli = record['files']['nested8.sv']['text']
    fixed = next(c for c in cases if (c['bits'], c['mutable'], c['kind']) == (8, 0, 'nested'))
    clean = lambda text: re.sub(r'^// Date: [^\r\n]+$', '// Date: <generated>', text, flags=re.M)
    assert clean(cli) == clean(fixed['plain_hdl']), 'strict CLI and native artifacts diverge'
    return products


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--current', action='store_true', help='also require current producer byte identity')
    parser.add_argument('--qualify', action='store_true', help='reject hostile saved products')
    args = parser.parse_args()
    record = json.loads(gzip.decompress(RECEIPT.read_bytes()))
    verify(record, args.current)
    if args.qualify:
        products = json.loads(record['files']['products.json']['text'])
        bad_products = []
        bad = copy.deepcopy(products)
        bad['cases'][0]['mutable'] = False
        bad_products.append(bad)
        bad = copy.deepcopy(products)
        nested = next(c for c in bad['cases'] if c['kind'] == 'nested' and not c['mutable'])
        nested['plain_hdl'] = nested['plain_hdl'].replace(
            'wire intermediate_xor_intermediate_or_A_B_1_C_2;', 'wire [31:0] intermediate_xor_intermediate_or_A_B_1_C_2;')
        bad_products.append(bad)
        bad = copy.deepcopy(products)
        bad['cases'][0]['source'] = ''
        bad_products.append(bad)
        for bad in bad_products:
            changed = copy.deepcopy(record)
            text = encoded(bad)
            changed['files']['products.json'] = {'text': text, 'sha256': hashlib.sha256(text.encode()).hexdigest()}
            try:
                verify(changed)
            except AssertionError:
                continue
            raise AssertionError('hostile saved product accepted')
        print('hostile Boolean-kind, widened-parent and consumed-input products rejected')
    print('revision-bound source ownership, native/capture separation, nested truncation and strict CLI trace diagnosis verified')


if __name__ == '__main__':
    main()
