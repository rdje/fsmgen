"""Complete qualified child inputs; their source models remain explicit assumptions."""
import ast
from parent_common import *
import requirements

REPLAYS = ('preparation', 'association', 'canonical_preparation', 'publication', 'raw')


def original_inputs():
    proof_names = {role: PLAN[role] + '/proof.json' for role in REPLAYS}
    bodies = fixed(proof_names.values())
    proofs = {role: json.loads(bodies[name]) for role, name in proof_names.items()}
    paths = {role: PLAN[role] + '/verify.py' for role in REPLAYS}
    reader_bodies = fixed(paths.values())
    successes = {}
    for role, path in paths.items():
        syntax = ast.parse(reader_bodies[path], path)
        values = [ast.literal_eval(node.value) for node in syntax.body if isinstance(node, ast.Assign)
                  and any(isinstance(target, ast.Name) and target.id == 'SUCCESS' for target in node.targets)]
        need(len(values) == 1 and type(values[0]) is str, 'one whole fixed original child success contract')
        successes[role] = values[0]
    actual_names = {name: PLAN['preparation'] + '/' + name + '-actual.json'
                    for name in proofs['preparation']['prerequisites']}
    actual_names.update(primary=PLAN['preparation'] + '/gate-primary-actual.json',
                        epoch_primary=PLAN['preparation'] + '/gate-primary-epoch-actual.json')
    actual_bodies = fixed(actual_names.values())
    native = {role: json.loads(actual_bodies[name]) for role, name in actual_names.items()}
    failures = {
        'prerequisite-first-seal': PLAN['preparation'] + '/seal-actual.json',
        'prerequisite-first-recovery': PLAN['preparation'] + '/recovery-publication-actual.json',
        'raw-first-prior': PLAN['raw'] + '/gate-prior-actual.json',
        'raw-first-core': PLAN['raw'] + '/gate-core-actual.json',
    }
    failure_bodies = fixed(failures.values())
    failed = {role: json.loads(failure_bodies[name]) for role, name in failures.items()}
    need(all(type(row['status']) is int and row['status'] == 1
             and type(row['expected_status']) is int and row['expected_status'] == 0 for row in failed.values()),
         'all first unexpected original failures remain non-success')
    need(all(type(row['status']) is int and row['status'] == 0 for row in native.values()),
         'every original exact primary coordinate address execution remains typed successful')
    replays = {}
    for role in REPLAYS:
        row = json.loads((BASE / ('replay-' + role + '-actual.json')).read_bytes())
        need(type(row['status']) is int and row['status'] == 0
             and type(row['expected_status']) is int and row['expected_status'] == 0
             and row['command'] == ['scripts/run_with_ram_guard.sh', '--', 'python3', '-B', paths[role]]
             and row['stdout'] == successes[role] and row['stderr'].count('\n') == 1
             and row['programmes'][paths[role]]['body'].encode() == reader_bodies[paths[role]],
             'whole actual original child replay and explicit dated source role')
        replays[role] = row
    return dict(proofs=proofs, native=native, failures=failed, replays=replays,
        fixed_members={name: pin(body) for name, body in {**bodies, **reader_bodies, **actual_bodies, **failure_bodies}.items()})


def boundary(inputs):
    return dict(prerequisite=inputs['proofs']['preparation']['unknowns'],
        association=inputs['proofs']['association']['association']['boundary'],
        raw=inputs['proofs']['raw']['unknowns'],
        condition=PLAN['condition'],
        assumptions='All qualified original finite source products are shared assumptions; no original producer/native/private recapture is inferred. Earlier pending progress labels remain dated checkpoint conditions; only the separately qualified finite cause/canonical owners close.')


def expected():
    inputs = original_inputs()
    return dict(schema_version=1, owner=PLAN['owner'], revision=PLAN['revision'],
        source=json.loads((BASE / 'source-roles.json').read_bytes()), contracts=requirements.contracts(),
        inputs=inputs, current=load_product('current-before.json.gz'),
        canonical=load_product('canonical-before.json.gz'), boundary=boundary(inputs))
