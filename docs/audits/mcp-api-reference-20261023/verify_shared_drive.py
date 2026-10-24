#!/usr/bin/env python3
"""Verify bounded shared binding/drive subjects without closing compound models."""
import argparse
import copy
import gzip
import json
import re
import sys
from pathlib import Path

from verify_shared_candidate import verify as verify_candidate
from verify_shared_binding import verify as verify_binding
from verify_composition_shallow import TableView, literal
from verify_composition_dt import code
from verify_error_context import source
from verify_model_roots import capture_check
from verify_normalized_symbols import body, returns
from verify_normalized_envelope import exact, require, sha

BASE = Path(__file__).resolve().parent
ROOT = BASE.parents[2]
OWNER = 'PERL-POD-API-REFERENCE.6.1.2.3.2.1.2.3.2.2.5.3'
BOOK = 'docs/book/src/11-extensions-and-embedding.md'
POD = 'perl/FSM/Support/CapabilityManifest.pm'
MARKER = 'Normalized shared-datapath binding and drive-intent subjects'
CONTEXTS = {
    'composition_shared_datapath_': 'semantic.composition.shared_datapath_candidates[]',
    'success_forward_ir_lowered_rtl_ir_composition_shared_datapath_': 'semantic.forward_ir.lowered_rtl_ir.composition_shared_datapath_candidates[]'}
ORACLE = {
    'bound_connection_expr_keys': (
        '.contributors[].bound_connection_expr', 'signal_ref_variant', ['kind', 'signal_name']),
    'candidate_contributor_drive_intent_entry_keys': (
        '.contributors[].drive_intent', 'object',
        ['default_value', 'driver_blocks', 'driver_count', 'driver_enable_signals',
         'family_enable_signals', 'multiplexer_type', 'reset_value', 'rhs_enable_families', 'rhs_values']),
    'candidate_contributor_drive_intent_rhs_enable_family_entry_keys': (
        '.contributors[].drive_intent.rhs_enable_families[]', 'array_element',
        ['driver_blocks', 'driver_enable_signals', 'family_enable_signal', 'rhs_value'])}


def read(name):
    return json.loads(gzip.decompress((BASE / name).read_bytes()))


def verify(packet, capture, current=False, contracts_current=False):
    require(packet['schema'] == 'fsmgen.shared_drive.v1' and packet['owner'] == OWNER, 'packet identity')
    previous = read('shared-candidate-qualified.json.gz')
    verify_candidate(previous, capture)
    binding = read('shared-binding-public-probe.json.gz')
    verify_binding(binding, capture, current_code=current or contracts_current)
    partition = read('shared-datapath-partition.json.gz')
    require(packet['inputs'] == {name: sha((BASE / name).read_bytes()) for name in (
        'shared-datapath-partition.json.gz', 'shared-candidate-qualified.json.gz', 'shared-binding-public-probe.json.gz')}, 'input identity')
    selected = {prefix + suffix for prefix in CONTEXTS for suffix in ORACLE}
    require(set(packet['fields']) == selected == set(partition['cohorts'][OWNER]), 'complete binding/drive population')
    require(exact(packet['remaining_shared']) == exact({key: value for key, value in previous['remaining_shared'].items() if key not in selected}), 'remaining shared conservation')
    require(exact(packet['remaining_fields']) == exact(previous['remaining_fields']), 'deeper delegation conservation')
    paths = set(previous['sources']) | {'perl/FSM/IR/StructuralRTLIR/ConnectionExpr.pm'}
    require(set(packet['sources']) == paths, 'source population')
    texts = {}
    for path, saved in packet['sources'].items():
        raw = saved['text'].encode()
        require(sha(raw) == saved['sha256'], 'source digest')
        require(code(raw) == code(source(capture, path)), 'original runtime conservation')
        if path != POD:
            require(raw == source(capture, path), 'dedicated source identity')
        if current:
            require((ROOT / path).read_bytes() == raw, 'current source stale')
        elif contracts_current:
            require(code((ROOT / path).read_bytes()) == code(raw), 'current contract/builder stale')
        texts[Path(path).stem] = saved['text']
    native = capture['native_api']['manifest']['semantic_exports']['normalized_semantic_json']
    for prefix, root in CONTEXTS.items():
        for suffix, (relative, rule, keys) in ORACLE.items():
            key = prefix + suffix
            row = packet['fields'][key]
            require(set(row) == {'value', 'subject', 'rule', 'alias_owner', 'value_owner'}, 'field shape')
            alias = 'LoweredRTLIRContract' if prefix.startswith('success_') else 'CompositionContract'
            require(row['subject'] == root + relative and row['rule'] == rule, 'exact subject/container/variant')
            require(row['alias_owner'] == 'FSM::Support::NormalizedSemantic' + alias
                    and row['value_owner'] == 'FSM::Support::NormalizedSemanticLoweredRTLIRContract', 'exact dedicated owners')
            require(exact(row['value']) == exact(native[key]) == exact(keys), 'native/literal value/type/order')
            lower = 'normalized_semantic_lowered_rtl_ir_composition_shared_datapath_' + suffix
            value_function = ('normalized_semantic_lowered_rtl_ir_output_drive_rhs_enable_family_entry_keys'
                              if suffix.endswith('rhs_enable_family_entry_keys') else lower)
            require(literal(texts['NormalizedSemanticLoweredRTLIRContract'], value_function) == keys, 'dedicated drive literal')
            if lower != value_function:
                returns(texts['NormalizedSemanticLoweredRTLIRContract'], lower, value_function)
            semantic = key.removeprefix('success_')
            report, payload = 'normalized_semantic_' + semantic, 'normalized_semantic_payload_' + semantic
            returns(texts['NormalizedSemanticReportContract'], report, payload)
            returns(texts['NormalizedSemanticPayloadContract'], payload, report)
            returns(texts['NormalizedSemanticForwardIRContract' if prefix.startswith('success_') else 'NormalizedSemanticCompositionContract'], report, lower)
            factory = body(texts['NormalizedSemanticReportContract'], 'build_normalized_semantic_report_contract')
            require(re.search(r'\b' + re.escape(key) + r'\s*=>\s*' + re.escape(report) + r'\(\)', factory), 'factory field allocation')
    builder = texts['SharedDatapathCandidateBuilder']
    drive = builder.split('\nsub drive_intent_from_output_drive_family ', 1)[1].split('\nsub ', 1)[0]
    require("return {} unless ref($output_drive_family) eq 'HASH';" in drive, 'empty drive object fallback')
    require(re.search(r'return\s*\{.*?rhs_enable_families\s*=>\s*\[\s*map\s*\{\s*\+\{', drive, re.S), 'drive object and nested family array source join')
    for field in ('driver_blocks', 'driver_enable_signals'):
        require(field + ' => [@{$_->{' + field + '} || []}]' in drive, 'nested family array copy')
    require('bound_connection_expr => undef' in builder
            and 'bound_connection_expr => _clone($binding_metadata->{bound_connection_expr})' in builder, 'nullable preserved binding projection')
    connection = texts['ConnectionExpr']
    require("kind => 'signal_ref'" in connection and "kind => 'concat'" in connection
            and 'bound_connection_expr => _clone(binding_expr($binding))' in connection, 'distinct recursive expression source owner')
    require('%{build_normalized_semantic_report_contract()}' in texts['SemanticExportsSection'], 'manifest republishing')
    require(set(packet['documents']) == {BOOK, POD} and packet['documents'][POD] == packet['sources'][POD], 'document population')
    for path, saved in packet['documents'].items():
        require(sha(saved['text'].encode()) == saved['sha256'], 'document digest')
        if current:
            require((ROOT / path).read_text() == saved['text'], 'current document stale')
        marker = ('### ' if path == BOOK else '=head2 ') + MARKER + '\n'
        require(marker in saved['text'], 'missing shared drive guide')
        guide = saved['text'].split(marker, 1)[1].split('\n### ' if path == BOOK else '\n=head', 1)[0]
        for phrase in ('signal_ref', 'concat', 'operands', 'nullable', 'object', 'arrays',
                       'deeper', 'source availability', 'execution', 'complete expression grammar'):
            require(phrase in guide, 'missing drive interpretation: ' + phrase)
        if path == BOOK:
            for prefix, root in CONTEXTS.items():
                require('| `' + prefix + '` | `' + root + '` |' in guide, 'exact documented drive context')
            for suffix, (relative, rule, keys) in ORACLE.items():
                require('| `' + suffix + '` | `' + relative[1:] + '` | `' + rule + '` | ' + ', '.join('`' + key + '`' for key in keys) + ' |' in guide, 'exact documented drive family')
            example = re.search(r'```json\n(.*?)\n```', guide, re.S)
            require(example is not None and exact(json.loads(example.group(1))) == exact(
                binding['result']['cases'][1]['result'][0]['contributors'][0]['bound_connection_expr']),
                'documented complete compound example joins actual public result')
    expected = {BASE.relative_to(ROOT).as_posix() + '/' + name for name in (
        'build_shared_drive.py', 'verify_shared_drive.py', 'verify_shared_binding.py', 'probe_shared_binding.pl')}
    require(set(packet['instruments']) == expected, 'instrument population')
    for path, saved in packet['instruments'].items():
        require(sha(saved['text'].encode()) == saved['sha256'] and (ROOT / path).read_text() == saved['text'], 'instrument identity')
    if current:
        require(packet['python'] == {'implementation': sys.implementation.name, 'version': list(sys.version_info)}, 'current reader runtime stale')
    return {'selected_fields': len(selected), 'remaining_shared': len(packet['remaining_shared']),
            'remaining_fields': len(packet['remaining_fields']), 'limits': packet['limits']}


def controls(packet, capture):
    results = {}
    key = 'composition_shared_datapath_bound_connection_expr_keys'
    for label in ('omission', 'extra', 'wrong_tier', 'wrong_subject', 'universal_binding', 'drive_as_array',
                  'family_as_object', 'wrong_owner', 'wrong_order', 'lost_shared', 'lost_deeper',
                  'source_change', 'instrument_change', 'missing_guide', 'stale_document'):
        bad = copy.deepcopy(packet)
        if label == 'omission':
            bad['fields'].pop(key)
        elif label == 'extra':
            bad['fields']['invented'] = bad['fields'][key]
        elif label == 'wrong_tier':
            bad['fields'][key]['subject'] = CONTEXTS['success_forward_ir_lowered_rtl_ir_composition_shared_datapath_'] + '.contributors[].bound_connection_expr'
        elif label == 'wrong_subject':
            bad['fields'][key]['subject'] = 'semantic.composition.shared_datapath_candidates[].drive_intent'
        elif label == 'universal_binding':
            bad['fields'][key]['rule'] = 'object'
        elif label == 'drive_as_array':
            row = bad['fields']['composition_shared_datapath_candidate_contributor_drive_intent_entry_keys']
            row['subject'] += '[]'; row['rule'] = 'array_element'
        elif label == 'family_as_object':
            row = bad['fields']['composition_shared_datapath_candidate_contributor_drive_intent_rhs_enable_family_entry_keys']
            row['subject'] = row['subject'][:-2]; row['rule'] = 'object'
        elif label == 'wrong_owner':
            bad['fields'][key]['value_owner'] = 'FSM::Support::NormalizedSemanticStructuralRTLIRContract'
        elif label == 'wrong_order':
            bad['fields'][key]['value'].reverse()
        elif label in ('lost_shared', 'lost_deeper'):
            values = bad['remaining_shared' if label == 'lost_shared' else 'remaining_fields']
            values.pop(next(iter(values)))
        else:
            saved = (bad['sources']['perl/FSM/Composition/SharedDatapathCandidateBuilder.pm'] if label == 'source_change' else
                     next(iter(bad['instruments'].values())) if label == 'instrument_change' else bad['documents'][BOOK])
            saved['text'] = saved['text'].replace('### ' + MARKER + '\n', '') if label == 'missing_guide' else saved['text'] + '\n# changed\n'
            saved['sha256'] = sha(saved['text'].encode())
        try:
            verify(bad, capture, current=label == 'stale_document')
        except ValueError as error:
            results[label] = str(error)
        else:
            raise ValueError('Accepted counterfeit: ' + label)
    return results


class DriveView(TableView):
    def handle_starttag(self, tag, attrs):
        if tag == 'h3':
            self.active = dict(attrs).get('id') == 'normalized-shared-datapath-binding-and-drive-intent-subjects'
        else:
            super().handle_starttag(tag, attrs)


def rendered(build):
    book = (build / '11-extensions-and-embedding.html').read_bytes()
    pod = (build / 'perl-api/FSM/Support/CapabilityManifest.html').read_bytes()
    view = DriveView(); view.feed(book.decode())
    require(view.rows[1:3] == [[prefix, root] for prefix, root in CONTEXTS.items()], 'native drive context table')
    require(view.rows[4:] == [[suffix, relative[1:], rule, ', '.join(keys)]
                            for suffix, (relative, rule, keys) in ORACLE.items()], 'native drive subject/value table')
    require(MARKER.encode() in pod and b'complete expression grammar' in pod, 'native drive POD guide')
    return {'book_sha256': sha(book), 'pod_sha256': sha(pod), 'rows': view.rows,
            'scope': 'Selected native content only; broader browser/manual signoff stays open.'}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('packet', type=Path, nargs='?', default=BASE / 'shared-drive-qualified.json.gz')
    mode = parser.add_mutually_exclusive_group()
    mode.add_argument('--current', action='store_true')
    mode.add_argument('--current-contracts', action='store_true')
    parser.add_argument('--build', type=Path)
    args = parser.parse_args()
    capture = read('model-roots-qualified.json.gz'); capture_check(capture)
    packet = json.loads(gzip.decompress(args.packet.read_bytes()))
    result = verify(packet, capture, args.current, args.current_contracts)
    result['rejected_controls'] = controls(packet, capture)
    if args.build:
        result['rendered'] = rendered(args.build)
    print(json.dumps(result, sort_keys=True))


if __name__ == '__main__':
    main()
