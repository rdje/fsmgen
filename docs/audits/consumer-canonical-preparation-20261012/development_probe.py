"""Declared development-only whole interface probe; no formal admission."""
from canonical_common import *
import intake
import prepare
import reader
import controls
import publish

roles = intake.derive()
source = intake.live(roles)
sources = canonical_sources()
names = [PLAN['meaning'] + '/proof.json', PLAN['meaning'] + '/qualification.json', REGISTRY]
raw = fixed(names)
original = {name: [json.loads(line) for line in body.splitlines()] if name == REGISTRY else json.loads(body)
            for name, body in raw.items()}
public = original_public(); prior = public['historical']()
current = public['current_input'](prior, sources)
public['check'](current, sources, prior, public['authority'](prior))
review = json.loads((BASE / 'meaning-plan.json').read_bytes())
need([(row['old'], row['new']) for row in review['changes']] == reader.DECLARED, 'development independently declared review allocation')
inputs = (sources, original, current, review, prior)
candidate = prepare.construct(sources, original, current, review)
qualification = reader.check(candidate, inputs)
falsification = controls.qualify(candidate, inputs)
before = {name: Path(name).read_bytes() for name in (TASK, BOOK, REGISTRY, 'MEMORY.md', 'docs/TASK_TREE.md')}
after, measured = publish.transformation(before)
need(all(Path(name).read_bytes() == body for name, body in before.items()), 'development does not publish maintained sources')
save_product('development-products.json.gz', dict(source=source, source_roles=pin(canonical(roles)), candidate=candidate,
    qualification=qualification, controls=falsification, publication={name: body.decode() for name, body in after.items()},
    publication_metrics=measured, role='Development-only complete interface/capacity/refusal/publication probe. Caught library ValueErrors are not native status-1 controls.'))
print('PASS development-only complete canonical proposal, capacity, controls and publication interfaces.')
