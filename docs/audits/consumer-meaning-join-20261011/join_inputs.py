"""Whole original source assertions, native observations and qualified child roles."""
from join_common import *
import intake

TEST = 't/1986-isf-record-port-value-gates.t'
CAPTURE = 'docs/audits/record-value-original-candidate-20261004'
MODES = ('ordinary', 'storable', 'controls')
PATHS = (TEST, CAPTURE + '/observe.pl', CAPTURE + '/binding.json',
    PLAN['source_contract'] + '/candidate.json.gz', PLAN['source_contract'] + '/qualification.json',
    PLAN['source_contract'] + '/proof.json',
    PLAN['helper'] + '/candidate.json.gz', PLAN['helper'] + '/qualification.json', PLAN['helper'] + '/proof.json',
    PLAN['remaining'] + '/candidate-v2.json.gz', PLAN['remaining'] + '/qualification.json', PLAN['remaining'] + '/proof.json',
    *(CAPTURE + '/' + mode + '.json' for mode in MODES))


def inputs():
    roles = json.loads((BASE / 'source-roles.json').read_bytes())
    bodies = fixed(PATHS)
    for name, body in bodies.items():
        entry = roles['publication']['members'][name]
        need(pin(body) == {key: entry[key] for key in ('bytes', 'sha256')}
             and body == Path(name).read_bytes(), 'whole fixed original consumer join input')
    def decode(name):
        return json.loads(gzip.decompress(bodies[name]) if name.endswith('.gz') else bodies[name])
    source = bodies[TEST].decode()
    need(decode(CAPTURE + '/binding.json')['sources'][TEST]['body'] == source, 'whole original assertion source')
    prepared = decode(PLAN['source_contract'] + '/candidate.json.gz')
    need(len(prepared['assertions']) == 125 and prepared['boundary'].startswith('Complete original source assertion'),
         'complete qualified source assertion domain')
    children = {'helper': decode(PLAN['helper'] + '/candidate.json.gz'),
                'remaining': decode(PLAN['remaining'] + '/candidate-v2.json.gz')}
    return dict(source=source, prepared=prepared, children=children,
        qualifications={role: decode(PLAN[role] + '/qualification.json') for role in children},
        native={mode: decode(CAPTURE + '/' + mode + '.json')['consumers'] for mode in MODES},
        identities={name: pin(body) for name, body in bodies.items()}, source_roles=pin(canonical(roles)))


def contracts():
    before = nodes(fixed([TASK])[TASK])
    active = nodes(intake.overlays()[TASK])
    owner, parent = PLAN['owner'], PLAN['parent']
    need(before.keys() == active.keys() and field(before[owner], 'Status') == 'pending'
         and field(active[owner], 'Status') == 'active' and field(active[parent], 'Status') == 'active',
         'exact already-owned complete consumer join activation')
    need(all(field(before[owner], key) == field(active[owner], key) for key in ('Goal', 'Acceptance', 'Children')),
         'whole unchanged original complete consumer join contract')
    need(all(body == active[name] for name, body in before.items() if name != owner),
         'every unrelated original complete task block retains')
    need(all(field(active[parent + '.' + str(i)], 'Status') == 'done' for i in (1, 2))
         and field(active[parent + '.4'], 'Status') == 'pending', 'qualified children and separate meaning acceptance retain')
    return dict(parent=active[parent].decode(), owner=active[owner].decode(),
                children={parent + '.' + str(i): active[parent + '.' + str(i)].decode() for i in range(1, 5)})


def header(data):
    return dict(schema_version=1, owner=PLAN['owner'], revision=PLAN['revision'], inputs=data['identities'],
        source_roles=data['source_roles'], contracts=contracts(), boundary=PLAN['condition'],
        assumptions='Complete committed helper/remaining source-meaning algorithms are shared qualified prerequisites, independently reexecuted through isolated readers. Original source/native/private/synthetic/Storable witnesses keep their exact dated limits.',
        comparison_scope='Every original source assertion in each unchanged mode; source meaning and whole primitive/structural operands joined before native flag/body custody. No flag is an outcome authority.')
