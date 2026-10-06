"""The prior current predicate must not lend success to superseding live facts."""
import json
import subprocess
from pathlib import Path

BASE = Path('docs/audits/record-value-parser-path-publication-20261006')
ns = {'__name__': 'probe_prior_source_current_role'}
exec(compile((BASE / 'verify.py').read_bytes(), str(BASE / 'verify.py'), 'exec'), ns)
target = BASE / 'prior-current-refusal.json'
assert not target.exists() and not (BASE / 'manifest.json').exists()
proposal = ns['transform']()
paths = (Path(ns['CARD']), Path(ns['CHAPTER']))
before = {str(p): p.read_bytes() for p in paths}
assert before[ns['CARD']].decode() == proposal['before_card']
assert before[ns['CHAPTER']].decode() == proposal['before_chapter']
programme = Path('docs/audits/record-value-parser-path-models-20261006/publication.py')
code = "from pathlib import Path; ns={'__name__':'actual_prior_current_predicate'}; p=Path('" + str(programme) + "'); exec(compile(p.read_bytes(),str(p),'exec'),ns); ns['check_current'](ns['current_input']())"
command = ['python3', '-B', '-c', code]
try:
    paths[0].write_text(proposal['card'])
    paths[1].write_text(proposal['chapter'])
    result = subprocess.run(command, capture_output=True, text=True)
finally:
    for path, raw in before.items():
        Path(path).write_bytes(raw)
restored = all(Path(path).read_bytes() == raw for path, raw in before.items())
record = dict(command=command, status=result.returncode, stdout=result.stdout, stderr=result.stderr,
    before={p: raw.decode() for p, raw in before.items()},
    candidate=dict(card=proposal['card'], chapter=proposal['chapter']), restored=restored,
    programme_identity=ns['identity'](programme.read_bytes()),
    role='Actual committed source-only current semantic predicate, not a new complete source/root replay. The new root separately authenticates/reexecutes the original sources and historical snapshot.')
target.write_text(json.dumps(record, sort_keys=True, indent=2)+'\n')
assert result.returncode == 1 and restored
assert 'ValueError: whole prior qualified source-context body' in result.stderr
print('PASS actual prior source-only current refusal; complete live bytes restored.')
