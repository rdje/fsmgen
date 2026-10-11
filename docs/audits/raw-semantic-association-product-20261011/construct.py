"""Construct complete cross-product candidates; semantic independence is a successor."""
from collections import defaultdict
from common import *

A = Path('docs/audits')
PATHS = {
    'raw': A / 'record-value-class-frame-join-20261006/raw-product.json',
    'classes': A / 'record-value-class-frame-join-20261006/source-models.json',
    'frames': A / 'record-value-class-frame-join-20261006/proofs.json',
    'headers': A / 'observer-original-header-join-20261011/joined.json',
    'expressions': A / 'observer-source-headers-20261011/headers.json',
    'coordinates': A / 'coordinate-original-matching-qualified-20261009/matching.json',
    'operands': A / 'address-raw-operands-20261010/operands.json',
    'source_address': A / 'address-source-integration-20261010/hypotheses.json',
    'holders': A / 'address-raw-join-20261010/holders.json',
    'numbers': A / 'address-numeric-join-20261010/joining.json',
}


def inputs():
    custody = load('intake-before.json')['members']
    data, registry = {}, {}
    for role, path in PATHS.items():
        raw = local(path).read_bytes()
        need(str(path) in custody and pin(raw) == {k: custody[str(path)][k] for k in ('bytes', 'sha256')},
             'whole selected construction input belongs to admitted namespace')
        data[role] = json.loads(raw)
        registry[role] = dict(path=str(path), identity=pin(raw))
    return data, registry


def unique(rows, key, cause):
    result = {key(row): row for row in rows}
    need(len(result) == len(rows), cause)
    return result


def derive(data, registry):
    classes = unique([(m['mode'], c) for m in data['classes']['modes'] for c in m['cases']],
                     lambda r: (r[0], r[1]['domain'], r[1]['index']), 'unique source class cases')
    classes = {key: row[1] for key, row in classes.items()}
    qualified = {(m['mode'], c['domain'], c['index']): c for m in data['frames']['modes'] for c in m['cases']}
    coordinates = unique(data['coordinates']['matches'], lambda r: (r['mode'], r['domain'], r['index']),
                         'unique coordinate record candidates')
    operands = {(m['mode'], name, r['index']): r for m in data['operands']['modes']
                for name, domain in m['domains'].items() for r in domain['records']}
    views = {}
    for role in ('source_address', 'holders'):
        rows = [v for m in data[role]['modes'] for v in m['views']]
        views[role] = unique(rows, lambda r: tuple(r['domain']), 'unique ' + role + ' source-phase domain')
    views['numbers'] = unique(data['numbers']['views'], lambda r: tuple(r['domain']), 'unique numeric source-phase domain')
    header_groups = {}
    for role in ('source_headers', 'public_headers', 'loads'):
        grouped = defaultdict(list)
        for row in data['headers'][role]:
            allocation = row['allocation']
            grouped[(*allocation['record'], allocation['phase'])].append(row)
        header_groups[role] = grouped
    opaque = unique(data['headers']['complete_opaque_allocation'], lambda r: tuple(r['record']),
                    'unique whole opaque record allocation')
    raw_records = {(m['mode'], name, r['index']): r for m in data['raw']['inventories']
                   for name, domain in m['domains'].items() for r in domain['nonempty']}
    need(set(raw_records) == set(classes) == set(qualified) == set(coordinates) == set(operands) == set(opaque),
         'complete candidate raw/source/class/header/coordinate/address record domain')
    used_phases = set()
    modes = []
    for mode in data['raw']['inventories']:
        domains = {}
        for name, domain in mode['domains'].items():
            records = []
            for original in domain['nonempty']:
                key = mode['mode'], name, original['index']
                source, proof, coordinate, parsed = classes[key], qualified[key], coordinates[key], operands[key]
                need(len(source['phases']) == len(proof['phases']) == len(coordinate['phases']) == len(parsed['phases']),
                     'complete ordered candidate phase population')
                phases = []
                for index, phase in enumerate(source['phases']):
                    domain_key = (*key, index)
                    need(phase['phase'] == proof['phases'][index]['phase'] == parsed['phases'][index]['phase'] == index,
                         'candidate discrete source phase order')
                    used_phases.add(domain_key)
                    source_headers = header_groups['source_headers'][domain_key]
                    public_headers = header_groups['public_headers'][domain_key]
                    identifiers = {identifier for h in source_headers for identifier in h['source_header']['source_argument_ids']}
                    identifiers.update(identifier for h in public_headers for identifier in h['allocation']['complete_argument_ids'])
                    phases.append(dict(domain=list(domain_key), source_class_frame=phase,
                        qualified_class_frame=proof['phases'][index], coordinate=coordinate['phases'][index],
                        source_headers=source_headers, public_headers=public_headers,
                        loads=header_groups['loads'][domain_key],
                        source_arguments={identifier: data['expressions']['operands'][identifier] for identifier in sorted(identifiers)},
                        parsed_address=parsed['phases'][index],
                        **{role: table[domain_key] for role, table in views.items()}))
                forwarding = None
                if proof['forwarded'] is not None:
                    relation = proof['forwarded']
                    child_key = mode['mode'], 'api', relation['capture_api']
                    child = raw_records[child_key]
                    raw = original['body'].encode()
                    cut = relation['entire_outer_prefix']['bytes']
                    prefix, trace = raw[:cut].decode(), raw[cut:].decode()
                    need(pin(prefix.encode()) == relation['entire_outer_prefix']
                         and pin(trace.encode()) == relation['new_outer_trace']
                         and child['body_identity'] == relation['inner_body'], 'complete inherited forwarding candidate custody')
                    forwarding = dict(source_relation=relation, inner_record=list(child_key), outer_record=list(key),
                                      whole_inner_body=child['body'], whole_outer_prefix=prefix, whole_new_outer_trace=trace)
                records.append(dict(record=list(key), original=original,
                    source_case={k: v for k, v in source.items() if k != 'phases'},
                    qualified_case={k: v for k, v in proof.items() if k != 'phases'},
                    observer_coordinate=coordinate['observer_caller'], opaque_allocation=opaque[key],
                    parsed_operands=parsed, phases=phases, forwarding=forwarding))
            domains[name] = dict(population=domain['population'], empty_string_members=domain['empty_string_members'], records=records)
        modes.append(dict(mode=mode['mode'], domains=domains))
    need(all(set(table) == used_phases for table in views.values()), 'complete candidate source/address phase membership')
    need(all(set(table) <= used_phases for table in header_groups.values()), 'no borrowed candidate header phase')
    return dict(schema_version=1, revision=REVISION, owner=OWNER, scope=SCOPE, inputs=registry,
        semantic_qualification='pending independent complete semantic reconstruction and separating controls under .5.2.2.2',
        original_unknowns=data['headers']['original_unknowns'],
        inherited_scopes={role: {key: data[role][key] for key in ('scope', 'role', 'unresolved', 'original_unmeasured') if key in data[role]}
                          for role in data}, modes=modes)


if __name__ == '__main__':
    data, registry = inputs()
    candidate = derive(data, registry)
    actual = load('checks.json')['native-census']
    need(type(actual.get('status')) is int and actual['status'] == 0 and actual['stderr'] == ''
         and actual['command'] == ['perl', str(BASE / 'native.pl')], 'actual independent original body census before construction')
    save('native-census.json', json.loads(actual['stdout']))
    save_product('candidate.json.gz', candidate)
    print('PASS complete source-bound raw-body candidate construction; independent semantic qualification remains pending.')
