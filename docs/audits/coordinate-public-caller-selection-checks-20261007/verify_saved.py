"""Reconstruct every saved public selection from fixed Git bytes and raw wire."""
import copy
import hashlib
import io
import json
import re
import subprocess
import tarfile
from pathlib import Path

BASE = Path('docs/audits/coordinate-public-caller-selection-checks-20261007')
SELECT = Path('docs/audits/record-value-coordinate-public-caller-selection-20261007')
SOURCE = Path('docs/audits/record-value-coordinate-public-hypotheses-20261007')
CAPTURE = Path('docs/audits/record-value-coordinate-public-capture-20261007')
REVISION = '3ae29914b6a74f4009a52b6c9e8136f2bd471039'


def need(value, cause):
    if not value:
        raise ValueError(cause)


def pin(raw):
    return dict(bytes=len(raw), sha256=hashlib.sha256(raw).hexdigest())


def same(left, right):
    return json.dumps(left, sort_keys=True) == json.dumps(right, sort_keys=True)


def data(path):
    return json.loads(path.read_bytes())


def namespace(path):
    result = {'__name__':'independent_public_selection_dependency'}
    exec(compile(path.read_bytes(), str(path), 'exec'), result)
    return result


def source_span(declaration, raw):
    span = declaration['source']
    offset = span['offset_bytes']
    encoded = span['text'].encode('utf-8')
    need(type(offset) is int and offset >= 0 and raw[offset:offset+len(encoded)] == encoded,
         'independent exact binary source span')
    opening = raw[:offset].count(b'\n') + 1
    closing = raw[:offset+len(encoded)].count(b'\n') + 1
    need(type(span['first_line']) is int and type(span['closing_line']) is int
         and span['first_line'] == opening and span['closing_line'] == closing
         and span['identity'] == pin(encoded), 'independent complete byte/LF lexical alternatives')
    return opening, closing


def frame(frame, declaration, source, filenames):
    opening, closing = source_span(declaration, source)
    need(type(frame[2]) is int and frame[2] in (opening, closing)
         and frame[3] == declaration['callee'] and frame[1] in filenames,
         'independent source-selected public frame coordinate')
    labels = []
    if frame[2] == opening:
        labels.append('first')
    if frame[2] == closing:
        labels.append('closing')
    return dict(source=declaration['source'], raw_frame=frame, filename=frame[1],
                line=frame[2], callee=frame[3], matching_line_labels=labels)


def reconstruct(inputs, committed):
    fixed_inputs = json.loads(committed[str(SOURCE/'inputs.json')])
    hypotheses = json.loads(committed[str(SOURCE/'hypotheses.json')])
    wire = json.loads(committed[str(CAPTURE/'wire.json')])
    need(same(inputs['source'], fixed_inputs['source']) and same(inputs['source_pins'], fixed_inputs['source_pins'])
         and same(inputs['hypotheses'], hypotheses) and same(inputs['wire'], wire),
         'whole independently fixed source hypothesis and untouched native capture input')
    relations = [('block_eval','block-eval'), ('anonymous_delegate','anonymous'),
                 ('do_load','do-load'), ('require_load','require-load'), ('module_delegate','module-call')]
    results = []
    for observed in wire['runs']:
        payload = json.loads(observed['actual']['stdout'])
        observations = {row['role']:row for row in payload['observations']}
        calls = []
        boundaries = {}
        for declaration in hypotheses['calls']:
            raw = fixed_inputs['source'][declaration['unit']].encode('utf-8')
            index = declaration['caller_frame_index']
            selected = frame(observations[declaration['role']]['frames'][index], declaration,
                             raw, declaration['filename_hypotheses'])
            calls.append(dict(role=declaration['role'], frame_index=index, selection=selected))
        for name, role in relations:
            declaration = hypotheses['boundaries'][name]
            index = declaration['caller_frame_index']
            selected = frame(observations[role]['frames'][index], declaration,
                             fixed_inputs['source']['fixture.pl'].encode('utf-8'), [declaration['filename']])
            boundaries[name] = dict(role=role, frame_index=index, selection=selected)
        results.append(dict(invocation=observed['invocation'], calls=calls, boundaries=boundaries,
                            module_filename=payload['module_filename'],
                            whole_raw_wire_identity=pin(observed['actual']['stdout'].encode())))
    return dict(runs=results, role=inputs['role'])


def check_selected(candidate, expected):
    for run in candidate['runs']:
        selections = [row['selection'] for row in run['calls']]
        selections.extend(row['selection'] for row in run['boundaries'].values())
        need(all(type(row['line']) is int for row in selections), 'selected lines retain integer kind')
    need(same(candidate, expected), 'whole independent public source/raw selection allocation and scope')


def check_actual(row, command, stdout):
    need(row['command'] == ['scripts/run_with_ram_guard.sh','--',*command]
         and type(row['status']) is int and row['status'] == 0 and row['stdout'] == stdout,
         'whole actual selection command integer success and stdout')
    need(re.fullmatch(r'ram-guard: PID \d+; host [0-9.]+%; host cutoff 88%; descendant RSS cutoff 4096 MiB; poll 2s\n', row['stderr']),
         'whole unchanged selection guard actual stderr')
    paths = [BASE/'run.py', Path('scripts/run_with_ram_guard.sh')]
    paths.extend(Path(arg) for arg in command if arg.startswith(('docs/','scripts/','t/')) and Path(arg).is_file())
    need(same(row['instruments'], {str(p):pin(p.read_bytes()) for p in paths}), 'all actual selection producing instrument identities')


def main():
    producer = namespace(SELECT/'verify.py')
    paths = list(SELECT.iterdir())
    need(all(p.is_file() and not p.is_symlink() and p.stat().st_dev == Path.cwd().stat().st_dev for p in paths),
         'complete regular same-volume selected member domain')
    members = {p.name:pin(p.read_bytes()) for p in paths if p.name != 'manifest.json'}
    need(same(members, data(SELECT/'manifest.json')), 'whole independent public caller selection seal')
    archived = subprocess.check_output(['git','archive',REVISION,*map(str,producer['ROOTS'])])
    with tarfile.open(fileobj=io.BytesIO(archived)) as archive:
        committed = {m.name:archive.extractfile(m).read() for m in archive.getmembers() if m.isfile()}
    binding = data(SELECT/'binding.json')
    need(same({p:v for root in binding['members'].values() for p,v in root.items()},
              {p:pin(raw) for p,raw in committed.items()})
         and all(Path(p).read_bytes() == raw for p,raw in committed.items()), 'whole independent committed source/native/actual prerequisite custody')
    need(same(binding, producer['binding']()), 'whole saved complete owners and source binding')
    inputs = data(SELECT/'inputs.json')
    expected = reconstruct(inputs, committed)
    need(same(expected, producer['derive'](inputs)), 'independent byte/LF/raw interpretation agrees with whole producer')
    check_selected(data(SELECT/'selections.json'), expected)
    need(same(producer['controls'](inputs), data(SELECT/'controls.json')), 'all full genuine semantic candidate inputs and intended refusals')
    prior = data(Path('docs/audits/coordinate-public-capture-checks-20261007/saved-result-qualified.json'))['stdout']
    check_actual(data(BASE/'prerequisite.json'), ['python3','-B','docs/audits/coordinate-public-capture-checks-20261007/verify_saved.py'], prior)
    check_actual(data(BASE/'seal.json'), ['python3','-B',str(SELECT/'verify.py'),'--seal'], producer['SUCCESS'])
    cases = [
        ('Boolean-selected-line', lambda s:s['runs'][0]['calls'][5]['selection'].update(line=True), 'selected lines retain integer kind'),
        ('false-closing-alternative', lambda s:s['runs'][0]['calls'][1]['selection'].update(line=inputs['hypotheses']['calls'][1]['line_hypotheses']['closing']), 'whole independent public source/raw selection allocation and scope'),
        ('lost-equivalent-label', lambda s:s['runs'][0]['calls'][0]['selection']['matching_line_labels'].pop(), 'whole independent public source/raw selection allocation and scope'),
        ('lost-selected-call', lambda s:s['runs'][0]['calls'].pop(), 'whole independent public source/raw selection allocation and scope'),
        ('borrowed-selected-filename', lambda s:s['runs'][1]['calls'][5]['selection'].update(filename='borrowed-body.pl'), 'whole independent public source/raw selection allocation and scope'),
        ('borrowed-selected-scope', lambda s:s.update(role='Original coordinate identity is qualified.'), 'whole independent public source/raw selection allocation and scope')]
    controls = []
    for name, mutate, cause in cases:
        changed = copy.deepcopy(expected)
        mutate(changed)
        need(not same(changed, expected), 'genuine independent selected-result control')
        try:
            check_selected(changed, expected)
        except ValueError as error:
            need(str(error) == cause, 'intended independent selected-result refusal')
            controls.append(dict(control=name,status=1,cause=cause))
        else:
            raise ValueError('false-green independent selected-result control')
    need(same(members, {p.name:pin(p.read_bytes()) for p in SELECT.iterdir() if p.name!='manifest.json'}),
         'every complete immutable source/raw/control/selection member conserves')
    print(json.dumps(dict(members=len(members), runs=len(expected['runs']),
        calls_per_run=[len(r['calls']) for r in expected['runs']],
        boundaries_per_run=[len(r['boundaries']) for r in expected['runs']], controls=controls,
        scope=producer['ROLE']), sort_keys=True))


if __name__ == '__main__':
    main()
