"""Development-only complete wrapper/publication preflight before formal freeze."""
from publication_common import *
import publish

import intake
import verify
contracts = verify.contracts()
roles = intake.derive()
source = intake.live(roles)
fact = publish.fact
candidate = fact.admission()
need(fact.published(candidate) == candidate['after'], 'whole candidate development correspondence')
admitted = fact.authenticate()
names = (TASK, BOOK, REGISTRY, 'MEMORY.md', 'docs/TASK_TREE.md', fact.CARD)
before = {name: Path(name).read_bytes() for name in names}
after, measured = publish.transformation(before)
need(all(Path(name).read_bytes() == body for name, body in before.items()), 'pure development proposal preserves production')
need(nodes(after[TASK])[PLAN['parent']] == nodes(before[TASK])[PLAN['parent']], 'canonical parent remains unchanged')
# The unique claim-bearing UTF-8 line must keep its stable inventory identity.
protected = b'Perl reader checks captured UTF-8 bytes and lossless physical reconstruction;'
need(before[BOOK].count(protected) == after[BOOK].count(protected) == 1, 'stable complete encoding claim line')
import re
for line in before[BOOK].splitlines():
    if re.search(rb'\d', line) and not line.startswith(b'scripts/run_with_ram_guard.sh'):
        need(after[BOOK].count(line) == before[BOOK].count(line), 'all quantitative book claim lines retain')
save_product('development-source-proposal.json.gz', dict(before={name: pin(body) for name, body in before.items()},
    after={name: body.decode() for name, body in after.items()}, measured=measured, admitted=admitted))
print('PASS development-only complete admitted wrapper and pure non-growing publication; every resume health dimension checked.')
