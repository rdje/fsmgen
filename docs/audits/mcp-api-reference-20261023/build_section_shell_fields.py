#!/usr/bin/env python3
"""Census section-shell fields from the retained qualified metadata observation."""
import argparse
import gzip
import hashlib
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
BASE = Path(__file__).resolve().parent
OWNER = 'PERL-POD-API-REFERENCE.6.1.2.3.2.1.2.2'
BOOK = 'docs/book/src/11-extensions-and-embedding.md'
POD = 'perl/FSM/Support/CapabilityManifest.pm'
CAPTURE = BASE / 'model-roots-qualified.json.gz'
COHORTS = BASE / 'common-record-cohorts.json'

MEANINGS = {
    'schema_version': 'Numeric version of this dedicated bounded contract, separate from build, MCP protocol and language versions.',
    'status': 'bounded_public scopes this shell contract; it does not make every child public, available or fully stable.',
    'contract_source': 'Dedicated shell-owner namespace string; not a callable operation.',
    'report_source': 'Manifest-producer namespace string FSM::Support::CapabilityManifest.',
    'entrypoints': 'Discovery examples: cli is a string; cli_aliases and in_process are arrays of strings. These routes do not add MCP operations.',
    'public_top_level_presence_keys': 'Required field-name strings for the parent manifest section, not for this shell record or every nested object.',
    'nested_contract_keys': 'Names of the children with dedicated contract owners in nested_contract_source_map.',
    'nested_contract_source_map': 'Child-name to dedicated owner-namespace map. Key membership matches nested_contract_keys; payload subject remains owner-specific.',
    'nested_presence_key_map': 'Child-name to field-name-array discovery map. Subject can be a result, registry siblings or a contract record; use the explicit subject binding.',
    'guidance': 'Array of scope and deliberate-widening advice strings, not additional executable operations.',
    'scalar_string_keys': 'Diagnostics section fields whose values are strings; currently registry_source.',
    'list_keys': 'Diagnostics section fields whose values are lists; currently stable_codes.',
    'stable_code_entry_presence_keys': 'Field names for each stable diagnostic-code entry, not for the diagnostics section.',
    'presence_key_family_map': 'Named family to field-name-array lookup repeating each same-named compatibility field.',
    'stable_code_family_values': 'Bounded diagnostic family labels; these are enum values rather than field names. Detailed code meaning is delegated.',
    'path_list_keys': 'Documentation section field names carrying path lists: human_contract and downstream_alignment.',
    'path_contract': 'Boolean rules: repository-relative tracked Markdown pointers, with exact file membership not frozen.',
    'path_list_contract_map': 'Each named documentation path list mapped to path_contract rules, not file contents.',
    'file_surface_entry_presence_keys': 'Fields of each file_surfaces.entries item, equal to file_surfaces.entry_presence_keys, not the container keys.',
}
FLAGS = {
    'systemverilog_external_contract_advertised', 'stable_code_registry_contract_advertised',
    'check_json_contract_advertised', 'nested_contracts_advertised',
    'normalized_semantic_json_contract_advertised',
}
STABILITY = {
    'full_backend_validation_section_stable', 'full_diagnostics_section_stable',
    'full_embedding_section_stable', 'full_language_surface_stable',
    'full_semantic_exports_section_stable',
}
LANGUAGE_CHILDREN = {
    'strict_mode', 'file_surfaces', 'hial_vial_bridge', 'vial_execution',
    'vial_native_uvm_emission', 'vial_vhdl_emission', 'vial_tooling',
    'default_mode_compatibility', 'assignments', 'system_contracts',
    'expressions', 'declarations', 'composition',
}


def digest(raw):
    return hashlib.sha256(raw).hexdigest()


def encode(value):
    return json.dumps(value, sort_keys=True, ensure_ascii=True, separators=(',', ':')).encode()


def pointer(parent, key):
    return parent + '/' + str(key).replace('~', '~0').replace('/', '~1')


def at(value, path):
    for token in path.split('/')[1:]:
        value = value[token.replace('~1', '/').replace('~0', '~')]
    return value


def kind(value):
    return {dict: 'object', list: 'array', str: 'string', int: 'integer',
            bool: 'boolean', type(None): 'null'}[type(value)]


def nested(node, path):
    rows = []
    if type(node) is dict:
        rows.append({'pointer': path, 'kind': 'object', 'members': node,
                     'element_kinds': {k: kind(v) for k, v in node.items()}})
        for key, value in node.items():
            rows.extend(nested(value, pointer(path, key)))
    elif type(node) is list:
        rows.append({'pointer': path, 'kind': 'array', 'members': node,
                     'element_kinds': [kind(v) for v in node]})
        for index, value in enumerate(node):
            rows.extend(nested(value, pointer(path, index)))
    return rows


def subject(section, child):
    if section == 'backend_validation':
        return 'successful_external_validation_result'
    if section == 'diagnostics':
        return 'diagnostics_registry_siblings' if child == 'stable_code_registry' else 'check_report_envelope'
    if section == 'semantic_exports':
        return 'normalized_semantic_report_envelope'
    if section == 'language_surface':
        return 'language_child_metadata'
    return {'composition_report': 'sanitized_composition_report_fragment',
            'hdl_generator_result': 'known_generator_result_key_union',
            'serializable_generation_result_snapshot': 'serialized_generation_result_snapshot'}.get(child, 'advertised_contract_record')


def build():
    capture_bytes, cohort_bytes = CAPTURE.read_bytes(), COHORTS.read_bytes()
    capture, cohorts = json.loads(gzip.decompress(capture_bytes)), json.loads(cohort_bytes)
    manifest = capture['native_api']['manifest']
    records, fields, patterns, sources = [], [], [], {POD}
    for selected in cohorts['cohorts'][OWNER]:
        path = selected['pointer']
        section = path.split('/')[1]
        obj = at(manifest, path)
        owner_source = obj['contract_source'].replace('::', '/')
        source_path = 'perl/' + owner_source + '.pm'
        sources.add(source_path)
        records.append({'pointer': path, 'owner': obj['contract_source'],
            'source': source_path, 'subject': 'manifest_section:' + section,
            'presence': 'observed published shell metadata; described parent keys are separately required',
            'ordering': 'named object lookup; no positional priority promised for discovery arrays',
            'extension': 'deliberate documented regression-backed widening, not recursive closure',
            'nested_subjects': {name: subject(section, name) for name in obj.get('nested_presence_key_map', {})},
            'deeper_owner': 'PERL-POD-API-REFERENCE.6.1.2.3.2.4' if section in ('backend_validation', 'language_surface') else
                            'PERL-POD-API-REFERENCE.6.1.2.3.2.3' if section in ('embedding', 'semantic_exports') else
                            'PERL-POD-API-REFERENCE.6.1.2.3.2.2'})
        # Retain dedicated binding sources as evidence, without executing them.
        for namespace in obj.get('nested_contract_source_map', {}).values():
            sources.add('perl/' + namespace.replace('::', '/') + '.pm')
        for key, value in sorted(obj.items()):
            meaning = MEANINGS.get(key)
            if key in FLAGS:
                meaning = 'Boolean true advertises the named dedicated contract; it does not grant execution or arbitrary-input support.'
            elif key in STABILITY:
                meaning = 'Boolean false declines a whole-section stability promise while preserving the bounded named families.'
            elif section == 'language_surface' and key in {name + '_presence_keys' for name in LANGUAGE_CHILDREN}:
                meaning = 'Field-name strings for ' + key[:-14] + ' child metadata, equal to its nested_presence_key_map entry; deeper value meaning remains delegated.'
            if meaning is None:
                raise ValueError('Unclassified shell field: ' + path + '/' + key)
            fields.append({'pointer': pointer(path, key), 'owner': obj['contract_source'],
                'kind': kind(value), 'value_sha256': digest(encode(value)), 'meaning': meaning,
                'documentation': {'book': 'Section-shell contract records', 'pod': 'Section-shell records'},
                'coverage': 'shell field/family meaning; deeper payload meaning explicitly delegated'})
            patterns.extend(nested(value, pointer(path, key)))
    def snapshot(path):
        raw = (ROOT / path).read_bytes()
        return {'sha256': digest(raw), 'text': raw.decode()}
    return {'schema': 'fsmgen.section_shell_fields.v1', 'owner': OWNER,
        'capture': CAPTURE.relative_to(ROOT).as_posix(), 'capture_sha256': digest(capture_bytes),
        'capture_head': capture['head'], 'cohorts_sha256': digest(cohort_bytes),
        'builder': {'path': Path(__file__).resolve().relative_to(ROOT).as_posix(),
            'text': Path(__file__).read_text(), 'sha256': digest(Path(__file__).read_bytes()),
            'python': {'implementation': sys.implementation.name, 'version': list(sys.version_info)}},
        'records': records, 'fields': fields, 'nested_patterns': patterns,
        'sources': {path: snapshot(path) for path in sorted(sources)},
        'documents': {path: snapshot(path) for path in (BOOK, POD)},
        'facets': {'universal_nested_subject': False, 'recursive_closed_objects': False,
                   'entrypoints_enable_mcp_execution': False, 'array_priority_promised': False,
                   'all_children_public': False, 'exact_documentation_path_lists_frozen': False},
        'evidence_legs': {
            'rederive': 'Enumerate all selected shell fields and nested containers from the retained qualified native observation; retain exact owners, sources, subject bindings and current documentation.',
            'falsify': 'Independent native field/type/owner/container and dedicated-contract relationship joins; actual draft subject failure and coherent missing/extra/wrong-owner/meaning/source/document interventions.',
            'durability': 'Tracked capture/raw/native custody, exact source/doc/builder snapshots, independent saved/current reader, controls and task/Git.'},
        'limits': 'Dated selected section-shell semantics, not complete nested payload, all common records, MCP operating-reference, backend availability, simulation or publication qualification.'}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('output', type=Path)
    args = parser.parse_args()
    output = args.output.resolve()
    if output.parent != BASE or output.exists():
        raise SystemExit('Output must be a new file in this audit directory')
    raw = (json.dumps(build(), sort_keys=True, indent=2) + '\n').encode()
    with output.open('xb') as stream:
        stream.write(gzip.compress(raw, mtime=0))
    print('Wrote dated section-shell census; independent verification required.')


if __name__ == '__main__':
    main()
