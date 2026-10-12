"""Construct the explicitly reviewed finite proposal without publishing it."""
from preparation_inputs import *


def propose(ctx):
    sources, data = ctx['sources'], ctx['data']
    review = json.loads((BASE / 'proposal-review.json').read_bytes())
    before, after = sources[TARGET].decode(), sources[TARGET].decode()
    for old, new in review['changes']:
        need(after.count(old) == 1, 'unique reviewed prospective meaning')
        after = after.replace(old, new, 1)
    rows = []
    for index, (old, new) in enumerate(zip(before.split('\n\n'), after.split('\n\n'), strict=True)):
        rows.append(dict(index=index, before=old, after=new,
            change_ids=[i for i, (text, _) in enumerate(review['changes']) if text in old],
            kind='unchanged' if old == new else 'reviewed_join_or_equivalent'))
    cards = {name: body for name, body in sources.items() if Path(name).parent == Path('docs/knowledge')}
    previous = metrics(cards)
    cards[TARGET] = after.encode()
    return dict(schema_version=1, owner=PLAN['owner'], revision=PLAN['revision'], target=TARGET,
        before=before, after=after, before_identity=pin(before.encode()), after_identity=pin(after.encode()),
        correspondence=rows, review=review, input_identities=data['identities'], contracts=data['contracts'],
        scope=scope(data), canonical_members={name: pin(body) for name, body in sources.items()},
        queries=ctx['current']['queries'], previous=previous, proposed=metrics(cards), authority=ctx['authority'])
