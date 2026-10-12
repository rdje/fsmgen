"""Independently qualify complete unchanged original-consumer acceptance."""
import argparse
from parent_common import *
import model
import interfaces

SUCCESS = 'PASS complete unchanged original consumer acceptance; full alias downstream and higher owners remain separate.\n'


def check(candidate):
    data = model.inputs()
    header = model.header(data)
    need(type(candidate) is dict and set(candidate) == set(header) | {'admission', 'source_contracts', 'meanings', 'links', 'current', 'failures'}
         and type(candidate['schema_version']) is int, 'closed complete original-consumer schema')
    need(same({key: candidate[key] for key in header}, header), 'whole unchanged original consumer source descendant and boundary contract custody')
    public = data['public']
    fact = public['consumer_fact']
    admitted = fact.published(candidate['admission'])
    need(admitted.encode() == data['canonical'][PLAN['target']], 'whole admitted unchanged canonical consumer publication')
    source = interfaces.source_contracts(candidate['source_contracts'])
    means = interfaces.meanings(candidate['meanings'])
    qualified_path = PLAN['meaning'] + '/qualification.json'
    need(same(means['qualification'], json.loads(fixed([qualified_path])[qualified_path])), 'whole freshly rederived complete original consumer meanings')
    links = source_meaning_links(candidate, source, means)
    public['check'](candidate['current'], data['canonical'], data['prior'], public['authority'](data['prior']))
    need(same(candidate['current'], data['current']), 'whole source-bound current canonical fact query capacity and chapter roles')
    fact.check_failed_size(candidate['failures']['preparation-size'])
    need(same(candidate['failures'], data['failures']), 'whole original first failures retain distinct actual and declared statuses')
    return dict(owner=PLAN['owner'], revision=PLAN['revision'], candidate=pin(canonical(candidate)),
        contracts=header['contracts'], source=header['source'], namespaces=header['namespaces'],
        admission=fact.authenticate(), source_contracts=source['qualification'], meanings=means['qualification'], links=links,
        canonical=pin(canonical(header['canonical'])), current=pin(canonical(candidate['current'])),
        failures={role: pin(canonical(row)) for role, row in candidate['failures'].items()},
        boundary=PLAN['condition'], assumptions=header['assumptions'])


def source_meaning_links(candidate, source, meanings):
    assertions = source['candidate']['assertions']
    rows = candidate['links']
    modes = ('ordinary', 'storable', 'controls')
    join = meanings['candidate']['children']['join']['modes']
    need([mode['mode'] for mode in join] == list(modes) and type(rows) is list
         and len(rows) == len(assertions) * len(modes), 'complete original source operand truth link domain')
    indexed = {}
    keys = {'mode', 'index', 'role', 'context', 'source', 'native', 'meaning', 'basis', 'operand', 'outcome'}
    for row in rows:
        need(type(row) is dict and set(row) == keys and type(row['index']) is int
             and row['mode'] in modes and type(row['outcome']) is int and row['outcome'] in (0, 1),
             'closed typed complete original consumer link')
        key = row['mode'], row['index']
        need(key not in indexed, 'unique original mode source assertion link')
        indexed[key] = row
    qualified = []
    for index, assertion in enumerate(assertions):
        role = 'remaining' if assertion['context']['helper'] is None else 'helper'
        for mode, original in zip(modes, join, strict=True):
            row = original['consumers'][index]
            value = row['meaning']
            need(type(row['index']) is int and row['index'] == index and row['role'] == role
                 and same(row['source_contract'], assertion) and same(value['source_assertion'], assertion),
                 'whole independently admitted original source to consumer meaning join')
            need(type(row['outcome']) is type(value['outcome']) is int and row['outcome'] == value['outcome']
                 and same({key: row['native'][key] for key in value['operand']}, value['operand']),
                 'whole independently rederived typed original operand and comparison outcome')
            wanted = dict(mode=mode, index=index, role=role, context=assertion['context'], source=pin(canonical(assertion)),
                native=pin(canonical(row['native'])), meaning=pin(canonical(value)), basis=pin(canonical({name: part for name, part in value.items() if name not in ('operand', 'outcome', 'source_assertion')})),
                operand=value['operand'], outcome=value['outcome'])
            need((mode, index) in indexed and same(indexed[(mode, index)], wanted),
                 'whole independently rederived source-derived original consumer link')
            qualified.append(dict(mode=mode, index=index, role=role, source=wanted['source'], meaning=wanted['meaning'],
                operand=pin(canonical(wanted['operand'])), outcome=wanted['outcome']))
    need(len(indexed) == len(qualified), 'every source meaning operand truth link consumed exactly once')
    return dict(population=len(qualified), bindings=qualified,
        condition='Every whole original source expression/context binds its independently rederived typed meaning/operand/outcome. Native flags supply no independent truth; original Storable/synthetic/private limits retain.')


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--candidate', default='candidate.json.gz')
    parser.add_argument('--save', action='store_true')
    args = parser.parse_args()
    need(Path(args.candidate).name == args.candidate and args.candidate.endswith('.json.gz'), 'ordinary own complete original-consumer candidate')
    result = check(load_product(args.candidate))
    if args.save:
        need(args.candidate == 'candidate.json.gz', 'only complete positive original consumer acceptance publishes')
        save('qualification.json', result)
    print(SUCCESS, end='')
