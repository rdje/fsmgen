"""Select only predeclared public caller/boundary coordinate alternatives."""
import argparse
import copy
import hashlib
import io
import json
import subprocess
import tarfile
from pathlib import Path

BASE = Path('docs/audits/record-value-coordinate-public-caller-selection-20261007')
SOURCE = Path('docs/audits/record-value-coordinate-public-hypotheses-20261007')
CAPTURE = Path('docs/audits/record-value-coordinate-public-capture-20261007')
REVISION = '3ae29914b6a74f4009a52b6c9e8136f2bd471039'
ROOTS = [SOURCE, Path('docs/audits/coordinate-public-hypotheses-checks-20261007'),
         CAPTURE, Path('docs/audits/coordinate-public-capture-checks-20261007')]
BOUNDARIES = {'block_eval':'block-eval', 'anonymous_delegate':'anonymous',
              'do_load':'do-load', 'require_load':'require-load', 'module_delegate':'module-call'}
ROLE = ('Dated finite own public caller/boundary coordinate selection only. '
        'Whole raw public wire is conserved; trace/confess origins and genuine native '
        'semantic controls remain pending. No original/private/formatter/toolchain '
        'identity or original-coordinate meaning is qualified.')
SUCCESS = 'PASS complete predeclared public caller/boundary selections and genuine candidate controls; origins and native semantic controls remain pending.\n'


def require(value, cause):
    if not value:
        raise ValueError(cause)


def pin(raw):
    return dict(bytes=len(raw), sha256=hashlib.sha256(raw).hexdigest())


def same(a, b):
    return json.dumps(a, sort_keys=True) == json.dumps(b, sort_keys=True)


def load(path):
    return json.loads(path.read_bytes())


def module(path):
    namespace = {'__name__': 'public_caller_selection_dependency'}
    exec(compile(path.read_bytes(), str(path), 'exec'), namespace)
    return namespace


def binding():
    result = {}
    for root in ROOTS:
        current_paths = list(root.iterdir())
        require(all((p.is_file() and (not p.is_symlink()) for p in current_paths)), 'complete flat regular public source/capture domain')
        raw = subprocess.check_output(['git', 'archive', REVISION, str(root)])
        with tarfile.open(fileobj=io.BytesIO(raw)) as archive:
            committed = {m.name: archive.extractfile(m).read() for m in archive.getmembers() if m.isfile()}
        require({str(p): p.read_bytes() for p in current_paths} == committed, 'complete fixed committed public source/capture/programme/actual domain')
        result[str(root)] = {p: pin(raw) for p, raw in committed.items()}
    task = subprocess.check_output(['git', 'show', REVISION + ':docs/tasks/SEMANTIC-INTROSPECTION-MCP-FRONTIER.md']).decode()
    owners = {}
    for root in (SOURCE, CAPTURE):
        owner = (root / 'scope.txt').read_text().splitlines()[0].removeprefix('Owner: ')
        a = task.index('- ID: `' + owner + '`')
        b = task.index('\n- ID:', a + 1)
        owners[owner] = task[a:b]
        require('\n  Status: `done`\n' in owners[owner], 'complete committed completed source and capture owners')
    return dict(revision=REVISION, members=result, owners=owners, task_identity=pin(task.encode()), role=ROLE)


def inputs():
    source = load(SOURCE / 'inputs.json')
    public = module(SOURCE / 'verify.py')
    hypotheses = public['derive'](source)
    require(same(hypotheses, load(SOURCE / 'hypotheses.json')), 'complete committed unselected coordinate hypotheses')
    wire = load(CAPTURE / 'wire.json')
    custody = module(CAPTURE / 'verify.py')
    require(same(custody['derive'](wire), load(CAPTURE / 'custody.json')), 'complete independently qualified native public wire custody')
    return dict(source=source['source'], source_pins=source['source_pins'], hypotheses=hypotheses, wire=wire, role=ROLE)


def frame_selection(frame, declaration, filenames):
    require(type(frame) is list and len(frame) == 8 and (frame[3] == declaration['callee']), 'exact source-declared public caller target')
    require(type(frame[2]) is int, 'public coordinate must remain an integer line')
    alternatives = declaration['line_hypotheses']
    labels = [label for label in ('first', 'closing') if frame[2] == alternatives[label]]
    require(labels, 'public line must select a predeclared lexical alternative')
    require(frame[1] in filenames, 'public filename must select a predeclared own source alternative')
    return dict(filename=frame[1], line=frame[2], callee=frame[3], matching_line_labels=labels, source=declaration['source'], raw_frame=frame)


def derive(candidate):
    require(candidate['role'] == ROLE, 'finite public selection cannot promote original or pending meanings')
    fixed_source = load(SOURCE / 'inputs.json')
    fixed_hypotheses = load(SOURCE / 'hypotheses.json')
    require(same(candidate['source'], fixed_source['source']) and same(candidate['source_pins'], fixed_source['source_pins']), 'complete independently fixed source identity')
    require(same(candidate['hypotheses'], fixed_hypotheses), 'whole pre-native unselected hypothesis identity')
    calls = fixed_hypotheses['calls']
    boundaries = fixed_hypotheses['boundaries']
    wire = candidate['wire']
    require(len(wire['runs']) == len(fixed_hypotheses['invocations']), 'complete public invocation selection population')
    products = []
    for saved, invocation in zip(wire['runs'], fixed_hypotheses['invocations']):
        require(same(saved['invocation'], invocation) and saved['actual']['cwd'] == invocation['root'] and (saved['actual']['command'] == invocation['command']), 'exact legitimate public selection invocation')
        require(type(saved['actual']['status']) is int and saved['actual']['status'] == 0, 'integer public selection actual success')
        for field in ('stdout', 'stderr'):
            require(same(saved['actual'][field + '_identity'], pin(saved['actual'][field].encode())), 'complete candidate public wire byte identity')
        payload = json.loads(saved['actual']['stdout'])
        require([r['role'] for r in payload['observations']] == [r['role'] for r in calls], 'whole source-declared public call allocation')
        observed = {r['role']: r for r in payload['observations']}
        selected_calls = []
        for declaration in calls:
            frames = observed[declaration['role']]['frames']
            index = declaration['caller_frame_index']
            require(len(frames) > index, 'complete source-declared public caller frame')
            selected_calls.append(dict(role=declaration['role'], frame_index=index, selection=frame_selection(frames[index], declaration, declaration['filename_hypotheses'])))
        selected_boundaries = {}
        require(set(boundaries) == set(BOUNDARIES), 'complete independent own boundary allocation')
        for name, role in BOUNDARIES.items():
            declaration = boundaries[name]
            frames = observed[role]['frames']
            index = declaration['caller_frame_index']
            require(len(frames) > index, 'complete source-declared public boundary frame')
            selected_boundaries[name] = dict(role=role, frame_index=index, selection=frame_selection(frames[index], declaration, [declaration['filename']]))
        require(payload['module_filename'] == fixed_hypotheses['module_filename'], 'source-declared public module filename accessor')
        products.append(dict(invocation=invocation, calls=selected_calls, boundaries=selected_boundaries, whole_raw_wire_identity=pin(saved['actual']['stdout'].encode()), module_filename=payload['module_filename']))
    return dict(runs=products, role=ROLE)


def changed_payload(candidate, mutate):
    row = candidate['wire']['runs'][0]['actual']
    payload = json.loads(row['stdout'])
    mutate(payload)
    row['stdout'] = json.dumps(payload, sort_keys=True, separators=(',', ':')) + '\n'
    row['stdout_identity'] = pin(row['stdout'].encode())


def controls(original):
    cases=[
        ('wrong-caller',lambda c:changed_payload(c,lambda p:p['observations'][0]['frames'][1].__setitem__(3,'Borrowed::observe')), 'exact source-declared public caller target'),
        ('wrong-line',lambda c:changed_payload(c,lambda p:p['observations'][1]['frames'][1].__setitem__(2,99999)), 'public line must select a predeclared lexical alternative'),
        ('Boolean-line',lambda c:changed_payload(c,lambda p:p['observations'][0]['frames'][1].__setitem__(2,True)), 'public coordinate must remain an integer line'),
        ('borrowed-filename',lambda c:changed_payload(c,lambda p:p['observations'][5]['frames'][1].__setitem__(1,'borrowed-body.pl')), 'public filename must select a predeclared own source alternative'),
        ('wrong-boundary-caller',lambda c:changed_payload(c,lambda p:p['observations'][3]['frames'][2].__setitem__(3,'Borrowed::eval')), 'exact source-declared public caller target'),
        ('lost-call',lambda c:changed_payload(c,lambda p:p['observations'].pop()), 'whole source-declared public call allocation'),
        ('wrong-root',lambda c:c['wire']['runs'][0]['actual'].update(cwd='../foreign'), 'exact legitimate public selection invocation'),
        ('borrowed-source',lambda c:c['source'].update({'fixture.pl':c['source']['load-body.pl']}), 'complete independently fixed source identity'),
        ('lost-hypothesis',lambda c:c['hypotheses']['boundaries'].pop('module_delegate'), 'whole pre-native unselected hypothesis identity'),
        ('Boolean-status',lambda c:c['wire']['runs'][0]['actual'].update(status=False), 'integer public selection actual success'),
        ('original-identity-promotion',lambda c:c.update(role='Original and formatter coordinate identities are measured.'), 'finite public selection cannot promote original or pending meanings'),
    ]
    rows=[]
    for name,mutate,cause in cases:
        candidate = copy.deepcopy(original)
        mutate(candidate)
        require(not same(candidate,original), 'genuine public selection candidate control')
        try:
            derive(candidate)
        except ValueError as error:
            require(str(error)==cause, 'intended public coordinate candidate refusal: '+name)
            rows.append(dict(control=name,status=1,cause=cause,complete_candidate=candidate))
        else:
            raise ValueError('false-green public coordinate candidate control: ' + name)
    return rows


def members():
    require(all((p.is_file() and (not p.is_symlink()) for p in BASE.iterdir())), 'whole regular flat public selection member domain')
    return {p.name: pin(p.read_bytes()) for p in BASE.iterdir() if p.name != 'manifest.json'}


def save(name, value):
    path = BASE / name
    raw = json.dumps(value, sort_keys=True, indent=2) + '\n'
    if path.exists():
        require(path.read_text() == raw, 'whole retained public selection product: ' + name)
    else:
        require(not (BASE / 'manifest.json').exists(), 'sealed public selection cannot publish')
        path.write_text(raw)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--seal', action='store_true')
    args = parser.parse_args()
    if (BASE / 'manifest.json').exists():
        require(same(load(BASE / 'manifest.json'), members()), 'whole immutable public caller selection seal')
    before = binding()
    save('binding.json', before)
    candidate = inputs()
    save('inputs.json', candidate)
    save('selections.json', derive(candidate))
    save('controls.json', controls(candidate))
    require(same(binding(), before), 'every complete source/native prerequisite conserves')
    if args.seal:
        save('manifest.json', members())
    print(SUCCESS, end='')


if __name__ == '__main__':
    main()
