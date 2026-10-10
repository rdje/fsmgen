"""Actually rerun every completed source/value/publication prerequisite."""
import subprocess
from common import BASE, BOUNDARY, PREDICATE, SCALAR, REGEX, REVISION, SCOPE, canonical, fixed_inputs, need, pin, save
from run import execute


def readers():
    # This is the complete declared source prerequisite set. Dated publication
    # readers use their explicitly qualified committed context, not later tasks.
    namespace = {'__name__': 'source_value_prerequisites'}
    exec(compile((PREDICATE/'common.py').read_bytes(), str(PREDICATE/'common.py'), 'exec'), namespace)
    result = dict(namespace['READERS'])
    result.update({
        'predicate-values': [str(PREDICATE/'verify.py')],
        'scalar-values': [str(SCALAR/'verify.py')],
        'regex-values': [str(REGEX/'verify.py')],
        'regex-dated-publication': [str(BOUNDARY/'checkpoint.py'), '--replay'],
        'remaining-value-boundaries': [str(BOUNDARY/'verify.py')],
        'remaining-value-dated-publication': [str(BOUNDARY/'publication_verify.py')],
    })
    return result


def main():
    fixed = {}
    for path in fixed_inputs():
        command = ['git', '--no-replace-objects', 'show', REVISION+':'+str(path)]
        actual = subprocess.run(command, capture_output=True)
        need(actual.returncode == 0 and actual.stderr == b'' and actual.stdout == path.read_bytes(),
             'whole fixed/current source-value input custody')
        fixed[str(path)] = dict(command=command, status=actual.returncode, identity=pin(actual.stdout))
    receipts = {}
    for name, arguments in readers().items():
        record = execute('prerequisite-'+name, ['python3', '-B', *arguments])
        receipts[name] = dict(context='complete fixed committed inputs' if 'dated-publication' in name
                             else 'current fixed source inputs',
                             receipt='actual-prerequisite-'+name+'-1.json', identity=pin(canonical(record)))
    save('prerequisites.json', dict(revision=REVISION, fixed=fixed, readers=receipts, scope=SCOPE))
    print('PASS complete fresh source-value prerequisite set and exact source versus dated-publication contexts.')


if __name__ == '__main__':
    main()
