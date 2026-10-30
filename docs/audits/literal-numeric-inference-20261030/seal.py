#!/usr/bin/env python3
"""Seal existing focused evidence; this starts no source or HDL workload."""
import gzip
import hashlib
import json
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
SCRATCH = ROOT / '.artifacts/literal-numeric-inference'
BASE = 'perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/'
PRODUCERS = [BASE + 'SourceLiteralWidthSupport.pm', BASE + 'IntermediateSignalWidthSupport.pm',
             'perl/FSM/SourceLiteralWidthAllocationSupport.pm', 'perl/FSM/CoreExpressionWidthSupport.pm',
             't/2262-target-source-literal-numeric-inference.t', 't/2261-target-source-literal-width.t',
             't/2192-parser-bitwise-intermediate-widths.t']


def digest(data):
    return hashlib.sha256(data).hexdigest()


def main():
    target = Path(__file__).with_name('receipt.json.gz')
    if target.exists():
        raise SystemExit('refusing to replace retained evidence')
    artifacts = {}
    for path in sorted(SCRATCH.rglob('*')):
        if path.is_file() and not path.is_symlink():
            raw = path.read_bytes()
            artifacts[path.relative_to(SCRATCH).as_posix()] = {'text': raw.decode(), 'sha256': digest(raw)}
    record = {
        'kind': 'literal_numeric_inference_20261030',
        'predecessor_revision': subprocess.check_output(['git', 'rev-parse', 'HEAD'], cwd=ROOT, text=True).strip(),
        'scope': 'Focused current source/generated-text and selected-module predecessor comparisons; no HDL execution, full historical dependency capsule, generic-floor or final declaration qualification. Separate comparison exit statuses were not captured; complete Test::More failure streams are retained.',
        'retained_first': {name: digest(target.with_name(name).read_bytes()) for name in ('first-receipt.json.gz', 'first-reader.py')},
        'artifacts': artifacts,
        'producers': {path: {'text': (ROOT / path).read_text(), 'sha256': digest((ROOT / path).read_bytes())} for path in PRODUCERS},
    }
    target.write_bytes(gzip.compress((json.dumps(record, sort_keys=True, indent=2) + '\n').encode(), mtime=0))
    print('retained focused products and explicit qualification limits')


if __name__ == '__main__':
    main()
