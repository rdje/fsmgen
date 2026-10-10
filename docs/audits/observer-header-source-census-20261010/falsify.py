"""Execute genuine whole-census interventions against the independent reader."""
import base64
import copy
import gzip
from common import canonical, load, pin, save
from oracle import validate


def candidates():
    baseline = load('census.json')
    edits = [
        ('omitted-phase', lambda c: c['phases'].pop(), 'phases'),
        ('omitted-frame', lambda c: c['frames'].pop(), 'frames'),
        ('borrowed-frame', lambda c: c['frames'][0].update(input=copy.deepcopy(c['frames'][-1]['input'])), 'frames'),
        ('reordered-frame', lambda c: c['frames'].insert(0,c['frames'].pop()), 'frames'),
        ('omitted-operand', lambda c: c['operands'].pop(), 'operands'),
        ('wrong-operand-role', lambda c: c['operands'][0]['input'].update(role='borrowed role'), 'operands'),
        ('invented-operand-schema', lambda c: c['operands'][0].update(schema='zero_literal'), 'operands'),
        ('promoted-false-scalar', lambda c: c['operands'][0].update(value_knowledge='exact native numeric zero'), 'operands'),
        ('lost-opaque-scope', lambda c: c.update(role='all original provider settings measured'), 'role'),
        ('lost-ambiguity', lambda c: c['obligations'].pop('false_scalar_representation'), 'obligations'),
        ('source-do-changed', lambda c: c['loads'][0].update(source_operator='require'), 'loads'),
        ('premature-full-header', lambda c: c.update(full_headers_qualified=True), None),
    ]
    for name, edit, field in edits:
        candidate = copy.deepcopy(baseline)
        edit(candidate)
        cause = 'closed complete census product; no premature header claim' if field is None else 'complete independent source census: ' + field
        yield name, cause, candidate


def outcome(candidate, source, raw):
    try:
        validate(candidate, source, raw)
    except ValueError as error:
        return dict(accepted=False, exception='ValueError', message=str(error))
    return dict(accepted=True)


def main():
    from common import BASE, need
    source, raw = load('source-models.json'), (BASE / 'source-models.json').read_bytes()
    controls = {}
    for name, cause, candidate in candidates():
        raw_candidate = canonical(candidate)
        actual = outcome(candidate, source, raw)
        controls[name] = dict(candidate_identity=pin(raw_candidate),
            whole_candidate_gzip_base64=base64.b64encode(gzip.compress(raw_candidate,mtime=0)).decode(),
            expected_cause=cause, actual=actual)
        need(actual == dict(accepted=False, exception='ValueError', message=cause),
             'actual intended independent refusal: ' + name)
    save('controls.json', controls)
    print('PASS complete whole-census source/member/order/role/schema/scope/header interventions rejected at intended contracts.')


if __name__ == '__main__':
    main()
