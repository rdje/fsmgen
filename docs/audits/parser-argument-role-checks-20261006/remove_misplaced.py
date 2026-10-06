"""One owned path-recovery removal after complete generated-output comparison."""
import hashlib
import json
import stat
from pathlib import Path

BASE = Path('docs/audits/parser-argument-role-checks-20261006')


def pin(raw):
    return {'bytes': len(raw), 'sha256': hashlib.sha256(raw).hexdigest()}


def main():
    receipt = json.loads((BASE / 'misplaced-output-comparison.json').read_bytes())
    assert receipt['exact_population_and_bytes_equal'] is True
    assert receipt['misplaced'] == receipt['corrected']
    assert receipt['misplaced_from_root'] == '../../.artifacts/parser-argument-roles-book'
    assert receipt['corrected_from_root'] == '.artifacts/parser-argument-roles-book'
    root = Path.cwd().resolve()
    target = (root / receipt['misplaced_from_root']).resolve()
    good = root / receipt['corrected_from_root']
    assert target.name == good.name and target.is_dir() and not target.is_symlink()
    assert all(not p.is_symlink() and not (p / '.git').exists() for p in [target, *target.parents])
    device = root.stat().st_dev
    assert target.stat().st_dev == device
    actual = {str(p.relative_to(target)) for p in target.rglob('*')}
    expected = set(receipt['misplaced']['files']) | set(receipt['misplaced']['directories'])
    assert actual == expected
    for name, expected_pin in receipt['misplaced']['files'].items():
        old, current = target / name, good / name
        info = old.lstat()
        assert stat.S_ISREG(info.st_mode) and info.st_dev == device
        assert pin(old.read_bytes()) == pin(current.read_bytes()) == expected_pin
    # Every byte is compared before removal; each node is checked again at its
    # unlink boundary. Directory removal cannot recurse into unlisted data.
    removed = []
    for name, expected_pin in receipt['misplaced']['files'].items():
        old = target / name
        assert stat.S_ISREG(old.lstat().st_mode) and pin(old.read_bytes()) == expected_pin
        old.unlink()
        removed.append(name)
    for name in sorted(receipt['misplaced']['directories'], key=lambda s: len(Path(s).parts), reverse=True):
        node = target / name
        assert node.is_dir() and not node.is_symlink() and not (node / '.git').exists()
        node.rmdir()
    target.rmdir()
    assert not target.exists()
    assert all(pin((good / name).read_bytes()) == value for name, value in receipt['corrected']['files'].items())
    result = {'status': 0, 'misplaced_from_root': receipt['misplaced_from_root'], 'removed_exact_files': removed,
              'misplaced_residue': 'absent', 'corrected_population_bytes': 'unchanged',
              'scope': 'Only the complete byte-identical owned misplaced generated output; no other outside-repository data changed.'}
    (BASE / 'misplaced-removal.json').write_text(json.dumps(result, sort_keys=True, indent=2) + '\n')
    print('PASS exact owned misplaced output removed; residue absent; repository-local product conserved.')


if __name__ == '__main__':
    main()
