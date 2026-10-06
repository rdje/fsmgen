"""Join finite original public headers without historical/private attribution."""
import argparse
import copy
import io
import json
import re
import subprocess
import tarfile
from pathlib import Path

BASE = Path('docs/audits/record-value-public-boundary-join-20261006')
CONTEXT = Path('docs/audits/record-value-parser-context-join-20261006')
CONTEXT_CHECKS = Path('docs/audits/parser-context-join-checks-20261006')
FIXTURE = Path('docs/audits/record-value-public-native-fixtures-20261006')
FIXTURE_CHECKS = Path('docs/audits/public-native-fixture-checks-20261006')
REVISION = '66fb051cfca1d170cdcf7c8b46d316b8d8e185ae'


def module(path):
    ns = {'__name__': 'public_original_boundary_prerequisite'}
    exec(compile(path.read_bytes(), str(path), 'exec'), ns)
    return ns


context, fixture = (module(path / 'verify.py') for path in (CONTEXT, FIXTURE))
profile = module(fixture['PRIOR'] / 'verify.py')
model = module(BASE / 'model.py')
require, same, identity, load = (context[k] for k in ('require', 'same', 'identity', 'load'))
DIRECTORIES = [CONTEXT, CONTEXT_CHECKS, FIXTURE, FIXTURE_CHECKS]


def members():
    paths = list(BASE.iterdir())
    require(all(p.is_file() and not p.is_symlink() for p in paths), 'whole regular public boundary join member population')
    return {p.name: identity(p.read_bytes()) for p in paths if p.name != 'manifest.json'}


def save(name, value):
    path = BASE / name
    if path.exists():
        require(same(load(path), value), 'whole saved public boundary product: ' + name)
    else:
        require(not (BASE / 'manifest.json').exists(), 'sealed public boundary join cannot publish')
        path.write_text(json.dumps(value, sort_keys=True, indent=2) + '\n')


def committed(directory):
    data = subprocess.check_output(['git', 'archive', REVISION, str(directory)])
    with tarfile.open(fileobj=io.BytesIO(data)) as archive:
        return {entry.name: archive.extractfile(entry).read() for entry in archive.getmembers() if entry.isfile()}


def authenticate():
    binding = load(BASE / 'binding.json')
    require(binding['revision'] == REVISION and set(binding['archives']) == {str(p) for p in DIRECTORIES},
            'fixed complete original/public root and actual-checker intake')
    task = subprocess.check_output(['git', 'show', REVISION + ':' + binding['task_path']])
    require(same(identity(task), binding['task_identity']), 'whole public boundary prior task population')
    for directory in DIRECTORIES:
        root = CONTEXT if directory == CONTEXT_CHECKS else FIXTURE if directory == FIXTURE_CHECKS else directory
        owner = (root / 'scope.txt').read_text().splitlines()[0].removeprefix('Owner: ')
        start = task.decode().index('- ID: `' + owner + '`'); end = task.decode().index('\n- ID:', start + 1)
        require(binding['owners'][str(directory)] == owner and binding['owner_bodies'][owner] == task.decode()[start:end]
                and '\n  Status: `done`\n' in binding['owner_bodies'][owner], 'whole completed public/context source owner')
        actual = {str(p): p.read_bytes() for p in directory.iterdir()}
        require(actual == committed(directory) and same(binding['archives'][str(directory)],
            {p:identity(raw) for p,raw in actual.items()}), 'whole committed public/context source/programme/receipt products')
    if (BASE / 'manifest.json').exists():
        require(same(load(BASE / 'manifest.json'), members()), 'whole immutable original public boundary seal')
    receipts = []
    for directory in DIRECTORIES:
        programme = directory / ('verify_seal.py' if directory in (CONTEXT_CHECKS, FIXTURE_CHECKS) else 'verify.py')
        command = ['python3', '-B', str(programme)]; p = subprocess.run(command, capture_output=True)
        require(p.returncode == 0, 'complete prior source/context/public/native actual-checker replay: ' + str(directory))
        receipts.append(dict(command=command, status=p.returncode, stdout=p.stdout.decode(), stderr=p.stderr.decode()))
    return receipts


def models():
    expected = model['derive'](context, fixture, profile, require, same)
    require(same(expected, load(BASE / 'pre-native-models.json')), 'whole independent pre-original public source hypotheses')
    return expected


def public_arguments(call):
    prefix = 'Test::Builder::subtest('
    require(call.startswith(prefix) and call.endswith(')'), 'finite public Builder header syntax')
    split = re.fullmatch(r'([^,]+), (.*)', call[len(prefix):-1])
    require(split is not None and split[1], 'whole opaque public receiver token and visible tail')
    callback = context['subtest']['callback']
    tail = callback['arguments']('public_tail(' + split[2] + ')', 'public_tail')
    return dict(receiver_opaque=split[1], tail=tail)


def check(actual_models, expected, native, original, nested):
    require(same(actual_models, expected), 'complete independent public boundary source models')
    own = expected['own']
    # The source-role oracle is evaluated within this input's intervention
    # epoch. Actual original ancestry is independently bound and conserved
    # below; control successes never substitute for canonical root replay.
    own_join = context['check'](own, own, native, native, nested, nested)
    require([row['mode'] for row in native] == [row['mode'] for row in expected['public_modes']],
            'complete original public boundary mode population')
    modes = []
    for wanted, observed, joined in zip(expected['public_modes'], native, own_join['contexts'], strict=True):
        cases = []
        for case, owned in zip(wanted['cases'], joined['cases'], strict=True):
            require((case['domain'], case['index']) == (owned['domain'], owned['index']),
                    'complete public boundary source/own record allocation')
            row = next(r for r in observed['domains'][case['domain']]['nonempty'] if r['index'] == case['index'])
            frames = [f for f in row['segments'] if f['kind'] == 'frame']
            phases = []
            for phase, positions in zip(case['phases'], owned['phases'], strict=True):
                start, end = positions['body_positions'][-1] + 1, positions['entry_positions'][0]
                public = [i for i in range(start, end + 1) if context['function'](frames[i]) in model['PUBLIC']]
                require([context['function'](frames[i]) for i in public] == phase['public_path'],
                        'finite source/current public symbol population and order agreement')
                builder, delegate = public
                require(start <= builder < delegate == end < positions['load_position'],
                        'finite public body/delegate/own-entry/load interval order')
                footprint = public_arguments(frames[builder]['call'])
                require(len(footprint['tail']) == 2, 'complete finite visible public Builder name/callback tail')
                context['subtest']['callback']['check_footprint'](footprint['tail'], [phase['public_name'], phase['callback']])
                require(frames[positions['load_position']]['call'] == phase['load'] and phase['source_operator'] == 'do',
                        'source do operator and finite displayed load identifier stay separate')
                phases.append(dict(phase=phase['phase'], public_positions=public,
                    public_header_compatibility=footprint, load_position=positions['load_position'],
                    source_operator='do', own_eval_positions=positions['operations'],
                    remaining_framework=[frames[i] for i in range(start, end) if i != builder],
                    meaning='source/public signature and current independent boundary-path agreement only; historical/private/formatter/receiver/callback identities unmeasured'))
            cases.append(dict(domain=case['domain'], index=case['index'], subtest=case['subtest'],
                              original_body=row['body_identity'], phases=phases))
        modes.append(dict(mode=wanted['mode'], cases=cases))
    require(same(native, original), 'whole canonical original raw public population conserves')
    return dict(modes=modes, own_join=own_join, scope='Finite public header compatibility only; every private/eval/historical/identity meaning stays unmeasured.')


def controls(expected, original, nested):
    trace = context['module'](context['RAW'] / 'trace_inventory.py')['inventory']
    first_case = expected['public_modes'][0]['cases'][0]
    def row(native):
        return next(r for r in native[0]['domains'][first_case['domain']]['nonempty'] if r['index'] == first_case['index'])
    def change(native, alter):
        record = row(native); segments = record['segments']; parts = [s['raw'] for s in segments]
        index = next(i for i,s in enumerate(segments) if s['kind']=='frame' and s['call'].startswith('Test::Builder::subtest('))
        alter(parts, index, segments[index]); body = ''.join(parts)
        require(body != record['body'], 'genuine complete public raw header intervention')
        record.update(body=body, body_identity=identity(body.encode()), **trace(body))
    def replace(native, before, after):
        change(native, lambda parts,i,s: parts.__setitem__(i,parts[i].replace(before,after,1)))
    def insert(native, public_more):
        def alter(parts, index, segment):
            if public_more:
                text = next(s['raw'] for s in row(native)['segments'] if s['kind']=='frame' and s['call'].startswith('Test::More::subtest('))
            else:
                text = parts[index]
            parts.insert(index, text)
        change(native, alter)
    # All four separating inputs retain their own core/body/entry/eval/load
    # roles; the prior semantic composite accepts each intervention epoch.
    cases = [
        ('wrong-public-authored-name', lambda m,n: replace(n, json.dumps(first_case['subtest']), '"borrowed"'), 'direct Value source scalar argument footprint', True),
        ('wrong-public-callback-kind', lambda m,n: replace(n, 'CODE(', 'HASH('), 'direct Value reference argument footprint', True),
        ('duplicate-public-population', lambda m,n: insert(n,False), 'finite source/current public symbol population and order agreement', True),
        ('public-delegate-before-builder', lambda m,n: insert(n,True), 'finite source/current public symbol population and order agreement', True),
        ('lost-public-source-case', lambda m,n: m['public_modes'][0]['cases'].pop(), 'complete independent public boundary source models', False),
        ('borrowed-public-source-phase', lambda m,n: m['public_modes'][0]['cases'][0]['phases'][0].update(phase=99), 'complete independent public boundary source models', False),
        ('invented-original-version', lambda m,n: m.update(historical='Original versions measured.'), 'complete independent public boundary source models', False),
    ]
    result = []
    for name, mutate, cause, separating in cases:
        modeled, candidate = copy.deepcopy(expected), copy.deepcopy(original); mutate(modeled,candidate)
        require(not (same(modeled,expected) and same(candidate,original)), 'genuine public boundary intervention: ' + name)
        if separating:
            context['check'](expected['own'],expected['own'],candidate,candidate,nested,nested)
        try:
            check(modeled, expected, candidate, original, nested)
        except ValueError as error:
            require(str(error) == cause, 'intended public boundary refusal: ' + name + ': ' + str(error))
            result.append(dict(control=name, status=1, cause=str(error),
                prior_semantic_composite='passed within intervention epoch; canonical ancestry is a separate mandatory leg' if separating else 'not asserted'))
        else:
            raise ValueError('false-green original public boundary control: ' + name)
    return result


def main():
    p = argparse.ArgumentParser(description=__doc__); p.add_argument('--seal',action='store_true'); args=p.parse_args()
    replays = authenticate(); expected = models()
    original = load(context['RAW'] / 'proofs.json')['inventories']
    nested = context['nested_records'](expected['own'])
    save('proofs.json', dict(models=expected, observations=check(expected,expected,original,original,nested),
        controls=controls(expected,original,nested), scope='Complete finite original/source/public compatibility; all historical/private/formatter/identity gaps stay open.'))
    save('prerequisite-replays.json',replays)
    guide = module(BASE / 'book.py')
    save('book-proof.json', guide['proof']((BASE / 'book-input.html').read_text()))
    original_guide = module(BASE / 'initial-book.py.txt')
    require(same(load(BASE / 'initial-book-proof.json'), original_guide['proof']((BASE / 'initial-book-input.html').read_text())),
            'complete first scoped native guide success retained')
    try:
        guide['check']((BASE / 'initial-book-input.html').read_text())
    except ValueError as error:
        require(str(error) == 'native completed public join deferrals retired', 'initial stale completed-profile deferral refuses')
    else:
        raise ValueError('false-green initial stale chapter currency')
    if args.seal:
        save('manifest.json',members())
    print('PASS complete finite original public boundary/header compatibility and separating controls; historical/private/identity meanings remain open.')


if __name__ == '__main__':
    main()
