"""Qualify explicit source recovery and fixture Git without whole-tree copying."""
import base64
import hashlib
import io
import json
import os
import subprocess
import tarfile
import tempfile
from pathlib import Path

import epoch

ROOT, BASE = epoch.ROOT, epoch.BASE
NAMES = ('README_POLICY.md', 'docs/book/src/reference-source/README_POLICY.markdown.source.txt',
         'scripts/check_docs_relative_paths.sh')
SOURCES = ('epoch.py', 'git_readonly.py', 'qualify.py', 'verify.py')


def identity(raw):
    return {'bytes': len(raw), 'sha256': hashlib.sha256(raw).hexdigest()}


def primary():
    directory = Path(epoch.git('rev-parse', '--absolute-git-dir').decode().strip())
    return {'files': {name: identity((directory / name).read_bytes()) if (directory / name).exists() else None
                      for name in ('index', 'config', 'HEAD', 'packed-refs')},
            'refs': epoch.git('for-each-ref', '--format=%(refname) %(objectname)').decode()}


def run(args, root, env):
    result = subprocess.run(args, cwd=root, env=env, capture_output=True, text=True)
    return {'arguments': args, 'status': result.returncode,
            'stdout': result.stdout, 'stderr': result.stderr}


def main():
    before = primary()
    metadata, rows = epoch.metadata(NAMES)
    objects = {row['oid']: base64.b64encode(epoch.git('cat-file', 'blob', row['oid'])).decode()
               for row in rows.values()}
    controls = []
    with tempfile.TemporaryDirectory(prefix='coordinate-epoch-preparation-', dir=ROOT / '.artifacts') as temporary:
        root = Path(temporary)
        epoch.recover(root, rows, NAMES)
        recovered = {}
        for path, row in rows.items():
            endpoint = root / path
            raw = os.readlink(endpoint).encode() if endpoint.is_symlink() else endpoint.read_bytes()
            assert raw == base64.b64decode(objects[row['oid']])
            recovered[path] = {'identity': identity(raw), 'mode': row['mode'],
                               'same_volume': endpoint.lstat().st_dev == ROOT.stat().st_dev,
                               'executable': bool(endpoint.lstat().st_mode & 0o111)}
        blocked = root / 'blocked'
        blocked.mkdir()
        (root / '.artifacts').symlink_to('blocked', target_is_directory=True)
        try:
            epoch.environment(root)
        except ValueError as error:
            blocked_control = {'name': 'fixture-metadata-alias', 'cause': str(error)}
        else:
            raise ValueError('false-green fixture metadata alias')
        assert not list(blocked.iterdir())
        (root / '.artifacts').unlink()
        blocked.rmdir()
        env = epoch.environment(root)
        positives = [run(args, root, env) for args in (
            ['git', 'rev-parse', 'HEAD'],
            ['git', 'show', epoch.REVISION + ':README_POLICY.md'],
            ['git', 'ls-files', '--stage', '-z', '--', *NAMES],
            ['git', '-C', 'docs/book', 'rev-parse', '--show-toplevel'])]
        ignored = subprocess.run(['git', 'check-ignore', '--no-index', '--stdin'], input='\n'.join(NAMES) + '\n',
                                 cwd=root, env=env, capture_output=True, text=True)
        positives.append({'arguments': ['git', 'check-ignore', '--no-index', '--stdin'],
                          'status': ignored.returncode, 'stdout': ignored.stdout, 'stderr': ignored.stderr})
        for args in (['git', 'add', 'README_POLICY.md'], ['git', 'read-tree', 'HEAD'],
                     ['git', 'hash-object', '-w', 'README_POLICY.md'],
                     ['git', 'archive', '-oowned.tar', 'HEAD'],
                     ['git', '-c', 'alias.unowned=!touch unowned', 'unowned']):
            result = run(args, root, env)
            assert result['status'] == 2 and result['stderr'].startswith('readonly epoch replay: Git command refused: ')
            controls.append({'name': 'refused-' + '-'.join(args[1:]), 'actual': result})
        foreign = run(['git', '-C', '..', 'rev-parse', 'HEAD'], root, env)
        assert foreign['status'] == 2 and foreign['stderr'] == 'readonly epoch replay: foreign Git working root\n'
        controls.append({'name': 'foreign-working-root', 'actual': foreign})
        calls = (root / '.artifacts/readonly-git-calls.jsonl').read_text()
        private_index = identity((root / '.artifacts/epoch.index').read_bytes())
        for name, action in (
            ('root-wildcard', lambda: epoch.scope(['.'])),
            ('missing-scope', lambda: epoch.scope([])),
            ('duplicate-scope', lambda: epoch.scope(['README_POLICY.md', 'README_POLICY.md'])),
            ('path-escape', lambda: epoch.safe_path('../escaped')),
            ('absolute-path', lambda: epoch.safe_path('/escaped')),
            ('metadata-path', lambda: epoch.safe_path('.git/config')),
            ('alias-escape', lambda: epoch.alias_target('README_POLICY.md', '../escaped')),
        ):
            try:
                action()
            except ValueError as error:
                controls.append({'name': name, 'cause': str(error)})
            else:
                raise ValueError('false-green control: ' + name)
        for name, member_name, oid in (('member-loss', 'unknown.txt', rows['README_POLICY.md']['oid']),
                                       ('blob-substitution', 'README_POLICY.md', '0' * 40)):
            child = root / name
            child.mkdir()
            member = tarfile.TarInfo(member_name)
            member.size = 1
            declared = {'README_POLICY.md': {'mode': '100644', 'oid': oid}}
            try:
                epoch.restore(member, io.BytesIO(b'x'), child, declared)
            except ValueError as error:
                controls.append({'name': name, 'cause': str(error)})
            else:
                raise ValueError('false-green control: ' + name)
    controls.append(blocked_control)
    after = primary()
    assert before == after
    proof = {'scope': 'Explicit small preparation population only; complete dated replay/current publication remains successor-owned. Logical historical path-size sum is not .git size or corruption evidence; whole-tree recovery was retired before copying.',
             'revision': epoch.REVISION, 'names': NAMES, 'metadata_base64': base64.b64encode(metadata).decode(),
             'objects': objects, 'rows': rows, 'recovered': recovered,
             'primary_before': before, 'primary_after': after, 'private_index': private_index,
             'positives': positives, 'controls': controls, 'accepted_calls': calls,
             'sources': {name: (BASE / name).read_text() for name in SOURCES}}
    (BASE / 'proof.json').write_text(json.dumps(proof, sort_keys=True, indent=2) + '\n')
    print('PASS explicit same-volume preparation, exact object/mode/alias recovery and read-only Git controls; full replay remains open.')


if __name__ == '__main__':
    main()
