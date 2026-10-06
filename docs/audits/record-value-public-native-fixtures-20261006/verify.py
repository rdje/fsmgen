"""Qualify finite current public fixtures; preserve historical/private gaps."""
import argparse
import copy
import io
import json
import subprocess
import tarfile
from pathlib import Path

BASE = Path('docs/audits/record-value-public-native-fixtures-20261006')
PRIOR = Path('docs/audits/record-value-public-framework-profile-20261006')
REVISION = '88d440175d9b3dc7591c31e1e524623b5e5ae50e'


def module(path):
    ns = {'__name__': 'public_native_fixture_dependency'}
    exec(compile(path.read_bytes(), str(path), 'exec'), ns)
    return ns


producer, model, expected = (module(BASE / name) for name in ('capture.py', 'model.py', 'expectations.py'))
identity = producer['identity']


def require(value, cause):
    if not value:
        raise ValueError(cause)


def same(left, right):
    return json.dumps(left, sort_keys=True) == json.dumps(right, sort_keys=True)


def load(path):
    return json.loads(path.read_bytes())


def save(name, data):
    path = BASE / name
    if path.exists():
        require(same(load(path), data), 'complete saved public fixture product: ' + name)
    else:
        require(not (BASE / 'manifest.json').exists(), 'sealed public fixture cannot publish')
        path.write_text(json.dumps(data, sort_keys=True, indent=2) + '\n')


def members():
    paths = list(BASE.iterdir())
    require(all(p.is_file() and not p.is_symlink() for p in paths), 'whole regular public fixture member population')
    return {p.name: identity(p.read_bytes()) for p in paths if p.name != 'manifest.json'}


def validate_pre(pre):
    require(pre['revision'] == REVISION and pre['task_path'] == 'docs/tasks/SEMANTIC-INTROSPECTION-MCP-FRONTIER.md',
            'fixed public fixture prior revision/task role')
    task = subprocess.check_output(['git', 'show', REVISION + ':' + pre['task_path']])
    require(same(identity(task), pre['task_identity']), 'whole completed public profile task identity')
    owner = (PRIOR / 'scope.txt').read_text().splitlines()[0].removeprefix('Owner: ')
    start = task.decode().index('- ID: `' + owner + '`')
    end = task.decode().index('\n- ID:', start + 1)
    body = task.decode()[start:end]
    require(pre['owner'] == owner and pre['owner_body'] == body and '\n  Status: `done`\n' in body,
            'whole completed public profile owner')
    data = subprocess.check_output(['git', 'archive', REVISION, str(PRIOR)])
    with tarfile.open(fileobj=io.BytesIO(data)) as archive:
        committed = {entry.name: archive.extractfile(entry).read() for entry in archive.getmembers() if entry.isfile()}
    actual = {str(p): p.read_bytes() for p in PRIOR.iterdir()}
    require(actual == committed and same(pre['prior'], {p: identity(raw) for p, raw in actual.items()}),
            'whole committed public profile/programme/native/product population')
    source_names = {'fixtures.pl', 'load-body.pl', 'require-body.pl', 'expectations.py', 'model.py', 'capture.py'}
    require(set(pre['source']) == source_names and same(pre['source'],
        {name: identity((BASE / name).read_bytes()) for name in source_names}), 'complete fixed own fixture source population')
    require(same(pre['expectations'], expected['ROLES']) and same(pre['additional_public_clauses'], expected['EXTRA_CLAUSES']),
            'independent fixed source-selected public expectations')
    expected['check_clauses'](load(PRIOR / 'public-profile.json'), require)


def check(record):
    require(set(record) == {'command', 'status', 'stdout', 'stderr', 'stdout_identity', 'stderr_identity',
                           'pre_native', 'workspace', 'role'}, 'complete public fixture process domain')
    require(record['command'] == producer['COMMAND'] and record['workspace'] == str(producer['WORK']),
            'exact own public fixture command/locality')
    require(same(record['pre_native'], identity((BASE / 'pre-native.json').read_bytes())),
            'whole independent pre-observation source binding')
    require(record['role'] == 'Own current installed public fixtures only; historical/original/private identities remain unmeasured.',
            'current public fixture versus historical/private scope')
    return model['check'](record, expected['ROLES'], require)


def first_refusal():
    initial_pre = load(BASE / 'initial-pre-native.json.txt')
    for name, pin in initial_pre['source'].items():
        require(same(identity((BASE / ('initial-' + name + '.txt')).read_bytes()), pin),
                'whole initial pre-observation fixture source')
    first = load(BASE / 'first-native.json')
    require(same(first, load(BASE / 'initial-native.json.txt')) and same(first['pre_native'],
        identity((BASE / 'initial-pre-native.json.txt').read_bytes())), 'complete first source/native capture binding')
    original_model = module(BASE / 'initial-model.py.txt')
    original_expected = module(BASE / 'initial-expectations.py.txt')['ROLES']
    require(same(original_expected, initial_pre['expectations']), 'whole initial source-selected public expectations')
    try:
        original_model['check'](first, original_expected, require)
    except ValueError as error:
        require(str(error) == 'source-selected public load body', 'intended complete first fixture model refusal')
    else:
        raise ValueError('false-green first unqualified fixture model')
    rows = json.loads(first['stdout'])['observations']
    for row in rows[-2:]:
        require('PublicFixture::trace_inner' not in row['text'] and 'PublicFixture::trace_outer' in row['text'],
                'first direct-emitter name hypothesis separated from actual outer trace')
    diagnostic = load(BASE / 'load-cache-diagnosis.json')
    require(type(diagnostic['actual']['status']) is int and diagnostic['actual']['status'] == 0,
            'actual own public cache diagnosis success')
    for stream in ('stdout', 'stderr'):
        require(same(identity(diagnostic['actual'][stream].encode()), diagnostic['actual'][stream + '_identity']),
                'whole actual public cache diagnosis streams')
    selected = [r for r in json.loads(diagnostic['actual']['stdout'])['observations'] if r['role'] in ('do-load', 'require-load')]
    key = './docs/audits/record-value-public-native-fixtures-20261006/load-body.pl'
    require(selected == diagnostic['selected'] and selected[0]['before'] is None
        and selected[0]['after'] == selected[1]['before'] == key and selected[1]['loaded'] is None,
        'public do/require shared-identifier cache root cause')
    return dict(status=1, cause='source-selected public load body', trace_name_hypothesis='refused',
                cache='finite actual public observation; no universal do/cache rule')


def observation_controls(record):
    products = []
    def modify(candidate, mutate):
        data = json.loads(candidate['stdout']); mutate(data['observations'])
        candidate['stdout'] = json.dumps(data, sort_keys=True, separators=(',', ':')) + '\n'
        candidate['stdout_identity'] = identity(candidate['stdout'].encode())
    cases = [
        ('Boolean-process-status', lambda r: r.update(status=False), 'public fixture integer process success'),
        ('float-process-status', lambda r: r.update(status=0.0), 'public fixture integer process success'),
        ('Boolean-stream-count', lambda r: r['stdout_identity'].update(bytes=True), 'complete public fixture stream byte/kind identity'),
        ('lost-role', lambda r: modify(r, lambda rows: rows.pop()), 'complete ordered public fixture role population'),
        ('wrong-callback-body', lambda r: modify(r, lambda rows: rows[0].update(body='borrowed')), 'source-selected public callback body'),
        ('wrong-forwarded-arguments', lambda r: modify(r, lambda rows: rows[1].update(arguments=[])), 'source-selected public callback forwarded arguments'),
        ('wrong-own-caller', lambda r: modify(r, lambda rows: rows[0]['frames'][1].__setitem__(3, 'PublicFixture::borrowed')), 'source-selected own public caller order'),
        ('wrong-eval-result', lambda r: modify(r, lambda rows: rows[3].update(value=None)), 'source-selected public eval return/error roles'),
        ('string-eval-fields', lambda r: modify(r, lambda rows: rows[3]['frames'][2].__setitem__(6, 'borrowed')), 'source-selected block-eval public fields'),
        ('lost-load-body', lambda r: modify(r, lambda rows: rows[5]['loaded'].update(body='borrowed')), 'source-selected public load body'),
        ('wrong-require-flag', lambda r: modify(r, lambda rows: [f.__setitem__(7, 0) for f in rows[6]['loaded']['frames']]), 'published require positive frame flag'),
        ('lost-trace-body', lambda r: modify(r, lambda rows: rows[7].update(text=rows[7]['text'].replace('public-trace-message', 'borrowed'))), 'public trace body and own call roles'),
        ('wrong-trace-policy', lambda r: modify(r, lambda rows: rows[8].update(text=rows[7]['text'])), 'source-selected public trace argument policy'),
        ('invented-historical-scope', lambda r: r.update(role='Original framework identities measured.'), 'current public fixture versus historical/private scope'),
    ]
    for name, mutate, cause in cases:
        candidate = copy.deepcopy(record); mutate(candidate)
        require(not same(candidate, record), 'genuine observation intervention: ' + name)
        try:
            check(candidate)
        except ValueError as error:
            require(str(error) == cause, 'intended public fixture observation refusal: ' + name)
            products.append(dict(control=name, status=1, cause=str(error)))
        else:
            raise ValueError('false-green public observation control: ' + name)
    return products


def native_controls(current):
    source = (BASE / 'fixtures.pl').read_text()
    work = Path('.artifacts/public-native-fixtures/controls'); work.mkdir(parents=True, exist_ok=True)
    cases = [
        ('native-callback-body', "body => 'more_empty'", "body => 'borrowed'", 'source-selected public callback body'),
        ('native-forwarded-argument', "'public-argument-A'", "'changed-public-argument'", 'source-selected public callback forwarded arguments'),
        ('native-string-eval', "eval { $frames = leaf(); 'public-eval-result' }", "eval '$frames = leaf(); \"public-eval-result\"'", 'source-selected block-eval public fields'),
        ('native-own-caller', 'more_empty', 'other_empty', 'source-selected own public caller order'),
        ('native-trace-policy', "$mode eq 'full' ? 0 : -1", "$mode eq 'full' ? -1 : 0", 'source-selected public trace argument policy'),
    ]
    result = []
    for name, before, after, cause in cases:
        # Keep the body marker unchanged in the renamed-callback control so
        # only the independently selected caller-order leg separates it.
        changed = source.replace(before, after)
        if name == 'native-own-caller':
            changed = changed.replace("body => 'other_empty'", "body => 'more_empty'")
        require(changed != source, 'genuine native source intervention: ' + name)
        if current:
            path = work / (name + '.pl'); path.write_text(changed)
            raw = producer['run'](['perl', str(path)])
        else:
            raw = load(BASE / 'native-controls.json')[name]['actual']
        require(raw['command'] == ['perl', str(work / (name + '.pl'))]
                and raw['workspace'] == str(producer['WORK'])
                and same(raw['pre_native'], identity((BASE / 'pre-native.json').read_bytes())),
                'whole actual native intervention command/source/locality binding')
        require(type(raw['status']) is int and raw['status'] == 0, 'native mutated fixture must execute successfully')
        try:
            model['check'](raw, expected['ROLES'], require)
        except ValueError as error:
            require(str(error) == cause, 'intended native behavioral separating refusal: ' + name)
            result.append((name, dict(source=changed, actual=raw, semantic_status=1, cause=str(error))))
        else:
            raise ValueError('false-green actual native source control: ' + name)
    return dict(result)


def source_controls(pre):
    result = []
    for name, mutate, cause in [
        ('borrowed-prior-revision', lambda p: p.update(revision='326d85a9f978bca6669f80c1f73458630dd3d25f'), 'fixed public fixture prior revision/task role'),
        ('lost-own-source', lambda p: p['source'].pop('require-body.pl'), 'complete fixed own fixture source population'),
        ('invented-expected-source-role', lambda p: p['expectations']['more-empty'].update(body='borrowed'), 'independent fixed source-selected public expectations'),
    ]:
        candidate = copy.deepcopy(pre); mutate(candidate)
        try:
            validate_pre(candidate)
        except ValueError as error:
            require(str(error) == cause, 'intended public source refusal: ' + name)
            result.append(dict(control=name, status=1, cause=str(error)))
        else:
            raise ValueError('false-green public source control: ' + name)
    return result


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--current', action='store_true')
    parser.add_argument('--seal', action='store_true')
    args = parser.parse_args()
    if (BASE / 'manifest.json').exists():
        require(same(load(BASE / 'manifest.json'), members()), 'whole immutable public fixture seal')
    pre = load(BASE / 'pre-native.json'); validate_pre(pre)
    command = ['python3', '-B', str(PRIOR / 'verify.py')]
    p = subprocess.run(command, capture_output=True)
    require(p.returncode == 0, 'complete prior public profile reader/control replay')
    prior = dict(command=command, status=p.returncode, stdout=p.stdout.decode(), stderr=p.stderr.decode())
    native = load(BASE / 'native.json'); qualified = check(native)
    current_profile_command = ['python3', '-B', str(PRIOR / 'verify.py'), '--current']
    if args.current:
        current_profile = subprocess.run(current_profile_command, capture_output=True)
        require(current_profile.returncode == 0, 'actual current installed public profile replay')
        save('profile-current-native.json', dict(command=current_profile_command, status=current_profile.returncode,
            stdout=current_profile.stdout.decode(), stderr=current_profile.stderr.decode()))
        fresh = producer['run']()
        require(same(fresh, native), 'actual complete current public fixture raw replay')
    saved_profile = load(BASE / 'profile-current-native.json')
    require(saved_profile['command'] == current_profile_command and type(saved_profile['status']) is int
            and saved_profile['status'] == 0 and saved_profile['stdout'] == prior['stdout']
            and saved_profile['stderr'] == '', 'complete saved actual current public profile result')
    native_proofs = native_controls(args.current or not (BASE / 'native-controls.json').exists())
    save('native-controls.json', native_proofs)
    proof = dict(prior=prior, source_model=qualified, first_refusal=first_refusal(),
        observation_controls=observation_controls(native), source_controls=source_controls(pre),
        native_controls={k:dict(status=v['semantic_status'], cause=v['cause']) for k,v in native_proofs.items()},
        scope='Finite own current public fixtures only. Original/private/formatter/coordinate/address identities remain unmeasured.')
    save('proofs.json', proof)
    if args.seal:
        save('manifest.json', members())
    print('PASS finite independent public callback/eval/load/trace roles and genuine source/native controls; historical/private identities remain open.')


if __name__ == '__main__':
    main()
