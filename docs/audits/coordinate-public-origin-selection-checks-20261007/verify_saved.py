"""Rebuild every origin by matching exact source-built headers, without the parser."""
import copy
import hashlib
import io
import json
import re
import subprocess
import tarfile
from pathlib import Path

BASE = Path('docs/audits/coordinate-public-origin-selection-checks-20261007')
MODEL = Path('docs/audits/record-value-coordinate-public-origin-selection-20261007')
HYP = Path('docs/audits/record-value-coordinate-public-origin-hypotheses-20261007')
CAPTURE = Path('docs/audits/record-value-coordinate-public-capture-20261007')
CALLERS = Path('docs/audits/record-value-coordinate-public-caller-selection-20261007')
REVISION = 'b3b1bc6164b1a0ea0943d2399ad90de11ecad9de'
ROOTS = [HYP, Path('docs/audits/coordinate-public-origin-hypotheses-checks-20261007'),
         CAPTURE, Path('docs/audits/coordinate-public-capture-checks-20261007'),
         CALLERS, Path('docs/audits/coordinate-public-caller-selection-checks-20261007')]


def need(value, cause):
    if not value:
        raise ValueError(cause)


def pin(raw):
    return dict(bytes=len(raw), sha256=hashlib.sha256(raw).hexdigest())


def same(a, b):
    return json.dumps(a, sort_keys=True) == json.dumps(b, sort_keys=True)


def data(path):
    return json.loads(path.read_bytes())


def namespace(path):
    result = {'__name__': 'independent_origin_selection'}
    exec(compile(path.read_bytes(), str(path), 'exec'), result)
    return result


def source_lines(alternative, sources):
    raw = sources[alternative['unit']].encode('utf-8')
    span = alternative['source']; text = span['text'].encode('utf-8'); offset = span['offset_bytes']
    need(type(offset) is int and offset >= 0 and raw[offset:offset + len(text)] == text
         and span['identity'] == pin(text), 'independent whole binary origin source statement')
    lines = dict(first=raw[:offset].count(b'\n') + 1,
                 closing=raw[:offset + len(text)].count(b'\n') + 1)
    need(same(lines, alternative['line_hypotheses'])
         and type(span['first_line']) is int and type(span['closing_line']) is int
         and span['first_line'] == lines['first'] and span['closing_line'] == lines['closing'],
         'independent exact source byte/LF origin alternatives')
    return lines


def rebuilt_origin(raw, declaration, sources):
    # Enumerate exact headers from complete independently verified own source
    # alternatives. This does not call or reuse the producer's origin parser.
    headers = {}
    for alternative in declaration['alternatives']:
        lines = source_lines(alternative, sources)
        for filename in alternative['filename_hypotheses']:
            for number in dict.fromkeys(lines.values()):
                header = declaration['message'] + ' at ' + filename + ' line ' + str(number) + '.\n'
                labels = [name for name in ('first', 'closing') if lines[name] == number]
                headers.setdefault(header, dict(filename=filename, line=number, matches=[]))['matches'].append(
                    dict(alternative=alternative, matching_line_labels=labels))
    matching = [header for header in headers if type(raw) is str and raw.startswith(header)]
    need(len(matching) == 1, 'independent exact own source-built public origin header')
    header = matching[0]; choice = headers[header]; message = declaration['message']
    return dict(**choice, outcome='selected', unresolved=None, raw=raw, raw_identity=pin(raw.encode()),
                message=message, raw_header=header[len(message):], raw_body=raw[len(header):])


def reconstruct(inputs, fixed):
    source = json.loads(fixed[str(HYP / 'inputs.json')])
    hypotheses = json.loads(fixed[str(HYP / 'hypotheses.json')])
    wire = json.loads(fixed[str(CAPTURE / 'wire.json')])
    need(same(inputs['source'], source['source']) and same(inputs['source_pins'], source['source_pins'])
         and same(inputs['hypotheses'], hypotheses) and same(inputs['wire'], wire),
         'whole independently fixed source/hypothesis/raw-wire origin input')
    runs = []
    need(len(wire['runs']) == len(hypotheses['invocations']), 'complete independent origin invocation allocation')
    for saved, invocation in zip(wire['runs'], hypotheses['invocations']):
        need(same(saved['invocation'], invocation), 'independent exact origin root recipe')
        payload = json.loads(saved['actual']['stdout'])
        need([r['role'] for r in payload['observations']] == [r['role'] for r in hypotheses['cases']],
             'complete independent source/raw origin role allocation')
        cases = []
        for observed, declared in zip(payload['observations'], hypotheses['cases']):
            cases.append(dict(role=declared['role'], origins={field: rebuilt_origin(
                observed[field], declared['origins'][field], source['source']) for field in ('trace', 'guard_error')}))
        runs.append(dict(invocation=invocation, cases=cases,
                         whole_raw_wire_identity=pin(saved['actual']['stdout'].encode())))
    return dict(runs=runs, role=inputs['role'], configuration=hypotheses['configuration'])


def check_selected(candidate, expected):
    for run in candidate['runs']:
        for case in run['cases']:
            for origin in case['origins'].values():
                need(type(origin['line']) is int, 'selected public origin lines retain integer kind')
                need(origin['raw'] == origin['message'] + origin['raw_header'] + origin['raw_body']
                     and origin['raw_identity'] == pin(origin['raw'].encode()),
                     'whole unnormalized selected public origin byte partition')
    need(same(candidate, expected), 'whole independent origin source/raw allocation and unresolved scope')


def actual(row, command, stdout):
    need(row['command'] == ['scripts/run_with_ram_guard.sh', '--', *command]
         and type(row['status']) is int and row['status'] == 0 and row['stdout'] == stdout,
         'whole actual origin command integer success and stdout')
    need(re.fullmatch(r'ram-guard: PID \d+; host [0-9.]+%; host cutoff 88%; descendant RSS cutoff 4096 MiB; poll 2s\n', row['stderr']),
         'whole unchanged origin guard stderr')
    paths = [BASE / 'run.py', Path('scripts/run_with_ram_guard.sh')]
    paths.extend(Path(arg) for arg in command if arg.startswith(('docs/', 'scripts/', 't/')) and Path(arg).is_file())
    need(same(row['instruments'], {str(p): pin(p.read_bytes()) for p in paths}),
         'all complete actual origin producing instruments')


def main():
    paths = list(MODEL.iterdir())
    need(all(p.is_file() and not p.is_symlink() and p.stat().st_dev == Path.cwd().stat().st_dev for p in paths),
         'whole regular same-volume origin selection seal domain')
    members = {p.name: pin(p.read_bytes()) for p in paths if p.name != 'manifest.json'}
    need(same(members, data(MODEL / 'manifest.json')), 'whole independent origin selection seal')
    archived = subprocess.check_output(['git', 'archive', REVISION, *map(str, ROOTS)])
    with tarfile.open(fileobj=io.BytesIO(archived)) as archive:
        fixed = {m.name: archive.extractfile(m).read() for m in archive.getmembers() if m.isfile()}
    need(set(fixed) == {str(p) for root in ROOTS for p in root.iterdir()}
         and all(Path(p).read_bytes() == raw for p, raw in fixed.items()),
         'whole independent fixed Git source/native/actual membership and bytes')
    binding = data(MODEL / 'binding.json')
    need(same({p: identity for root in binding['members'].values() for p, identity in root.items()},
              {p: pin(raw) for p, raw in fixed.items()}) and binding['revision'] == REVISION,
         'whole independent fixed origin binding members')
    task = subprocess.check_output(['git', 'show', REVISION + ':docs/tasks/SEMANTIC-INTROSPECTION-MCP-FRONTIER.md'])
    owners = {}
    for root in (HYP, CAPTURE, CALLERS):
        owner = fixed[str(root / 'scope.txt')].decode().splitlines()[0].removeprefix('Owner: ')
        text = task.decode(); start = text.index('- ID: `' + owner + '`'); stop = text.index('\n- ID:', start + 1)
        owners[owner] = text[start:stop]
        need('\n  Status: `done`\n' in owners[owner], 'complete independent committed done prerequisite owner')
    need(same(binding['owners'], owners) and binding['task_identity'] == pin(task),
         'whole exact prerequisite owner bodies and committed task identity')
    producer = namespace(MODEL / 'verify.py')
    need(same(binding, producer['binding']()), 'complete producing origin binding agrees')
    inputs = data(MODEL / 'inputs.json'); expected = reconstruct(inputs, fixed)
    need(same(expected, producer['qualify'](producer['derive'](inputs))),
         'independent exact source-built header selection agrees with complete producer')
    check_selected(data(MODEL / 'selections.json'), expected)
    need(same(producer['controls'](inputs), data(MODEL / 'controls.json')), 'all full genuine origin candidate inputs and refusals')
    actual(data(BASE / 'seal.json'), ['python3', '-B', str(MODEL / 'verify.py'), '--seal'], producer['SUCCESS'])
    prior = json.loads(fixed['docs/audits/coordinate-public-origin-hypotheses-checks-20261007/saved-result.json'])['stdout']
    actual(data(BASE / 'prerequisite.json'), ['python3', '-B', str(ROOTS[1] / 'verify_saved.py')], prior)
    mutations = [
        ('Boolean-origin-line', lambda c: c['runs'][0]['cases'][5]['origins']['trace'].update(line=True),
         'selected public origin lines retain integer kind'),
        ('false-closing-origin', lambda c: c['runs'][0]['cases'][1]['origins']['trace'].update(line=37),
         'whole independent origin source/raw allocation and unresolved scope'),
        ('lost-equivalent-label', lambda c: c['runs'][0]['cases'][0]['origins']['guard_error']['matches'][0]['matching_line_labels'].pop(),
         'whole independent origin source/raw allocation and unresolved scope'),
        ('lost-private-body-bytes', lambda c: c['runs'][1]['cases'][-1]['origins']['trace'].update(raw_body=''),
         'whole unnormalized selected public origin byte partition'),
        ('borrowed-origin-allocation', lambda c: c['runs'][0]['cases'][0]['origins'].update(trace=c['runs'][0]['cases'][0]['origins']['guard_error']),
         'whole independent origin source/raw allocation and unresolved scope'),
        ('configuration-promotion', lambda c: c.update(configuration='Original public formatter states are measured.'),
         'whole independent origin source/raw allocation and unresolved scope'),
    ]
    controls = []
    for name, mutate, cause in mutations:
        candidate = copy.deepcopy(expected); mutate(candidate)
        need(not same(candidate, expected), 'genuine independent origin result control')
        try:
            check_selected(candidate, expected)
        except ValueError as error:
            need(str(error) == cause, 'intended independent origin result refusal')
            controls.append(dict(control=name, status=1, cause=cause))
        else:
            raise ValueError('false-green independent origin result control')
    changed = copy.deepcopy(inputs)
    row = changed['wire']['runs'][0]['actual']
    payload = json.loads(row['stdout']); payload['observations'][-1]['trace'] += 'borrowed private body\n'
    row['stdout'] = json.dumps(payload, sort_keys=True, separators=(',', ':')) + '\n'
    row['stdout_identity'] = pin(row['stdout'].encode())
    need(not same(changed, inputs), 'genuine complete raw-body input mutation')
    try:
        reconstruct(changed, fixed)
    except ValueError as error:
        need(str(error) == 'whole independently fixed source/hypothesis/raw-wire origin input',
             'intended complete native raw-body substitution refusal')
        controls.append(dict(control='forged-raw-body-with-new-hash', status=1, cause=str(error)))
    else:
        raise ValueError('false-green complete native raw-body input')
    need(same(members, {p.name: pin(p.read_bytes()) for p in MODEL.iterdir() if p.name != 'manifest.json'}),
         'every complete source/raw/selected/control member conserves')
    print(json.dumps(dict(members=len(members), runs=len(expected['runs']),
                         origins_per_run=[sum(len(c['origins']) for c in r['cases']) for r in expected['runs']],
                         controls=controls, scope=producer['ROLE']), sort_keys=True))


if __name__ == '__main__':
    main()
