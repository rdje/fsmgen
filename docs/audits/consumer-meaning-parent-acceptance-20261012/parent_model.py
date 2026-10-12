"""Complete original parent/descendant contracts and whole qualified child inputs."""
from acceptance_common import *
import meaning_readers

TEST = 't/1986-isf-record-port-value-gates.t'
CAPTURE = 'docs/audits/record-value-original-candidate-20261004'
MODES = ('ordinary', 'storable', 'controls')
PATHS = (TEST, CAPTURE + '/binding.json', CAPTURE + '/observe.pl',
    PLAN['source_contract'] + '/candidate.json.gz', PLAN['source_contract'] + '/qualification.json',
    PLAN['source_contract'] + '/proof.json',
    *(root + '/' + name for root, product in meaning_readers.ROLES.values()
      for name in (product, 'qualification.json', 'proof.json')),
    *(CAPTURE + '/' + mode + '.json' for mode in MODES))


def contracts():
    before = nodes(fixed([TASK])[TASK])
    active = nodes(gzip.decompress((BASE / 'activation-task.gz').read_bytes()))
    owner, parent = PLAN['owner'], PLAN['parent']
    need(before.keys() == active.keys() and field(before[owner], 'Status') == 'pending'
         and field(active[owner], 'Status') == 'active' and field(active[parent], 'Status') == 'active',
         'exact complete meaning-parent acceptance activation')
    need(all(field(before[owner], key) == field(active[owner], key) for key in ('Goal', 'Acceptance', 'Children'))
         and all(body == active[name] for name, body in before.items() if name != owner),
         'every unchanged whole original parent/descendant/unrelated contract retains')
    descendants = sorted(name for name in active if name.startswith(parent + '.'))
    children = [parent + '.' + str(i) for i in range(1, 5)]
    need(descendants == children and field(active[parent], 'Children') == ', '.join(children)
         and all(field(active[name], 'Status') == 'done' for name in children[:3]),
         'complete unchanged qualified meaning descendant population')
    ancestor = parent.rsplit('.', 1)[0]
    need(field(active[ancestor], 'Status') == 'active' and field(active[ancestor + '.3'], 'Status') == 'pending'
         and field(active[ancestor + '.4'], 'Status') == 'pending',
         'canonical and original consumer-parent acceptance remain separate')
    return dict(parent=active[parent].decode(), descendants={name: active[name].decode() for name in descendants},
        ancestor=active[ancestor].decode(), condition='Only unchanged independent meaning parent and its final acceptance leaf may close; canonical and original consumer-parent owners remain open.')


def inputs(*, development=False):
    bodies = fixed(PATHS)
    need(all(Path(name).read_bytes() == body for name, body in bodies.items()), 'whole fixed committed meaning-parent source input')
    def decode(name):
        return json.loads(gzip.decompress(bodies[name]) if name.endswith('.gz') else bodies[name])
    source = bodies[TEST].decode()
    need(decode(CAPTURE + '/binding.json')['sources'][TEST]['body'] == source, 'whole original meaning-parent assertion source')
    if development:
        source_role = dict(phase='development-only; source intake and formal qualification not yet admitted')
    else:
        roles = json.loads((BASE / 'source-roles.json').read_bytes())
        for name, body in bodies.items():
            entry = roles['publication']['members'][name]
            need(pin(body) == {key: entry[key] for key in ('bytes', 'sha256')}, 'whole formal meaning-parent input source role')
        source_role = pin(canonical(roles))
    return dict(source=source, prepared=decode(PLAN['source_contract'] + '/candidate.json.gz'),
        children={role: decode(root + '/' + product) for role, (root, product) in meaning_readers.ROLES.items()},
        qualifications={role: decode(root + '/qualification.json') for role, (root, _) in meaning_readers.ROLES.items()},
        native={mode: decode(CAPTURE + '/' + mode + '.json')['consumers'] for mode in MODES},
        identities={name: pin(body) for name, body in bodies.items()}, source_roles=source_role)


def header(data):
    return dict(schema_version=1, owner=PLAN['owner'], revision=PLAN['revision'],
        inputs=data['identities'], source_roles=data['source_roles'], contracts=contracts(), boundary=PLAN['condition'],
        assumptions='Qualified complete original helper/remaining/join source model algorithms remain shared prerequisites and independently reexecute. Their whole native/source/cause evidence and every first failure retain fixed roles. Original Storable copy kinds are a qualified witness; complete synthetic trace construction and native/private/provider/flags/encoding/identity remain unmeasured.')


def propose(data):
    return dict(header(data), children=data['children'])
