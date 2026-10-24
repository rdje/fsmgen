#!/usr/bin/env python3
"""Verify retained Boolean repair results, complete conservation and source delta."""
import argparse
import copy
import gzip
import hashlib
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
BASE = Path(__file__).resolve().parent
REPORT = 'perl/FSM/Support/NormalizedSemanticReport.pm'


def require(ok, why):
    if not ok:
        raise ValueError(why)


def exact(value):
    return json.dumps(value, sort_keys=True, ensure_ascii=True, separators=(',', ':'))


def sha(raw):
    return hashlib.sha256(raw).hexdigest()


def verify(before, after, current=False):
    owner = 'PERL-POD-API-REFERENCE.6.1.2.3.2.1.2.3.2.2.2.2'
    expected_paths = {REPORT, 'perl/FSM/Support/CompositionReportContract.pm',
        't/2105-normalized-semantic-json-booleans.t',
        'docs/audits/mcp-api-reference-20261023/probe_normalized_booleans.pl'}
    for phase, packet in (('before', before), ('after', after)):
        require(packet['schema'] == 'fsmgen.normalized_boolean_repair.v1' and packet['owner'] == owner and packet['phase'] == phase, 'packet identity')
        require(exact(json.loads(packet['raw_stdout'])) == exact(packet['decoded']), 'raw/decoded complete join')
        require(packet['decoded']['scope'] == 'synthetic_public_builder_metadata_no_source_query', 'fixture scope')
        require(set(packet['sources']) == expected_paths, 'complete source/probe/test population')
        for path, saved in packet['sources'].items():
            require(sha(saved['text'].encode()) == saved['sha256'], 'source digest')
            if current and phase == 'after':
                require((ROOT / path).read_text() == saved['text'], 'current source stale')
    marker = '    return (1, undef) unless defined $value;\n'
    branch = '    return (1, $value) if JSON::PP::is_bool($value);\n'
    original = before['sources'][REPORT]['text']
    require(original.count(marker) == 1 and branch not in original, 'original missing Boolean branch')
    require(after['sources'][REPORT]['text'] == original.replace(marker, marker + branch), 'exact Boolean-only repair')
    for path in expected_paths - {REPORT}:
        require(before['sources'][path] == after['sources'][path], 'unchanged probe/test/composition oracle')
    require(branch in before['sources']['perl/FSM/Support/CompositionReportContract.pm']['text'], 'established public JSON Boolean predicate')
    old, new = before['decoded'], after['decoded']
    require(old['runtime'] == new['runtime'] and set(new['runtime']) == {'perl', 'json_pp'}, 'controlled runtime identity')
    ids = ['json_values', 'plain_values', 'private_refs']
    require([c['id'] for c in old['cases']] == ids == [c['id'] for c in new['cases']], 'complete ordered case population')
    for prior, final in zip(old['cases'], new['cases']):
        require(exact({k: v for k, v in prior.items() if k != 'output'}) == exact({k: v for k, v in final.items() if k != 'output'}), 'same inputs/caller observations')
        require(exact({k: v for k, v in prior['output'].items() if k != 'semantic'}) == exact({k: v for k, v in final['output'].items() if k != 'semantic'}), 'complete non-semantic report conservation')
        if final['id'] != 'private_refs':
            require(prior['caller_before'] == prior['caller_after'] == final['caller_before'] == final['caller_after'], 'caller input/value/kind conservation')
        if final['id'] == 'json_values':
            source = final['input']
            semantic = final['output']['semantic']
            require(exact(semantic['system_contract']) == exact(source['module_info']['system_contract']), 'complete Boolean system fields')
            require(exact(semantic['signal_analysis']) == exact(source['module_info']['signal_analysis']), 'complete Boolean signal fields')
            require(exact(semantic['forward_ir']['intent_hir']) == exact(source['result']['intent_hir']), 'complete ordered primitive hash/array values')
            require('declare_ports' not in prior['output']['semantic']['system_contract']
                    and 'implicit' not in prior['output']['semantic']['system_contract']
                    and 'signed' not in prior['output']['semantic']['signal_analysis']['inputs'][0], 'genuine original declared-field loss')
            require('explicit_system_contract' in semantic and semantic['explicit_system_contract'] is None, 'nullable parent key retains')
        elif final['id'] == 'plain_values':
            require(exact(prior['output']) == exact(final['output']), 'complete unaffected plain-value report')
        else:
            expected = {'false_value': False, 'values': [False, 0, None]}
            require(exact(final['output']['semantic']['forward_ir']['intent_hir']) == exact(expected), 'private refs excluded while false values retain positions')
            require(final['caller_private_unchanged'] is True and final['caller_scalar_value'] == 9 and final['caller_false_kind'] == 'boolean', 'private/scalar/Boolean caller preservation')
    return {'cases': len(ids), 'source_delta': 'one standard Boolean-recognition line', 'runtime': new['runtime']}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--current', action='store_true')
    args = parser.parse_args()
    before = json.loads(gzip.decompress((BASE / 'normalized-boolean-repair-before.json.gz').read_bytes()))
    after = json.loads(gzip.decompress((BASE / 'normalized-boolean-repair-after.json.gz').read_bytes()))
    result = verify(before, after, args.current)
    controls = {}
    for label in ('numeric_false', 'missing_array_value', 'unrelated_report_change', 'lost_case', 'caller_mutation', 'unrelated_source_change'):
        bad = copy.deepcopy(after)
        first = bad['decoded']['cases'][0]
        if label == 'numeric_false':
            first['output']['semantic']['system_contract']['declare_ports'] = 0
        elif label == 'missing_array_value':
            first['output']['semantic']['forward_ir']['intent_hir']['probe_values'].pop(0)
        elif label == 'unrelated_report_change':
            first['output']['producer']['name'] = 'changed'
        elif label == 'lost_case':
            bad['decoded']['cases'].pop()
        elif label == 'caller_mutation':
            first['caller_after'] = '{}'
        else:
            saved = bad['sources'][REPORT]
            saved['text'] += '\n# changed\n'
            saved['sha256'] = sha(saved['text'].encode())
        bad['raw_stdout'] = json.dumps(bad['decoded'], sort_keys=True) + '\n'
        try:
            verify(before, bad)
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
