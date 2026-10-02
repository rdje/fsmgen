"""Declared source-origin family: complete lexical like/unlike sites, not an AST."""
import hashlib
import json
import re
import subprocess
from pathlib import Path

BASE = Path(__file__).parent
names = [
    't/2043-isf-conditional-origin-parser.t',
    't/2044-isf-conditional-origin-source-authority.t',
    't/2045-isf-same-source-library-origins.t',
    't/2046-isf-library-document-origin-authority.t',
    't/2047-isf-atl-document-origin-authority.t',
    't/2048-isf-file-document-origin-authority.t',
    't/2052-isf-local-formal-origin-authority.t']
sources, sites = {}, []
for name in names:
    raw = Path(name).read_bytes()
    sources[name] = {'bytes': len(raw), 'sha256': hashlib.sha256(raw).hexdigest(),
                     'source': raw.decode()}
    for match in re.finditer(rb'\b(?:like|unlike|diagnostic_matches)\s*\('
                            rb'|\bis\s*\(\s*(?:first_line|diagnostic_line)\s*\(', raw):
        line = raw[:match.start()].count(b'\n') + 1
        lines = raw.decode().splitlines()
        sites.append({'path': name, 'line': line, 'offset': match.start(),
                      'context': '\n'.join(lines[max(0, line - 3):line + 2]),
                      'review': 'unclassified lexical site'})
data = {'baseline': subprocess.check_output(['git', 'rev-parse', 'HEAD']).decode().strip(),
        'sources': sources, 'sites': sites,
        'scope': 'Exact declared seven-test family like/unlike, diagnostic_matches and '
                 'is(first_line/diagnostic_line) lexical sites and complete source bytes; '
                 'no parsed-function or all-repository semantic coverage.'}
(BASE / 'inventory.json').write_text(json.dumps(data, sort_keys=True, indent=2) + '\n')
print(json.dumps({'files': len(sources), 'lexical_sites': len(sites)}, sort_keys=True))
