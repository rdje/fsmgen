#!/usr/bin/env python3
"""Refresh baseline identities while retaining the qualified repair boundary."""
import argparse
import gzip
import json
import subprocess
from pathlib import Path

from build_normalized_baseline import build
from build_diagnostic_families import sha, snapshot

ROOT = Path(__file__).resolve().parents[3]
BASE = Path(__file__).resolve().parent
OWNER = 'PERL-POD-API-REFERENCE.6.1.2.3.2.1.2.3.2.2.2.3'
INPUTS = ('normalized-baseline-census-qualified.json.gz',
          'normalized-boolean-repair-before.json.gz',
          'normalized-boolean-repair-after.json.gz')
INSTRUMENTS = ('build_normalized_baseline_closure.py', 'verify_normalized_baseline_closure.py',
               'build_normalized_baseline.py', 'verify_normalized_baseline.py',
               'verify_normalized_booleans.py', 'build_diagnostic_families.py',
               'verify_normalized_envelope.py', 'verify_error_context.py',
               'verify_model_roots.py', 'verify_source_identity.py',
               'verify_diagnostic_limits.py', 'verify_inventory.py')


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('output', type=Path)
    args = parser.parse_args()
    target = args.output.resolve()
    if target.parent != BASE or target.exists():
        raise SystemExit('Output must be a new file in this audit directory')
    paths = [p.relative_to(ROOT).as_posix() for p in (BASE / n for n in INSTRUMENTS)]
    paths.append('scripts/generate_pod_reference.py')
    packet = {'schema': 'fsmgen.normalized_baseline_closure.v1', 'owner': OWNER,
        'head': subprocess.check_output(['git', 'rev-parse', 'HEAD'], cwd=ROOT, text=True).strip(),
        'inputs': {name: sha((BASE / name).read_bytes()) for name in INPUTS},
        'baseline': build(), 'instruments': {p: snapshot(p) for p in paths},
        'evidence_legs': {
            'rederive': 'Refresh existing baseline producer from retained native metadata and current source/document bytes; do not rerun native collection.',
            'falsify': 'Authenticate prior complete census and repair; require exact repair bridge, unchanged dedicated sources, field/delegation conservation and independent literal-family oracle.',
            'durability': 'Retain dated inputs, complete refreshed source/document/instrument bytes, independent reader and stale/unrelated-change controls.'},
        'limits': 'Baseline metadata/source closure and synthetic direct-helper Boolean repair only. Native DSL/CLI/MCP source reachability, nested models, full CI/publication and broader browser review remain owned.'}
    target.write_bytes(gzip.compress((json.dumps(packet, sort_keys=True, indent=2) + '\n').encode(), mtime=0))
    print('Wrote dated baseline closure; independent verification required.')


if __name__ == '__main__':
    main()
