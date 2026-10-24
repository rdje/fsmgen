#!/usr/bin/env python3
"""Verify exact alias subjects, structural delegation and optional extensions."""
import argparse
import copy
import gzip
import json
import re
import sys
from pathlib import Path

from verify_composition_shallow import TableView, literal, verify as verify_shallow
from verify_error_context import source
from verify_model_roots import capture_check
from verify_normalized_symbols import body, returns
from verify_normalized_envelope import exact, require, sha

BASE = Path(__file__).resolve().parent
ROOT = BASE.parents[2]
OWNER = 'PERL-POD-API-REFERENCE.6.1.2.3.2.1.2.3.2.2.4.2'
BOOK = 'docs/book/src/11-extensions-and-embedding.md'
POD = 'perl/FSM/Support/CapabilityManifest.pm'
MARKER = 'Normalized composition parameter-override aliases'
# Independently enumerated payload contexts and allowed key lists. The source
# delegation oracle below distinguishes identical ordinary/generated values.
CONTEXTS = {
    'composition_child_parameter_override_': 'semantic.composition.children[].parameter_overrides[]',
    'composition_generated_child_parameter_override_': 'semantic.composition.generated_children[].parameter_overrides[]',
    'success_forward_ir_intent_hir_composition_child_parameter_override_': 'semantic.forward_ir.intent_hir.composition_children[].parameter_overrides[]',
    'success_forward_ir_intent_hir_composition_generated_child_parameter_override_': 'semantic.forward_ir.intent_hir.composition_generated_children[].parameter_overrides[]',
}
SHAPES = {
    'entry_keys': ['name', 'origin_kind', 'raw_value_ast', 'value_kind', 'value_payload', 'value_text'],
    'raw_value_extension_keys': ['raw_value'],
    'value_metadata_extension_keys': ['declaration_default_value_kind', 'declaration_default_value_width', 'value_type_spec', 'value_width'],
}


def read(name):
    return json.loads(gzip.decompress((BASE / name).read_bytes()))


def verify(packet, capture, current=False):
    require(packet['schema'] == 'fsmgen.composition_override_aliases.v1' and packet['owner'] == OWNER, 'packet identity')
    shallow = read('composition-shallow-qualified.json.gz')
    verify_shallow(shallow, capture)
    partition = read('normalized-composition-partition.json.gz')
    require(packet['inputs'] == {n: sha((BASE / n).read_bytes()) for n in ('normalized-composition-partition.json.gz', 'composition-shallow-qualified.json.gz')}, 'input identity')
    selected = {prefix + suffix for prefix in CONTEXTS for suffix in SHAPES}
    require(set(packet['fields']) == selected == set(partition['cohorts'][OWNER]), 'complete exact alias population')
    require(packet['remaining_composition'] == {k: v for k, v in shallow['remaining_composition'].items() if k not in selected}, 'remaining composition conservation')
    require(packet['remaining_fields'] == shallow['remaining_fields'], 'deeper delegation conservation')
    names = ('CapabilityManifest', 'SemanticExportsSection', 'NormalizedSemanticReportContract',
        'NormalizedSemanticPayloadContract', 'NormalizedSemanticForwardIRContract',
        'NormalizedSemanticIntentHIRContract', 'NormalizedSemanticCompositionContract', 'NormalizedSemanticStructuralRTLIRContract')
    require(set(packet['sources']) == {'perl/FSM/Support/' + n + '.pm' for n in names}, 'source population')
    texts = {}
    for path, saved in packet['sources'].items():
        raw = saved['text'].encode()
        require(sha(raw) == saved['sha256'], 'source digest')
        original = source(capture, path)
        require(raw.split(b'\n__END__\n', 1)[0] == original.split(b'\n__END__\n', 1)[0], 'source runtime conservation')
        if path != POD:
            require(raw == original, 'dedicated source identity')
        if current:
            require((ROOT / path).read_bytes() == raw, 'current source stale')
        texts[Path(path).stem] = saved['text']
    native = capture['native_api']['manifest']['semantic_exports']['normalized_semantic_json']
    for prefix, subject in CONTEXTS.items():
        for suffix, keys in SHAPES.items():
            key = prefix + suffix
            row = packet['fields'][key]
            require(set(row) == {'value', 'subject', 'rule', 'alias_owner', 'value_owner'}, 'field shape')
            require(row['subject'] == subject and row['rule'] == suffix, 'precise subject/extension rule')
            require(row['alias_owner'] == 'FSM::Support::NormalizedSemanticCompositionContract'
                    and row['value_owner'] == 'FSM::Support::NormalizedSemanticStructuralRTLIRContract', 'exact alias/value owners')
            require(exact(row['value']) == exact(native[key]) == exact(keys), 'native/literal value/type/order')
            comp = 'normalized_semantic_' + prefix.removeprefix('success_forward_ir_intent_hir_') + suffix
            structural = 'normalized_semantic_structural_rtl_ir_instance_parameter_override_' + suffix
            require(literal(texts['NormalizedSemanticStructuralRTLIRContract'], structural) == keys, 'dedicated structural literal')
            returns(texts['NormalizedSemanticCompositionContract'], comp, structural)
            semantic = key.removeprefix('success_')
            report = 'normalized_semantic_' + semantic
            payload = 'normalized_semantic_payload_' + semantic
            returns(texts['NormalizedSemanticReportContract'], report, payload)
            if prefix.startswith('success_'):
                hir = report.replace('_forward_ir', '', 1)
                returns(texts['NormalizedSemanticPayloadContract'], payload, report)
                returns(texts['NormalizedSemanticForwardIRContract'], report, hir)
                returns(texts['NormalizedSemanticIntentHIRContract'], hir, comp)
            else:
                returns(texts['NormalizedSemanticPayloadContract'], payload, comp)
            factory = body(texts['NormalizedSemanticReportContract'], 'build_normalized_semantic_report_contract')
            require(re.search(r'\b' + re.escape(key) + r'\s*=>\s*' + re.escape(report) + r'\(\)', factory), 'factory field allocation')
    guidance = texts['NormalizedSemanticStructuralRTLIRContract']
    require('optional authored-token metadata on parameter overrides where a single token survives validation' in guidance
            and 'optional resolved type, packed-width, and matched declaration-default metadata' in guidance, 'canonical optional extension meaning')
    require('%{build_normalized_semantic_report_contract()}' in texts['SemanticExportsSection'], 'manifest republishing')
    require(set(packet['documents']) == {BOOK, POD} and packet['documents'][POD] == packet['sources'][POD], 'document population')
    for path, saved in packet['documents'].items():
        require(sha(saved['text'].encode()) == saved['sha256'], 'document digest')
        if current:
            require((ROOT / path).read_text() == saved['text'], 'current document stale')
        marker = ('### ' if path == BOOK else '=head2 ') + MARKER + '\n'
        require(marker in saved['text'], 'missing override alias guide')
        guide = saved['text'].split(marker, 1)[1].split('\n### ' if path == BOOK else '\n=head', 1)[0]
        for phrase in ('single authored token', 'optional', 'resolver', 'declaration', 'raw_value_ast',
                       'not a complete', 'standalone-DT', 'source availability'):
            require(phrase in guide, 'missing alias interpretation: ' + phrase)
        if path == BOOK:
            for prefix, subject in CONTEXTS.items():
                require('| `' + prefix + '` | `' + subject + '` |' in guide, 'exact documented context')
            for suffix, keys in SHAPES.items():
                require('| `' + suffix + '` | ' + ', '.join('`' + key + '`' for key in keys) + ' |' in guide, 'exact documented shape/value')
    expected = {BASE.relative_to(ROOT).as_posix() + '/' + n for n in ('build_composition_overrides.py', 'verify_composition_overrides.py')}
    require(set(packet['instruments']) == expected, 'instrument population')
    for path, saved in packet['instruments'].items():
        require(sha(saved['text'].encode()) == saved['sha256'] and (ROOT / path).read_text() == saved['text'], 'instrument identity')
    if current:
        require(packet['python'] == {'implementation': sys.implementation.name, 'version': list(sys.version_info)}, 'current runtime stale')
    return {'selected_fields': len(selected), 'remaining_composition': len(packet['remaining_composition']), 'remaining_fields': len(packet['remaining_fields']), 'limits': packet['limits']}


def controls(packet, capture):
    results = {}
    key = 'composition_child_parameter_override_entry_keys'
    for label in ('omission', 'extra', 'wrong_tier', 'wrong_collection', 'optional_as_core', 'wrong_alias_owner',
                  'wrong_value_owner', 'wrong_value', 'lost_composition', 'lost_deeper', 'source_change', 'instrument_change', 'missing_guide', 'stale_document'):
        bad = copy.deepcopy(packet)
        if label == 'omission':
            bad['fields'].pop(key)
        elif label == 'extra':
            bad['fields']['invented'] = bad['fields'][key]
        elif label == 'wrong_tier':
            bad['fields'][key]['subject'] = CONTEXTS['success_forward_ir_intent_hir_composition_child_parameter_override_']
        elif label == 'wrong_collection':
            bad['fields'][key]['subject'] = CONTEXTS['composition_generated_child_parameter_override_']
        elif label == 'optional_as_core':
            bad['fields']['composition_child_parameter_override_raw_value_extension_keys']['rule'] = 'entry_keys'
        elif label == 'wrong_alias_owner':
            bad['fields'][key]['alias_owner'] = bad['fields'][key]['value_owner']
        elif label == 'wrong_value_owner':
            bad['fields'][key]['value_owner'] = bad['fields'][key]['alias_owner']
        elif label == 'wrong_value':
            bad['fields'][key]['value'].append('raw_value')
        elif label in ('lost_composition', 'lost_deeper'):
            value = bad['remaining_composition' if label == 'lost_composition' else 'remaining_fields']
            value.pop(next(iter(value)))
        else:
            saved = (bad['sources']['perl/FSM/Support/NormalizedSemanticStructuralRTLIRContract.pm'] if label == 'source_change' else
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


class OverrideView(TableView):
    def handle_starttag(self, tag, attrs):
        if tag == 'h3':
            self.active = dict(attrs).get('id') == 'normalized-composition-parameter-override-aliases'
        else:
            super().handle_starttag(tag, attrs)


def rendered(build, packet):
    book = (build / '11-extensions-and-embedding.html').read_bytes()
    pod = (build / 'perl-api/FSM/Support/CapabilityManifest.html').read_bytes()
    view = OverrideView()
    view.feed(book.decode())
    require(view.rows[1:5] == [[key, subject] for key, subject in CONTEXTS.items()], 'native context table')
    require(view.rows[6:] == [[suffix, ', '.join(keys), rule] for suffix, keys, rule in (
        ('entry_keys', SHAPES['entry_keys'], 'Core entry keys.'),
        ('raw_value_extension_keys', SHAPES['raw_value_extension_keys'], 'Optional authored-token extension.'),
        ('value_metadata_extension_keys', SHAPES['value_metadata_extension_keys'], 'Optional resolver/declaration metadata.'))], 'native shape table')
    require(MARKER.encode() in pod and b'single authored token' in pod, 'native POD guide')
    return {'book_sha256': sha(book), 'pod_sha256': sha(pod), 'rows': view.rows,
        'scope': 'Selected rendered content only; no browser or whole-manual visual signoff.'}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('packet', type=Path)
    parser.add_argument('--current', action='store_true')
    parser.add_argument('--build', type=Path)
    args = parser.parse_args()
    capture = read('model-roots-qualified.json.gz')
    capture_check(capture)
    packet = json.loads(gzip.decompress(args.packet.read_bytes()))
    result = verify(packet, capture, args.current)
    result['rejected_controls'] = controls(packet, capture)
    if args.build:
        result['rendered'] = rendered(args.build, packet)
    print(json.dumps(result, sort_keys=True))


if __name__ == '__main__':
    main()
