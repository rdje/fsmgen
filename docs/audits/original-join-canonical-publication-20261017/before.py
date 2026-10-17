"""Exercise the actual predecessor against the exact committed prospective card."""
import gzip,hashlib,json,sys
from pathlib import Path
sys.path.insert(0,'scripts')
import check_record_value_publication as public
BASE=Path(__file__).resolve().parent
PLAN=json.loads((BASE/'plan.json').read_bytes())
raw=Path(PLAN['preparation'],'v3-candidate.json.gz').read_bytes()
assert len(raw)==601228 and hashlib.sha256(raw).hexdigest()=='ceb890ac7ca617bbdb518b340577d91d7754cbdd24567e8b3ed833c1457821b1'
candidate=json.loads(gzip.decompress(raw))
canonical=public.sources();prior=public.historical()
public.check(public.current_input(prior,canonical),canonical,prior,public.authority(prior))
assert canonical[candidate['target']].decode()==candidate['before']
prospective=dict(canonical,**{candidate['target']:candidate['after'].encode()})
record=public.current_input(prior,prospective)
try:
 public.check(record,prospective,prior,public.authority(prior))
except ValueError as error:
 assert str(error)=='complete current target meanings questions metadata and replay routes'
 print('REFUSED complete prepared original joined meanings at unchanged predecessor target contract.',flush=True)
 raise SystemExit(1)
raise AssertionError('predecessor accepted unadmitted original joined meanings')
