"""Separate finite visible-prefix meaning from full observer formatting truth."""
import copy
import hashlib
import json
import re
from pathlib import Path

BASE = Path('docs/audits/observer-join-prerequisite-20261010')
LEGACY = Path('docs/audits/record-value-class-frame-join-20261006')


def module(path):
    ns = {'__name__': 'observer_prerequisite_probe', '__file__': str(path)}
    exec(compile(path.read_bytes(), str(path), 'exec'), ns)
    return ns


def pin(raw):
    return {'bytes': len(raw), 'sha256': hashlib.sha256(raw).hexdigest()}


def main():
    assert not (BASE / 'probe.json').exists(), 'retain the first successful distinction'
    old = module(LEGACY / 'verify.py')
    expected = old['source_models']()
    original = old['load'](LEGACY / 'raw-product.json')['inventories']
    nested = old['public']['context']['nested_records'](expected['frame_model']['own'])
    baseline = old['prior_predicates'](expected, original, nested)
    wanted = None
    for mode in original:
        for domain, population in mode['domains'].items():
            for row in population['nonempty']:
                for segment in row['segments']:
                    if segment['kind'] != 'frame' or not segment['call'].startswith('Test::Builder::subtest('):
                        continue
                    match = re.search(r'"(?:\\.|[^"\\])*"\.\.\.', segment['call'])
                    if match is not None and len(json.loads(match[0][:-3])) > 1:
                        wanted = (mode['mode'], domain, row['index'], segment['call'], match[0])
                        break
                if wanted:
                    break
            if wanted:
                break
        if wanted:
            break
    assert wanted is not None, 'actual public observer header has a source-name truncation'
    mode_name, domain, index, call, display = wanted
    value = json.loads(display[:-3])
    shortened = json.dumps(value[:1]) + '...'
    changed_call = call.replace(display, shortened, 1)
    assert changed_call != call and call.count(display) == 1
    candidate = copy.deepcopy(original)
    mode = next(m for m in candidate if m['mode'] == mode_name)
    row = old['row'](mode, domain, index)
    before_body = row['body']
    assert before_body.count(call) == 1
    changed_body = before_body.replace(call, changed_call, 1)
    trace = old['public']['context']['module'](old['public']['context']['RAW'] / 'trace_inventory.py')['inventory']
    parsed = trace(changed_body)
    row.update(body=changed_body, body_identity=pin(changed_body.encode()), **parsed)
    assert row['body'] == changed_body and row['body_identity'] == pin(changed_body.encode())
    compatible = old['prior_predicates'](expected, candidate, nested)
    try:
        old['check'](expected, expected, candidate, original, nested)
    except ValueError as error:
        refusal = str(error)
        assert refusal == 'every canonical original raw body allocation context and opaque byte conserves', refusal
    else:
        raise ValueError('whole original custody must reject the changed header')
    products = {'candidate.json': candidate, 'baseline-prior.json': baseline,
                'candidate-prior.json': compatible}
    for name, value in products.items():
        path = BASE / name
        assert not path.exists(), 'no successful product overwrite'
        path.write_text(json.dumps(value, sort_keys=True, indent=2) + '\n')
    report = {'scope': 'Diagnosis only: deliberately limited visible-prefix semantics accept another proper prefix; unchanged full original custody rejects it. This is not a false green of the full historical reader.',
              'legacy': str(LEGACY / 'verify.py'),
              'intervention': {'mode': mode_name, 'domain': domain, 'index': index,
                               'before_call': call, 'after_call': changed_call,
                               'before_display': display, 'after_display': shortened,
                               'before_body': pin(before_body.encode()), 'after_body': pin(changed_body.encode())},
              'baseline_prior_status': 0, 'candidate_prior_status': 0,
              'candidate_full_status': 1, 'candidate_full_cause': refusal,
              'products': {name: pin((BASE / name).read_bytes()) for name in products},
              'missing': ['Complete original observer full-header/quoting/truncation contract',
                          'Original formatter/settings/provider identity remains unmeasured; current public fixtures establish compatibility only'],
              'next': 'Complete unchanged observer join under .2, then qualify publication and full parent under .3; raw-stack closure follows.'}
    (BASE / 'probe.json').write_text(json.dumps(report, sort_keys=True, indent=2) + '\n')
    print('PASS actual proper-prefix distinction: limited predecessor semantics accept; whole original custody rejects. Full observer/header/format qualification remains pending.')


if __name__ == '__main__':
    main()
