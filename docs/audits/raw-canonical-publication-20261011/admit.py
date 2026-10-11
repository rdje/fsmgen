"""Preflight complete raw admission before changing a canonical product."""
import json
from pathlib import Path
import sys
from capture import BASE, canonical, pin, save

sys.path.insert(0, 'scripts')
import record_value_raw_fact as fact

qualified = fact.authenticate()
candidate = fact.admission()
published = fact.published(candidate)
assert Path(fact.CARD).read_bytes() == candidate['before'].encode()
save('admission.json', dict(qualification=qualified, candidate=candidate,
    before=candidate['before'], after=published, before_identity=pin(candidate['before'].encode()),
    after_identity=pin(published.encode()),
    condition='The preparation is unchanged and complete. Its original source/actual proof retains its declared epoch. The current admission date changes at equal byte size; no old fact, question, evidence or probe changes. Production is still unpublished.'))
print('PASS complete admitted raw source/body/namespace and non-growing canonical preflight; production remains unpublished.')
