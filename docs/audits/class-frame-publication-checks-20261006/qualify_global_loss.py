"""Expose whole-population losses in the unpublished target-only reader sketch."""
import copy
import json
from pathlib import Path

BASE = Path('docs/audits/record-value-class-frame-publication-20261006')
CHECKS = Path('docs/audits/class-frame-publication-checks-20261006')
ns = {'__name__':'prospective_global_loss','__file__':str(BASE / 'verify.py')}
exec(compile((BASE / 'verify.py').read_bytes(),str(BASE / 'verify.py'),'exec'),ns)
source = ns['load'](BASE / 'source-model.json')
rows = source['allocation']['rows']; ids = {Path(p).stem for p in ns['PATHS']}
record = dict(cards=source['cards'],chapter=ns['book']['transform'](ns['git'](ns['CHAPTER']).decode()),
    tooling_chapter=ns['git'](ns['TOOLING_CHAPTER']).decode(),census=source['after'],surface=source['surface'],source_budget=source['source_budget'],
    queries={role:dict(command=['knowledge-map/scripts/query_knowledge_map.sh','--all'] + (['--no-cache'] if role=='direct' else []),
        status=0,stdout=rows,stderr='') for role in ('direct','cached')})
ns['check_current'](record)
line = next(line for line in rows.splitlines() if not ids.intersection(line.split('\t')[1].split(',')))
question_loss = copy.deepcopy(record); question_loss['queries']['direct']['stdout'] = rows.replace(line + '\n','',1)
ns['require'](question_loss != record,'genuine global question intervention')
ns['check_current'](question_loss)
member_loss = copy.deepcopy(record); member_loss['census']['files'] -= 1
ns['check_current'](member_loss)
output = CHECKS / 'first-global-loss.json'; ns['require'](not output.exists(),'first global loss evidence cannot overwrite')
output.write_text(json.dumps(dict(positive='accepted',lost_non_target_question='accepted',lost_physical_population='accepted',
    source_model=ns['identity']((BASE / 'source-model.json').read_bytes()),programme=ns['identity']((BASE / 'verify.py').read_bytes()),
    removed_row=line,scope='Source-constructed predicate vectors only, never actual query receipts or live publication. The unpublished sketch must bind complete global ownership and physical members before publication.'),sort_keys=True,indent=2) + '\n')
print('ROOT CAUSE: unpublished target-only current predicate accepts a genuine non-target global question loss and reduced physical population; live publication must wait for whole-population repair.')
