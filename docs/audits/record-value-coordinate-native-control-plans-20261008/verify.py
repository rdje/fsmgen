"""Bind complete source-only native control plans; never execute Perl fixtures."""
import argparse
import copy
import hashlib
import io
import json
import subprocess
import tarfile
from pathlib import Path

BASE = Path('docs/audits/record-value-coordinate-native-control-plans-20261008')
REVISION = 'e78541a5a84559c56cbef73d9afe5cbe1f1e498a'
AUDITS = Path('docs/audits')
SOURCE = AUDITS / 'record-value-coordinate-public-hypotheses-20261007'
ROOT = '.artifacts/public-coordinate-native-controls-20261008/'
ROLE = ('Source-only finite own native control plans. No variant execution or native '
        'refusal is earned. Original/private/formatter/toolchain identities remain '
        'unmeasured; capture and semantic qualification are separate successors.')
SUCCESS = 'PASS complete source-only native control plans and genuine plan controls; no native variant executes.\n'


def need(value, cause):
    if not value:
        raise ValueError(cause)


def pin(raw):
    return dict(bytes=len(raw), sha256=hashlib.sha256(raw).hexdigest())


def same(a, b):
    return json.dumps(a, sort_keys=True) == json.dumps(b, sort_keys=True)


def load(path):
    return json.loads(path.read_bytes())


def fixed_domain():
    names = subprocess.check_output(['git', 'ls-tree', '-z', '--name-only',
                                     REVISION + ':docs/audits']).split(b'\0')
    roots = [AUDITS / n.decode() for n in names
             if n.startswith((b'record-value-coordinate-', b'coordinate-public-'))]
    raw = subprocess.check_output(['git', 'archive', REVISION, *map(str, roots)])
    with tarfile.open(fileobj=io.BytesIO(raw)) as archive:
        fixed = {m.name: archive.extractfile(m).read() for m in archive.getmembers() if m.isfile()}
    current = {}
    for root in roots:
        need(root.is_dir() and not root.is_symlink()
             and root.stat().st_dev == Path.cwd().stat().st_dev, 'regular same-volume prerequisite roots')
        for p in root.iterdir():
            need(p.is_file() and not p.is_symlink() and p.stat().st_dev == Path.cwd().stat().st_dev,
                 'complete regular same-volume prerequisite members')
            current[str(p)] = p.read_bytes()
    need(current == fixed, 'whole fixed committed coordinate source/native/actual domain')
    return roots, fixed


def binding():
    roots, fixed = fixed_domain()
    task = subprocess.check_output(['git', 'show', REVISION + ':docs/tasks/SEMANTIC-INTROSPECTION-MCP-FRONTIER.md'])
    owners = {}
    for root in roots:
        if not root.name.startswith('record-value-'):
            continue
        owner = fixed[str(root / 'scope.txt')].decode().splitlines()[0].removeprefix('Owner: ')
        text = task.decode(); a = text.index('- ID: `' + owner + '`'); b = text.index('\n- ID:', a + 1)
        owners[owner] = text[a:b]
        need('\n  Status: `done`\n' in owners[owner], 'whole completed committed prerequisite owners')
    return dict(revision=REVISION, roots=list(map(str, roots)), owners=owners,
                members={p: pin(raw) for p, raw in fixed.items()}, task_identity=pin(task), role=ROLE)


def inputs():
    source = load(SOURCE / 'inputs.json')
    return dict(source=source['source'], source_pins=source['source_pins'],
                hypotheses=load(SOURCE / 'hypotheses.json'), role=ROLE)


def statement(source, text):
    raw = source.encode(); fragment = text.encode()
    need(raw.count(fragment) == 1, 'unique complete own control source statement')
    a = raw.index(fragment)
    return dict(offset_bytes=a, text=text, identity=pin(fragment),
                first_line=raw[:a].count(b'\n') + 1,
                closing_line=raw[:a + len(fragment)].count(b'\n') + 1)


def derive(candidate):
    need(candidate['role'] == ROLE, 'source plans cannot promote native or original qualification')
    fixed = inputs()
    need(same(candidate['source'], fixed['source']) and same(candidate['source_pins'], fixed['source_pins']),
         'whole fixed good fixture source identity')
    need(same(candidate['hypotheses'], fixed['hypotheses']), 'whole fixed good public hypothesis identity')
    source = candidate['source']; calls = candidate['hypotheses']['calls']
    need(set(source) == {'fixture.pl', 'lib/CoordinateDependency.pm', 'load-body.pl', 'require-body.pl'},
         'complete own fixture source allocation')
    plans = []
    for name in ('wrong-caller', 'wrong-line', 'wrong-root', 'borrowed-source'):
        changed = copy.deepcopy(source)
        if name == 'wrong-caller':
            changed = {p: s.replace('CoordinatePublic', 'CoordinateBorrowed') for p, s in source.items()}
        elif name == 'wrong-line':
            old = "sub single {\n    observe('single'); # site single"
            need(source['fixture.pl'].count(old) == 1, 'unique line-shift insertion boundary')
            changed['fixture.pl'] = source['fixture.pl'].replace(old, "sub single {\n\n\n\n\n\n    observe('single'); # site single", 1)
        elif name == 'borrowed-source':
            old = "do './load-body.pl'; # site do boundary"
            need(source['fixture.pl'].count(old) == 1, 'unique borrowed source loading boundary')
            changed['fixture.pl'] = source['fixture.pl'].replace(old, "do './borrowed-body.pl'; # site do boundary", 1)
            changed['borrowed-body.pl'] = changed.pop('load-body.pl')
        role = 'do-load' if name == 'borrowed-source' else 'single'
        call = next(row for row in calls if row['role'] == role)
        unit = 'borrowed-body.pl' if name == 'borrowed-source' else 'fixture.pl'
        text = call['source']['text'].replace('CoordinatePublic', 'CoordinateBorrowed') if name == 'wrong-caller' else call['source']['text']
        span = statement(changed[unit], text)
        expected = dict(role=role, frame_index=call['caller_frame_index'], good_declaration=call,
                        variant_unit=unit, variant_statement=span,
                        caller='CoordinateBorrowed::observe' if name == 'wrong-caller' else call['callee'],
                        first_line=span['first_line'], closing_line=span['closing_line'],
                        filename='./borrowed-body.pl' if name == 'borrowed-source' else 'fixture.pl',
                        disposition='pending native capture and independent refusal qualification')
        causes = {
            'wrong-caller': 'exact source-declared public caller target',
            'wrong-line': 'public line must select a predeclared lexical alternative',
            'borrowed-source': 'public filename must select a predeclared own source alternative',
            'wrong-root': 'exact legitimate public selection invocation',
        }
        expected.update(refusal=causes[name], coordinate_check='positive' if name == 'wrong-root' else 'refuse')
        base_invocation = candidate['hypotheses']['invocations'][0]
        changes = {p: dict(before=source.get(p), after=changed.get(p))
                   for p in sorted(set(source) | set(changed)) if source.get(p) != changed.get(p)}
        plans.append(dict(name=name, source=changed, source_pins={p: pin(s.encode()) for p, s in changed.items()},
                          changes=changes, invocation=dict(root=ROOT + name, command=['perl', 'fixture.pl']),
                          base_invocation=base_invocation, expected=expected,
                          guard=['scripts/run_with_ram_guard.sh', '--'],
                          custody='Each fresh control root is legitimate custody; compare coordinates to unchanged good declarations. Only wrong-root compares its actual root to the unchanged base invocation. Never rewrite actual cwd or source.'))
    return dict(plans=plans, role=ROLE, native_executed=False)


def controls(original):
    cases = [
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
    rows = []
    for name, mutate, cause in cases:
        candidate = copy.deepcopy(original); mutate(candidate)
        need(not same(candidate, original), 'genuine source-plan candidate control')
        try:
            derive(candidate)
        except ValueError as error:
            need(str(error) == cause, 'intended source-plan candidate refusal: ' + name)
            rows.append(dict(control=name, status=1, cause=cause, candidate=candidate))
        else:
            raise ValueError('false-green source-plan candidate: ' + name)
    return rows


def members():
    need(all(p.is_file() and not p.is_symlink() and p.stat().st_dev == Path.cwd().stat().st_dev
             for p in BASE.iterdir()), 'regular same-volume complete plan seal')
    return {p.name: pin(p.read_bytes()) for p in BASE.iterdir() if p.name != 'manifest.json'}


def save(name, value):
    path = BASE / name; raw = json.dumps(value, sort_keys=True, indent=2) + '\n'
    if path.exists():
        need(path.read_text() == raw, 'whole retained plan product: ' + name)
    else:
        need(not (BASE / 'manifest.json').exists(), 'sealed plan cannot publish')
        path.write_text(raw)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--seal', action='store_true'); args = parser.parse_args()
    if (BASE / 'manifest.json').exists():
        need(same(load(BASE / 'manifest.json'), members()), 'whole immutable native control plan seal')
    before = binding(); save('binding.json', before)
    candidate = inputs(); save('inputs.json', candidate)
    save('plans.json', derive(candidate)); save('controls.json', controls(candidate))
    need(same(binding(), before), 'every complete original source/native/actual member conserves')
    if args.seal:
        save('manifest.json', members())
    print(SUCCESS, end='')


if __name__ == '__main__':
    main()
