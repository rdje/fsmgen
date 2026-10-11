"""Exercise the existing current factory on the complete prepared candidate."""
import json
from pathlib import Path
import sys

sys.path.insert(0, 'scripts')
import check_record_value_publication as current

candidate = json.loads(Path('docs/audits/raw-canonical-preparation-20261011/candidate.json').read_bytes())
prior = current.historical()
canonical = current.sources()
record = current.current_input(prior, canonical)
target = candidate['target']
assert canonical[target] == candidate['before'].encode()
canonical[target] = candidate['after'].encode()
record['cards'][target] = candidate['after']
record['source_members'][target] = current.identity(canonical[target])
physical = {p: raw for p, raw in canonical.items() if Path(p).parent == Path('docs/knowledge')}
record['census'] = prior['public']['metrics'](physical)
try:
    current.check(record, canonical, prior, current.authority(prior))
except ValueError as error:
    assert str(error) == 'complete current target meanings questions metadata and replay routes'
    print('REFUSED prepared finite raw update at existing target-meaning contract: ' + str(error))
    raise SystemExit(1)
raise AssertionError('existing factory unexpectedly admits the new finite raw meaning')
