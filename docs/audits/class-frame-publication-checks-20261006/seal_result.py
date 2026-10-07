"""Bind an actual completed seal command to every complete publication member."""
import json
from pathlib import Path

BASE = Path('docs/audits/record-value-class-frame-publication-20261006')
CHECKS = Path('docs/audits/class-frame-publication-checks-20261006')
ns = {'__name__':'whole_actual_publication_seal','__file__':str(BASE / 'verify.py')}
exec(compile((BASE / 'verify.py').read_bytes(),str(BASE / 'verify.py'),'exec'),ns)
actual = ns['load'](CHECKS / 'seal-command.json')
ns['require'](type(actual['status']) is int and actual['status'] == 0
    and actual['command'] == ['scripts/run_with_ram_guard.sh','--','python3','-B',str(BASE / 'verify.py'),'--seal']
    and actual['stdout'] == ns['SUCCESS'],'actual full publication seal success before receipt binding')
ns['require'](ns['same'](ns['load'](BASE / 'manifest.json'),ns['members']()),'whole complete immutable publication seal before actual-result binding')
record = dict(actual,whole_members={str(Path(p).relative_to(BASE)):pin for p,pin in ns['whole'](BASE).items()},
    actual_result_identity=ns['identity']((CHECKS / 'seal-command.json').read_bytes()))
out = CHECKS / 'sealed-replay.json'; ns['require'](not out.exists(),'actual whole sealed receipt cannot overwrite')
out.write_text(json.dumps(record,sort_keys=True,indent=2)+'\n')
print('PASS actual full publication seal command and complete member receipt bound without rewriting any sealed source/product.')
