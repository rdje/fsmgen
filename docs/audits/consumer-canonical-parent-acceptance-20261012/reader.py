"""Independently qualify complete unchanged canonical-parent acceptance."""
import argparse
from parent_common import *
import model
import interfaces

SUCCESS = 'PASS complete unchanged consumer canonical acceptance; original consumer parent and higher owners remain separate.\n'


def check(candidate):
    data = model.inputs()
    header = model.header(data)
    need(type(candidate) is dict and set(candidate) == set(header) | {'admission', 'meanings', 'current', 'failures'}
         and type(candidate['schema_version']) is int, 'closed complete canonical-parent schema')
    need(same({key: candidate[key] for key in header}, header), 'whole unchanged canonical source descendant and boundary contract custody')
    public = data['public']
    fact = public['consumer_fact']
    admitted = fact.published(candidate['admission'])
    need(admitted.encode() == data['canonical'][PLAN['target']], 'whole admitted unchanged canonical consumer publication')
    means = interfaces.meanings(candidate['meanings'])
    qualified_path = PLAN['meaning'] + '/qualification.json'
    need(same(means['qualification'], json.loads(fixed([qualified_path])[qualified_path])), 'whole freshly rederived complete original consumer meanings')
    public['check'](candidate['current'], data['canonical'], data['prior'], public['authority'](data['prior']))
    need(same(candidate['current'], data['current']), 'whole source-bound current canonical fact query capacity and chapter roles')
    fact.check_failed_size(candidate['failures']['preparation-size'])
    need(same(candidate['failures'], data['failures']), 'whole original first failures retain distinct actual and declared statuses')
    return dict(owner=PLAN['owner'], revision=PLAN['revision'], candidate=pin(canonical(candidate)),
        contracts=header['contracts'], source=header['source'], namespaces=header['namespaces'],
        admission=fact.authenticate(), meanings=means['qualification'],
        canonical=pin(canonical(header['canonical'])), current=pin(canonical(candidate['current'])),
        failures={role: pin(canonical(row)) for role, row in candidate['failures'].items()},
        boundary=PLAN['condition'], assumptions=header['assumptions'])


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--candidate', default='candidate.json.gz')
    parser.add_argument('--save', action='store_true')
    args = parser.parse_args()
    need(Path(args.candidate).name == args.candidate and args.candidate.endswith('.json.gz'), 'ordinary own complete canonical-parent candidate')
    result = check(load_product(args.candidate))
    if args.save:
        need(args.candidate == 'candidate.json.gz', 'only complete positive canonical acceptance publishes')
        save('qualification.json', result)
    print(SUCCESS, end='')
