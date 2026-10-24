#!/usr/bin/env python3
"""Independently verify symbol subjects, kinds, delegations and grouped forms."""
import argparse
import copy
import gzip
import json
import re
import sys
from pathlib import Path

from verify_normalized_envelope import exact, read, require, sha
from verify_error_context import source
from verify_model_roots import capture_check
from verify_normalized_baseline_closure import verify as verify_predecessor

ROOT = Path(__file__).resolve().parents[3]
BASE = Path(__file__).resolve().parent
OWNER = 'PERL-POD-API-REFERENCE.6.1.2.3.2.1.2.3.2.2.3'
BOOK = 'docs/book/src/11-extensions-and-embedding.md'
POD = 'perl/FSM/Support/CapabilityManifest.pm'
# Deliberately separate from the producer: each source family has an exact
# payload subject and a key/value/extension interpretation.
ORACLE = {
    'constant_value_entry_keys': ('constants.<name>', 'core_keys'),
    'constant_scalar_value_extension_keys': ('constants.<name>', 'scalar_extension'),
    'constant_list_value_extension_keys': ('constants.<name>', 'list_extension'),
    'enum_entry_value_kinds': ('enums.<name>', 'value_kinds'),
    'enum_member_value_kinds': ('enums.<name>.<member>', 'value_kinds'),
    'type_entry_keys': ('types.<name>', 'recursive_core_keys'),
    'type_scalar_value_kinds': ('types.<name>', 'scalar_kinds'),
    'type_aggregate_value_kinds': ('types.<name>', 'aggregate_kinds'),
    'type_state_model_extension_keys': ('types.<name>', 'scalar_state_extension'),
    'type_list_extension_keys': ('types.<name>', 'recursive_list_extension'),
    'type_record_extension_keys': ('types.<name>', 'recursive_record_extension'),
    'package_import_entry_value_kinds': ('package_imports[]', 'value_kinds'),
    'package_import_entry_value_meaning': ('package_imports[]', 'scalar_meaning'),
}


def body(text, name):
    parts = text.split('\nsub ' + name + ' {', 1)
    require(len(parts) == 2, 'missing public function: ' + name)
    return parts[1].split('\n}', 1)[0]


def returns(text, caller, callee):
    require(re.fullmatch(r'\s*return\s+' + re.escape(callee) + r'\(\);\s*', body(text, caller)),
            'public family delegation: ' + caller)


def verify(packet, capture, current=False, documents=True):
    require(packet['schema'] == 'fsmgen.normalized_symbol_families.v1' and packet['owner'] == OWNER, 'packet identity')
    require(packet['capture_sha256'] == sha((BASE / 'model-roots-qualified.json.gz').read_bytes())
            and packet['capture_head'] == capture['head'], 'native capture identity')
    predecessor = read('normalized-baseline-current-qualified.json.gz')
    verify_predecessor(predecessor, capture)
    require(packet['predecessor_sha256'] == sha((BASE / 'normalized-baseline-current-qualified.json.gz').read_bytes())
            and packet['predecessor_fields'] == predecessor['baseline']['remaining_fields'], 'predecessor identity/delegations')
    roots = {'symbol_contract_': 'semantic.symbol_contract',
        'success_forward_ir_intent_hir_symbol_contract_': 'semantic.forward_ir.intent_hir.symbol_contract'}
    selected = {p + suffix for p in roots for suffix in ORACLE}
    require(set(packet['fields']) == selected and selected <= set(packet['predecessor_fields']), 'complete selected population')
    require(packet['remaining_fields'] == {k: v for k, v in packet['predecessor_fields'].items() if k not in selected}, 'complete remaining delegation')
    names = ('CapabilityManifest', 'SemanticExportsSection', 'NormalizedSemanticReportContract',
        'NormalizedSemanticPayloadContract', 'NormalizedSemanticForwardIRContract',
        'NormalizedSemanticIntentHIRContract', 'NormalizedSemanticSymbolContract')
    paths = {'perl/FSM/Support/' + n + '.pm' for n in names}
    require(set(packet['sources']) == paths, 'complete source population')
    texts = {}
    for path, saved in packet['sources'].items():
        require(sha(saved['text'].encode()) == saved['sha256'], 'source digest')
        original = source(capture, path)
        require(saved['text'].encode().split(b'\n__END__\n', 1)[0] == original.split(b'\n__END__\n', 1)[0], 'source runtime conservation')
        if path != POD:
            require(saved['text'].encode() == original, 'dedicated source identity')
        if current:
            require((ROOT / path).read_text() == saved['text'], 'current source stale')
        texts[Path(path).stem] = saved['text']
    native = capture['native_api']['manifest']['semantic_exports']['normalized_semantic_json']
    for prefix, root in roots.items():
        for suffix, (subject, rule) in ORACLE.items():
            key = prefix + suffix
            row = packet['fields'][key]
            semantic_key = key.removeprefix('success_')
            require(set(row) == {'value', 'subject', 'rule', 'owner', 'presence_map_value', 'semantic_map_key', 'semantic_map_value'}, 'field record shape')
            require(row['subject'] == root + '.' + subject and row['rule'] == rule, 'precise subject/rule: ' + key)
            require(row['owner'] == 'FSM::Support::NormalizedSemanticSymbolContract', 'dedicated symbol owner')
            require(exact(row['value']) == exact(native[key]), 'complete native value/type/order: ' + key)
            function = 'normalized_semantic_symbol_contract_' + suffix
            literal = body(texts['NormalizedSemanticSymbolContract'], function)
            match = re.fullmatch(r'\s*return\s*\[\s*qw\((.*?)\)\s*,?\s*\]\s*;\s*', literal, re.S)
            if rule == 'scalar_meaning':
                match = re.fullmatch(r"\s*return\s*'([^']+)'\s*;\s*", literal)
                require(match is not None and row['value'] == match.group(1), 'scalar literal meaning')
            else:
                require(match is not None and row['value'] == match.group(1).split(), 'dedicated literal family')
            grouped = [row['value']] if rule == 'scalar_meaning' else row['value']
            require(row['semantic_map_key'] == semantic_key
                    and exact(row['presence_map_value']) == exact(native['presence_key_family_map'][key]) == exact(grouped)
                    and exact(row['semantic_map_value']) == exact(native['semantic_presence_key_family_map'][semantic_key]) == exact(grouped), 'both grouped projections')
            # Source-level public delegation separates identical list values
            # from accidental borrowing of an unrelated field family.
            payload_function = 'normalized_semantic_payload_' + semantic_key
            report_function = 'normalized_semantic_' + semantic_key
            returns(texts['NormalizedSemanticReportContract'], report_function, payload_function)
            if prefix == 'symbol_contract_':
                returns(texts['NormalizedSemanticPayloadContract'], payload_function, function)
            else:
                forward_function = 'normalized_semantic_' + semantic_key
                hir_function = 'normalized_semantic_intent_hir_symbol_contract_' + suffix
                returns(texts['NormalizedSemanticPayloadContract'], payload_function, forward_function)
                returns(texts['NormalizedSemanticForwardIRContract'], forward_function, hir_function)
                returns(texts['NormalizedSemanticIntentHIRContract'], hir_function, function)
            top = body(texts['NormalizedSemanticReportContract'], 'build_normalized_semantic_report_contract')
            require(re.search(r'\b' + re.escape(key) + r'\s*=>\s*' + re.escape(report_function) + r'\(\)', top), 'factory field/function allocation')
            grouped_source = body(texts['NormalizedSemanticReportContract'], 'normalized_semantic_presence_key_family_map')
            call = re.escape(report_function) + r'\(\)'
            if rule == 'scalar_meaning':
                call = r'\[\s*' + call + r'\s*\]'
            require(re.search(r'\b' + re.escape(key) + r'\s*=>\s*' + call + r'\s*,', grouped_source), 'grouped scalar/list source allocation')
    require('%{build_normalized_semantic_report_contract()}' in texts['SemanticExportsSection']
            and 'normalized_semantic_json => build_manifest_normalized_semantic_json_surface()' in texts['SemanticExportsSection'], 'manifest republishes report contract')
    require(set(packet['documents']) == {BOOK, POD} and packet['documents'][POD] == packet['sources'][POD], 'document/POD membership')
    for path, saved in packet['documents'].items():
        require(sha(saved['text'].encode()) == saved['sha256'], 'document digest')
        if current:
            require((ROOT / path).read_text() == saved['text'], 'current document stale')
        if documents:
            marker = ('### Normalized symbol family subjects\n' if path == BOOK else '=head2 Normalized symbol family subjects\n')
            require(marker in saved['text'], 'missing symbol guide')
            guide = saved['text'].split(marker, 1)[1].split('\n### ' if path == BOOK else '\n=head', 1)[0]
            for phrase in ('member_payload_map', 'scalar_payload', 'state_model', 'member_order',
                           'scalar_package_name', 'single-element arrays', 'dynamic', 'not a closed schema'):
                require(phrase in guide, 'missing symbol distinction: ' + phrase)
            if path == BOOK:
                require(all('`' + suffix + '`' in guide for suffix in ORACLE), 'complete suffix documentation')
                require(all('`' + prefix + '`' in guide for prefix in roots), 'both metadata prefixes documented')
    expected = {BASE.relative_to(ROOT).as_posix() + '/' + n for n in ('build_normalized_symbols.py', 'verify_normalized_symbols.py')}
    require(set(packet['instruments']) == expected, 'producer/reader population')
    for path, saved in packet['instruments'].items():
        require(sha(saved['text'].encode()) == saved['sha256'] and (ROOT / path).read_text() == saved['text'], 'instrument identity/freshness')
    if current:
        require(packet['python'] == {'implementation': sys.implementation.name, 'version': list(sys.version_info)}, 'current runtime stale')
    return {'selected_fields': len(selected), 'remaining_fields': len(packet['remaining_fields']),
        'subjects': sorted(roots.values()), 'limits': packet['limits']}


def controls(packet, capture):
    results = {}
    key = 'symbol_contract_package_import_entry_value_meaning'
    for label in ('omission', 'extra', 'wrong_tier', 'keys_not_values', 'wrong_owner', 'borrowed_value',
                  'meaning_array', 'grouped_scalar', 'wrong_group_key', 'lost_delegation',
                  'source_change', 'instrument_change', 'missing_guide', 'stale_document'):
        bad = copy.deepcopy(packet)
        fields = bad['fields']
        if label == 'omission':
            fields.pop(next(iter(fields)))
        elif label == 'extra':
            fields['invented_symbol_keys'] = fields[key]
        elif label == 'wrong_tier':
            fields[key]['subject'] = 'semantic.forward_ir.lowered_rtl_ir.symbol_contract.package_imports[]'
        elif label == 'keys_not_values':
            fields['symbol_contract_enum_entry_value_kinds']['rule'] = 'core_keys'
        elif label == 'wrong_owner':
            fields[key]['owner'] = 'FSM::Support::NormalizedSemanticModuleContract'
        elif label == 'borrowed_value':
            fields['symbol_contract_type_list_extension_keys']['value'] = ['payload']
        elif label == 'meaning_array':
            fields[key]['value'] = [fields[key]['value']]
        elif label == 'grouped_scalar':
            fields[key]['presence_map_value'] = fields[key]['value']
        elif label == 'wrong_group_key':
            fields[key]['semantic_map_key'] = 'forward_ir_intent_hir_' + key
        elif label == 'lost_delegation':
            bad['remaining_fields'].pop(next(iter(bad['remaining_fields'])))
        else:
            saved = (bad['sources']['perl/FSM/Support/NormalizedSemanticSymbolContract.pm'] if label == 'source_change' else
                     next(iter(bad['instruments'].values())) if label == 'instrument_change' else bad['documents'][BOOK])
            saved['text'] = (saved['text'].replace('### Normalized symbol family subjects\n', '')
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
