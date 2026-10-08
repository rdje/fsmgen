"""Reconstruct every saved semantic allocation from fixed Git and binary source."""
import copy
import hashlib
import io
import json
import re
import subprocess
import tarfile
from pathlib import Path

BASE = Path('docs/audits/coordinate-native-semantic-checks-20261008')
MODEL = Path('docs/audits/record-value-coordinate-native-semantic-20261008')
REVISION = '857ba30485c5a176263e6e5779779051294d6f23'
ROLE = ('Dated finite native semantic falsification only. Whole raw bytes and actual '
        'roots conserve; whole public qualification and every original/private/'
        'formatter/toolchain/address identity remain pending.')
SOURCE = 'docs/audits/record-value-coordinate-public-hypotheses-20261007/'
CALLERS = 'docs/audits/record-value-coordinate-public-caller-selection-20261007/'
ORIGINS = 'docs/audits/record-value-coordinate-public-origin-selection-20261007/'
PLANS = 'docs/audits/record-value-coordinate-native-control-plans-20261008/'
CAPTURE = 'docs/audits/record-value-coordinate-native-control-capture-20261008/'
GOOD = 'docs/audits/record-value-coordinate-public-capture-20261007/'
BOUNDARIES = {'block_eval': 'block-eval', 'anonymous_delegate': 'anonymous',
              'do_load': 'do-load', 'require_load': 'require-load', 'module_delegate': 'module-call'}


def need(value, cause):
    if not value:
        raise ValueError(cause)


def pin(raw):
    return dict(bytes=len(raw), sha256=hashlib.sha256(raw).hexdigest())


def same(a, b):
    return json.dumps(a, sort_keys=True) == json.dumps(b, sort_keys=True)


def read(path):
    return json.loads(path.read_bytes())


def source_lines(source, span):
    raw = source.encode('utf-8'); text = span['text'].encode('utf-8')
    need(raw.count(text) == 1, 'independent unique binary statement')
    start = raw.index(text)
    first = len(raw[:start].split(b'\n')); closing = len(raw[:start + len(text)].split(b'\n'))
    need(same(span, dict(offset_bytes=start, text=text.decode(), identity=pin(text),
                         first_line=first, closing_line=closing)), 'independent full binary span and LF allocation')
    return dict(first=first, closing=closing)


def frame(frame, declaration, filenames, source):
    alternatives = source_lines(source, declaration['source'])
    need(same(alternatives, declaration['line_hypotheses']), 'independent source-derived competing line alternatives')
    if frame[3] != declaration['callee']:
        cause = 'exact source-declared public caller target'
    elif type(frame[2]) is not int:
        cause = 'public coordinate must remain an integer line'
    elif frame[2] not in alternatives.values():
        cause = 'public line must select a predeclared lexical alternative'
    elif frame[1] not in filenames:
        cause = 'public filename must select a predeclared own source alternative'
    else:
        selected = dict(filename=frame[1], line=frame[2], callee=frame[3],
                        matching_line_labels=[key for key in ('first', 'closing') if alternatives[key] == frame[2]],
                        source=declaration['source'], raw_frame=frame)
        return dict(status='selected', selection=selected, refusal=None)
    return dict(status='refused', selection=None, refusal=cause)


def origin(raw, declared, sources):
    message = declared['message']; need(raw.startswith(message), 'independent source-authored origin message')
    rest = raw[len(message):]; header, separator, tail = rest.partition('\n')
    need(separator == '\n' and header.startswith(' at ') and header.endswith('.'), 'independent exact origin header boundary')
    filename, marker, numeral = header[4:-1].rpartition(' line ')
    need(marker == ' line ' and re.fullmatch('[1-9][0-9]*', numeral), 'independent exact origin line grammar')
    line = int(numeral); matches = []
    for choice in declared['alternatives']:
        alternatives = source_lines(sources[choice['unit']], choice['source'])
        need(same(alternatives, choice['line_hypotheses']), 'independent origin source line alternatives')
        labels = [key for key in ('first', 'closing') if alternatives[key] == line]
        if filename in choice['filename_hypotheses'] and labels:
            matches.append(dict(alternative=choice, matching_line_labels=labels))
    return dict(filename=filename, line=line, matches=matches,
                outcome='selected' if matches else 'unresolved', unresolved=None if matches else declared['unresolved'],
                raw=raw, raw_identity=pin(raw.encode()), message=message,
                raw_header=header + separator, raw_body=tail)


def coordinates(payload, inputs):
    hypotheses = inputs['hypotheses']; sources = inputs['good_source']
    need([r['role'] for r in payload['observations']] == [r['role'] for r in hypotheses['calls']],
         'independent whole public observation population')
    observed = {r['role']: r for r in payload['observations']}; calls = []
    for declared in hypotheses['calls']:
        index = declared['caller_frame_index']; raw = observed[declared['role']]['frames'][index]
        calls.append(dict(role=declared['role'], frame_index=index,
                          result=frame(raw, declared, declared['filename_hypotheses'], sources[declared['unit']])))
    boundaries = {}
    for name, role in BOUNDARIES.items():
        declared = hypotheses['boundaries'][name]; index = declared['caller_frame_index']
        boundaries[name] = dict(role=role, frame_index=index,
            result=frame(observed[role]['frames'][index], declared, [declared['filename']], sources['fixture.pl']))
    origins = []
    for declared in inputs['origins']['cases']:
        origins.append(dict(role=declared['role'], origins={
            field: origin(observed[declared['role']][field], declared['origins'][field], sources)
            for field in ('trace', 'guard_error')}))
    need(payload['module_filename'] == hypotheses['module_filename'], 'independent unchanged module filename')
    return dict(calls=calls, boundaries=boundaries, origins=origins, module_filename=payload['module_filename'])


def reconstruct(inputs):
    plans = inputs['plans']['plans']; wire = inputs['wire']
    need([r['name'] for r in wire['runs']] == [p['name'] for p in plans], 'independent whole native semantic allocation')
    positive = []
    for row, invocation in zip(inputs['good_wire']['runs'], inputs['hypotheses']['invocations']):
        need(same(row['invocation'], invocation) and row['actual']['cwd'] == invocation['root'], 'independent positive root')
        positive.append(dict(invocation=invocation, coordinates=coordinates(json.loads(row['actual']['stdout']), inputs),
                             raw_wire_identity=pin(row['actual']['stdout'].encode())))
    result = []
    for row, plan in zip(wire['runs'], plans):
        native = row['actual']; source = {p: raw.encode() for p, raw in inputs['good_source'].items()}
        if row['name'] == 'wrong-caller':
            source = {p: b'CoordinateBorrowed'.join(raw.split(b'CoordinatePublic')) for p, raw in source.items()}
        elif row['name'] == 'wrong-line':
            raw = source['fixture.pl']; start = raw.index(b"    observe('single'); # site single")
            source['fixture.pl'] = raw[:start] + b'\n' * 5 + raw[start:]
        elif row['name'] == 'borrowed-source':
            source['fixture.pl'] = source['fixture.pl'].replace(b"do './load-body.pl'", b"do './borrowed-body.pl'", 1)
            source['borrowed-body.pl'] = source.pop('load-body.pl')
        need(same(row['source'], {p: raw.decode() for p, raw in source.items()})
             and same(row['before'], {p: pin(raw) for p, raw in source.items()})
             and same(row['after'], row['before']) and same(plan['source'], row['source']),
             'independent complete variant source and census')
        need(type(native['status']) is int and native['status'] == 0, 'independent integer native status')
        need(same(row['invocation'], plan['invocation']) and native['cwd'] == plan['invocation']['root']
             and native['command'] == plan['invocation']['command'], 'independent actual control root and command')
        for field in ('stdout', 'stderr'):
            need(type(native[field]) is str and same(native[field + '_identity'], pin(native[field].encode())),
                 'independent entire native stream identity')
        allocation = coordinates(json.loads(native['stdout']), inputs); expected = plan['expected']
        unit = 'borrowed-body.pl' if row['name'] == 'borrowed-source' else 'fixture.pl'
        lines = source_lines(source[unit].decode(), expected['variant_statement'])
        need(expected['first_line'] == lines['first'] and expected['closing_line'] == lines['closing'],
             'independent variant target lexical lines')
        payload = json.loads(native['stdout']); observed = next(r for r in payload['observations'] if r['role'] == expected['role'])
        raw = observed['frames'][expected['frame_index']]
        need(raw[2] in lines.values() and raw[1] == expected['filename'] and raw[3] == expected['caller'],
             'independent actual source-selected target frame')
        target = next(c['result'] for c in allocation['calls'] if c['role'] == expected['role'])
        base = plan['base_invocation']
        admitted = same(row['invocation'], base) and native['cwd'] == base['root'] and native['command'] == base['command']
        root = dict(status='selected', selection=dict(invocation=base), refusal=None) if admitted else dict(
            status='refused', selection=None, refusal='exact legitimate public selection invocation')
        refusal = root if row['name'] == 'wrong-root' else target
        need(refusal['status'] == 'refused' and refusal['refusal'] == expected['refusal'], 'independent exact expected native refusal')
        if row['name'] == 'wrong-root':
            need(all(c['result']['status'] == 'selected' for c in allocation['calls'])
                 and all(c['result']['status'] == 'selected' for c in allocation['boundaries'].values())
                 and all(o['outcome'] == 'selected' for c in allocation['origins'] for o in c['origins'].values()),
                 'independent whole positive wrong-root coordinates')
        result.append(dict(name=row['name'], invocation=row['invocation'], source=plan['source'], expected=expected,
                           target_frame=raw, target_result=target, base_root_admission=root,
                           intended_refusal=refusal['refusal'], coordinates=allocation, actual=native,
                           environment=row['environment'], before=row['before'], after=row['after']))
    return dict(runs=result, positive_comparisons=positive, role=ROLE)


def check(product, expected):
    need(product['role'] == ROLE, 'independent semantic scope cannot promote identities')
    need([r['name'] for r in product['runs']] == [r['name'] for r in expected['runs']], 'independent complete semantic run population')
    need(all(type(r['actual']['status']) is int and r['actual']['status'] == 0 for r in product['runs']),
         'independent semantic status remains integer success')
    need(same(product, expected), 'independent whole binary-source and wire semantic reconstruction')


def receipt(name, command, stdout):
    row = read(BASE / name)
    paths = [BASE / 'run.py', Path('scripts/run_with_ram_guard.sh')]
    paths.extend(Path(arg) for arg in command if arg.startswith(('docs/', 'scripts/', 't/')) and Path(arg).is_file())
    need(row['command'] == ['scripts/run_with_ram_guard.sh', '--', *command]
         and type(row['status']) is int and row['status'] == 0 and row['stdout'] == stdout
         and same(row['instruments'], {str(p): pin(p.read_bytes()) for p in paths})
         and re.fullmatch(r'ram-guard: PID \d+; host [0-9.]+%; host cutoff 88%; descendant RSS cutoff 4096 MiB; poll 2s\n', row['stderr']),
         'independent whole actual result and instruments: ' + name)


def main():
    members = {p.name: pin(p.read_bytes()) for p in MODEL.iterdir() if p.name != 'manifest.json'}
    need(all(p.is_file() and not p.is_symlink() and p.stat().st_dev == Path.cwd().stat().st_dev for p in MODEL.iterdir())
         and same(members, read(MODEL / 'manifest.json')), 'independent whole immutable semantic seal')
    binding = read(MODEL / 'binding.json')
    names = subprocess.check_output(['git', 'ls-tree', '-z', '--name-only', REVISION + ':docs/audits']).split(b'\0')
    roots = ['docs/audits/' + n.decode() for n in names if n.startswith(
        (b'record-value-coordinate-', b'coordinate-public-', b'coordinate-native-control-'))]
    need(binding['roots'] == roots and binding['revision'] == REVISION, 'independent complete committed prerequisite census')
    archive = subprocess.check_output(['git', 'archive', REVISION, *roots])
    with tarfile.open(fileobj=io.BytesIO(archive)) as source:
        fixed = {m.name: source.extractfile(m).read() for m in source.getmembers() if m.isfile()}
    need(fixed == {str(p): p.read_bytes() for root in roots for p in Path(root).iterdir()}
         and same(binding['members'], {p: pin(raw) for p, raw in fixed.items()}), 'independent complete fixed prerequisite bytes')
    task = subprocess.check_output(['git', 'show', REVISION + ':docs/tasks/SEMANTIC-INTROSPECTION-MCP-FRONTIER.md'])
    owners = {}
    for root in roots:
        if '/record-value-' not in root:
            continue
        owner = fixed[root + '/scope.txt'].decode().splitlines()[0].removeprefix('Owner: ')
        suffix = task.decode().split('- ID: `' + owner + '`', 1)[1].split('\n- ID:', 1)[0]
        need('\n  Status: `done`\n' in suffix, 'independent completed full prerequisite owner')
        owners[owner] = '- ID: `' + owner + '`' + suffix
    need(same(binding['owners'], owners) and same(binding['task_identity'], pin(task))
         and binding['role'] == ROLE, 'independent whole committed owner and scope binding')
    inputs = read(MODEL / 'inputs.json')
    expected_inputs = dict(good_source=json.loads(fixed[SOURCE + 'inputs.json'])['source'],
        hypotheses=json.loads(fixed[SOURCE + 'hypotheses.json']), origins=json.loads(fixed[ORIGINS + 'inputs.json'])['hypotheses'],
        plans=json.loads(fixed[PLANS + 'plans.json']), wire=json.loads(fixed[CAPTURE + 'wire.json']),
        good_wire=json.loads(fixed[GOOD + 'wire.json']), role=ROLE)
    need(same(inputs, expected_inputs), 'independent entire fixed input authority')
    expected = reconstruct(inputs); product = read(MODEL / 'qualification.json'); check(product, expected)
    receipt('semantic.json', ['python3', '-B', str(MODEL / 'verify.py'), '--seal'],
            'PASS complete retained native semantic refusals, positive wrong-root coordinates and genuine controls; no capture executes.\n')
    prior = Path('docs/audits/coordinate-native-control-capture-checks-20261008/verify_saved.py')
    receipt('prerequisite-approved.json', ['python3', '-B', str(prior)],
            json.loads(fixed['docs/audits/coordinate-native-control-capture-checks-20261008/saved-result.json'])['stdout'])
    controls = []
    cases = [
        ('lost-run', lambda c: c['runs'].pop(), 'independent complete semantic run population'),
        ('Boolean-status', lambda c: c['runs'][0]['actual'].update(status=False), 'independent semantic status remains integer success'),
        ('lost-refusal', lambda c: c['runs'][0].update(intended_refusal=None), 'independent whole binary-source and wire semantic reconstruction'),
        ('borrowed-source', lambda c: c['runs'][3]['source'].update({'borrowed-body.pl': '1;\n'}), 'independent whole binary-source and wire semantic reconstruction'),
        ('wrong-root-false-coordinate', lambda c: c['runs'][2]['coordinates']['calls'][0]['result'].update(status='refused'), 'independent whole binary-source and wire semantic reconstruction'),
        ('root-refusal-loss', lambda c: c['runs'][2]['base_root_admission'].update(refusal=None), 'independent whole binary-source and wire semantic reconstruction'),
        ('whole-public-promotion', lambda c: c.update(role='Original and whole public qualify.'), 'independent semantic scope cannot promote identities'),
    ]
    for name, mutate, cause in cases:
        candidate = copy.deepcopy(product); mutate(candidate)
        need(not same(candidate, product), 'genuine independent semantic mutation')
        try:
            check(candidate, expected)
        except ValueError as error:
            need(str(error) == cause, 'intended independent semantic refusal: ' + name)
            controls.append(dict(control=name, status=1, cause=cause, candidate=candidate))
        else:
            raise ValueError('false-green independent semantic control: ' + name)
    producer = {'__name__': 'native_semantic_producer_controls'}
    exec(compile((MODEL / 'verify.py').read_bytes(), str(MODEL / 'verify.py'), 'exec'), producer)
    need(same(producer['controls'](inputs), read(MODEL / 'controls.json')), 'entire producer candidate controls reproduce')
    proof = dict(members=members, controls=controls, scope=ROLE,
                 prerequisite_members=len(fixed), reconstruction_identity=pin(json.dumps(expected, sort_keys=True).encode()))
    path = BASE / 'proof.json'; raw = json.dumps(proof, sort_keys=True, indent=2) + '\n'
    if path.exists():
        need(path.read_text() == raw, 'whole retained independent semantic proof')
    else:
        path.write_text(raw)
    print('PASS independent complete binary-source/native-wire semantic refusals and positive wrong-root coordinates; no original identity or whole-public promotion.')


if __name__ == '__main__':
    main()
