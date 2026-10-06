"""Bind the untouched actual current result to every sealed publication byte."""
import json
from pathlib import Path

BASE=Path('docs/audits/record-value-public-boundary-publication-20261006')
CHECKS=Path('docs/audits/public-boundary-publication-checks-20261006')
ns={'__name__':'capture_publication_result'}
exec(compile((CHECKS/'verify_seal.py').read_bytes(),str(CHECKS/'verify_seal.py'),'exec'),ns)
result=ns['load'](CHECKS/'seal-command-final.json')
result['whole_members']=ns['members']()
result['actual_result_identity']=ns['identity']((CHECKS/'seal-command-final.json').read_bytes())
ns['header'](result)
output=CHECKS/'sealed-replay.json';assert not output.exists()
output.write_text(json.dumps(result,sort_keys=True,indent=2)+'\n')
print('PASS untouched actual current result and complete publication member binding.')
