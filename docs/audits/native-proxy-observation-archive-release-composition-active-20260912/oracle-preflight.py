"""Compare independent composition predictions on the retained active-runtime inputs."""
import copy
import importlib.util
import json
from pathlib import Path

BASE = Path(__file__).resolve().parent
ROOT = BASE.parents[2]
LOG = ROOT / '.artifacts/logs' / BASE.name


def module(name, path):
    spec = importlib.util.spec_from_file_location(name, path)
    value = importlib.util.module_from_spec(spec); spec.loader.exec_module(value)
    return value


PREPARE = module('active_composition_oracle_prepare', BASE / 'prepare.py')
CORE = module('active_composition_qualified_oracles', PREPARE.ORDINARY / 'audit.py')
ACTIVE = module('active_composition_original_runtime_state', PREPARE.ACTIVE / 'audit.py')
PIN_NAMES = ['plan.json', 'prepare.py', 'prepare-pin.json', 'qualify.t', 'qualifier-pin.json',
             'audit.py', 'oracle-preflight.py']


def evaluate(plan):
    assert PREPARE.build() == plan
    pins = PREPARE.load(BASE / 'oracle-pins.json')
    assert pins == [PREPARE.pin(BASE / n) for n in PIN_NAMES]
    _, vectors = CORE.authenticate(PREPARE.load(PREPARE.ORDINARY / 'plan.json'))
    inherited = CORE.prerequisites(vectors)
    original = (PREPARE.ORDINARY / 'audit.py').read_text()
    original = original[original.index('def verify_row('):original.index('def main():')]
    expected = original.replace('def verify_row(', 'def _verify_composition(', 1).replace(
        'work_settlement retirement before_archive', 'work_settlement before_archive', 1).replace(
        'PREPARE.resolve(', 'CORE.PREPARE.resolve(', 1)
    current = (BASE / 'audit.py').read_text()
    current = current[current.index('def _verify_composition('):current.index('def verify_row(')]
    assert current == expected
    row = PREPARE.load(PREPARE.BOUNDARY / 'result/qualification.json')['cases'][2]
    assert row['profile_id'] == plan['profile_id'] and row['selection'] == plan['selection']
    ACTIVE.active_state(row)
    spec, _ = CORE.OLD.setup(row)
    calls = CORE.FLOW.derive(row['context'], row['operation']['before'], spec)
    predictions = []; witnesses = {}
    for case in plan['cases']:
        resolved = CORE.PREPARE.resolve(calls, row['context'], plan['sealed_symbols'], case['recipe'])
        recursive = CORE.TRACE.derive(calls, row['context'], plan['sealed_symbols'], resolved, CORE.ERROR_TEXT)
        independent = CORE.PREFLIGHT.reference(calls, row['context'], plan['sealed_symbols'], resolved)
        assert recursive == independent
        predictions.append(dict(index=case['index'], name=case['name'], resolved=resolved,
            prediction_sha256=CORE.SIGNATURE(independent), success=independent['success'],
            effects=independent['effects'], handles=len(independent['handles']), calls=len(independent['calls'])))
        witnesses.setdefault(case['recipe']['kind'], (recursive, independent))
    controls = []
    for name, kind, mutate in (
        ('lost-close', 'group', lambda r: r['events'].pop(-2)),
        ('declaration-order-winner', 'group', lambda r: r.update(error='wrong winner\n')),
        ('masked-primary', 'source-primary', lambda r: r.update(error='cleanup replaced primary\n')),
        ('lost-directory-primary', 'directory-primary', lambda r: r.update(directory_primary_hits=0)),
        ('invented-primary', 'healthy', lambda r: r.update(injected_hits=1)),
        ('lost-owner', 'group', lambda r: r['handles'].pop()),
        ('wrong-errno', 'group', lambda r: next(x for x in r['reports'] if x['applied']).update(errno='SUCCESS')),
        ('lost-unlink', 'healthy', lambda r: r['effects'].update(unlink_completed=0)),
        ('lost-absence', 'healthy', lambda r: r['effects'].update(last_reference_check=None)),
        ('lost-report-hit', 'group', lambda r: r['reported_error_addresses'].pop()),
        ('false-success', 'source-primary', lambda r: r.update(success=1)),
    ):
        actual, expected = witnesses[kind]; changed = copy.deepcopy(actual); mutate(changed)
        assert changed != expected, name
        controls.append(name)
    return dict(schema='fsmgen.release_active_composition_oracle_preflight.v1', success=True,
        source_revision=plan['source_revision'], prospective_pins=pins, predictions=predictions,
        falsifiers=controls, inherited=inherited, fixture_allocations=0, prior_identity_verified=True,
        scope='Pure baseline predictions and retained cross-profile binding evidence only; no fixture is replayed.')


def summary(result):
    return dict(success=True, predictions=len(result['predictions']), falsifiers=result['falsifiers'],
        inherited=result['inherited'], fixture_allocations=0, prior_identity_verified=True)


if __name__ == '__main__':
    result = evaluate(PREPARE.load(BASE / 'plan.json'))
    with (LOG / 'oracle.json').open('x') as stream:
        stream.write(json.dumps(result, sort_keys=True, indent=2) + '\n')
    print(json.dumps(summary(result), sort_keys=True))
