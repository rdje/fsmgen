"""Real independent source-directory/file controls on explicitly synthetic own fixtures."""
import os
import subprocess
from pathlib import Path
from common import *
import intake

SCRATCH = Path('.artifacts/raw-semantic-admission-20261011/topology')


def main():
    need(not (BASE / 'topology-controls.json').exists(), 'retain first whole topology executions')
    results = {}
    for name in ('positive', 'missing', 'changed-tail', 'extra-file', 'empty-directory', 'symlink', 'foreign-path'):
        fixture = local(SCRATCH / name, exists=False)
        need(not fixture.exists(), 'fresh synthetic topology fixture before writes')
        source = fixture / 'source'
        source.mkdir(parents=True)
        member = source / 'member.txt'
        original = b'complete synthetic source\n'
        member.write_bytes(original)
        member.chmod(0o644)
        members = {str(member): dict(**pin(original), mode='100644', oid='synthetic-source-control')}
        selected = [str(source)]
        if name == 'missing':
            member.unlink()
        elif name == 'changed-tail':
            member.write_bytes(original + b'changed\n')
        elif name == 'extra-file':
            (source / 'extra.txt').write_bytes(b'unlisted\n')
        elif name == 'empty-directory':
            (source / 'empty').mkdir()
        elif name == 'symlink':
            (source / 'alias').symlink_to('member.txt')
        elif name == 'foreign-path':
            # Refusal is checked before access; no foreign repository is touched.
            selected = ['.git/foreign-admission-control']
        candidate = dict(roots=selected, members=members)
        candidate_path = fixture / 'candidate.json'
        candidate_path.write_bytes(canonical(candidate))
        diagnostic = None
        try:
            intake.graph(selected, members)
            for path, row in members.items():
                actual = identity(path)
                need(actual == dict(bytes=row['bytes'], sha256=row['sha256'], executable=False), 'whole synthetic source bytes/mode')
        except (ValueError, FileNotFoundError) as error:
            diagnostic = str(error)
        command = ['perl', str(BASE / 'census.pl'), str(candidate_path)]
        actual = subprocess.run(command, capture_output=True)
        native = dict(command=command, status=actual.returncode, stdout=actual.stdout.decode(), stderr=actual.stderr.decode())
        entries = []
        for path in sorted(source.rglob('*')):
            row = dict(path=str(path.relative_to(source)), symlink=path.is_symlink(), directory=path.is_dir())
            if path.is_symlink():
                row['target'] = os.readlink(path)
            elif path.is_file():
                row['body'] = path.read_bytes().decode()
            entries.append(row)
        row = dict(input=candidate, source_entries=entries, python_diagnostic=diagnostic, native=native,
                   scope='Synthetic ordinary own-source control only; no original native input is changed and foreign paths are refused before access.')
        save('topology-' + name + '.json', row)
        # Persist candidate, native streams and Python outcome before assertions.
        need(type(actual.returncode) is int, 'actual native source-control exit')
        if name == 'positive':
            need(diagnostic is None and actual.returncode == 0 and actual.stderr == b'', 'independent positive source-control result')
        else:
            need(diagnostic is not None and actual.returncode != 0, 'independent hostile source-control result: ' + name)
        results[name] = row
    save('topology-controls.json', dict(programme=pin(local(BASE / 'topology.py').read_bytes()), cases=results))
    print('PASS complete synthetic source topology and whole-byte controls through independent Python and native readers; no foreign repository accessed.')


if __name__ == '__main__':
    main()
