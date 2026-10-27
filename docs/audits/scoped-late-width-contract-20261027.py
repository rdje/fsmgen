#!/usr/bin/env python3
"""Replay saved diagnostic policies; this does not qualify a new public API."""
import copy
import gzip
import json
from pathlib import Path
import sys


def signature(entry):
    return (entry['kind'], entry['signal'], entry['expression'], entry['width'])


def verify(packet):
    rows = packet['results']
    ids = [op + '/' + slot for op in ('<-=', '<=-', '<=+')
           for slot in ('', '(param X)', '8', 'word_t')] + ['collision/8', 'collision/16']
    expected_ids = {(name, policy) for name in ids
                    for policy in ('fresh', 'seed_all', 'drop_generated')}
    assert len(rows) == len(expected_ids)
    assert {(r['id'], r['policy']) for r in rows} == expected_ids
    scope = {'kind': 'direct_module', 'owner': 'late_case'}
    public = {}
    for row in rows:
        assert not row['error']
        assert row['scope'] == scope
        assert row['caller_before'] == row['caller_after']
        assert row['size_before'] == row['size_after']
        target = row['after'][row['target']]
        record = target['requirements']
        assert record['scope'] == scope and record['width'] == target['width']
        param = lambda kind, signal, name, width: (kind, signal, ['param', [name]], width)
        policy = row['policy']
        if row['id'].startswith('collision/'):
            x = int(row['id'].split('/')[1])
            expected = []
            if policy == 'seed_all':
                expected.append(param('generated', 'data_r', 'X', x))
            if policy != 'fresh':
                expected.append(param('generated', 'data', 'W', 8))
            expected.append(param('generated', 'next_data', 'Y', 8))
            if x == 16 and policy != 'seed_all':
                expected.append(('generated', 'next_data_r', None, 16))
            assert target['width'] == x
        else:
            op, slot = row['id'].split('/', 1)
            aux = 'next_data' if op == '<-=' else 'data_r'
            expected = []
            if policy != 'fresh' and slot:
                expected.append(param('declaration', aux, 'X', 8) if slot == '(param X)'
                                else ('declaration', aux, slot, 8))
            if policy == 'seed_all':
                expected.append(('generated', 'data', None, 1))
            expected.append(param('generated', 'data', 'W', 8))
            assert target['width'] == 8
        assert [signature(e) for e in record['requirements']] == expected
        assert record['width'] == max(e['width'] for e in record['requirements'])
        for entry in record['requirements']:
            expr = entry['expression']
            capture = entry['width_capture']
            if isinstance(expr, list):
                name = expr[1][0]
                assert capture['scope'] == scope and capture['width'] == entry['width']
                assert capture['observations'] == [{
                    'lookup': 'parameter', 'kind': 'parameter', 'token': name,
                    'parameter': name, 'suffix': '',
                    'value_payload': {'kind': 'scalar', 'payload': str(entry['width'])}}]
                assert capture['binding'] == {'kind': 'reference', 'observation_index': 0,
                    'value_expression': {'kind': 'literal', 'token': str(entry['width'])}}
            else:
                assert capture is None
        eligible = len(expected) == 1 and isinstance(expected[0][2], list)
        assert (target['binding'] is not None) == eligible
        now = {n: {k: s[k] for k in ('width', 'source', 'type_name', 'type_spec')}
               for n, s in row['after'].items()}
        if row['id'] in public:
            assert public[row['id']] == now
        public[row['id']] = now
    controls = packet['controls']
    assert len(controls) == 6
    for row, mode, result in zip(controls[:3], ('scalar', 'list', 'void'), ('', [''], None)):
        assert row == {'mode': mode, 'seen': [mode], 'result': result, 'width': 8, 'aux_width': 8}
    for row in controls[3:]:
        assert row['before'] == row['after'] and row['caller_before'] == row['caller_after']
        assert row['error'].startswith('Declared width capture requires an explicit direct-module scope.')


def main():
    packet = json.loads(gzip.decompress(Path(__file__).with_suffix('.json.gz').read_bytes()))
    verify(packet)
    if '--self-test' in sys.argv:
        mutations = []
        bad = copy.deepcopy(packet); bad['results'].pop(); mutations.append(bad)
        bad = copy.deepcopy(packet); bad['results'][0]['after']['next_data']['width'] = 9; mutations.append(bad)
        bad = copy.deepcopy(packet)
        row = next(r for r in bad['results'] if r['id'] == 'collision/8' and r['policy'] == 'seed_all')
        row['after']['next_data_r']['requirements']['requirements'].pop(0); mutations.append(bad)
        bad = copy.deepcopy(packet)
        row = next(r for r in bad['results'] if r['id'] == '<-=/' and r['policy'] == 'seed_all')
        row['after']['next_data']['binding'] = {'invented': True}; mutations.append(bad)
        for bad in mutations:
            try:
                verify(bad)
            except (AssertionError, KeyError, TypeError):
                continue
            raise AssertionError('altered observation was accepted')
    print('scoped-late-width-contract: saved actual policy boundaries and rejecting controls pass; new scoped entrypoint remains unimplemented')


if __name__ == '__main__':
    main()
