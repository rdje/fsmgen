"""Retain the whole actual current canonical/query/native input after publication."""
import sys
from helper_common import *

previous = sys.path[:]
try:
    sys.path.insert(0, 'scripts')
    import check_record_value_publication as current
finally:
    sys.path[:] = previous

import argparse
parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('epoch', choices=('before', 'after'))
args = parser.parse_args()
sources = current.sources()
prior = current.historical()
record = current.current_input(prior, sources)
current.check(record, sources, prior, current.authority(prior))
save_product('canonical-' + args.epoch + '.json.gz', {name: body.decode() for name, body in sources.items()})
save_product('current-' + args.epoch + '.json.gz', record)
print('PASS complete current unchanged canonical meanings and whole source/query/capacity input: ' + args.epoch + '.')
