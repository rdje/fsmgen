"""Review fixed default dispatch and direct dynamic edges without executing readers.

This is a deliberately partial control-flow proof. Function bodies, imported
module initialization, dynamic expansions and filesystem effects require the
separate transitive-effects qualification. No historical module is imported.
"""
import argparse
import ast
import copy
import gzip
import json
from pathlib import Path

import bounded_runtime_inventory as bounded
import epoch_constraints as epoch
import execute
import prepare
import runtime_inventory as inventory
import saved_reader_sources as reader_sources

AUTHORITY = 'b919b7f8ec74627ecb83fb80cb9d8b2f74c7f45d'
PATH = execute.AUDIT / 'default-dispatch-qualified.json.gz'
SELF = 'default_dispatch.py'
PREMISES = ('runtime_inventory.py', 'bounded_runtime_inventory.py', 'epoch_constraints.py',
            'execute.py', 'prepare.py', 'selected_checkout.py')
BASES = {key: epoch.BASES[key] for key in ('prerequisites', 'association')}
SCOPE = ('Exact selected-epoch default entry dispatch and direct fixed dynamic-source edges only. '
         'No historical module, saved semantic cohort, original producer or new source fixture runs. '
         'Imported initialization, transitive dynamic expansion, called function effects, cache '
         'custody and future progress remain unqualified. Original native0/after-gap, every '
         'failed/spent fixture, unused slot and wider native/private/resource gate retain.')


def source(node, text):
    value = ast.get_source_segment(text, node)
    assert value is not None
    return dict(line=node.lineno, column=node.col_offset, end_line=node.end_lineno,
                end_column=node.end_col_offset, text=value)


def boolean(node, flags):
    """Interpret only the reviewed argparse boolean grammar, never Python code."""
    if isinstance(node, ast.Attribute) and isinstance(node.value, ast.Name):
        assert node.value.id == 'args' and node.attr in flags, 'closed dispatch flag'
        return flags[node.attr]
    if isinstance(node, ast.UnaryOp) and isinstance(node.op, ast.Not):
        return not boolean(node.operand, flags)
    if isinstance(node, ast.BoolOp):
        values = [boolean(item, flags) for item in node.values]
        assert isinstance(node.op, (ast.Or, ast.And)), 'closed boolean operator'
        return any(values) if isinstance(node.op, ast.Or) else all(values)
    raise AssertionError('unresolved dispatch predicate')


def dispatch(body):
    text = body.decode('utf-8')
    tree = ast.parse(body)
    main = [node for node in tree.body if isinstance(node, ast.If)
            and ast.dump(node.test) == ast.dump(ast.parse("__name__ == '__main__'", mode='eval').body)]
    assert len(main) == 1 and main[0] is tree.body[-1], 'unique terminal main guard'
    flags = {}
    for node in main[0].body:
        if not (isinstance(node, ast.Expr) and isinstance(node.value, ast.Call)
                and inventory.spelling(node.value.func) == 'parser.add_argument'):
            continue
        call = node.value
        assert len(call.args) == 1 and len(call.keywords) == 1
        option = ast.literal_eval(call.args[0])
        assert type(option) is str and option.startswith('--')
        assert call.keywords[0].arg == 'action' and ast.literal_eval(call.keywords[0].value) == 'store_true'
        assert option[2:] not in flags
        flags[option[2:]] = False
    assert set(flags) == {'preflight', 'core', 'seal', 'current'}, 'reviewed no-argument interface'
    selected, predicates, excluded = [], [], []

    def walk(nodes):
        for node in nodes:
            if isinstance(node, ast.If):
                value = boolean(node.test, flags)
                predicates.append(dict(source(node.test, text), value=value))
                excluded.extend(source(item, text) for item in (node.orelse if value else node.body))
                walk(node.body if value else node.orelse)
            else:
                assert isinstance(node, (ast.Assign, ast.Expr)), 'closed dispatch statement kind'
                value = node.value
                assert isinstance(value, ast.Call), 'reviewed call-valued dispatch statements'
                operation = inventory.spelling(value.func)
                arguments = [boolean(arg, flags) for arg in value.args] if operation in ('core', 'delivery') else None
                selected.append(dict(source(node, text), operation=operation, boolean_arguments=arguments))

    walk(main[0].body)
    # Separately reviewed source-level oracle: these default commands enter both
    # complete phases with current=False and consume saved proof/manifest data.
    # It deliberately makes no claim about effects below these call boundaries.
    assert [row['operation'] for row in selected] == [
        'argparse.ArgumentParser', *(['parser.add_argument'] * 4), 'parser.parse_args',
        'need', 'core', 'delivery', 'need', 'need', 'print'], 'reviewed complete default dispatch'
    assert [row['boolean_arguments'] for row in selected if row['operation'] in ('core', 'delivery')] == [[False], [False]]
    assert [(row['text'], row['value']) for row in predicates] == [
        ('args.preflight', False), ('args.core', False), ('args.seal', False)]
    assert [row['operation'] for row in selected].count('save') == 0
    return dict(main=source(main[0], text), flags=flags, selected=selected,
                predicates=predicates, excluded=excluded,
                boundary='Calls and branch selection only; downstream effects are unresolved.')


def function(body, name):
    text = body.decode('utf-8')
    found = [node for node in ast.parse(body).body if isinstance(node, ast.FunctionDef) and node.name == name]
    assert len(found) == 1
    return source(found[0], text)


def fixed_sources():
    plans = {role: epoch.decoded(epoch.REVISION, base + '/plan.json') for role, base in BASES.items()}
    declarations = epoch.decoded(epoch.REVISION, BASES['prerequisites'] + '/reader-contracts.json')
    assert set(declarations) == {'context', 'cause', 'consumer'}
    names = {base + '/' + name for base in BASES.values() for name in ('verify.py', 'plan.json')}
    names.update((BASES['prerequisites'] + '/reader-contracts.json',
                  BASES['prerequisites'] + '/admission_common.py',
                  BASES['association'] + '/association_common.py',
                  BASES['association'] + '/association_inputs.py', epoch.FACTORY))
    for role, row in declarations.items():
        entry = plans['prerequisites'][role] + '/verify.py'
        assert row['command'] == ['python3', '-B', entry]
        names.add(entry)
    assert plans['association']['admission'] == BASES['prerequisites']
    bodies = epoch.batch(epoch.REVISION, names)
    return plans, declarations, bodies


def build():
    plans, declarations, bodies = fixed_sources()
    tree, members = epoch.tree(epoch.REVISION)
    entries = {role: base + '/verify.py' for role, base in BASES.items()}
    dispatches = {role: dispatch(bodies[name]) for role, name in entries.items()}
    edges = []
    reader_source = function(bodies[entries['prerequisites']], 'reader')
    assert "scope = {'__name__': '__main__', '__file__': entry}" in reader_source['text']
    assert "sys.argv[:] = [entry]" in reader_source['text']
    assert "exec(compile(bodies[entry], entry, 'exec'), scope)" in reader_source['text']
    for role, row in sorted(declarations.items()):
        target = row['command'][-1]
        assert bodies[target] == epoch.read(plans['prerequisites']['revision'], target)
        edges.append(dict(caller=entries['prerequisites'], function='reader', role=role,
                          target=target, fixed_revision=plans['prerequisites']['revision'],
                          module_name='__main__', argv=[target], source=reader_source,
                          declaration=row, downstream_effects_qualified=False))
    admission_source = function(bodies[entries['association']], 'fresh_admission')
    assert "namespace = {'__name__': '__main__', '__file__': entry}" in admission_source['text']
    assert "sys.argv[:] = [entry]" in admission_source['text']
    assert "exec(compile(sources[entry], entry, 'exec'), namespace)" in admission_source['text']
    target = entries['prerequisites']
    assert bodies[target] == epoch.read(plans['association']['revision'], target)
    edges.append(dict(caller=entries['association'], function='fresh_admission', role='admission',
                      target=target, fixed_revision=plans['association']['revision'], module_name='__main__',
                      argv=[target], source=admission_source, downstream_effects_qualified=False))
    for role, filename, module_name in (
        ('prerequisites', 'admission_common.py', 'fixed_join_admission_current_factory'),
        ('association', 'association_common.py', 'fixed_original_association_current_factory')):
        name = BASES[role] + '/' + filename
        site = function(bodies[name], 'public')
        assert "exec(compile(body, name, 'exec'), result)" in site['text']
        assert f"'__name__': '{module_name}'" in site['text']
        assert bodies[epoch.FACTORY] == epoch.read(plans[role]['revision'], epoch.FACTORY)
        edges.append(dict(caller=name, function='public', role='factory', target=epoch.FACTORY,
                          fixed_revision=plans[role]['revision'], module_name=module_name,
                          argv=None, source=site, downstream_effects_qualified=False))
    # Consume the existing complete candidate census once, without copying or
    # repeatedly serializing it. Its committed producer/source premise is explicit.
    inventory_path = execute.AUDIT / 'runtime-source-inventory-bounded.json.gz'
    raw = execute.read(inventory_path)
    assert raw == epoch.read(AUTHORITY, str(inventory_path)), 'committed complete inventory input'
    inventory_identity = prepare.identity(raw)
    del raw
    with gzip.open(execute.safe(inventory_path), 'rt', encoding='utf-8') as stream:
        whole = json.load(stream)
    assert whole['revision'] == epoch.REVISION and whole['reachability_qualified'] is False
    sources = {}
    for name, body in sorted(bodies.items()):
        assert members[name]['mode'] in ('100644', '100755')
        entry = dict(mode=members[name]['mode'], oid=members[name]['oid'], body=prepare.blob(body))
        if name.endswith('.py'):
            original = whole['records'][name]
            sites = inventory.python_sites(body, name)
            assert prepare.unblob(original['source']) == body and original['mode'] == entry['mode']
            assert bounded.strict_equal(sites, original['sites'])
            entry['lexical_sites'] = sites
        sources[name] = entry
    del whole
    commands = {role: ['python3', '-B', name] for role, name in entries.items()}
    for role, command in commands.items():
        assert command == prepare.cohorts(prepare.premises()[0])[role]['command']
    return dict(schema='fsmgen.default_dispatch_source_edges.v1', revision=epoch.REVISION,
                commands=commands, sources=sources, dispatches=dispatches, edges=edges,
                inventory=dict(revision=AUTHORITY, path=str(inventory_path), **inventory_identity),
                runtime_permission=False, transitive_effects_qualified=False, scope=SCOPE)


def controls(value):
    outcomes = []
    for role in BASES:
        name = value['commands'][role][-1]
        original = prepare.unblob(value['sources'][name]['body'])
        bad = original.replace(b'if args.seal:', b'if not args.seal:', 1)
        assert bad != original
        try:
            dispatch(bad)
        except AssertionError as error:
            outcomes.append(dict(label=role + '_default_write_branch', source=prepare.blob(bad),
                                 refusal=str(error), kind='caught static-library assertion; no native reader runs'))
        else:
            raise AssertionError('changed default publication branch admitted')
    member = next(iter(value['sources']))
    for label in ('omitted_source', 'source', 'command', 'edge', 'module_role', 'predicate', 'kind', 'permission', 'scope'):
        bad = copy.deepcopy(value)
        if label == 'omitted_source': del bad['sources'][member]
        elif label == 'source': bad['sources'][member]['body'] = prepare.blob(b'changed input')
        elif label == 'command': bad['commands']['association'].append('--core')
        elif label == 'edge': bad['edges'].pop()
        elif label == 'module_role': bad['edges'][0]['module_name'] = 'input_only'
        elif label == 'predicate': bad['dispatches']['association']['predicates'][0]['value'] = True
        elif label == 'kind': bad['dispatches']['association']['predicates'][0]['value'] = 0
        elif label == 'permission': bad['runtime_permission'] = True
        else: bad['scope'] = 'complete runtime custody'
        try:
            bounded.strict_equal(bad, value)
        except AssertionError as error:
            outcomes.append(dict(label=label, candidate=bad, refusal=str(error),
                                 kind='caught strict-record assertion; no native reader runs'))
        else:
            raise AssertionError('changed source-edge record admitted: ' + label)
    return outcomes


def source_metadata(*, current=False):
    return dict(programme=prepare.blob(reader_sources.body(SELF, current=current)),
                premises={name: prepare.blob(reader_sources.body(name, current=current))
                          for name in PREMISES})


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--write', action='store_true')
    parser.add_argument('--current', action='store_true',
                        help='compare current reader and premise metadata instead of its saved epoch')
    args = parser.parse_args()
    expected = build()
    outcomes = controls(expected)
    product = dict(result=expected, controls=outcomes,
                   **source_metadata(current=args.current or args.write))
    if args.write:
        execute.save(PATH, product)
    else:
        saved = json.loads(gzip.decompress(execute.read(PATH)))
        assert bounded.strict_equal(saved, product)
    print('Fixed default dispatch and direct dynamic-source edges pass; transitive effects and runtime custody remain unqualified.')


if __name__ == '__main__':
    if not __debug__:
        raise SystemExit('Acceptance assertions must be enabled.')
    main()
