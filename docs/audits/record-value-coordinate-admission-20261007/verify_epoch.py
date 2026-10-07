"""Qualify retained live-epoch failure and actual unchanged historical execution."""
import copy
import json
import subprocess
import tarfile
from pathlib import Path

BASE = Path('docs/audits/record-value-coordinate-admission-20261007')
REVISION = 'e0620dd2ffb04c340b91693a04f5885c8abb6595'
OLD_CHECKS = Path('docs/audits/class-frame-publication-checks-20261006')
COMMAND = ['python3', '-B', str(OLD_CHECKS / 'verify_seal.py')]


def require(condition, cause):
    if not condition:
        raise ValueError(cause)


def load(path):
    return json.loads(path.read_bytes())


def same(left, right):
    return json.dumps(left, sort_keys=True, allow_nan=False) == json.dumps(right, sort_keys=True, allow_nan=False)


def fixed_members():
    """Reconstruct all committed member values without trusting the fixture."""
    import hashlib
    result = {}
    process = subprocess.Popen(['git', 'archive', REVISION], stdout=subprocess.PIPE)
    try:
        with tarfile.open(fileobj=process.stdout, mode='r|') as archive:
            for entry in archive:
                if entry.isdir():
                    continue
                if entry.isfile():
                    raw = archive.extractfile(entry).read()
                    result[entry.name] = dict(bytes=len(raw), sha256=hashlib.sha256(raw).hexdigest())
                elif entry.issym():
                    result[entry.name] = dict(kind='opaque-symlink', target=entry.linkname)
                else:
                    raise ValueError('unsupported fixed historical archive member')
    except BaseException:
        process.terminate()
        raise
    finally:
        process.stdout.close(); process.wait()
    require(process.returncode == 0, 'actual independent historical source archive success')
    return result


def check(actual, expected):
    require(set(actual) == {'revision', 'destination', 'command', 'status', 'stdout', 'stderr',
        'members', 'after_members', 'programme', 'role'}, 'closed historical epoch actual execution')
    require(type(actual['status']) is int and actual['status'] == 0, 'historical epoch actual integer success')
    require(actual['revision'] == REVISION and actual['destination'] == '.artifacts/coordinate-publication-epoch'
        and actual['command'] == COMMAND and actual['stdout'] == load(OLD_CHECKS / 'independent-result.json')['stdout']
        and actual['stderr'] == '', 'whole unchanged historical epoch command and streams')
    require(all(type(pin['bytes']) is int and pin['bytes'] >= 0
        for population in (actual['members'], actual['after_members']) for pin in population.values()
        if 'bytes' in pin), 'historical epoch discrete member byte kinds')
    require(same(actual['members'], expected) and same(actual['after_members'], expected),
            'whole independent historical committed source population')
    import hashlib
    programme = (BASE / 'replay_epoch.py').read_bytes()
    require(same(actual['programme'], dict(bytes=len(programme), sha256=hashlib.sha256(programme).hexdigest())),
            'whole actual historical epoch controller identity')
    require(actual['role'] == 'Fresh unchanged complete historical actual-result qualifier at its exact committed source epoch; original evidence retained and live publication bytes untouched. No later current currency.',
            'historical epoch execution cannot establish later currency')


def main():
    actual = load(BASE / 'historical-epoch-actual.json')
    expected = fixed_members(); check(actual, expected)
    first = load(BASE / 'first-actual-publication_result.json')
    require(type(first['status']) is int and first['status'] == 1 and first['command'] == COMMAND
        and first['stdout'] == '' and first['stderr'].endswith('ValueError: whole actual current physical source and non-target conservation\n'),
        'whole retained historical qualifier live-epoch refusal')
    import hashlib
    source = (BASE / 'first-verify.py.txt').read_bytes()
    require(same(first['instruments'][str(BASE / 'verify.py')], dict(bytes=len(source), sha256=hashlib.sha256(source).hexdigest())),
            'whole first refusal invocation controller identity')
    old = {'__name__': 'old_publication_epoch_check', '__file__': str(OLD_CHECKS / 'verify_publication.py')}
    exec(compile((OLD_CHECKS / 'verify_publication.py').read_bytes(), old['__file__'], 'exec'), old)
    namespace = old['ns']
    epoch = {**{p: raw for p, raw in namespace['sources']().items() if Path(p).parent == Path('docs/knowledge')},
        **{p: text.encode() for p, text in namespace['model']['cards']().items()}}
    require(namespace['public']['cards']() != epoch, 'genuine live source progress differs from old publication epoch')
    require(old['check'](load(old['BASE'] / 'publication.json')) == load(OLD_CHECKS / 'publication-proof.json')['proof'],
            'whole saved publication source proof still reconstructs independently of live currency')
    controls = []
    for name, mutate, cause in (
        ('Boolean-status', lambda r:r.update(status=True), 'historical epoch actual integer success'),
        ('float-status', lambda r:r.update(status=0.0), 'historical epoch actual integer success'),
        ('lost-historical-source', lambda r:r['members'].pop(next(iter(r['members']))), 'whole independent historical committed source population'),
        ('Boolean-member-bytes', lambda r:next(pin for pin in r['members'].values() if 'bytes' in pin).update(bytes=True), 'historical epoch discrete member byte kinds'),
        ('wrong-committed-epoch', lambda r:r.update(revision='5f20dde9c42acb997c0a27d3957a7cdb2183802a'), 'whole unchanged historical epoch command and streams'),
        ('later-current-promotion', lambda r:r.update(role='Original formatter and later currency measured.'), 'historical epoch execution cannot establish later currency')):
        candidate = copy.deepcopy(actual); mutate(candidate)
        require(not same(candidate, actual), 'genuine historical epoch intervention: ' + name)
        try:
            check(candidate, expected)
        except ValueError as error:
            require(str(error) == cause, 'intended historical epoch refusal: ' + name)
            controls.append(dict(control=name, cause=cause))
        else:
            raise ValueError('false-green historical epoch result: ' + name)
    borrowed = load(BASE / 'actual-current.json')
    require(type(borrowed['status']) is int and borrowed['status'] == 0, 'genuine narrower current-only success')
    candidate = copy.deepcopy(actual); candidate.update(command=borrowed['command'], stdout=borrowed['stdout'])
    try:
        check(candidate, expected)
    except ValueError as error:
        require(str(error) == 'whole unchanged historical epoch command and streams', 'intended borrowed current-only result refusal')
        controls.append(dict(control='borrowed-current-only-success', cause=str(error)))
    else:
        raise ValueError('borrowed current-only success accepted as historical qualifier')
    print(json.dumps(dict(revision=REVISION, members=len(expected), controls=controls,
        scope='Whole retained genuine live-epoch failure and independently reconstructed complete unchanged historical execution; original programmes/seals retain and later current currency is separate.'), sort_keys=True))


if __name__ == '__main__':
    main()
