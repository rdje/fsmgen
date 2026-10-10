"""Independently qualify the dated observer-prerequisite diagnosis, not its repair."""
import ast
import copy
import hashlib
import json
import os
import re
import stat
import subprocess
from pathlib import Path

BASE = Path('docs/audits/observer-join-prerequisite-20261010')
REVISION = '60f6259b7c789d91d6df24c13e0ee1994ca030d7'
PREFIX = 'docs/audits/'
TASK = 'docs/tasks/SEMANTIC-INTROSPECTION-MCP-FRONTIER.md'
JOIN = 'SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.4.3.3.5.2.1.5.2.2.3.1.2.1.3.1.2.3.2.3.3.3.3.2.3.2.3.3.2.3.2.2.2.3.5'
SCOPE = 'Dated prerequisite/continuity diagnosis only. Limited historical predicates remain valid; full observer/header/format repair and original parents stay open.'
SUCCESS = 'PASS complete dated observer prerequisite diagnosis; original pending contract, whole fixed source/candidate/results and genuine controls qualify. Full observer/header/format repair remains pending.\n'


def need(ok, cause):
    if not ok:
        raise ValueError(cause)


def pin(raw):
    return {'bytes': len(raw), 'sha256': hashlib.sha256(raw).hexdigest()}


def same(left, right):
    return json.dumps(left, sort_keys=True, allow_nan=False) == json.dumps(right, sort_keys=True, allow_nan=False)


def load(path):
    return json.loads(path.read_bytes())


def git(*args):
    r = subprocess.run(['git', '--no-replace-objects', *args], capture_output=True)
    need(r.returncode == 0 and not r.stderr, 'complete independent fixed Git result')
    return r.stdout


def module(path):
    ns = {'__name__': 'observer_diagnosis_oracle_dependency', '__file__': str(path)}
    exec(compile(path.read_bytes(), str(path), 'exec'), ns)
    return ns


def own(path):
    root = Path.cwd().resolve()
    p = Path(path)
    need(not p.is_absolute() and not {'..', '.git'}.intersection(p.parts), 'own relative diagnosis input')
    full = root / p
    need(full.resolve() == full and stat.S_ISREG(full.lstat().st_mode)
         and full.stat().st_dev == root.stat().st_dev, 'plain same-volume diagnosis member')
    for parent in full.parents:
        if parent == root:
            break
        need(not (parent / '.git').exists(), 'own diagnosis repository boundary')
    return full


def source_domain():
    admission = PREFIX + 'address-raw-admission-20261010'
    inherited = json.loads(git('show', REVISION + ':' + admission + '/admission.json'))
    selected = set(inherited['custody']['roots']) | {admission}
    selected.update(PREFIX + name for name in (
        'record-value-class-frame-join-20261006', 'class-frame-join-checks-20261006',
        'record-value-original-observer-sources-20261005', 'record-value-original-observer-boundaries-20261005',
        'record-value-public-boundary-join-20261006', 'record-value-public-framework-profile-20261006',
        'record-value-public-native-fixtures-20261006'))
    roots = sorted(p for p in selected if not any(p.startswith(q + '/') for q in selected if q != p))
    raw = git('--literal-pathspecs', 'ls-tree', '-r', '-z', REVISION, '--', *roots)
    entries = {}
    for record in raw.rstrip(b'\0').split(b'\0'):
        metadata, name = record.split(b'\t', 1)
        mode, kind, oid = metadata.decode().split()
        path = name.decode()
        need(kind == 'blob' and mode in ('100644', '100755') and path not in entries,
             'complete independent regular source tree')
        entries[path] = {'mode': mode, 'oid': oid}
    # A second native protocol streams each immutable Git object and compares
    # the complete current bytes. The producer used a streaming tar archive.
    process = subprocess.Popen(['git', '--no-replace-objects', 'cat-file', '--batch'],
                               stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    observed = {}
    try:
        for path, declaration in sorted(entries.items()):
            current = own(path)
            need(bool(current.stat().st_mode & 0o111) == (declaration['mode'] == '100755'),
                 'complete independent source executable mode')
            process.stdin.write(declaration['oid'].encode() + b'\n')
            process.stdin.flush()
            oid, kind, size = process.stdout.readline().split()
            need(oid.decode() == declaration['oid'] and kind == b'blob', 'whole independent Git object authority')
            remaining = int(size)
            digest = hashlib.sha256()
            with current.open('rb') as stream:
                while remaining:
                    chunk = process.stdout.read(min(1048576, remaining))
                    need(bool(chunk) and stream.read(len(chunk)) == chunk, 'whole independent source bytes')
                    digest.update(chunk)
                    remaining -= len(chunk)
                need(not stream.read(1) and process.stdout.read(1) == b'\n', 'whole independent source boundary')
            observed[path] = {**declaration, 'identity': {'bytes': int(size), 'sha256': digest.hexdigest()}}
        process.stdin.close()
        error = process.stderr.read()
        status = process.wait()
        need(status == 0 and not error and not process.stdout.read(1), 'complete independent binary source transport')
    except BaseException:
        process.kill()
        process.wait()
        raise
    finally:
        process.stdout.close()
        process.stderr.close()
        if not process.stdin.closed:
            process.stdin.close()
    for root_name in roots:
        root = Path(root_name)
        if root.is_file():
            actual = {root_name}
        else:
            actual = set()
            for directory, children, names in os.walk(root, followlinks=False):
                need('.git' not in children and '.git' not in names, 'source namespace repository boundary')
                for name in children:
                    p = Path(directory) / name
                    need(not p.is_symlink() and p.stat().st_dev == Path.cwd().stat().st_dev,
                         'source namespace directory boundary')
                actual.update(str(Path(directory) / name) for name in names)
        expected = {p for p in entries if p == root_name or p.startswith(root_name + '/')}
        need(actual == expected and expected, 'complete independent source namespace membership')
    return roots, observed


def node(text, owner):
    pattern = re.compile(r'^- ID: `' + re.escape(owner) + r'`\n.*?(?=\n- ID: |\Z)', re.M | re.S)
    found = pattern.findall(text)
    need(len(found) == 1, 'unique fixed original task node')
    return found[0]


def authority(record, roots, members, task):
    need(set(record) == {'revision', 'owner', 'custody', 'task', 'prior_memory', 'mechanisms',
                        'probe', 'actual_results', 'scope'}, 'closed independent diagnosis schema')
    need(record['revision'] == REVISION and record['owner'] == JOIN + '.1', 'exact dated diagnosis authority')
    need(record['scope'] == SCOPE, 'diagnosis scope cannot promote full observer closure')
    c = record['custody']
    need(set(c) == {'revision', 'roots', 'members', 'transport'}
         and c['revision'] == REVISION and c['roots'] == roots and same(c['members'], members),
         'complete fixed-Git source member allocation and identity')
    need(same(c['transport'], {'command': ['git', '--no-replace-objects', '-c', 'tar.umask=0022', '--literal-pathspecs',
         'archive', '--format=tar', REVISION, '--', *roots], 'status': 0, 'stderr': ''}),
         'complete actual producer source transport')
    raw_parent = JOIN.rsplit('.', 3)[0]
    owners = (JOIN, JOIN.rsplit('.', 1)[0], JOIN.rsplit('.', 2)[0],
              JOIN.rsplit('.', 2)[0] + '.6', raw_parent, raw_parent + '.5')
    wanted = {owner: node(task.decode(), owner) for owner in owners}
    need(same(record['task'], {'path': TASK, 'identity': pin(task), 'nodes': wanted}), 'whole original task and unclosed prerequisite contracts')
    need('\n  Status: `pending`\n' in wanted[JOIN]
         and '\n  Status: `done`\n' in wanted[JOIN.rsplit('.', 2)[0] + '.6']
         and '\n  Status: `active`\n' in wanted[JOIN.rsplit('.', 1)[0]], 'original pending/done observer allocation')
    need(record['prior_memory'] == git('show', REVISION + ':MEMORY.md').decode(), 'whole fixed prior resume pointer')
    mechanisms = {}
    for path, name in (
        (PREFIX + 'record-value-original-value-frames-20261005/verify.py', 'check_footprint'),
        (PREFIX + 'record-value-public-boundary-join-20261006/verify.py', 'public_arguments'),
        (PREFIX + 'record-value-class-frame-join-20261006/verify.py', 'prior_predicates')):
        raw = git('show', REVISION + ':' + path)
        nodes = [n for n in ast.parse(raw).body if isinstance(n, ast.FunctionDef) and n.name == name]
        need(len(nodes) == 1 and path in members, 'complete independently bound mechanism source')
        mechanisms[path + ':' + name] = {'source': pin(raw), 'function': ast.get_source_segment(raw.decode(), nodes[0])}
    need(same(record['mechanisms'], mechanisms), 'whole independently selected predicate mechanisms')


def actual(record):
    expected = {
        'distinction': (['python3', '-B', str(BASE / 'probe.py')],
            'PASS actual proper-prefix distinction: limited predecessor semantics accept; whole original custody rejects. Full observer/header/format qualification remains pending.\n'),
        'frontier-history': (['git', 'log', '-1', '--format=%H%x20%s',
            '-SStart full raw-stack joining from every complete qualified inventory', '--', 'MEMORY.md'],
            git('log', '-1', '--format=%H%x20%s', '-SStart full raw-stack joining from every complete qualified inventory',
                REVISION, '--', 'MEMORY.md').decode())}
    need(set(record) == set(expected), 'complete actual diagnosis result membership')
    for name, (command, stdout) in expected.items():
        row = record[name]
        need(type(row['status']) is int and row['status'] == 0, 'actual discrete successful diagnosis status')
        need(row['command'] == ['scripts/run_with_ram_guard.sh', '--', *command], 'exact actual diagnosis command')
        need(row['stdout'] == stdout, 'whole actual diagnosis result stream')
        need(type(row['stderr']) is str and re.fullmatch(
            r'ram-guard: PID [0-9]+; host [0-9]+\.[0-9]+%; host cutoff 88%; descendant RSS cutoff 4096 MiB; poll 2s\n',
            row['stderr']) is not None, 'actual unchanged diagnosis guard')
        paths = {str(BASE / 'checks.py'), 'scripts/run_with_ram_guard.sh',
                 str(BASE / 'probe.py') if name == 'distinction' else 'MEMORY.md'}
        need(set(row['instruments']) == paths, 'complete actual direct invocation instruments')
        for path in paths:
            source = BASE / 'history-memory-input.md.txt' if path == 'MEMORY.md' else Path(path)
            need(same(row['instruments'][path], pin(own(source).read_bytes())), 'whole actual invocation source epoch')


def distinction(record):
    old = module(Path(PREFIX + 'record-value-class-frame-join-20261006/verify.py'))
    models = old['source_models']()
    original = old['load'](Path(PREFIX + 'record-value-class-frame-join-20261006/raw-product.json'))['inventories']
    nested = old['public']['context']['nested_records'](models['frame_model']['own'])
    baseline = old['prior_predicates'](models, original, nested)
    probe = record['probe']
    need(set(probe) == {'scope', 'legacy', 'intervention', 'baseline_prior_status', 'candidate_prior_status',
                       'candidate_full_status', 'candidate_full_cause', 'products', 'missing', 'next'},
         'closed independent distinction schema')
    need(probe['scope'] == 'Diagnosis only: deliberately limited visible-prefix semantics accept another proper prefix; unchanged full original custody rejects it. This is not a false green of the full historical reader.'
         and probe['legacy'] == PREFIX + 'record-value-class-frame-join-20261006/verify.py'
         and probe['next'] == 'Complete unchanged observer join under .2, then qualify publication and full parent under .3; raw-stack closure follows.',
         'exact limited distinction and unchanged repair scope')
    intervention = probe['intervention']
    candidate = copy.deepcopy(original)
    mode = next(m for m in candidate if m['mode'] == intervention['mode'])
    row = old['row'](mode, intervention['domain'], intervention['index'])
    before = row['body']
    call = intervention['before_call']
    display = intervention['before_display']
    need(before.count(call) == 1 and call.startswith('Test::Builder::subtest(')
         and display.endswith('...') and call.count(display) == 1, 'actual own public header intervention source')
    value = json.loads(display[:-3])
    replacement = json.dumps(value[:1]) + '...'
    after_call = call.replace(display, replacement, 1)
    after = before.replace(call, after_call, 1)
    need(len(value) > 1 and intervention['after_display'] == replacement
         and intervention['after_call'] == after_call and before != after
         and intervention['before_body'] == pin(before.encode())
         and intervention['after_body'] == pin(after.encode()), 'genuine exact proper-prefix intervention')
    trace = old['public']['context']['module'](old['public']['context']['RAW'] / 'trace_inventory.py')['inventory']
    row.update(body=after, body_identity=pin(after.encode()), **trace(after))
    need(same(load(BASE / 'candidate.json'), candidate), 'whole one-call candidate and non-target conservation')
    compatible = old['prior_predicates'](models, candidate, nested)
    need(same(load(BASE / 'baseline-prior.json'), baseline) and same(load(BASE / 'candidate-prior.json'), compatible),
         'whole independent limited-predicate result reconstruction')
    cause = 'every canonical original raw body allocation context and opaque byte conserves'
    try:
        old['check'](models, models, candidate, original, nested)
    except ValueError as error:
        need(str(error) == cause, 'intended complete historical custody refusal')
    else:
        raise ValueError('historical whole-byte reader falsely admitted a changed header')
    need(type(probe['baseline_prior_status']) is int and probe['baseline_prior_status'] == 0
         and type(probe['candidate_prior_status']) is int and probe['candidate_prior_status'] == 0
         and type(probe['candidate_full_status']) is int and probe['candidate_full_status'] == 1
         and probe['candidate_full_cause'] == cause, 'separate limited-success and full-refusal results')
    need(same(probe['products'], {name: pin((BASE / name).read_bytes())
         for name in ('candidate.json', 'baseline-prior.json', 'candidate-prior.json')}), 'whole actual distinction products')
    need(probe['missing'] == ['Complete original observer full-header/quoting/truncation contract',
         'Original formatter/settings/provider identity remains unmeasured; current public fixtures establish compatibility only'],
         'unmeasured original formatter boundary cannot promote')
    return {'intervention': intervention, 'baseline': pin((BASE / 'baseline-prior.json').read_bytes()),
            'compatible': pin((BASE / 'candidate-prior.json').read_bytes()), 'full_refusal': cause,
            'meaning': 'Existing finite prefix semantics and whole-byte custody are separate valid contracts; full observer acceptance remains pending.'}


def main():
    need(Path(__file__).resolve().parents[3] == Path.cwd().resolve(), 'invoke diagnosis in its own repository root')
    manifest = load(BASE / 'manifest.json')
    # Source diagnosis is immutable; subsequent book/current publication is
    # separately qualified by book.py and its complete actual receipts.
    excluded = {'manifest.json', 'checks.json', 'proof.json', 'publication.json',
                'native.html.txt', 'native-proof.json'}
    need({p.name for p in BASE.iterdir()} - excluded == set(manifest), 'complete immutable diagnosis member allocation')
    for name, expected in manifest.items():
        need(pin(own(BASE / name).read_bytes()) == expected, 'whole immutable diagnosis member: ' + name)
    roots, members = source_domain()
    task = git('show', REVISION + ':' + TASK)
    record = load(BASE / 'binding.json')
    authority(record, roots, members, task)
    actual(record['actual_results'])
    result = distinction(record)
    controls = []
    for name, mutate, cause, reader in (
        ('lost-source', lambda r: r['custody']['members'].pop(next(iter(r['custody']['members']))),
         'complete fixed-Git source member allocation and identity', 'authority'),
        ('closed-pending-owner', lambda r: r['task']['nodes'].__setitem__(JOIN, r['task']['nodes'][JOIN].replace('Status: `pending`', 'Status: `done`')),
         'whole original task and unclosed prerequisite contracts', 'authority'),
        ('promoted-scope', lambda r: r.update(scope='Full observer acceptance complete.'),
         'diagnosis scope cannot promote full observer closure', 'authority'),
        ('unknown-native-field', lambda r: r.update(native_identity='measured'),
         'closed independent diagnosis schema', 'authority'),
        ('Boolean-status', lambda r: r['actual_results']['distinction'].update(status=True),
         'actual discrete successful diagnosis status', 'actual'),
        ('borrowed-output', lambda r: r['actual_results']['distinction'].update(stdout='PASS\n'),
         'whole actual diagnosis result stream', 'actual')):
        changed = copy.deepcopy(record)
        mutate(changed)
        need(changed != record, 'genuine diagnosis control: ' + name)
        try:
            authority(changed, roots, members, task) if reader == 'authority' else actual(changed['actual_results'])
        except ValueError as error:
            need(str(error) == cause, 'intended diagnosis control cause: ' + name)
            controls.append({'control': name, 'status': 1, 'cause': cause})
        else:
            raise ValueError('false-green diagnosis control: ' + name)
    proof = {'binding': pin((BASE / 'binding.json').read_bytes()), 'original_task': pin(task),
             'source_roots': roots, 'distinction': result, 'controls': controls,
             'scope': SCOPE, 'next': [JOIN + '.2', JOIN + '.3'],
             'legs': {'rederive': 'Independent binary Git/current whole-source comparison, fixed task/source-function reconstruction and exact original/candidate semantic replay.',
                      'falsify': 'Actual source-name proper-prefix distinction and full custody refusal; genuine missing-source, premature closure, scope, Boolean-status and borrowed-output controls.',
                      'durability': 'Fixed Git epoch, complete source ledger, whole candidates/results, invocation source epoch, immutable member seal and tracked independent reader.'}}
    destination = BASE / 'proof.json'
    if destination.exists():
        need(same(load(destination), proof), 'whole immutable independently rederived diagnosis proof')
    else:
        destination.write_text(json.dumps(proof, sort_keys=True, indent=2) + '\n')
    print(SUCCESS, end='')


if __name__ == '__main__':
    main()
