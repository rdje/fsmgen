"""Independent whole-fact, route, source and capacity correspondence reader."""
import argparse
from preparation_inputs import *

DECLARED = [
    ('date: 2026-10-11\n', 'date: 2026-10-12\n'),
    ('Full source-chain/separate probe replay needed. Independent source models qualify typed consumer operands/truth, never\n'
     'passed flags; Storable kinds/synthetic trace opacity retain.',
     'Full source-chain/separate probe replay needed. Independent source models join all original context/cause/coordinate/typed\n'
     'consumer operands/truth, never passed flags; Storable kinds/synthetic trace opacity retain.'),
    ('consumer-parent/alias/semantic/cold/candidate-parent/hot/host-native stay open.',
     'higher parents/alias/semantic/cold/candidate-parent/hot/host-native stay open.'),
    ('coordinates/finite address roles qualify below.', 'coordinates/finite address roles qualify.'),
    ('Finite joins authenticate completed owners/fresh products.', 'Finite joins verify completed owners/fresh products.'),
    ('Copy interventions rebuild whole input/private typed graphs, readonly',
     'Copy trials rebuild whole input/private typed graphs, readonly'),
    ('Metadata guards/record recursion/cycles qualify; list recursion is bound, unexercised.',
     'Metadata guards/record recursion/cycles qualify; list recursion bound, unexercised.'),
    ('active `$operation` retains saved CODE handles.', 'active `$operation` holds saved CODE handles.'),
    ('Native refusals retain whole causes/class/HASH shape/within-capture identity for both observed empty blessed classes.',
     'Native refusals retain whole causes/class/HASH shape/within-capture identity of both observed empty blessed classes.'),
    ('Nested Metadata/new outer Value retain distinct class/phase roles and whole',
     'Nested Metadata/new outer Value keep distinct class/phase roles and whole'),
    ('Source associations precede raw intake;', 'Source joins precede raw intake;')]
SUCCESS = 'PASS independent complete non-growing original-join canonical preparation; production original parents and full alias remain separate.\n'


def check(candidate, ctx=None):
    ctx = context() if ctx is None else ctx
    sources, data = ctx['sources'], ctx['data']
    keys = {'schema_version', 'owner', 'revision', 'target', 'before', 'after', 'before_identity', 'after_identity',
            'correspondence', 'review', 'input_identities', 'contracts', 'scope', 'canonical_members', 'queries',
            'previous', 'proposed', 'authority'}
    need(type(candidate) is dict and set(candidate) == keys and type(candidate['schema_version']) is int
         and candidate['schema_version'] == 1 and candidate['owner'] == PLAN['owner']
         and candidate['revision'] == PLAN['revision'] and candidate['target'] == TARGET,
         'closed typed complete original-join canonical schema')
    need(same(candidate['input_identities'], data['identities']), 'complete own committed association input identities')
    need(same(candidate['contracts'], data['contracts']), 'every unchanged original parent and descendant contract')
    need(same(candidate['scope'], scope(data)), 'complete original assumptions failures native private and scope boundaries')
    need(same(candidate['canonical_members'], {name: pin(body) for name, body in sources.items()}),
         'every own canonical source membership and whole body')
    review = json.loads((BASE / 'proposal-review.json').read_bytes())
    need(set(review) == {'after', 'before', 'changes', 'condition', 'first_projection', 'header', 'meanings', 'target'}
         and same(review['changes'], DECLARED) and review['target'] == TARGET,
         'independent finite joined meaning and equivalent contraction review')
    before, after = sources[TARGET].decode(), sources[TARGET].decode()
    for old, new in DECLARED:
        need(after.count(old) == 1, 'unique independent original fact allocation')
        after = after.replace(old, new, 1)
    need(same(review['before'], dict(body=before, identity=pin(before.encode())))
         and same(review['after'], dict(body=after, identity=pin(after.encode()))), 'whole reviewed proposal before and after')
    first = review['first_projection']
    first_body = before
    for old, new in first['changes']:
        need(first_body.count(old) == 1, 'unique first static projection change')
        first_body = first_body.replace(old, new, 1)
    need(first_body == first['body'] and same(first['identity'], pin(first_body.encode()))
         and len(first_body.encode()) > len(before.encode()), 'first oversized static projection remains rejected without native-failure promotion')
    need(candidate['before'] == before and same(candidate['before_identity'], pin(before.encode())),
         'whole own original target beforeimage')
    need(candidate['after'] == after and same(candidate['after_identity'], pin(after.encode())),
         'whole independently allocated joined meanings and retained facts')
    before_header = before.split('---\n', 2)[1].replace('date: 2026-10-11\n', 'date: 2026-10-12\n', 1)
    need(after.split('---\n', 2)[1] == before_header, 'all original questions identifiers probes and header fields retain')
    for line in before.splitlines():
        if re.search(r'[0-9]', line) and not line.startswith('date: '):
            need(after.splitlines().count(line) == before.splitlines().count(line), 'all original numeric fact lines retain')
    parts = before.split('\n\n')
    rows = candidate['correspondence']
    need(type(rows) is list and len(rows) == len(parts), 'complete original paragraph population')
    consumed = []
    for index, part in enumerate(parts):
        wanted, used = part, []
        for i, (old, new) in enumerate(DECLARED):
            if old in part:
                need(part.count(old) == 1, 'unique own paragraph meaning allocation')
                wanted = wanted.replace(old, new, 1)
                used.append(i)
        expected = dict(index=index, before=part, after=wanted, change_ids=used,
                        kind='unchanged' if part == wanted else 'reviewed_join_or_equivalent')
        need(same(rows[index], expected), 'whole typed ordered original paragraph and reviewed meaning correspondence')
        consumed.extend(used)
    need(sorted(consumed) == list(range(len(DECLARED))) and '\n\n'.join(row['after'] for row in rows) == after
         and same(candidate['review'], review), 'every reviewed change consumed once and complete review retains')
    cards = {name: body for name, body in sources.items() if Path(name).parent == Path('docs/knowledge')}
    previous = metrics(cards)
    cards[TARGET] = after.encode()
    measured = metrics(cards)
    need(same(candidate['previous'], previous) and same(candidate['proposed'], measured),
         'complete typed independently measured non-growing capacity')
    need(same(candidate['authority'], ctx['authority']), 'unchanged whole collection and card capacity authority')
    for key, value in measured.items():
        row = ctx['authority']
        allowed = min(row['enforcement_ceilings'][key], row['baseline'][key] + row['transition']['max_growth'][key])
        need(type(value) is int and value <= previous[key] and value <= allowed, 'non-growing unchanged canonical allowance: ' + key)
    need(len(after.encode()) <= len(before.encode()), 'non-growing whole canonical target')
    allocation = ctx['prior']['metadata']['allocation'](sources)['rows']
    prospective = dict(sources, **{TARGET: after.encode()})
    need(same(ctx['prior']['metadata']['allocation'](prospective)['rows'], allocation),
         'complete prospective fact and question ownership conserves')
    need(same(candidate['queries'], ctx['current']['queries'])
         and set(candidate['queries']) == {'direct', 'cached'}
         and all(type(row['status']) is int and row['status'] == 0 and same(row['stdout'], allocation)
                 for row in candidate['queries'].values()), 'whole actual distinct direct and cached canonical question allocation')
    return dict(owner=PLAN['owner'], revision=PLAN['revision'], candidate=pin(canonical(candidate)),
        association=data['association'], contracts=pin(canonical(data['contracts'])),
        source_members=pin(canonical(candidate['canonical_members'])), previous=previous, proposed=measured,
        correspondence=pin(canonical(rows)), scope=scope(data), condition=PLAN['condition'])


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--candidate', default='candidate.json.gz')
    parser.add_argument('--save', action='store_true')
    args = parser.parse_args()
    path = BASE / args.candidate
    need(Path(args.candidate).name == args.candidate and args.candidate.endswith('.json.gz')
         and stat.S_ISREG(path.lstat().st_mode) and path.stat().st_dev == Path.cwd().stat().st_dev,
         'ordinary own same-volume complete canonical candidate')
    result = check(load_product(args.candidate))
    if args.save:
        need(args.candidate in ('candidate.json.gz', 'v3-candidate.json.gz'), 'only whole positive proposal publishes qualification')
        save(('v3-' if args.candidate.startswith('v3-') else '') + 'qualification.json', result)
    print(SUCCESS, end='')
