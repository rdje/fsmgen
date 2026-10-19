"""Qualify the conservative fixed-module graph; never execute its source."""
import argparse
import ast
import copy
import gzip
import json
import posixpath
import sys

import bounded_runtime_inventory as bounded
import caller_modules
import default_dispatch as dispatch
import epoch_constraints as epoch
import execute
import prepare
import qualify_fixed_module_gap as stopped

PATH = execute.AUDIT / 'caller-modules-qualified.json.gz'
PREMISES = (*stopped.PREMISES, 'caller_modules.py', 'qualify_caller_modules.py')
SCOPE = ('Conservative fixed imported/wrapper-loaded Python source namespaces at the selected '
         'Git epoch, including nondefault and uncalled bodies. Ordinary sibling/scripts '
         'absolute imports, source-declared module wrappers, namespace exports, globals() '
         'parameter binding and unfiltered finite loop/comprehension paths use the declared '
         'source grammar. Python AST and that grammar remain shared premises; standard-library '
         'membership is an external interpreter premise. Embedded executable data, compile-only '
         'inputs, complete executable allocation, default reachability, effects and output '
         'custody remain unqualified. No historical module, preparation producer, original '
         'semantic cohort or new source fixture runs. All earlier failures and unused slots retain.')


def locate(row):
    return row['caller'], row['source']['line'], row['source']['column']


def review(value):
    """Check fixed bytes, independent lexical/import census and graph reachability.

    This traversal does not call Graph's expression evaluator or import resolver.
    The separate finite-loop oracle establishes the formerly missing namespace
    allocation. General expression semantics remain an explicit shared premise.
    """
    assert value['revision'] == epoch.REVISION
    assert all(value[key] is False for key in (
        'default_reachability_qualified', 'effects_qualified', 'runtime_permission'))
    bounded.strict_equal(value['language'], dict(implementation=sys.implementation.name,
        version=list(sys.version_info), stdlib_module_names=sorted(sys.stdlib_module_names)))
    members = epoch.tree(epoch.REVISION)[1]
    names = set(value['sources']) | set(value['declarations'])
    bodies = epoch.batch(epoch.REVISION, names)
    trees = {}
    for name, row in value['sources'].items():
        assert prepare.unblob(row['body']) == bodies[name], 'whole fixed Python source'
        assert row['mode'] == members[name]['mode'] and row['oid'] == members[name]['oid']
        trees[name] = ast.parse(bodies[name], filename=name)
    for name, blob in value['declarations'].items():
        assert prepare.unblob(blob) == bodies[name], 'whole fixed data declaration'
        json.loads(bodies[name])
    imports, dynamic = {}, set()
    for name, tree in trees.items():
        for node in ast.walk(tree):
            if isinstance(node, (ast.Import, ast.ImportFrom)):
                assert not isinstance(node, ast.ImportFrom) or node.level == 0
                modules = [item.name for item in node.names] if isinstance(node, ast.Import) else [node.module]
                targets = []
                for module in modules:
                    choices = [directory + '/' + module.replace('.', '/') + '.py'
                               for directory in (posixpath.dirname(name), 'scripts')]
                    target = next((candidate for candidate in choices if candidate in members), None)
                    assert target or module.split('.')[0] in sys.stdlib_module_names
                    assert target is None or target in trees, 'omitted imported source'
                    targets.append(target)
                imports[(name, node.lineno, node.col_offset)] = dict(
                    caller=name, source=dispatch.source(node, bodies[name].decode()), modules=modules, targets=targets)
            if isinstance(node, ast.Call) and isinstance(node.func, ast.Name) and node.func.id in (
                    'module', 'exec', 'compile', 'eval', '__import__'):
                dynamic.add((name, node.lineno, node.col_offset))
    actual_imports = {locate(row): row for row in value['imports']}
    assert len(actual_imports) == len(value['imports'])
    bounded.strict_equal(actual_imports, imports)
    assert {locate(row) for row in value['boundaries']} == dynamic, 'complete lexical dynamic sites'
    module_sites = {locate(row) for row in value['boundaries'] if row['operation'] == 'module'}
    assert {locate(row) for row in value['wrappers']} == module_sites, 'every fixed module call resolves'
    assert all('unresolved' not in row for row in value['boundaries'] if row['operation'] == 'module')
    assert all(row['target'] in trees and type(row['module_name']) is str
               and type(row['file_field']) is bool and row['loader'] in (
                   'exec dictionary namespace', 'importlib file module') for row in value['wrappers'])
    edges = {(row['caller'], target) for row in value['imports'] for target in row['targets'] if target}
    edges.update((row['caller'], row['target']) for row in value['wrappers'])
    edges.update((row['caller'], row['fixed_target']) for row in value['boundaries'] if row.get('fixed_target'))
    initial = dispatch.fixed_sources()[2]
    reached = {name for name in initial if name.endswith('.py')}
    while True:
        following = reached | {target for caller, target in edges if caller in reached}
        if following == reached:
            break
        reached = following
    assert reached == set(trees), 'complete rooted fixed-source member population'
    assert set(value['exports']) == set(trees), 'complete exported namespace population'
    namespace_calls = {}
    for name, tree in trees.items():
        for node in ast.walk(tree):
            if not (isinstance(node, ast.Call) and isinstance(node.func, ast.Subscript)
                    and len(node.args) == 1 and not node.keywords and isinstance(node.args[0], ast.Call)
                    and ast.unparse(node.args[0]) == 'globals()'):
                continue
            wrapper = node.func.value
            assert isinstance(wrapper, ast.Call) and isinstance(wrapper.func, ast.Name) and wrapper.func.id == 'module'
            routes = [row for row in value['wrappers'] if locate(row) == (name, wrapper.lineno, wrapper.col_offset)]
            assert len(routes) == 1, 'one source namespace at this caller'
            target, function = routes[0]['target'], ast.literal_eval(node.func.slice)
            declaration = next(item for item in trees[target].body
                               if isinstance(item, ast.FunctionDef) and item.name == function)
            assert len(declaration.args.args) == 1
            origin = value['exports'][name]['module']['declaration']
            namespace_calls[(name, node.lineno, node.col_offset)] = dict(
                caller=name, target=target, function=function, parameter=declaration.args.args[0].arg,
                source=dispatch.source(node, bodies[name].decode()), namespace_source=name,
                module_binding=['declared', *origin])
    bounded.strict_equal({locate(row): row for row in value['namespace_calls']}, namespace_calls)
    # Independent exact source oracle for the stopped caller and finite paths.
    caller, target = stopped.CALLER, stopped.STOP
    globals_paths = {}
    for node in trees[caller].body:
        if (isinstance(node, ast.Assign) and isinstance(node.value, ast.Call)
                and isinstance(node.value.func, ast.Name) and node.value.func.id == 'Path'
                and len(node.value.args) == 1 and isinstance(node.value.args[0], ast.Constant)):
            for assigned in node.targets:
                if isinstance(assigned, ast.Name):
                    globals_paths[assigned.id] = ast.literal_eval(node.value.args[0])
    check = next(node for node in trees[target].body if isinstance(node, ast.FunctionDef) and node.name == 'check')
    loop = next(node for node in check.body if isinstance(node, ast.For))
    assert [item.id for item in loop.target.elts] == ['name', 'programme', 'prepared', 'budget']
    expected = []
    for index, item in enumerate(loop.iter.elts):
        expression = item.elts[1]
        assert isinstance(expression, ast.BinOp) and isinstance(expression.op, ast.Div)
        assert isinstance(expression.left, ast.Name) and expression.left.id in ('checks', 'base')
        root = globals_paths[{'checks': 'CHECKS', 'base': 'BASE'}[expression.left.id]]
        expected.append((root + '/' + ast.literal_eval(expression.right), [dict(line=loop.lineno, index=index)]))
    calls = [row for row in value['namespace_calls'] if row['target'] == target]
    assert len(calls) == 1 and calls[0]['caller'] == caller and calls[0]['function'] == 'check'
    assert calls[0]['parameter'] == 'ns' and calls[0]['namespace_source'] == caller
    assert calls[0]['module_binding'] == ['declared', caller, 'module']
    assert calls[0]['source']['text'] == "module(BASE / 'recoveries.py')['check'](globals())"
    binding = value['exports'][caller]['module']
    assert binding == dict(declaration=[caller, 'module']), 'caller callable export'
    routes = [row for row in value['wrappers'] if row['caller'] == target]
    assert [(row['target'], row['finite_path']) for row in routes] == expected, 'independent preparation path allocation'
    assert all(row['namespace_caller'] == [caller, calls[0]['source']['line'], calls[0]['source']['column']]
               and row['module_name'] == 'class_frame_semantic_retention' and row['file_field'] is True for row in routes)
    return dict(imports='independent whole-AST local/stdlib edge census',
                members='independent fixed-byte identity and rooted edge closure',
                caller='independent literal source caller/parameter/export and finite preparation path allocation',
                shared='Python AST, general expression/wrapper grammar and interpreter stdlib membership',
                executable_data_qualified=False)


def controls(expected):
    outcomes = []
    member = stopped.STOP
    for label in ('source', 'omitted_member', 'omitted_import', 'wrong_caller', 'wrong_path',
                  'wrong_namespace', 'missing_export', 'missing_site', 'typed_role', 'permission'):
        bad = copy.deepcopy(expected)
        route = next(row for row in bad['wrappers'] if row['caller'] == member)
        if label == 'source': bad['sources'][member]['body'] = prepare.blob(b'changed fixed source')
        elif label == 'omitted_member': del bad['sources'][member]
        elif label == 'omitted_import': bad['imports'].pop()
        elif label == 'wrong_caller': route['namespace_caller'][0] = member
        elif label == 'wrong_path': route['target'] = member
        elif label == 'wrong_namespace': route['module_name'] = '__main__'
        elif label == 'missing_export': del bad['exports'][stopped.CALLER]['module']
        elif label == 'missing_site': bad['boundaries'].pop()
        elif label == 'typed_role': bad['runtime_permission'] = 0
        else: bad['runtime_permission'] = True
        try:
            review(bad)
        except (AssertionError, KeyError) as error:
            outcomes.append(dict(label=label, candidate_identity=bounded.identity(bad),
                                 changes=changes(expected, bad), refusal=type(error).__name__ + ': ' + str(error),
                                 kind='caught source-review assertion; no native historical execution'))
        else:
            raise AssertionError('changed graph admitted: ' + label)
    return outcomes


def changes(before, after, path=()):
    """Retain exact candidate reconstruction without copying the whole graph."""
    if type(before) is dict and type(after) is dict:
        assert not after.keys() - before.keys(), 'reviewed controls remove or replace existing fields'
        removed = [dict(path=[*path, key], before=before[key], remove=True)
                   for key in sorted(before.keys() - after.keys())]
        return removed + [change for key in sorted(after)
                          for change in changes(before[key], after[key], (*path, key))]
    if type(before) is list and type(after) is list and len(before) == len(after):
        return [change for index, (left, right) in enumerate(zip(before, after))
                for change in changes(left, right, (*path, index))]
    try:
        bounded.strict_equal(before, after)
    except AssertionError:
        return [dict(path=list(path), before=before, after=after)]
    return []


def replay_controls(graph, outcomes):
    for outcome in outcomes:
        candidate = copy.deepcopy(graph)
        assert outcome['changes'], 'genuine changed candidate'
        for change in outcome['changes']:
            parent = candidate
            for part in change['path'][:-1]:
                parent = parent[part]
            key = change['path'][-1]
            bounded.strict_equal(parent[key], change['before'])
            if change.get('remove') is True:
                del parent[key]
            else:
                parent[key] = change['after']
        bounded.strict_equal(bounded.identity(candidate), outcome['candidate_identity'])
        try:
            review(candidate)
        except (AssertionError, KeyError) as error:
            assert type(error).__name__ + ': ' + str(error) == outcome['refusal']
        else:
            raise AssertionError('retained candidate no longer refuses: ' + outcome['label'])


def derive():
    graph = json.loads(prepare.encoded(caller_modules.Graph().build()))
    outcomes = controls(graph)
    replay_controls(graph, outcomes)
    return dict(schema='fsmgen.caller_fixed_module_closure.v1', graph=graph, review=review(graph),
                controls=outcomes, scope=SCOPE,
                programmes={name: prepare.blob(execute.read(execute.AUDIT / name)) for name in PREMISES})


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--write', action='store_true')
    args = parser.parse_args()
    value = derive()
    if args.write:
        execute.save(PATH, value)
    else:
        bounded.strict_equal(json.loads(gzip.decompress(execute.read(PATH))), value)
    print('Fixed caller namespaces, finite module paths and conservative imported/wrapper source closure pass; executable data, default effects and custody remain unqualified.')
