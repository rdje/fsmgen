"""Join retained public origin headers to the committed source alternatives."""
import argparse
import copy
import hashlib
import io
import json
import re
import subprocess
import tarfile
from pathlib import Path

BASE = Path('docs/audits/record-value-coordinate-public-origin-selection-20261007')
HYP = Path('docs/audits/record-value-coordinate-public-origin-hypotheses-20261007')
CAPTURE = Path('docs/audits/record-value-coordinate-public-capture-20261007')
CALLERS = Path('docs/audits/record-value-coordinate-public-caller-selection-20261007')
REVISION = 'b3b1bc6164b1a0ea0943d2399ad90de11ecad9de'
ROOTS = [HYP, Path('docs/audits/coordinate-public-origin-hypotheses-checks-20261007'),
         CAPTURE, Path('docs/audits/coordinate-public-capture-checks-20261007'),
         CALLERS, Path('docs/audits/coordinate-public-caller-selection-checks-20261007')]
ROLE = ('Dated finite own public origin-header selection only; exact retained fixture grammar. '
        'All raw bodies/frames/arguments remain intact. Public global/internal/formatter '
        'states and every original/private/formatter/toolchain identity remain unmeasured. '
        'Genuine executed native bad variants and original-coordinate intake remain pending.')
SUCCESS = 'PASS complete predeclared public origin joins and genuine candidate controls; native bad variants and original identities remain pending.\n'


def require(value, cause):
    if not value:
        raise ValueError(cause)


def pin(raw):
    return dict(bytes=len(raw), sha256=hashlib.sha256(raw).hexdigest())


def same(a, b):
    return json.dumps(a, sort_keys=True) == json.dumps(b, sort_keys=True)


def load(path):
    return json.loads(path.read_bytes())


def namespace(path):
    result = {'__name__': 'public_origin_dependency'}
    exec(compile(path.read_bytes(), str(path), 'exec'), result)
    return result


def binding():
    members = {}
    for root in ROOTS:
        paths = list(root.iterdir())
        require(all(p.is_file() and not p.is_symlink()
                    and p.stat().st_dev == Path.cwd().stat().st_dev for p in paths),
                'whole regular same-volume source/native/actual domain')
        raw = subprocess.check_output(['git', 'archive', REVISION, str(root)])
        with tarfile.open(fileobj=io.BytesIO(raw)) as archive:
            fixed = {m.name: archive.extractfile(m).read() for m in archive.getmembers() if m.isfile()}
        require({str(p): p.read_bytes() for p in paths} == fixed,
                'complete fixed committed source-hypothesis/native/actual members')
        members[str(root)] = {p: pin(raw) for p, raw in fixed.items()}
    task = subprocess.check_output(['git', 'show', REVISION + ':docs/tasks/SEMANTIC-INTROSPECTION-MCP-FRONTIER.md']).decode()
    owners = {}
    for root in (HYP, CAPTURE, CALLERS):
        owner = (root / 'scope.txt').read_text().splitlines()[0].removeprefix('Owner: ')
        a = task.index('- ID: `' + owner + '`'); b = task.index('\n- ID:', a + 1)
        owners[owner] = task[a:b]
        require('\n  Status: `done`\n' in owners[owner], 'complete committed completed prerequisite owners')
    return dict(revision=REVISION, members=members, owners=owners,
                task_identity=pin(task.encode()), role=ROLE)


def inputs():
    source = load(HYP / 'inputs.json')
    model = namespace(HYP / 'verify.py')
    require(same(model['derive'](source), load(HYP / 'hypotheses.json')),
            'complete committed source-only origin hypotheses')
    wire = load(CAPTURE / 'wire.json')
    capture = namespace(CAPTURE / 'verify.py')
    require(same(capture['derive'](wire), load(CAPTURE / 'custody.json')),
            'whole complete native public wire custody')
    return dict(source=source['source'], source_pins=source['source_pins'],
                hypotheses=load(HYP / 'hypotheses.json'), wire=wire, role=ROLE)


def origin(raw, declaration):
    require(type(raw) is str and raw.startswith(declaration['message']),
            'exact source-authored public origin message')
    message = declaration['message']
    # This finite grammar describes the retained fixtures only. Preserve every
    # byte before and after the header; do not normalize private trace bodies.
    match = re.match(r' at ([^\r\n]+) line ([1-9][0-9]*)\.\n', raw[len(message):])
    require(match is not None, 'exact retained public origin header grammar')
    filename, line = match.group(1), int(match.group(2))
    choices = []
    for alternative in declaration['alternatives']:
        labels = [name for name in ('first', 'closing')
                  if line == alternative['line_hypotheses'][name]]
        if filename in alternative['filename_hypotheses'] and labels:
            choices.append(dict(alternative=alternative, matching_line_labels=labels))
    stop = len(message) + match.end()
    return dict(filename=filename, line=line, matches=choices,
                outcome='selected' if choices else 'unresolved',
                unresolved=None if choices else declaration['unresolved'],
                raw=raw, raw_identity=pin(raw.encode()),
                message=message, raw_header=match.group(0), raw_body=raw[stop:])


def derive(candidate):
    require(candidate['role'] == ROLE, 'public origins cannot promote original or pending scope')
    fixed = load(HYP / 'inputs.json')
    require(same(candidate['source'], fixed['source'])
            and same(candidate['source_pins'], fixed['source_pins']),
            'whole independently fixed origin source identity')
    hypotheses = load(HYP / 'hypotheses.json')
    require(same(candidate['hypotheses'], hypotheses), 'whole precommitted unselected origin alternatives')
    require(len(candidate['wire']['runs']) == len(hypotheses['invocations']),
            'whole public origin invocation population')
    results = []
    for saved, invocation in zip(candidate['wire']['runs'], hypotheses['invocations']):
        actual = saved['actual']
        require(same(saved['invocation'], invocation) and actual['cwd'] == invocation['root']
                and actual['command'] == invocation['command'], 'exact legitimate origin invocation')
        require(type(actual['status']) is int and actual['status'] == 0, 'integer public origin actual success')
        for field in ('stdout', 'stderr'):
            require(type(actual[field]) is str and same(actual[field + '_identity'], pin(actual[field].encode())),
                    'whole public origin wire identity')
        payload = json.loads(actual['stdout'])
        require([r['role'] for r in payload['observations']] == [r['role'] for r in hypotheses['cases']],
                'whole source-declared public origin case allocation')
        cases = []
        for observed, declared in zip(payload['observations'], hypotheses['cases']):
            cases.append(dict(role=declared['role'], origins={stream: origin(observed[stream], declared['origins'][stream])
                         for stream in ('trace', 'guard_error')}))
        results.append(dict(invocation=invocation, cases=cases,
                            whole_raw_wire_identity=pin(actual['stdout'].encode())))
    return dict(runs=results, role=ROLE, configuration=hypotheses['configuration'])


def qualify(selected):
    require(all(row['outcome'] == 'selected' for run in selected['runs']
                for case in run['cases'] for row in case['origins'].values()),
            'public origin outside predeclared own statements remains unresolved')
    return selected


def changed_payload(candidate, mutate):
    actual = candidate['wire']['runs'][0]['actual']
    payload = json.loads(actual['stdout']); mutate(payload)
    actual['stdout'] = json.dumps(payload, sort_keys=True, separators=(',', ':')) + '\n'
    actual['stdout_identity'] = pin(actual['stdout'].encode())


def controls(original):
    cases = [
        ('wrong-origin-line', lambda c: changed_payload(c, lambda p: p['observations'][0].update(
            trace=p['observations'][0]['trace'].replace('line 31.', 'line 99999.', 1))),
         'public origin outside predeclared own statements remains unresolved'),
        ('borrowed-origin-file', lambda c: changed_payload(c, lambda p: p['observations'][5].update(
            trace=p['observations'][5]['trace'].replace('./load-body.pl', 'borrowed-body.pl', 1))),
         'public origin outside predeclared own statements remains unresolved'),
        ('wrong-origin-message', lambda c: changed_payload(c, lambda p: p['observations'][0].update(
            guard_error=p['observations'][0]['guard_error'].replace('public coordinate guard', 'public coordinate fixture', 1))),
         'exact source-authored public origin message'),
        ('normalized-header', lambda c: changed_payload(c, lambda p: p['observations'][1].update(
            trace=p['observations'][1]['trace'].replace('\n at ', '\n\tat ', 1))),
         'exact retained public origin header grammar'),
        ('lost-origin-case', lambda c: changed_payload(c, lambda p: p['observations'].pop()),
         'whole source-declared public origin case allocation'),
        ('borrowed-source', lambda c: c['source'].update({'fixture.pl': c['source']['load-body.pl']}),
         'whole independently fixed origin source identity'),
        ('premature-hypothesis', lambda c: c['hypotheses']['cases'][0]['origins']['trace'].update(selected='observer-call'),
         'whole precommitted unselected origin alternatives'),
        ('wrong-root', lambda c: c['wire']['runs'][0]['actual'].update(cwd='../foreign'),
         'exact legitimate origin invocation'),
        ('Boolean-status', lambda c: c['wire']['runs'][0]['actual'].update(status=False),
         'integer public origin actual success'),
        ('private-identity-promotion', lambda c: c.update(role='Original formatter and private coordinates measured.'),
         'public origins cannot promote original or pending scope'),
    ]
    rows = []
    for name, mutate, cause in cases:
        candidate = copy.deepcopy(original); mutate(candidate)
        require(not same(candidate, original), 'genuine public origin candidate')
        try:
            qualify(derive(candidate))
        except ValueError as error:
            require(str(error) == cause, 'intended public origin refusal: ' + name)
            rows.append(dict(control=name, status=1, cause=cause, complete_candidate=candidate))
        else:
            raise ValueError('false-green public origin control: ' + name)
    return rows


def members():
    require(all(p.is_file() and not p.is_symlink() for p in BASE.iterdir()), 'whole flat regular origin selection domain')
    return {p.name: pin(p.read_bytes()) for p in BASE.iterdir() if p.name != 'manifest.json'}


def save(name, value):
    path = BASE / name; raw = json.dumps(value, sort_keys=True, indent=2) + '\n'
    if path.exists():
        require(path.read_text() == raw, 'whole retained public origin product: ' + name)
    else:
        require(not (BASE / 'manifest.json').exists(), 'sealed public origin selection cannot publish')
        path.write_text(raw)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--seal', action='store_true'); args = parser.parse_args()
    if (BASE / 'manifest.json').exists():
        require(same(load(BASE / 'manifest.json'), members()), 'whole immutable public origin selection seal')
    before = binding(); save('binding.json', before)
    candidate = inputs(); save('inputs.json', candidate)
    save('selections.json', qualify(derive(candidate)))
    save('controls.json', controls(candidate))
    require(same(binding(), before), 'every complete original prerequisite member conserves')
    if args.seal:
        save('manifest.json', members())
    print(SUCCESS, end='')


if __name__ == '__main__':
    main()
