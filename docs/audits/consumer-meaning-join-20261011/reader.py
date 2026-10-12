"""Independently partition source assertions and join fresh isolated child meanings."""
import argparse
from join_common import *
import child_readers
import join_inputs as inputs

SUCCESS = 'PASS independent complete original consumer source/meaning/operand/truth join; meaning acceptance and every higher owner retain.\n'


def check(candidate):
    data = inputs.inputs()
    header = inputs.header(data)
    need(type(candidate) is dict and set(candidate) == set(header) | {'modes'}
         and type(candidate['schema_version']) is int, 'closed whole original consumer join schema')
    need(same({key: candidate[key] for key in header}, header), 'complete original consumer join source and boundary custody')
    need(type(candidate['modes']) is list and len(candidate['modes']) == len(inputs.MODES),
         'complete original consumer join mode domain')
    partition = {'helper': [], 'remaining': []}
    probes = {'helper': [], 'remaining': []}
    for mi, (actual, mode) in enumerate(zip(candidate['modes'], inputs.MODES, strict=True)):
        need(type(actual) is dict and set(actual) == {'mode', 'consumers'} and actual['mode'] == mode
             and type(actual['consumers']) is list and len(actual['consumers']) == len(data['prepared']['assertions']),
             'complete original source consumer join population')
        for index, (row, assertion) in enumerate(zip(actual['consumers'], data['prepared']['assertions'], strict=True)):
            role = 'helper' if assertion['helper'] is not None else 'remaining'
            need((assertion['context']['helper'] is None) == (role == 'remaining'), 'independent own source role partition')
            need(type(row) is dict and set(row) == {'index', 'source_contract', 'role', 'native', 'meaning', 'outcome'}
                 and type(row['index']) is int and row['index'] == index and row['role'] == role
                 and same(row['source_contract'], assertion), 'whole own original source assertion and role allocation')
            if mi == 0:
                partition[role].append(index)
            probes[role].append(row['native'])
    need(len(partition['helper']) == 86 and len(partition['remaining']) == 39
         and sorted(partition['helper'] + partition['remaining']) == list(range(125)),
         'complete disjoint original source assertion partition')
    # Both readers rederive their source models on their unchanged complete
    # positives; supplied joined operands are then compared before parent source
    # meaning/body custody. False-green flags cannot pass on original success.
    admitted = {role: child_readers.admit(role, probes[role]) for role in partition}
    offsets = {role: 0 for role in partition}
    allocations = []
    for mi, (actual, mode) in enumerate(zip(candidate['modes'], inputs.MODES, strict=True)):
        joined = []
        for index, row in enumerate(actual['consumers']):
            role = row['role']
            child = admitted[role]['candidate']['modes'][mi]['consumers'][index]
            source = child['meaning']
            need(source is not None and same(source['source_assertion'], row['source_contract'])
                 and same(child['source_context'], row['source_contract']['context']),
                 'whole independently qualified child assertion source join')
            need(same(row['meaning'], source), 'whole independently rederived own consumer meaning join')
            truth = admitted[role]['truths'][offsets[role]]
            offsets[role] += 1
            need(type(row['outcome']) is int and row['outcome'] in (0, 1) and row['outcome'] == source['outcome'] == truth,
                 'whole own consumer source and comparison outcome join')
            need(same({key: row['native'][key] for key in source['operand']}, source['operand']),
                 'whole own source-derived typed consumer operand join')
            need(same(row['native'], data['native'][mode][index]) and same(child['native'], row['native']),
                 'whole original consumer observation join custody')
            joined.append(dict(index=index, role=role, source=pin(canonical(row['source_contract'])),
                meaning=pin(canonical(source)), operand=pin(canonical(source['operand'])), outcome=truth))
        allocations.append(dict(mode=mode, consumers=joined, whole_native=pin(canonical(data['native'][mode]))))
    need(all(offsets[role] == len(probes[role]) == len(partition[role]) * len(inputs.MODES) for role in partition),
         'every original comparison and meaning consumed exactly once')
    return dict(owner=PLAN['owner'], revision=PLAN['revision'], candidate=pin(canonical(candidate)),
        inputs=data['identities'], source_roles=data['source_roles'], partition=partition, allocations=allocations,
        children={role: {key: admitted[role][key] for key in ('qualification', 'custody')} for role in partition},
        boundary=PLAN['condition'], assumptions=header['assumptions'])


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--candidate', default='candidate.json.gz')
    parser.add_argument('--save', action='store_true')
    args = parser.parse_args()
    need(Path(args.candidate).name == args.candidate and args.candidate.endswith('.json.gz'), 'ordinary own join candidate route')
    result = check(load_product(args.candidate))
    if args.save:
        need(args.candidate == 'candidate.json.gz', 'only complete positive consumer join publishes')
        save('qualification.json', result)
    print(SUCCESS, end='')
