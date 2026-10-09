"""Reproduce the first transport-mode failure and qualify explicit archive policy."""
import hashlib
import io
import json
import runpy
import subprocess
import tarfile
from pathlib import Path

BASE = Path('docs/audits/coordinate-source-hypothesis-checks-20261009')
PRODUCT = Path('docs/audits/coordinate-source-hypotheses-20261009')
REVISION = 'f5d2e81710ddbd2dd10f406551220d1a5ff2c32a'


def pin(raw):
    return {'bytes': len(raw), 'sha256': hashlib.sha256(raw).hexdigest()}


def config():
    run = subprocess.run(['git', 'config', '--local', '--null', '--list'], capture_output=True)
    if run.returncode or run.stderr:
        raise ValueError('complete read-only local configuration identity')
    return pin(run.stdout)


def main():
    before = config()
    observations = []
    files = ['docs/audits/coordinate-refusal-phases-20261009/verify.py', 'scripts/run_with_ram_guard.sh']
    for options in ([], ['-c', 'tar.umask=0002'], ['-c', 'tar.umask=0022']):
        command = ['git', '--no-replace-objects', *options, 'archive', '--format=tar', REVISION, '--', *files]
        run = subprocess.run(command, capture_output=True)
        if run.returncode or run.stderr:
            raise ValueError('complete read-only archive transport result')
        with tarfile.open(fileobj=io.BytesIO(run.stdout)) as archive:
            members = {m.name: {'mode': m.mode, 'identity': pin(archive.extractfile(m).read())}
                       for m in archive if m.isfile()}
        if set(members) != set(files):
            raise ValueError('complete controlled regular/executable archive population')
        observations.append({'command': command, 'status': run.returncode, 'stderr': run.stderr.decode(), 'members': members})
    for path, loose, strict in ((files[0], 0o664, 0o644), (files[1], 0o775, 0o755)):
        rows = [o['members'][path] for o in observations]
        if [r['mode'] for r in rows] != [loose, loose, strict] or len({r['identity']['sha256'] for r in rows}) != 1:
            raise ValueError('genuine archive policy intervention conserves every payload')
    first = BASE / 'first-verify.py.txt'
    try:
        runpy.run_path(str(first))['original']()
    except ValueError as error:
        if str(error) != 'independent complete archive mode identity':
            raise ValueError('intended retained first archive failure')
        first_failure = str(error)
    else:
        raise ValueError('first archive-mode failure did not reproduce')
    corrected = PRODUCT / 'verify.py'
    actual = runpy.run_path(str(corrected))['original']()[0]
    if actual != json.loads((PRODUCT / 'qualification.json').read_bytes())['custody'] or config() != before:
        raise ValueError('complete corrected input custody and primary configuration conservation')
    print(json.dumps({'result': 'PASS first archive-mode failure and explicit transport policy repair',
        'documentation': 'https://git-scm.com/docs/git-archive#Documentation/git-archive.txt-tarumask',
        'first_programme': pin(first.read_bytes()), 'corrected_programme': pin(corrected.read_bytes()),
        'first_failure': first_failure, 'observations': observations, 'local_configuration': before}, sort_keys=True))


if __name__ == '__main__':
    main()
