"""Execute the full inherited reader set and committed scalar qualification."""
import subprocess
from pathlib import Path
from common import AUTHORITY, BASE, CENSUS, SCALAR, REVISION, SCOPE, canonical, module, need, pin, save
from run import execute


def inputs():
    return [AUTHORITY, CENSUS/'census.json', CENSUS/'source-models.json',
            SCALAR/'manifest-qualified.json', SCALAR/'qualified-proof.json']


def readers():
    result = dict(module(Path('docs/audits/observer-predicate-values-20261010/common.py'))['READERS'])
    result['predicate-values'] = ['docs/audits/observer-predicate-values-20261010/verify.py']
    result['scalar-values'] = [str(SCALAR/'verify.py')]
    return result


def main():
    fixed = {}
    for path in inputs():
        command = ['git', '--no-replace-objects', 'show', REVISION+':'+str(path)]
        result = subprocess.run(command, capture_output=True)
        need(result.returncode == 0 and not result.stderr and result.stdout == path.read_bytes(),
             'whole fixed/current regex prerequisite source')
        fixed[str(path)] = dict(command=command, status=result.returncode, identity=pin(result.stdout))
    receipts = {name: execute('prerequisite-'+name, ['python3', '-B', *arguments])
                for name, arguments in readers().items()}
    save('prerequisites.json', dict(revision=REVISION, fixed=fixed,
        readers={k:pin(canonical(v)) for k,v in receipts.items()}, scope=SCOPE))


if __name__ == '__main__':
    main()
