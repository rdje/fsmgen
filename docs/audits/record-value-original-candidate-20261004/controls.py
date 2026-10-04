"""Exercise observation provenance guards; semantic graph controls follow."""
import copy
import json
from pathlib import Path

BASE = Path('docs/audits/record-value-original-candidate-20261004')
reader = {'__name__': 'capture_reader'}
exec(compile((BASE / 'check_capture.py').read_bytes(), str(BASE / 'check_capture.py'), 'exec'), reader)
binding = reader['authenticate']()
execution = reader['load'](BASE / 'execution.json')
records = {m: reader['load'](BASE / (m + '.json')) for m in reader['MODES']}
rows = []


def control(name, change, expected):
    bad_execution, bad_records = copy.deepcopy(execution), copy.deepcopy(records)
    change(bad_execution, bad_records)
    try:
        reader['check_products'](bad_execution, bad_records, binding)
    except ValueError as error:
        assert str(error) == expected
        rows.append({'name': name, 'status': 1, 'error': str(error)})
    else:
        raise ValueError('false-green capture control: ' + name)


control('omit-original-copy', lambda e, r: r['ordinary']['copies'].pop(), 'complete captured native population')
control('omit-bad-provider-trial', lambda e, r: r['controls']['trials'].pop(), 'each original input receives both actual providers')
control('promote-native-status', lambda e, r: e['modes'][0].update(status=False), 'actual mode native status')
control('wrong-host-profile', lambda e, r: r['ordinary']['host'].update(storable='wrong'), 'whole observed native host profile')
control('hide-alias-abort', lambda e, r: r['alias']['test_run'].update(completed=1), 'actual alias abort boundary')
control('borrow-producer-authority', lambda e, r: e['producer'].update(body=e['producer']['body'] + '\n'), 'whole executed capture producer')
control('absolute-fixture-coordinate', lambda e, r: e['modes'][0].update(fixture='/native/absolute'), 'relative native fixture')
path = BASE / 'capture-controls.json'
if path.exists():
    assert reader['equal'](reader['load'](path), rows), 'whole saved controls'
else:
    path.write_text(json.dumps(rows, sort_keys=True, indent=2) + '\n')
print('PASS observation omission/host/status/abort/producer/coordinate guards reject their actual controls; independent semantics remain pending.')
