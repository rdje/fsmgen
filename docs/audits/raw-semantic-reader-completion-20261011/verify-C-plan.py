"""Complete original-reader checkpoint; interrupted attempts remain non-success."""
import argparse
import re
from common import *
import intake

BOOK = 'docs/book/src/13k-isf-feature-support-matrix.md'
SURFACES = 'doctrine/live_document_size/surfaces.jsonl'
ASSOCIATION = Path('docs/audits/raw-association-acceptance-20261011')
SUCCESS = 'PASS complete unchanged original reader checkpoint; ignored-stream recovery and full raw parent acceptance remain open.\n'
RETAIN_COMMAND = ['python3', '-B', '-c',
    'import json,sys;exec(json.load(open(sys.argv[1]))["read_only_programme"])',
    str(PRIOR / 'retention-verification.json')]
FOCUSED = ['prove', '-v', 't/1549-task-tree-integrity-doctrine.t',
    't/1636-claim-verification-doctrine.t', 't/1303-isf-public-live-book-paths-audit.t',
    't/1305-isf-book-feature-matrix-audit.t']


def read(path):
    raw = local(path).read_bytes()
    value = json.loads(raw)
    need(raw == canonical(value), 'whole canonical checkpoint record')
    return value


def instruments():
    paths = [BASE / name for name in ('checks.py', 'verify.py', 'publish.py')]
    return dict(programs(), **{str(p): dict(body=(raw := local(p).read_bytes()).decode(),
        identity=pin(raw)) for p in paths})


def nodes(raw):
    matches = list(re.finditer(rb'^- ID: `([^`]+)`\n.*?(?=^- ID: |\Z)', raw, re.M | re.S))
    result = {m[1].decode(): m[0] for m in matches}
    need(len(result) == len(matches), 'complete unique checkpoint task graph')
    return result


def field(block, name):
    match = re.search(rb'^  ' + name.encode() + rb': `(.*)`$', block, re.M)
    return match[1] if match else None


def contracts(final=None):
    original = git('show', REVISION + ':' + TASK)
    declared = gzip.decompress(local(BASE / 'declared-task.md.gz').read_bytes())
    old, start = nodes(original), nodes(declared)
    need(set(old) == set(start), 'complete original task population at activation')
    for key in old:
        need(all(field(old[key], f) == field(start[key], f) for f in ('Goal', 'Acceptance', 'Children')),
             'every original task obligation retains without narrowing')
        if key != LEAF:
            need(old[key] == start[key], 'every unrelated activation node conserves whole')
    need(field(old[LEAF], 'Status') == b'blocked' and field(start[LEAF], 'Status') == b'active'
         and field(start[OWNER], 'Status') == b'active'
         and field(start[OWNER + '.1'], 'Status') == b'done',
         'clean committed preservation precedes original remaining-reader activation')
    if final is not None:
        end = nodes(final)
        need(set(end) == set(start), 'whole checkpoint task population at closure')
        for key in start:
            if key in (OWNER, LEAF):
                need(all(field(start[key], f) == field(end[key], f) for f in ('Goal', 'Acceptance', 'Children'))
                     and field(end[key], 'Status') == b'done', 'only complete checkpoint owners close unchanged')
            else:
                need(start[key] == end[key], 'all original parents, successors and completed descendants conserve whole')
        need(all(field(end[k], 'Status') == b'active' for k in (RAW + '.5.2', RAW + '.5.2.3'))
             and all(field(end[k], 'Status') == b'pending' for k in (RAW + '.5.2.3.2', RAW + '.5.2.3.3', RAW + '.5.3')),
             'stream repair, original raw parent and canonical acceptance remain open')
    return dict(original=pin(original), declared=pin(declared), final=pin(final) if final is not None else None,
        obligations={k: {f: (field(start[k], f) or b'').decode()
                        for f in ('Goal', 'Acceptance', 'Children')} for k in (OWNER, LEAF)})


def execution_source(spec):
    return {arg: dict(body=(raw := local(arg).read_bytes()).decode(), identity=pin(raw))
            for arg in spec['command'] if Path(arg).is_file()}


def qualify_reader(row, spec, epoch, revision, source=None):
    need(type(row.get('status')) is int and row['status'] == 0, 'actual typed successful original reader status')
    need(row['command'] == spec['command'] and row['specification'] == spec,
         'whole unchanged original reader command and declared role')
    need(row.get('revision', row.get('source_revision')) == revision,
         'explicit original reader source revision')
    need(row['programmes'] == row['programmes_after'] == epoch
         and row['direct_instruments'] == row['direct_instruments_after'] == execution_source(spec),
         'whole actual original reader programme epoch')
    need(type(row['stdout']) is str and row['stderr'] == '' and spec['match'] in ('whole', 'terminal')
         and (row['stdout'] == spec['stdout'] if spec['match'] == 'whole'
              else row['stdout'].endswith(spec['stdout'])), 'whole declared original reader success stream')
    for stream in ('stdout', 'stderr'):
        need(local(row[stream + '_path']).read_bytes() == row[stream].encode(),
             'whole tracked original reader native stream bytes')
    if source is not None:
        need(row['source'] == source and row['owner'] == LEAF and row['scope'] == SCOPE,
             'whole admitted C reader source and finite owner')


def allocate(mapping, specs):
    need(set(mapping) == set(specs), 'every complete original reader role allocated exactly once')
    paths = [row['receipt'] for row in mapping.values()]
    need(len(paths) == len(set(paths)), 'unique complete original reader result allocation')
    for name, row in mapping.items():
        need(row['specification'] == specs[name], 'complete original reader role conserves')


def controls(specs, mapping, source):
    """Real changed candidates exercise the same acceptance predicates."""
    import copy
    plan = load('execution-plan.json')
    name = plan['remaining'][0]
    spec = specs[name]
    original = read(BASE / ('reader-C-' + name + '-actual.json'))
    cases = []
    candidates = [
        ('boolean-status', 'actual typed successful original reader status',
         lambda v: v.update(status=False)),
        ('omitted-terminal-status', 'actual typed successful original reader status',
         lambda v: v.pop('status')),
        ('changed-original-command', 'whole unchanged original reader command and declared role',
         lambda v: v.update(command=spec['command'] + ['--invented'])),
        ('borrowed-source-revision', 'explicit original reader source revision',
         lambda v: v.update(revision=plan['revision'][:-1] + '0')),
        ('missing-native-source', 'whole admitted C reader source and finite owner',
         lambda v: v.update(source={})),
    ]
    for label, reason, mutate in candidates:
        candidate = copy.deepcopy(original)
        mutate(candidate)
        try:
            qualify_reader(candidate, spec, plan['programmes'], REVISION, source)
        except ValueError as error:
            need(str(error) == reason, 'genuine control reaches intended original checkpoint predicate')
            cases.append(dict(name=label, candidate=candidate, refusal=str(error)))
        else:
            raise ValueError('hostile checkpoint candidate was accepted: ' + label)
    candidate = copy.deepcopy(mapping)
    candidate.pop(name)
    try:
        allocate(candidate, specs)
    except ValueError as error:
        need(str(error) == 'every complete original reader role allocated exactly once',
             'genuine complete-corpus omission reaches intended predicate')
        cases.append(dict(name='omitted-original-reader', candidate=candidate, refusal=str(error)))
    else:
        raise ValueError('incomplete original corpus was accepted')
    qualify_reader(original, spec, plan['programmes'], REVISION, source)
    return cases


def gate(name, command, success=None):
    row = load('checks.json')[name]
    need(row['command'] == ['scripts/run_with_ram_guard.sh', '--', *command]
         and type(row.get('status')) is int and row['status'] == 0
         and row['programmes'] == row['programmes_after'] == instruments()
             == load('qualification-plan.json')['programmes']
         and row['inputs'] == row['inputs_after'] and row['epoch_conserved'] is True,
         'actual complete external checkpoint gate command/status/source epoch: ' + name)
    need(type(row['stdout']) is str and type(row['stderr']) is str and re.match(
        r'ram-guard: PID [0-9]+; host [0-9]+\.[0-9]+%; host cutoff 88%; descendant RSS cutoff 4096 MiB; poll 2s\n',
        row['stderr']) is not None and 'ram-guard: host memory' not in row['stderr']
         and 'ram-guard: terminating PID tree' not in row['stderr'],
         'complete actual standard RAM-guard diagnostic without cutoff')
    if success is not None:
        need(row['stdout'] == success and row['stderr'].count('\n') == 1,
             'complete intended predecessor success: ' + name)
    for stream in ('stdout', 'stderr'):
        path = local(row[stream + '_path'], exists=False)
        need(str(path).startswith('.artifacts/raw-semantic-reader-completion-20261011/checks/'),
             'own optional same-volume external stream materialization')
        if path.exists():
            need(path.read_bytes() == row[stream].encode(), 'existing external stream bytes conserve')
    return row


def defaults():
    # These exact original declarations are themselves admitted from fixed Git.
    text = fixed_sources([str(PRIOR / 'verify.py')])[str(PRIOR / 'verify.py')].decode()
    import ast
    module = ast.parse(text)
    declaration = next(n.value for n in module.body if isinstance(n, ast.Assign)
                       and any(isinstance(t, ast.Name) and t.id == 'DEFAULTS' for t in n.targets))
    constants = {'ADMISSION': ADMISSION, 'PRIOR': ASSOCIATION, 'CONSTRUCTION': CONSTRUCTION,
                 'REPAIR': REPAIR, 'CUSTODY': CUSTODY, 'SEMANTIC': SEMANTIC}
    return eval(compile(ast.Expression(declaration), str(PRIOR / 'verify.py'), 'eval'),
                {'__builtins__': {}}, constants)


def corpus():
    source = load('intake-before.json')
    need(source == load('intake-after.json') == intake.derive(),
         'whole original source/native/product/mode/member/directory epoch across all original readers')
    plan = load('execution-plan.json')
    original_plan = read(PRIOR / 'qualification-plan.json')
    prior_proof = read(PRIOR / 'retention-proof.json')['retention']
    specs = original_plan['specifications']
    need(plan['revision'] == REVISION and plan['owner'] == LEAF
         and plan['specifications'] == specs and plan['programmes'] == programs()
         and plan['qualified_prior'] == prior_proof['qualified'] and plan['remaining'] == prior_proof['remaining'],
         'whole unchanged original corpus and first retained A/B versus C allocation')
    need(set(plan['qualified_prior']).isdisjoint(plan['remaining'])
         and set(plan['qualified_prior']) | set(plan['remaining']) == set(specs),
         'complete disjoint original-reader continuation without replacement')
    old_source = read(PRIOR / 'intake-before.json')
    need(all(source['members'].get(k) == v for k, v in old_source['members'].items()),
         'every whole original A/B input also admitted unchanged in C source custody')
    mapping = {}
    for name, entry in plan['qualified_prior'].items():
        path = PRIOR / entry['receipt']
        need(entry['identity'] == identity(path), 'whole first retained complete A/B actual')
        qualify_reader(read(path), specs[name], original_plan['programmes'], old_source['revision'])
        mapping[name] = dict(receipt=str(path), identity=identity(path), specification=specs[name])
    source_pin = pin(canonical(source))
    for name in plan['remaining']:
        stem = 'reader-C-' + name
        path = BASE / (stem + '-actual.json')
        row = read(path)
        qualify_reader(row, specs[name], programs(), REVISION, source_pin)
        guard = load(stem + '-guard-actual.json')
        need(type(guard['status']) is int and guard['status'] == 0
             and guard['command'] == ['scripts/run_with_ram_guard.sh', '--', 'python3', '-B',
                 str(BASE / 'capture.py'), '--child', '--attempt', 'C', '--name', name]
             and guard['specification'] == specs[name]
             and guard['programmes'] == guard['programmes_after'] == programs()
             and guard['stdout'] == 'PASS complete unchanged original prerequisite ' + name + '\n'
             and guard['native_stdout'] == row['stdout'] and guard['native_stderr'] == row['stderr']
             and re.fullmatch(r'ram-guard: PID [0-9]+; host [0-9]+\.[0-9]+%; host cutoff 88%; descendant RSS cutoff 4096 MiB; poll 2s\n', guard['stderr']) is not None,
             'whole successful externally captured original guarded C result without weakened limits')
        for stream in ('stdout', 'stderr'):
            need(local(guard[stream + '_path']).read_bytes() == guard[stream].encode(),
                 'whole tracked terminal original guard stream')
        mapping[name] = dict(receipt=str(path), identity=identity(path), specification=specs[name],
                             guard=identity(BASE / (stem + '-guard-actual.json')))
    allocate(mapping, specs)
    return dict(source=source_pin, readers=mapping, controls=controls(specs, mapping, source_pin))


def core():
    complete = corpus()
    preserved = gate('original-retention', RETAIN_COMMAND,
        'PASS complete dated partial-reader evidence preservation; full original corpus, stream recovery and raw parent acceptance remain open.\n')
    default_results = {}
    for timing in ('before', 'after'):
        for role, path, success in defaults():
            default_results[timing + '-' + role] = pin(canonical(gate(timing + '-' + role,
                ['python3', '-B', str(path)], success)))
    return dict(owner=LEAF, **complete, contracts=contracts(),
        preserved_epoch=pin(canonical(preserved)), predecessor_defaults=default_results,
        limits='Every C reader passes the original 88% host / 4096-MiB descendant / 2s guard. '
               'Interrupted peak RSS and the first A outer launch diagnostic remain unmeasured.',
        condition=SCOPE)


def authority(before, tasks, books, after):
    rows = [json.loads(line) for line in before.splitlines()]
    measured = metrics(tasks)['metrics']
    for row in rows:
        if row.get('surface_id') == 'task_evidence':
            need(row['state'] == 'warning_debt' and measured['lines_each'] < 7200,
                 'bounded owned checkpoint task evidence')
            for key, value in measured.items():
                need(value <= row['enforcement_ceilings'][key], 'unchanged task collection ceilings')
                row['transition']['max_growth'][key] = max(0,
                    value + row['transition']['ratchet_step'][key] - row['baseline'][key])
        elif row.get('surface_id') == 'shipped_behavior':
            baseline = metrics(books)['metrics']
            current = dict(books)
            current[BOOK] = after
            result = metrics(current)['metrics']
            keys = ('files', 'bytes_total', 'lines_total')
            row['reference_contract']['aggregate_change'] = dict(
                authority_id='RAW-ORIGINAL-READER-CHECKPOINT-20261011', owner=LEAF,
                baseline={k: baseline[k] for k in keys},
                delta={k: result[k] - baseline[k] for k in keys},
                rationale='Replace only the earlier partial-reader notice with complete unchanged original-reader checkpoint status. Stream recovery and full original parent acceptance remain open; no ceilings widen.')
    return b''.join(canonical(row) for row in rows)


def publication():
    import publish
    row = load('publication.json')
    before = gzip.decompress(local(BASE / 'book-before.md.gz').read_bytes())
    after = gzip.decompress(local(BASE / 'book-after.md.gz').read_bytes())
    old_notice = read(PRIOR / 'book-size-correction-plan.json')['addition'].encode()
    need(before == git('show', REVISION + ':' + BOOK) and before.count(old_notice) == 1
         and after == before.replace(old_notice, publish.ADDITION, 1),
         'whole exact sole owned book notice replacement and retained historical context')
    task = gzip.decompress(local(BASE / 'qualified-task.md.gz').read_bytes())
    tasks = fixed_sources(row['task_names'])
    tasks[TASK] = task
    books = fixed_sources(row['book_names'])
    registry = git('show', REVISION + ':' + SURFACES)
    need(load('task-census.json') == metrics(tasks)
         and local(BASE / 'registry-before.txt').read_bytes() == registry
         and local(BASE / 'registry-after.txt').read_bytes() == authority(registry, tasks, books, after),
         'whole measured checkpoint authority without changed ceilings or unrelated surface allowance')
    return dict(contracts=contracts(task), book=pin(after), registry=pin(local(BASE / 'registry-after.txt').read_bytes()))


def catalog():
    return {p.name: identity(p) for p in sorted(BASE.iterdir())
            if p.name not in ('checks.json', 'manifest.json')}


def full():
    external = {}
    for name, command in {'focused': FOCUSED, 'book-build': ['mdbook', 'build', 'docs/book'],
        'current-native': ['python3', '-B', 'scripts/check_record_value_publication.py', '--build', 'docs/book/book'],
        'size': ['scripts/check_live_document_size.sh'], 'claims': ['scripts/check_claim_verification.pl'],
        'inventory': ['scripts/check_claim_verification_inventory.pl']}.items():
        row = gate(name, command)
        if name == 'focused':
            need('All tests successful.' in row['stdout'], 'actual complete focused checkpoint regression success')
        external[name] = pin(canonical(row))
    return dict(checkpoint=core(), publication=publication(), external=external,
        legs=dict(rederive='Independent complete original role allocation, original native stream/programme/source custody and fresh predecessor defaults.',
            falsify='Genuine Boolean status, omitted terminal, changed command, borrowed source, missing source and omitted-reader candidates reject; all first A/B guard and fixed-context/missing-stream refusals retain unchanged.',
            durability='Complete actual original A/B/C programmes, commands, products and streams remain tracked under required-history custody. Whole source admission and exact publication/task/authority snapshots are independently sealed. Interrupted peak RSS and first A launch diagnostic are missing measurements, never inferred.'),
        condition=SCOPE)


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--core', action='store_true')
    parser.add_argument('--corpus', action='store_true')
    parser.add_argument('--seal', action='store_true')
    args = parser.parse_args()
    need(sum((args.core, args.corpus, args.seal)) <= 1, 'one explicit checkpoint qualification role')
    if args.corpus:
        corpus()
        print('PASS complete unchanged original reader corpus and whole source custody; checkpoint gates remain required.')
    elif args.core:
        core()
        print('PASS complete original-reader checkpoint obligations; publication gates remain required.')
    else:
        proof = full()
        if args.seal:
            save('proof.json', proof)
            save('manifest.json', catalog())
        else:
            need(load('proof.json') == proof and load('manifest.json') == catalog(),
                 'whole exact complete original-reader checkpoint proof and namespace')
        print(SUCCESS, end='')
