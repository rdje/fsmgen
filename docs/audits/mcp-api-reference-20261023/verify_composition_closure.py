#!/usr/bin/env python3
"""Qualify composition cohort conservation and selected grouped projections."""
import argparse
import copy
import gzip
import json
import re
import sys
from pathlib import Path

import verify_composition_shallow as shallow
import verify_composition_overrides as overrides
import verify_composition_dt as dt
from partition_normalized_composition import verify as verify_partition
from verify_error_context import source
from verify_model_roots import capture_check
from verify_normalized_symbols import body
from verify_normalized_envelope import exact, require, sha

BASE = Path(__file__).resolve().parent
ROOT = BASE.parents[2]
OWNER = 'PERL-POD-API-REFERENCE.6.1.2.3.2.1.2.3.2.2.4.4'
BOOK = 'docs/book/src/11-extensions-and-embedding.md'
POD = 'perl/FSM/Support/CapabilityManifest.pm'
MARKER = 'Normalized composition grouped lookups'
READERS = {'composition-shallow-qualified.json.gz': shallow,
           'composition-overrides-qualified.json.gz': overrides,
           'composition-dt-qualified.json.gz': dt}
INPUTS = {'model-roots-qualified.json.gz', 'normalized-composition-partition.json.gz'} | set(READERS)
INSTRUMENTS = {BASE.relative_to(ROOT).as_posix() + '/' + name for name in (
    'build_composition_closure.py', 'verify_composition_closure.py',
    'build_composition_shallow.py', 'verify_composition_shallow.py',
    'build_composition_overrides.py', 'verify_composition_overrides.py',
    'build_composition_dt.py', 'verify_composition_dt.py',
    'partition_normalized_composition.py', 'build_diagnostic_families.py',
    'verify_error_context.py', 'verify_model_roots.py',
    'verify_normalized_symbols.py', 'verify_normalized_envelope.py')}


def read(name):
    return json.loads(gzip.decompress((BASE / name).read_bytes()))


def allocation(text, key, function):
    require(re.search(r'\b' + re.escape(key) + r'\s*=>\s*' + re.escape(function) + r'\(\)', text),
            'exact grouped source allocation: ' + key)


def verify(packet, capture, current=False, contracts_current=False):
    require(packet['schema'] == 'fsmgen.composition_closure.v1' and packet['owner'] == OWNER, 'closure identity')
    require(packet['inputs'] == {name: sha((BASE / name).read_bytes()) for name in INPUTS}, 'input identity')
    partition = read('normalized-composition-partition.json.gz')
    verify_partition(partition)
    require(set(packet['cohorts']) == set(READERS), 'complete cohort population')
    originals = {name: read(name) for name in READERS}
    require(set(packet['sources']) == {path for old in originals.values() for path in old['sources']}, 'complete source population')
    require(set(packet['documents']) == {BOOK, POD} and packet['documents'][POD] == packet['sources'][POD], 'document population/POD join')
    texts = {}
    for path, saved in packet['sources'].items():
        raw = saved['text'].encode()
        require(sha(raw) == saved['sha256'], 'source digest')
        require(dt.code(raw) == dt.code(source(capture, path)), 'original runtime source conservation')
        if path != POD:
            require(raw == source(capture, path), 'dedicated source identity')
        if current:
            require((ROOT / path).read_bytes() == raw, 'current source stale')
        elif contracts_current:
            require(dt.code((ROOT / path).read_bytes()) == dt.code(raw), 'current code stale')
        texts[Path(path).stem] = saved['text']
    fields = {}
    for name, reader in READERS.items():
        old = originals[name]
        reader.verify(old, capture)  # Old snapshots retain their own dated qualification.
        expected = copy.deepcopy(old)
        expected['sources'][POD] = packet['sources'][POD]
        expected['documents'] = packet['documents']
        expected['python'] = packet['python']
        fresh = packet['cohorts'][name]
        require(exact(fresh) == exact(expected), 'only declared comparison-view replacements: ' + name)
        reader.verify(fresh, capture, current=current)
        require(not (set(fields) & set(fresh['fields'])), 'disjoint cohorts')
        fields.update({key: {'cohort': name, **row} for key, row in fresh['fields'].items()})
    require(exact(packet['fields']) == exact(fields), 'complete field/subject/owner conservation')
    require(set(fields) == set(partition['selected_values']), 'exact composition partition union')
    require(packet['remaining_composition'] == {}, 'no unallocated composition fields')
    require(exact(packet['remaining_fields']) == exact(partition['remaining_fields']), 'deeper delegation conservation')
    native = capture['native_api']['manifest']['semantic_exports']['normalized_semantic_json']
    report_keys = set(fields)
    semantic_keys = {key.removeprefix('success_') for key in report_keys} - {'composition_presence_keys'}
    expected_groups = {
        'presence_key_family_map': {key: native['presence_key_family_map'][key] for key in report_keys},
        'semantic_presence_key_family_map': {key: native['semantic_presence_key_family_map'][key] for key in semantic_keys}}
    require(exact(packet['grouped']) == exact(expected_groups), 'exact grouped membership/value/type/order')
    require('composition_presence_keys' not in native['semantic_presence_key_family_map'], 'original semantic envelope absence')
    report_map = body(texts['NormalizedSemanticReportContract'], 'normalized_semantic_presence_key_family_map')
    semantic_map = body(texts['NormalizedSemanticPayloadContract'], 'normalized_semantic_payload_presence_key_family_map')
    factory = body(texts['NormalizedSemanticReportContract'], 'build_normalized_semantic_report_contract')
    allocation(factory, 'presence_key_family_map', 'normalized_semantic_presence_key_family_map')
    allocation(factory, 'semantic_presence_key_family_map', 'normalized_semantic_payload_presence_key_family_map')
    require(not re.search(r'\bcomposition_presence_keys\s*=>', semantic_map), 'source semantic envelope absence')
    for key, row in fields.items():
        require(exact(row['value']) == exact(partition['selected_values'][key]) == exact(native[key]), 'exact native selected values')
        require(exact(packet['grouped']['presence_key_family_map'][key]) == exact(row['value']), 'report grouped value join')
        semantic = key.removeprefix('success_')
        report_function = ('normalized_semantic_composition_keys' if key == 'composition_presence_keys'
                           else 'normalized_semantic_' + semantic)
        allocation(report_map, key, report_function)
        if key != 'composition_presence_keys':
            require(exact(packet['grouped']['semantic_presence_key_family_map'][semantic]) == exact(row['value']), 'semantic grouped value join')
            allocation(semantic_map, semantic, 'normalized_semantic_payload_' + semantic)
    for path, saved in packet['documents'].items():
        require(sha(saved['text'].encode()) == saved['sha256'], 'document digest')
        if current:
            require((ROOT / path).read_text() == saved['text'], 'current document stale')
        marker = ('### ' if path == BOOK else '=head2 ') + MARKER + '\n'
        require(marker in saved['text'], 'missing grouped composition guide')
        guide = saved['text'].split(marker, 1)[1].split('\n### ' if path == BOOK else '\n=head', 1)[0]
        for phrase in ('semantic_presence_key_family_map', 'presence_key_family_map', 'composition_presence_keys',
                       'success_', 'omits', 'broader', 'source availability'):
            require(phrase in guide, 'missing grouped interpretation: ' + phrase)
        if path == BOOK:
            require('| `composition_presence_keys` | absent |' in guide, 'documented exact envelope absence')
            for report, semantic in (
                ('composition_child_entry_keys', 'composition_child_entry_keys'),
                ('success_forward_ir_intent_hir_composition_child_entry_keys', 'forward_ir_intent_hir_composition_child_entry_keys')):
                require('| `' + report + '` | `' + semantic + '` |' in guide, 'documented grouped lookup example')
    require(set(packet['instruments']) == INSTRUMENTS, 'instrument population')
    for path, saved in packet['instruments'].items():
        require(sha(saved['text'].encode()) == saved['sha256'] and (ROOT / path).read_text() == saved['text'], 'instrument identity')
    if current:
        require(packet['python'] == {'implementation': sys.implementation.name, 'version': list(sys.version_info)}, 'current runtime stale')
    return {'cohort_fields': {name: len(value['fields']) for name, value in originals.items()},
        'selected_fields': len(fields), 'selected_grouped_entries': {key: len(value) for key, value in expected_groups.items()},
        'remaining_fields': len(packet['remaining_fields']), 'limits': packet['limits']}


def controls(packet, capture):
    results = {}
    key = 'composition_child_entry_keys'
    name = 'composition-shallow-qualified.json.gz'
    for label in ('lost_cohort', 'lost_field', 'extra_field', 'wrong_subject', 'wrong_owner',
                  'wrong_order', 'lost_deeper', 'wrong_report_map', 'wrong_semantic_key',
                  'invented_semantic_envelope', 'input_identity', 'source_change',
                  'instrument_loss', 'missing_cohort_guide', 'missing_grouped_guide', 'stale_document'):
        bad = copy.deepcopy(packet)
        if label == 'lost_cohort':
            bad['cohorts'].pop(name)
        elif label == 'lost_field':
            bad['fields'].pop(key)
        elif label == 'extra_field':
            bad['fields']['invented'] = bad['fields'][key]
        elif label in ('wrong_subject', 'wrong_owner', 'wrong_order'):
            row = bad['cohorts'][name]['fields'][key]
            if label == 'wrong_subject':
                row['subject'] = 'semantic.composition.generated_children[]'
            elif label == 'wrong_owner':
                row['owner'] = 'FSM::Support::NormalizedSemanticStructuralRTLIRContract'
            else:
                row['value'].reverse()
            bad['fields'][key] = {'cohort': name, **row}
        elif label == 'lost_deeper':
            bad['remaining_fields'].pop(next(iter(bad['remaining_fields'])))
        elif label == 'wrong_report_map':
            bad['grouped']['presence_key_family_map'][key].reverse()
        elif label == 'wrong_semantic_key':
            group = bad['grouped']['semantic_presence_key_family_map']
            group['success_forward_ir_intent_hir_composition_child_entry_keys'] = group.pop('forward_ir_intent_hir_composition_child_entry_keys')
        elif label == 'invented_semantic_envelope':
            bad['grouped']['semantic_presence_key_family_map']['composition_presence_keys'] = bad['fields']['composition_presence_keys']['value']
        elif label == 'input_identity':
            bad['inputs'][name] = '0' * 64
        elif label == 'instrument_loss':
            bad['instruments'].pop(next(iter(bad['instruments'])))
        else:
            if label == 'source_change':
                saved = bad['sources']['perl/FSM/Composition/ChildExportBuilder.pm']
                saved['text'] = saved['text'].replace('standalone_dt_enable_families => \\@enable_families', 'standalone_dt_enable_families => {}')
            else:
                saved = bad['documents'][BOOK]
                marker = shallow.MARKER if label == 'missing_cohort_guide' else MARKER
                saved['text'] = (saved['text'].replace('### ' + marker + '\n', '')
                                 if label.startswith('missing_') else saved['text'] + '\nchanged\n')
            saved['sha256'] = sha(saved['text'].encode())
            if label != 'source_change':
                # Keep refreshed views coherent so these controls reach the
                # actual guide/current-document checks, not a view mismatch.
                for cohort in bad['cohorts'].values():
                    cohort['documents'][BOOK] = copy.deepcopy(saved)
        try:
            verify(bad, capture, current=label == 'stale_document')
        except ValueError as error:
            results[label] = str(error)
        else:
            raise ValueError('Accepted counterfeit: ' + label)
    return results


class GroupedView(shallow.TableView):
    def handle_starttag(self, tag, attrs):
        if tag == 'h3':
            self.active = dict(attrs).get('id') == 'normalized-composition-grouped-lookups'
        else:
            super().handle_starttag(tag, attrs)


def rendered(build, packet):
    rows = {name: reader.rendered(build, packet['cohorts'][name]) if reader is not dt else dt.rendered(build)
            for name, reader in READERS.items()}
    book = (build / '11-extensions-and-embedding.html').read_bytes()
    pod = (build / 'perl-api/FSM/Support/CapabilityManifest.html').read_bytes()
    require(MARKER.encode() in book and MARKER.encode() in pod, 'native grouped guide')
    view = GroupedView()
    view.feed(book.decode())
    require(view.rows[1:] == [
        ['composition_presence_keys', 'absent'],
        ['composition_child_entry_keys', 'composition_child_entry_keys'],
        ['success_forward_ir_intent_hir_composition_child_entry_keys', 'forward_ir_intent_hir_composition_child_entry_keys']],
        'native exact grouped membership examples')
    return {'cohorts': rows, 'grouped_rows': view.rows, 'book_sha256': sha(book), 'pod_sha256': sha(pod),
            'scope': 'Selected rendered content; broader browser/whole-manual review stays open.'}


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
        result['rendered'] = rendered(args.build, packet)
    print(json.dumps(result, sort_keys=True))


if __name__ == '__main__':
    main()
