#!/usr/bin/env python3
"""Independently join saved shell fields, owners, map subjects and documentation."""
import argparse
import copy
import gzip
import hashlib
import json
from pathlib import Path

from verify_error_context import source
from verify_model_roots import capture_check

ROOT = Path(__file__).resolve().parents[3]
BASE = Path(__file__).resolve().parent
OWNER = 'PERL-POD-API-REFERENCE.6.1.2.3.2.1.2.2'
BOOK = 'docs/book/src/11-extensions-and-embedding.md'
POD = 'perl/FSM/Support/CapabilityManifest.pm'
BUILDER = 'docs/audits/mcp-api-reference-20261023/build_section_shell_fields.py'
SECTIONS = {'backend_validation', 'diagnostics', 'documentation', 'embedding',
            'language_surface', 'semantic_exports'}


def require(ok, reason):
    if not ok:
        raise ValueError(reason)


def sha(raw):
    return hashlib.sha256(raw).hexdigest()


def encoded(value):
    return json.dumps(value, ensure_ascii=True, sort_keys=True, separators=(',', ':')).encode()


def at(value, path):
    for token in path.split('/')[1:]:
        token = token.replace('~1', '/').replace('~0', '~')
        value = value[int(token)] if type(value) is list else value[token]
    return value


def keypath(path, name):
    return path + '/' + str(name).replace('~', '~0').replace('/', '~1')


def kind(value):
    for cls, label in ((bool, 'boolean'), (int, 'integer'), (str, 'string'),
                       (dict, 'object'), (list, 'array'), (type(None), 'null')):
        if type(value) is cls:
            return label
    raise ValueError('Unsupported JSON kind')


def verify(packet, capture, current=False):
    require(packet['schema'] == 'fsmgen.section_shell_fields.v1' and packet['owner'] == OWNER, 'census identity')
    require(packet['capture'] == 'docs/audits/mcp-api-reference-20261023/model-roots-qualified.json.gz', 'capture path')
    require(packet['capture_sha256'] == sha((BASE / 'model-roots-qualified.json.gz').read_bytes()), 'capture identity')
    require(packet['capture_head'] == capture['head'], 'capture epoch')
    require(packet['cohorts_sha256'] == sha((BASE / 'common-record-cohorts.json').read_bytes()), 'selection identity')
    builder = packet['builder']
    require(builder['path'] == BUILDER and sha(builder['text'].encode()) == builder['sha256'], 'builder custody')
    require(builder['python']['implementation'] and len(builder['python']['version']) == 5, 'runtime identity')
    if current:
        require((ROOT / BUILDER).read_bytes() == builder['text'].encode(), 'current builder stale')
    manifest = capture['native_api']['manifest']
    paths = {'/' + section + ('/surface_contract' if section == 'language_surface' else '/section_contract') for section in SECTIONS}
    selected = json.loads((BASE / 'common-record-cohorts.json').read_bytes())['cohorts'][OWNER]
    require({row['pointer'] for row in selected} == paths, 'selected section population')
    records = {row['pointer']: row for row in packet['records']}
    require(len(records) == len(packet['records']) and records.keys() == paths, 'complete record population')
    expected_fields = {keypath(p, name) for p in paths for name in at(manifest, p)}
    fields = {row['pointer']: row for row in packet['fields']}
    require(len(fields) == len(packet['fields']) and fields.keys() == expected_fields, 'complete field population')
    expected_sources = {POD}
    for path, row in records.items():
        obj = at(manifest, path)
        section = path.split('/')[1]
        source_path = 'perl/' + obj['contract_source'].replace('::', '/') + '.pm'
        expected_sources.add(source_path)
        expected_sources.update('perl/' + ns.replace('::', '/') + '.pm' for ns in obj.get('nested_contract_source_map', {}).values())
        require(row['owner'] == obj['contract_source'] and row['source'] == source_path, 'dedicated owner/source')
        require(row['subject'] == 'manifest_section:' + section, 'parent subject')
        require(row['presence'] and row['ordering'] and row['extension'], 'missing presence/order/extension meaning')
        expected_deeper = 'PERL-POD-API-REFERENCE.6.1.2.3.2.' + ('4' if section in ('backend_validation', 'language_surface') else '3' if section in ('embedding', 'semantic_exports') else '2')
        require(row['deeper_owner'] == expected_deeper, 'lost deeper delegation')
        require(type(obj['schema_version']) is int and obj['status'] == 'bounded_public', 'version/status shape')
        require(obj['report_source'] == 'FSM::Support::CapabilityManifest', 'manifest producer')
        require(set(obj['public_top_level_presence_keys']) <= set(manifest[section]), 'parent required presence')
        entries = obj['entrypoints']
        require(set(entries) == {'cli', 'cli_aliases', 'in_process'} and type(entries['cli']) is str, 'entrypoint shape')
        require(all(type(entries[k]) is list and all(type(x) is str for x in entries[k]) for k in ('cli_aliases', 'in_process')), 'entrypoint list kind')
        if 'nested_contract_source_map' in obj:
            require(set(obj['nested_contract_keys']) == set(obj['nested_contract_source_map']) == set(obj['nested_presence_key_map']), 'nested map domain')
            for child, namespace in obj['nested_contract_source_map'].items():
                require(manifest[section][child]['contract_source'] == namespace, 'child owner join')
        subjects = {}
        for child, family in obj.get('nested_presence_key_map', {}).items():
            target = manifest[section][child]
            subject = 'advertised_contract_record'
            if section == 'backend_validation':
                reference, subject = target['success_top_level_presence_keys'], 'successful_external_validation_result'
            elif section == 'diagnostics' and child == 'stable_code_registry':
                reference, subject = target['public_sibling_keys'], 'diagnostics_registry_siblings'
                require(set(reference) <= set(manifest['diagnostics']), 'registry siblings located in parent')
            elif section == 'language_surface':
                reference, subject = obj[child + '_presence_keys'], 'language_child_metadata'
                require(set(reference) <= set(target), 'language child metadata presence')
            elif section == 'embedding' and child == 'hdl_generator_result':
                reference = sorted(set().union(*(target[k] for k in ('public_top_level_presence_keys', 'direct_root_top_level_keys', 'composition_root_top_level_keys'))))
                subject = 'known_generator_result_key_union'
            elif section == 'embedding' and child == 'composition_report':
                reference, subject = target['public_top_level_keys'], 'sanitized_composition_report_fragment'
            else:
                reference = target['public_top_level_presence_keys']
                if section == 'diagnostics':
                    subject = 'check_report_envelope'
                elif section == 'semantic_exports':
                    subject = 'normalized_semantic_report_envelope'
                elif child == 'serializable_generation_result_snapshot':
                    subject = 'serialized_generation_result_snapshot'
            require(encoded(family) == encoded(reference), 'dedicated nested family: ' + child)
            subjects[child] = subject
        require(row['nested_subjects'] == subjects, 'wrong nested subject: ' + section)
        for name, family in obj.get('presence_key_family_map', {}).items():
            require(encoded(family) == encoded(obj[name]), 'same-named family join')
        if section == 'documentation':
            rules = {'repo_relative_paths': True, 'tracked_markdown_files': True, 'exact_path_lists_frozen': False}
            require(encoded(obj['path_contract']) == encoded(rules), 'path contract meaning')
            require(set(obj['path_list_keys']) == set(obj['path_list_contract_map']), 'path list domains')
            require(all(encoded(r) == encoded(rules) for r in obj['path_list_contract_map'].values()), 'per-list path rules')
            require('nested_presence_key_map' not in obj and 'nested_contract_source_map' not in obj, 'absent nested maps')
        if section == 'language_surface':
            require(obj['file_surface_entry_presence_keys'] == manifest[section]['file_surfaces']['entry_presence_keys'], 'file entry subject')
    for path, row in fields.items():
        actual = at(manifest, path)
        parent, name = path.rsplit('/', 1)
        require(row['owner'] == at(manifest, parent)['contract_source'], 'field owner')
        require(row['kind'] == kind(actual) and row['value_sha256'] == sha(encoded(actual)), 'field value/type')
        require(row['meaning'] and row['coverage'], 'field meaning/coverage')
        require(row['documentation'] == {'book': 'Section-shell contract records', 'pod': 'Section-shell records'}, 'documentation route')
        if name.endswith('_advertised') or name.startswith('full_'):
            require(type(actual) is bool, 'Boolean flag type')
    pending = [(p, at(manifest, p)) for p in expected_fields]
    expected_nested = {}
    while pending:
        path, value = pending.pop()
        if type(value) in (dict, list):
            expected_nested[path] = value
            members = value.items() if type(value) is dict else enumerate(value)
            pending.extend((keypath(path, k), v) for k, v in members if type(v) in (dict, list))
    nested = {r['pointer']: r for r in packet['nested_patterns']}
    require(len(nested) == len(packet['nested_patterns']) and nested.keys() == expected_nested.keys(), 'complete nested population')
    for path, value in expected_nested.items():
        row = nested[path]
        kinds = {k: kind(v) for k, v in value.items()} if type(value) is dict else [kind(v) for v in value]
        require(row['kind'] == kind(value) and encoded(row['members']) == encoded(value) and row['element_kinds'] == kinds, 'nested members/order/types')
    require(encoded(packet['facets']) == encoded({
        'universal_nested_subject': False, 'recursive_closed_objects': False,
        'entrypoints_enable_mcp_execution': False, 'array_priority_promised': False,
        'all_children_public': False, 'exact_documentation_path_lists_frozen': False}), 'semantic boundary facets')
    require(set(packet['sources']) == expected_sources, 'complete semantic source population')
    for path, snapshot in packet['sources'].items():
        raw = snapshot['text'].encode()
        require(sha(raw) == snapshot['sha256'], 'source snapshot digest')
        original = source(capture, path)
        require(raw.split(b'\n__END__\n', 1)[0] == original.split(b'\n__END__\n', 1)[0], 'source runtime conservation')
        if path != POD:
            require(raw == original, 'dedicated source identity')
        if current:
            require((ROOT / path).read_bytes() == raw, 'current source stale')
    require(set(packet['documents']) == {BOOK, POD}, 'document population')
    for path, snapshot in packet['documents'].items():
        require(sha(snapshot['text'].encode()) == snapshot['sha256'], 'document digest')
        if current:
            require((ROOT / path).read_text() == snapshot['text'], 'current document stale')
    require(packet['sources'][POD] == packet['documents'][POD], 'POD/source join')
    book = packet['documents'][BOOK]['text'].split('### Section-shell contract records\n', 1)[1].split('\n### ', 1)[0]
    pod = packet['documents'][POD]['text'].split('=head2 Section-shell records\n', 1)[1].split('\n=head1 ', 1)[0]
    for phrase in ('known-key union', 'snapshot output', 'registry sibling', 'success-result', 'path_list_contract_map'):
        require(phrase in book.lower() and phrase in pod.lower(), 'documented subject boundary: ' + phrase)
    require('universal schema' in pod and 'subject depends' in book, 'missing subject warning')
    return {'records': len(records), 'fields': len(fields), 'nested_containers': len(nested),
            'deeper_owners': sorted({r['deeper_owner'] for r in records.values()})}


def controls(packet, capture):
    rejected = {}
    for label in ('missing_record', 'extra_field', 'wrong_owner', 'borrowed_value',
                  'wrong_kind', 'wrong_subject', 'lost_delegation', 'missing_map_member',
                  'numeric_boolean', 'false_execution', 'borrowed_source',
                  'wrong_doc_subject', 'stale_document', 'stale_builder'):
        bad = copy.deepcopy(packet)
        if label == 'missing_record':
            bad['records'].pop()
        elif label == 'extra_field':
            r = copy.deepcopy(bad['fields'][0]); r['pointer'] += '_invented'; bad['fields'].append(r)
        elif label == 'wrong_owner':
            bad['records'][0]['owner'] = bad['records'][1]['owner']
        elif label == 'borrowed_value':
            bad['fields'][0]['value_sha256'] = bad['fields'][1]['value_sha256']
        elif label == 'wrong_kind':
            bad['fields'][0]['kind'] = 'array'
        elif label == 'wrong_subject':
            next(r for r in bad['records'] if r['pointer'].startswith('/backend_validation'))['nested_subjects']['systemverilog_external'] = 'advertised_contract_record'
        elif label == 'lost_delegation':
            bad['records'][0]['deeper_owner'] = OWNER
        elif label == 'missing_map_member':
            next(r for r in bad['nested_patterns'] if r['pointer'].endswith('/entrypoints'))['members'].pop('cli')
        elif label == 'numeric_boolean':
            bad['facets']['array_priority_promised'] = 0
        elif label == 'false_execution':
            bad['facets']['entrypoints_enable_mcp_execution'] = True
        elif label == 'borrowed_source':
            p = 'perl/FSM/Support/BackendValidationContract.pm'
            bad['sources'][p]['text'] += '\n# borrowed\n'; bad['sources'][p]['sha256'] = sha(bad['sources'][p]['text'].encode())
        elif label in ('wrong_doc_subject', 'stale_document'):
            doc = bad['documents'][BOOK]
            doc['text'] = doc['text'].replace('known-key union', 'universal-required-keys') if label == 'wrong_doc_subject' else doc['text'] + '\n'
            doc['sha256'] = sha(doc['text'].encode())
        else:
            bad['builder']['text'] += '\n# changed instrument\n'; bad['builder']['sha256'] = sha(bad['builder']['text'].encode())
        try:
            verify(bad, capture, current=label in ('stale_document', 'stale_builder'))
        except (ValueError, KeyError) as error:
            rejected[label] = str(error)
        else:
            raise ValueError('Control accepted: ' + label)
    return rejected


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('packet', type=Path)
    parser.add_argument('--current', action='store_true')
    args = parser.parse_args()
    packet = json.loads(gzip.decompress(args.packet.read_bytes()))
    capture = json.loads(gzip.decompress((BASE / 'model-roots-qualified.json.gz').read_bytes()))
    capture_check(capture)  # Authenticate saved wire/native/source custody; never rerun a producer.
    result = verify(packet, capture, args.current)
    result['rejected_controls'] = controls(packet, capture)
    result['reader_source_sha256'] = sha(Path(__file__).read_bytes())
    result['reader_source_text'] = Path(__file__).read_text()
    print(json.dumps(result, sort_keys=True))


if __name__ == '__main__':
    main()
