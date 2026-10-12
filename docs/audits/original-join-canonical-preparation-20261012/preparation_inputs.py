"""Whole committed original meanings, unchanged contracts and finite proposal scope."""
import contextlib
import stat
from preparation_common import *

TARGET = 'docs/knowledge/record-value-finite-copy-probe-reader.md'


def contracts():
    before = nodes(fixed([TASK])[TASK])
    active = nodes(gzip.decompress((BASE / 'activation-task.gz').read_bytes()))
    added = {PLAN[key] for key in ('owner', 'publication', 'acceptance')}
    need(set(active) == set(before) | added and not set(before) & added,
         'exact existing task graph and three declared acceptance children')
    for name, block in before.items():
        if name == PLAN['parent']:
            need(all(field(block, key) == field(active[name], key) for key in ('Goal', 'Acceptance', 'Commit'))
                 and field(block, 'Status') == 'pending' and field(active[name], 'Status') == 'active'
                 and field(active[name], 'Children') == ', '.join(PLAN[key] for key in ('owner', 'publication', 'acceptance')),
                 'whole unchanged original acceptance contract and explicit child split')
        else:
            need(block == active[name], 'every unrelated whole original task block retains')
    need(field(active[PLAN['owner']], 'Status') == 'active'
         and all(field(active[PLAN[key]], 'Status') == 'active' for key in ('family', 'join', 'parent'))
         and all(field(active[PLAN[key]], 'Status') == 'pending' for key in ('publication', 'acceptance', 'full_alias')),
         'only preparation active; production original parents and full alias stay separate')
    return {name: body.decode() for name, body in active.items()
            if name == PLAN['family'] or name.startswith(PLAN['family'] + '.') or name == PLAN['full_alias']}


@contextlib.contextmanager
def association_module(entry):
    """Isolate unchanged archived modules from this preparation's same-named modules."""
    root = PLAN['association']
    names = git('ls-tree', '-r', '--name-only', PLAN['revision'], '--', root).decode().splitlines()
    programmes = fixed(name for name in names if name.endswith('.py'))
    need(all(Path(name).read_bytes() == body for name, body in programmes.items()),
         'whole unchanged committed association programmes')
    modules = {Path(name).stem for name in programmes} | {'capture'}
    previous = {name: sys.modules[name] for name in modules if name in sys.modules}
    old_path, old_argv = sys.path[:], sys.argv[:]
    try:
        for name in modules:
            sys.modules.pop(name, None)
        sys.path.insert(0, root)
        name = root + '/' + entry + '.py'
        sys.argv[:] = [name]
        namespace = {'__name__': 'fixed_preparation_association_' + entry, '__file__': name}
        exec(compile(programmes[name], name, 'exec'), namespace)
        yield namespace
    finally:
        sys.path[:] = old_path
        sys.argv[:] = old_argv
        for name in modules:
            sys.modules.pop(name, None)
        sys.modules.update(previous)


def inputs():
    declaration = json.loads((BASE / 'input-contracts.json').read_bytes())
    need(set(declaration) == {'command', 'condition', 'inputs', 'scope'}
         and declaration['command'] == ['python3', '-B', PLAN['association'] + '/verify.py']
         and declaration['scope'] == PLAN['condition'], 'closed complete committed association input contract')
    root = PLAN['association']
    wanted = {'proof.json', 'manifest.json', 'source-roles.json', 'candidate.json.gz', 'qualification.json',
              'formal-programmes.json', 'development-initial-programmes.json', 'typed-equality-repair.json',
              'capture-typed-repair-expansion.json', 'capture-candidate-input-expansion.json',
              'development-boolean-alias-actual.json', 'development-float-alias-actual.json',
              'development-boolean-alias-v2-actual.json', 'development-float-alias-v2-actual.json',
              'controls.json', 'plan.json', 'input-contracts.json', 'integration-contract.json'}
    need(set(declaration['inputs']) == {root + '/' + name for name in wanted},
         'complete declared proof native controls first failures repair and source roles')
    bodies = fixed(declaration['inputs'])
    decoded = {}
    for name, body in bodies.items():
        info = Path(name).lstat()
        need(stat.S_ISREG(info.st_mode) and info.st_dev == Path.cwd().stat().st_dev
             and Path(name).read_bytes() == body and same(pin(body), declaration['inputs'][name]),
             'whole ordinary same-volume fixed association input')
        raw = gzip.decompress(body) if name.endswith('.gz') else body
        value = json.loads(raw)
        if name.endswith('.gz'):
            need(raw == canonical(value), 'whole canonical compressed association candidate')
        decoded[Path(name).name] = value
    with association_module('reader') as reader:
        qualification = reader['check'](decoded['candidate.json.gz'])
    need(same(qualification, decoded['qualification.json'])
         and same(decoded['proof.json']['qualification'], qualification),
         'complete independently rederived original joined meanings and committed proof')
    with association_module('verify') as verifier:
        failures = verifier['failures']()
    need(same(failures, decoded['proof.json']['failures']), 'whole original first false greens and exact typed repairs retain')
    candidate = decoded['candidate.json.gz']
    return dict(identities=declaration['inputs'], contracts=contracts(),
        association=dict(proof=pin(bodies[root + '/proof.json']),
            candidate=pin(canonical(candidate)), qualification=pin(canonical(qualification)),
            manifest=pin(bodies[root + '/manifest.json']), source_roles=pin(bodies[root + '/source-roles.json']),
            controls=decoded['proof.json']['controls'], failures=failures,
            source_model_assumptions=candidate['source_model_assumptions'],
            original_conditions=candidate['original_conditions'], source_role_condition=candidate['source_role_condition'],
            truth_authority=candidate['truth_authority'], assurance=candidate['assurance'],
            condition=decoded['proof.json']['condition']))


def scope(data):
    return dict(condition=PLAN['condition'], original=data['association'],
        assurance=dict(original_native_private=False, later_historical_execution_currency=False,
            original_producer_recapture=False, production=False, original_parent=False, full_alias=False),
        review='Exact paragraph correspondence and explicit engineering equivalence review, supported by complete independently rederived original source associations. Shared qualified prior causes and typed truths are declared premises; no universal natural-language proof or native passed-flag authority.')


def context():
    sources = canonical_sources()
    need(all(Path(name).read_bytes() == body for name, body in sources.items()),
         'every unchanged current canonical source body')
    factory = public()
    prior = factory['historical']()
    current = factory['current_input'](prior, sources)
    factory['check'](current, sources, prior, factory['authority'](prior))
    registry = list(map(json.loads, fixed([REGISTRY])[REGISTRY].splitlines()))
    authority = next(row for row in registry if row.get('surface_id') == 'knowledge_cards')
    return dict(sources=sources, data=inputs(), factory=factory, prior=prior, current=current, authority=authority)
