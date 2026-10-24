#!/usr/bin/env python3
"""Verify shared candidate subjects, optional type projections and source owners."""
import argparse
import copy
import gzip
import json
import re
import sys
from pathlib import Path

from partition_shared_datapath import verify as verify_partition
from verify_composition_shallow import TableView, literal
from verify_composition_dt import code
from verify_error_context import source
from verify_model_roots import capture_check
from verify_normalized_symbols import body, returns
from verify_normalized_envelope import exact, require, sha

BASE = Path(__file__).resolve().parent
ROOT = BASE.parents[2]
OWNER = 'PERL-POD-API-REFERENCE.6.1.2.3.2.1.2.3.2.2.5.2'
BOOK = 'docs/book/src/11-extensions-and-embedding.md'
POD = 'perl/FSM/Support/CapabilityManifest.pm'
MARKER = 'Normalized shared-datapath candidate and contributor subjects'
CONTEXTS = {
    'composition_shared_datapath_': 'semantic.composition.shared_datapath_candidates[]',
    'success_forward_ir_lowered_rtl_ir_composition_shared_datapath_': 'semantic.forward_ir.lowered_rtl_ir.composition_shared_datapath_candidates[]'}
# Explicit reviewed oracle, separate from the producer's source projection.
ORACLE = {
    'candidate_entry_keys': ('', 'core', ['signal_name', 'width', 'interface_type', 'storage_class', 'reset_value', 'contributor_count', 'contributors', 'top_output_signals', 'peer_input_count', 'peer_input_endpoints', 'default_lifted_visibility', 'planned_reexport_top_output_signals', 'loopback_allowed', 'lifted_runtime_kind', 'lifted_runtime_signal', 'lifted_runtime_next_signal', 'lifted_runtime_reset_value', 'lifted_runtime_reset_active_level', 'lifted_runtime_reset_kind', 'lifted_runtime_reset_keyword', 'aggregate_target_enable_signal', 'multi_value_conflict_signal', 'multi_value_assertion', 'aggregate_enable_family_count', 'aggregate_enable_families']),
    'candidate_declared_type_extension_keys': ('', 'optional_extension', ['declared_type_name', 'declared_type_spec']),
    'candidate_contributor_entry_keys': ('.contributors[]', 'core', ['kind', 'instance_name', 'module_name', 'source_name', 'endpoint', 'bound_signal', 'bound_signals', 'bound_connection_expr', 'output_drive_family', 'drive_intent', 'intent_hir', 'lowered_rtl_ir', 'structural_rtl_ir']),
    'candidate_contributor_declared_type_extension_keys': ('.contributors[]', 'optional_extension', ['declared_type_name', 'declared_type_spec'])}


def read(name):
    return json.loads(gzip.decompress((BASE / name).read_bytes()))


def verify(packet, capture, current=False, contracts_current=False):
    require(packet['schema'] == 'fsmgen.shared_candidate.v1' and packet['owner'] == OWNER, 'packet identity')
    partition = read('shared-datapath-partition.json.gz')
    verify_partition(partition)
    require(packet['inputs'] == {name: sha((BASE / name).read_bytes()) for name in ('shared-datapath-partition.json.gz', 'composition-final-qualified.json.gz')}, 'input identity')
    selected = {prefix + suffix for prefix in CONTEXTS for suffix in ORACLE}
    require(set(packet['fields']) == selected == set(partition['cohorts'][OWNER]), 'complete candidate population')
    require(exact(packet['remaining_shared']) == exact({key: value for key, value in partition['selected_values'].items() if key not in selected}), 'remaining shared conservation')
    require(exact(packet['remaining_fields']) == exact(partition['remaining_fields']), 'deeper delegation conservation')
    names = ('CapabilityManifest', 'SemanticExportsSection', 'NormalizedSemanticReportContract',
             'NormalizedSemanticPayloadContract', 'NormalizedSemanticForwardIRContract',
             'NormalizedSemanticCompositionContract', 'NormalizedSemanticLoweredRTLIRContract')
    paths = {'perl/FSM/Support/' + name + '.pm' for name in names} | {'perl/FSM/Composition/SharedDatapathCandidateBuilder.pm'}
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
            alias_owner = 'LoweredRTLIRContract' if prefix.startswith('success_') else 'CompositionContract'
            require(row['subject'] == root + relative and row['rule'] == rule, 'exact candidate/contributor/extension subject')
            require(row['alias_owner'] == 'FSM::Support::NormalizedSemantic' + alias_owner
                    and row['value_owner'] == 'FSM::Support::NormalizedSemanticLoweredRTLIRContract', 'dedicated candidate owner')
            require(exact(row['value']) == exact(native[key]) == exact(keys), 'native/literal value/type/order')
            lower = 'normalized_semantic_lowered_rtl_ir_composition_shared_datapath_' + suffix
            require(literal(texts['NormalizedSemanticLoweredRTLIRContract'], lower) == keys, 'dedicated candidate literal')
            semantic = key.removeprefix('success_')
            report = 'normalized_semantic_' + semantic
            payload = 'normalized_semantic_payload_' + semantic
            returns(texts['NormalizedSemanticReportContract'], report, payload)
            if prefix.startswith('success_'):
                returns(texts['NormalizedSemanticPayloadContract'], payload, report)
                returns(texts['NormalizedSemanticForwardIRContract'], report, lower)
                require('composition_shared_datapath_candidates' in literal(texts['NormalizedSemanticLoweredRTLIRContract'], 'normalized_semantic_lowered_rtl_ir_optional_composition_keys'), 'optional lowered collection membership')
            else:
                returns(texts['NormalizedSemanticPayloadContract'], payload, report)
                returns(texts['NormalizedSemanticCompositionContract'], report, lower)
            factory = body(texts['NormalizedSemanticReportContract'], 'build_normalized_semantic_report_contract')
            require(re.search(r'\b' + re.escape(key) + r'\s*=>\s*' + re.escape(report) + r'\(\)', factory), 'factory field allocation')
    builder = texts['SharedDatapathCandidateBuilder']
    for key in ('declared_type_name', 'declared_type_spec'):
        require('$contributor->{' + key + '} = $' + key + ' if defined $' + key + ';' in builder, 'independently optional contributor type field')
        require(re.search(r'\$candidate->\{' + key + r'\}\s*=\s*\$declared_type_contract->\{' + key + r'\}\s*if defined \$declared_type_contract->\{' + key + r'\};', builder), 'independently optional candidate type field')
    require('%{build_normalized_semantic_report_contract()}' in texts['SemanticExportsSection'], 'manifest republishing')
    require(set(packet['documents']) == {BOOK, POD} and packet['documents'][POD] == packet['sources'][POD], 'document population')
    for path, saved in packet['documents'].items():
        require(sha(saved['text'].encode()) == saved['sha256'], 'document digest')
        if current:
            require((ROOT / path).read_text() == saved['text'], 'current document stale')
        marker = ('### ' if path == BOOK else '=head2 ') + MARKER + '\n'
        require(marker in saved['text'], 'missing shared candidate guide')
        guide = saved['text'].split(marker, 1)[1].split('\n### ' if path == BOOK else '\n=head', 1)[0]
        for phrase in ('declared_type_name', 'declared_type_spec', 'independently', 'optional', 'contributors[]',
                       'source availability', 'equal populations', 'deeper', 'execution'):
            require(phrase in guide, 'missing candidate interpretation: ' + phrase)
        if path == BOOK:
            for prefix, root in CONTEXTS.items():
                require('| `' + prefix + '` | `' + root + '` |' in guide, 'exact documented candidate context')
            for suffix, (relative, rule, keys) in ORACLE.items():
                displayed = relative[1:] if relative else '(candidate entry)'
                require('| `' + suffix + '` | `' + displayed + '` | `' + rule + '` | ' + ', '.join('`' + key + '`' for key in keys) + ' |' in guide, 'exact documented candidate family')
    instruments = {BASE.relative_to(ROOT).as_posix() + '/' + name for name in ('build_shared_candidate.py', 'verify_shared_candidate.py')}
    require(set(packet['instruments']) == instruments, 'instrument population')
    for path, saved in packet['instruments'].items():
        require(sha(saved['text'].encode()) == saved['sha256'] and (ROOT / path).read_text() == saved['text'], 'instrument identity')
    if current:
        require(packet['python'] == {'implementation': sys.implementation.name, 'version': list(sys.version_info)}, 'current runtime stale')
    return {'selected_fields': len(selected), 'remaining_shared': len(packet['remaining_shared']),
            'remaining_fields': len(packet['remaining_fields']), 'limits': packet['limits']}


def controls(packet, capture):
    results = {}
    key = 'composition_shared_datapath_candidate_entry_keys'
    for label in ('omission', 'extra', 'wrong_tier', 'wrong_subject', 'optional_as_core', 'wrong_alias_owner',
                  'wrong_value_owner', 'wrong_order', 'lost_shared', 'lost_deeper', 'source_change',
                  'instrument_change', 'missing_guide', 'stale_document'):
        bad = copy.deepcopy(packet)
        if label == 'omission':
            bad['fields'].pop(key)
        elif label == 'extra':
            bad['fields']['success_forward_ir_intent_hir_composition_shared_datapath_candidate_entry_keys'] = bad['fields'][key]
        elif label == 'wrong_tier':
            bad['fields'][key]['subject'] = CONTEXTS['success_forward_ir_lowered_rtl_ir_composition_shared_datapath_']
        elif label == 'wrong_subject':
            bad['fields'][key]['subject'] += '.contributors[]'
        elif label == 'optional_as_core':
            bad['fields']['composition_shared_datapath_candidate_declared_type_extension_keys']['rule'] = 'core'
        elif label in ('wrong_alias_owner', 'wrong_value_owner'):
            bad['fields'][key]['alias_owner' if label == 'wrong_alias_owner' else 'value_owner'] = 'FSM::Support::NormalizedSemanticStructuralRTLIRContract'
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


class CandidateView(TableView):
    def handle_starttag(self, tag, attrs):
        if tag == 'h3':
            self.active = dict(attrs).get('id') == 'normalized-shared-datapath-candidate-and-contributor-subjects'
        else:
            super().handle_starttag(tag, attrs)


def rendered(build):
    book = (build / '11-extensions-and-embedding.html').read_bytes()
    pod = (build / 'perl-api/FSM/Support/CapabilityManifest.html').read_bytes()
    view = CandidateView()
    view.feed(book.decode())
    require(view.rows[1:3] == [[prefix, root] for prefix, root in CONTEXTS.items()], 'native candidate context table')
    require(view.rows[4:] == [[suffix, relative[1:] if relative else '(candidate entry)', rule, ', '.join(keys)]
                            for suffix, (relative, rule, keys) in ORACLE.items()], 'native candidate subject/key table')
    require(MARKER.encode() in pod and b'independently' in pod, 'native candidate POD guide')
    return {'book_sha256': sha(book), 'pod_sha256': sha(pod), 'rows': view.rows,
            'scope': 'Selected native rendered content only; broader browser/manual signoff stays open.'}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('packet', type=Path)
    mode = parser.add_mutually_exclusive_group()
    mode.add_argument('--current', action='store_true')
    mode.add_argument('--current-contracts', action='store_true')
    parser.add_argument('--build', type=Path)
    args = parser.parse_args()
    capture = read('model-roots-qualified.json.gz')
    capture_check(capture)
    packet = json.loads(gzip.decompress(args.packet.read_bytes()))
    result = verify(packet, capture, args.current, args.current_contracts)
    result['rejected_controls'] = controls(packet, capture)
    if args.build:
        result['rendered'] = rendered(args.build)
    print(json.dumps(result, sort_keys=True))


if __name__ == '__main__':
    main()
