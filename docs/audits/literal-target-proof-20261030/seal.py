#!/usr/bin/env python3
"""Seal the already settled target-proof observations without replaying them."""
import base64
import gzip
import hashlib
import json
from pathlib import Path
import subprocess

ROOT = Path(__file__).resolve().parents[3]
SLOT = ROOT / '.artifacts/literal-target-proof-20261030'
SOURCE = 'perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/SourceLiteralWidthSupport.pm'
TEST = 't/2267-target-source-literal-declarations.t'


def packed(raw):
    return {'data_base64': base64.b64encode(raw).decode(), 'bytes': len(raw),
            'sha256': hashlib.sha256(raw).hexdigest()}


def main():
    output = Path(__file__).with_name('receipt.json.gz')
    assert not output.exists(), 'Keep prior receipts immutable.'
    artifacts = {}
    for path in sorted(SLOT.rglob('*')):
        if not path.is_file():
            continue
        assert not path.is_symlink() and path.stat().st_dev == ROOT.stat().st_dev
        raw = path.read_bytes()
        # Keep raw identity, but do not persist the machine-local checkout path.
        normalized = raw.replace(str(ROOT).encode(), b'<repository-root>')
        artifacts[path.relative_to(SLOT).as_posix()] = {
            **packed(normalized), 'raw_bytes': len(raw), 'raw_sha256': hashlib.sha256(raw).hexdigest()}
    producers = {path: packed((ROOT / path).read_bytes()) for path in (
        SOURCE, TEST, 'perl/FSM/DirectDeclaredWidthSupport.pm',
        'perl/FSM/SourceLiteralWidthAllocationSupport.pm',
        'perl/FSM/IntermediateWidthAllocationSupport.pm',
        'perl/FSM/Backend/VerilogFamily/DeclarationCapture.pm',
        't/2265-target-source-literal-selection.t')}
    revision = subprocess.check_output(['git', 'rev-parse', 'HEAD'], cwd=ROOT, text=True).strip()
    record = {
        'kind': 'literal_target_proof_20261030', 'before_revision': revision,
        'original_source': packed(subprocess.check_output(['git', 'show', revision + ':' + SOURCE], cwd=ROOT)),
        'runs': {'red': 1, 'first-implementation': 1, 'second-implementation': 1,
                 'focused': 0, 'no-target-fence': 1, 'book': 0, 'final-focused': 0},
        'artifacts': artifacts, 'producers': producers,
        'scope': 'Private complete literal target-record proof; ordinary fixed emission and explicit mutable source/binary selector seams. No live ledger or final Core-width exception.',
        'gaps': ['No whole historical dependency/environment reconstruction.',
                 'Initial sandbox guard refusal has no separately retained native status.',
                 'Raw-root stream reconstruction is not retained; normalized complete bytes and raw identities are separate.',
                 'Saved current identity checks cover named producers only; no unconditional future behavior watcher.',
                 'No external HDL execution, normal generic generation, full feature or publication qualification.'],
    }
    output.write_bytes(gzip.compress((json.dumps(record, sort_keys=True, indent=2) + '\n').encode(), mtime=0))


if __name__ == '__main__':
    main()
