"""Save complete current canonical/query/capacity inputs without changing them."""
import argparse
from container_common import *
p = argparse.ArgumentParser(description=__doc__)
p.add_argument('epoch', choices=('before', 'after'))
a = p.parse_args()
current = public()
sources = current['sources']()
prior = current['historical']()
record = current['current_input'](prior, sources)
current['check'](record, sources, prior, current['authority'](prior))
save_product('canonical-' + a.epoch + '.json.gz', {name: body.decode() for name, body in sources.items()})
save_product('current-' + a.epoch + '.json.gz', record)
print('PASS complete current unchanged canonical/query/capacity input: ' + a.epoch + '.')
