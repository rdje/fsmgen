"""Independent fixed-source canonical proposal and complete meaning correspondence."""
from canonical_common import *

# These independently declared deltas, not candidate fields or the producer,
# bound the only new finite meaning and the exact reviewed contractions.
DECLARED = [
    ('Raw bodies/lossless grammar/source joins qualify.', 'Whole cause/raw/empty/nested source joins/lossless grammar qualify.'),
    ('Finite contexts qualify helper/consumer/parser locations', 'Finite contexts bind helper/consumer/parser locations'),
    ('texts/operation spans separately from cause/operand truth;', 'texts/operation spans apart from cause/operand truth;'),
    ('detached private copy preserves outer caller.', 'detached private copy keeps outer caller.'),
    ('Complete source-chain/separate probe replay required.', 'Full source-chain/separate probe replay needed.'),
]
SUCCESS = 'PASS independent complete non-growing source-bound cause canonical preparation; production and cause-parent acceptance remain open.\n'


def context():
    sources, original = original_inputs()
    need(same(load_product('canonical-sources.json.gz'), {name: body.decode() for name, body in sources.items()}),
         'whole fixed original canonical beforeimage collection')
    public = original_public()
    prior = public['historical']()
    current = load_product('current-before.json.gz')
    public['check'](current, sources, prior, public['authority'](prior))
    review = json.loads((BASE / 'meaning-plan.json').read_bytes())
    need(set(review) == {'changes', 'review'} and len(review['changes']) == len(DECLARED), 'complete declared meaning review population')
    for i, (change, (old, new)) in enumerate(zip(review['changes'], DECLARED, strict=True)):
        need(set(change) == {'kind', 'old', 'new', 'meaning'} and change['old'] == old and change['new'] == new
             and change['kind'] == ('extension' if i == 0 else 'equivalent') and type(change['meaning']) is str and bool(change['meaning']),
             'independent exact declared finite extension and equivalent contractions')
    return sources, original, current, review, prior


def check(candidate, inputs=None):
    sources, original, current, review, prior = context() if inputs is None else inputs
    need(set(candidate) == {'schema_version', 'owner', 'revision', 'target', 'before', 'after', 'before_identity', 'after_identity',
        'correspondence', 'review', 'previous', 'proposed', 'authority', 'canonical_members', 'queries', 'scope'}
         and type(candidate['schema_version']) is int and candidate['schema_version'] == 1
         and candidate['owner'] == PLAN['owner'] and candidate['revision'] == PLAN['revision'] and candidate['target'] == PLAN['target'],
         'closed complete prospective cause canonical schema')
    need(same(candidate['scope'], scope(original)), 'whole original native private source and preparation boundary')
    need(same(candidate['canonical_members'], {name: pin(body) for name, body in sources.items()}), 'complete own canonical source membership and bodies')
    before = sources[PLAN['target']].decode()
    after = before
    for old, new in DECLARED:
        need(after.count(old) == 1, 'unique independent original meaning allocation')
        after = after.replace(old, new, 1)
    need(candidate['before'] == before and candidate['before_identity'] == pin(before.encode()), 'whole original canonical target beforeimage')
    need(candidate['after'] == after and candidate['after_identity'] == pin(after.encode()), 'whole independently declared finite cause meanings')
    need(before.split('---\n', 2)[:2] == after.split('---\n', 2)[:2], 'every original fact question evidence probe and metadata byte retains')
    parts = before.split('\n\n')
    rows = candidate['correspondence']
    need(len(rows) == len(parts) and same([row['index'] for row in rows], list(range(len(parts)))), 'complete ordered whole meaning correspondence population')
    consumed = []
    for index, part in enumerate(parts):
        wanted = part
        used = []
        for i, (old, new) in enumerate(DECLARED):
            if old in part:
                need(part.count(old) == 1, 'own complete paragraph meaning occurrence')
                wanted = wanted.replace(old, new, 1)
                used.append(i)
        row = rows[index]
        need(set(row) == {'index', 'before', 'after', 'change_ids', 'kind'} and row['before'] == part and row['after'] == wanted
             and same(row['change_ids'], used)
             and row['kind'] == ('unchanged' if part == wanted else 'explicit_finite_extension_or_equivalent_compaction'),
             'whole own old new paragraph and reviewed meaning allocation')
        consumed.extend(used)
    need(sorted(consumed) == list(range(len(DECLARED))) and '\n\n'.join(row['after'] for row in rows) == after
         and same(candidate['review'], review), 'whole explicit review and every declared change consumed once')
    cards = {name: body for name, body in sources.items() if Path(name).parent == Path('docs/knowledge')}
    previous = metrics(cards)
    cards[PLAN['target']] = after.encode()
    measured = metrics(cards)
    authority = next(row for row in original[REGISTRY] if row.get('surface_id') == 'knowledge_cards')
    need(same(candidate['previous'], previous) and same(candidate['proposed'], measured), 'complete independently measured canonical capacity')
    need(same(candidate['authority'], authority), 'unchanged complete canonical capacity authority')
    for key, value in measured.items():
        allowed = min(authority['enforcement_ceilings'][key], authority['baseline'][key] + authority['transition']['max_growth'][key])
        need(type(value) is int and value <= previous[key] and value <= allowed, 'non-growing prospective canonical metric: ' + key)
    need(len(after.encode()) <= len(before.encode()), 'non-growing whole target file')
    prospective = dict(sources, **{PLAN['target']: after.encode()})
    allocation = prior['metadata']['allocation'](sources)['rows']
    need(prior['metadata']['allocation'](prospective)['rows'] == allocation, 'complete prospective question and fact ownership conserves')
    need(set(candidate['queries']) == {'direct', 'cached'}, 'complete distinct native query role population')
    for role, row in candidate['queries'].items():
        need(type(row['status']) is int and row['status'] == 0, 'typed actual original query success')
        need(same(row, current['queries'][role]) and row['stdout'] == allocation, 'whole own source-derived actual direct cached question allocation')
    return dict(owner=PLAN['owner'], revision=PLAN['revision'], candidate=pin(canonical(candidate)),
        source_members=pin(canonical(candidate['canonical_members'])), previous=previous, proposed=measured,
        correspondence=pin(canonical(rows)), scope=scope(original),
        condition='Whole byte correspondence and explicit engineering equivalence review, supported by qualified original finite source/cause products. No universal natural-language proof or live publication is inferred.')


if __name__ == '__main__':
    candidate = json.loads((BASE / 'candidate.json').read_bytes())
    result = check(candidate)
    save('qualification.json', result)
    print(SUCCESS, end='')
