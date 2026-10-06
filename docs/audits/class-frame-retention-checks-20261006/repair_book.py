"""Apply only the qualified literal option repair, preserving first publication."""
import copy
import json
from pathlib import Path

BASE = Path('docs/audits/record-value-class-frame-retention-20261006')
CHECKS = Path('docs/audits/class-frame-retention-checks-20261006')
ns = {'__name__':'repair_retention_option','__file__':str(BASE / 'verify.py')}
exec(compile((BASE / 'verify.py').read_bytes(),str(BASE / 'verify.py'),'exec'),ns)
load,identity,require = (ns[k] for k in ('load','identity','require'))
record = load(BASE / 'book-change.json'); chapter = Path(record['chapter'])
require(chapter.read_text() == record['after'],'whole first retention guide before option repair')
prior = record['after']; after = ns['module'](BASE / 'book.py')['transform'](record['before'])
require(after == prior.replace('The additional --live-unchanged check','The additional `--live-unchanged` check'),
        'exact sole source repair for native option literal')
for root,name in ((BASE,'book-change.json'),(CHECKS,'publication-proof.json'),(CHECKS,'publication-check.json')):
    source = root / name; target = CHECKS / ('first-' + name)
    require(not target.exists() and source.is_file() and not source.is_symlink() and source.stat().st_dev == Path.cwd().stat().st_dev,'exact unsealed first source product retention')
    target.write_bytes(source.read_bytes()); require(target.read_bytes() == source.read_bytes(),'whole first source product verified copy')
    source.unlink()
updated = copy.deepcopy(record); updated['after'] = after; updated['after_identity'] = identity(after.encode())
updated['actual']['bytes_total'] += len(after.encode())-len(prior.encode())
updated['authority_after']['reference_contract']['aggregate_change']['delta']['bytes_total'] += len(after.encode())-len(prior.encode())
registry = Path('doctrine/live_document_size/surfaces.jsonl'); lines = registry.read_text().splitlines()
require(next(json.loads(s) for s in lines if json.loads(s).get('surface_id') == 'shipped_behavior') == record['authority_after'],'exact prior source aggregate before literal repair')
ns['save']('book-change.json',updated); chapter.write_text(after)
registry.write_text('\n'.join(json.dumps(updated['authority_after'],sort_keys=True,separators=(',',':')) if json.loads(s).get('surface_id') == 'shipped_behavior' else s for s in lines) + '\n')
print('PASS exact inline-code option repair; complete first publication and failed native render retained, all other source meanings and ceilings unchanged.')
