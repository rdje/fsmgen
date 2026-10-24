#!/usr/bin/env python3
"""Read retained native T383 controls without executing a producer."""
import argparse
import copy
import gzip
import hashlib
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
BASE = Path(__file__).resolve().parent


def require(ok, why):
    if not ok:
        raise ValueError(why)


def sha(raw):
    return hashlib.sha256(raw).hexdigest()


def read(name):
    return json.loads(gzip.decompress((BASE / name).read_bytes()))


def verify(packet, current=False):
    before = read('diagnostic-map-repair-before.json.gz')
    require(packet['schema'] == 'fsmgen.diagnostic_map_repair.v1' and packet['owner'] == before['owner'], 'repair identity')
    require(packet['before_sha256'] == sha((BASE / 'diagnostic-map-repair-before.json.gz').read_bytes()), 'original packet identity')
    require(packet['test_before'] == before['test_before'] and sha(packet['test_before'].encode()) == before['test_before_sha256'], 'original test identity')
    require(packet['contract_sources'] == before['contract_sources'], 'contract source conservation')
    for name, text in packet['contract_sources'].items():
        if current:
            require((ROOT / ('perl/FSM/Support/' + name + '.pm')).read_text() == text, 'current dedicated contract stale')
    old, new = packet['test_before'], packet['test_after']
    # Exact narrow reversal proves all original array checks and discovery
    # traversal remain intact, rather than accepting an arbitrary green test.
    import_line = 'use FSM::Support::ReportSourceContract qw(report_source_optional_fields);\n'
    start = new.index('            # These two report contracts mirror')
    end = new.index("            ok(ref($values) eq 'ARRAY'", start)
    branch = new[start:end]
    require("$entry->{name} eq 'presence_key_family_map'" in branch and "$family eq 'source_optional_fields'" in branch, 'narrow map/family admission')
    require('CheckDiagnosticsContract|NormalizedSemanticReportContract' in branch and 'report_source_optional_fields()' in branch and '$parent->{$family}' in branch, 'dedicated owner/value/sibling admission')
    reversed_source = new[:start] + new[end:]
    require(reversed_source.count(import_line) == 1 and reversed_source.count('                    name => $key,\n') == 1, 'exact additional source loci')
    reversed_source = reversed_source.replace(import_line, '').replace('                    name => $key,\n', '')
    require(reversed_source == old, 'unrelated test change')
    producer = BASE / 'qualify_diagnostic_map_repair.py'
    require(sha(packet['producer_source'].encode()) == packet['producer_sha256'], 'producer source digest')
    if current:
        require(producer.read_text() == packet['producer_source'], 'current repair producer stale')
        require((ROOT / packet['test_path']).read_text() == new, 'current repaired test stale')
    labels = {'valid_CheckDiagnosticsContract', 'valid_NormalizedSemanticReportContract',
              'wrong_owner', 'wrong_map_name', 'wrong_family_name', 'missing_member', 'extra_member',
              'missing_sibling', 'changed_sibling', 'array_instead_of_object', 'generic_object',
              'ordinary_array', 'duplicate_array', 'nested_array_value'}
    require(set(packet['runs']) == {'before', 'after'}, 'phase population')
    native = read('model-roots-qualified.json.gz')['native_api']['manifest']
    optional = native['diagnostics']['check_json']['source_optional_fields']
    for phase, source in (('before', old), ('after', new)):
        runs = packet['runs'][phase]
        require(set(runs) == labels, 'complete actual control population')
        for label, run in runs.items():
            fixture = {'contract_source': 'FSM::Support::CheckDiagnosticsContract',
                       'source_optional_fields': copy.deepcopy(optional),
                       'presence_key_family_map': {'source_optional_fields': copy.deepcopy(optional)}}
            if label.startswith('valid_'):
                fixture['contract_source'] = 'FSM::Support::' + label[len('valid_'):]
            elif label == 'wrong_owner':
                fixture['contract_source'] = 'FSM::Support::ReportSourceContract'
            elif label == 'wrong_map_name':
                fixture['nested_presence_key_map'] = fixture.pop('presence_key_family_map')
            elif label in ('wrong_family_name', 'generic_object'):
                fixture['presence_key_family_map'] = {'unpublished_fields': copy.deepcopy(optional)}
            elif label == 'missing_member':
                del fixture['presence_key_family_map']['source_optional_fields']['reductions']
            elif label == 'extra_member':
                fixture['presence_key_family_map']['source_optional_fields']['invented'] = {}
            elif label == 'missing_sibling':
                del fixture['source_optional_fields']
            elif label == 'changed_sibling':
                fixture['source_optional_fields'] = {}
            elif label == 'array_instead_of_object':
                fixture['presence_key_family_map']['source_optional_fields'] = list(optional)
            else:
                values = ['mode'] if label == 'ordinary_array' else ['mode', 'mode'] if label == 'duplicate_array' else [['mode']]
                fixture = {'command_presence_keys': values, 'presence_key_family_map': {'command_presence_keys': values}}
            require(run['fixture'] == fixture, 'independent case identity: ' + label)
            intended = label.startswith('valid_') or label == 'ordinary_array'
            expected = intended if phase == 'after' else label in ('ordinary_array', 'array_instead_of_object')
            require(type(run['exit_status']) is int and (run['exit_status'] == 0) == expected, 'actual control exit: ' + label)
            require(run['intended_valid'] is intended and run['expected_success_at_phase'] is expected, 'control classification')
            require(run['stdout'].startswith('ok ') and ('not ok ' in run['stdout']) == (not expected), 'actual TAP result: ' + label)
            require(('Failed test' in run['stderr']) == (not expected), 'actual stderr result')
            require(run['command'][:2] == ['perl', '-Iperl'] and run['command'][2].startswith('.artifacts/tmp/'), 'local native command')
            start = source.index("subtest 'direct support contracts")
            end = source.index('done_testing();', start) + len('done_testing();')
            literal = "'" + json.dumps(fixture, sort_keys=True).replace('\\', '\\\\').replace("'", "\\'") + "'"
            call = 'assert_family_map_integrity(decode_json(' + literal + "), 'isolated fixture');\ndone_testing();"
            require(run['probe_source'] == source[:start] + call + source[end:], 'actual unchanged helper invocation')
            require(run['fixture'] == packet['runs']['after'][label]['fixture'], 'before/after same input')
    return {'phases': len(packet['runs']), 'actual_cases_per_phase': len(labels), 'source_reversal': True}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--current', action='store_true')
    args = parser.parse_args()
    packet = read('diagnostic-map-repair-after.json.gz')
    result = verify(packet, args.current)
    controls = {}
    for label in ('missing_case', 'false_pass', 'boolean_status', 'changed_fixture', 'changed_probe', 'unrelated_test_change'):
        bad = copy.deepcopy(packet)
        if label == 'missing_case':
            bad['runs']['before'].pop('wrong_owner')
        elif label in ('false_pass', 'boolean_status'):
            bad['runs']['after']['wrong_owner']['exit_status'] = 0 if label == 'false_pass' else True
        elif label == 'changed_probe':
            bad['runs']['after']['wrong_owner']['probe_source'] += '\n# changed\n'
        elif label == 'changed_fixture':
            bad['runs']['before']['wrong_owner']['fixture']['contract_source'] = 'borrowed'
        else:
            bad['test_after'] += '\n# unrelated\n'
        try:
            verify(bad)
        except (ValueError, KeyError) as error:
            controls[label] = str(error)
        else:
            raise ValueError('Accepted counterfeit: ' + label)
    result['rejected_controls'] = controls
    result['reader_source'] = Path(__file__).read_text()
    result['reader_sha256'] = sha(Path(__file__).read_bytes())
    print(json.dumps(result, sort_keys=True))


if __name__ == '__main__':
    main()
