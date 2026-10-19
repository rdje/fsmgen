"""Inventory source-only compile/exec operands, never reconstruct or execute them.

The unit is a lexical call site in the conservative fixed module population.
Neither a call's spelling nor direct syntactic pairing proves default runtime
reachability, callable identity, input provenance or filesystem effects.
"""
import argparse
import ast
import copy
import gzip
import io
import json
import tokenize

import bounded_runtime_inventory as bounded
import default_dispatch as dispatch
import epoch_constraints as epoch
import execute
import prepare
import qualify_caller_modules as caller

AUTHORITY = '582e65084bbcdf7018ca0180ccfe01f859ce951e'
INPUT = execute.AUDIT / 'caller-modules-qualified.json.gz'
PATH = execute.AUDIT / 'executable-operands-qualified.json.gz'
OWNER = ('SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.4.3.3.5.2.1.5.2.2.3.1.2.1.3.1.2.3.2.3.3.3.3.2.3.2.3.3.2.3.4.3.3.2.2.3.3.2.3.3.2.1.3.2.1.2')
PREMISES = ('operand_inventory.py', 'bounded_runtime_inventory.py', 'default_dispatch.py',
            'epoch_constraints.py', 'execute.py', 'prepare.py', 'selected_checkout.py',
            'qualify_caller_modules.py', 'caller_modules.py', 'fixed_modules.py',
            'runtime_inventory.py', 'qualify_fixed_module_gap.py')
SCOPE = ('Whole lexical compile/exec candidate inventory over the committed conservative '
         'fixed imported/wrapper module graph. Nondefault and uncalled bodies are included. '
         'AST source expressions, enclosing recipes and direct exec/compile pairing are '
         'syntax evidence only. Separate token enumeration checks site allocation/pairing '
         'without using AST traversal; CPython lexical grammar and the fixed source graph '
         'remain shared premises. Source/data/namespace/export bindings and input-only '
         'preparation reconstruction belong to the named successor. No historical source '
         'or recipe executes; no default reachability, full executable allocation, effect '
         'or runtime custody authority follows. Every earlier failure and unused slot retains.')


def token_sites(body):
    """Independent bare-call token census for the reviewed fixed source grammar."""
    text = body.decode('utf-8')
    lines = text.splitlines()
    ignored = {tokenize.ENCODING, tokenize.NL, tokenize.NEWLINE, tokenize.COMMENT,
               tokenize.INDENT, tokenize.DEDENT, tokenize.ENDMARKER}
    tokens = [item for item in tokenize.tokenize(io.BytesIO(body).readline) if item.type not in ignored]
    result = {}
    for index, item in enumerate(tokens):
        if item.type != tokenize.NAME or item.string not in ('exec', 'compile'):
            continue
        if index + 1 >= len(tokens) or tokens[index + 1].string != '(':
            continue
        if index and tokens[index - 1].string in ('.', 'def', 'class'):
            continue
        line, column = item.start
        byte_column = len(lines[line - 1][:column].encode('utf-8'))
        role = ('exec-operand' if item.string == 'compile' and index >= 2
                and [part.string for part in tokens[index - 2:index]] == ['exec', '(']
                else 'compile-only-operand' if item.string == 'compile' else 'exec-call')
        key = (line, byte_column)
        assert key not in result
        result[key] = dict(operation=item.string, syntactic_role=role)
    return result


def ast_sites(body, name):
    text, tree = body.decode('utf-8'), ast.parse(body, filename=name)
    parents, owners = {}, {}

    def visit(node, owner=None):
        if isinstance(node, (ast.FunctionDef, ast.AsyncFunctionDef, ast.Lambda)):
            owner = node
        owners[id(node)] = owner
        for child in ast.iter_child_nodes(node):
            parents[id(child)] = node
            visit(child, owner)

    visit(tree)
    result = []
    for node in ast.walk(tree):
        if not (isinstance(node, ast.Call) and isinstance(node.func, ast.Name)
                and node.func.id in ('exec', 'compile')):
            continue
        operation = node.func.id
        if operation == 'compile':
            assert len(node.args) == 3 and not node.keywords, 'reviewed compile signature'
            assert ast.literal_eval(node.args[2]) == 'exec', 'reviewed compilation mode'
            parent = parents[id(node)]
            paired = (isinstance(parent, ast.Call) and isinstance(parent.func, ast.Name)
                      and parent.func.id == 'exec' and parent.args[0] is node)
            role = 'exec-operand' if paired else 'compile-only-operand'
            expressions = dict(input=dispatch.source(node.args[0], text),
                               logical_name=dispatch.source(node.args[1], text),
                               mode=dispatch.source(node.args[2], text))
            namespace = dispatch.source(parent.args[1], text) if paired else None
        else:
            assert len(node.args) == 2 and not node.keywords, 'reviewed exec signature'
            assert isinstance(node.args[0], ast.Call) and isinstance(node.args[0].func, ast.Name)
            assert node.args[0].func.id == 'compile', 'direct compile operand'
            role, expressions = 'exec-call', dict(compilation=dispatch.source(node.args[0], text))
            namespace = dispatch.source(node.args[1], text)
        owner = owners[id(node)]
        result.append(dict(source=dispatch.source(node, text), operation=operation,
            syntactic_role=role, expressions=expressions, namespace=namespace,
            enclosing_recipe=dispatch.source(owner, text) if owner is not None else None,
            enclosing_name=owner.name if isinstance(owner, (ast.FunctionDef, ast.AsyncFunctionDef))
                           else '<lambda>' if owner else '<module>',
            binding_owner=OWNER + '.2', binding_qualified=False))
    return sorted(result, key=lambda row: (row['source']['line'], row['source']['column']))


def derive():
    raw = execute.read(INPUT)
    assert raw == epoch.read(AUTHORITY, str(INPUT)), 'whole committed fixed module graph'
    graph = json.loads(gzip.decompress(raw))['graph']
    assert graph['revision'] == epoch.REVISION and graph['runtime_permission'] is False
    sources, sites, lexical = {}, {}, {}
    for name, row in graph['sources'].items():
        body = prepare.unblob(row['body'])
        assert body == epoch.read(epoch.REVISION, name), 'whole original fixed source'
        actual = ast_sites(body, name)
        # Tokens independently detect omitted calls and wrong direct pairing.
        tokens = token_sites(body)
        syntax = {(item['source']['line'], item['source']['column']): dict(
            operation=item['operation'], syntactic_role=item['syntactic_role']) for item in actual}
        assert len(syntax) == len(actual)
        bounded.strict_equal(tokens, syntax)
        if not actual:
            continue
        assert len(sites) < 256 and sum(map(len, sites.values())) + len(actual) <= 4096, 'bounded operand population'
        sources[name], sites[name] = row, actual
        lexical[name] = [dict(line=key[0], column=key[1], **value) for key, value in sorted(tokens.items())]
    expected = {(row['caller'], row['source']['line'], row['source']['column'], row['operation'])
                for row in graph['boundaries'] if row['operation'] in ('compile', 'exec')}
    actual = {(name, row['source']['line'], row['source']['column'], row['operation'])
              for name, rows in sites.items() for row in rows}
    assert actual == expected, 'complete fixed-graph compile/exec lexical allocation'
    return dict(schema='fsmgen.executable_operand_inventory.v1', revision=epoch.REVISION,
        fixed_graph=dict(revision=AUTHORITY, path=str(INPUT), **prepare.identity(raw)),
        commands=graph['commands'], source_population=sorted(graph['sources']),
        sources=sources, sites=sites, independent_tokens=lexical,
        reconstruction_owner=OWNER + '.2', qualification_owner=OWNER + '.3',
        scope=SCOPE, bindings_qualified=False, default_reachability_qualified=False,
        runtime_permission=False)


def controls(expected):
    outcomes = []
    source = next(iter(expected['sites']))
    compile_site = next(row for row in expected['sites'][source] if row['operation'] == 'compile')
    for label in ('source', 'omitted_source', 'omitted_site', 'wrong_role', 'wrong_input',
                  'wrong_namespace', 'wrong_recipe', 'wrong_owner', 'typed_binding', 'runtime_permission'):
        bad = copy.deepcopy(expected)
        row = next(item for item in bad['sites'][source] if item['source'] == compile_site['source'])
        if label == 'source': bad['sources'][source]['body'] = prepare.blob(b'changed fixed source')
        elif label == 'omitted_source': del bad['sources'][source]
        elif label == 'omitted_site': bad['sites'][source].remove(row)
        elif label == 'wrong_role': row['syntactic_role'] = 'executed-default-source'
        elif label == 'wrong_input': row['expressions']['input']['text'] = 'other_source'
        elif label == 'wrong_namespace': row['namespace'] = {'text': 'trusted_namespace'}
        elif label == 'wrong_recipe': row['enclosing_recipe'] = None
        elif label == 'wrong_owner': row['binding_owner'] = OWNER
        elif label == 'typed_binding': row['binding_qualified'] = 0
        else: bad['runtime_permission'] = True
        changes = caller.changes(expected, bad)
        assert changes, 'genuine operand intervention'
        try:
            bounded.strict_equal(bad, expected)
        except AssertionError as error:
            outcomes.append(dict(label=label, changes=changes, candidate_identity=bounded.identity(bad),
                                 refusal=str(error), kind='caught full-record assertion; no historical native exit'))
        else:
            raise AssertionError('changed inventory admitted: ' + label)
    return outcomes


def replay(expected, outcomes):
    for outcome in outcomes:
        bad = copy.deepcopy(expected)
        for change in outcome['changes']:
            parent = bad
            for key in change['path'][:-1]:
                parent = parent[key]
            key = change['path'][-1]
            bounded.strict_equal(parent[key], change['before'])
            if change.get('remove') is True:
                del parent[key]
            else:
                parent[key] = change['after']
        bounded.strict_equal(bounded.identity(bad), outcome['candidate_identity'])
        try:
            bounded.strict_equal(bad, expected)
        except AssertionError as error:
            assert str(error) == outcome['refusal']
        else:
            raise AssertionError('saved intervention admitted')


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--write', action='store_true')
    args = parser.parse_args()
    result = derive()
    outcomes = controls(result)
    replay(result, outcomes)
    product = dict(result=result, controls=outcomes,
        programmes={name: prepare.blob(execute.read(execute.AUDIT / name)) for name in PREMISES})
    if args.write:
        execute.save(PATH, product)
    else:
        bounded.strict_equal(json.loads(gzip.decompress(execute.read(PATH))), product)
    print('Complete compile/exec syntax operands, token allocation and saved rejection candidates agree; source/data bindings and runtime remain unqualified.')
