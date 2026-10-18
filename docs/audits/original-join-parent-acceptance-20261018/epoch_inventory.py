"""Read-only inventory of historical factory guards and their project import closure."""
import argparse
import ast
import copy
import gzip
import json
from pathlib import Path

import execute
import prepare

AUDIT = execute.AUDIT
BASES = {
    'cause': ('primary-raw-cause-container-acceptance-20261012', 'container_common.py'),
    'consumer': ('original-consumer-parent-acceptance-20261012', 'interfaces.py'),
    'prerequisites': ('original-context-cause-consumer-prerequisites-20261012', 'admission_common.py'),
    'association': ('original-context-cause-consumer-association-20261012', 'association_common.py')}
FACTORY = 'scripts/check_record_value_publication.py'


def fixed(revision, name):
    return execute.command(['git', '--no-replace-objects', 'show', revision + ':' + name])


def closure(revision):
    listing = execute.command(['git', '--no-replace-objects', 'ls-tree', '-r', '--name-only', revision, '--', 'scripts']).decode().splitlines()
    available = {Path(name).stem: name for name in listing
                 if Path(name).parent == Path('scripts') and name.endswith('.py') and Path(name).stem.isidentifier()}
    pending, bodies, edges = [FACTORY], {}, {}
    while pending:
        name = pending.pop()
        if name in bodies:
            continue
        body = fixed(revision, name)
        dependencies = set()
        for node in ast.walk(ast.parse(body, filename=name)):
            imports = [item.name for item in node.names] if isinstance(node, ast.Import) else (
                [node.module] if isinstance(node, ast.ImportFrom) and node.level == 0 and node.module else [])
            dependencies.update(available[item.split('.')[0]] for item in imports if item.split('.')[0] in available)
        bodies[name], edges[name] = body, sorted(dependencies)
        pending.extend(dependencies)
    return dict(available_modules=dict(sorted(available.items())), edges=dict(sorted(edges.items())),
                modules={name: prepare.blob(body) for name, body in sorted(bodies.items())})


def derive():
    current_revision = execute.command(['git', '--no-replace-objects', 'rev-parse', 'HEAD']).decode().strip()
    current = execute.read(FACTORY)
    roles = {}
    factories = set()
    for role, (folder, source_file) in BASES.items():
        base = Path('docs/audits') / folder
        plan_body = execute.read(base / 'plan.json')
        plan = json.loads(plan_body)
        integration_body = execute.read(base / 'integration-contract.json')
        retained = json.loads(integration_body)['retained_dependencies']
        old = fixed(plan['revision'], FACTORY)
        assert old != current and len(retained) == 12
        helpers = {name: fixed(plan['revision'], name) for name in retained}
        assert all(prepare.identity(body) == retained[name] and execute.read(name) == body for name, body in helpers.items())
        source = execute.read(base / source_file)
        tree = ast.parse(source)
        function = next(node for node in tree.body if isinstance(node, ast.FunctionDef) and node.name == 'public')
        guard = ast.get_source_segment(source.decode(), function)
        assert 'Path(name).read_bytes() == body' in guard and "name = 'scripts/check_record_value_publication.py'" in guard
        factories.add(prepare.identity(old)['sha256'])
        roles[role] = dict(root=str(base), revision=plan['revision'], owner=plan['owner'], condition=plan['condition'],
                           plan=prepare.blob(plan_body), integration=prepare.blob(integration_body),
                           guard_path=str(base / source_file), guard_source=prepare.blob(source), function=guard,
                           factory=prepare.blob(old), helpers={name: prepare.identity(body) for name, body in helpers.items()})
    assert len(factories) == 1, 'all four original factory roles have identical source'
    first = roles['cause']['revision']
    imports = closure(first)
    differences = {name for name, row in imports['modules'].items() if execute.read(name) != prepare.unblob(row)}
    assert differences == {FACTORY}, 'historical project import sources differ only at the known factory'
    assert all(closure(row['revision']) == imports for row in roles.values()), 'complete historical import closure is identical'
    plan, _, original, _ = prepare.premises()
    assert prepare.check_contracts(execute.read(prepare.TASK), original, plan)
    return dict(schema='fsmgen.original_historical_factory_roles.v1', owner=plan['acceptance'] + '.2.2.2.1',
                source_revision=current_revision, current_factory=prepare.blob(current), historical_roles=roles,
                historical_imports=imports, differing_imports=sorted(differences), original_contracts=original,
                proposal=dict(historical_cohorts=['prerequisites', 'association'],
                              current_cohorts=['current', 'focused', 'book', 'native_book', 'source_views'],
                              independently_frozen_cohort='publication',
                              source_view='Read-only exact historical factory bytes in the declared historical role; all project imports are fully bound and otherwise unchanged. Preserve original guards and namespaces. Current publication runs with the actual current factory.',
                              missing_legs=['No replay adapter is implemented or qualified.',
                                            'No complete semantic replay has passed under that historical source view.',
                                            'No corrected fresh intake is admitted.']),
                scope='Source-role inventory and bounded proposal only. Every original Goal/Acceptance, first failure, '
                      'dated/source-model/native/private premise and independent owner retains. No guard is weakened '
                      'and no acceptance cohort or original producer executes.')


def check(candidate, expected):
    candidate, expected = copy.deepcopy(candidate), copy.deepcopy(expected)
    candidate.pop('source_revision')
    expected.pop('source_revision')
    assert candidate == expected, 'whole unchanged historical/current source-role inventory'
    return True


def controls(expected):
    for label in ('role', 'factory', 'import', 'changed_import', 'current_promotion', 'missing_leg', 'contract'):
        candidate = copy.deepcopy(expected)
        if label == 'role':
            del candidate['historical_roles']['consumer']
        elif label == 'factory':
            candidate['historical_roles']['cause']['factory'] = candidate['current_factory']
        elif label == 'import':
            del candidate['historical_imports']['modules'][next(iter(candidate['historical_imports']['modules']))]
        elif label == 'changed_import':
            modules = candidate['historical_imports']['modules']
            name = next(iter(modules))
            modules[name] = prepare.blob(prepare.unblob(modules[name]) + b'\n# changed import\n')
        elif label == 'current_promotion':
            candidate['proposal']['historical_cohorts'].append('current')
        elif label == 'missing_leg':
            candidate['proposal']['missing_legs'].pop()
        else:
            name = next(iter(candidate['original_contracts']))
            candidate['original_contracts'][name] += '\n  Acceptance: `narrowed`\n'
        try:
            check(candidate, expected)
        except AssertionError:
            continue
        raise AssertionError('hostile role inventory admitted: ' + label)


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--write', action='store_true')
    args = parser.parse_args()
    result = derive()
    controls(result)
    path = AUDIT / 'historical-factory-role-inventory.json.gz'
    if args.write:
        execute.save(path, result)
    else:
        saved = json.loads(gzip.decompress(execute.read(path)))
        # HEAD progresses after preparation; all measured source/contract facts must retain.
        assert check(saved, result)
    print('Complete historical factory guards/import/source roles agree; replay implementation and acceptance remain pending.')
