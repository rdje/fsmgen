"""Exercise actual current qualification with unrelated book/aggregate progress."""
import importlib.util
import json
import subprocess
from pathlib import Path

BASE = Path('docs/audits/record-value-own-boundary-publication-20261005')
target = BASE / 'unrelated-progress.json'
assert not target.exists()
other = Path('docs/book/src/00-introduction.md')
registry = Path('doctrine/live_document_size/surfaces.jsonl')
before = {str(path): path.read_bytes() for path in (other, registry)}
spec = importlib.util.spec_from_file_location('unrelated_publication_metrics', BASE / 'publish.py')
publisher = importlib.util.module_from_spec(spec); spec.loader.exec_module(publisher)
addition = '\nAn independent reader may qualify current reference meanings while unrelated\nchapter prose advances under its own measured book authority.\n'
candidate = before[str(other)] + addition.encode()
plane_spec = importlib.util.spec_from_file_location('unchanged_plane_selection', Path('scripts/book_source_references.py'))
plane = importlib.util.module_from_spec(plane_spec); plane_spec.loader.exec_module(plane)
assert str(other) not in {row['source'] for row in plane.expected_rows()}
old_book = {str(path): path.read_bytes() for path in Path('docs/book/src').glob('*.md')}
new_book = {**old_book, str(other): candidate}
lines = registry.read_text().splitlines()
for index, line in enumerate(lines):
    row = json.loads(line)
    if row.get('surface_id') == 'shipped_behavior':
        baseline, after = publisher.metrics(old_book), publisher.metrics(new_book)
        row['reference_contract']['aggregate_change'] = {
            'authority_id': 'OWN-BOUNDARY-UNRELATED-READER-CONTROL', 'owner': publisher.OWNER,
            'baseline': baseline, 'delta': {key: after[key]-baseline[key] for key in baseline},
            'rationale': 'Temporary actual unrelated book progress exercises the scoped current reader; original live bytes restore afterward.'}
        lines[index] = json.dumps(row, sort_keys=True)
registry_candidate = ('\n'.join(lines)+'\n').encode()
command = ['python3', '-B', str(BASE / 'verify.py'), '--current']
try:
    other.write_bytes(candidate); registry.write_bytes(registry_candidate)
    result = subprocess.run(command, capture_output=True, text=True)
finally:
    for path, body in before.items():
        Path(path).write_bytes(body)
restored = all(Path(path).read_bytes() == body for path, body in before.items())
record = {'before': {path: body.decode() for path, body in before.items()},
          'candidates': {str(other): candidate.decode(), str(registry): registry_candidate.decode()},
          'addition': addition, 'command': command, 'status': result.returncode,
          'stdout': result.stdout, 'stderr': result.stderr, 'restored': restored,
          'scope': 'Actual unrelated native chapter and measured authority progress passes current semantic/source qualification; historical and live relevant meanings stay exact.'}
target.write_text(json.dumps(record, sort_keys=True, indent=2)+'\n')
assert result.returncode == 0 and restored
print('PASS actual unrelated chapter/measured aggregate progress under current reader; complete live bytes restored.')
