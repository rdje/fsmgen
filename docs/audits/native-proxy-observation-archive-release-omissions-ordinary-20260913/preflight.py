"""Qualify current Perl bindings against independent healthy close events."""
import copy
import json
from pathlib import Path
import re
import sys
from model import CORE, resolve

BASE = Path(__file__).resolve().parent
ROOT = BASE.parents[2]
LOG = ROOT / '.artifacts/logs' / BASE.name
NAMES = ['prepare.py', 'model.py', 'OmissionPlan.pm', 'binding.t', 'preflight.py', 'source-pins.json', 'plan.json']


def load(path):
    return json.loads(path.read_bytes())


def verify(plan, pins, report, tap):
    assert set(report) == {'schema', 'success', 'prospective_pins', 'variants', 'controls', 'allocated', 'forbidden_process_attempts'}
    assert report['schema'] == 'fsmgen.release_omission_binding.v1' and report['success'] is True
    assert report['prospective_pins'] == pins and report['allocated'] == [] and report['forbidden_process_attempts'] == 0
    vectors = load(ROOT / plan['binding_vectors'])
    profiles = {p['id']: p for p in plan['binding_profiles']}
    expected = []
    for profile in vectors['profiles']:
        for variant in profile['variants']:
            bindings = [dict(case_index=case['index'], targets=resolve(variant['calls'], profile['context'],
                plan['sealed_symbols'], case['recipe'])) for case in profiles[profile['profile']]['cases']]
            expected.append(dict(profile=profile['profile'], name=variant['name'], resolutions=bindings, inputs_unchanged=1))
    assert report['variants'] == expected
    assert len(report['controls']) == len({r['name'] for r in report['controls']}) == 10
    assert all(r['returned'] == 0 and r['error'].endswith('\n') for r in report['controls'])
    assertions = len(expected) * 3 + len(report['controls']) * 2 + 1
    CORE.SUPPORT.tap(tap, assertions)
    return dict(variants=len(expected), resolutions=sum(len(v['resolutions']) for v in expected), assertions=assertions)


def main():
    assert sys.argv[1:] in ([], ['--verify-saved'])
    prepare = CORE.module('ordinary_omission_preflight_prepare', BASE / 'prepare.py')
    plan = load(BASE / 'plan.json'); assert plan == prepare.build()
    pins = load(BASE / 'binding-pins.json'); assert pins == [prepare.pin(BASE / n) for n in NAMES]
    directory = BASE / 'result/preflight' if sys.argv[1:] else LOG
    assert (directory / 'binding.exit').read_bytes() == b'0\n'
    report = load(directory / 'binding.json'); tap = directory / 'binding.tap'
    counts = verify(plan, pins, report, tap)
    controls = []
    for name, mutate in (
        ('missing-variant', lambda r: r['variants'].pop()),
        ('repeated-variant', lambda r: r['variants'].append(copy.deepcopy(r['variants'][0]))),
        ('wrong-scope', lambda r: r['variants'][0]['resolutions'][1]['targets'][0].update(close_scope='foreign')),
        ('stale-label', lambda r: r['variants'][0]['resolutions'][1]['targets'][0].update(label='source:99999')),
        ('foreign-path', lambda r: r['variants'][0]['resolutions'][1]['targets'][0].update(path='foreign')),
        ('stale-call', lambda r: r['variants'][0]['resolutions'][1]['targets'][0].update(open_call_id=-1)),
        ('healthy-target', lambda r: r['variants'][0]['resolutions'][0].update(targets=[{}])),
        ('omitted-current-target', lambda r: r['variants'][0]['resolutions'][1].update(targets=[])),
    ):
        changed = copy.deepcopy(report); mutate(changed)
        assert CORE.rejects(lambda: verify(plan, pins, changed, tap)), name
        controls.append(name)
    result = dict(schema='fsmgen.release_omission_preflight.v1', success=True, prospective_pins=pins,
        counts=counts, recipe_controls=len(report['controls']), falsifiers=controls,
        allocated=[], scope='Pure current-flow binding only; no omitted-close or file fixture executed.')
    if sys.argv[1:]:
        assert result == load(directory / 'preflight.json')
    else:
        with (LOG / 'preflight.json').open('x') as stream:
            stream.write(json.dumps(result, sort_keys=True, indent=2) + '\n')
    print(json.dumps({k:v for k,v in result.items() if k != 'prospective_pins'}, sort_keys=True))


if __name__ == '__main__':
    main()
