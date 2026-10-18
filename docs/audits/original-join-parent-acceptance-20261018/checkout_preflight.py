"""Real whole-file controls and original guards; no semantic delegation."""
import ast
import copy
import hashlib
import json
import os
from pathlib import Path
import sys
import tempfile

import execute
import historical_checkout as checkout
import historical_factory
import prepare


def refused(function):
    try:
        function()
    except (AssertionError, KeyError, ValueError):
        return
    raise AssertionError('invalid complete checkout admitted')


def entry(body, mode='100644'):
    return dict(mode=mode, bytes=len(body),
                oid=hashlib.sha1(b'blob ' + str(len(body)).encode() + b'\0' + body).hexdigest())


with tempfile.TemporaryDirectory(prefix='historical-checkout-controls-', dir=execute.ROOT / '.artifacts') as folder:
    root = Path(folder)
    (root / 'nested').mkdir()
    (root / 'source.py').write_bytes(b'pass\n')
    (root / 'nested/item').write_bytes(b'whole input\n')
    (root / 'link').symlink_to('nested/item')
    expected = {'source.py': entry(b'pass\n'), 'nested/item': entry(b'whole input\n'),
                'link': entry(b'nested/item', '120000')}
    assert checkout.inspect(root, expected)
    (root / 'nested/item').write_bytes(b'other input\n')
    refused(lambda: checkout.inspect(root, expected))
    (root / 'nested/item').write_bytes(b'whole input\n')
    (root / 'extra').write_bytes(b'new member')
    refused(lambda: checkout.inspect(root, expected))
    (root / 'extra').unlink()
    (root / 'source.py').chmod(0o755)
    refused(lambda: checkout.inspect(root, expected))
    (root / 'source.py').chmod(0o644)
    (root / 'link').unlink()
    (root / 'link').symlink_to('../outside')
    refused(lambda: checkout.inspect(root, expected))
    (root / 'link').unlink()
    (root / 'link').symlink_to('nested/item')
    (root / 'empty').mkdir()
    refused(lambda: checkout.inspect(root, expected))
    (root / 'empty').rmdir()
    bad = copy.deepcopy(expected)
    del bad['nested/item']
    refused(lambda: checkout.inspect(root, bad))
    (root / 'source.py').unlink()
    refused(lambda: checkout.inspect(root, expected))

image = historical_factory.inventory()
primary = Path.cwd()
read_bytes, read_text = Path.read_bytes, Path.read_text
previous_path = sys.path[:]
try:
    os.chdir(execute.ROOT / checkout.FOLDER)
    for role in image['historical_roles'].values():
        source = Path(role['guard_path']).read_bytes()
        assert source == prepare.unblob(role['guard_source'])
        function = next(node for node in ast.parse(source).body
                        if isinstance(node, ast.FunctionDef) and node.name == 'public')
        delegated = []

        def need(condition, message):
            if not condition:
                raise ValueError(message)

        def fixed(names):
            return {name: execute.command(['git', '--no-replace-objects', 'show', role['revision'] + ':' + name])
                    for name in names}

        namespace = dict(Path=Path, BASE=Path(role['root']), json=json, sys=sys, need=need,
                         fixed=fixed, pin=prepare.identity, exec=lambda code, result: delegated.append(code))
        exec(compile(ast.Module(body=[function], type_ignores=[]), role['guard_path'], 'exec'), namespace)
        namespace['public']()
        assert len(delegated) == 1 and sys.path == previous_path

    base = Path('docs/audits/primary-raw-cause-container-acceptance-20261012')
    source = (base / 'verify.py').read_bytes()
    function = next(node for node in ast.parse(source).body
                    if isinstance(node, ast.FunctionDef) and node.name == 'repaired_preflight')
    position = next(i for i, node in enumerate(function.body) if isinstance(node, ast.Assign)
                    and any(isinstance(target, ast.Name) and target.id == 'changed' for target in node.targets))
    first = json.loads((base / 'development-preflight-actual.json').read_bytes())
    namespace = dict(Path=Path, BASE=base, first=first, need=need)
    exec(compile(ast.Module(body=function.body[position:position + 2], type_ignores=[]), str(base / 'verify.py'), 'exec'), namespace)
    assert namespace['changed'] == {str(base / name) for name in ('verify.py', 'container_publish.py', 'plan.json')}
finally:
    os.chdir(primary)
    sys.path[:] = previous_path
assert Path.read_bytes is read_bytes and Path.read_text is read_text
plan, _, original, _ = prepare.premises()
assert prepare.check_contracts(execute.read(prepare.TASK), original, plan)
print('Whole physical source/member/mode/link/directory controls and every exact historical factory/runtime guard pass; no file-read substitution or semantic reader executes.')
