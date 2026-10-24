#!/usr/bin/env python3
"""Verify shallow composition subjects against saved native and literal contracts."""
import argparse
import copy
import gzip
from html.parser import HTMLParser
import json
import re
import sys
from pathlib import Path

from partition_normalized_composition import verify as verify_partition
from verify_error_context import source
from verify_model_roots import capture_check
from verify_normalized_symbols import body, returns
from verify_normalized_envelope import exact, require, sha

BASE = Path(__file__).resolve().parent
ROOT = BASE.parents[2]
OWNER = 'PERL-POD-API-REFERENCE.6.1.2.3.2.1.2.3.2.2.4.1'
BOOK = 'docs/book/src/11-extensions-and-embedding.md'
POD = 'perl/FSM/Support/CapabilityManifest.pm'
# Explicit reviewed subjects, independent of the producer's substring classifier.
ORACLE = {
    'composition_presence_keys': ('semantic.composition', 'normalized_semantic_composition_presence_keys'),
    'composition_child_entry_keys': ('semantic.composition.children[]', 'normalized_semantic_composition_child_entry_keys'),
    'composition_generated_child_entry_keys': ('semantic.composition.generated_children[]', 'normalized_semantic_composition_generated_child_entry_keys'),
    'success_forward_ir_intent_hir_composition_child_entry_keys': ('semantic.forward_ir.intent_hir.composition_children[]', 'normalized_semantic_composition_child_entry_keys'),
    'success_forward_ir_intent_hir_composition_generated_child_entry_keys': ('semantic.forward_ir.intent_hir.composition_generated_children[]', 'normalized_semantic_composition_generated_child_entry_keys'),
}
MARKER = 'Normalized composition envelope and shallow children'


def read(name):
    return json.loads(gzip.decompress((BASE / name).read_bytes()))


def literal(text, function):
    match = re.fullmatch(r'\s*return\s*\[\s*qw\((.*?)\)\s*,?\s*\]\s*;\s*', body(text, function), re.S)
    require(match is not None, 'literal family: ' + function)
    return match.group(1).split()


def verify(packet, capture, current=False):
    require(packet['schema'] == 'fsmgen.composition_shallow.v1' and packet['owner'] == OWNER, 'packet identity')
    partition = read('normalized-composition-partition.json.gz')
    verify_partition(partition)
    require(packet['partition_sha256'] == sha((BASE / 'normalized-composition-partition.json.gz').read_bytes()), 'partition identity')
    require(set(packet['fields']) == set(ORACLE) == set(partition['cohorts'][OWNER]), 'exact shallow population')
    require(packet['remaining_composition'] == {k: v for k, v in partition['selected_values'].items() if k not in ORACLE}, 'remaining composition conservation')
    require(packet['remaining_fields'] == partition['remaining_fields'], 'deeper delegation conservation')
    names = ('CapabilityManifest', 'SemanticExportsSection', 'NormalizedSemanticReportContract',
        'NormalizedSemanticPayloadContract', 'NormalizedSemanticForwardIRContract',
        'NormalizedSemanticIntentHIRContract', 'NormalizedSemanticCompositionContract')
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
    for key, (subject, function) in ORACLE.items():
        row = packet['fields'][key]
        require(set(row) == {'value', 'subject', 'function', 'owner'}, 'field shape')
        require((row['subject'], row['function']) == (subject, function), 'exact subject/function: ' + key)
        require(row['owner'] == 'FSM::Support::NormalizedSemanticCompositionContract', 'dedicated owner')
        require(exact(row['value']) == exact(native[key]) == exact(partition['selected_values'][key]), 'native value/type/order')
        require(row['value'] == literal(texts['NormalizedSemanticCompositionContract'], function), 'dedicated literal value')
        semantic_key = key.removeprefix('success_')
        report_function = 'normalized_semantic_' + semantic_key
        payload_function = 'normalized_semantic_payload_' + semantic_key
        if key == 'composition_presence_keys':
            report_function = 'normalized_semantic_composition_keys'
            payload_function = 'normalized_semantic_payload_composition_keys'
            returns(texts['NormalizedSemanticReportContract'], report_function, function)
            returns(texts['NormalizedSemanticPayloadContract'], payload_function, function)
        else:
            returns(texts['NormalizedSemanticReportContract'], report_function, payload_function)
            if key.startswith('success_'):
                forward_function = 'normalized_semantic_' + semantic_key
                hir_function = forward_function.replace('_forward_ir', '', 1)
                returns(texts['NormalizedSemanticPayloadContract'], payload_function, forward_function)
                returns(texts['NormalizedSemanticForwardIRContract'], forward_function, hir_function)
                returns(texts['NormalizedSemanticIntentHIRContract'], hir_function, function)
                collection = subject.rsplit('.', 1)[1][:-2]
                require(collection in literal(texts['NormalizedSemanticIntentHIRContract'], 'normalized_semantic_intent_hir_optional_composition_keys'), 'optional HIR collection membership')
            else:
                returns(texts['NormalizedSemanticPayloadContract'], payload_function, function)
        factory = body(texts['NormalizedSemanticReportContract'], 'build_normalized_semantic_report_contract')
        factory_function = payload_function if key == 'composition_presence_keys' else report_function
        require(re.search(r'\b' + re.escape(key) + r'\s*=>\s*' + re.escape(factory_function) + r'\(\)', factory), 'factory field allocation')
    require('%{build_normalized_semantic_report_contract()}' in texts['SemanticExportsSection'], 'manifest republishes report contract')
    require(set(packet['documents']) == {BOOK, POD} and packet['documents'][POD] == packet['sources'][POD], 'document population')
    for path, saved in packet['documents'].items():
        require(sha(saved['text'].encode()) == saved['sha256'], 'document digest')
        if current:
            require((ROOT / path).read_text() == saved['text'], 'current document stale')
        marker = ('### ' if path == BOOK else '=head2 ') + MARKER + '\n'
        require(marker in saved['text'], 'missing shallow composition guide')
        guide = saved['text'].split(marker, 1)[1].split('\n### ' if path == BOOK else '\n=head', 1)[0]
        for phrase in ('parameter_overrides', 'plan_snapshot', 'provenance_report', 'shallow',
                       'equal child populations', 'source availability', 'shared_datapath_candidates'):
            require(phrase in guide, 'missing interpretation: ' + phrase)
        if path == BOOK:
            for key, (subject, function) in ORACLE.items():
                require('| `' + key + '` | `' + subject + '` | `' + function + '` |' in guide, 'exact documented field row')
            for value in (native['composition_presence_keys'], native['composition_child_entry_keys']):
                require(', '.join('`' + key + '`' for key in value) in guide, 'complete documented literal list')
    expected = {BASE.relative_to(ROOT).as_posix() + '/' + n for n in ('build_composition_shallow.py', 'verify_composition_shallow.py')}
    require(set(packet['instruments']) == expected, 'instrument population')
    for path, saved in packet['instruments'].items():
        require(sha(saved['text'].encode()) == saved['sha256'] and (ROOT / path).read_text() == saved['text'], 'instrument identity')
    if current:
        require(packet['python'] == {'implementation': sys.implementation.name, 'version': list(sys.version_info)}, 'current runtime stale')
    return {'selected_fields': len(ORACLE), 'remaining_composition': len(packet['remaining_composition']), 'remaining_fields': len(packet['remaining_fields']), 'limits': packet['limits']}


def controls(packet, capture):
    results = {}
    key = 'composition_child_entry_keys'
    for label in ('omission', 'extra', 'wrong_tier', 'wrong_collection', 'wrong_owner', 'borrowed_function',
                  'wrong_value_order', 'lost_composition', 'lost_deeper', 'source_change', 'instrument_change', 'missing_guide', 'stale_document'):
        bad = copy.deepcopy(packet)
        if label == 'omission':
            bad['fields'].pop(key)
        elif label == 'extra':
            bad['fields']['invented'] = bad['fields'][key]
        elif label == 'wrong_tier':
            bad['fields'][key]['subject'] = ORACLE['success_forward_ir_intent_hir_composition_child_entry_keys'][0]
        elif label == 'wrong_collection':
            bad['fields'][key]['subject'] = ORACLE['composition_generated_child_entry_keys'][0]
        elif label == 'wrong_owner':
            bad['fields'][key]['owner'] = 'FSM::Support::NormalizedSemanticStructuralRTLIRContract'
        elif label == 'borrowed_function':
            bad['fields'][key]['function'] = ORACLE['composition_generated_child_entry_keys'][1]
        elif label == 'wrong_value_order':
            bad['fields'][key]['value'].reverse()
        elif label in ('lost_composition', 'lost_deeper'):
            values = bad['remaining_composition' if label == 'lost_composition' else 'remaining_fields']
            values.pop(next(iter(values)))
        else:
            saved = (bad['sources']['perl/FSM/Support/NormalizedSemanticCompositionContract.pm'] if label == 'source_change' else
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


class TableView(HTMLParser):
    def __init__(self):
        super().__init__()
        self.active = False
        self.rows = []
        self.row = None
        self.cell = None
        self.text = []

    def handle_starttag(self, tag, attrs):
        if tag == 'h3':
            self.active = dict(attrs).get('id') == 'normalized-composition-envelope-and-shallow-children'
        if self.active and tag == 'tr':
            self.row = []
        if self.active and tag in ('td', 'th'):
            self.cell = []

    def handle_data(self, value):
        if self.active:
            self.text.append(value)
            if self.cell is not None:
                self.cell.append(value)

    def handle_endtag(self, tag):
        if self.active and tag in ('td', 'th'):
            self.row.append(''.join(self.cell).strip())
            self.cell = None
        if self.active and tag == 'tr':
            self.rows.append(self.row)


def rendered(build, packet):
    view = TableView()
    book = (build / '11-extensions-and-embedding.html').read_bytes()
    pod = (build / 'perl-api/FSM/Support/CapabilityManifest.html').read_bytes()
    view.feed(book.decode())
    require(view.rows[1:] == [[key, row['subject'], row['function']] for key, row in packet['fields'].items()], 'native table exact rows/order')
    text = ' '.join(''.join(view.text).split())
    for key in ('composition_presence_keys', 'composition_child_entry_keys'):
        require(', '.join(packet['fields'][key]['value']) in text, 'native literal list')
    require(MARKER.encode() in pod and b'equal child populations' in pod, 'native POD guide')
    return {'book_sha256': sha(book), 'pod_sha256': sha(pod), 'rows': view.rows,
            'scope': 'Selected native rendered content only; no browser or whole-manual visual signoff.'}


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
