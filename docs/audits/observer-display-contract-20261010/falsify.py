"""Run genuine independent negative controls and retain every complete candidate."""
import base64
import copy
import gzip
import hashlib
import json
from pathlib import Path
import oracle_repaired as oracle

BASE = oracle.BASE


def pin(raw):
    return dict(bytes=len(raw), sha256=hashlib.sha256(raw).hexdigest())


def canonical(value):
    return (json.dumps(value, sort_keys=True, indent=2, allow_nan=False) + '\n').encode()


def baseline():
    load = lambda name: json.loads((BASE / name).read_bytes())
    return dict(catalogue=load('repaired-catalogue.json'), hypotheses=load('repaired-hypotheses.json'),
                wire=json.loads(load('repaired-native.json')['stdout']), products=load('repaired-joined.json')['products'])


def row(packet, identifier):
    return next(r for r in packet['wire']['observations'] if r['id'] == identifier)


def candidates():
    b = baseline()
    out = []
    def add(name, cause, mutation):
        value = copy.deepcopy(b)
        mutation(value)
        out.append((name, cause, value))
    def replace(value, identifier, old, new):
        r = row(value, identifier)
        assert r['text'].count(old) == 1, (identifier, old)
        r['text'] = r['text'].replace(old, new, 1)
    def omission(value):
        for key in ['hypotheses', 'products']:
            value[key].pop()
        value['catalogue']['cases'].pop()
        value['wire']['observations'].pop()
    add('omitted-whole-case', 'whole selected catalogue', omission)
    def reorder(value):
        values = value['wire']['observations']
        values[0], values[1] = values[1], values[0]
    add('reordered-case', 'complete ordered observations', reorder)
    def borrowed(value):
        for key in ['before', 'after']:
            row(value, 'byte-65')[key] = copy.deepcopy(row(value, 'byte-66')[key])
    add('borrowed-source-input', 'complete source scalar', borrowed)
    add('wrong-token', 'whole source-generated public body and header',
        lambda v: replace(v, 'byte-65', '"VAW"', '"wrong"'))
    add('wrong-quote', 'whole source-generated public body and header',
        lambda v: replace(v, 'byte-65', '"VAW"', 'VAW'))
    add('wrong-escape', 'whole source-generated public body and header',
        lambda v: replace(v, 'byte-36', '\\$', '$'))
    add('wrong-truncation', 'whole source-generated public body and header',
        lambda v: replace(v, 'boundary-64-65', '"...', '"'))
    add('wrong-count', 'whole source-generated public body and header',
        lambda v: replace(v, 'arity-8-9', ', ...)', ')'))
    add('wrong-regex-suffix-order', 'whole source-generated public body and header',
        lambda v: replace(v, 'repaired-suffix-wide-truncation-3-False', ')...u', ')u...'))
    add('wrong-hook-priority', 'whole source-generated public body and header',
        lambda v: replace(v, 'reference-traced-True', 'own-trace-token', 'own-reference-formatter-token'))
    add('wrong-numeric-truncation', 'whole source-generated public body and header',
        lambda v: replace(v, 'scalar-15', '9' * 65, '9' * 61))
    def alias(value):
        r = row(value, 'held-alias-and-distinction')
        for key in ['before', 'after']:
            r[key][2] = copy.deepcopy(r[key][1])
    add('borrowed-live-reference', 'explicit source reference alias', alias)
    def lifetime(value):
        row(value, 'byte-65')['after'][0]['codepoints'][0] = 0
    add('changed-source-lifetime', 'source argument conservation', lifetime)
    def loss(value):
        r = next(r for r in value['products'] if r['id'] == 'boundary-64-65')
        assert r['source']['slots'][0]['display']['truncated'] is True
        r['source']['slots'][0]['display']['token_is_complete_source_value'] = True
    add('hidden-source-promoted-complete', 'whole independent public products and loss metadata', loss)
    def numeric_loss(value):
        r = next(r for r in value['products'] if r['id'] == 'scalar-15')
        r['source']['slots'][0]['display']['truncated'] = True
    add('false-numeric-loss', 'whole independent public products and loss metadata', numeric_loss)
    add('original-identity-promotion', 'closed current public wire scope',
        lambda v: v['wire'].update(role='Original formatter identity qualified'))
    add('unknown-native-field', 'closed current public wire scope', lambda v: v['wire'].update(native_identity=True))
    add('boolean-profile', 'declared public profile', lambda v: row(v, 'byte-0')['profile'].update(arg_len=True))
    actual = json.loads((BASE / 'native-controls.json').read_bytes())
    for name, result in actual.items():
        assert type(result['status']) is int and result['status'] == 0 and result['stderr'] == ''
        wire = json.loads(result['stdout'])
        value = copy.deepcopy(b)
        value['wire'] = wire
        out.append(('actual-profile-' + name, 'declared public profile', copy.deepcopy(value)))
        target = row(value, result['case'])
        original = row(b, result['case'])
        assert target['text'] != original['text'] and target['profile'] != original['profile']
        target['profile'] = copy.deepcopy(original['profile'])
        out.append(('actual-header-with-camouflaged-profile-' + name,
                    'whole source-generated public body and header', value))
    return out


def outcome(packet):
    try:
        oracle.validate(**packet)
        return dict(accepted=True, exception=None, message='')
    except Exception as error:
        return dict(accepted=False, exception=type(error).__name__, message=str(error))


def main():
    output = BASE / 'falsification.json'
    assert not output.exists()
    original = baseline()
    assert outcome(original) == dict(accepted=True, exception=None, message='')
    result = {}
    for name, cause, value in candidates():
        actual = outcome(value)
        raw = canonical(value)
        assert actual == dict(accepted=False, exception='ValueError', message=cause), (name, actual, cause)
        result[name] = dict(expected_cause=cause, actual=actual, candidate_identity=pin(raw),
                            whole_candidate_gzip_base64=base64.b64encode(gzip.compress(raw, mtime=0)).decode())
    sources = ['oracle_repaired.py', 'falsify.py', 'repaired-catalogue.json', 'repaired-hypotheses.json',
               'repaired-native.json', 'repaired-joined.json', 'native-controls.json']
    output.write_bytes(canonical(dict(controls=result, inputs={name: pin((BASE / name).read_bytes()) for name in sources},
        role='Actual in-process independent validator outcomes, not fabricated subprocess statuses. Every full candidate is losslessly retained; real changed-profile native processes have separate complete results.')))
    print('PASS independent controls reject borrowed/omitted/reordered/quote/escape/truncation/count/reference/loss/scope and genuine changed-profile/header candidates at declared causes.')


if __name__ == '__main__':
    main()
