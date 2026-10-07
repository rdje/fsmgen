"""Independently check full Git bytes, variants, binary spans and pending refusal plans."""
import copy
import hashlib
import io
import json
import re
import subprocess
import tarfile
from pathlib import Path

BASE = Path('docs/audits/coordinate-native-control-plan-checks-20261008')
MODEL = Path('docs/audits/record-value-coordinate-native-control-plans-20261008')
REVISION = 'e78541a5a84559c56cbef73d9afe5cbe1f1e498a'
ROOT = '.artifacts/public-coordinate-native-controls-20261008/'


def need(value, cause):
    if not value:
        raise ValueError(cause)


def pin(raw):
    return dict(bytes=len(raw), sha256=hashlib.sha256(raw).hexdigest())


def same(a, b):
    return json.dumps(a, sort_keys=True) == json.dumps(b, sort_keys=True)


def read(path):
    return json.loads(path.read_bytes())


def check(plans, inputs):
    source = inputs['source']; good = {p: s.encode() for p, s in source.items()}
    names = ('wrong-caller', 'wrong-line', 'wrong-root', 'borrowed-source')
    need(plans['role'] == inputs['role'] and plans['native_executed'] is False,
         'independent source-only pending qualification scope')
    need([r['name'] for r in plans['plans']] == list(names), 'independent complete ordered native variant allocation')
    for row in plans['plans']:
        name = row['name']; changed = dict(good)
        if name == 'wrong-caller':
            changed = {p: b'CoordinateBorrowed'.join(raw.split(b'CoordinatePublic')) for p, raw in good.items()}
        elif name == 'wrong-line':
            marker = b"    observe('single'); # site single"
            need(good['fixture.pl'].count(marker) == 1, 'independent unique binary line insertion site')
            a = good['fixture.pl'].index(marker)
            changed['fixture.pl'] = good['fixture.pl'][:a] + b'\n' * 5 + good['fixture.pl'][a:]
        elif name == 'borrowed-source':
            old = b"do './load-body.pl'; # site do boundary"
            a = good['fixture.pl'].index(old)
            changed['fixture.pl'] = good['fixture.pl'][:a] + b"do './borrowed-body.pl'; # site do boundary" + good['fixture.pl'][a + len(old):]
            changed['borrowed-body.pl'] = changed.pop('load-body.pl')
        need(same(row['source'], {p: raw.decode() for p, raw in changed.items()})
             and same(row['source_pins'], {p: pin(raw) for p, raw in changed.items()}),
             'independent complete variant source bytes and membership')
        differences = {p: dict(before=source.get(p), after=changed[p].decode() if p in changed else None)
                       for p in sorted(set(good) | set(changed)) if good.get(p) != changed.get(p)}
        need(same(row['changes'], differences), 'independent full before-after source difference allocation')
        need(same(row['invocation'], dict(root=ROOT + name, command=['perl', 'fixture.pl']))
             and same(row['base_invocation'], inputs['hypotheses']['invocations'][0])
             and row['guard'] == ['scripts/run_with_ram_guard.sh', '--'],
             'independent legitimate control custody and unchanged base-root boundary')
        expected = row['expected']; role = 'do-load' if name == 'borrowed-source' else 'single'
        declaration = next(c for c in inputs['hypotheses']['calls'] if c['role'] == role)
        unit = 'borrowed-body.pl' if name == 'borrowed-source' else 'fixture.pl'
        text = b"CoordinatePublic::observe('do-load'); # site do-load" if name == 'borrowed-source' else b"observe('single'); # site single"
        a = changed[unit].index(text); raw = changed[unit]
        first = len(raw[:a].split(b'\n')); closing = len(raw[:a + len(text)].split(b'\n'))
        span = dict(offset_bytes=a, text=text.decode(), identity=pin(text), first_line=first, closing_line=closing)
        need(same(expected['good_declaration'], declaration) and same(expected['variant_statement'], span)
             and expected['variant_unit'] == unit and expected['role'] == role
             and type(expected['first_line']) is int and type(expected['closing_line']) is int
             and expected['first_line'] == first and expected['closing_line'] == closing
             and expected['frame_index'] == declaration['caller_frame_index'],
             'independent binary statement and exact lexical line allocation')
        caller = 'CoordinateBorrowed::observe' if name == 'wrong-caller' else 'CoordinatePublic::observe'
        filename = './borrowed-body.pl' if name == 'borrowed-source' else 'fixture.pl'
        cause = {
            'wrong-caller': 'exact source-declared public caller target',
            'wrong-line': 'public line must select a predeclared lexical alternative',
            'borrowed-source': 'public filename must select a predeclared own source alternative',
            'wrong-root': 'exact legitimate public selection invocation',
        }[name]
        need(expected['caller'] == caller and expected['filename'] == filename
             and expected['refusal'] == cause
             and expected['disposition'] == 'pending native capture and independent refusal qualification'
             and expected['coordinate_check'] == ('positive' if name == 'wrong-root' else 'refuse'),
             'independent source-selected separating refusal remains pending')
        if name == 'wrong-caller':
            need(caller != declaration['callee'] and all(b'CoordinatePublic' not in raw for raw in changed.values()),
                 'independent wrong-caller namespace separation')
        elif name == 'wrong-line':
            need(first not in declaration['line_hypotheses'].values(), 'independent shifted line separates good alternatives')
        elif name == 'borrowed-source':
            need(filename not in declaration['filename_hypotheses'] and changed[unit] == good['load-body.pl'],
                 'independent borrowed filename preserves complete body')
        else:
            need(changed == good and row['invocation']['root'] != row['base_invocation']['root'],
                 'independent wrong-root keeps every good coordinate source')
        need(row['custody'] == 'Each fresh control root is legitimate custody; compare coordinates to unchanged good declarations. Only wrong-root compares its actual root to the unchanged base invocation. Never rewrite actual cwd or source.',
             'independent actual-root conservation scope')


def main():
    members = {p.name: pin(p.read_bytes()) for p in MODEL.iterdir() if p.name != 'manifest.json'}
    need(all(p.is_file() and not p.is_symlink() and p.stat().st_dev == Path.cwd().stat().st_dev for p in MODEL.iterdir())
         and same(read(MODEL / 'manifest.json'), members), 'independent complete immutable plan seal')
    binding = read(MODEL / 'binding.json')
    need(binding['revision'] == REVISION, 'independent fixed prerequisite revision')
    names = subprocess.check_output(['git', 'ls-tree', '-z', '--name-only', REVISION + ':docs/audits']).split(b'\0')
    roots = ['docs/audits/' + n.decode() for n in names if n.startswith((b'record-value-coordinate-', b'coordinate-public-'))]
    need(binding['roots'] == roots, 'independent whole fixed prerequisite root census')
    archived = subprocess.check_output(['git', 'archive', REVISION, *roots])
    with tarfile.open(fileobj=io.BytesIO(archived)) as archive:
        fixed = {m.name: archive.extractfile(m).read() for m in archive.getmembers() if m.isfile()}
    current = {str(p): p.read_bytes() for root in roots for p in Path(root).iterdir()}
    need(current == fixed and same(binding['members'], {p: pin(raw) for p, raw in fixed.items()}),
         'independent complete committed source/native/actual byte conservation')
    task = subprocess.check_output(['git', 'show', REVISION + ':docs/tasks/SEMANTIC-INTROSPECTION-MCP-FRONTIER.md'])
    owners = {}
    for root in roots:
        if '/record-value-' not in root:
            continue
        owner = fixed[root + '/scope.txt'].decode().splitlines()[0].split('Owner: ', 1)[1]
        suffix = task.decode().split('- ID: `' + owner + '`', 1)[1].split('\n- ID:', 1)[0]
        owners[owner] = '- ID: `' + owner + '`' + suffix
        need('\n  Status: `done`\n' in suffix, 'independent whole completed prerequisite owner')
    need(same(binding['owners'], owners) and same(binding['task_identity'], pin(task)),
         'independent full committed owner bodies and task identity')
    prefix = 'docs/audits/record-value-coordinate-public-hypotheses-20261007/'
    original = json.loads(fixed[prefix + 'inputs.json']); inputs = read(MODEL / 'inputs.json')
    need(same(inputs, dict(source=original['source'], source_pins=original['source_pins'],
                          hypotheses=json.loads(fixed[prefix + 'hypotheses.json']), role=binding['role'])),
         'independent complete unchanged good input authority')
    plans = read(MODEL / 'plans.json'); check(plans, inputs)
    producer_controls = read(MODEL / 'controls.json')
    alterations = [
        ('changed-good-source', lambda c: c['source'].update({'fixture.pl': c['source']['fixture.pl'] + '\n'}),
         'whole fixed good fixture source identity'),
        ('lost-source-member', lambda c: c['source'].pop('load-body.pl'), 'whole fixed good fixture source identity'),
        ('Boolean-good-line', lambda c: c['hypotheses']['calls'][0]['line_hypotheses'].update(first=True),
         'whole fixed good public hypothesis identity'),
        ('changed-base-root', lambda c: c['hypotheses']['invocations'][0].update(root=ROOT + 'wrong-root'),
         'whole fixed good public hypothesis identity'),
        ('lost-call-member', lambda c: c['hypotheses']['calls'].pop(), 'whole fixed good public hypothesis identity'),
        ('native-promotion', lambda c: c.update(role='Native variants passed.'),
         'source plans cannot promote native or original qualification'),
    ]
    need(len(producer_controls) == len(alterations), 'complete independent producer control population')
    for saved, (name, mutate, cause) in zip(producer_controls, alterations):
        candidate = copy.deepcopy(inputs); mutate(candidate)
        need(not same(candidate, inputs) and same(saved, dict(control=name, status=1, cause=cause, candidate=candidate)),
             'independent entire genuine producer candidate and named refusing decision')
    controls = []
    cases = [
        ('lost-variant', lambda c: c['plans'].pop(), 'independent complete ordered native variant allocation'),
        ('borrowed-body-loss', lambda c: c['plans'][-1]['source'].update({'borrowed-body.pl': '1;\n'}),
         'independent complete variant source bytes and membership'),
        ('Boolean-line', lambda c: c['plans'][1]['expected'].update(first_line=True),
         'independent binary statement and exact lexical line allocation'),
        ('root-promotion', lambda c: c['plans'][2].update(base_invocation=c['plans'][2]['invocation']),
         'independent legitimate control custody and unchanged base-root boundary'),
        ('false-native-signoff', lambda c: c.update(native_executed=True),
         'independent source-only pending qualification scope'),
        ('wrong-refusal', lambda c: c['plans'][0]['expected'].update(refusal='passed'),
         'independent source-selected separating refusal remains pending'),
    ]
    for name, mutate, cause in cases:
        candidate = copy.deepcopy(plans); mutate(candidate)
        need(not same(candidate, plans), 'genuine independent plan control')
        try:
            check(candidate, inputs)
        except ValueError as error:
            need(str(error) == cause, 'intended independent plan refusal: ' + name)
            controls.append(dict(control=name, status=1, cause=cause))
        else:
            raise ValueError('false-green independent plan control: ' + name)
    receipt = read(BASE / 'seal.json')
    need(receipt['command'] == ['scripts/run_with_ram_guard.sh', '--', 'python3', '-B', str(MODEL / 'verify.py'), '--seal']
         and type(receipt['status']) is int and receipt['status'] == 0
         and receipt['stdout'] == 'PASS complete source-only native control plans and genuine plan controls; no native variant executes.\n'
         and same(receipt['instruments'], {str(p): pin(p.read_bytes()) for p in (BASE / 'run.py', Path('scripts/run_with_ram_guard.sh'), MODEL / 'verify.py')}),
         'independent full actual source-plan seal receipt and producing instruments')
    need(re.fullmatch(r'ram-guard: PID \d+; host [0-9.]+%; host cutoff 88%; descendant RSS cutoff 4096 MiB; poll 2s\n', receipt['stderr']),
         'independent whole actual plan guard stderr')
    prior = read(BASE / 'prerequisite-approved.json')
    prior_path = Path('docs/audits/coordinate-public-origin-selection-checks-20261007/verify_saved.py')
    old_actual = json.loads(fixed['docs/audits/coordinate-public-origin-selection-checks-20261007/saved-result.json'])
    need(prior['command'] == ['scripts/run_with_ram_guard.sh', '--', 'python3', '-B', str(prior_path)]
         and type(prior['status']) is int and prior['status'] == 0 and prior['stdout'] == old_actual['stdout']
         and same(prior['instruments'], {str(p): pin(p.read_bytes()) for p in (BASE / 'run.py', Path('scripts/run_with_ram_guard.sh'), prior_path)})
         and re.fullmatch(r'ram-guard: PID \d+; host [0-9.]+%; host cutoff 88%; descendant RSS cutoff 4096 MiB; poll 2s\n', prior['stderr']),
         'independent whole fresh prerequisite actual result and source identity')
    proof = dict(members=members, prerequisite_members=len(fixed), controls=controls,
                 scope=inputs['role'], native_executed=False)
    path = BASE / 'proof.json'; raw = json.dumps(proof, sort_keys=True, indent=2) + '\n'
    if path.exists():
        need(path.read_text() == raw, 'whole retained independent plan proof')
    else:
        path.write_text(raw)
    print('PASS independent whole source-only variant plans, binary spans, genuine refusing controls and actual seal custody; native execution remains pending.')


if __name__ == '__main__':
    main()
