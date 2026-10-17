"""Capture fixed original-join publication verification with complete current source epochs."""
from pathlib import Path
from datetime import datetime, timezone
import argparse
import ast
import base64
import gzip
import hashlib
import json
import os
import subprocess
import sys
import tempfile

BASE = Path('docs/audits/original-join-publication-closeout-20261017')
SCRATCH = Path('.artifacts/original-join-publication-closeout-20261017')
SELECTOR = SCRATCH / 'owner-watch-only.pl'
OWNER = 'SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.4.3.3.5.2.1.5.2.2.3.1.2.1.3.1.2.3.2.3.3.3.3.2.3.2.3.3.2.3.4.3.2'
ROOT = Path(__file__).resolve().parents[3]
COMMANDS = {
    'focused': ['python3','-B','-m','unittest','discover','-s','t/python','-p','test_record_value*publication.py','-v'],
    'frozen': ['python3','-B','docs/audits/original-join-canonical-publication-20261017/verify.py'],
    'inventory': ['scripts/check_claim_verification_inventory.pl','--write'],
    'staged': ['scripts/check_doctrines.sh'],
}



def record(body):
    return dict(bytes=len(body), sha256=hashlib.sha256(body).hexdigest(),
                body_base64=base64.b64encode(body).decode())


def save(name, data):
    with (BASE / name).open('xb') as stream:
        stream.write(gzip.compress(json.dumps(data, sort_keys=True).encode(), mtime=0))


def project_modules(bodies=None,declaration=None):
    available=sorted(str(path) for path in Path('scripts').glob('*.py') if path.stem.isidentifier()) if bodies is None else declaration['available_modules']
    assert len(available)==len(set(available))
    assert all(Path(name).parent==Path('scripts') and Path(name).stem.isidentifier() for name in available)
    seeds=sorted({'scripts/check_record_value_publication.py','scripts/book_source_references.py',
                  'scripts/decision_store_git.py'}|{name for name in available
                  if Path(name).name.startswith('record_value') and name.endswith('_fact.py')})
    pending=list(seeds);modules={};edges={}
    while pending:
        name=pending.pop()
        if name in modules:
            continue
        path=Path(name)
        if bodies is None:
            assert not path.is_symlink() and path.resolve().is_relative_to(ROOT)
            body=path.read_bytes()
        else:
            body=bodies[name]
        dependencies=set()
        for node in ast.walk(ast.parse(body,filename=name)):
            imports=[item.name for item in node.names] if isinstance(node,ast.Import) else (
                [node.module] if isinstance(node,ast.ImportFrom) and node.level==0 and node.module else [])
            for imported in imports:
                target='scripts/'+imported.split('.',1)[0]+'.py'
                if target in available:
                    dependencies.add(target)
        modules[name]={key:value for key,value in record(body).items() if key!='body_base64'}
        edges[name]=sorted(dependencies);pending.extend(dependencies)
    return dict(available_modules=available,seeds=seeds,modules=dict(sorted(modules.items())),edges=dict(sorted(edges.items())))


def sources(action):
    names = {path.as_posix() for pattern in [
        'scripts/record_value*_fact.py', 't/python/test_record_value*.py',
        'docs/knowledge/*.md', 'docs/decisions/**/*.md',
        'docs/audits/original-join-canonical-preparation-20261012/*.py']
        for path in Path('.').glob(pattern) if path.is_file()}
    names.update(path.as_posix() for path in BASE.glob('*.py'))
    names.update(path.as_posix() for path in Path('docs/audits/original-join-canonical-publication-20261017').glob('*.py'))
    names.update([str(BASE / 'plan.json'), 'scripts/check_record_value_publication.py',
        'scripts/book_source_references.py', 'scripts/decision_store_git.py',
        'scripts/run_with_ram_guard.sh', 'scripts/project_data_locality_env.sh',
        'doctrine/live_document_size/surfaces.jsonl',
        'docs/book/src/13k-isf-feature-support-matrix.md',
        'docs/book/src/90-reference-map.md',
        'docs/tasks/SEMANTIC-INTROSPECTION-MCP-FRONTIER.md'])
    closure=project_modules()
    assert json.dumps(closure,sort_keys=True,allow_nan=False)==json.dumps(
        json.loads((BASE/'module-closure-current.json').read_bytes()),sort_keys=True,allow_nan=False)
    names.update(closure['modules']);names.add(str(BASE/'module-closure-current.json'))
    previous=sys.path[:]
    try:
        sys.path.insert(0,'scripts')
        import book_source_references as plane
    finally:
        sys.path[:]=previous
    routes=plane.expected_rows()
    aliases={str(asset.relative_to(ROOT)):(target,row['source'])
             for row,asset,target in plane.endpoints(routes)}
    names.update([plane.SELECTION,plane.MANIFEST])
    names.update(row['source'] for row in routes)
    names.update(aliases)
    if action in ('native-final','native-v2'):
        names.update(str(SCRATCH/'book'/name) for name in (
            '13k-isf-feature-support-matrix.html','90-reference-map.html','reference-source/routes.jsonl'))
        names.update(str(SCRATCH/'book'/row['asset']) for row in routes)
    rows = {}
    for name in sorted(names):
        path = Path(name)
        plane.local_parents(ROOT/path)
        assert path.resolve().is_relative_to(ROOT) and path.stat().st_dev==ROOT.stat().st_dev
        if name in aliases:
            target,source=aliases[name]
            assert path.is_symlink() and os.readlink(path)==target
            assert path.resolve(strict=True)==(ROOT/source)
            rows[name]=dict(record(path.read_bytes()),mode=path.lstat().st_mode&0o777,symlink_target=target)
        else:
            assert not path.is_symlink()
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
    folder = SCRATCH / 'checks' / args.action
    folder.mkdir(parents=True, exist_ok=False)
    before, git_before = sources(args.action), git_state()
    command = ['scripts/run_with_ram_guard.sh', '--', *COMMANDS[args.action]]
    start = dict(owner=OWNER, utc=datetime.now(timezone.utc).isoformat(), command=command,
                 expected_status=expected, sources_before=before, git_before=git_before,
                 boundary='Complete declared current canonical/helper/test, own programme and preparation-programme source epochs. Fixed preparation authentication separately binds every saved member and original source role. Native expected refusal remains nonzero. No fresh original execution, original-parent/full-alias/HIAL/full-CI/push/visual closure.')
    save(args.action + '-started.json.gz', start)
    with (folder / 'stdout').open('xb') as out, (folder / 'stderr').open('xb') as err:
        result = subprocess.run(command, stdout=out, stderr=err)
    after, git_after = sources(args.action), git_state()
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
