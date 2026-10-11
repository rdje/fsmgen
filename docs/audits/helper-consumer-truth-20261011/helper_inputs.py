"""Complete original source inputs; prior qualified models are shared assumptions."""
from helper_common import *
import intake

TEST = 't/1986-isf-record-port-value-gates.t'
CAPTURE = 'docs/audits/record-value-original-candidate-20261004'
CONTEXT = 'docs/audits/record-value-original-contexts-20261005'
PRIMARY = 'docs/audits/record-value-original-primary-20261005'
MODES = ('ordinary', 'storable', 'controls')
PATHS = (TEST, CAPTURE + '/observe.pl', CAPTURE + '/binding.json',
    CONTEXT + '/verify.py', CONTEXT + '/source_catalog.py', CONTEXT + '/proofs.json',
    PRIMARY + '/verify.py', PRIMARY + '/cause_model.py', PRIMARY + '/proofs.json',
    PLAN['publication'] + '/candidate.json.gz', PLAN['publication'] + '/qualification.json',
    PLAN['publication'] + '/proof.json', PLAN['association'] + '/candidate.json.gz',
    PLAN['association'] + '/association.json', PLAN['cause_parent'] + '/proof.json',
    *(CAPTURE + '/' + mode + '.json' for mode in MODES))


def module(name):
    namespace = {'__name__': 'qualified_original_helper_source', '__file__': name}
    exec(compile(Path(name).read_bytes(), name, 'exec'), namespace)
    return namespace


def inputs():
    roles = json.loads((BASE / 'source-roles.json').read_bytes())
    bodies = fixed(PATHS)
    for name, body in bodies.items():
        entry = roles['publication']['members'][name]
        need(pin(body) == {key: entry[key] for key in ('bytes', 'sha256')}
             and body == Path(name).read_bytes(), 'whole fixed original helper-consumer input')
    decode = lambda name: json.loads(gzip.decompress(bodies[name]) if name.endswith('.gz') else bodies[name])
    source = bodies[TEST].decode()
    binding = decode(CAPTURE + '/binding.json')
    need(binding['sources'][TEST]['body'] == source, 'whole original/current helper assertion source')
    prepared = decode(PLAN['publication'] + '/candidate.json.gz')
    need(len(prepared['assertions']) == 125 and prepared['boundary'].startswith('Complete original source assertion'),
         'complete qualified source-contract input without operand truth promotion')
    return dict(source=source, prepared=prepared,
        contexts=decode(CONTEXT + '/proofs.json')['proofs'],
        association=decode(PLAN['association'] + '/candidate.json.gz'),
        native={mode: decode(CAPTURE + '/' + mode + '.json')['consumers'] for mode in MODES},
        identities={name: pin(body) for name, body in bodies.items()}, source_roles=pin(canonical(roles)))


def contracts():
    before = nodes(fixed([TASK])[TASK])
    active = nodes(intake.overlays()[TASK])
    parent, owner = PLAN['parent'], PLAN['owner']
    added = {parent + '.' + str(index) for index in range(1, 5)}
    need(set(active) == set(before) | added and field(before[parent], 'Status') == 'pending'
         and field(active[parent], 'Status') == 'active'
         and field(active[parent], 'Children') == ', '.join(sorted(added)), 'exact safe complete consumer-meaning decomposition')
    need(all(field(before[parent], key) == field(active[parent], key) for key in ('Goal', 'Acceptance')),
         'unchanged whole original consumer operand/truth contract')
    for name, body in before.items():
        if name != parent:
            need(body == active[name], 'every unrelated whole original consumer task retains')
    need(all(field(active[name], 'Status') == ('active' if name == owner else 'pending') for name in added),
         'only refusal-helper truth child activates')
    return dict(parent={key: field(before[parent], key) for key in ('Goal', 'Acceptance')},
        whole_parent=active[parent].decode(), children={name: active[name].decode() for name in sorted(added)})


def header(data):
    return dict(schema_version=1, owner=PLAN['owner'], revision=PLAN['revision'],
        inputs=data['identities'], source_roles=data['source_roles'], contracts=contracts(),
        boundary=PLAN['condition'],
        comparison_scope='Only source-authored refusal-helper ok/like assertions: observer-projected integer Boolean negated eval and ASCII regex search on the complete first diagnostic line. Whole nonhelper observations retain without a truth claim.',
        assumptions='Original qualified source/context/API/parser/cause products remain shared assumptions. No native class/private/provider/flags/encoding/identity or synthetic trace construction is measured anew.')
