"""Retain the prior epoch reader's actual refusal and complete byte restoration."""
import json
import subprocess
from pathlib import Path

BASE = Path('docs/audits/record-value-parser-path-models-20261006')
target = BASE / 'prior-current-refusal.json'
assert not target.exists() and not (BASE / 'manifest.json').exists()
ns = {'__name__': 'prior_model_publication_probe'}
exec(compile((BASE / 'publication.py').read_bytes(), str(BASE / 'publication.py'), 'exec'), ns)
proposal = ns['transform'](); card = Path(ns['CARD']); before = card.read_bytes()
assert before.decode() == proposal['before_card']
command = ['python3', '-B', str(ns['ns']['PUBLICATION'] / 'verify.py'), '--current']
try:
    card.write_text(proposal['card'])
    result = subprocess.run(command, capture_output=True, text=True)
finally:
    card.write_bytes(before)
restored = card.read_bytes() == before
record = {'command': command, 'status': result.returncode, 'stdout': result.stdout, 'stderr': result.stderr,
          'before': before.decode(), 'candidate': proposal['card'], 'restored': restored,
          'programme_identity': ns['identity'](Path(command[2]).read_bytes()),
          'scope': 'Prior exact whole-card epoch refuses newly source-qualified bounded progress; its historical replay remains preserved. The new current semantic role is qualified separately.'}
target.write_text(json.dumps(record, sort_keys=True, indent=2)+'\n')
assert result.returncode == 1 and restored
assert 'ValueError: whole old/new source-context meaning/question/reader epoch' in result.stderr
print('PASS actual prior whole-card epoch refusal with full inputs and restoration')
