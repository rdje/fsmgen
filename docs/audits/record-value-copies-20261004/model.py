"""Strict source identity and reference obligation; no native products read."""
import re
from pathlib import Path
import importlib.util

scope_model_path = Path('docs/audits/record-value-scopes-20261004/model.py')
loader = importlib.util.spec_from_file_location('qualified_scope_source_helpers', scope_model_path)
helpers = importlib.util.module_from_spec(loader)
loader.loader.exec_module(helpers)

def source_reference(value):
    if value is None:
        return None
    result = helpers.source_projection(value)
    for key in ('width', 'low', 'high'):
        if key in result:
            assert type(result[key]) in (int, str) and re.fullmatch(r'[0-9]+', str(result[key]))
            result[key] = int(result[key])
    return result

def valid_reference(value):
    if value is None:
        return True
    if not isinstance(value, dict) or not {'root', 'role', 'path_text', 'type_spec', 'width'} <= set(value) <= {'root', 'role', 'path_text', 'type_spec', 'width', 'low', 'high'}:
        return False
    if not re.fullmatch(r'[A-Za-z_]\w*', value['root']) or value['role'] not in ('input', 'output', 'storage', 'local'):
        return False
    spec = value['type_spec']
    if not helpers.type_valid(spec) or value['width'] <= 0 or value['width'] != spec['width']:
        return False
    leaf = bool(value['path_text'])
    if leaf:
        return spec['kind'] not in ('record', 'list') and {'low', 'high'} <= set(value) and value['high'] - value['low'] + 1 == value['width']
    return 'low' not in value and 'high' not in value

def whole_record(value):
    return value is not None and value['path_text'] == '' and value['type_spec']['kind'] == 'record'

def outcome(source, target):
    if not valid_reference(source) or not valid_reference(target):
        return {'accepted': 0, 'product': None, 'reason': 'invalid-reference'}
    obligation = any(whole_record(value) and value['role'] in ('input', 'output') for value in (source, target))
    if not obligation:
        return {'accepted': 1, 'product': 0, 'reason': 'existing-assignment-contract'}
    if not whole_record(source) or not whole_record(target):
        return {'accepted': 0, 'product': None, 'reason': 'whole-record-roots-required'}
    if target['role'] == 'input':
        return {'accepted': 0, 'product': None, 'reason': 'input-target'}
    if source['type_spec'] != target['type_spec']:
        return {'accepted': 0, 'product': None, 'reason': 'resolved-recursive-identity'}
    return {'accepted': 1, 'product': 1, 'reason': 'same-resolved-record'}
