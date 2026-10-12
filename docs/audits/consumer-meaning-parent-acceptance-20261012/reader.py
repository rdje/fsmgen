"""Admit complete unchanged meaning acceptance through every independent child."""
import argparse
from acceptance_common import *
import meaning_readers
import parent_model as model

SUCCESS = 'PASS independent unchanged complete consumer meanings and descendant contracts; canonical/original parent and higher owners retain.\n'


def check(candidate, *, development=False):
    data = model.inputs(development=development)
    header = model.header(data)
    need(type(candidate) is dict and set(candidate) == set(header) | {'children'}
         and type(candidate['schema_version']) is int, 'closed complete original meaning-parent schema')
    need(same({key: candidate[key] for key in header}, header), 'whole unchanged parent/descendant/source/boundary contract custody')
    need(type(candidate['children']) is dict and candidate['children'].keys() == data['children'].keys(),
         'complete independent meaning child domain')
    # Source expressions and actual comparisons, rather than recorded passed
    # flags or a narrower successful child, must admit every provided meaning.
    admissions = {role: meaning_readers.admit(role, candidate['children'][role])
                  for role in ('join', 'helper', 'remaining')}
    for role, admitted in admissions.items():
        need(same(admitted['qualification'], data['qualifications'][role])
             and same(candidate['children'][role], data['children'][role]),
             'whole freshly rederived committed child meaning and original custody')
    join = candidate['children']['join']
    allocations = []
    for mi, mode in enumerate(model.MODES):
        rows = join['modes'][mi]['consumers']
        need(join['modes'][mi]['mode'] == mode and len(rows) == len(data['prepared']['assertions']) == 125,
             'complete unchanged original meaning-parent assertion mode')
        accepted = []
        for index, (row, assertion, native) in enumerate(zip(rows, data['prepared']['assertions'], data['native'][mode], strict=True)):
            role = 'remaining' if assertion['context']['helper'] is None else 'helper'
            child = candidate['children'][role]['modes'][mi]['consumers'][index]
            other = candidate['children']['helper' if role == 'remaining' else 'remaining']['modes'][mi]['consumers'][index]
            need(type(row['index']) is int and row['index'] == index and row['role'] == role
                 and same(row['source_contract'], assertion) and same(child['source_context'], assertion['context'])
                 and same(child['meaning'], row['meaning']) and other['meaning'] is None,
                 'every own source assertion meaning and exact complementary descendant join')
            need(same(row['native'], native) and same(child['native'], native) and same(other['native'], native)
                 and type(row['outcome']) is int and row['outcome'] == row['meaning']['outcome'],
                 'every complete original typed operand observation and independently qualified outcome retains')
            accepted.append(dict(index=index, source=pin(canonical(assertion)), role=role,
                meaning=pin(canonical(row['meaning'])), native=pin(canonical(native)), outcome=row['outcome']))
        allocations.append(dict(mode=mode, consumers=accepted))
    return dict(owner=PLAN['owner'], revision=PLAN['revision'], candidate=pin(canonical(candidate)),
        contracts=model.contracts(), allocations=allocations,
        admissions={role: {key: row[key] for key in ('qualification', 'custody')} for role, row in admissions.items()},
        inputs=data['identities'], source_roles=data['source_roles'], boundary=PLAN['condition'],
        phase='development-only; no formal acceptance' if development else 'complete independent meaning acceptance',
        assumptions=header['assumptions'])


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--candidate', default='candidate.json.gz')
    parser.add_argument('--save', action='store_true')
    args = parser.parse_args()
    need(Path(args.candidate).name == args.candidate and args.candidate.endswith('.json.gz'), 'ordinary own complete meaning candidate route')
    result = check(load_product(args.candidate))
    if args.save:
        need(args.candidate == 'candidate.json.gz', 'only complete positive meaning acceptance publishes')
        save('qualification.json', result)
    print(SUCCESS, end='')
