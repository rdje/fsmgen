#!/usr/bin/env python3
"""Qualify a current baseline through an exact, independently checked repair."""
import argparse
import copy
import gzip
import json
import re
import sys
from pathlib import Path

import verify_normalized_baseline as baseline_reader
import verify_normalized_booleans as boolean_reader
from verify_error_context import source
from verify_model_roots import capture_check
from verify_normalized_envelope import exact, read, require, sha

ROOT = Path(__file__).resolve().parents[3]
BASE = Path(__file__).resolve().parent
REPORT = 'perl/FSM/Support/NormalizedSemanticReport.pm'
OWNER = 'PERL-POD-API-REFERENCE.6.1.2.3.2.1.2.3.2.2.2.3'
INSTRUMENTS = {BASE.relative_to(ROOT).as_posix() + '/' + name for name in (
    'build_normalized_baseline_closure.py', 'verify_normalized_baseline_closure.py',
    'build_normalized_baseline.py', 'verify_normalized_baseline.py',
    'verify_normalized_booleans.py', 'build_diagnostic_families.py',
    'verify_normalized_envelope.py', 'verify_error_context.py',
    'verify_model_roots.py', 'verify_source_identity.py', 'verify_diagnostic_limits.py',
    'verify_inventory.py')}
INSTRUMENTS.add('scripts/generate_pod_reference.py')


def verify(packet, capture, current=False):
    require(packet['schema'] == 'fsmgen.normalized_baseline_closure.v1'
            and packet['owner'] == OWNER and re.fullmatch('[0-9a-f]{40}', packet['head']), 'closure identity')
    inputs = ('normalized-baseline-census-qualified.json.gz',
              'normalized-boolean-repair-before.json.gz', 'normalized-boolean-repair-after.json.gz')
    require(packet['inputs'] == {name: sha((BASE / name).read_bytes()) for name in inputs}, 'retained input identity')
    prior, before, after = (read(name) for name in inputs)
    baseline_reader.verify(prior, capture)
    repair = boolean_reader.verify(before, after, current)
    fresh = packet['baseline']
    require(exact(fresh['fields']) == exact(prior['fields'])
            and exact(fresh['remaining_fields']) == exact(prior['remaining_fields']), 'complete field/delegation conservation')
    require(set(fresh['sources']) == set(prior['sources']), 'unchanged baseline source membership')
    require(prior['sources'][REPORT] == before['sources'][REPORT], 'prior baseline to original repair bridge')
    require(source(capture, REPORT).decode() == before['sources'][REPORT]['text'], 'native to original repair bridge')
    require(fresh['sources'][REPORT] == after['sources'][REPORT], 'exact repaired current report bridge')
    for path in set(prior['sources']) - {REPORT, baseline_reader.POD}:
        require(fresh['sources'][path] == prior['sources'][path], 'unchanged dedicated family: ' + path)
    # The old oracle deliberately requires the original runtime. Supply that
    # one authenticated source only after proving both exact repair joins above.
    # No retained or refreshed evidence is rewritten by this comparison view.
    original_view = copy.deepcopy(fresh)
    original_view['sources'][REPORT] = copy.deepcopy(before['sources'][REPORT])
    result = baseline_reader.verify(original_view, capture)
    require(set(packet['instruments']) == INSTRUMENTS, 'complete instrument population')
    for path, saved in packet['instruments'].items():
        require(set(saved) == {'text', 'sha256'} and sha(saved['text'].encode()) == saved['sha256'], 'instrument digest')
        require((ROOT / path).read_text() == saved['text'], 'reader/producer instrument changed: ' + path)
    for group in ('sources', 'documents', 'helpers'):
        for path, saved in fresh[group].items():
            require(sha(saved['text'].encode()) == saved['sha256'], group + ' digest')
            if current:
                require((ROOT / path).read_text() == saved['text'], 'current ' + group + ' stale: ' + path)
    if current:
        builder = fresh['builder']
        require((ROOT / builder['path']).read_text() == builder['text'], 'current baseline producer stale')
        require(fresh['python'] == {'implementation': sys.implementation.name, 'version': list(sys.version_info)}, 'current runtime stale')
    for path in (baseline_reader.BOOK, baseline_reader.POD):
        text = fresh['documents'][path]['text']
        require(('preserves JSON Boolean' in text if path == baseline_reader.BOOK
                 else 'preserves C<JSON::PP::Boolean>' in text)
                and 'native' in text and 'reachability' in text, 'current repair guidance and source-qualification limit')
    result['qualified_repair'] = repair
    result['scope'] = packet['limits']
    return result


def controls(packet, capture):
    results = {}
    for label in ('field_value', 'lost_delegation', 'unrelated_family', 'unrelated_report',
                  'old_report', 'input_identity', 'missing_instrument', 'changed_instrument',
                  'missing_guide', 'stale_document'):
        bad = copy.deepcopy(packet)
        fresh = bad['baseline']
        if label == 'field_value':
            fresh['fields']['public_layers']['value'].reverse()
        elif label == 'lost_delegation':
            fresh['remaining_fields'].pop(next(iter(fresh['remaining_fields'])))
        elif label == 'input_identity':
            bad['inputs'][next(iter(bad['inputs']))] = '0' * 64
        elif label == 'missing_instrument':
            bad['instruments'].pop(next(iter(bad['instruments'])))
        else:
            if label == 'old_report':
                fresh['sources'][REPORT] = read('normalized-boolean-repair-before.json.gz')['sources'][REPORT]
            else:
                saved = (fresh['sources'][baseline_reader.owner_path('Payload')] if label == 'unrelated_family' else
                         fresh['sources'][REPORT] if label == 'unrelated_report' else
                         next(iter(bad['instruments'].values())) if label == 'changed_instrument' else
                         fresh['documents'][baseline_reader.BOOK])
                saved['text'] = (saved['text'].replace('### Normalized payload and IR baseline families\n', '')
                                 if label == 'missing_guide' else saved['text'] + '\n# changed\n')
                saved['sha256'] = sha(saved['text'].encode())
        try:
            verify(bad, capture, current=label == 'stale_document')
        except (ValueError, KeyError, AssertionError) as error:
            results[label] = str(error)
        else:
            raise ValueError('Accepted counterfeit: ' + label)
    return results


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('packet', type=Path, nargs='?',
                        default=BASE / 'normalized-baseline-current-qualified.json.gz')
    parser.add_argument('--current', action='store_true')
    args = parser.parse_args()
    capture = read('model-roots-qualified.json.gz')
    capture_check(capture)
    packet = json.loads(gzip.decompress(args.packet.read_bytes()))
    result = verify(packet, capture, args.current)
    result['rejected_controls'] = controls(packet, capture)
    result['reader_source'] = Path(__file__).read_text()
    result['reader_sha256'] = sha(Path(__file__).read_bytes())
    print(json.dumps(result, sort_keys=True))


if __name__ == '__main__':
    main()
