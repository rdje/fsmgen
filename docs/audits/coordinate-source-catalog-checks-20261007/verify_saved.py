"""Independently consume complete source spans, seal and actual final result."""
import copy
import hashlib
import json
import re
import subprocess
from pathlib import Path

BASE = Path('docs/audits/record-value-coordinate-source-catalog-20261007')
CHECKS = Path('docs/audits/coordinate-source-catalog-checks-20261007')


def require(value, cause):
    if not value:
        raise ValueError(cause)


def load(path):
    return json.loads(path.read_bytes())


def same(a, b):
    return json.dumps(a, sort_keys=True) == json.dumps(b, sort_keys=True)


def pin(raw):
    return dict(bytes=len(raw), sha256=hashlib.sha256(raw).hexdigest())


def module():
    namespace = {'__name__': 'saved_source_catalog'}
    exec(compile((BASE / 'verify.py').read_bytes(), str(BASE / 'verify.py'), 'exec'), namespace)
    return namespace


def verify_span(source, row):
    raw = source.encode()
    for field in ('offset_bytes', 'bytes', 'start_line', 'end_line'):
        require(type(row[field]) is int and row[field] >= (1 if field.endswith('line') else 0),
                'source span genuine integer dimensions')
    offset, size = row['offset_bytes'], row['bytes']
    selected = raw[offset:offset + size]
    require(selected == row['text'].encode() and same(pin(selected), row['identity']),
            'independent complete UTF-8 source span selection')
    # This leg uses binary prefix/LF counts, independently of the producer's
    # Unicode substring/index implementation. No runtime line is guessed.
    require(row['start_line'] == len(raw[:offset].split(b'\n'))
            and row['end_line'] == len(raw[:offset + size].rstrip(b'\n').split(b'\n')),
            'independent inclusive lexical source line range')


def verify_catalog(source, catalog):
    require(set(catalog['units']) == set(source['units']), 'whole independent source unit population')
    for unit, group in catalog['units'].items():
        body = source['units'][unit]['body']
        require(group['path'] == source['units'][unit]['path']
                and same(group['identity'], pin(body.encode())), 'independent whole source unit identity')
        lines = body.splitlines(keepends=True)
        expected = []
        for index, line in enumerate(lines):
            match = re.match(r'^sub ([A-Za-z_]\w*)', line)
            if match is None:
                continue
            if line.rstrip('\n').endswith('}'):
                text = line.rstrip('\n')
            else:
                ends = [i for i in range(index + 1, len(lines)) if lines[i].startswith('}')]
                require(ends, 'independent column-zero function closing boundary')
                text = ''.join(lines[index:ends[0] + 1]).rstrip('\n')
            expected.append((match[1], text))
        require([(r['name'], r['text']) for r in group['named']] == expected,
                'independent every complete single-line and multiline named function')
        for row in (*group['named'], *group['guard_calls']):
            verify_span(body, row)
        for row in group['guard_calls']:
            owner = next(r for r in group['named'] if r['name'] == row['owner'])
            require(owner['offset_bytes'] <= row['offset_bytes']
                    and row['offset_bytes'] + row['bytes'] <= owner['offset_bytes'] + owner['bytes'],
                    'independent guard/call contained lexical owner')
    for row in catalog['qualified_lexical_spans']:
        verify_span(source['units'][row['unit']]['body'], row)


def actual_result(actual, reader):
    command = ['scripts/run_with_ram_guard.sh', '--', 'python3', '-B', str(BASE / 'verify.py'), '--seal']
    require(actual['command'] == command, 'actual complete catalog seal command')
    require(type(actual['status']) is int and actual['status'] == 0,
            'actual catalog genuine integer success')
    require(actual['stdout'] == reader['SUCCESS'] and re.fullmatch(
        r'ram-guard: PID [0-9]+; host [0-9]+\.[0-9]+%; host cutoff 88%; descendant RSS cutoff 4096 MiB; poll 2s\n',
        actual['stderr']) is not None, 'actual catalog complete stdout and guard stderr')
    expected = {str(BASE / 'verify.py'), str(CHECKS / 'run.py'), 'scripts/run_with_ram_guard.sh'}
    require(set(actual['instruments']) == expected
            and all(same(value, pin(Path(path).read_bytes())) for path, value in actual['instruments'].items()),
            'actual catalog complete executed instrument identities')


def refuse(name, operation, cause):
    try:
        operation()
    except ValueError as error:
        require(str(error) == cause, 'independent intended refusal: ' + name + ': ' + str(error))
        return dict(control=name, status=1, cause=cause)
    raise ValueError('independent false-green catalog: ' + name)


def main():
    reader = module()
    before = reader['members']()
    require(same(load(BASE / 'manifest.json'), before), 'whole immutable catalog member seal')
    source, catalog = load(BASE / 'inputs.json'), load(BASE / 'catalog.json')
    canonical = reader['inputs']()
    require(same(source, canonical), 'whole independently fixed-Git source/generation/recipe inputs')
    # JSON objects are unordered. Reconstruct declared array order from the
    # independently fixed committed declarations, after whole-map equality;
    # never sort or normalize the retained catalog's ordered arrays.
    require(same(catalog, reader['derive'](canonical)), 'whole independently regenerated catalog')
    verify_catalog(source, catalog)
    require(same(load(BASE / 'controls.json'), reader['controls'](canonical, catalog)), 'every genuine source control retained')
    first = {'__name__': 'first_source_catalog'}
    first_path = BASE / 'first-verify.py.txt'
    exec(compile(first_path.read_bytes(), str(first_path), 'exec'), first)
    original_inputs = load(BASE / 'first-inputs.json')
    require(same(first['inputs'](), original_inputs), 'whole first failed scanner source inputs')
    refuse('actual-first-scanner-gap', lambda: first['derive'](original_inputs),
           'complete finite own named function lexical bodies')
    failed = load(CHECKS / 'first-derive.json')
    require(type(failed['status']) is int and failed['status'] == 1
            and failed['command'] == ['scripts/run_with_ram_guard.sh', '--', 'python3', '-B', str(BASE / 'verify.py')]
            and failed['stdout'] == ''
            and failed['stderr'].endswith('ValueError: complete finite own named function lexical bodies\n'),
            'whole actual first scanner failure retained')
    actual = load(CHECKS / 'seal.json')
    actual_result(actual, reader)
    rejected = []
    for value in (True, 0.0, 1):
        changed = copy.deepcopy(actual); changed['status'] = value
        rejected.append(refuse('status-' + repr(value), lambda: actual_result(changed, reader),
                               'actual catalog genuine integer success'))
    first = copy.deepcopy(catalog); first['units']['value']['named'].pop()
    rejected.append(refuse('missing-function', lambda: verify_catalog(source, first),
                           'independent every complete single-line and multiline named function'))
    first = copy.deepcopy(catalog); first['units']['value']['guard_calls'][0]['start_line'] += 1
    rejected.append(refuse('wrong-lexical-line', lambda: verify_catalog(source, first),
                           'independent inclusive lexical source line range'))
    first = copy.deepcopy(catalog); first['units']['value']['guard_calls'][0]['offset_bytes'] += 1
    rejected.append(refuse('wrong-source-byte', lambda: verify_catalog(source, first),
                           'independent complete UTF-8 source span selection'))
    first = copy.deepcopy(catalog); first['units']['value']['guard_calls'][0]['bytes'] = True
    rejected.append(refuse('Boolean-source-size', lambda: verify_catalog(source, first),
                           'source span genuine integer dimensions'))
    require(same(before, reader['members']()), 'all sealed source catalog members conserve after independent read')
    print(json.dumps(dict(role=reader['ROLE'], members=len(before),
        units=len(catalog['units']), named_functions=sum(len(r['named']) for r in catalog['units'].values()),
        selected_spans=len(catalog['qualified_lexical_spans']), controls=rejected), sort_keys=True))


if __name__ == '__main__':
    main()
