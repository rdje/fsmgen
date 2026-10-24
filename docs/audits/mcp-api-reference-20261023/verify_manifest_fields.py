#!/usr/bin/env python3
"""Verify dated manifest fields against qualified native data, sources and docs."""
import argparse
import copy
import gzip
import hashlib
import json
from pathlib import Path
import re

from verify_model_roots import capture_check
from verify_error_context import source

ROOT = Path(__file__).resolve().parents[3]
BASE = Path(__file__).resolve().parent
BOOK = 'docs/book/src/11-extensions-and-embedding.md'
POD = 'perl/FSM/Support/CapabilityManifest.pm'
CENSUS_OWNER = 'PERL-POD-API-REFERENCE.6.1.2.3.2.1.1'


def require(condition, message):
    if not condition:
        raise ValueError(message)


def sha(raw):
    return hashlib.sha256(raw).hexdigest()


def canonical(value):
    return json.dumps(value, sort_keys=True, ensure_ascii=True, separators=(',', ':')).encode()


def location(parent, key):
    return parent + '/' + str(key).replace('~', '~0').replace('/', '~1')


def at(value, path):
    for part in path.split('/')[1:]:
        value = value[part.replace('~1', '/').replace('~0', '~')]
    return value


def json_type(value):
    for python_type, label in ((bool, 'boolean'), (int, 'integer'), (str, 'string'),
                               (list, 'array'), (dict, 'object'), (type(None), 'null')):
        if type(value) is python_type:
            return label
    raise ValueError('Unexpected native JSON value')


def book_owners(text):
    begin = text.index('top_level_contract_source_map` for the public')
    end = text.index('That grouped map', begin)
    return re.findall(r'^- `([a-z_]+)`$', text[begin:end], re.M)


def check_owner_list(text, manifest):
    observed = book_owners(text)
    expected = set(manifest['manifest_contract']['top_level_contract_source_map'])
    require(len(observed) == len(set(observed)) and set(observed) == expected,
            'book owner list mismatch: missing=' + str(sorted(expected - set(observed))))


def verify(value, record, current=False):
    require(value['owner'] == CENSUS_OWNER and value['schema'] == 'fsmgen.manifest_field_census.v1', 'census identity')
    capture_path = ROOT / value['capture']
    require(capture_path.resolve().parent == BASE and sha(capture_path.read_bytes()) == value['capture_sha256'], 'capture custody')
    builder = value['builder']
    require(builder['path'] == 'docs/audits/mcp-api-reference-20261023/build_manifest_fields.py' and sha(builder['text'].encode()) == builder['sha256'], 'builder custody')
    require(builder['python']['implementation'] and len(builder['python']['version']) == 5, 'builder runtime identity')
    if current:
        require((ROOT / builder['path']).read_bytes() == builder['text'].encode(), 'current builder stale')
    manifest = record['native_api']['manifest']
    require(value['capture_head'] == record['head'], 'capture epoch')
    # Membership comes from complete actual objects; no builder field-name or
    # semantic classifier is imported into this independent reader.
    objects = {'': manifest, '/producer': manifest['producer'],
               '/manifest_contract': manifest['manifest_contract'],
               '/producer/section_contract': manifest['producer']['section_contract']}
    expected = {location(parent, name) for parent, obj in objects.items() for name in obj}
    fields = {r['pointer']: r for r in value['fields']}
    require(len(fields) == len(value['fields']) and set(fields) == expected, 'complete field population')
    declared = manifest['manifest_contract']
    require(set(declared['public_top_level_presence_keys']) == set(manifest), 'manifest presence join')
    producer = manifest['producer']
    pc = producer['section_contract']
    require(set(pc['public_top_level_presence_keys']) == set(producer), 'producer presence join')
    sections = set(manifest) - {'manifest_contract', 'manifest_schema_version'}
    require(set(declared['top_level_contract_source_map']) == sections == set(declared['top_level_section_presence_key_map']), 'section map domains')
    for name in sections:
        slot = 'surface_contract' if name == 'language_surface' else 'section_contract'
        require(declared['top_level_contract_source_map'][name] == manifest[name][slot]['contract_source'], 'dedicated owner join')
        require(set(declared['top_level_section_presence_key_map'][name]) <= set(manifest[name]), 'section required presence')
        family = name + '_presence_keys'
        require(canonical(declared[family]) == canonical(declared['presence_key_family_map'][family]) == canonical(declared['top_level_section_presence_key_map'][name]), 'legacy/grouped family join')
    for name, members in pc['presence_key_family_map'].items():
        require(canonical(members) == canonical(pc[name]), 'producer grouped family join')
    for name in pc['scalar_string_keys']:
        require(type(producer[name]) is str and bool(producer[name]), 'producer string kind')
    for name in pc['boolean_keys']:
        require(type(producer[name]) is bool, 'producer Boolean kind')
    require(type(manifest['manifest_schema_version']) is int, 'manifest integer kind')
    require(re.fullmatch(r'(?:unknown|[0-9a-f]{7,12})', producer['git_commit']) is not None, 'best effort revision shape')
    require(all(type(v) is bool and v for v in pc['identity_contract'].values()), 'explicit producer identity promises')
    require(canonical(value['facets']) == canonical({'git_commit_best_effort': True, 'release_contract': False,
        'recursive_closed_objects': False, 'mcp_execution_advertised_by_entrypoints': False,
        'contract_authority_meaning_defined': False, 'array_priority_promised': False}), 'wrong semantic boundary')
    gaps = [r for r in value['fields'] if r['semantic_status'] == 'owned_definition_gap']
    require([r['pointer'] for r in gaps] == ['/producer/contract_authority'], 'definition gap omitted or moved')
    require(gaps[0]['repair_owner'] == 'PERL-POD-API-REFERENCE.6.4', 'gap repair ownership')
    require(value['gaps'][0]['pointer'] == gaps[0]['pointer'] and value['gaps'][0]['owner'] == gaps[0]['repair_owner'], 'gap matrix join')
    for path, row in fields.items():
        actual = at(manifest, path)
        require(row['kind'] == json_type(actual) and row['value_sha256'] == sha(canonical(actual)), 'field value/type: ' + path)
        require(row['meaning'] and row['extension'] and row['ordering'], 'missing interpretation: ' + path)
        require(row['documentation']['book'] == 'Manifest shell and producer fields' and row['documentation']['pod'] == 'MANIFEST FIELD GUIDE', 'missing documentation route')
    # Reconstruct nested containers without the producer's traversal routine.
    expected_nested = {}
    queue = [(p, at(manifest, p)) for p in expected if p.startswith('/manifest_contract/') or p.startswith('/producer/section_contract/')]
    while queue:
        path, obj = queue.pop()
        if type(obj) is dict:
            expected_nested[path] = ('object', obj)
            queue.extend((location(path, k), v) for k, v in obj.items() if type(v) in (dict, list))
        elif type(obj) is list:
            expected_nested[path] = ('array', obj)
            queue.extend((location(path, i), v) for i, v in enumerate(obj) if type(v) in (dict, list))
    nested = {r['pointer']: r for r in value['nested_patterns']}
    require(len(nested) == len(value['nested_patterns']) and set(nested) == set(expected_nested), 'nested pattern population')
    for path, (label, obj) in expected_nested.items():
        row = nested[path]
        require(row['kind'] == label and row['rule'], 'nested interpretation')
        if label == 'object':
            require(row['keys'] == sorted(obj) and row['value_kinds'] == {k: json_type(v) for k, v in obj.items()}, 'dynamic map domain/kinds')
        else:
            require(canonical(row['members']) == canonical(obj) and row['element_kinds'] == [json_type(x) for x in obj], 'array members/order/kinds')
    expected_sources = {POD, *['perl/FSM/Support/' + n + '.pm' for n in
        ('CapabilityManifestContract', 'ProducerContract', 'ProducerSection')]}
    require(set(value['sources']) == expected_sources, 'source population')
    for path, row in value['sources'].items():
        raw = row['text'].encode()
        require(sha(raw) == row['sha256'], 'source digest')
        original = source(record, path)
        require(raw.split(b'\n__END__\n', 1)[0] == original.split(b'\n__END__\n', 1)[0], 'native runtime source changed')
        if path != POD:
            require(raw == original, 'contract/producer source changed')
    require(set(value['documents']) == {BOOK, POD}, 'documentation population')
    for path, row in value['documents'].items():
        require(sha(row['text'].encode()) == row['sha256'], 'documentation digest')
        if current:
            require((ROOT / path).read_bytes() == row['text'].encode(), 'current documentation stale: ' + path)
    require(value['sources'][POD] == value['documents'][POD], 'POD/source custody')
    book = value['documents'][BOOK]['text']
    check_owner_list(book, manifest)
    begin = book.index('### Manifest shell and producer fields')
    end = book.index('\n### ', begin + 5)
    guide = book[begin:end]
    pod = value['documents'][POD]['text'].split('=head1 MANIFEST FIELD GUIDE\n', 1)[1].split('=head1 ', 1)[0]
    # These independently reviewed phrases express the specific competing
    # meanings tested by controls. General prose correctness remains review.
    for phrase in ('best-effort', 'not a release', 'presence', 'ordering', 'contract_authority', 'undefined'):
        require(phrase in guide and phrase in pod, 'semantic documentation boundary: ' + phrase)
    require('manifest_schema_version' in guide and 'top_level_contract_source_map' in guide and 'identity_contract' in guide, 'missing shell/identity guidance')
    return {'fields': len(fields), 'nested_containers': len(nested), 'definition_gaps': [r['pointer'] for r in gaps]}


def controls(value, record):
    rejected = []
    for label in ('missing_field', 'extra_field', 'borrowed_value', 'wrong_kind', 'wrong_meaning', 'numeric_facet', 'lost_gap', 'missing_map_member', 'borrowed_source', 'wrong_doc_meaning', 'missing_owner_doc', 'stale_current_doc', 'borrowed_builder'):
        bad = copy.deepcopy(value)
        if label == 'missing_field':
            bad['fields'].pop()
        elif label == 'extra_field':
            row = copy.deepcopy(bad['fields'][0]); row['pointer'] = '/invented'; bad['fields'].append(row)
        elif label == 'borrowed_value':
            bad['fields'][0]['value_sha256'] = bad['fields'][1]['value_sha256']
        elif label == 'wrong_kind':
            next(r for r in bad['fields'] if r['pointer'] == '/manifest_schema_version')['kind'] = 'boolean'
        elif label == 'wrong_meaning':
            bad['facets']['git_commit_best_effort'] = False
        elif label == 'numeric_facet':
            bad['facets']['release_contract'] = 0
        elif label == 'lost_gap':
            next(r for r in bad['fields'] if r['pointer'] == '/producer/contract_authority')['semantic_status'] = 'reviewed_in_this_scope'
        elif label == 'missing_map_member':
            next(r for r in bad['nested_patterns'] if r['pointer'] == '/manifest_contract/top_level_contract_source_map')['keys'].remove('semantic_introspection')
        elif label == 'borrowed_source':
            path = 'perl/FSM/Support/ProducerContract.pm'
            bad['sources'][path]['text'] = bad['sources'][path]['text'].replace('bounded_public', 'borrowed_public')
            bad['sources'][path]['sha256'] = sha(bad['sources'][path]['text'].encode())
        elif label == 'wrong_doc_meaning':
            bad['documents'][BOOK]['text'] = bad['documents'][BOOK]['text'].replace('best-effort', 'guaranteed-full')
            bad['documents'][BOOK]['sha256'] = sha(bad['documents'][BOOK]['text'].encode())
        elif label == 'stale_current_doc':
            bad['documents'][BOOK]['text'] += '\n'
            bad['documents'][BOOK]['sha256'] = sha(bad['documents'][BOOK]['text'].encode())
        elif label == 'borrowed_builder':
            bad['builder']['text'] += '\n# counterfeit instrument\n'
        else:
            begin = bad['documents'][BOOK]['text'].index('top_level_contract_source_map` for the public')
            text = bad['documents'][BOOK]['text']
            bad['documents'][BOOK]['text'] = text[:begin] + text[begin:].replace('- `semantic_introspection`\n', '', 1)
            bad['documents'][BOOK]['sha256'] = sha(bad['documents'][BOOK]['text'].encode())
        try:
            verify(bad, record, current=(label == 'stale_current_doc'))
        except (ValueError, AssertionError, KeyError):
            rejected.append(label)
        else:
            raise ValueError('Counterfeit accepted: ' + label)
    return rejected


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('census', type=Path)
    parser.add_argument('--current', action='store_true')
    args = parser.parse_args()
    value = json.loads(gzip.decompress(args.census.read_bytes()))
    require(value['capture'] == 'docs/audits/mcp-api-reference-20261023/model-roots-qualified.json.gz', 'fixed qualified capture required')
    record = json.loads(gzip.decompress((BASE / 'model-roots-qualified.json.gz').read_bytes()))
    capture_check(record)  # Saved native/wire/source authentication, no producer starts.
    result = verify(value, record, args.current)
    result['rejected_controls'] = controls(value, record)
    result['reader_source_sha256'] = sha(Path(__file__).read_bytes())
    result['reader_source_text'] = Path(__file__).read_text()
    print(json.dumps(result, sort_keys=True))


if __name__ == '__main__':
    main()
