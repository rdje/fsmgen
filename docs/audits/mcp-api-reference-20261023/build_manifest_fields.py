#!/usr/bin/env python3
"""Build a dated root/producer semantic census from already qualified metadata."""
import argparse
import gzip
import hashlib
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
BASE = Path(__file__).resolve().parent
OWNER = 'PERL-POD-API-REFERENCE.6.1.2.3.2.1.1'
CAPTURE = BASE / 'model-roots-qualified.json.gz'
BOOK = 'docs/book/src/11-extensions-and-embedding.md'
POD = 'perl/FSM/Support/CapabilityManifest.pm'
SOURCES = [POD, *['perl/FSM/Support/' + n + '.pm' for n in
           ('CapabilityManifestContract', 'ProducerContract', 'ProducerSection')]]


def digest(raw):
    return hashlib.sha256(raw).hexdigest()


def encode(value):
    return json.dumps(value, sort_keys=True, ensure_ascii=True, separators=(',', ':')).encode()


def pointer(parent, key):
    return parent + '/' + str(key).replace('~', '~0').replace('/', '~1')


def kind(value):
    return {dict: 'object', list: 'array', str: 'string', int: 'integer',
            bool: 'boolean', type(None): 'null'}[type(value)]


COMMON = {
    'schema_version': 'Numeric schema version published by this dedicated contract; do not substitute a build, protocol or language version.',
    'status': 'The selected contract marks its described surface bounded_public. This marker does not assert support for an arbitrary input or enable execution.',
    'contract_source': 'Namespace of the dedicated owner defining the bounded contract. It identifies authority, not a command to import or execute.',
    'report_source': 'Namespace of the manifest producer exposing the described object; distinct from the dedicated contract owner.',
    'entrypoints': 'Named CLI and in-process discovery routes. cli is a string; cli_aliases and in_process are arrays of strings in these two contracts. They are descriptive examples, not MCP tool calls.',
    'public_top_level_presence_keys': 'Array of required field names for the object described by this contract, rather than keys of this contract metadata record. This is a presence promise, not recursive closure.',
    'presence_key_family_map': 'Grouped lookup of named key-list families; each value repeats its same-named compatibility field. Members are strings naming fields, not example payload values.',
    'guidance': 'Array of explanatory strings describing scope and deliberate widening. Guidance is prose and does not grant additional callable operations.',
}
MANIFEST = {
    'manifest_schema_version': 'Integer version of the outer capability-manifest shell; currently 1. It is separate from every nested contract, VIAL language and MCP protocol version.',
    'producer': 'Current tool/build identity and its dedicated bounded producer contract. It is not a release-management or replay identity API.',
    'support_accounting': 'Regression-corpus-derived support/catalog metadata; deeper meanings and catalog variants are delegated to their dedicated owner and the next metadata cohort.',
    'diagnostics': 'Diagnostic registry and check-report contract advertisements; message/report meaning remains with their dedicated owners.',
    'semantic_exports': 'Normalized semantic report advertisements and dedicated export contracts; this object is not a raw AST or a source report.',
    'semantic_introspection': 'Query domains, families, applicability, ownership and read-only MCP discovery; deeper model and protocol fields remain separate cohorts.',
    'backend_validation': 'External HDL validation capability and contract advertisements; advertisement does not execute validation or guarantee installed tools.',
    'embedding': 'Published embedding/facade/snapshot/extension contract advertisements. This metadata does not expose every advertised operation through MCP.',
    'language_surface': 'Language/backend feature and VIAL metadata advertisements. Its dedicated top-level owner is under surface_contract for compatibility.',
    'verification_outputs': 'Verification target/artifact/validation contract advertisements; it does not execute a verification backend.',
    'documentation': 'Grouped repository-relative documentation pointers and their contract, not document contents or a search index.',
    'manifest_contract': 'Dedicated bounded outer-shell contract, ownership and presence-family discovery. Deeper payloads retain their own owners.',
}
PRODUCER = {
    'name': 'Tool identity string; the selected producer emits FSMGen.',
    'version': 'Current tool/build version string; the selected producer emits 0.1-dev. No package-manager release or schema compatibility guarantee is defined by this value.',
    'git_commit': 'Best-effort short Git hash or unknown. This provenance hint may be unavailable and is not a complete replay identity or release contract.',
    'contract_authority': 'Published Boolean marker, currently true. The contract defines its Boolean family but no stronger semantic meaning for this marker; that definition gap stays owned.',
    'source': 'Manifest builder namespace string, currently FSM::Support::CapabilityManifest; distinct from the producer section contract namespace.',
    'section_contract': 'ProducerContract metadata describing required producer fields, typed families and explicit identity flags.',
}
MANIFEST_EXTRA = {
    'top_level_contract_source_map': 'Map from each public object section name to its dedicated contract-owner namespace; outer schema and manifest_contract are excluded. Follow this map instead of guessing nested slot names.',
    'top_level_section_presence_key_map': 'Map from the same section names to their required first-level field-name arrays. It does not freeze deeper nested values or prohibit deliberate extensions.',
    'full_manifest_json_safe': 'Boolean promise that the complete manifest can be serialized as JSON, not permission to serialize raw implementation objects mentioned by metadata.',
    'nested_section_contracts_advertised': 'Boolean promise that dedicated section contracts are advertised; it does not make every nested helper or value a stable API.',
}
PRODUCER_EXTRA = {
    'scalar_string_keys': 'Producer field-name array for name, version, git_commit and source, whose public values are strings.',
    'boolean_keys': 'Producer field-name array identifying contract_authority as Boolean; it does not define additional authority semantics.',
    'identity_contract': 'Explicit Boolean identity promises: name identifies the tool, git_commit is best-effort short hash or unknown, and source identifies the manifest builder.',
}


def build():
    capture_raw = CAPTURE.read_bytes()
    record = json.loads(gzip.decompress(capture_raw))
    manifest = record['native_api']['manifest']
    contexts = {'': manifest, '/manifest_contract': manifest['manifest_contract'],
                '/producer': manifest['producer'],
                '/producer/section_contract': manifest['producer']['section_contract']}
    fields, nested = [], []
    for context, value in contexts.items():
        definitions = (MANIFEST if context == '' else PRODUCER if context == '/producer'
                       else dict(COMMON, **(MANIFEST_EXTRA if context == '/manifest_contract' else PRODUCER_EXTRA)))
        for key, item in sorted(value.items()):
            path = pointer(context, key)
            if context == '/manifest_contract' and key.endswith('_presence_keys') and key != 'public_top_level_presence_keys':
                meaning = ('Compatibility field-name array for the ' + key[:-14] +
                           ' section; equal to the grouped family-map entry with this field name. The list describes presence, not deeper value semantics.')
            else:
                meaning = definitions[key]  # An unclassified new field must stop the builder.
            is_gap = path == '/producer/contract_authority'
            fields.append({'pointer': path, 'kind': kind(item), 'value_sha256': digest(encode(item)),
                           'meaning': meaning, 'presence': 'required described-object field' if context in ('', '/producer') else 'observed published contract-metadata field',
                           'extension': 'deliberate owner-backed widening; no global closed-object rule',
                           'ordering': 'field membership is named; no positional meaning promised',
                           'semantic_status': 'owned_definition_gap' if is_gap else 'reviewed_in_this_scope',
                           'repair_owner': 'PERL-POD-API-REFERENCE.6.4' if is_gap else None,
                           'documentation': {'book': 'Manifest shell and producer fields', 'pod': 'MANIFEST FIELD GUIDE',
                                             'coverage': 'explicit definition gap' if is_gap else 'field/family interpretation; deeper section meaning delegated'}})
            # Root objects are delegated, and both separately indexed contract
            # contexts must not be descended through a second time.
            if context == '' or path == '/producer/section_contract':
                continue

            def descend(node, location):
                if isinstance(node, dict):
                    nested.append({'pointer': location, 'kind': 'object', 'keys': sorted(node),
                                   'value_kinds': {k: kind(v) for k, v in sorted(node.items())},
                                   'rule': 'named members; observed key domain is not a universal wildcard or recursive closure'})
                    for name, child in sorted(node.items()):
                        descend(child, pointer(location, name))
                elif isinstance(node, list):
                    nested.append({'pointer': location, 'kind': 'array', 'members': node,
                                   'element_kinds': [kind(x) for x in node],
                                   'rule': 'emitted sequence retained; semantic positional priority is not specified by this shell'})
                    for index, child in enumerate(node):
                        if isinstance(child, (dict, list)):
                            descend(child, pointer(location, index))
            descend(item, path)
    sources = {p: {'sha256': digest((ROOT / p).read_bytes()), 'text': (ROOT / p).read_text()}
               for p in SOURCES}
    documents = {p: {'sha256': digest((ROOT / p).read_bytes()), 'text': (ROOT / p).read_text()}
                 for p in (BOOK, POD)}
    return {'schema': 'fsmgen.manifest_field_census.v1', 'owner': OWNER,
            'capture': CAPTURE.relative_to(ROOT).as_posix(), 'capture_sha256': digest(capture_raw),
            'capture_head': record['head'],
            'builder': {'path': Path(__file__).resolve().relative_to(ROOT).as_posix(),
                        'sha256': digest(Path(__file__).read_bytes()), 'text': Path(__file__).read_text(),
                        'python': {'implementation': sys.implementation.name, 'version': list(sys.version_info)}},
            'fields': fields, 'nested_patterns': nested,
            'sources': sources, 'documents': documents,
            'facets': {'git_commit_best_effort': True, 'release_contract': False,
                       'recursive_closed_objects': False, 'mcp_execution_advertised_by_entrypoints': False,
                       'contract_authority_meaning_defined': False, 'array_priority_promised': False},
            'scope': 'Complete selected root/producer fields and nested contract-shell families, not deeper section or common-record semantics.',
            'gaps': [{'pointer': '/producer/contract_authority', 'priority': 'P2',
                      'owner': 'PERL-POD-API-REFERENCE.6.4',
                      'repair': 'Document exact supported marker meaning from an explicit producer-contract decision, or preserve the undefined boundary; never infer trust or compatibility.'}],
            'evidence_legs': {'rederive': 'Enumerate complete selected fields/nested containers from the retained qualified native manifest and bind exact sources/documents.',
                              'falsify': 'Independent saved-capture/contract-presence/source/value/documentation reader, actual old owner-list RED, and coherent omission/extra/type/meaning/source/stale-doc controls.',
                              'durability': 'This tracked producer, complete qualified capture/raw/native/source custody, compressed census containing reviewed sources/documents, independent reader and task/Git.'},
            'limits': 'Structural joins and facet controls do not prove arbitrary natural-language prose, unseen versions, all nested metadata, runtime availability, feature support or publication.'}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('output', type=Path)
    args = parser.parse_args()
    output = args.output.resolve()
    if not output.is_relative_to(BASE) or output.exists():
        raise SystemExit('Output must be a new file in this audit directory.')
    value = build()
    with output.open('xb') as stream:
        stream.write(gzip.compress((json.dumps(value, sort_keys=True, indent=2) + '\n').encode(), mtime=0))
    print('Wrote dated root/producer field census; independent verification required.')


if __name__ == '__main__':
    main()
