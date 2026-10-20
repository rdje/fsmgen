"""Reconstruct a stopped source-only candidate expansion, never qualify closure."""
import argparse
import ast
import copy
import gzip
import json

import bounded_runtime_inventory as bounded
import default_dispatch as dispatch
import epoch_constraints as epoch
import execute
import fixed_modules
import prepare
import runtime_inventory as inventory
import saved_reader_sources as reader_sources

PATH = execute.AUDIT / 'fixed-module-gap-qualified.json.gz'
SELF = 'qualify_fixed_module_gap.py'
STOP = 'docs/audits/record-value-class-frame-retention-20261006/recoveries.py'
CALLER = 'docs/audits/record-value-class-frame-retention-20261006/verify.py'
PREMISES = ('qualify_fixed_module_gap.py', 'fixed_modules.py', 'default_dispatch.py',
            'bounded_runtime_inventory.py', 'runtime_inventory.py', 'epoch_constraints.py',
            'execute.py', 'prepare.py', 'selected_checkout.py',
            'fixed-modules-first.py.source', 'fixed-modules-third.py.source')
SCOPE = ('Deterministic stopped conservative source-candidate expansion only. Imports and '
         'calls in nondefault and uncalled bodies are included. This neither proves nor '
         'disproves default reachability of the stopped recovery. Caller-supplied namespace '
         'and finite preparation-loop bindings remain unresolved. No historical code, '
         'saved preparation producer, original semantic cohort or new source image runs. '
         'Complete source closure, executable data, effects and runtime custody remain open.')


def derive():
    graph = fixed_modules.Graph()
    try:
        graph.build()
    except AssertionError as error:
        assert str(error) == 'source-defined module wrapper: ' + STOP, 'exact stopped analyzer locus'
        refusal = str(error)
    else:
        raise AssertionError('the saved unresolved boundary changed; review its meaning')
    assert STOP in graph.environments and CALLER in graph.environments
    stop_body, caller_body = graph.bodies[STOP], graph.bodies[CALLER]
    # This separate source review does not reuse Graph's wrapper classifier.
    # The parser is a shared premise, explicitly not an independent Python
    # semantics oracle. It establishes the precise missing data-flow contract.
    function = next(node for node in ast.parse(stop_body).body
                    if isinstance(node, ast.FunctionDef) and node.name == 'check')
    assert [arg.arg for arg in function.args.args] == ['ns']
    bindings = [node for node in ast.walk(function) if isinstance(node, ast.Assign)
                and isinstance(node.value, ast.GeneratorExp)
                and isinstance(node.value.elt, ast.Subscript)
                and isinstance(node.value.elt.value, ast.Name) and node.value.elt.value.id == 'ns']
    assert len(bindings) == 1
    assert isinstance(bindings[0].targets[0], ast.Tuple)
    assert [node.id for node in bindings[0].targets[0].elts] == ['require', 'same', 'identity', 'load', 'module']
    assert ast.literal_eval(bindings[0].value.generators[0].iter) == ('require', 'same', 'identity', 'load', 'module')
    loops = [node for node in function.body if isinstance(node, ast.For)]
    assert len(loops) == 1 and isinstance(loops[0].iter, ast.Tuple) and len(loops[0].iter.elts) == 3
    calls = [node for node in ast.walk(function) if isinstance(node, ast.Call)
             and isinstance(node.func, ast.Name) and node.func.id == 'module']
    assert len(calls) == 1 and len(calls[0].args) == 1
    assert isinstance(calls[0].args[0], ast.Name) and calls[0].args[0].id == 'programme'
    caller_calls = [node for node in ast.walk(ast.parse(caller_body)) if isinstance(node, ast.Call)
                    and isinstance(node.func, ast.Subscript)
                    and isinstance(node.func.slice, ast.Constant) and node.func.slice.value == 'check'
                    and isinstance(node.func.value, ast.Call)
                    and inventory.spelling(node.func.value.func) == 'module']
    assert len(caller_calls) == 1
    caller_call = caller_calls[0]
    assert ast.unparse(caller_call.func.value.args[0]) == "BASE / 'recoveries.py'"
    assert len(caller_call.args) == 1 and ast.unparse(caller_call.args[0]) == 'globals()'
    sources = {}
    for name, body in sorted(graph.bodies.items()):
        row = graph.members[name]
        assert body == epoch.read(epoch.REVISION, name), 'whole fixed reached-source bytes'
        sources[name] = dict(mode=row['mode'], oid=row['oid'], body=prepare.blob(body),
                             role='Python candidate source' if name in graph.environments else 'fixed JSON declaration',
                             sites=inventory.python_sites(body, name) if name in graph.environments else None)
    return dict(schema='fsmgen.stopped_fixed_module_candidate_graph.v1', revision=epoch.REVISION,
                sources=sources,
                partial_imports=[dict(caller=key[0], **row) for key, row in sorted(graph.imports.items())],
                partial_wrappers=[dict(caller=key[0], **row) for key, row in sorted(graph.routes.items())],
                partial_boundaries=[dict(caller=key[0], **row) for key, row in sorted(graph.boundaries.items())],
                stop=dict(kind='caught analyzer assertion; no native historical reader result', refusal=refusal,
                          source=STOP, function=dispatch.source(function, stop_body.decode()),
                          binding=dispatch.source(bindings[0], stop_body.decode()),
                          finite_loop=dispatch.source(loops[0], stop_body.decode()),
                          call=dispatch.source(calls[0], stop_body.decode()),
                          caller_source=CALLER, caller=dispatch.source(caller_call, caller_body.decode())),
                closed=False, default_reachability_qualified=False, runtime_permission=False,
                scope=SCOPE)


def controls(expected):
    result = []
    member = next(iter(expected['sources']))
    for label in ('source', 'member', 'role', 'namespace', 'caller', 'kind', 'closure', 'permission'):
        bad = copy.deepcopy(expected)
        if label == 'source': bad['sources'][member]['body'] = prepare.blob(b'changed fixed input')
        elif label == 'member': del bad['sources'][member]
        elif label == 'role': bad['sources'][member]['role'] = 'executed default module'
        elif label == 'namespace': bad['stop']['binding']['text'] = 'module = trusted_global_loader'
        elif label == 'caller': bad['stop']['caller']['text'] = "other['check']({})"
        elif label == 'kind': bad['closed'] = 0
        elif label == 'closure': bad['closed'] = True
        else: bad['runtime_permission'] = True
        try:
            bounded.strict_equal(bad, expected)
        except AssertionError as error:
            result.append(dict(label=label, candidate=bad, refusal=str(error),
                               kind='caught strict-record assertion; no native historical result'))
        else:
            raise AssertionError('changed diagnostic admitted: ' + label)
    return result


def source_metadata(*, current=False):
    return {name: prepare.blob(reader_sources.body(name, current=current))
            for name in PREMISES}


def product(*, current=False):
    value = derive()
    return dict(result=value, controls=controls(value), programmes=source_metadata(current=current))


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--write', action='store_true')
    parser.add_argument('--current', action='store_true',
                        help='compare current premise metadata instead of its saved epoch')
    args = parser.parse_args()
    value = product(current=args.current or args.write)
    if args.write:
        execute.save(PATH, value)
    else:
        saved = json.loads(gzip.decompress(execute.read(PATH)))
        bounded.strict_equal(saved, value)
    print('Stopped fixed-module candidate diagnostic reconstructs exactly; source closure and default effects remain unqualified.')


if __name__ == '__main__':
    if not __debug__:
        raise SystemExit('Acceptance assertions must be enabled.')
    main()
