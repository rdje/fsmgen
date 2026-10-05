"""Replay the retained first source predicate against its full bad candidate."""
import importlib.machinery
import importlib.util
import json
from pathlib import Path

BASE = Path('docs/audits/book-reference-publication-20261005')
loader = importlib.machinery.SourceFileLoader('retained_first_qualifier', str(BASE / 'initial-verifier.txt'))
spec = importlib.util.spec_from_loader(loader.name, loader)
reader = importlib.util.module_from_spec(spec)
loader.exec_module(reader)
rows = json.loads(reader.SELECTION.read_text())['routes']
old = json.loads(reader.CLASSIFICATION.read_text())
reader.qualify(json.loads((BASE / 'native.json').read_text()), rows, old)
reader.qualify(json.loads((BASE / 'initial-shared-source-candidate.json').read_text()), rows, old)
print('REPRODUCED immutable first predicate accepts baseline and the original whole coordinated corruption.')
