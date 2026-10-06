"""Exercise actual current qualification with unrelated book/aggregate progress."""
import importlib.util
import json
import subprocess
from pathlib import Path

BASE = Path('docs/audits/record-value-parser-path-models-20261006')
target = BASE / 'unrelated-progress.json'
assert not target.exists() and not (BASE / 'manifest.json').exists()
other = Path('docs/book/src/00-introduction.md')
registry = Path('doctrine/live_document_size/surfaces.jsonl')
card = Path('docs/knowledge/isf-record-output-source-contexts.md')
before = {str(path): path.read_bytes() for path in (other, registry, card)}
spec = importlib.util.spec_from_file_location('unrelated_publication_metrics', BASE / 'publication.py')
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
        baseline = {k: publisher.previous['metrics'](old_book)[k] for k in ('files', 'lines_total', 'bytes_total')}
        after = {k: publisher.previous['metrics'](new_book)[k] for k in baseline}
        row['reference_contract']['aggregate_change'] = {
            'authority_id': 'PARSER-MODEL-SCOPED-PROGRESS-CONTROL', 'owner': publisher.OWNER,
            'baseline': baseline, 'delta': {key: after[key]-baseline[key] for key in baseline},
            'rationale': 'Temporary actual unrelated book progress exercises the scoped current reader; original live bytes restore afterward.'}
        lines[index] = json.dumps(row, sort_keys=True)
registry_candidate = ('\n'.join(lines)+'\n').encode()
command = ['python3', '-B', str(BASE / 'publication.py'), '--current']
try:
    other.write_bytes(candidate); registry.write_bytes(registry_candidate)
    card.write_bytes(before[str(card)] + b'Whole original source declarations remain available in the retained inventory.\n')
    result = subprocess.run(command, capture_output=True, text=True)
finally:
    for path, body in before.items():
        Path(path).write_bytes(body)
restored = all(Path(path).read_bytes() == body for path, body in before.items())
record = {'before': {path: body.decode() for path, body in before.items()},
          'candidates': {str(other): candidate.decode(), str(registry): registry_candidate.decode(),
                         str(card): (before[str(card)] + b'Whole original source declarations remain available in the retained inventory.\n').decode()},
          'addition': addition, 'command': command, 'status': result.returncode,
          'stdout': result.stdout, 'stderr': result.stderr, 'restored': restored,
          'scope': 'Actual valid inventory sentence outside protected fact blocks plus unrelated chapter/measured-authority progress passes scoped current source qualification; all prior/new facts, questions and bytes restore.'}
target.write_text(json.dumps(record, sort_keys=True, indent=2)+'\n')
assert result.returncode == 0 and restored
print('PASS actual unrelated chapter/measured aggregate progress under current reader; complete live bytes restored.')
