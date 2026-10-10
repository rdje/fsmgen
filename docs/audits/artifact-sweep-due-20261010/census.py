"""Fixed read-only artifact census; no deletion function or caller path."""
import hashlib
import json
import os
import stat
import subprocess
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
BASE = Path(__file__).parent
SUFFIXES = ('.bin', '.log', '.pyc', '.stdout', '.stderr')
RUST = tuple(base + '/' + tail for base in ('target', 'rust/target')
             for tail in ('release', 'debug/incremental', 'debug/deps'))


def census():
    artifacts, boundaries = [], []
    device = ROOT.stat().st_dev
    for directory, children, names in os.walk(ROOT, followlinks=False):
        path = Path(directory)
        relative = path.relative_to(ROOT)
        if path != ROOT and ('.git' in children or '.git' in names):
            boundaries.append({'path': str(relative), 'reason': 'nested Git repository'})
            children[:] = []
            continue
        kept = []
        for name in children:
            item = path / name
            if item == ROOT / '.git':
                boundaries.append({'path': '.git', 'reason': 'primary Git metadata'})
            elif item.is_symlink() or item.lstat().st_dev != device:
                boundaries.append({'path': str(item.relative_to(ROOT)), 'reason': 'symlink or foreign-volume directory'})
            else:
                kept.append(name)
        children[:] = kept
        for name in names:
            if not name.endswith(SUFFIXES):
                continue
            item = path / name
            info = item.lstat()
            if not stat.S_ISREG(info.st_mode) or info.st_dev != device:
                boundaries.append({'path': str(item.relative_to(ROOT)), 'reason': 'nonregular or foreign-volume artifact'})
                continue
            artifacts.append({'path': str(item.relative_to(ROOT)), 'bytes': info.st_size,
                              'device': info.st_dev, 'inode': info.st_ino, 'mode': info.st_mode,
                              'nlink': info.st_nlink, 'mtime_ns': info.st_mtime_ns})
    artifacts.sort(key=lambda r: r['path'])
    boundaries.sort(key=lambda r: r['path'])
    cmd = ['rg', '--files', '--hidden', '--no-ignore']
    for suffix in SUFFIXES:
        cmd += ['-g', '*' + suffix]
    for row in boundaries:
        cmd += ['-g', '!' + row['path'], '-g', '!' + row['path'] + '/**']
    run = subprocess.run(cmd, cwd=ROOT, text=True, capture_output=True)
    assert run.returncode in (0, 1), run.stderr
    members = sorted(run.stdout.splitlines())
    assert members == [row['path'] for row in artifacts], 'independent complete rg/os.walk membership'
    rust = [{'path': relative, 'status': 'censused' if (ROOT / relative).is_dir() else 'absent',
             'retained': [row['path'] for row in artifacts if row['path'].startswith(relative + '/')
                          and row['path'].endswith(('.bin', '.log'))]} for relative in RUST]
    return {'artifacts': artifacts, 'boundaries': boundaries, 'rust': rust,
            'independent_rg': {'command': cmd, 'status': run.returncode, 'stdout': run.stdout, 'stderr': run.stderr}}


def main():
    assert not (BASE / 'manifest.json').exists(), 'sealed census producer must never run in its archive'
    prior = (ROOT / 'docs/ARTIFACT_CLEANUP.md').read_text()
    old_time = datetime.fromisoformat(prior.splitlines()[2].split(' — ', 1)[0])
    now = datetime.now(timezone.utc)
    assert (now - old_time).total_seconds() > 86400, 'daily sweep is not due'
    report = census()
    report.update(owner='SEMANTIC-INTROSPECTION-MCP-FRONTIER.82', utc=now.isoformat(),
                  prior_record=prior, revision=subprocess.check_output(['git', 'rev-parse', 'HEAD'], cwd=ROOT, text=True).strip(),
                  removed=[], decision='Retain all censused artifacts: exact safe-disposal authority has not been established for any candidate. No deletion is attempted.',
                  scope='Repository-owned regular same-volume log/bin/bytecode/stdout/stderr artifacts only; boundaries excluded. Node sizes/identities are dated metadata, not hashes or future absence promises.')
    (BASE / 'census.json').write_text(json.dumps(report, sort_keys=True, indent=2) + '\n')
    (ROOT / 'docs/ARTIFACT_CLEANUP.md').write_text('# Latest artifact cleanup\n\n' + now.isoformat()
        + ' — Removed nothing: own log/bin/bytecode/stdout/stderr and Rust locations censused; all artifacts retained because exact safe-disposal authority is unproved. Native/compiler/audit evidence and current book preserved.\n')
    print(json.dumps({'status': 0, 'artifact_members': len(report['artifacts']), 'removed': [], 'utc': report['utc']}, sort_keys=True))


if __name__ == '__main__':
    main()
