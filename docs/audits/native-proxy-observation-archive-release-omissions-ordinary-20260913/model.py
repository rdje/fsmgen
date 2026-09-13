"""Select from independently predicted healthy close order and source ownership."""
import importlib.util
from pathlib import Path

BASE = Path(__file__).resolve().parent


def module(name, path):
    spec = importlib.util.spec_from_file_location(name, path)
    value = importlib.util.module_from_spec(spec); spec.loader.exec_module(value)
    return value


CORE = module('omission_original_close_oracles',
    BASE.with_name('native-proxy-observation-archive-release-close-ordinary-20260912') / 'audit.py')


def resolve(calls, context, sealed, recipe):
    assert set(recipe) == {'kind', 'scope', 'handle_kind'}
    if recipe['kind'] == 'healthy':
        assert recipe['scope'] is None and recipe['handle_kind'] is None
        return []
    assert recipe['kind'] == 'omit'
    bindings = CORE.SELECT.ownership(calls, context)
    healthy = CORE.SUPPORT.TRACE.derive(calls, context, sealed, None)
    candidates = [b for b in bindings if b['close_scope'] == recipe['scope']]
    target = min(candidates, key=lambda b: healthy['events'].index('close:' + b['label'] + ':before'))
    assert target['kind'] == recipe['handle_kind']
    return [target]
