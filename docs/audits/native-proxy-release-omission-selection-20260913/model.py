"""Select representative omissions from original actual close events."""
import copy
import importlib.util
from pathlib import Path

BASE = Path(__file__).resolve().parent
spec = importlib.util.spec_from_file_location('omission_original_event_selector',
    BASE.with_name('native-proxy-release-close-selection-20260912') / 'model.py')
EVENTS = importlib.util.module_from_spec(spec); spec.loader.exec_module(EVENTS)


def select(row):
    """Choose the first actual normal close in each original cleanup scope."""
    assert row['operation']['result']['success'] == 1
    selected = {}
    for item in sorted(EVENTS.select(row), key=lambda value: value['baseline_close_event']):
        selected.setdefault(item['baseline_close_scope'], copy.deepcopy(item))
    cases = [dict(index=0, name='healthy', recipe=dict(kind='healthy', scope=None, handle_kind=None), baseline=None)]
    for scope in sorted(selected):
        item = selected[scope]
        cases.append(dict(index=len(cases), name='omit:' + scope,
            recipe=dict(kind='omit', scope=scope, handle_kind=item['kind']), baseline=item))
    return cases
