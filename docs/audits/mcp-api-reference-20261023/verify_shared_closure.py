#!/usr/bin/env python3
"""Qualify shared cohorts, current canonical origins and selected grouped maps."""
import argparse
import copy
import gzip
import json
from pathlib import Path
import re
import sys

import verify_shared_candidate as candidate
import verify_shared_drive as drive
import verify_shared_aggregate as aggregate
from verify_composition_shallow import TableView
from verify_composition_dt import code
from verify_error_context import source
from verify_model_roots import capture_check
from verify_normalized_symbols import body
from verify_normalized_envelope import exact, require, sha
from partition_shared_datapath import verify as verify_partition

BASE = Path(__file__).resolve().parent
ROOT = BASE.parents[2]
OWNER = 'PERL-POD-API-REFERENCE.6.1.2.3.2.1.2.3.2.2.5.5'
API = 'docs/book/src/11a-perl-api-reference.md'
CORE = 'docs/book/src/11-extensions-and-embedding.md'
POD = 'perl/FSM/Support/CapabilityManifest.pm'
MARKER = 'Normalized shared-datapath grouped lookups'
READERS = {'shared-candidate-qualified.json.gz': candidate,
           'shared-drive-final-qualified.json.gz': drive,
           'shared-aggregate-qualified.json.gz': aggregate}
INPUTS = {'shared-datapath-partition.json.gz', 'model-roots-qualified.json.gz'} | set(READERS)
INSTRUMENTS = {BASE.relative_to(ROOT).as_posix() + '/' + name for name in
               ('build_shared_closure.py', 'verify_shared_closure.py')}
EXAMPLES = (
    ('composition_shared_datapath_candidate_entry_keys', 'composition_shared_datapath_candidate_entry_keys'),
    ('success_forward_ir_lowered_rtl_ir_composition_shared_datapath_assertion_keys', 'forward_ir_lowered_rtl_ir_composition_shared_datapath_assertion_keys'))


def read(name):
    return json.loads(gzip.decompress((BASE / name).read_bytes()))


def expected_view(original, packet):
    view = copy.deepcopy(original)
    logical = API if API in original['documents'] else CORE
    view['documents'] = {logical: packet['documents'][API], POD: packet['documents'][POD]}
    view['sources'][POD] = packet['documents'][POD]
    view['python'] = packet['python']
    return view


def allocation(text, key, function):
    require(re.search(r'\b' + re.escape(key) + r'\s*=>\s*' + re.escape(function) + r'\(\)', text),
            'exact shared grouped source allocation: ' + key)


def verify(packet, capture, current=False, contracts_current=False):
    require(packet['schema'] == 'fsmgen.shared_closure.v1' and packet['owner'] == OWNER, 'closure identity')
    require(packet['inputs'] == {name: sha((BASE / name).read_bytes()) for name in INPUTS}, 'input identity')
    partition = read('shared-datapath-partition.json.gz')
    verify_partition(partition)
    originals = {name: read(name) for name in READERS}
    require(set(packet['cohorts']) == set(READERS) == set(packet['comparison_roles']), 'complete shared cohorts/roles')
    require(set(packet['sources']) == {path for old in originals.values() for path in old['sources']}, 'complete shared sources')
    require(set(packet['documents']) == {API, CORE, POD} and packet['documents'][POD] == packet['sources'][POD], 'actual canonical document population')
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
    for path, saved in packet['documents'].items():
        require(sha(saved['text'].encode()) == saved['sha256'], 'document digest')
        if current:
            require((ROOT / path).read_bytes() == saved['text'].encode(), 'current canonical document stale')
    fields = {}
    for name, reader in READERS.items():
        original = originals[name]
        reader.verify(original, capture)  # Authenticate the unmodified dated evidence first.
        logical = API if API in original['documents'] else CORE
        require(packet['comparison_roles'][name] == {'mode': 'saved-only', 'kind': 'derived_semantic_comparison',
            'actual_source': API, 'logical_path': logical, 'sha256': packet['documents'][API]['sha256']}, 'explicit canonical comparison origin and saved-only role')
        view = packet['cohorts'][name]
        require(exact(view) == exact(expected_view(original, packet)), 'only declared source/doc/runtime view replacements')
        reader.verify(view, capture)  # Live currency is proved against actual paths above.
        require(not (set(fields) & set(view['fields'])), 'disjoint shared cohorts')
        fields.update({key: {'cohort': name, **row} for key, row in view['fields'].items()})
        anchor = reader.MARKER.lower().replace(' ', '-')
        if logical == CORE:
            stub = '### ' + reader.MARKER + '\n\nSee the [canonical field reference](' + Path(API).name + '#' + anchor + ').'
            require(stub in packet['documents'][CORE]['text'], 'actual compatibility route')
    require(exact(packet['fields']) == exact(fields), 'complete shared field/subject/owner union')
    require(set(fields) == set(partition['selected_values']), 'exact shared partition union')
    require(packet['remaining_shared'] == {}, 'no unallocated shared fields')
    require(exact(packet['remaining_fields']) == exact(partition['remaining_fields']), 'complete deeper delegation conservation')
    native = capture['native_api']['manifest']['semantic_exports']['normalized_semantic_json']
    report_keys = set(fields)
    semantic_keys = {key.removeprefix('success_') for key in fields}
    groups = {
        'presence_key_family_map': {key: native['presence_key_family_map'][key] for key in report_keys},
        'semantic_presence_key_family_map': {key: native['semantic_presence_key_family_map'][key] for key in semantic_keys}}
    require(exact(packet['grouped']) == exact(groups), 'exact shared grouped membership/value/type/order')
    report_map = body(texts['NormalizedSemanticReportContract'], 'normalized_semantic_presence_key_family_map')
    semantic_map = body(texts['NormalizedSemanticPayloadContract'], 'normalized_semantic_payload_presence_key_family_map')
    factory = body(texts['NormalizedSemanticReportContract'], 'build_normalized_semantic_report_contract')
    allocation(factory, 'presence_key_family_map', 'normalized_semantic_presence_key_family_map')
    allocation(factory, 'semantic_presence_key_family_map', 'normalized_semantic_payload_presence_key_family_map')
    for key, row in fields.items():
        semantic = key.removeprefix('success_')
        require(exact(row['value']) == exact(partition['selected_values'][key]) == exact(native[key]), 'exact shared native values')
        require(exact(groups['presence_key_family_map'][key]) == exact(row['value'])
                == exact(groups['semantic_presence_key_family_map'][semantic]), 'shared selected grouped value join')
        allocation(report_map, key, 'normalized_semantic_' + semantic)
        allocation(semantic_map, semantic, 'normalized_semantic_payload_' + semantic)
    for path in (API, POD):
        text = packet['documents'][path]['text']
        marker = ('### ' if path == API else '=head2 ') + MARKER + '\n'
        require(marker in text, 'missing shared grouped guide')
        guide = text.split(marker, 1)[1].split('\n### ' if path == API else '\n=head', 1)[0]
        for phrase in ('presence_key_family_map', 'semantic_presence_key_family_map', 'success_',
                       'optional', 'signal_ref', 'assertion', 'source availability', 'deeper', 'equal populations', 'execution'):
            require(phrase in guide, 'missing shared grouped interpretation: ' + phrase)
        if path == API:
            for report, semantic in EXAMPLES:
                require('| `' + report + '` | `' + semantic + '` |' in guide, 'documented shared grouped lookup')
    require(set(packet['instruments']) == INSTRUMENTS, 'instrument population')
    for path, saved in packet['instruments'].items():
        require(sha(saved['text'].encode()) == saved['sha256'] and (ROOT / path).read_text() == saved['text'], 'instrument identity')
    if current:
        require(packet['python'] == {'implementation': sys.implementation.name, 'version': list(sys.version_info)}, 'current runtime stale')
    return {'selected_fields': len(fields), 'cohort_fields': {name: len(old['fields']) for name, old in originals.items()},
        'grouped_entries': {name: len(group) for name, group in groups.items()},
        'remaining_fields': len(packet['remaining_fields']), 'limits': packet['limits']}


def controls(packet, capture):
    results = {}
    name = 'shared-candidate-qualified.json.gz'
    key = 'composition_shared_datapath_candidate_entry_keys'
    for label in ('lost_cohort', 'lost_field', 'extra_field', 'wrong_subject', 'wrong_owner', 'wrong_order',
                  'optional_as_core', 'lost_assertion_context', 'lost_deeper', 'unallocated_shared',
                  'wrong_report_map', 'wrong_semantic_key', 'lost_grouped_entry', 'input_identity',
                  'source_change', 'instrument_loss', 'wrong_role', 'borrowed_origin', 'missing_route',
                  'missing_cohort_guide', 'missing_grouped_guide', 'stale_document'):
        bad = copy.deepcopy(packet)
        if label == 'lost_cohort': bad['cohorts'].pop(name)
        elif label == 'lost_field': bad['fields'].pop(key)
        elif label == 'extra_field': bad['fields']['invented'] = bad['fields'][key]
        elif label in ('wrong_subject', 'wrong_owner', 'wrong_order', 'optional_as_core', 'lost_assertion_context'):
            field = key
            owner = name
            if label == 'optional_as_core': field = 'composition_shared_datapath_candidate_declared_type_extension_keys'
            if label == 'lost_assertion_context':
                owner, field = 'shared-aggregate-qualified.json.gz', 'composition_shared_datapath_assertion_keys'
            row = bad['cohorts'][owner]['fields'][field]
            if label == 'wrong_subject': row['subject'] = 'semantic.forward_ir.intent_hir.children[]'
            elif label == 'wrong_owner': row['value_owner'] = 'FSM::Support::NormalizedSemanticStructuralRTLIRContract'
            elif label == 'wrong_order': row['value'].reverse()
            elif label == 'optional_as_core': row['rule'] = 'core'
            else: row['subjects'].pop()
            bad['fields'][field] = {'cohort': owner, **row}
        elif label == 'lost_deeper': bad['remaining_fields'].pop(next(iter(bad['remaining_fields'])))
        elif label == 'unallocated_shared': bad['remaining_shared'][key] = bad['fields'][key]['value']
        elif label == 'wrong_report_map': bad['grouped']['presence_key_family_map'][key].reverse()
        elif label == 'wrong_semantic_key':
            group = bad['grouped']['semantic_presence_key_family_map']
            semantic = EXAMPLES[1][1]
            group['success_' + semantic] = group.pop(semantic)
        elif label == 'lost_grouped_entry': bad['grouped']['semantic_presence_key_family_map'].pop(key)
        elif label == 'input_identity': bad['inputs'][name] = '0' * 64
        elif label == 'instrument_loss': bad['instruments'].pop(next(iter(bad['instruments'])))
        elif label == 'wrong_role': bad['comparison_roles'][name]['mode'] = 'current'
        elif label == 'borrowed_origin': bad['comparison_roles'][name]['actual_source'] = CORE
        elif label == 'source_change':
            path = 'perl/FSM/Composition/SharedDatapathSupport.pm'
            saved = bad['sources'][path]
            saved['text'] = saved['text'].replace("kind => 'onehot0'", "kind => 'compatible_fanin'", 1)
            saved['sha256'] = sha(saved['text'].encode())
            for view in bad['cohorts'].values():
                if path in view['sources']: view['sources'][path] = copy.deepcopy(saved)
        else:
            path = CORE if label == 'missing_route' else API
            saved = bad['documents'][path]
            marker = candidate.MARKER if label in ('missing_route', 'missing_cohort_guide') else MARKER
            saved['text'] = saved['text'] + '\nchanged\n' if label == 'stale_document' else saved['text'].replace('### ' + marker + '\n', '', 1)
            saved['sha256'] = sha(saved['text'].encode())
            # Propagate document interventions through the declared views; test
            # guide/currency checks rather than incidental view inconsistency.
            for cohort_name, original in ((n, read(n)) for n in READERS):
                bad['cohorts'][cohort_name] = expected_view(original, bad)
                bad['comparison_roles'][cohort_name]['sha256'] = bad['documents'][API]['sha256']
        try:
            verify(bad, capture, current=label == 'stale_document')
        except ValueError as error:
            results[label] = str(error)
        else:
            raise ValueError('Accepted shared counterfeit: ' + label)
    return results


class GroupedView(TableView):
    def handle_starttag(self, tag, attrs):
        if tag in ('h2', 'h3'):
            self.active = dict(attrs).get('id') == 'normalized-shared-datapath-grouped-lookups'
        else:
            super().handle_starttag(tag, attrs)


def rendered(build):
    """Read actual canonical output directly; no legacy-name proxy is used."""
    raw = (build / '11a-perl-api-reference.html').read_bytes()
    pod = (build / 'perl-api/FSM/Support/CapabilityManifest.html').read_bytes()
    core = (build / '11-extensions-and-embedding.html').read_bytes()
    rows = {}
    for reader, view_type in ((candidate, candidate.CandidateView), (drive, drive.DriveView)):
        view = view_type(); view.feed(raw.decode())
        require(view.rows[1:3] == [[prefix, root] for prefix, root in reader.CONTEXTS.items()], 'native actual canonical contexts')
        require(view.rows[4:] == [[suffix, relative[1:] if relative else '(candidate entry)', rule, ', '.join(keys)]
            for suffix, (relative, rule, keys) in reader.ORACLE.items()], 'native actual canonical subjects/values')
        anchor = reader.MARKER.lower().replace(' ', '-')
        require((Path(API).stem + '.html#' + anchor).encode() in core, 'native actual compatibility route')
        require(reader.MARKER.encode() in pod, 'native cohort POD guide')
        rows[reader.MARKER] = view.rows
    rows['aggregate'] = aggregate.rendered(build)
    view = GroupedView(); view.feed(raw.decode())
    require(view.rows[1:] == [list(pair) for pair in EXAMPLES], 'native actual grouped example rows')
    require(MARKER.encode() in pod and b'equal populations' in pod, 'native shared grouped POD')
    return {'canonical_page': '11a-perl-api-reference.html', 'canonical_sha256': sha(raw),
        'pod_sha256': sha(pod), 'cohorts': rows, 'grouped_rows': view.rows,
        'scope': 'Selected actual canonical native content/routes only; whole-manual/browser review remains open.'}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('packet', type=Path)
    mode = parser.add_mutually_exclusive_group()
    mode.add_argument('--current', action='store_true')
    mode.add_argument('--current-contracts', action='store_true')
    parser.add_argument('--build', type=Path)
    args = parser.parse_args()
    capture = read('model-roots-qualified.json.gz'); capture_check(capture)
    packet = json.loads(gzip.decompress(args.packet.read_bytes()))
    result = verify(packet, capture, args.current, args.current_contracts)
    result['rejected_controls'] = controls(packet, capture)
    if args.build: result['rendered'] = rendered(args.build)
    print(json.dumps(result, sort_keys=True))


if __name__ == '__main__':
    main()
