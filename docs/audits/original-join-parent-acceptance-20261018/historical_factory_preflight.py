"""Exercise exact original guards and source-view isolation without a semantic replay."""
import ast
import copy
from pathlib import Path
import sys
from unittest.mock import patch

import execute
import historical_factory as image_api
import prepare


def refused(call, exception=AssertionError, message=None):
    try:
        call()
    except exception as error:
        if message is not None:
            assert str(error) == message
        return
    raise AssertionError('invalid historical source view admitted')


image = image_api.inventory()
old = image_api.check_image(image)
factory_path = execute.ROOT / image_api.FACTORY
original_read = Path.read_bytes
live = original_read(factory_path)
assert live != old


def guard(role, expected_message):
    declaration = image['historical_roles'][role]
    source = prepare.unblob(declaration['guard_source'])
    function = next(node for node in ast.parse(source).body
                    if isinstance(node, ast.FunctionDef) and node.name == 'public')
    revision = declaration['revision']
    names = [*declaration['helpers'], image_api.FACTORY]
    fixed = {name: execute.command(['git', '--no-replace-objects', 'show', revision + ':' + name]) for name in names}
    delegated = []

    def need(condition, message):
        if not condition:
            raise ValueError(message)

    namespace = dict(Path=Path, BASE=Path(declaration['root']), json=execute.json, sys=sys,
                     fixed=lambda requested: {name: fixed[name] for name in requested}, pin=prepare.identity,
                     need=need, exec=lambda code, result: delegated.append(code))
    exec(compile(ast.Module(body=[function], type_ignores=[]), declaration['guard_path'], 'exec'), namespace)
    if expected_message is None:
        namespace['public']()
        assert len(delegated) == 1
    else:
        refused(namespace['public'], ValueError, expected_message)
        assert not delegated


for role in image['historical_roles']:
    message = 'whole unchanged maintained canonical factory' if role == 'consumer' else 'whole unchanged current canonical factory'
    guard(role, message)
    with image_api.source_view('prerequisites') as proof:
        assert factory_path.read_bytes() == old
        assert Path(image_api.FACTORY).read_bytes() == old
        guard(role, None)
        assert proof['reads'] and all(row['source'] == prepare.identity(old) for row in proof['reads'])
        refused(lambda: image_api.source_view('association').__enter__())
    assert Path.read_bytes is original_read and factory_path.read_bytes() == live

for role in ('current', 'publication', 'book', '../prerequisites'):
    refused(lambda: image_api.source_view(role).__enter__())
for label in ('missing_module', 'wrong_factory', 'promotion', 'missing_contract'):
    bad = copy.deepcopy(image)
    if label == 'missing_module':
        del bad['historical_imports']['modules'][next(iter(bad['historical_imports']['modules']))]
    elif label == 'wrong_factory':
        bad['historical_imports']['modules'][image_api.FACTORY] = prepare.blob(live)
    elif label == 'promotion':
        bad['proposal']['historical_cohorts'].append('current')
    else:
        del bad['original_contracts'][next(iter(bad['original_contracts']))]
    refused(lambda: image_api.source_view('prerequisites', bad).__enter__())

original_input_read = execute.read
dependency = next(name for name in image['historical_imports']['modules'] if name != image_api.FACTORY)


def changed_dependency(path):
    body = original_input_read(path)
    return body + b'\n# changed dependency\n' if str(path) == dependency else body


with patch.object(execute, 'read', side_effect=changed_dependency):
    refused(lambda: image_api.source_view('prerequisites').__enter__())
assert Path.read_bytes is original_read

class DeliberateFailure(Exception):
    pass


def fail_inside():
    with image_api.source_view('association'):
        assert factory_path.read_bytes() == old
        raise DeliberateFailure()


refused(fail_inside, DeliberateFailure)
assert Path.read_bytes is original_read and factory_path.read_bytes() == live
print('All four exact historical guards separate live/historical inputs; source/import/role and restoration controls pass. No semantic reader or cohort executes.')
