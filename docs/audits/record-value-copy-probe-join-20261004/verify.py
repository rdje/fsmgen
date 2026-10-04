"""Finite qualification join over exact completed source/capture/reader owners."""
import copy
import hashlib
import json
import subprocess
from pathlib import Path

BASE = Path('docs/audits/record-value-copy-probe-join-20261004')
READER = Path('docs/audits/record-value-copy-reader-20261004')


def require(condition, message):
    if not condition:
        raise ValueError(message)


def identity(raw):
    return {'bytes': len(raw), 'sha256': hashlib.sha256(raw).hexdigest()}


def load(path):
    return json.loads(path.read_text())


def check_binding(binding):
    require(set(binding) == {'revision', 'task_path', 'owners', 'archives'}, 'binding schema')
    source = subprocess.check_output(['git', 'show', binding['revision'] + ':' + binding['task_path']], text=True)
    prefix = ('SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.4.3.3.5.2.1.5.2.2.3.1.2.1.3.1.2.3.2.3.3.3.3.2.3.2.2.')
    require([r['id'] for r in binding['owners']] == [prefix + '1', prefix + '2'], 'exact owner population')
    for owner in binding['owners']:
        start = source.index('- ID: `' + owner['id'] + '`')
        end = source.index('\n- ID:', start + 1)
        require(source[start:end] == owner['body'] and '\n  Status: `done`\n' in owner['body'],
                'whole completed owner authority')
    require(set(binding['archives']) == {'record-value-copy-probes-20261004',
                                        'record-value-copy-reader-20261004'}, 'exact prerequisite archives')
    for name, manifest in binding['archives'].items():
        directory = Path('docs/audits') / name
        require(load(directory / 'manifest.json') == manifest, 'canonical archive manifest')
        require({p.name for p in directory.iterdir()} == set(manifest) | {'manifest.json'}, 'complete archive domain')
        for member, row in manifest.items():
            raw = (directory / member).read_bytes()
            require(identity(raw) == row, 'archive whole member: ' + member)
            original = subprocess.check_output(['git', 'show', binding['revision'] + ':' + str(directory / member)])
            require(raw == original, 'exact committed prerequisite member: ' + member)


def authority_controls(binding):
    controls = []
    for index in range(2):
        bad = copy.deepcopy(binding)
        bad['owners'][index]['body'] = bad['owners'][index]['body'].replace('Status: `done`', 'Status: `pending`')
        try:
            check_binding(bad)
        except ValueError as error:
            controls.append({'control': f'owner-{index}-incomplete', 'status': 1,
                             'error': str(error), 'binding': bad})
        else:
            raise ValueError('false-green incomplete-owner control')
    bad = copy.deepcopy(binding)
    del bad['archives']['record-value-copy-reader-20261004']['replay.json']
    try:
        check_binding(bad)
    except ValueError as error:
        controls.append({'control': 'omit-complete-replay', 'status': 1,
                         'error': str(error), 'binding': bad})
    else:
        raise ValueError('false-green omitted-replay control')
    return controls


def check_products():
    binding = load(BASE / 'binding.json')
    check_binding(binding)
    reader = {'__name__': 'finite_reader'}
    exec(compile((READER / 'verify.py').read_bytes(), str(READER / 'verify.py'), 'exec'), reader)
    reader['main']()
    saved = load(BASE / 'execution.json')
    require(set(saved) == {'command', 'working_directory', 'status', 'stdout', 'stderr',
                          'programs', 'replay', 'controls'}, 'complete execution schema')
    require(saved['command'] == ['python3', '-B', str(READER / 'replay.py')]
            and saved['working_directory'] == '.' and type(saved['status']) is int
            and saved['status'] == 0, 'actual fresh replay command/status')
    require(saved['programs'] == {name: identity((READER / name).read_bytes())
                                for name in ('verify.py', 'replay.py')}, 'whole executed reader source identity')
    require(saved['stderr'] == '' and saved['stdout'] ==
            'PASS fresh exact-source seven-mode native replay and independent complete graph/cause/TAP controls: '
            + saved['replay']['fixture'] + '/replay-receipt.json\n', 'complete runner output')
    reader['check_replay'](saved['replay'], reader['check_population'](reader['CAPTURE'], '.'))
    require(saved['replay']['qualification'] == 'PASS', 'fresh replay qualification')
    require(saved['controls'] == authority_controls(binding), 'actual complete join authority RED records')
    return saved


def main():
    check_products()
    proof = load(BASE / 'book-transform.json')
    book = subprocess.check_output(['git', 'show', proof['revision'] + ':' + proof['path']])
    require(identity(book) == proof['before'], 'original book authority')
    for replacement in proof['replacements']:
        before, after = (replacement[key].encode() for key in ('before', 'after'))
        require(book.count(before) == 1, 'book transform membership')
        book = book.replace(before, after)
    require(identity(book) == proof['after'], 'complete book change authority')
    manifest = load(BASE / 'manifest.json')
    require({p.name for p in BASE.iterdir()} == set(manifest) | {'manifest.json'}, 'whole join member domain')
    for name, row in manifest.items():
        require(identity((BASE / name).read_bytes()) == row, 'join immutable member: ' + name)
    print('PASS complete finite source/capture/reader/native/control/reexecution join; original copies and hot repairs remain open.')


if __name__ == '__main__':
    main()
