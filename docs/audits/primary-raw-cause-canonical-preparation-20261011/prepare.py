"""Propose source-bound canonical meanings without changing canonical production."""
from canonical_common import *


def proposed():
    sources, original = original_inputs()
    public = original_public()
    need(public['sources']() == sources, 'whole unchanged live canonical source domain')
    prior = public['historical']()
    current = public['current_input'](prior, sources)
    public['check'](current, sources, prior, public['authority'](prior))
    save_product('canonical-sources.json.gz', {name: body.decode() for name, body in sources.items()})
    save_product('current-before.json.gz', current)
    review = json.loads((BASE / 'meaning-plan.json').read_bytes())
    before = sources[PLAN['target']].decode()
    after = before
    for change in review['changes']:
        need(after.count(change['old']) == 1, 'unique exact prospective meaning')
        after = after.replace(change['old'], change['new'], 1)
    rows = []
    for index, (old, new) in enumerate(zip(before.split('\n\n'), after.split('\n\n'), strict=True)):
        rows.append(dict(index=index, before=old, after=new,
            change_ids=[i for i, change in enumerate(review['changes']) if change['old'] in old],
            kind='unchanged' if old == new else 'explicit_finite_extension_or_equivalent_compaction'))
    cards = {name: body for name, body in sources.items() if Path(name).parent == Path('docs/knowledge')}
    previous = metrics(cards)
    cards[PLAN['target']] = after.encode()
    measured = metrics(cards)
    authority = next(row for row in original[REGISTRY] if row.get('surface_id') == 'knowledge_cards')
    result = dict(schema_version=1, owner=PLAN['owner'], revision=PLAN['revision'], target=PLAN['target'],
        before=before, after=after, before_identity=pin(before.encode()), after_identity=pin(after.encode()),
        correspondence=rows, review=review, previous=previous, proposed=measured, authority=authority,
        canonical_members={name: pin(body) for name, body in sources.items()}, queries=current['queries'],
        scope=scope(original))
    save('candidate.json', result)
    return result


if __name__ == '__main__':
    proposed()
    print('Prepared complete non-growing cause canonical candidate; live canonical production remains unchanged.')
