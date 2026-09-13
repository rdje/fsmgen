"""Prove the outcome-counter correction against unchanged original rejections."""
import copy
import hashlib
from common import BASE, ROOT, load, module, physical, rejects


def verify():
    review = load(BASE / 'first-failure/review.json')
    for record in review['sources'] + review['outputs']:
        raw = (ROOT / record['destination']).read_bytes()
        assert len(raw) == record['size_bytes'] and hashlib.sha256(raw).hexdigest() == record['sha256']
    original = (BASE / 'first-failure/common.py.initial-source').read_text()
    change = load(BASE / 'correction-review.json')
    assert original.count(change['before']) == 1
    corrected = original.replace(change['before'], change['after'])
    for replacement in change['additional_changes']:
        assert corrected.count(replacement['before']) == 1
        corrected = corrected.replace(replacement['before'], replacement['after'])
    assert corrected == (BASE / 'common.py').read_text()
    namespace = {'__file__': str(BASE / 'common.py')}
    exec(compile(original, str(BASE / 'first-failure/common.py.initial-source'), 'exec'), namespace)
    release = BASE.parent / 'native-proxy-observation-archive-release-20260911'
    oracle = module(release / 'audit.py')
    report = load(release / 'result/qualification.json')
    missing = [row for row in report['cases'] if 'result' not in row['operation']]
    assert [row['name'] for row in missing] == review['affected_original_cases']
    controls = []
    for row in missing:
        spec, _ = oracle.setup(row)
        oracle.attempt(row, spec)
        assert rejects(lambda: namespace['physical'](row))
        measured = physical(row)
        assert measured['pre_envelope_rejections'] == 1
        assert measured['public_rejections'] == measured['public_successes'] == measured['handles'] == measured['actual_unlinks'] == 0
        for name, mutate in [('erased-error', lambda value: value['operation'].update(error='')),
                             ('invented-envelope', lambda value: value['operation'].update(result={'success': 0})),
                             ('false-return', lambda value: value['operation'].update(returned=1))]:
            altered = copy.deepcopy(row)
            mutate(altered)
            assert rejects(lambda: physical(altered))
            controls.append(row['name'] + ':' + name)
    counter_review = load(BASE / 'first-complete-counter-review/review.json')
    for record in counter_review['records']:
        raw = (ROOT / record['destination']).read_bytes()
        assert len(raw) == record['size_bytes'] and hashlib.sha256(raw).hexdigest() == record['sha256']
    close = BASE.parent / 'native-proxy-observation-archive-release-close-ordinary-20260912/result/cases'
    healthy = load(close / 'case-0000.json')
    fault = load(close / 'case-0001.json')
    assert namespace['physical'](healthy)['close_error_reports'] == len(healthy['operation']['handles']) > 0
    assert physical(healthy)['reported_close_failures'] == 0
    assert physical(fault)['reported_close_failures'] == 1
    original_faults = [row for row in report['cases'] if row['operation']['modeled_close_hits']]
    assert len(original_faults) == 3 and all(physical(row)['reported_close_failures'] == 1 for row in original_faults)
    for name, mutate in [
        ('lost-close-observation', lambda row: row['operation']['close_reports'].pop()),
        ('duplicate-close-observation', lambda row: row['operation']['close_reports'].append(copy.deepcopy(row['operation']['close_reports'][0]))),
        ('erased-modeled-report', lambda row: row['operation']['close_reports'][0].update(report_applied=0)),
        ('false-reported-success', lambda row: next(handle for handle in row['operation']['handles'] if handle['reported_return'] == 0).update(reported_return=1))]:
        altered = copy.deepcopy(fault)
        mutate(altered)
        assert rejects(lambda: physical(altered))
        controls.append(name)
    return dict(first_counter_rejections=len(missing), corrected_pre_envelope_rejections=len(missing),
                falsifiers=controls, exact_declared_source_replacements=True, corrected_report_falsifiers=4)


if __name__ == '__main__':
    import json
    print(json.dumps(verify(), sort_keys=True))
