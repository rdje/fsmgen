"""Resolve fixed module candidates using source namespaces and finite loops.

Only syntax and fixed Git objects are consumed. No historical function, import,
preparation program or embedded executable data is evaluated. This instrument
extends, rather than edits, the sealed stopped-diagnostic instrument.
"""
import argparse
import ast
import json
import sys

import default_dispatch as dispatch
import fixed_modules as prior
import runtime_inventory as inventory

MAX_BINDINGS = 4096


class Graph(prior.Graph):
    def __init__(self):
        super().__init__()
        self.contexts = {}
        self.namespace_calls = {}

    def exports(self):
        namespaces = {id(env): name for name, env in self.environments.items()}

        def project(value):
            if id(value) in namespaces:
                return dict(namespace=namespaces[id(value)])
            if isinstance(value, tuple) and value and value[0] == 'declared':
                return dict(declaration=list(value[1:]))
            if type(value) is dict:
                return {key: project(item) for key, item in value.items()}
            if isinstance(value, (list, tuple)):
                return [project(item) for item in value]
            assert type(value) in (str, int, bool, float, type(None)), 'closed source value'
            return value

        return {name: {key: project(value) for key, value in sorted(env.items())}
                for name, env in sorted(self.environments.items())}

    def value(self, node, env, caller):
        if isinstance(node, ast.Call) and not node.keywords:
            if inventory.spelling(node.func) == 'globals' and not node.args:
                return self.environments[caller]
            if inventory.spelling(node.func) == 'module':
                target, _ = self.wrapper_call(node, env, caller)
                return self.module(target)
        return super().value(node, env, caller)

    def wrapper_call(self, call, env, caller):
        binding = env.get('module')
        if not (isinstance(binding, tuple) and binding[0] == 'declared'):
            raise prior.Unknown('module callable needs a source namespace')
        return super().wrapper_call(call, env, caller)

    def namespace_call(self, node, env, caller):
        """Bind only a declared function explicitly passed globals()."""
        if not (isinstance(node.func, ast.Subscript) and len(node.args) == 1
                and not node.keywords and isinstance(node.args[0], ast.Call)
                and inventory.spelling(node.args[0].func) == 'globals'
                and not node.args[0].args and not node.args[0].keywords):
            return
        try:
            function = self.value(node.func, env, caller)
        except (prior.Unknown, KeyError, TypeError, IndexError):
            return
        assert isinstance(function, tuple) and function[0] == 'declared', 'declared namespace callee'
        _, target, name = function
        definitions = [item for item in ast.parse(self.bodies[target]).body
                       if isinstance(item, ast.FunctionDef) and item.name == name]
        assert len(definitions) == 1
        args = definitions[0].args
        assert len(args.args) == 1 and not (args.posonlyargs or args.kwonlyargs
               or args.vararg or args.kwarg or args.defaults), 'closed namespace parameter'
        key = (caller, node.lineno, node.col_offset)
        assert len(self.namespace_calls) < MAX_BINDINGS, 'bounded namespace callers'
        self.contexts.setdefault((target, name), {})[key] = {
            args.args[0].arg: self.environments[caller]}
        self.namespace_calls[key] = dict(caller=caller, target=target, function=name,
            parameter=args.args[0].arg, source=dispatch.source(node, self.bodies[caller].decode()),
            namespace_source=caller, module_binding=list(self.environments[caller]['module']))

    def scan(self, name, tree, env):
        text = self.bodies[name].decode()
        owners, loops = {}, {}

        def visit(node, owner=None, enclosing=()):
            if isinstance(node, (ast.FunctionDef, ast.AsyncFunctionDef)):
                owner, enclosing = node, ()
            owners[id(node)], loops[id(node)] = owner, enclosing
            if isinstance(node, (ast.GeneratorExp, ast.ListComp, ast.SetComp, ast.DictComp)):
                scope = enclosing
                for generator in node.generators:
                    if generator.ifs or generator.is_async:
                        assert not any(isinstance(child, ast.Call) and inventory.spelling(child.func) == 'module'
                                       for child in ast.walk(node)), 'filtered module comprehension requires review'
                    visit(generator.iter, owner, scope)
                    scope += ((node.lineno, generator.target, generator.iter),)
                for child in ([node.key, node.value] if isinstance(node, ast.DictComp) else [node.elt]):
                    visit(child, owner, scope)
                return
            nested = enclosing + ((node.lineno, node.target, node.iter),) if isinstance(node, ast.For) else enclosing
            for child in ast.iter_child_nodes(node):
                visit(child, owner, nested)

        visit(tree)
        for node in ast.walk(tree):
            if not isinstance(node, ast.Call):
                continue
            if not ((isinstance(node.func, ast.Name) and node.func.id in
                    ('module', 'exec', 'compile', 'eval', '__import__'))
                    or (isinstance(node.func, ast.Subscript) and len(node.args) == 1
                        and isinstance(node.args[0], ast.Call)
                        and inventory.spelling(node.args[0].func) == 'globals')):
                continue
            owner = owners[id(node)]
            contexts = self.contexts.get((name, owner.name), {}) if owner else {}
            # A parameterized function is interpreted under each source caller.
            # The unbound candidate remains explicit until a caller is found.
            bindings = list(contexts.items()) or [(None, {})]
            for context, parameters in bindings:
                local = dict(env, **parameters)
                if owner:
                    self.assignments(owner.body, local, name)
                candidates = [(local, [])]
                for line, target_node, iterator in loops[id(node)]:
                    expanded = []
                    for scope, path in candidates:
                        try:
                            values = self.value(iterator, scope, name)
                        except (prior.Unknown, KeyError, TypeError, IndexError):
                            expanded.append((scope, path + [dict(line=line, unresolved=True)]))
                            continue
                        if type(values) is dict:
                            values = list(values)
                        assert isinstance(values, list) and len(values) <= prior.MAX_SOURCES, ('finite source loop', name, line, type(values).__name__)
                        for index, value in enumerate(values):
                            nested = dict(scope)
                            self.assign(target_node, value, nested)
                            expanded.append((nested, path + [dict(line=line, index=index)]))
                            assert len(expanded) <= MAX_BINDINGS, 'bounded loop path product'
                    candidates = expanded
                for local, path in candidates:
                    self.namespace_call(node, local, name)
                    if not isinstance(node.func, ast.Name) or node.func.id not in (
                            'module', 'exec', 'compile', 'eval', '__import__'):
                        continue
                    operation = node.func.id
                    key = (name, node.lineno, node.col_offset, str(context), json.dumps(path, sort_keys=True))
                    site = dict(caller=name, source=dispatch.source(node, text),
                                owner=owner.name if owner else '<module>', operation=operation,
                                namespace_caller=list(context) if context else None, finite_path=path)
                    if operation == 'module':
                        try:
                            target, wrapper = self.wrapper_call(node, local, name)
                        except (prior.Unknown, KeyError, TypeError, IndexError) as error:
                            site['unresolved'] = type(error).__name__ + ': ' + str(error)
                        else:
                            self.module(target)
                            self.routes[key] = dict(site, target=target, **wrapper)
                    elif operation == 'exec':
                        assert len(node.args) == 2 and isinstance(node.args[0], ast.Call)
                        compilation = node.args[0]
                        assert inventory.spelling(compilation.func) == 'compile' and len(compilation.args) == 3
                        assert ast.literal_eval(compilation.args[2]) == 'exec'
                        try:
                            target = self.value(compilation.args[1], local, name)
                        except (prior.Unknown, KeyError, TypeError, IndexError):
                            site['unresolved'] = 'parametric wrapper or executable data; separate allocation'
                        else:
                            if type(target) is str and target in self.members:
                                self.module(target)
                                site['fixed_target'] = target
                            else:
                                site['unresolved'] = 'synthetic executable-data filename; separate allocation'
                    elif operation == 'compile':
                        site['input_role'] = 'exec operand or compile-only input; separate allocation'
                    else:
                        raise AssertionError('unreviewed dynamic boundary: ' + operation)
                    self.boundaries[key] = site
                    assert len(self.boundaries) <= MAX_BINDINGS, 'bounded dynamic bindings'

    def build(self):
        initial = dispatch.build()
        for name in initial['sources']:
            if name.endswith('.py'):
                self.module(name)
        for _ in range(prior.MAX_SOURCES):
            # Rebuild context-specific sites after namespace propagation. Keeping
            # stale unbound entries would misstate the resulting graph.
            before = (set(self.bodies), dict(self.routes), dict(self.boundaries), dict(self.namespace_calls))
            self.routes, self.boundaries = {}, {}
            for name in sorted(self.environments):
                tree = ast.parse(self.bodies[name])
                self.assignments(tree.body, self.environments[name], name)
                self.scan(name, tree, self.environments[name])
            if before == (set(self.bodies), self.routes, self.boundaries, self.namespace_calls):
                break
        else:
            raise AssertionError('source namespace closure did not converge')
        return dict(revision=prior.epoch.REVISION, commands=initial['commands'],
            language=dict(implementation=sys.implementation.name, version=list(sys.version_info),
                          stdlib_module_names=sorted(sys.stdlib_module_names)),
            sources={name: dict(body=prior.prepare.blob(body), mode=self.members[name]['mode'],
                               oid=self.members[name]['oid'], sites=inventory.python_sites(body, name))
                     for name, body in sorted(self.bodies.items()) if name in self.environments},
            declarations={name: prior.prepare.blob(body) for name, body in sorted(self.bodies.items())
                          if name not in self.environments},
            exports=self.exports(),
            imports=[dict(caller=key[0], **row) for key, row in sorted(self.imports.items())],
            wrappers=[row for key, row in sorted(self.routes.items())],
            boundaries=[row for key, row in sorted(self.boundaries.items())],
            namespace_calls=[row for key, row in sorted(self.namespace_calls.items())],
            default_reachability_qualified=False, effects_qualified=False, runtime_permission=False)


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.parse_args()
    result = Graph().build()
    print('sources', len(result['sources']))
    for row in result['boundaries']:
        if row.get('unresolved'):
            print(row['caller'], row['source']['line'], row['owner'], row['operation'], row['unresolved'])
