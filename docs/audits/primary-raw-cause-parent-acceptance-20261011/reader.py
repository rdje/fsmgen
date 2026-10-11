"""Independently bind complete child meanings, native roles and full obligations."""
import argparse
from parent_common import *
import context

SUCCESS = 'PASS independent complete unchanged finite cause/canonical parent composition; all original source/native/private limits retain.\n'


def check(candidate):
    expected = context.expected()
    need(type(candidate) is dict and set(candidate) == {
        'schema_version', 'owner', 'revision', 'source', 'contracts', 'inputs', 'current', 'canonical', 'boundary'}
         and type(candidate['schema_version']) is int and candidate['schema_version'] == 1
         and candidate['owner'] == PLAN['owner'] and candidate['revision'] == PLAN['revision'],
         'closed complete owned cause-parent schema')
    need(same(candidate['source'], expected['source']), 'whole original current source native custody join')
    need(same(candidate['contracts'], expected['contracts']), 'every whole unchanged original cause canonical descendant obligation')
    need(same(candidate['boundary'], expected['boundary']), 'whole original assumptions failures native private boundary')
    need(type(candidate['inputs']) is dict and set(candidate['inputs']) == set(expected['inputs']), 'complete original child input domains')
    native, failures, replays = (candidate['inputs'][key] for key in ('native', 'failures', 'replays'))
    need(set(native) == set(expected['inputs']['native']) and set(failures) == set(expected['inputs']['failures'])
         and set(replays) == set(context.REPLAYS), 'complete exact primary coordinate address failure and replay membership')
    need(all(type(row['status']) is int and row['status'] == 0 for row in (*native.values(), *replays.values()))
         and all(type(row['status']) is int and row['status'] == 1
                 and type(row['expected_status']) is int and row['expected_status'] == 0 for row in failures.values()),
         'actual typed original successes and unreclassified first failures')
    need(same(native, expected['inputs']['native']), 'whole exact original primary coordinate address commands programmes and terminals')
    need(same(failures, expected['inputs']['failures']), 'whole original first failure programme command and terminal custody')
    need(same(replays, expected['inputs']['replays']), 'whole own dated child replays and native source roles')
    need(same(candidate['inputs']['proofs'], expected['inputs']['proofs'])
         and same(candidate['inputs']['fixed_members'], expected['inputs']['fixed_members']),
         'complete independent association raw canonical and prerequisite meaning custody')
    sources = {name: body.encode() for name, body in candidate['canonical'].items()}
    need(same(candidate['canonical'], expected['canonical']), 'complete current canonical facts questions evidence and probes')
    public = original_public()
    prior = public['historical']()
    public['check'](candidate['current'], sources, prior, public['authority'](prior))
    need(same(candidate['current'], expected['current']), 'whole own current source query capacity native role')
    return dict(owner=PLAN['owner'], revision=PLAN['revision'], product=pin(canonical(candidate)),
        source=pin(canonical(candidate['source'])), contracts=pin(canonical(candidate['contracts'])),
        inputs=pin(canonical(candidate['inputs'])), canonical=pin(canonical(candidate['canonical'])),
        current=pin(canonical(candidate['current'])), boundary=candidate['boundary'])


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--candidate', default='candidate.json.gz')
    parser.add_argument('--save', action='store_true')
    args = parser.parse_args()
    need(Path(args.candidate).name == args.candidate and args.candidate.endswith('.json.gz'), 'ordinary own whole parent candidate')
    result = check(load_product(args.candidate))
    if args.save:
        need(args.candidate == 'candidate.json.gz', 'only whole positive parent admission may publish')
        save('qualification.json', result)
    print(SUCCESS, end='')
