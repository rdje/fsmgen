"""Whole fixed source inputs; qualified source models remain shared assumptions."""
from remaining_common import *
import intake

TEST = 't/1986-isf-record-port-value-gates.t'
CAPTURE = 'docs/audits/record-value-original-candidate-20261004'
PRODUCTS = 'docs/audits/record-value-products-20261004'
AUTHORED = 'docs/audits/record-value-fields-20261004/authored-models.json'
ACTORS = 'docs/audits/record-value-actors-20261004/actor-models.json'
COPY_INPUTS = 'docs/audits/record-value-copy-inputs-20261004/inputs.json'
COPY_PROOFS = 'docs/audits/record-value-original-copy-reader-20261004/proofs.json'
FAMILIES = {'scope': ('scopes', 'scope-products.json'),
            'reference': ('references', 'reference-products.json'),
            'copy': ('copies', 'copy-products.json'),
            'payload': ('identities', 'identity-products.json')}
MODES = ('ordinary', 'storable', 'controls')
PATHS = (TEST, CAPTURE + '/observe.pl', CAPTURE + '/binding.json', AUTHORED, ACTORS,
    COPY_INPUTS, COPY_PROOFS, 'docs/audits/record-value-original-copy-reader-20261004/verify.py',
    PRODUCTS + '/products.json', 'docs/audits/record-value-original-products-20261005/verify.py',
    PLAN['source_contract'] + '/candidate.json.gz', PLAN['source_contract'] + '/qualification.json',
    PLAN['source_contract'] + '/proof.json', PLAN['publication'] + '/candidate.json.gz',
    PLAN['publication'] + '/qualification.json', PLAN['publication'] + '/proof.json',
    *(CAPTURE + '/' + mode + '.json' for mode in MODES),
    *('docs/audits/record-value-' + family + '-20261004/' + filename
      for family, filename in FAMILIES.values()))


def inputs():
    roles = json.loads((BASE / 'source-roles.json').read_bytes())
    bodies = fixed(PATHS)
    for name, body in bodies.items():
        entry = roles['publication']['members'][name]
        need(pin(body) == {key: entry[key] for key in ('bytes', 'sha256')}
             and body == Path(name).read_bytes(), 'whole fixed original remaining-consumer input')
    def decode(name):
        return json.loads(gzip.decompress(bodies[name]) if name.endswith('.gz') else bodies[name])
    source = bodies[TEST].decode()
    need(decode(CAPTURE + '/binding.json')['sources'][TEST]['body'] == source,
         'whole original/current remaining assertion source')
    prepared = decode(PLAN['source_contract'] + '/candidate.json.gz')
    need(len(prepared['assertions']) == 125, 'complete qualified original source contracts')
    models = {kind: decode('docs/audits/record-value-' + family + '-20261004/' + filename)['rows']
              for kind, (family, filename) in FAMILIES.items()}
    return dict(source=source, prepared=prepared, authored=decode(AUTHORED), actors=decode(ACTORS),
        copy_inputs=decode(COPY_INPUTS)['rows'], copy_proofs=decode(COPY_PROOFS)['proofs'],
        products=decode(PRODUCTS + '/products.json'), models=models,
        native={mode: decode(CAPTURE + '/' + mode + '.json')['consumers'] for mode in MODES},
        identities={name: pin(body) for name, body in bodies.items()}, source_roles=pin(canonical(roles)))


def contracts():
    before = nodes(fixed([TASK])[TASK])
    active = nodes(intake.overlays()[TASK])
    owner, parent = PLAN['owner'], PLAN['parent']
    need(before.keys() == active.keys() and field(before[owner], 'Status') == 'pending'
         and field(active[owner], 'Status') == 'active', 'only existing remaining assertion leaf activates')
    for name, block in before.items():
        if name == owner:
            need(all(field(block, key) == field(active[name], key) for key in ('Goal', 'Acceptance', 'Children')),
                 'unchanged complete remaining assertion contract')
        else:
            need(block == active[name], 'every unrelated complete original task block retains')
    need(field(active[parent], 'Status') == 'active' and field(active[parent + '.1'], 'Status') == 'done'
         and all(field(active[parent + '.' + str(index)], 'Status') == 'pending' for index in (3, 4)),
         'helper done and complete consumer join/acceptance remain separate')
    return dict(parent=active[parent].decode(), owner=active[owner].decode(),
                siblings={parent + '.' + str(index): active[parent + '.' + str(index)].decode()
                          for index in (1, 3, 4)})


def header(data):
    return dict(schema_version=1, owner=PLAN['owner'], revision=PLAN['revision'],
        inputs=data['identities'], source_roles=data['source_roles'], contracts=contracts(),
        boundary=PLAN['condition'],
        comparison_scope='Remaining source assertions only: observed projected Boolean, defined scalar string equality, whole structural scalar-string equality, and finite ASCII regex search/negation. Raw operand primitive kinds remain independently exact.',
        assumptions='Qualified original source/type/actor/path/API/copy products and original Storable test-copy primitive-kind witness remain shared assumptions. The witness supplies recorded detached-copy kinds, not a new provider/flag/identity measurement. Complete original synthetic Carp trace is an authenticated opaque native input; its native coordinates/framework/private/provider/flags/encoding/identity and construction are not independently measured.')
