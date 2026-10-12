"""Admit the whole preparation while production canonical bytes stay unchanged."""
import sys
from publication_common import *

previous = sys.path[:]
try:
    sys.path.insert(0, 'scripts')
    import record_value_consumer_fact as fact
finally:
    sys.path[:] = previous

candidate = fact.admission()
after = fact.published(candidate)
qualification = fact.authenticate()
need(Path(fact.CARD).read_bytes() == candidate['before'].encode(), 'unchanged canonical production before admission')
save('admission.json', dict(qualification=qualification, candidate=candidate, before=candidate['before'], after=after))
print('PASS complete finite consumer source/candidate/native admission; live publication remains next.')
