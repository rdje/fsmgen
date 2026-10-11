"""Retain the whole actual current canonical/query/native input after publication."""
import sys
from publication_common import *

previous = sys.path[:]
try:
    sys.path.insert(0, 'scripts')
    import check_record_value_publication as current
finally:
    sys.path[:] = previous

sources = current.sources()
prior = current.historical()
record = current.current_input(prior, sources)
current.check(record, sources, prior, current.authority(prior))
save_product('canonical-after.json.gz', {name: body.decode() for name, body in sources.items()})
save_product('current-after.json.gz', record)
print('PASS complete current cause meanings and whole source/query/capacity input.')
