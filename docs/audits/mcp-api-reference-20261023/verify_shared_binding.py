#!/usr/bin/env python3
"""Verify the public signal/compound binding probe without recompiling sources."""
import argparse
import copy
import gzip
import json
from pathlib import Path

from verify_composition_dt import code
from verify_error_context import source
from verify_model_roots import capture_check
from verify_normalized_envelope import exact, require, sha

BASE = Path(__file__).resolve().parent
ROOT = BASE.parents[2]
OWNER = 'PERL-POD-API-REFERENCE.6.1.2.3.2.1.2.3.2.2.5.3'
PROBE = BASE.relative_to(ROOT).as_posix() + '/probe_shared_binding.pl'
SOURCES = {'perl/FSM/' + name + '.pm' for name in (
    'Composition/ChildExportBuilder', 'Composition/InterfacePortBuilder',
    'Composition/Net', 'Composition/Plan', 'Composition/Port',
    'Composition/SharedDatapathCandidateBuilder', 'Composition/SharedDatapathSupport',
    'IR/IntentHIR', 'IR/LoweredRTLIR', 'IR/StructuralRTLIR',
    'IR/StructuralRTLIR/ConnectionExpr', 'IR/StructuralRTLIRBuilder',
    'Support/NormalizedSemanticLoweredRTLIRContract')}


def verify(packet, capture, current_code=False):
    require(packet['owner'] == OWNER and packet['command'] == ['perl', '-Iperl', PROBE], 'probe identity')
    require(packet['exit_status'] == 0 and packet['stderr'] == '', 'successful public observation')
    require(exact(json.loads(packet['stdout'])) == exact(packet['result']), 'complete raw/decoded result join')
    instrument = packet['probe']
    require(instrument['path'] == PROBE and sha(instrument['text'].encode()) == instrument['sha256']
            and (ROOT / PROBE).read_text() == instrument['text'], 'exact probe source')
    result = packet['result']
    require(result['schema'] == 'fsmgen.shared_binding_probe.v1', 'result schema')
    require(set(result['sources']) == SOURCES, 'complete observed own-module population')
    require(not any(name.startswith('FSM/') for name in result['external_read_only_toolchain_modules']), 'no own module hidden as external')
    for path, saved in result['sources'].items():
        raw = saved['text'].encode()
        require(sha(raw) == saved['sha256'], 'source digest')
        require(code(raw) == code(source(capture, path)), 'original producer code join')
        if current_code:
            require(code((ROOT / path).read_bytes()) == code(raw), 'current producer code stale')
    require(result['advertised_keys'] == ['kind', 'signal_name'], 'unchanged bounded advertised family')
    cases = result['cases']
    require([case['kind'] for case in cases] == ['signal_ref', 'concat'], 'complete fixture variants')
    for case in cases:
        require(len(case['input_instances']) == 2 and len(case['result']) == 1, 'explicit fixture/result population')
        contributors = case['result'][0]['contributors']
        require([item['instance_name'] for item in contributors] == ['left', 'right'], 'complete ordered fixture contributors')
        for index, name in enumerate(('left', 'right')):
            expected = ({'kind': 'signal_ref', 'signal_name': name + '_bus'} if case['kind'] == 'signal_ref'
                        else {'kind': 'concat', 'operands': [
                            {'kind': 'signal_ref', 'signal_name': name + '_hi'},
                            {'kind': 'signal_ref', 'signal_name': name + '_lo'}]})
            actual_input = case['input_instances'][index]['port_bindings'][0]['connection_expr']
            require(exact(actual_input) == exact(expected), 'independent exact expression input')
            require(exact(contributors[index]['bound_connection_expr']) == exact(expected), 'complete cloned expression survives public builder')
            require(contributors[index]['bound_signals'] == ([name + '_bus'] if case['kind'] == 'signal_ref'
                    else [name + '_hi', name + '_lo']), 'dependency summary agrees with expression')
    return {'fixture_variants': [case['kind'] for case in cases],
        'scope': 'Signal-ref family versus preserved compound data through explicit public structured-IR inputs; no full expression grammar, native DSL/compiler/backend availability or unrelated candidate semantics.'}


def controls(packet, capture):
    results = {}
    for label in ('lost_variant', 'wrong_input', 'clamped_compound', 'lost_operand',
                  'invented_advertisement', 'lost_source', 'source_change', 'probe_change'):
        bad = copy.deepcopy(packet)
        result = bad['result']
        if label == 'lost_variant':
            result['cases'].pop()
        elif label == 'wrong_input':
            result['cases'][1]['input_instances'][0]['port_bindings'][0]['connection_expr'] = {'kind': 'signal_ref', 'signal_name': 'left_bus'}
        elif label == 'clamped_compound':
            result['cases'][1]['result'][0]['contributors'][0]['bound_connection_expr'] = {'kind': 'concat', 'signal_name': ''}
        elif label == 'lost_operand':
            result['cases'][1]['result'][0]['contributors'][0]['bound_connection_expr']['operands'].pop()
        elif label == 'invented_advertisement':
            result['advertised_keys'].append('operands')
        elif label == 'lost_source':
            result['sources'].pop(next(iter(result['sources'])))
        else:
            saved = next(iter(result['sources'].values())) if label == 'source_change' else bad['probe']
            saved['text'] = '# changed\n' + saved['text']
            saved['sha256'] = sha(saved['text'].encode())
        bad['stdout'] = json.dumps(result, sort_keys=True) + '\n'
        try:
            verify(bad, capture)
        except ValueError as error:
            results[label] = str(error)
        else:
            raise ValueError('Accepted counterfeit: ' + label)
    return results


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--current-code', action='store_true')
    args = parser.parse_args()
    packet = json.loads(gzip.decompress((BASE / 'shared-binding-public-probe.json.gz').read_bytes()))
    capture = json.loads(gzip.decompress((BASE / 'model-roots-qualified.json.gz').read_bytes()))
    capture_check(capture)
    result = verify(packet, capture, args.current_code)
    result['rejected_controls'] = controls(packet, capture)
    result['reader_sha256'] = sha(Path(__file__).read_bytes())
    print(json.dumps(result, sort_keys=True))


if __name__ == '__main__':
    main()
