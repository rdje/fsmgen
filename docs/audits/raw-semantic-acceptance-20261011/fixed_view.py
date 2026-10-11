"""Whole unchanged prerequisite readers and an exact committed clarity context."""
import argparse
import os
import subprocess
from common import *
import intake

VIEW = Path('.artifacts/raw-semantic-acceptance-20261011/clarity-fixed-view')
BOOK = 'docs/book/src/13k-isf-feature-support-matrix.md'
SURFACES = 'doctrine/live_document_size/surfaces.jsonl'
REFUSAL = 'REFUSED complete first unlabelled book: complete historical checkpoint needs its sole explicit retained label\n'
SUCCESS = REFUSAL + 'PASS complete exact book-clarity correction, genuine retained first-book refusal, original contracts and unchanged first semantic epoch.\n'
CAUSE = 'complete current corrected book/task/authority delivery; later changes require a dated role'


def source():
    raw = git('--literal-pathspecs', 'ls-tree', '-r', '-z', REVISION, '--', str(PRIOR), str(CLARITY), TASK, BOOK, SURFACES)
    entries = {}
    for record in raw.rstrip(b'\0').split(b'\0'):
        header, name = record.split(b'\t', 1)
        mode, kind, oid = header.decode().split()
        path = name.decode()
        need(mode in ('100644', '100755') and kind == 'blob' and path not in entries, 'ordinary complete fixed clarity context')
        entries[path] = dict(mode=mode, oid=oid)
    need(all(path in entries for path in (TASK, BOOK, SURFACES, str(CLARITY / 'verification.json'))), 'whole original live clarity triple and programme')
    bodies = fixed_sources(entries)
    members = {name: dict(**entry, **pin(bodies[name]), executable=entry['mode'] == '100755') for name, entry in entries.items()}
    return bodies, members


def census():
    local(VIEW, exists=False)
    need(VIEW.is_dir(), 'ordinary same-volume clarity context root')
    files, directories = {}, {'.'}
    for path in sorted(VIEW.rglob('*')):
        local(path, exists=False)
        name = str(path.relative_to(VIEW))
        if path.is_dir():
            directories.add(name)
        else:
            files[name] = identity(path)
    return dict(members=files, directories=sorted(directories))


def expected(members, override=None):
    rows = {name: {key: row[key] for key in ('bytes', 'sha256', 'executable')} for name, row in members.items()}
    if override is not None:
        rows[TASK] = dict(**pin(override), executable=rows[TASK]['executable'])
    directories = {'.'} | {str(parent) for name in rows for parent in Path(name).parents}
    return dict(members=rows, directories=sorted(directories))


def materialize():
    bodies, members = source()
    for name, body in bodies.items():
        target = local(VIEW / name, exists=False)
        if target.exists():
            need(identity(target) == expected(members)['members'][name], 'existing complete fixed-view member unchanged')
        else:
            target.parent.mkdir(parents=True, exist_ok=True)
            target.write_bytes(body)
            target.chmod(0o755 if members[name]['executable'] else 0o644)
    need(census() == expected(members), 'whole exact committed clarity view membership/bytes/modes/directories')
    return bodies, members


def command():
    return ['python3', '-B', '-c', 'import json,sys;exec(json.load(open(sys.argv[1]))["read_only_programme"])',
            str(CLARITY / 'verification.json')]


def qualify_view(row, inputs, negative=False):
    need(row['command'] == command() and row['cwd'] == str(VIEW) and type(row['status']) is int
         and row['programmes'] == row['programmes_after'] == programs()
         and row['inputs'] == row['inputs_after'] == inputs, 'complete fixed-view actual command/programme/source epoch')
    need(local(row['stdout_path']).read_bytes() == row['stdout'].encode()
         and local(row['stderr_path']).read_bytes() == row['stderr'].encode(), 'whole actual clarity context streams')
    if negative:
        need(row['status'] != 0 and row['stdout'] == REFUSAL and row['stderr'].endswith('ValueError: ' + CAUSE + '\n'),
             'actual intended advanced-task refusal in unchanged original clarity programme')
    else:
        need(row['status'] == 0 and row['stdout'] == SUCCESS and row['stderr'] == '', 'actual complete unchanged original clarity programme in its exact dated context')


def execute_view(label, inputs, negative=False):
    need(census() == inputs, 'complete declared fixed-view candidate before execution')
    stdout, stderr = BASE / (label + '.stdout.txt'), BASE / (label + '.stderr.txt')
    started = dict(command=command(), cwd=str(VIEW), programmes=programs(), inputs=inputs,
        original_programme=local(VIEW / CLARITY / 'verification.json').read_text(),
        stdout_path=str(stdout), stderr_path=str(stderr), source_revision=REVISION,
        condition='Complete committed source context only; never later live task/book/authority currency.')
    save(label + '-started.json', started)
    with stdout.open('xb', buffering=0) as out, stderr.open('xb', buffering=0) as err:
        result = subprocess.run(command(), cwd=VIEW, stdout=out, stderr=err)
    actual = dict(**started, status=result.returncode, stdout=stdout.read_bytes().decode(), stderr=stderr.read_bytes().decode(),
                  programmes_after=programs(), inputs_after=census())
    save(label + '-actual.json', actual)
    qualify_view(actual, inputs, negative)
    return label + '-actual.json'


def view_controls():
    bodies, members = materialize()
    save('fixed-view-source.json', dict(revision=REVISION, members=members, population=expected(members),
        original_programme=bodies[str(CLARITY / 'verification.json')].decode(),
        condition='Ordinary same-volume view, no nested Git repository. Every original closure/clarity member and exact original live triple is copied whole from the committed prerequisite. Original reader programme remains unchanged; Git history reads the owning outer repository.'))
    positive = execute_view('fixed-view-positive-before', expected(members))
    advanced = local(TASK).read_bytes()
    need(advanced == bodies[TASK].replace(('- ID: `' + LEAF + '`\n  Status: `pending`\n').encode(),
        ('- ID: `' + LEAF + '`\n  Status: `active`\n').encode(), 1) and advanced != bodies[TASK],
        'genuine sole later task activation without any original contract or other source change')
    path = local(BASE / 'advanced-task-candidate.md.gz', exists=False)
    need(not path.exists(), 'retain complete first advanced-task candidate')
    path.write_bytes(gzip.compress(advanced, mtime=0))
    local(VIEW / TASK).write_bytes(advanced)
    negative = execute_view('fixed-view-advanced-task', expected(members, advanced), negative=True)
    local(VIEW / TASK).write_bytes(bodies[TASK])
    need(census() == expected(members), 'whole fixed context restored byte/mode/member/directory exactly')
    restored = execute_view('fixed-view-positive-after', expected(members))
    save('fixed-view-controls.json', dict(positive=positive, negative=negative, restored=restored,
        candidate='advanced-task-candidate.md.gz', source=pin(canonical(load('fixed-view-source.json'))), scope=SCOPE,
        meaning='The unchanged original programme passes its whole committed triple, rejects the actual later task activation, and passes again after exact restoration. The dated context never claims current live task/book/authority currency.'))
    print('PASS whole committed clarity context, genuine advanced-task refusal and exact restoration; no original programme edit or later currency.')


def replay_view():
    _, members = materialize()
    result = subprocess.run(command(), cwd=VIEW, capture_output=True)
    actual = dict(command=command(), cwd=str(VIEW), status=result.returncode, stdout=result.stdout.decode(), stderr=result.stderr.decode())
    need(type(actual['status']) is int and actual['status'] == 0 and actual['stdout'] == SUCCESS
         and actual['stderr'] == '' and census() == expected(members), 'fresh complete original clarity replay in exact committed source context')
    return actual


def specifications():
    product = json.loads(git('show', REVISION + ':' + str(ADMISSION / 'readers.json')))
    return {name: row['specification'] for name, row in product['readers'].items()}


def instruments(spec):
    return {arg: dict(body=(raw := local(arg).read_bytes()).decode(), identity=pin(raw))
            for arg in spec['command'] if Path(arg).is_file()}


def qualify_reader(row, spec):
    need(type(row.get('status')) is int and row['status'] == 0 and row['command'] == spec['command']
         and row['specification'] == spec and row['source_revision'] == REVISION, 'actual complete original prerequisite command/status/source role')
    need(row['programmes'] == row['programmes_after'] == programs()
         and row['direct_instruments'] == row['direct_instruments_after'] == instruments(spec), 'complete fresh prerequisite programme epoch')
    need(spec['match'] in ('whole', 'terminal') and row['stderr'] == ''
         and (row['stdout'] == spec['stdout'] if spec['match'] == 'whole' else row['stdout'].endswith(spec['stdout'])),
         'whole declared original prerequisite stdout role')
    need(local(row['stdout_path']).read_bytes() == row['stdout'].encode()
         and local(row['stderr_path']).read_bytes() == row['stderr'].encode(), 'complete actual prerequisite stream bytes')


def execute_reader(label, spec):
    name = label + '-actual.json'
    if (BASE / name).exists():
        row = load(name)
        qualify_reader(row, spec)
        return name
    stdout, stderr = BASE / (label + '.stdout.txt'), BASE / (label + '.stderr.txt')
    started = dict(command=spec['command'], specification=spec, source_revision=REVISION,
        programmes=programs(), direct_instruments=instruments(spec), stdout_path=str(stdout), stderr_path=str(stderr),
        condition='The exact original source or dated role is retained; no later native/current publication currency is inferred.')
    save(label + '-started.json', started)
    with stdout.open('xb', buffering=0) as out, stderr.open('xb', buffering=0) as err:
        result = subprocess.run(spec['command'], stdout=out, stderr=err)
    actual = dict(**started, status=result.returncode, stdout=stdout.read_bytes().decode(), stderr=stderr.read_bytes().decode(),
        programmes_after=programs(), direct_instruments_after=instruments(spec))
    save(name, actual)
    qualify_reader(actual, spec)
    return name


def readers(attempt):
    need(attempt and attempt.isalnum(), 'plain complete-reader attempt label')
    before = intake.derive()
    before_name = 'reader-source-before-' + attempt + '.json'
    if (BASE / before_name).exists():
        need(load(before_name) == before, 'whole original reader source epoch conserved before resume')
    else:
        save(before_name, before)
    need(before == load('intake-before.json'), 'whole source/native/product graph admitted before prerequisite execution')
    specs = specifications()
    outcomes = {}
    for name in sorted(specs, key=lambda n: (n == 'address-coordinate', n)):
        spec = specs[name]
        member = execute_reader('reader-' + attempt + '-' + name, spec)
        outcomes[name] = dict(specification=spec, receipt=member, identity=identity(BASE / member))
        print('qualified complete fresh raw-parent prerequisite', name, flush=True)
    after = intake.derive()
    need(after == before, 'every complete original source/native/product byte and directory conserves across all fresh readers')
    after_name = 'reader-source-after-' + attempt + '.json'
    save(after_name, after)
    save('readers.json', dict(owner=LEAF, revision=REVISION, scope=SCOPE, readers=outcomes,
        source_before=before_name, source_after=after_name,
        condition='Every complete original prerequisite reader is freshly executed in its exact declared source or dated role. Full first/actual programmes, commands and both streams retain; interrupted or nonzero attempts never qualify.'))


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--view-controls', action='store_true')
    parser.add_argument('--readers', action='store_true')
    parser.add_argument('--attempt')
    args = parser.parse_args()
    need(args.view_controls != args.readers, 'one explicit whole source qualification role')
    if args.view_controls:
        need(args.attempt is None, 'closed fixed-view control role')
        view_controls()
    else:
        readers(args.attempt)
