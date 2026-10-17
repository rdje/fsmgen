"""Accept committed-only audit source/evidence and documentation boundaries."""
from pathlib import Path
from datetime import datetime, timezone
import argparse
import base64
import gzip
import hashlib
import json
import os
import subprocess
import tempfile

BASE = Path('docs/audits/task-acceptance-audit-acceptance-20261017')
SCRATCH = Path('.artifacts/task-acceptance-audit-acceptance-20261017')
SELECTOR = SCRATCH / 'owner-watch-only.pl'
OWNER = 'TASK-ACCEPTANCE-AUDIT-SOURCE-COVERAGE.2'
ROOT = Path(__file__).resolve().parents[3]
COMMANDS = {
    'scope-committed': ['prove', '-v', '-Iperl', '-It/lib', 't/2071-audit-source-acceptance.t'],
    'owner': ['prove', '-v', '-Iperl', '-It/lib', str(SELECTOR)],
    'book': ['mdbook', 'build', 'docs/book', '-d', str(SCRATCH / 'book')],
    'inventory': ['scripts/check_claim_verification_inventory.pl', '--write'],
    'staged': ['scripts/check_doctrines.sh'],
}



def record(body):
    return dict(bytes=len(body), sha256=hashlib.sha256(body).hexdigest(),
                body_base64=base64.b64encode(body).decode())


def save(name, data):
    with (BASE / name).open('xb') as stream:
        stream.write(gzip.compress(json.dumps(data, sort_keys=True).encode(), mtime=0))


def sources():
    names = {path.as_posix() for pattern in ['t/*.t', 't/lib/FSM/Test/**/*.pm',
                                          'perl/FSM/Support/**/*.pm']
             for path in Path('.').glob(pattern) if path.is_file()}
    names.update(path.as_posix() for path in BASE.glob('*.py'))
    names.update([str(SELECTOR), '.proverc', 'perl/FSM/ProjectDataLocality.pm',
                  'scripts/run_with_ram_guard.sh', 'scripts/project_data_locality_env.sh',
                  'scripts/check_task_acceptance.sh',
                  'doctrine/task_acceptance/change_paths.tsv',
                  'doctrine/task_acceptance/evidence_signatures.tsv',
                  'docs/tasks/TASK-ACCEPTANCE-PORTABLE-DOCTRINE.md'])
    rows = {}
    for name in sorted(names):
        path = Path(name)
        assert not path.is_symlink() and path.resolve().is_relative_to(Path.cwd())
        rows[name] = dict(record(path.read_bytes()), mode=path.stat().st_mode & 0o777)
    body = gzip.compress(json.dumps(rows, sort_keys=True).encode(), mtime=0)
    name = 'sources-' + hashlib.sha256(body).hexdigest() + '.json.gz'
    path = BASE / name
    # Publish only a complete closed file. Competing actions may reuse the same
    # content identity; they must never observe a half-written archive.
    with tempfile.NamedTemporaryFile(dir=SCRATCH, prefix='source-', delete=False) as stream:
        temporary = Path(stream.name)
        stream.write(body)
    try:
        try:
            os.link(temporary, path)
        except FileExistsError:
            pass
        assert not path.is_symlink() and path.read_bytes() == body
    finally:
        temporary.unlink()
    return dict(path=path.as_posix(), sha256=hashlib.sha256(body).hexdigest(),
                files=len(rows), bytes=sum(row['bytes'] for row in rows.values()))


def git_state():
    rows = []
    for argv in [['git', 'rev-parse', 'HEAD'], ['git', 'ls-files', '--stage', '-z']]:
        result = subprocess.run(argv, capture_output=True, timeout=30)
        assert result.returncode == 0
        rows.append(dict(command=argv, status=result.returncode,
                         stdout=record(result.stdout), stderr=record(result.stderr)))
    return dict(observations=rows, main_index=record(Path('.git/index').read_bytes()))


def main():
    assert Path.cwd().resolve() == ROOT, 'run from the script-derived repository root'
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('action', choices=sorted(COMMANDS))
    args = parser.parse_args()
    expected = 0
    root = ROOT
    for destination in [SCRATCH, BASE]:
        assert destination.resolve().is_relative_to(root)
        for parent in [destination, *destination.parents]:
            if parent == Path('.'):
                break
            assert not parent.is_symlink()
            if parent.exists():
                assert parent.is_dir() and parent.stat().st_dev == root.stat().st_dev
            assert not (parent / '.git').exists() and not (parent / '.git').is_symlink()
            assert not ((parent / 'HEAD').exists() and any(
                (parent / name).exists() for name in ['objects', 'refs', 'packed-refs']))
    SCRATCH.mkdir(parents=True, exist_ok=True)
    if not SELECTOR.exists():
        SELECTOR.write_bytes(Path('.artifacts/ghdl-test-policy-20261012/owner-watch-only.pl').read_bytes())
    assert SELECTOR.read_bytes() == Path('.artifacts/ghdl-test-policy-20261012/owner-watch-only.pl').read_bytes()
    folder = SCRATCH / 'checks' / args.action
    folder.mkdir(parents=True, exist_ok=False)
    before, git_before = sources(), git_state()
    command = ['scripts/run_with_ram_guard.sh', '--', *COMMANDS[args.action]]
    start = dict(owner=OWNER, utc=datetime.now(timezone.utc).isoformat(), command=command,
                 expected_status=expected, sources_before=before, git_before=git_before,
                 boundary='Complete selected ownership-watcher project source domain, '
                          'index/helper/locality/checker/declaration inputs and own programme; '
                          'Git metadata binds committed fixture baselines. Canonical OS/toolchain '
                          'executables remain required read-only dependencies. No whole T1669, '
                          'HDL/HIAL/full-CI/push or historical-first-census claim. Only committed-only audit fixture coverage is under acceptance.')
    save(args.action + '-started.json.gz', start)
    with (folder / 'stdout').open('xb') as out, (folder / 'stderr').open('xb') as err:
        result = subprocess.run(command, stdout=out, stderr=err)
    after, git_after = sources(), git_state()
    raw_index_conserved = git_before['main_index'] == git_after['main_index']
    entries_conserved = git_before['observations'] == git_after['observations']
    strict_index = args.action.startswith(('policy', 'index', 'owner', 'scope'))
    git_conserved = entries_conserved and (raw_index_conserved if strict_index else True)
    actual = dict(**start, status=result.returncode, sources_after=after,
                  source_conserved=before == after, git_after=git_after,
                  git_conserved=git_conserved, raw_index_conserved=raw_index_conserved,
                  git_entries_and_revision_conserved=entries_conserved,
                  git_comparison_mode='raw_index_and_entries' if strict_index else 'entries_and_revision',
                  streams={name: record((folder / name).read_bytes()) for name in ['stdout', 'stderr']})
    save(args.action + '-actual.json.gz', actual)
    print(args.action, 'native', result.returncode, 'source conserved', before == after,
          'Git/index conserved', git_conserved, 'raw index conserved', raw_index_conserved, flush=True)
    assert result.returncode == expected and before == after and git_conserved


if __name__ == '__main__':
    main()
