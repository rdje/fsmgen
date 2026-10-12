"""Authenticate whole admitted premises; no native passed flag supplies truth."""
import stat
from association_common import *

MODES = ('ordinary', 'storable', 'controls')
DOMAINS = ('api', 'copies', 'parses', 'test_run')
PATHS = {
    'admission': PLAN['admission'] + '/proof.json',
    'manifest': PLAN['admission'] + '/manifest.json',
    'roles': PLAN['admission'] + '/source-roles.json',
    'contexts': PLAN['context'] + '/proofs.json',
    'cause': PLAN['cause'] + '/candidate.json.gz',
    'cause_qualification': PLAN['cause'] + '/association.json',
    'consumer': PLAN['consumer'] + '/candidate.json.gz',
    'consumer_qualification': PLAN['consumer'] + '/qualification.json',
    'execution': PLAN['capture'] + '/execution.json',
    'binding': PLAN['capture'] + '/binding.json',
    'test': 't/1986-isf-record-port-value-gates.t',
    'products': 'docs/audits/record-value-products-20261004/products.json',
    'authored': 'docs/audits/record-value-fields-20261004/authored-models.json',
    'actors': 'docs/audits/record-value-actors-20261004/actor-models.json',
    'copy_inputs': 'docs/audits/record-value-copy-inputs-20261004/inputs.json',
    'copy_proofs': 'docs/audits/record-value-original-copy-reader-20261004/proofs.json',
    'scope_models': 'docs/audits/record-value-scopes-20261004/scope-products.json',
    'reference_models': 'docs/audits/record-value-references-20261004/reference-products.json',
    'copy_models': 'docs/audits/record-value-copies-20261004/copy-products.json',
    'payload_models': 'docs/audits/record-value-identities-20261004/identity-products.json',
    **{mode: PLAN['capture'] + '/' + mode + '.json' for mode in MODES}}


def inputs():
    declaration = json.loads((BASE / 'input-contracts.json').read_bytes())
    need(set(declaration) == {'command', 'condition', 'inputs', 'scope'}
         and declaration['command'] == ['python3', '-B', PLAN['admission'] + '/verify.py']
         and declaration['scope'] == PLAN['condition']
         and set(declaration['inputs']) == set(PATHS.values()), 'closed complete admitted association input contract')
    bodies = fixed(PATHS.values())
    decoded = {}
    for role, name in PATHS.items():
        body = bodies[name]
        info = Path(name).lstat()
        need(stat.S_ISREG(info.st_mode) and info.st_dev == Path.cwd().stat().st_dev
             and Path(name).read_bytes() == body and pin(body) == declaration['inputs'][name],
             'whole fixed same-volume admitted association source: ' + role)
        if role == 'test':
            decoded[role] = body.decode()
        else:
            raw = gzip.decompress(body) if name.endswith('.gz') else body
            decoded[role] = json.loads(raw)
            if name.endswith('.gz'):
                need(raw == canonical(decoded[role]), 'whole canonical compressed admitted source product')
    admitted, roles = decoded['admission'], decoded['roles']
    need(admitted['source'] == pin(canonical(roles))
         and roles['publication']['revision'] == admitted['revision'], 'complete admitted source graph and original epoch bind')
    for role, name in PATHS.items():
        if role not in ('admission', 'manifest', 'roles'):
            entry = roles['publication']['members'][name]
            need(pin(bodies[name]) == {key: entry[key] for key in ('bytes', 'sha256')},
                 'every original model/native/product belongs to the complete admitted source graph')
    need(same(admitted['meanings']['context']['proof'], decoded['contexts'])
         and same(admitted['meanings']['consumer']['proof']['qualification'], decoded['consumer_qualification']),
         'whole exact context and consumer meanings belong to completed admission')
    need(decoded['cause_qualification']['product'] == pin(canonical(decoded['cause']))
         and decoded['consumer_qualification']['candidate'] == pin(canonical(decoded['consumer'])),
         'whole exact qualified cause and consumer products')
    need(decoded['binding']['sources'][PATHS['test']]['body'] == decoded['test'],
         'whole original authored test source retains')
    need([row['mode'] for row in decoded['contexts']['proofs']] == list(MODES)
         and [row['mode'] for row in decoded['cause']['modes']] == list(MODES)
         and [row['mode'] for row in decoded['consumer']['meanings']['children']['join']['modes']] == list(MODES),
         'complete original unchanged-input modes retain')
    decoded['identities'] = declaration['inputs']
    return decoded


def header(data):
    admitted = data['admission']
    return dict(schema_version=1, owner=PLAN['owner'], revision=PLAN['revision'],
        inputs=data['identities'], contracts=contracts(), boundary=PLAN['condition'],
        original_conditions={role: value['declaration']['condition'] for role, value in admitted['meanings'].items()},
        source_role_condition=data['roles']['condition'],
        source_model_assumptions=data['consumer']['assumptions'],
        assurance=dict(original_native_private=False, later_historical_execution_currency=False,
                       original_producer_recapture=False, full_alias=False, canonical_parent=False),
        truth_authority='complete admitted source-derived typed operands/outcomes and primary causes; native flags are observations')


def contracts():
    before = nodes(fixed([TASK])[TASK])
    active = nodes(gzip.decompress((BASE / 'activation-task.gz').read_bytes()))
    owner = PLAN['owner']
    need(before.keys() == active.keys() and field(before[owner], 'Status') == 'pending'
         and field(active[owner], 'Status') == 'active', 'only existing complete association leaf activates')
    for name, block in before.items():
        if name == owner:
            need(all(field(block, key) == field(active[name], key) for key in ('Goal', 'Acceptance', 'Children', 'Commit')),
                 'unchanged complete association contract')
        else:
            need(block == active[name], 'every unrelated whole original task block retains')
    admission = owner.rsplit('.', 1)[0] + '.1'
    need(field(active[admission], 'Status') == 'done' and field(active[PLAN['parent']], 'Status') == 'active'
         and field(active[PLAN['acceptance']], 'Status') == field(active[PLAN['full_alias']], 'Status') == 'pending',
         'admission done; canonical/parent and full-alias acceptances remain separate')
    return dict(owner=active[owner].decode(), parent=active[PLAN['parent']].decode(),
                admission=active[admission].decode(), acceptance=active[PLAN['acceptance']].decode(),
                full_alias=active[PLAN['full_alias']].decode())


def records(native, domain):
    return [native['test_run']] if domain == 'test_run' else native[domain]


def context(native):
    return {key: native[key] for key in ('kind', 'caller', 'helper', 'parse') if key in native}


def cause_mode(data, mode):
    return next(row for row in data['cause']['modes'] if row['mode'] == mode)


def context_mode(data, mode):
    return next(row for row in data['contexts']['proofs'] if row['mode'] == mode)


def consumer_mode(data, mode):
    return next(row for row in data['consumer']['meanings']['children']['join']['modes'] if row['mode'] == mode)
