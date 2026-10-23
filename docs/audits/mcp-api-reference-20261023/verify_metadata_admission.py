#!/usr/bin/env python3
"""Compare the exact admission repair against the original complete matrix."""
import copy
import gzip
import json
from pathlib import Path
import sys

from verify_arguments import ENVELOPE, controls, rewire, verify
from verify_inventory import encoded, errors, same_value

METADATA = {'fsmgen_capability_query', 'fsmgen_discover_sources',
            'fsmgen_find_examples', 'fsmgen_explain_diagnostic', 'fsmgen_support_summary'}
ADAPTER = 'perl/FSM/Support/SemanticIntrospectionMCPAdapter.pm'


def read(path):
    return json.loads(gzip.decompress(Path(path).read_bytes()))


def compare(before, after):
    initial, final = verify(before), verify(after)
    assert encoded(before['tools']) == encoded(after['tools']), 'tool discovery changed'
    assert before['cases'] == after['cases'], 'request population changed'
    assert set(before['source_sha256']) == set(after['source_sha256']), 'source population changed'
    assert set(after['native_source_overrides']) == {ADAPTER}, 'unexpected native implementation overlay'
    for path, identity in before['source_sha256'].items():
        if path.startswith('perl/FSM/') and path != ADAPTER:
            assert after['source_sha256'][path] == identity, 'unrelated native source changed'
    tools = {tool['name']: tool for tool in after['tools']}
    refused, conserved, preserved = [], [], []
    for index, (case, old, new) in enumerate(zip(before['cases'], before['api']['rows'], after['api']['rows'])):
        request = json.loads(case['request_utf8'])
        params = request.get('params')
        invalid = errors(params, ENVELOPE)
        if not invalid and params['name'] in METADATA:
            invalid = errors(params.get('arguments', {}), tools[params['name']]['inputSchema'])
        if invalid:
            for response in (new['response'], after['wire_replies'][index]):
                assert response.get('error', {}).get('code') == -32602, 'targeted invalid input admitted or misclassified'
            refused.append(case['label'])
        elif 'result' in old['response']:
            assert encoded(new['response']) == encoded(old['response']), 'complete supported result changed'
            conserved.append(case['label'])
        else:
            assert new['response']['error']['code'] == old['response']['error']['code'], 'unowned refusal class changed'
        if invalid or case['tool'] in METADATA:
            expected = json.loads(case['request_utf8'])
            assert same_value(json.loads(new['request_after_json']), expected), 'caller values changed'
            assert same_value(json.loads(new['request_after_clone_json']), expected), 'caller clone kinds changed'
        preserved.append(case['label'])
    # Remaining findings belong to the separately owned source-kind repair;
    # numeric limit selection has its own counterfactual-catalog oracle.
    for labels in final['findings'].values():
        assert all(label.split(':')[0] not in METADATA for label in labels), 'metadata findings remain'
    return {'original_findings': {k: len(v) for k, v in initial['findings'].items()},
            'remaining_findings': {k: len(v) for k, v in final['findings'].items()},
            'refused_cases': refused, 'complete_results_conserved': conserved,
            'caller_cases_checked': preserved,
            'native_overlay': sorted(after['native_source_overrides'])}


def repair_controls(before, after):
    refused = []
    for name, message in (
        ('old_invalid_admission', 'targeted invalid input admitted or misclassified'),
        ('changed_valid_payload', 'complete supported result changed'),
        ('lost_caller_copy_preservation', 'caller clone kinds changed'),
        ('changed_native_overlay', 'native overlay hash mismatch'),
    ):
        bad = copy.deepcopy(after)
        if name == 'changed_native_overlay':
            bad['native_source_overrides'][ADAPTER] += '\n'
        else:
            label = {'old_invalid_admission': 'fsmgen_support_summary:limit_examples:numeric_string',
                     'changed_valid_payload': 'fsmgen_support_summary:valid_base',
                     'lost_caller_copy_preservation': 'fsmgen_discover_sources:query:zero'}[name]
            index = next(i for i, c in enumerate(bad['cases']) if c['label'] == label)
            row = bad['api']['rows'][index]
            if name == 'old_invalid_admission':
                row['response'] = copy.deepcopy(before['api']['rows'][index]['response'])
            elif name == 'changed_valid_payload':
                result = row['response']['result']
                result['structuredContent']['entry_count'] = -1
                result['content'][0]['text'] = json.dumps(result['structuredContent'])
            else:
                row['request_after_clone_json'] = before['api']['rows'][index]['request_after_clone_json']
            bad['wire_replies'][index] = copy.deepcopy(row['response'])
            rewire(bad)
        try:
            compare(before, bad)
        except AssertionError as error:
            assert str(error) == message, (name, str(error))
            refused.append(name)
        else:
            raise AssertionError('Repair control accepted: ' + name)
    return refused


def main():
    assert len(sys.argv) == 3
    before, after = map(read, sys.argv[1:])
    result = compare(before, after)
    result['original_reader_controls'] = controls(before)
    result['repair_reader_controls'] = controls(after)
    result['repair_controls'] = repair_controls(before, after)
    print(json.dumps(result, indent=2))


if __name__ == '__main__':
    main()
