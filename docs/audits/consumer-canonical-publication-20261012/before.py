"""A genuine old-factory refusal of the complete prepared candidate."""
import sys
from publication_common import *

previous = sys.path[:]
try:
    sys.path.insert(0, 'scripts')
    public = {'__name__': 'original_current_factory', '__file__': 'scripts/check_record_value_publication.py'}
    body = (BASE / 'before-factory.py.txt').read_bytes()
    need(body == fixed(['scripts/check_record_value_publication.py'])['scripts/check_record_value_publication.py'],
         'whole fixed predecessor factory')
    exec(compile(body, public['__file__'], 'exec'), public)
finally:
    sys.path[:] = previous
candidate = json.loads((Path(PLAN['preparation']) / 'candidate.json').read_bytes())
sources = public['sources']()
need(sources[PLAN['target']] == candidate['before'].encode(), 'whole original live canonical predecessor')
prior = public['historical']()
record = public['current_input'](prior, sources)
public['check'](record, sources, prior, public['authority'](prior))
sources[PLAN['target']] = candidate['after'].encode()
record['cards'][PLAN['target']] = candidate['after']
record['source_members'] = {name: pin(raw) for name, raw in sources.items()}
save_product('before-proposal.json.gz', dict(record=record, canonical={name: body.decode() for name, body in sources.items()}))
try:
    public['check'](record, sources, prior, public['authority'](prior))
except ValueError as error:
    need(str(error) == 'complete current target meanings questions metadata and replay routes', 'intended predecessor refusal')
    print('REFUSED complete prepared consumer meanings at unchanged predecessor target contract.')
    raise SystemExit(1)
raise ValueError('old factory accepted unadmitted consumer meanings')
