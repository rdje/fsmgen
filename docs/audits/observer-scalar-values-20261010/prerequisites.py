"""Execute the complete committed prerequisite reader set without original recapture."""
import subprocess
from common import BASE, CENSUS, PREDICATE, REVISION, SCOPE, canonical, module, need, pin, save
from run import execute


def main():
    prior = module(PREDICATE / 'common.py')
    readers = dict(prior['READERS'])
    readers['predicate-values'] = [str(PREDICATE / 'verify.py')]
    fixed = {}
    for path in [CENSUS / 'census.json', CENSUS / 'source-models.json',
                 PREDICATE / 'manifest-final.json', PREDICATE / 'predicate-values-qualified.json']:
        command = ['git', '--no-replace-objects', 'show', REVISION + ':' + str(path)]
        result = subprocess.run(command, capture_output=True)
        need(result.returncode == 0 and not result.stderr and result.stdout == path.read_bytes(),
             'whole fixed/current scalar prerequisite input')
        fixed[str(path)] = dict(identity=pin(result.stdout), command=command, status=result.returncode)
    receipts = {}
    for name, arguments in readers.items():
        receipts[name] = execute('prerequisite-' + name, ['python3', '-B', *arguments])
    save('prerequisites.json', dict(revision=REVISION, fixed=fixed,
         readers={k:pin(canonical(v)) for k,v in receipts.items()}, scope=SCOPE))


if __name__ == '__main__':
    main()
