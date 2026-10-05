"""Separate frozen publication qualification from current helper semantics."""
import json
import runpy
import subprocess
import sys
import traceback
from pathlib import Path

BASE = Path('docs/audits/book-reference-selection-20261005')
PUBLICATION = Path('docs/audits/record-value-helper-topic-publication-20261005')
registry_path = 'doctrine/live_document_size/surfaces.jsonl'
original = Path(registry_path).read_text()
rows = list(map(json.loads, original.splitlines()))
paths = sorted(str(p) for p in Path('docs/book/src').glob('*.md'))
before = {'files': len(paths), 'lines_total': sum(Path(p).read_bytes().count(b'\n') for p in paths), 'bytes_total': sum(Path(p).stat().st_size for p in paths)}
chapter = Path('docs/book/src/90-reference-map.md').read_text()
addition = '\nCanonical source references remain distinct from normative book chapters.\n'
change = next(r for r in rows if r.get('surface_id') == 'shipped_behavior')['reference_contract']['aggregate_change']
change.update({'authority_id': 'REFERENCE-SELECTION-CONTROL-SHIPPED-BEHAVIOR', 'baseline': before,
               'delta': {'files': 0, 'lines_total': addition.count('\n'), 'bytes_total': len(addition.encode())},
               'owner': 'SEMANTIC-INTROSPECTION-MCP-FRONTIER.73.2.2', 'rationale': 'Concrete isolated source-reference reader guidance control; no real source/config publication.'})
candidate = ''.join(json.dumps(row, sort_keys=True, separators=(',', ':')) + '\n' for row in rows)
command = [sys.executable, '-B', str(PUBLICATION / 'verify.py')]
snapshot = subprocess.run(command, capture_output=True, text=True)
record = {'snapshot': {'command': command, 'status': snapshot.returncode, 'stdout': snapshot.stdout, 'stderr': snapshot.stderr},
          'registry_before': original, 'registry_candidate': candidate,
          'chapter_before': chapter, 'chapter_candidate': chapter + addition,
          'scope': 'Virtual whole-registry publication with independently measured concrete book delta; live helper/core/source/query inputs are untouched. No production source, registry, proof or archive file is changed.'}
old_read = Path.read_text; old_argv = sys.argv
def controlled_read(path, *args, **kwargs):
    return candidate if str(path) == registry_path else old_read(path, *args, **kwargs)
try:
    Path.read_text = controlled_read
    sys.argv = [str(PUBLICATION / 'verify.py'), '--current']
    try:
        runpy.run_path(str(PUBLICATION / 'verify.py'), run_name='__main__')
    except AssertionError:
        record['current_outcome'] = {'status': 1, 'traceback': traceback.format_exc()}
    else:
        record['current_outcome'] = {'status': 0}
finally:
    Path.read_text = old_read; sys.argv = old_argv
assert Path(registry_path).read_text() == original
assert Path('docs/book/src/90-reference-map.md').read_text() == chapter
assert snapshot.returncode == 0 and record['current_outcome']['status'] == 1
target = BASE / 'reader-scope-probe.json'; assert not target.exists()
target.write_text(json.dumps(record, sort_keys=True, indent=2) + '\n')
print('PASS frozen publication remains qualified; unrelated whole-book authority control trips the current whole-registry identity. Separate live semantic watcher scope before publication.')
