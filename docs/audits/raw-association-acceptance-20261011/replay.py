"""Fresh read-only execution of every complete committed semantic intervention."""
import subprocess
from common import *

NATIVE = 'PASS independent original UTF-8 body, empty membership and lossless physical byte conservation; semantics remain pending.\n'
SEMANTIC = 'PASS independent complete original raw semantic links; inherited bodies and native/private limits conserve.\n'
CASES = [
    ('positive', None),
    ('full-stack', 'semantic full stack and complete ordered body'),
    ('first-cause', 'semantic complete source first cause'),
    ('wrong-caller', 'semantic source caller and coordinate association'),
    ('borrowed-address', 'semantic whole simultaneous address/holder association'),
    ('header-order', 'semantic complete ordered source header and arguments'),
    ('argument-role', 'semantic complete ordered source header and arguments'),
    ('opaque-promotion', 'semantic complete opaque allocation'),
    ('scope-promotion', 'semantic scope and original native/private boundary'),
    ('omitted-record', 'semantic complete original member allocation'),
    ('nested-cause', 'semantic whole nested inner/outer cause association'),
    ('phase-order', 'semantic complete ordered throw-phase allocation'),
    ('class-promotion', 'semantic whole source guard class and phase'),
    ('public-header', 'semantic complete public header association'),
    ('load-operator', 'semantic whole source do and diagnostic load association'),
    ('boolean-phase', 'semantic complete ordered throw-phase allocation'),
]


def epoch():
    return dict(closure=programs(), semantic={str(path): dict(body=(raw := local(path).read_bytes()).decode(), identity=pin(raw))
        for path in sorted(PRIOR.iterdir()) if path.suffix in ('.py', '.pl')})


def selected(member):
    paths = [Path('docs/audits') / path for path in PATHS.values()]
    paths += [CONSTRUCTION / 'native.pl', CONSTRUCTION / 'candidate.json.gz', PRIOR / member]
    return {str(path): identity(path) for path in paths}


def validate(row, name, kind, cause, member):
    command = (['perl', str(PRIOR / 'native.pl'), str(PRIOR / member)] if kind == 'native'
               else ['python3', '-B', str(PRIOR / 'reader.py'), str(PRIOR / member)])
    need(row['command'] == command and row['programmes'] == row['programmes_after'] == epoch()
         and row['inputs'] == row['inputs_after'] == selected(member), 'complete fresh association control epoch: ' + name)
    need(local(row['stdout_path']).read_bytes() == row['stdout'].encode()
         and local(row['stderr_path']).read_bytes() == row['stderr'].encode(), 'whole actual association control streams')
    need(type(row['status']) is int, 'association result status requires a JSON integer')
    if kind == 'native' or cause is None:
        need(row['status'] == 0 and row['stderr'] == '' and row['stdout'] == (NATIVE if kind == 'native' else SEMANTIC),
             'actual unchanged whole body or complete positive semantic predicate: ' + name)
    else:
        need(row['status'] != 0 and row['stdout'] == '' and row['stderr'].endswith('ValueError: ' + cause + '\n'),
             'actual intended independent complete semantic refusal: ' + name)


def one(name, kind, cause, member):
    label = 'fresh-' + name + '-' + kind
    if (BASE / (label + '-actual.json')).exists():
        row = load(label + '-actual.json')
        validate(row, name, kind, cause, member)
        return label + '-actual.json'
    command = (['perl', str(PRIOR / 'native.pl'), str(PRIOR / member)] if kind == 'native'
               else ['python3', '-B', str(PRIOR / 'reader.py'), str(PRIOR / member)])
    stdout, stderr = BASE / (label + '.stdout.txt'), BASE / (label + '.stderr.txt')
    started = dict(command=command, programmes=epoch(), inputs=selected(member), stdout_path=str(stdout), stderr_path=str(stderr),
                   outcome='started; absent terminal result is non-success')
    save(label + '-started.json', started)
    with stdout.open('xb', buffering=0) as out, stderr.open('xb', buffering=0) as err:
        result = subprocess.run(command, stdout=out, stderr=err)
    actual = dict(**started, status=result.returncode, stdout=stdout.read_bytes().decode(), stderr=stderr.read_bytes().decode(),
                  programmes_after=epoch(), inputs_after=selected(member))
    save(label + '-actual.json', actual)
    validate(actual, name, kind, cause, member)
    return label + '-actual.json'


def rows():
    raw = local(PRIOR / 'bounded-controls.json').read_bytes()
    observed = json.loads(raw)
    need(raw == canonical(observed) and [(r['name'], r['cause']) for r in observed['cases']] == CASES,
         'entire independently declared committed semantic control allocation')
    need(all(r['member'] == 'control-' + r['name'] + '.json.gz' for r in observed['cases']),
         'exact complete committed intervention members')
    return observed['cases']


if __name__ == '__main__':
    outcomes = []
    for row in rows():
        name, cause, member = row['name'], row['cause'], row['member']
        outcomes.append(dict(name=name, cause=cause, member=member,
            native=one(name, 'native', cause, member), semantic=one(name, 'semantic', cause, member)))
        print('qualified complete fresh association control', name, flush=True)
    save('fresh-controls.json', dict(cases=outcomes, scope=SCOPE,
        condition='Every complete committed candidate remains immutable. The prior default separately reconstructs each exact declared mutation and unchanged inherited projection. This process freshly executes the unchanged original-body and independent source-first semantic readers on every whole candidate; each child exits before the next.'))
