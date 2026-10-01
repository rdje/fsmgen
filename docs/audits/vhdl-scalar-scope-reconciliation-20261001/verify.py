"""Authenticate the bounded VHDL scope repair and real translator controls."""
import hashlib
import json
import re
import subprocess
from pathlib import Path

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[2]
OLD = '- Signed scalar addition/subtraction/multiplication arithmetic is locked as an\n  explicit fail-closed direct VHDL boundary by focused pipeline and facade\n  coverage.\n'
NEW = '- Bounded signed scalar addition/subtraction/multiplication and their RHS chains\n  lower as one-bit `std_logic` bit-pattern logic: addition/subtraction use `xor`,\n  multiplication uses `and`. Signed scalar division/modulo and mixed\n  signed/unsigned scalar arithmetic remain fail-closed in pipeline and facade\n  coverage; this is not broad arithmetic or VHDL executable qualification.\n'
OLD_DEFERRED = '  signed arithmetic operators beyond the shipped same-width vector arithmetic\n  family, GHDL validation, packages, multi-clock domains, and full feature\n'
NEW_DEFERRED = '  signed arithmetic beyond the shipped scalar addition/subtraction/multiplication\n  and same-width vector families, GHDL validation, packages, multi-clock domains, and full feature\n'


def sha(raw):
    return hashlib.sha256(raw).hexdigest()


def scope(old, current):
    assert old.count(OLD) == 1
    assert old.count(OLD_DEFERRED) == 1
    assert current == old.replace(OLD, NEW, 1).replace(OLD_DEFERRED, NEW_DEFERRED, 1)
    assert 'Authored ISF packed record inputs remain unsupported.' in current


def main():
    m = json.loads((HERE / 'manifest.json').read_bytes())
    assert m['schema'] == 'fsmgen.vhdl_scalar_scope_reconciliation.v1'
    assert m['baseline_revision'] == 'b069b76e9072bbc3b9f83692e4092964404617cf'
    files = {p.name for p in HERE.iterdir() if p.is_file() and p.name != 'manifest.json'}
    assert files == set(m['sha256'])
    for name, digest in m['sha256'].items():
        assert sha((HERE / name).read_bytes()) == digest
    for path, identity in m['producers'].items():
        blob = subprocess.check_output(['git', 'rev-parse', m['baseline_revision'] + ':' + path], cwd=ROOT).decode().strip()
        assert blob == identity['git_blob']
        assert sha(subprocess.check_output(['git', 'cat-file', 'blob', blob], cwd=ROOT)) == identity['sha256']
    old = subprocess.check_output(['git', 'cat-file', 'blob', m['producers']['docs/VHDL_SCOPE.md']['git_blob']], cwd=ROOT).decode()
    current = (HERE / 'scope.md.source').read_text()
    scope(old, current)
    for bad in (old, current.replace('division/modulo', 'addition/subtraction', 1),
                current.replace('Authored ISF packed record inputs remain unsupported.', 'Authored ISF packed record inputs are supported.')):
        try:
            scope(old, bad)
        except AssertionError:
            continue
        raise AssertionError('stale or unrelated scope change accepted')
    history = (HERE / 'history.txt').read_text()
    assert '0f31a983ffaafb606b41e1e42c965523279f37db' in history
    assert 'b4033eb3f62856b8d60d3554475883e13490dfcd' in history
    shipped = subprocess.check_output(['git', 'show', 'b4033eb3f62856b8d60d3554475883e13490dfcd:docs/VHDL_SCOPE.md'], cwd=ROOT).decode()
    assert OLD in shipped and 'RHS/chain lowering for one-bit signed scalar target/operand shapes' in shipped
    receipt = (HERE / 'backend.txt').read_text()
    assert 'All tests successful.' in receipt and 'Files=2, Tests=160,' in receipt
    assert 'Result: PASS' in receipt and 'Result: FAIL' not in receipt
    for test in ('1420-vhdl-direct-backend-scaffold', '386-hdl-generator-facade-target-language-boundary-audit'):
        assert re.search(r't/' + re.escape(test) + r'\.t\s+\.+ ok', receipt)
    availability = 'ghdl unavailable on PATH\nnvc unavailable on PATH\nvcom unavailable on PATH\n'
    assert (HERE / 'tools-path.txt').read_text() == availability
    assert (HERE / 'tools-discovery.txt').read_text() == availability
    print('Exact old/refined signed-scalar VHDL scope and historical omission authenticated; current pipeline/facade positive and precise-refusal controls pass. Stale arithmetic and unrelated record-profile mutations reject. No production, wider-backend or executable VHDL change.')


if __name__ == '__main__':
    main()
