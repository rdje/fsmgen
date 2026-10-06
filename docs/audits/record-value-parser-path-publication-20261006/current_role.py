"""Exercise only live semantic currency; full source replay is a separate leg."""
from pathlib import Path

BASE = Path('docs/audits/record-value-parser-path-publication-20261006')
ns = {'__name__': 'actual_current_publication_role'}
exec(compile((BASE / 'verify.py').read_bytes(), str(BASE / 'verify.py'), 'exec'), ns)
ns['authenticate'](replay=False)
ns['check_current'](ns['current_input']())
print('PASS actual scoped current fact/query/guide/physical authority; source replay remains separately authenticated.')
