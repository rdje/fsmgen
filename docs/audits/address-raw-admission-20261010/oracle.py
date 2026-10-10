"""Independent blob-stream, original-capture and actual-result admission oracle."""
import hashlib
import json
import re
import subprocess
from pathlib import Path

BASE = Path('docs/audits/address-raw-admission-20261010')
A = Path('docs/audits')
SOURCE = A / 'address-source-integration-20261010'
CLASS = A / 'record-value-class-frame-join-20261006'
COORD = A / 'coordinate-original-hostile-20261009'
REVISION = 'c2b2a7f4a006bb267c4b077c37c5a295d24f44a5'
ROLE = ('Complete dated original/raw/source prerequisite custody and actual replay only; '
        'reference-operand parsing, original numeric role/lifetime joins and governed '
        'canonical publication remain successor-owned. No original execution is recaptured.')


def need(ok, why):
    if not ok:
        raise ValueError(why)


def pin(raw):
    return {'bytes': len(raw), 'sha256': hashlib.sha256(raw).hexdigest()}


def same(left, right):
    return json.dumps(left, sort_keys=True, allow_nan=False) == json.dumps(right, sort_keys=True, allow_nan=False)


def load(path):
    return json.loads(Path(path).read_bytes())


def roots():
    names = list(load(A / 'coordinate-original-intake-20261009/admission.json')['custody']['roots'])
    names.extend(str(Path(p).parent) if p.startswith('docs/audits/') else p
                 for p in load(SOURCE / 'binding.json')['inputs'])
    names.extend(['docs/audits/' + name + '-20261009' for name in (
        'coordinate-original-intake', 'coordinate-original-intake-checks',
        'coordinate-original-matching-qualified', 'coordinate-original-matching-qualified-checks',
        'coordinate-expression-alternatives', 'coordinate-expression-alternative-checks',
        'coordinate-observer-caller', 'coordinate-observer-caller-checks', 'coordinate-original-mismatch',
        'coordinate-original-hostile', 'coordinate-original-hostile-checks')])
    names.append(str(SOURCE))
    result = []
    for name in sorted(set(names), key=lambda p: (len(Path(p).parts), p)):
        if not any(Path(name).is_relative_to(Path(parent)) for parent in result):
            result.append(name)
    return sorted(result)


def custody():
    selected = roots()
    command = ['git', '--no-replace-objects', '--literal-pathspecs', 'ls-tree', '-r', '-z', REVISION, '--', *selected]
    run = subprocess.run(command, capture_output=True)
    need(run.returncode == 0 and not run.stderr, 'independent whole admission tree result')
    entries = []
    for row in run.stdout.rstrip(b'\0').split(b'\0'):
        header, path = row.split(b'\t', 1)
        mode, kind, oid = header.decode().split()
        need(kind == 'blob' and mode in ('100644', '100755'), 'independent own regular admission tree')
        entries.append((path.decode(), mode, oid))
    need(len({p for p, _, _ in entries}) == len(entries), 'independent unique admission population')
    # A second binary transport checks exact objects without using tar or producer code.
    process = subprocess.Popen(['git', '--no-replace-objects', 'cat-file', '--batch'],
                               stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    members = {}
    root = Path.cwd().resolve()
    try:
        for name, mode, oid in entries:
            path = root / name
            need(path.resolve() == path and path.is_file() and path.stat().st_dev == root.stat().st_dev,
                 'independent plain same-volume admission member')
            for parent in path.parents:
                if parent == root:
                    break
                need(not (parent / '.git').exists(), 'independent own admission repository')
            process.stdin.write((oid + '\n').encode())
            process.stdin.flush()
            object_id, kind, size = process.stdout.readline().decode().split()
            need(object_id == oid and kind == 'blob' and size.isdecimal(), 'independent blob protocol header')
            digest, remaining = hashlib.sha256(), int(size)
            with path.open('rb') as current:
                while remaining:
                    chunk = process.stdout.read(min(1024 * 1024, remaining))
                    need(chunk and current.read(len(chunk)) == chunk, 'independent whole fixed admission bytes')
                    digest.update(chunk)
                    remaining -= len(chunk)
                need(not current.read(1), 'independent whole fixed admission boundary')
            need(process.stdout.read(1) == b'\n', 'independent complete binary blob framing')
            members[name] = {'mode': mode, 'oid': oid, 'identity': {'bytes': int(size), 'sha256': digest.hexdigest()}}
        process.stdin.close()
        need(not process.stdout.read(), 'independent complete blob stream boundary')
        stderr = process.stderr.read()
        status = process.wait()
        need(status == 0 and not stderr, 'independent actual blob stream success')
    except BaseException:
        process.terminate()
        process.wait()
        raise
    finally:
        if not process.stdin.closed:
            process.stdin.close()
        process.stdout.close()
        process.stderr.close()
    for name in selected:
        path = Path(name)
        actual = {str(p) for p in path.rglob('*') if p.is_file() or p.is_symlink()} if path.is_dir() else {name}
        wanted = {p for p in members if Path(p).is_relative_to(path)}
        need(actual == wanted and wanted, 'independent complete admission namespace')
    return {'revision': REVISION, 'roots': selected, 'members': members,
            'transport': {'command': ['git', '--no-replace-objects', '-c', 'tar.umask=0022', '--literal-pathspecs',
                                     'archive', '--format=tar', REVISION, '--', *selected], 'status': 0, 'stderr': ''}}


def allocation():
    modes = []
    for name in ('ordinary', 'storable', 'controls'):
        original = load(A / 'record-value-original-candidate-20261004' / (name + '.json'))
        need(original['mode'] == name, 'independent original mode')
        domains = {}
        for domain in ('api', 'copies', 'parses', 'test_run'):
            records = [original[domain]] if domain == 'test_run' else original[domain]
            empty, nonempty = [], []
            for index, row in enumerate(records):
                need(type(row['error']) is str, 'independent original error wire type')
                if row['error'] == '':
                    empty.append(index)
                else:
                    nonempty.append({'index': index, 'body': pin(row['error'].encode()), 'wire_kind': 'string',
                        'context': {k: row[k] for k in ('kind', 'caller', 'helper', 'parse') if k in row}})
            domains[domain] = {'population': len(records), 'empty': empty, 'nonempty': nonempty}
        modes.append({'mode': name, 'domains': domains})
    model = load(CLASS / 'source-models.json')
    original_keys = {(m['mode'], name, row['index']) for m in modes
                     for name, domain in m['domains'].items() for row in domain['nonempty']}
    source_keys = [(m['mode'], case['domain'], case['index']) for m in model['modes'] for case in m['cases']]
    qualified = load(CLASS / 'proofs.json')
    qualified_keys = [(m['mode'], case['domain'], case['index']) for m in qualified['modes'] for case in m['cases']]
    need(set(source_keys) == set(qualified_keys) == original_keys
         and len(source_keys) == len(qualified_keys) == len(original_keys),
         'independent complete original/class/frame refusal association')
    views = []
    for mode in model['modes']:
        for case in mode['cases']:
            for phase in case['phases']:
                views.append([mode['mode'], case['domain'], case['index'], phase['phase']])
    source = load(SOURCE / 'hypotheses.json')
    actual = [v['domain'] for m in source['modes'] for v in m['views']]
    need({tuple(v) for v in actual} == {tuple(v) for v in views} and len(actual) == len(views),
         'independent whole simultaneous source phase allocation')
    # Source integration orders categories explicitly; preserve its qualified ordering.
    return {'modes': modes, 'source_views': actual,
            'products': {str(p): pin(p.read_bytes()) for p in (CLASS / 'raw-product.json', CLASS / 'source-models.json',
                CLASS / 'proofs.json', SOURCE / 'hypotheses.json', SOURCE / 'proof.json', COORD / 'qualification.json')}}


def actual(row, name):
    paths = {'source': SOURCE / 'verify.py', 'class-frame': CLASS / 'verify.py',
             'coordinate': A / 'coordinate-original-hostile-checks-20261009/verify_hostile.py'}
    reader = str(paths[name])
    need(set(row) == {'command', 'status', 'stdout', 'stderr', 'instruments'}, 'closed actual admission result')
    need(type(row['status']) is int and row['status'] == 0, 'actual admission integer success')
    need(row['command'] == ['scripts/run_with_ram_guard.sh', '--', 'python3', '-B', reader],
         'complete actual admission reader command')
    instruments = {str(BASE / 'checks.py'), 'scripts/run_with_ram_guard.sh', reader}
    need(row['instruments'] == {p: pin(Path(p).read_bytes()) for p in instruments},
         'complete actual invocation instruments')
    need(re.fullmatch(r'ram-guard: PID [0-9]+; host [0-9.]+%; host cutoff 88%; descendant RSS cutoff 4096 MiB; poll 2s\n',
                      row['stderr']) is not None, 'complete actual admission guard stream')
    if name == 'source':
        expected = 'PASS complete source role/graph/lifetime integration; original raw/native and governed publication remain open.\n'
    elif name == 'class-frame':
        expected = ('PASS complete finite source-inferred class/frame associations, whole original body/phase/operand joins '
                    'and genuine separating controls; native/private/formatter/coordinate/address meanings remain open.\n')
    else:
        saved = load(COORD / 'qualification.json')
        records = sum(len(d['nonempty']) for m in saved['original']['inventories'] for d in m['domains'].values())
        fields = {'lost-point': 'points', 'lost-source-recipe': 'representatives',
            'borrowed-intervention': 'controls', 'false-green-prior': 'controls',
            'lost-forwarded-pair': 'forwarding', 'lost-empty': 'original',
            'Boolean-reader-status': 'actual_matching_reader', 'borrowed-reader-command': 'actual_matching_reader',
            'borrowed-reader-stdout': 'actual_matching_reader'}
        expected = json.dumps({
            'result': 'PASS complete independent original-coordinate hostile qualification and predecessor preservation',
            'whole_qualification': pin(json.dumps(saved, sort_keys=True).encode()),
            'actual_matching_reader': saved['actual_matching_reader'],
            'coverage': {'points': len(saved['points']), 'source_recipe_modes': len(saved['representatives']),
                'semantic_controls': len(saved['controls']), 'forwarding_pairs': len(saved['forwarding']),
                'intervened_records': records},
            'controls': {name: 'complete independent hostile field: ' + field for name, field in fields.items()}},
            sort_keys=True) + '\n'
    need(row['stdout'] == expected, 'complete actual admission reader stdout')


def owners():
    path = 'docs/tasks/SEMANTIC-INTROSPECTION-MCP-FRONTIER.md'
    run = subprocess.run(['git', '--no-replace-objects', 'cat-file', 'blob', REVISION + ':' + path], capture_output=True)
    need(run.returncode == 0 and not run.stderr, 'independent complete committed task')
    raw = run.stdout
    nodes = {block.split('`', 2)[1]: block for block in re.split(r'(?m)(?=^- ID: `)', raw.decode())[1:]}
    selected = {}
    for folder in (SOURCE, CLASS, COORD):
        scope = (folder / 'scope.txt').read_bytes()
        identifiers = re.findall(rb'(?:Owner: )?(SEMANTIC-INTROSPECTION-MCP-FRONTIER(?:\.[0-9]+)+)', scope)
        need(identifiers and len(set(identifiers)) == 1, 'independent unique declared prerequisite owner')
        identifier = identifiers[0].decode()
        block = nodes[identifier].removesuffix('\n')
        need('\n  Status: `done`\n' in block, 'independent completed prerequisite owner')
        selected[str(folder)] = {'id': identifier, 'body': block, 'scope': pin(scope)}
    return {'path': path, 'task': pin(raw), 'completed': selected}


def qualify(candidate, expected_custody, expected_allocation, expected_owners):
    need(set(candidate) == {'owner', 'role', 'custody', 'allocation', 'actual_readers', 'prerequisite_owners'},
         'closed complete admission product')
    need(candidate['owner'] == (BASE / 'scope.txt').read_text().strip() and candidate['role'] == ROLE,
         'exact admission owner and successor scope')
    need(same(candidate['custody'], expected_custody), 'whole independent admission custody')
    need(same(candidate['allocation'], expected_allocation), 'whole independent original/source allocation')
    need(same(candidate['prerequisite_owners'], expected_owners), 'whole independent completed prerequisite owners')
    need(set(candidate['actual_readers']) == {'source', 'class-frame', 'coordinate'}, 'complete actual admission reader population')
    for name, row in candidate['actual_readers'].items():
        actual(row, name)
    return {'regular_members': len(expected_custody['members']), 'complete_roots': len(expected_custody['roots']),
            'source_views': len(expected_allocation['source_views']),
            'nonempty_records': sum(len(d['nonempty']) for m in expected_allocation['modes'] for d in m['domains'].values()),
            'empty_records': sum(len(d['empty']) for m in expected_allocation['modes'] for d in m['domains'].values()),
            'raw_body_bytes': sum(r['body']['bytes'] for m in expected_allocation['modes'] for d in m['domains'].values()
                                  for r in d['nonempty'])}
