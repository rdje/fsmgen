"""Compare source-scope and prefix predictions on the original last-observation fixture."""
import copy
import errno
import importlib.util
import json
import os
from pathlib import Path

BASE = Path(__file__).resolve().parent
ROOT = BASE.parents[2]
LOG = ROOT / '.artifacts/logs' / BASE.name


def module(name, path):
    spec = importlib.util.spec_from_file_location(name, path)
    value = importlib.util.module_from_spec(spec); spec.loader.exec_module(value)
    return value


PREPARE = module('last_close_oracle_prepare', BASE / 'prepare.py')
CORE = module('last_close_oracle_qualified_support', PREPARE.ORDINARY / 'audit.py')
LAST = module('last_close_oracle_original_final_reference', PREPARE.LAST / 'audit.py')
PIN_NAMES = ['plan.json', 'prepare.py', 'prepare-pin.json', 'qualify.t', 'audit.py', 'oracle-preflight.py']


def evaluate(plan):
    assert PREPARE.build() == plan
    pins = PREPARE.load(BASE / 'oracle-pins.json')
    assert pins == [PREPARE.pin(BASE / n) for n in PIN_NAMES]
    CORE.authenticate(PREPARE.load(PREPARE.ORDINARY / 'plan.json'))
    original = (PREPARE.ORDINARY / 'audit.py').read_text()
    original = original[original.index('def verify_row('):original.index('def main():')]
    expected = original.replace('def verify_row(', 'def _verify_close(').replace(
        'work_settlement retirement before_archive', 'work_settlement retirement controlled_setup_removed_hold before_archive')
    current = (BASE / 'audit.py').read_text()
    current = current[current.index('def _verify_close('):current.index('def verify_row(')]
    assert current == expected
    setup = (PREPARE.LAST / 'qualify.t').read_text()
    setup = setup[setup.index('        die "last-observation matrix requires'):setup.index('        $row->{before_archive} =')]
    assert (BASE / 'qualify.t').read_text().count(setup) == 1
    row = PREPARE.load(PREPARE.BOUNDARY / 'result/qualification.json')['cases'][3]
    assert row['profile_id'] == plan['profile_id'] and row['selection'] == plan['selection']
    assert LAST.last_state(row) == 1
    specification, _ = CORE.OLD.setup(row)
    calls = CORE.FLOW.derive(row['context'], row['operation']['before'], specification)
    healthy = CORE.SUPPORT.TRACE.derive(calls, row['context'], plan['sealed_symbols'], None)
    bindings = CORE.SELECT.ownership(calls, row['context'])
    by_address = {b['address']: b for b in bindings}
    assert len(by_address) == len(bindings) == len(plan['cases']) - 1
    assert set(by_address) == {c['reports'][0]['address'] for c in plan['cases'][1:]}
    predictions = []
    witnesses = {}
    for case in plan['cases']:
        resolved = [by_address[r['address']] for r in case['reports']]
        recursive = CORE.TRACE.derive(calls, row['context'], plan['sealed_symbols'], resolved, os.strerror(errno.EIO))
        prefix = CORE.PREFIX.reference(calls, plan['sealed_symbols'], healthy, bindings, resolved[0] if resolved else None)
        assert recursive == prefix
        predictions.append(dict(index=case['index'], name=case['name'], resolved=resolved,
            prediction_sha256=CORE.SIGNATURE(prefix), success=prefix['success'],
            effects=prefix['effects'], handles=len(prefix['handles']), calls=len(prefix['calls'])))
        if resolved:
            witnesses.setdefault('fault', (recursive, prefix))
            if prefix['effects']['unlink_completed']: witnesses['late'] = (recursive, prefix)
    controls = []
    for name, witness, change in (
        ('lost-close', 'fault', lambda p: p['events'].remove(next(e for e in p['events'] if e.startswith('close:')))),
        ('changed-error', 'fault', lambda p: p.update(error='different\n')),
        ('false-success', 'fault', lambda p: p.update(success=True)),
        ('wrong-owner', 'fault', lambda p: p['handles'][0].update(close_scope='Foreign')),
        ('lost-unlink', 'late', lambda p: p['effects'].update(unlink_completed=0)),
        ('lost-absence', 'late', lambda p: p['effects'].update(reference_absence_verified=0)),
    ):
        recursive, prefix = witnesses[witness]
        changed = copy.deepcopy(recursive); change(changed)
        assert changed != prefix, name
        controls.append(name)
    return dict(schema='fsmgen.release_last_close_oracle_preflight.v1', success=True,
        source_revision=plan['source_revision'], prospective_pins=pins, predictions=predictions,
        falsifiers=controls, fixture_allocations=0, prior_last_state_verified=True,
        scope='Pure predictions against original last-observation inputs; actual new fixture coverage remains pending.')


def summary(result):
    return dict(success=True, predictions=len(result['predictions']),
        falsifiers=result['falsifiers'], fixture_allocations=0, prior_last_state_verified=True)


if __name__ == '__main__':
    result = evaluate(PREPARE.load(BASE / 'plan.json'))
    with (LOG / 'oracle.json').open('x') as stream:
        stream.write(json.dumps(result, sort_keys=True, indent=2) + '\n')
    print(json.dumps(summary(result), sort_keys=True))
