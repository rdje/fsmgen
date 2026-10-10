"""Independent complete Git/source intake check after the fresh predecessor gate.

The fresh source gate already executes the complete corrected predecessor. This
distinct leg verifies all its input bytes and independently reconstructs the
new intake, rather than repeating the same expensive test without a new change.
"""
import hashlib
import json
import subprocess
from pathlib import Path

BASE = Path('docs/audits/address-observer-holders-20261010')
ORIGINAL = Path('docs/audits/record-value-original-candidate-20261004')


def pin(raw):
    return {'bytes': len(raw), 'sha256': hashlib.sha256(raw).hexdigest()}


def exact(left, right):
    return json.dumps(left, sort_keys=True) == json.dumps(right, sort_keys=True)


def qualify(inputs, binding):
    outcome = json.loads((BASE / 'checks.json').read_bytes())['first-source']
    expected = 'PASS complete corrected source models and original caller headers conserved; holder prefixes await independent qualification.\n'
    if (type(outcome['status']) is not int or outcome['status'] != 0 or outcome['stdout'] != expected
            or outcome['instruments'][str(BASE / 'source.py')] != pin((BASE / 'source.py').read_bytes())):
        raise ValueError('actual complete fresh predecessor/source intake qualification')
    for path, identity in binding['inputs'].items():
        raw = Path(path).read_bytes()
        if pin(raw) != identity or raw != subprocess.check_output(['git', 'show', binding['revision'] + ':' + path]):
            raise ValueError('complete fixed Git durability bytes: ' + path)
    for path, identity in inputs['conserved_models'].items():
        if path not in binding['inputs'] or pin(Path(path).read_bytes()) != identity:
            raise ValueError('whole conserved source model bytes')
    if inputs['observer_source'] != (ORIGINAL / 'observe.pl').read_text() or inputs['test_source'] != Path('t/1986-isf-record-port-value-gates.t').read_text():
        raise ValueError('whole observer and test source intake')
    helper = json.loads(Path('docs/audits/address-helper-bindings-20261010/hypotheses.json').read_bytes())
    fields = {'kind', 'caller', 'helper', 'parse', 'api', 'api_start', 'api_end', 'parse_start', 'parse_end',
              'consumer_start', 'consumer_end', 'accepted'}
    for model, mode in zip(inputs['modes'], ('ordinary', 'storable', 'controls'), strict=True):
        if model['mode'] != mode:
            raise ValueError('complete original intake capture population')
        captured = json.loads((ORIGINAL / (mode + '.json')).read_bytes())
        headers = {table: [{key: value for key, value in row.items() if key in fields}
                           for row in captured[table]] for table in ('api', 'copies', 'helpers', 'parses', 'consumers')}
        inherited = next(row for row in helper['modes'] if row['mode'] == mode)
        views = [{'domain': view['domain'], 'event': view['event']}
                 for case in inherited['cases'] for view in case['views']]
        if not exact(model, {'mode': mode, 'headers': headers, 'views': views}):
            raise ValueError('complete original header and source-view intake')
    return {'fixed_git_inputs': len(binding['inputs']), 'conserved_models': len(inputs['conserved_models']),
            'fresh_source_gate': pin(json.dumps(outcome, sort_keys=True).encode())}
