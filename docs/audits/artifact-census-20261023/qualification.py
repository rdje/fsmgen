"""Retain final document and saved-census checks; never repeat collection."""
import gzip
import json
import os
from pathlib import Path
import runpy

ROOT = Path(__file__).resolve().parents[3]
os.chdir(ROOT)
BASE = 'docs/audits/width-ir-qualification-20261023.py'
base = runpy.run_path(BASE)
capture, sha, require = [base[k] for k in ('capture', 'sha', 'require')]
SELF = Path(__file__).resolve().relative_to(ROOT).as_posix()
PATHS = [SELF, BASE, 'docs/audits/artifact-census-20261023/census.py',
    'docs/audits/artifact-census-20261023/census.json.gz',
    'docs/audits/artifact-census-20261020/census.py', 'docs/ARTIFACT_CLEANUP.md',
    'docs/book/src/10-errors-strict-mode-and-troubleshooting.md',
    'docs/tasks/ISF-REDUCTION-DELIVERY.md', 'MEMORY.md', 'docs/TASK_TREE.md',
    'doctrine/live_document_size/surfaces.jsonl']
commands = {
    'saved_census': ['python3', '-B', 'docs/audits/artifact-census-20261023/census.py'],
    'book_build': ['mdbook', 'build', 'docs/book'],
    'book_sources': ['python3', '-B', 'scripts/book_source_references.py', '--check', '--verify-build', 'docs/book/book'],
    'book_index': ['python3', '-B', 'scripts/check_book_source_index.py'],
    'tasks': ['scripts/check_task_tree_integrity.pl'],
    'decisions': ['python3', '-B', 'scripts/decision_records.py', 'check'],
}
packet = {'owner': 'ISF-REDUCTION-DELIVERY.18', 'qualified': False, 'results': {},
    'inputs': {p: sha(Path(p).read_bytes()) for p in PATHS},
    'scope': 'Saved dated census and final native document checks only. No collection, disposal, source query or compiler epoch repeats.'}
target = Path(__file__).with_name('qualification.json.gz')
require(not target.exists(), 'refusing to overwrite qualification')
try:
    for label, argv in commands.items():
        packet['results'][label] = capture(argv, timeout=600)
        require(type(packet['results'][label]['exit']) is int and packet['results'][label]['exit'] == 0,
                'failed check: ' + label)
    require(all(sha(Path(p).read_bytes()) == value for p, value in packet['inputs'].items()), 'inputs changed during checks')
    packet['qualified'] = True
finally:
    with target.open('xb') as stream:
        stream.write(gzip.compress((json.dumps(packet, sort_keys=True, indent=2) + '\n').encode(), mtime=0))
print('Saved census, book/source/index/task/decision checks pass; no collection or deletion repeated.')
