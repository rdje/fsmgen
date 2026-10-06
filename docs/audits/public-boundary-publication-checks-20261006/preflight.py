"""Exercise source/current/native predicates before the complete guarded seal."""
from pathlib import Path

base=Path('docs/audits/record-value-public-boundary-publication-20261006')
ns={'__name__':'publication_preflight'}
exec(compile((base/'verify.py').read_bytes(),str(base/'verify.py'),'exec'),ns)
ns['source_proof']()
ns['controls'](ns['load'](base/'publication.json')['snapshot'])
ns['native_proof']((base/'native-input.html').read_text())
print('PASS source/current/native publication predicates and genuine controls; complete prerequisite replay remains separate.')
