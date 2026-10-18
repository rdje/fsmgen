"""Exercise real physical controls and original guards without semantic delegation."""
import argparse
import ast
import gzip
import hashlib
import json
import os
from pathlib import Path
import sys
import tempfile

import epoch_constraints as constraints
import execute
import prepare
import selected_checkout as checkout


def need(value, message):
    if not value:
        raise ValueError(message)


def entry(body, mode='100644'):
    return dict(mode=mode, bytes=len(body),
                oid=hashlib.sha1(b'blob ' + str(len(body)).encode() + b'\0' + body).hexdigest())


def refused(label, function, outcomes):
    try:
        function()
    except (AssertionError, KeyError, ValueError, FileNotFoundError) as error:
        outcomes[label] = dict(type=type(error).__name__, cause=str(error))
        return
    raise AssertionError('invalid physical source admitted: ' + label)


def physical_controls():
    outcomes = {}
    with tempfile.TemporaryDirectory(prefix='selected-checkout-controls-', dir=execute.ROOT / '.artifacts/tmp') as folder:
        root = Path(folder)
        (root / 'nested').mkdir()
        (root / 'source.py').write_bytes(b'pass\n')
        (root / 'nested/item').write_bytes(b'whole input\n')
        (root / 'link').symlink_to('nested/item')
        for name in constraints.RUNTIME:
            (root / name).mkdir()
        expected = {'source.py': entry(b'pass\n'), 'nested/item': entry(b'whole input\n'),
                    'link': entry(b'nested/item', '120000')}
        observe = lambda: checkout.inspect(root, expected, constraints.RUNTIME)
        assert observe()
        (root / 'nested/item').write_bytes(b'other input\n')
        refused('same_size_content', observe, outcomes)
        (root / 'nested/item').write_bytes(b'whole input\n')
        (root / 'source.py').chmod(0o755)
        refused('mode', observe, outcomes)
        (root / 'source.py').chmod(0o644)
        (root / 'link').unlink()
        (root / 'link').symlink_to('../outside')
        refused('outside_link', observe, outcomes)
        (root / 'link').unlink()
        (root / 'link').symlink_to('nested/item')
        (root / 'extra').write_bytes(b'extra')
        refused('extra_member', observe, outcomes)
        (root / 'extra').unlink()
        (root / '.artifacts/tmp/added').write_bytes(b'not an empty output namespace')
        refused('runtime_file', observe, outcomes)
        (root / '.artifacts/tmp/added').unlink()
        (root / '.artifacts/extra').mkdir()
        refused('extra_directory', observe, outcomes)
        (root / '.artifacts/extra').rmdir()
        (root / '.artifacts/tmp').rmdir()
        refused('missing_runtime_directory', observe, outcomes)
        (root / '.artifacts/tmp').mkdir()
        refused('omitted_source_declaration', lambda: checkout.inspect(
            root, {name: row for name, row in expected.items() if name != 'nested/item'}, constraints.RUNTIME), outcomes)
        (root / 'source.py').unlink()
        refused('missing_member', observe, outcomes)
        (root / 'source.py').write_bytes(b'pass\n')
        assert observe()
    return outcomes


def original_guards():
    selected = checkout.selection()
    previous_cwd, previous_path = Path.cwd(), sys.path[:]
    read_bytes, read_text = Path.read_bytes, Path.read_text
    outcome = {}
    try:
        os.chdir(execute.ROOT / checkout.FOLDER)
        for role, filename in (('cause', 'container_common.py'), ('consumer', 'interfaces.py'),
                               ('prerequisites', 'admission_common.py'), ('association', 'association_common.py')):
            base = Path(constraints.BASES[role])
            name = str(base / filename)
            source = Path(name).read_bytes()
            function = next(node for node in ast.parse(source).body
                            if isinstance(node, ast.FunctionDef) and node.name == 'public')
            assert ast.get_source_segment(source.decode(), function) == selected['original_guards'][name]
            plan = json.loads((base / 'plan.json').read_bytes())
            delegated = []

            def fixed(names):
                return constraints.batch(plan['revision'], names)

            namespace = dict(Path=Path, BASE=base, json=json, sys=sys, need=need,
                             fixed=fixed, pin=prepare.identity,
                             exec=lambda code, result: delegated.append(code))
            exec(compile(ast.Module(body=[function], type_ignores=[]), name, 'exec'), namespace)
            namespace['public']()
            assert len(delegated) == 1 and sys.path == previous_path
            outcome[role] = dict(revision=plan['revision'],
                                 delegated_source=prepare.identity(Path(constraints.FACTORY).read_bytes()))

        base = Path(constraints.BASES['cause'])
        name = str(base / 'verify.py')
        source = Path(name).read_bytes()
        function = next(node for node in ast.parse(source).body
                        if isinstance(node, ast.FunctionDef) and node.name == 'repaired_preflight')
        assert ast.get_source_segment(source.decode(), function) == selected['original_guards'][name]
        position = next(i for i, node in enumerate(function.body) if isinstance(node, ast.Assign)
                        and any(isinstance(target, ast.Name) and target.id == 'changed' for target in node.targets))
        first = json.loads((base / 'development-preflight-actual.json').read_bytes())
        namespace = dict(Path=Path, BASE=base, first=first, need=need)
        exec(compile(ast.Module(body=function.body[position:position + 2], type_ignores=[]), name, 'exec'), namespace)
        outcome['runtime_repair'] = sorted(namespace['changed'])
        assert outcome['runtime_repair'] == selected['development_repair']['changed']

        name = constraints.BASES['consumer'] + '/model.py'
        source = Path(name).read_bytes()
        function = next(node for node in ast.parse(source).body
                        if isinstance(node, ast.FunctionDef) and node.name == 'inputs')
        assert ast.get_source_segment(source.decode(), function) == selected['original_guards'][name]
        guard = next(node for node in function.body if isinstance(node, ast.Expr) and isinstance(node.value, ast.Call)
                     and any(isinstance(arg, ast.Constant) and arg.value == 'every unchanged current canonical source byte'
                             for arg in node.value.args))
        canonical = constraints.batch(selected['canonical_revision'], selected['canonical_members'])
        namespace = dict(Path=Path, canonical=canonical, need=need)
        exec(compile(ast.Module(body=[guard], type_ignores=[]), name, 'exec'), namespace)
        outcome['canonical'] = {name: prepare.identity(body) for name, body in canonical.items()}
    finally:
        os.chdir(previous_cwd)
        sys.path[:] = previous_path
    assert Path.read_bytes is read_bytes and Path.read_text is read_text
    return outcome


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--physical-only', action='store_true')
    parser.add_argument('--write', action='store_true')
    args = parser.parse_args()
    value = dict(physical_controls=physical_controls())
    if not args.physical_only:
        value['original_guards'] = original_guards()
    if args.write:
        execute.save(execute.AUDIT / 'selected-checkout-inert-controls.json.gz', value)
    elif not args.physical_only:
        saved = json.loads(gzip.decompress(execute.read(execute.AUDIT / 'selected-checkout-inert-controls.json.gz')))
        assert value == saved
    print('Selected checkout physical controls and requested original inert guards pass; no semantic delegation executes.')
