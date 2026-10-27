#!/usr/bin/env python3
"""Verify saved actual auxiliary-origin observations without parsing new source."""
import argparse
import copy
import gzip
import json
from pathlib import Path

OPS = ['<-=', '<=-', '<=+']
PAIRS = {(8, 8): 8, (16, 8): 16, (8, 16): 16}


def require(test, message):
    if not test:
        raise ValueError(message)


def verify(rows):
    require(len(rows) == 33, 'complete bounded case inventory')
    expected = {(op, 'pair', w, x) for op in OPS for w, x in PAIRS}
    expected |= {(op, 'slot:' + slot, w, 8) for op in OPS for slot in ['(param X)', '8', ''] for w in [1, 8]}
    expected |= {(op, mode, None, None) for op in OPS for mode in ['late', 'type']}
    actual = set()
    paired = {}
    for row in rows:
        op = row['operator']
        require(op in OPS and row['success'] == 1 and row['error'] == '', 'actual source success')
        require(row['caller_before'] == row['caller_after'], 'complete frontend caller conservation')
        aux = 'next_data' if op == '<-=' else 'data_r'
        mode = row.get('mode')
        key = (op, mode, None, None) if mode else (op, 'slot:' + row['slot'] if 'slot' in row else 'pair', row['W'], row['X'])
        require(key not in actual, 'unique case identity')
        actual.add(key)
        data, output = row['signals']['data'], row['signals'][aux]
        require(output['binding'] is None, 'auxiliary publication is not implemented in this epoch')
        if mode == 'type':
            require(data['width'] == output['width'] == 8, 'actual named-type width')
            require(data['source'] is None and output['source'] is None and data['binding'] is None, 'named-type nonrelationship')
            continue
        w = 8 if mode == 'late' else row['W']
        if mode:
            width = 8
        elif 'slot' not in row:
            width = PAIRS[(row['W'], row['X'])]
            require('(' + aux + ' (param X))' in row['source_text'], 'actual explicit auxiliary X declaration')
        else:
            width = w if row['slot'] == '' else 8
            paired[(op, w, row['slot'])] = row['signals']
        require(data['width'] == w and output['width'] == width, 'independently expected numeric geometry')
        origin = {'signal': 'data', 'expression': ['param', ['W']], 'resolved_width': w}
        require(data['source'] == origin and output['source'] == origin, 'actual copied legacy origin discards explicit auxiliary slot')
        if mode == 'late':
            require(data['binding'] is None, 'unscoped direct sizing cannot infer lexical ownership')
        else:
            require(data['binding']['scope']['owner'] == ('aux_slot' if 'slot' in row else 'aux_origin'), 'actual primary lexical scope')
            require(data['binding']['observations'][0]['parameter'] == 'W', 'actual primary parameter identity')
    require(actual == expected, 'literal expected case set')
    for op in OPS:
        for w in [1, 8]:
            require(paired[(op, w, '(param X)')] == paired[(op, w, '8')], 'single-slot equal-default provenance-loss control')
    return len(rows)


def self_test(rows):
    controls = [copy.deepcopy(rows[:-1])]
    wrong_width = copy.deepcopy(rows)
    wrong_width[2]['signals']['next_data']['width'] = 8
    controls.append(wrong_width)
    wrong_origin = copy.deepcopy(rows)
    wrong_origin[0]['signals']['next_data']['source']['expression'] = ['param', ['X']]
    controls.append(wrong_origin)
    false_binding = copy.deepcopy(rows)
    false_binding[0]['signals']['next_data']['binding'] = copy.deepcopy(rows[0]['signals']['data']['binding'])
    controls.append(false_binding)
    for control in controls:
        try:
            verify(control)
        except ValueError:
            continue
        raise ValueError('altered observation incorrectly accepted')
    return len(controls)


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--self-test', action='store_true')
    args = parser.parse_args()
    packet = Path(__file__).with_suffix('.json.gz')
    data = json.loads(gzip.decompress(packet.read_bytes()))
    print('auxiliary-width-origin: verified', verify(data['observations']), 'saved actual cases')
    if args.self_test:
        print('auxiliary-width-origin: rejected', self_test(data['observations']), 'altered observations')
    print('auxiliary-width-origin: explicit auxiliary constraint retention remains P1-open before propagation; no generic HDL claim')
