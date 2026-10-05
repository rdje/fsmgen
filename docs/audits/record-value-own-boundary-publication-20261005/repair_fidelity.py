"""Repair the unsealed source publication, preserving every first accepted byte."""
import importlib.util
import json
from pathlib import Path

BASE = Path('docs/audits/record-value-own-boundary-publication-20261005')
spec = importlib.util.spec_from_file_location('atomic_source_publisher', BASE / 'publish.py')
publisher = importlib.util.module_from_spec(spec); spec.loader.exec_module(publisher)
initial = json.loads((BASE / 'initial-publication.json').read_text())
current = BASE / 'publication.json'
assert current.read_bytes() == (BASE / 'initial-publication.json').read_bytes()
assert not (BASE / 'manifest.json').exists()
after, own_block = publisher.transform(initial['before'])
assert after[publisher.HELPER] != initial['after'][publisher.HELPER]
for path, body in initial['after'].items():
    assert Path(path).read_text() == body, 'whole original accepted live input before repair'
    if path != publisher.HELPER:
        assert after[path] == body, 'only atomic helper prose changes'
assert './t/1986-isf-record-port-value-gates.t' in own_block
repaired = {**initial, 'after': after, 'own_block': own_block}
current.write_text(json.dumps(repaired, sort_keys=True, indent=2) + '\n')
Path(publisher.HELPER).write_bytes(after[publisher.HELPER].encode())
queries = BASE / 'current-queries.json'
assert queries.read_bytes() == (BASE / 'initial-current-queries.json').read_bytes(), 'whole first actual query product preserved'
queries.unlink()  # Exact byte-identical retained copy; recapture the corrected live inputs.
print('PASS first programme/products retained; repaired atomic source prose preserves exact file identifier and every other source word. Only helper body changes; current inputs require fresh capture.')
