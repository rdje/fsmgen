#!/usr/bin/env python3
"""Seal a completed diagnosis checkpoint; never execute source or HDL workloads."""
import gzip
import hashlib
import json
from pathlib import Path
import subprocess


def sha(data):
    return hashlib.sha256(data).hexdigest()


def require(ok, message):
    if not ok:
        raise ValueError(message)


root = Path.cwd()
parser = 'perl/FSM/Adapter/ISF/Parser.pm'
baseline = 'b84eb7d9246bb300dcbe925c0463b074df0d2434'
require(Path(parser).read_bytes() == subprocess.check_output(['git', 'show', baseline + ':' + parser]),
        'production parser differs from committed baseline')
require(not Path('t/2097-isf-authored-library-overrides.t').exists(), 'unqualified draft still runnable')
require(not subprocess.check_output(['git', 'diff', 'HEAD', '--name-only', '--', 'bin', 'perl', 't']),
        'production or runnable regression changed')
streams = {}
for name in ('focused', 'mdbook', 'doctrines'):
    path = '.artifacts/library-override-diagnosis-' + name + '-20261022.log'
    raw = Path(path).read_bytes()
    streams[path] = {'raw_sha256': sha(raw), 'text': raw.decode().replace(str(root), '<repo>')}
require('All tests successful.' in next(v['text'] for k, v in streams.items() if '-focused-' in k), 'focused checks incomplete')
require('HTML book written' in next(v['text'] for k, v in streams.items() if '-mdbook-' in k), 'book incomplete')
require('all doctrine checks passed' in next(v['text'] for k, v in streams.items() if '-doctrines-' in k), 'doctrines incomplete')
record = {'owner': 'ISF-REDUCTION-DELIVERY.2.3.2.1.2.1', 'schema_version': 1,
          'scope': 'Completed diagnosis and decomposition only. Normalizer repair and qualified private override preservation remain pending.',
          'restored_parser': {'path': parser, 'revision': baseline, 'sha256': sha(Path(parser).read_bytes())},
          'streams': streams,
          'producer': {'path': __file__, 'text': Path(__file__).read_text()},
          'legs': {'rederive': 'Actual first-touch public raw/normalized/facade products and parser restoration identity.',
                   'falsify': 'Independent literal shapes, scoped head-recursion counterfactual and hostile saved shape/kind/caller/membership controls.',
                   'durability': 'Tracked initial draft, original peers, diagnosis, producers/verifier, task/book/decision and Git.'},
          'limits': 'No production fix, broad normalizer safety, qualified source-retention RED/GREEN, full dependency/process footprint, raw-root reconstruction, generic HDL or publication claim.'}
output = Path('docs/audits/library-override-diagnosis-qualification-20261022.json.gz')
with output.open('xb') as stream:
    with gzip.GzipFile(fileobj=stream, mode='wb', mtime=0) as packed:
        packed.write((json.dumps(record, sort_keys=True, indent=2) + '\n').encode())
print(output)
