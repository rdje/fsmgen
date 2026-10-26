#!/usr/bin/env python3
"""Verify the bounded composition-scope receipt; no generic support is inferred."""

import argparse
import copy
import gzip
import hashlib
import json
from pathlib import Path
import re
import subprocess


PACKET = Path('docs/audits/width-forwarding-contract-20261026.json.gz')


def valid_results(results):
    try:
        success = {'literal8', 'literal16', 'constant8', 'constant16', 'sibling_literal_control'}
        failures = {'top_parameter', 'unknown_parameter', 'sibling_parameter'}
        if set(results) != success | failures:
            return False
        for name, result in results.items():
            if result['pipeline_ok'] != int(name in success):
                return False
            if result['parser_ok'] != int(name != 'top_parameter'):
                return False
            if result['raw_caller_unchanged'] != 1 or json.loads(result['raw_before_json']) != result['raw']:
                return False
        for value in (8, 16):
            literal, constant = (results[prefix + str(value)] for prefix in ('literal', 'constant'))
            if literal['hdl'] != constant['hdl']:
                return False
            for result in (literal, constant):
                # Both successful source forms produce a static instance value,
                # with a child generic and no top configuration declaration.
                if not re.search(r'module\s+scope_probe\s*\(', result['hdl']):
                    return False
                if not re.search(r'parameter\s+CAP\s*=\s*4\b', result['hdl']):
                    return False
                if not re.search(r'\.CAP\(\s*' + str(value) + r'\s*\)', result['hdl']):
                    return False
                for field in ('intent_parameters', 'structural_parameters'):
                    entry, = result[field]
                    if entry['instance_name'] != 'consumer':
                        return False
                    override, = entry['parameter_overrides']
                    if override['name'] != 'CAP' or override['value_text'] != str(value):
                        return False
                    if override['value_payload'] != {'kind': 'scalar', 'payload': str(value)}:
                        return False
                    raw = 'WIDTH' if result is constant else str(value)
                    if override['raw_value'] != raw:
                        return False
        control = results['sibling_literal_control']
        if [entry['instance_name'] for entry in control['structural_parameters']] != ['parent', 'consumer']:
            return False
        error = results['top_parameter']['parser_error']
        if "child '+params'" not in error or 'perl/FSM/Composition/Parser.pm line 276' not in error:
            return False
        for name, token in [('unknown_parameter', 'WIDTH'), ('sibling_parameter', 'parent.WIDTH')]:
            error = results[name]['pipeline_error']
            if "saw '" + token + "'" not in error or 'perl/FSM/ParameterValueSupport.pm line 340' not in error:
                return False
        return True
    except (KeyError, TypeError, ValueError, IndexError, json.JSONDecodeError):
        return False


def hostile_controls(results):
    mutations = [
        ('false_top_admission', lambda data: data['top_parameter'].update(parser_ok=1)),
        ('false_sibling_binding', lambda data: data['sibling_parameter'].update(pipeline_ok=1)),
        ('erase_static_source_token', lambda data: data['constant8']['structural_parameters'][0]
         ['parameter_overrides'][0].update(raw_value='8')),
        ('wrong_static_value', lambda data: data['constant16']['intent_parameters'][0]
         ['parameter_overrides'][0].update(value_text='8')),
        ('static_as_top_generic', lambda data: data['constant8'].update(
            hdl=data['constant8']['hdl'].replace('module scope_probe (', 'module scope_probe #(parameter WIDTH=8) ('))),
        ('changed_caller', lambda data: data['literal8'].update(raw=[])),
    ]
    for name, mutate in mutations:
        candidate = copy.deepcopy(results)
        mutate(candidate)
        assert not valid_results(candidate), name
    return [name for name, _ in mutations]


def verify(packet, *, historical=False):
    assert valid_results(packet['results']), 'saved source/native observations violate the declared oracle'
    assert hostile_controls(packet['results']) == packet['rejected_hostile_controls']
    for path, source in packet['sources'].items():
        data = source.encode()
        assert hashlib.sha256(data).hexdigest() == packet['source_epoch_sha256'][path], path
        assert subprocess.check_output(['git', 'show', packet['base_revision'] + ':' + path]) == data, path
        if not historical:
            assert Path(path).read_bytes() == data, 'current compiler changed; reverify the scope contract: ' + path
    for identity in packet['compiled_identities'].values():
        assert packet['source_epoch_sha256'][identity['file']] == identity['sha256']


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--historical', action='store_true', help='verify retained Git epoch without claiming current source equality')
    args = parser.parse_args()
    packet = json.loads(gzip.decompress(PACKET.read_bytes()))
    verify(packet, historical=args.historical)
    print('width-forwarding-contract: retained source/native/IR scope controls, exact Git joins and hostile products verified; generic implementation remains pending')


if __name__ == '__main__':
    main()
