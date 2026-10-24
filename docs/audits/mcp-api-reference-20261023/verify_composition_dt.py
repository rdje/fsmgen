#!/usr/bin/env python3
"""Verify standalone-DT child subjects, container kinds and delegated families."""
import argparse
import copy
import gzip
import json
import re
import sys
from pathlib import Path

from verify_composition_overrides import verify as verify_overrides
from verify_composition_shallow import TableView, literal
from verify_error_context import source
from verify_model_roots import capture_check
from verify_normalized_symbols import body, returns
from verify_normalized_envelope import exact, require, sha

BASE = Path(__file__).resolve().parent
ROOT = BASE.parents[2]
OWNER = 'PERL-POD-API-REFERENCE.6.1.2.3.2.1.2.3.2.2.4.3'
BOOK = 'docs/book/src/11-extensions-and-embedding.md'
POD = 'perl/FSM/Support/CapabilityManifest.pm'
MARKER = 'Normalized composition standalone-DT children'
CONTEXTS = {
    'composition_standalone_dt_': 'semantic.composition.standalone_dt_children[]',
    'success_forward_ir_intent_hir_composition_standalone_dt_': 'semantic.forward_ir.intent_hir.composition_standalone_dt_children[]',
}
# Separate reviewed oracle: object versus element subjects are intentional.
ORACLE = {
    'child_entry_keys': ('', 'shallow_entry', ['instance_name', 'module_name', 'source_name', 'standalone_dt_count', 'standalone_dt_names', 'standalone_dt_enable_families', 'standalone_dt_module_enable_family', 'standalone_dt_multi_drive_target_count', 'standalone_dt_multi_drive_targets', 'intent_hir', 'lowered_rtl_ir', 'structural_rtl_ir']),
    'enable_family_entry_keys': ('.standalone_dt_enable_families[]', 'array_element', ['dt_name', 'enable_signal']),
    'module_enable_family_keys': ('.standalone_dt_module_enable_family', 'object', ['dt_names', 'enable_signals']),
    'multi_drive_target_entry_keys': ('.standalone_dt_multi_drive_targets[]', 'array_element', ['dt_enable_signals', 'dt_names', 'lhs_enable_signals', 'multi_drive_assertion', 'multiplexer_type', 'rhs_values', 'signal_name']),
    'multi_drive_assertion_keys': ('.standalone_dt_multi_drive_targets[].multi_drive_assertion', 'object', ['input_count', 'input_enable_signals', 'kind', 'target_signal']),
}


def read(name):
    return json.loads(gzip.decompress((BASE / name).read_bytes()))


def code(raw):
    return raw.split(b'\n__END__\n', 1)[0]


def verify(packet, capture, current=False, contracts_current=False):
    require(packet['schema'] == 'fsmgen.composition_dt_families.v1' and packet['owner'] == OWNER, 'packet identity')
    predecessor = read('composition-overrides-qualified.json.gz')
    verify_overrides(predecessor, capture)
    partition = read('normalized-composition-partition.json.gz')
    require(packet['inputs'] == {n: sha((BASE / n).read_bytes()) for n in ('normalized-composition-partition.json.gz', 'composition-overrides-qualified.json.gz')}, 'input identity')
    selected = {prefix + suffix for prefix in CONTEXTS for suffix in ORACLE}
    require(set(packet['fields']) == selected == set(partition['cohorts'][OWNER]), 'complete exact DT population')
    require(packet['remaining_composition'] == {k: v for k, v in predecessor['remaining_composition'].items() if k not in selected}, 'remaining composition conservation')
    require(packet['remaining_fields'] == predecessor['remaining_fields'], 'deeper delegation conservation')
    names = ('CapabilityManifest', 'SemanticExportsSection', 'NormalizedSemanticReportContract',
        'NormalizedSemanticPayloadContract', 'NormalizedSemanticForwardIRContract',
        'NormalizedSemanticIntentHIRContract', 'NormalizedSemanticCompositionContract', 'NormalizedSemanticLoweredRTLIRContract')
    paths = {'perl/FSM/Support/' + n + '.pm' for n in names} | {'perl/FSM/Composition/ChildExportBuilder.pm'}
    require(set(packet['sources']) == paths, 'source population')
    texts = {}
    for path, saved in packet['sources'].items():
        raw = saved['text'].encode()
        require(sha(raw) == saved['sha256'], 'source digest')
        original = source(capture, path)
        require(code(raw) == code(original), 'source runtime conservation')
        if path != POD:
            require(raw == original, 'dedicated source identity')
        if current:
            require((ROOT / path).read_bytes() == raw, 'current source stale')
        elif contracts_current:
            require(code((ROOT / path).read_bytes()) == code(raw), 'current contract/builder code stale')
        texts[Path(path).stem] = saved['text']
    native = capture['native_api']['manifest']['semantic_exports']['normalized_semantic_json']
    for prefix, root in CONTEXTS.items():
        for suffix, (relative, rule, keys) in ORACLE.items():
            key = prefix + suffix
            row = packet['fields'][key]
            require(set(row) == {'value', 'subject', 'rule', 'alias_owner', 'value_owner'}, 'field shape')
            require(row['subject'] == root + relative and row['rule'] == rule, 'exact DT subject/container')
            dedicated = 'NormalizedSemanticLoweredRTLIRContract' if suffix.startswith('multi_drive_') else 'NormalizedSemanticCompositionContract'
            require(row['alias_owner'] == 'FSM::Support::NormalizedSemanticCompositionContract'
                    and row['value_owner'] == 'FSM::Support::' + dedicated, 'exact DT owners')
            require(exact(row['value']) == exact(native[key]) == exact(keys), 'native/literal value/type/order')
            comp = 'normalized_semantic_composition_standalone_dt_' + suffix
            function = ('normalized_semantic_lowered_rtl_ir_standalone_dt_' + suffix if suffix.startswith('multi_drive_') else comp)
            require(literal(texts[dedicated], function) == keys, 'dedicated DT literal')
            if dedicated != 'NormalizedSemanticCompositionContract':
                returns(texts['NormalizedSemanticCompositionContract'], comp, function)
            semantic = key.removeprefix('success_')
            report = 'normalized_semantic_' + semantic
            payload = 'normalized_semantic_payload_' + semantic
            returns(texts['NormalizedSemanticReportContract'], report, payload)
            if prefix.startswith('success_'):
                hir = report.replace('_forward_ir', '', 1)
                returns(texts['NormalizedSemanticPayloadContract'], payload, report)
                returns(texts['NormalizedSemanticForwardIRContract'], report, hir)
                returns(texts['NormalizedSemanticIntentHIRContract'], hir, comp)
                require('composition_standalone_dt_children' in literal(texts['NormalizedSemanticIntentHIRContract'], 'normalized_semantic_intent_hir_optional_composition_keys'), 'optional flattened HIR membership')
            else:
                returns(texts['NormalizedSemanticPayloadContract'], payload, comp)
            factory = body(texts['NormalizedSemanticReportContract'], 'build_normalized_semantic_report_contract')
            require(re.search(r'\b' + re.escape(key) + r'\s*=>\s*' + re.escape(report) + r'\(\)', factory), 'factory field allocation')
    builder = texts['ChildExportBuilder'].split('\nsub build_standalone_dt_child_exports ', 1)[1].split('\nsub ', 1)[0]
    for pattern in (r'standalone_dt_enable_families\s*=>\s*\\@enable_families',
                    r'standalone_dt_multi_drive_targets\s*=>\s*\\@multi_drive_targets',
                    r'standalone_dt_module_enable_family\s*=>\s*\{\s*dt_names\s*=>\s*\[.*?enable_signals\s*=>\s*\[',
                    r'multi_drive_assertion\s*=>\s*\{\s*%\{\$assertion\},\s*input_enable_signals\s*=>\s*\['):
        require(re.search(pattern, builder, re.S), 'typed shallow-builder array/object source join')
    require('%{build_normalized_semantic_report_contract()}' in texts['SemanticExportsSection'], 'manifest republishing')
    require(set(packet['documents']) == {BOOK, POD} and packet['documents'][POD] == packet['sources'][POD], 'document population')
    for path, saved in packet['documents'].items():
        require(sha(saved['text'].encode()) == saved['sha256'], 'document digest')
        if current:
            require((ROOT / path).read_text() == saved['text'], 'current document stale')
        marker = ('### ' if path == BOOK else '=head2 ') + MARKER + '\n'
        require(marker in saved['text'], 'missing standalone-DT guide')
        guide = saved['text'].split(marker, 1)[1].split('\n### ' if path == BOOK else '\n=head', 1)[0]
        for phrase in ('multi_drive_assertion', 'module_enable_family', 'objects', 'arrays',
                       'parameter-override aliases', 'execution', 'arbitration', 'source availability'):
            require(phrase in guide, 'missing DT interpretation: ' + phrase)
        if path == BOOK:
            for prefix, root in CONTEXTS.items():
                require('| `' + prefix + '` | `' + root + '` |' in guide, 'exact documented DT context')
            for suffix, (relative, rule, keys) in ORACLE.items():
                displayed = relative[1:] if relative else '(child entry)'
                require('| `' + suffix + '` | `' + displayed + '` | ' + ', '.join('`' + k + '`' for k in keys) + ' |' in guide, 'exact documented DT subject/value')
    expected = {BASE.relative_to(ROOT).as_posix() + '/' + n for n in ('build_composition_dt.py', 'verify_composition_dt.py')}
    require(set(packet['instruments']) == expected, 'instrument population')
    for path, saved in packet['instruments'].items():
        require(sha(saved['text'].encode()) == saved['sha256'] and (ROOT / path).read_text() == saved['text'], 'instrument identity')
    if current:
        require(packet['python'] == {'implementation': sys.implementation.name, 'version': list(sys.version_info)}, 'current runtime stale')
    return {'selected_fields': len(selected), 'remaining_composition': len(packet['remaining_composition']),
        'remaining_fields': len(packet['remaining_fields']), 'limits': packet['limits']}


def controls(packet, capture):
    results = {}
    key = 'composition_standalone_dt_child_entry_keys'
    for label in ('omission', 'extra', 'wrong_tier', 'wrong_child_kind', 'module_as_array', 'assertion_as_array',
                  'wrong_alias_owner', 'wrong_target_owner', 'wrong_value', 'lost_deeper', 'source_change',
                  'instrument_change', 'missing_guide', 'stale_document'):
        bad = copy.deepcopy(packet)
        if label == 'omission':
            bad['fields'].pop(key)
        elif label == 'extra':
            bad['fields']['composition_standalone_dt_parameter_override_entry_keys'] = bad['fields'][key]
        elif label == 'wrong_tier':
            bad['fields'][key]['subject'] = CONTEXTS['success_forward_ir_intent_hir_composition_standalone_dt_']
        elif label == 'wrong_child_kind':
            bad['fields'][key]['subject'] = 'semantic.composition.generated_children[]'
        elif label in ('module_as_array', 'assertion_as_array'):
            field = 'composition_standalone_dt_' + ('module_enable_family_keys' if label == 'module_as_array' else 'multi_drive_assertion_keys')
            bad['fields'][field]['subject'] += '[]'
            bad['fields'][field]['rule'] = 'array_element'
        elif label == 'wrong_alias_owner':
            bad['fields'][key]['alias_owner'] = 'FSM::Support::NormalizedSemanticIntentHIRContract'
        elif label == 'wrong_target_owner':
            bad['fields']['composition_standalone_dt_multi_drive_target_entry_keys']['value_owner'] = 'FSM::Support::NormalizedSemanticCompositionContract'
        elif label == 'wrong_value':
            bad['fields'][key]['value'].append('parameter_overrides')
        elif label == 'lost_deeper':
            bad['remaining_fields'].pop(next(iter(bad['remaining_fields'])))
        else:
            saved = (bad['sources']['perl/FSM/Composition/ChildExportBuilder.pm'] if label == 'source_change' else
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


class DTView(TableView):
    def handle_starttag(self, tag, attrs):
        if tag == 'h3':
            self.active = dict(attrs).get('id') == 'normalized-composition-standalone-dt-children'
        else:
            super().handle_starttag(tag, attrs)


def rendered(build):
    book = (build / '11-extensions-and-embedding.html').read_bytes()
    pod = (build / 'perl-api/FSM/Support/CapabilityManifest.html').read_bytes()
    view = DTView()
    view.feed(book.decode())
    require(view.rows[1:3] == [[prefix, root] for prefix, root in CONTEXTS.items()], 'native DT context table')
    expected = [[suffix, relative[1:] if relative else '(child entry)', ', '.join(keys)] for suffix, (relative, rule, keys) in ORACLE.items()]
    require(view.rows[4:] == expected, 'native DT subject/key table')
    require(MARKER.encode() in pod and b'multi_drive_assertion' in pod, 'native DT POD guide')
    return {'book_sha256': sha(book), 'pod_sha256': sha(pod), 'rows': view.rows,
        'scope': 'Selected native rendered content only; no browser or whole-manual visual signoff.'}


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
