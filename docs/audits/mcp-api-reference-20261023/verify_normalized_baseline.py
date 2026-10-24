#!/usr/bin/env python3
"""Independently join baseline subjects to dedicated literal contract families."""
import argparse
import copy
import gzip
import json
import re
import sys
from pathlib import Path

from verify_normalized_envelope import read, sha, exact, require
from verify_error_context import source
from verify_model_roots import capture_check

ROOT = Path(__file__).resolve().parents[3]
BASE = Path(__file__).resolve().parent
OWNER = 'PERL-POD-API-REFERENCE.6.1.2.3.2.1.2.3.2.2.2'
BOOK = 'docs/book/src/11-extensions-and-embedding.md'
POD = 'perl/FSM/Support/CapabilityManifest.pm'
BUILDER = 'docs/audits/mcp-api-reference-20261023/build_normalized_baseline.py'

# Public owner/function oracle is separate from the producer's field classifier.
ORACLE = {
    'success_semantic_presence_keys': ('semantic', 'success_base', 'Payload', 'payload_presence_keys'),
    'success_semantic_optional_child_presence_keys': ('semantic', 'optional_children', 'Payload', 'payload_optional_child_presence_keys'),
    'success_module_presence_keys': ('semantic.module', 'base_fields', 'Module', 'module_presence_keys'),
    'success_module_optional_metric_keys': ('semantic.module', 'optional_metrics', 'Module', 'module_optional_metric_keys'),
    'success_explicit_system_contract_presence_keys': ('semantic.explicit_system_contract', 'when_preserved_object', 'ExplicitSystem', 'explicit_system_contract_presence_keys'),
    'success_signal_analysis_presence_keys': ('semantic.signal_analysis', 'bucket_names', 'SignalAnalysis', 'signal_analysis_presence_keys'),
    'success_signal_analysis_entry_presence_keys': ('semantic.signal_analysis.<bucket>[]', 'common_entry_fields', 'SignalAnalysis', 'signal_analysis_entry_presence_keys'),
    'success_system_contract_presence_keys': ('semantic.system_contract', 'effective_system_fields', 'System', 'system_contract_presence_keys'),
    'success_symbol_contract_presence_keys': ('semantic.symbol_contract', 'when_available_object', 'Symbol', 'symbol_contract_presence_keys'),
    'success_forward_ir_presence_keys': ('semantic.forward_ir', 'tier_names', 'ForwardIR', 'forward_ir_presence_keys'),
    'success_forward_ir_intent_hir_presence_keys': ('semantic.forward_ir.intent_hir', 'tier_base_fields', 'IntentHIR', 'intent_hir_presence_keys'),
    'success_forward_ir_intent_hir_optional_composition_keys': ('semantic.forward_ir.intent_hir', 'optional_composition_fields', 'IntentHIR', 'intent_hir_optional_composition_keys'),
    'success_forward_ir_lowered_rtl_ir_presence_keys': ('semantic.forward_ir.lowered_rtl_ir', 'tier_base_fields', 'LoweredRTLIR', 'lowered_rtl_ir_presence_keys'),
    'success_forward_ir_lowered_rtl_ir_optional_composition_keys': ('semantic.forward_ir.lowered_rtl_ir', 'optional_composition_fields', 'LoweredRTLIR', 'lowered_rtl_ir_optional_composition_keys'),
    'success_forward_ir_structural_rtl_ir_presence_keys': ('semantic.forward_ir.structural_rtl_ir', 'tier_base_fields', 'StructuralRTLIR', 'structural_rtl_ir_presence_keys'),
}
OWNERS = {
    'semantic_contract_source': ('semantic', 'Payload'), 'module_contract_source': ('module', 'Module'),
    'explicit_system_contract_source': ('explicit_system_contract', 'ExplicitSystem'),
    'signal_analysis_contract_source': ('signal_analysis', 'SignalAnalysis'),
    'system_contract_source': ('system_contract', 'System'), 'symbol_contract_source': ('symbol_contract', 'Symbol'),
    'forward_ir_contract_source': ('forward_ir', 'ForwardIR'), 'composition_contract_source': ('composition', 'Composition'),
    'forward_ir_intent_hir_contract_source': ('forward_ir_intent_hir', 'IntentHIR'),
    'forward_ir_lowered_rtl_ir_contract_source': ('forward_ir_lowered_rtl_ir', 'LoweredRTLIR'),
    'forward_ir_structural_rtl_ir_contract_source': ('forward_ir_structural_rtl_ir', 'StructuralRTLIR'),
}


def owner_path(name):
    return 'perl/FSM/Support/NormalizedSemantic' + name + 'Contract.pm'


def literal_family(text, function):
    body = text.split('\nsub normalized_semantic_' + function + ' {', 1)[1].split('\n}', 1)[0]
    match = re.search(r'return\s*\[\s*qw\((.*?)\)\s*,?\s*\]\s*;', body, re.S)
    require(match is not None, 'unsupported literal-family source grammar: ' + function)
    return match.group(1).split()


def verify(packet, capture, current=False):
    require(packet['schema'] == 'fsmgen.normalized_baseline_families.v1' and packet['owner'] == OWNER, 'packet identity')
    require(packet['capture_sha256'] == sha((BASE / 'model-roots-qualified.json.gz').read_bytes()) and packet['capture_head'] == capture['head'], 'capture identity')
    previous = read('normalized-envelope-qualified.json.gz')
    require(packet['predecessor_sha256'] == sha((BASE / 'normalized-envelope-qualified.json.gz').read_bytes()) and packet['predecessor_fields'] == previous['remaining_fields'], 'exact predecessor delegation')
    native = capture['native_api']['manifest']['semantic_exports']['normalized_semantic_json']
    selected = set(ORACLE) | {'public_layers'} | set(OWNERS)
    require(set(packet['fields']) == selected, 'complete selected population')
    remaining = set(previous['remaining_fields']) - selected
    targets = [OWNER.rsplit('.', 1)[0] + '.8', 'PERL-POD-API-REFERENCE.6.1.2.3.2.3',
               'PERL-POD-API-REFERENCE.6.1.2.3.3', 'PERL-POD-API-REFERENCE.6.4']
    require(packet['remaining_fields'] == {key: targets for key in remaining}, 'complete deeper delegation')
    paths = {owner_path(owner) for _, owner in OWNERS.values()} | {POD,
        'perl/FSM/Support/NormalizedSemanticReport.pm', 'perl/FSM/Support/NormalizedSemanticReportContract.pm'}
    require(set(packet['sources']) == paths, 'semantic source membership')
    for filename, saved in packet['sources'].items():
        raw = saved['text'].encode()
        require(sha(raw) == saved['sha256'], 'source digest')
        original = source(capture, filename)
        require(raw.split(b'\n__END__\n', 1)[0] == original.split(b'\n__END__\n', 1)[0], 'source runtime conservation')
        if filename != POD:
            require(raw == original, 'dedicated source identity')
        if current:
            require((ROOT / filename).read_bytes() == raw, 'current source stale')
    for key, row in packet['fields'].items():
        require(set(row) == {'subject', 'rule', 'value'} and exact(row['value']) == exact(native[key]), 'native field value/type/order: ' + key)
    for key, (subject, rule, owner, function) in ORACLE.items():
        row = packet['fields'][key]
        require(row['subject'] == subject and row['rule'] == rule, 'subject/availability rule: ' + key)
        declared = literal_family(packet['sources'][owner_path(owner)]['text'], function)
        require(native[key] == declared, 'dedicated public family oracle: ' + key)
    for key, (subject, owner) in OWNERS.items():
        row = packet['fields'][key]
        require(row['subject'] == 'nested_owner:' + subject and row['rule'] == 'dedicated_owner_identity'
                and row['value'] == 'FSM::Support::NormalizedSemantic' + owner + 'Contract', 'dedicated owner identity')
    layer = packet['fields']['public_layers']
    require(layer['subject'] == 'public_layer_names' and layer['rule'] == 'advertised_values', 'layer values versus payload keys')
    report = packet['sources']['perl/FSM/Support/NormalizedSemanticReport.pm']['text']
    match = re.search(r'semantic_layers\s*=>\s*\[qw\((.*?)\)\]', report, re.S)
    require(match is not None and native['public_layers'] == match.group(1).split(), 'producer-advertised layer values')
    body = report.split('\nsub _semantic_contract {', 1)[1].split('\nsub ', 1)[0]
    literal = body.split('my %semantic = (', 1)[1].split('\n    );', 1)[0]
    required = set(re.findall(r'^        ([a-z_]+)\s*=>', literal, re.M))
    optional = set(re.findall(r'\$semantic\{([a-z_]+)\}\s*=', body))
    require(required == set(native['success_semantic_presence_keys']) and optional == set(native['success_semantic_optional_child_presence_keys']), 'source-derived required/optional allocation')
    require('explicit_system_contract => $explicit_system_contract' in literal and 'return (1, undef) unless defined $value;' in report, 'source-derived nullable preserved key')
    require('if defined $symbol_contract' in body and 'if defined $composition' in body and 'if defined $protocol_intent_bundle' in body, 'source optional availability conditions')
    builder = packet['builder']
    require(builder['path'] == BUILDER and sha(builder['text'].encode()) == builder['sha256'], 'builder identity')
    helper = 'docs/audits/mcp-api-reference-20261023/build_diagnostic_families.py'
    require(packet['helpers'] == previous['helpers'], 'producer helper closure')
    if current:
        require((ROOT / BUILDER).read_text() == builder['text'] and (ROOT / helper).read_text() == packet['helpers'][helper]['text'], 'current producer stale')
        require(packet['python'] == {'implementation': sys.implementation.name, 'version': list(sys.version_info)}, 'current runtime stale')
    require(set(packet['documents']) == {BOOK, POD} and packet['documents'][POD] == packet['sources'][POD], 'document/POD membership')
    for filename, marker in ((BOOK, '### Normalized payload and IR baseline families\n'), (POD, '=head2 Normalized payload and IR baseline families\n')):
        saved = packet['documents'][filename]
        require(sha(saved['text'].encode()) == saved['sha256'], 'document digest')
        if current:
            require((ROOT / filename).read_text() == saved['text'], 'current document stale')
        require(marker in saved['text'], 'missing baseline guide')
        guide = saved['text'].split(marker, 1)[1].split('\n### ' if filename == BOOK else '\n=head', 1)[0]
        for phrase in ('protocol_intent_bundle', 'explicit_system_contract', 'null', 'optional', 'not a closed schema'):
            require(phrase in guide, 'missing baseline distinction: ' + phrase)
        if filename == BOOK:
            require(all('`' + key + '`' in guide for key in selected if not key.endswith('_contract_source')), 'baseline family documentation coverage')
    return {'selected_fields': len(selected), 'remaining_fields': len(remaining),
            'source_required_children': sorted(required), 'source_optional_children': sorted(optional)}


def controls(packet, capture):
    results = {}
    for label in ('missing_field', 'wrong_subject', 'wrong_tier', 'mandatory_optional', 'nonnull_explicit',
                  'bucket_entry_swap', 'layer_keys_not_values', 'lost_remaining', 'wrong_owner', 'invented_owner_field',
                  'changed_source', 'changed_helper', 'missing_guide', 'stale_document'):
        bad = copy.deepcopy(packet)
        fields = bad['fields']
        if label == 'missing_field':
            fields.pop('success_module_optional_metric_keys')
        elif label == 'wrong_subject':
            fields['success_symbol_contract_presence_keys']['subject'] = 'semantic.module'
        elif label == 'wrong_tier':
            fields['success_forward_ir_intent_hir_presence_keys']['value'] = fields['success_forward_ir_lowered_rtl_ir_presence_keys']['value']
        elif label == 'mandatory_optional':
            fields['success_semantic_optional_child_presence_keys']['rule'] = 'success_base'
        elif label == 'nonnull_explicit':
            fields['success_explicit_system_contract_presence_keys']['rule'] = 'always_nonnull_object'
        elif label == 'bucket_entry_swap':
            fields['success_signal_analysis_entry_presence_keys']['value'] = fields['success_signal_analysis_presence_keys']['value']
        elif label == 'layer_keys_not_values':
            fields['public_layers']['subject'] = 'semantic.forward_ir'
        elif label == 'lost_remaining':
            bad['remaining_fields'].pop(next(iter(bad['remaining_fields'])))
        elif label == 'wrong_owner':
            fields['system_contract_source']['value'] = fields['explicit_system_contract_source']['value']
        elif label == 'invented_owner_field':
            fields['explicit_system_contract_contract_source'] = fields.pop('explicit_system_contract_source')
        else:
            saved = (bad['sources'][owner_path('Payload')] if label == 'changed_source' else
                     next(iter(bad['helpers'].values())) if label == 'changed_helper' else bad['documents'][BOOK])
            saved['text'] = saved['text'].replace('### Normalized payload and IR baseline families\n', '') if label == 'missing_guide' else saved['text'] + '\n# changed\n'
            saved['sha256'] = sha(saved['text'].encode())
        try:
            verify(bad, capture, current=label == 'stale_document')
        except (ValueError, KeyError) as error:
            results[label] = str(error)
        else:
            raise ValueError('Adverse control accepted: ' + label)
    return results


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('packet', type=Path)
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
