"""Record one fixed acceptance cohort outside its unchanged RAM guard."""
import argparse
import gzip
import hashlib
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import time
import traceback

import prepare
import selected_intake

ROOT, AUDIT = prepare.ROOT, prepare.AUDIT
WORK = Path('.artifacts/original-join-parent-acceptance-selected-20261018')
OWNER = prepare.premises()[0]['acceptance'] + '.2.2.3.3.2.3.2'
SUBJECT = OWNER + ': prepare selected-checkout acceptance intake'
ORDER = ('prerequisites', 'association', 'publication', 'current', 'focused', 'book', 'native_book', 'source_views')
PROGRAMMES = ('prepare.py', 'inventory.json.gz', 'execute.py', 'verify_execution.py',
              'execute_snapshot.py', 'verify_snapshot.py', 'snapshot_intake.py',
              'selected_checkout.py', 'qualify_selected_checkout.py', 'epoch_constraints.py',
              'selected_intake.py', 'selected-intake.json.gz', 'execute_selected.py',
              'verify_selected.py', 'selected_preflight.py')
MUTABLE = {prepare.TASK, 'MEMORY.md'}
RESOURCE_COMMANDS = (('sysctl', '-n', 'hw.memsize'), ('vm_stat',), ('ps', '-axo', 'pid=,ppid=,rss=,comm='))
SOURCE_LIMIT = 128 * 1024 * 1024
INPUT_LIMIT = 192 * 1024 * 1024
SAMPLE_LIMIT = 43200
SCOPE = ('Complete saved semantic rederivation and current publication checks only. '
         'Original producers are not recaptured; source-model/shared-premise/native/private limits, '
         'dated execution roles and all first failures retain. Resource samples are external observations, '
         'not occupied-capacity attribution or a guarantee about unobserved peaks. '
         'OS/toolchain executables are required read-only external dependencies. '
         'Full alias, visual, HIAL, full-CI and push remain separately owned. '
         'Historical prerequisites/association execute unchanged commands in the complete conjunctively selected physical checkout. '
         'Other cohorts retain primary source and all three failed intakes stay failed.')


def command(argv):
    result = subprocess.run(argv, capture_output=True, cwd=ROOT, timeout=60)
    assert result.returncode == 0 and not result.stderr, (argv, result.returncode, result.stderr)
    return result.stdout


def safe(path):
    """Check parents without following a foreign directory or repository."""
    path = ROOT / path
    assert path.is_relative_to(ROOT)
    assert '..' not in path.relative_to(ROOT).parts
    for parent in reversed(path.parents):
        if parent == ROOT:
            continue
        if not parent.is_relative_to(ROOT):
            continue
        assert not parent.is_symlink()
        if parent.exists():
            assert parent.is_dir() and parent.stat().st_dev == ROOT.stat().st_dev
            if parent == ROOT / '.git' and path == ROOT / '.git/index':
                continue  # The primary index is an explicitly owned read-only input.
            assert not (parent / '.git').exists()
            assert not ((parent / 'HEAD').exists() and (parent / 'objects').exists())
    return path


def read(path):
    path = safe(path)
    assert path.is_file() and not path.is_symlink() and path.stat().st_dev == ROOT.stat().st_dev
    return path.read_bytes()


def save(path, value):
    path = safe(path)
    with path.open('xb') as stream:
        stream.write(gzip.compress(prepare.encoded(value), mtime=0))


def tree(revision):
    result = {}
    for row in command(['git', '--no-replace-objects', 'ls-tree', '-r', '-z', revision]).split(b'\0'):
        if not row:
            continue
        header, name = row.split(b'\t', 1)
        mode, kind, oid = header.decode().split()
        assert name.decode() not in result
        result[name.decode()] = (mode, kind, oid)
    return result


def qualification():
    revision = command(['git', '--no-replace-objects', 'log', '-1', '--format=%H',
                        '--fixed-strings', '--grep=' + SUBJECT]).decode().strip()
    assert len(revision) == 40, 'commit recorder preparation before acceptance execution'
    assert command(['git', '--no-replace-objects', 'show', '-s', '--format=%s', revision]).decode().strip() == SUBJECT
    for name in PROGRAMMES:
        path = str(AUDIT / name)
        assert command(['git', '--no-replace-objects', 'show', revision + ':' + path]) == read(path), path
    return revision


def admission(revision):
    """Require committed successful inert custody before any acceptance launch."""
    records = {}
    for name in ('selected-intake-qualification-final-started.json.gz',
                 'selected-intake-qualification-final-actual.json.gz',
                 'selected-preflight-final-qualified.json.gz'):
        path = AUDIT / name
        body = read(path)
        assert command(['git', '--no-replace-objects', 'show', revision + ':' + str(path)]) == body
        records[name] = json.loads(gzip.decompress(body))
    started = records['selected-intake-qualification-final-started.json.gz']
    actual = records['selected-intake-qualification-final-actual.json.gz']
    proof = records['selected-preflight-final-qualified.json.gz']
    assert all(actual[key] == value for key, value in started.items())
    assert type(actual['status']) is int and actual['status'] == 0
    assert prepare.unblob(actual['stdout']) == (
        b'Selected-checkout closed source/cwd/command/contract/custody/stop/resource/book '
        b'controls pass; no semantic reader or acceptance cohort executes.\n')
    stderr = prepare.unblob(actual['stderr'])
    assert stderr.startswith(b'ram-guard: PID ') and b'ram-guard: terminating PID tree' not in stderr
    assert actual['source_after'] == dict(value=started['sources'], error=None)
    assert actual['tools_after'] == dict(value=started['tools'], error=None)
    assert actual['primary_after']['error'] is None
    assert all(actual['primary_after']['value'][key] == started['primary'][key] for key in ('head', 'entries'))
    assert proof['schema'] == 'fsmgen.selected_intake_inert_qualification.v1'
    assert proof['slots_before'] == proof['slots_after']
    assert all(value is None for name, value in proof['slots_before'].items()
               if Path(name).name.startswith('selected-'))
    assert selected_intake.validate(proof['profile'])
    for name, row in started['sources'].items():
        assert command(['git', '--no-replace-objects', 'show', revision + ':' + name]) == prepare.unblob(row)
    return True


def selected(name):
    path = Path(name)
    return (path.suffix in ('.py', '.pl', '.pm', '.sh', '.t', '.md') or name.startswith('bin/')
            or name.startswith(('docs/knowledge/', 'docs/decisions/', 'knowledge-map/'))
            or name in MUTABLE
            or name in ('docs/book/src/13k-isf-feature-support-matrix.md', 'docs/book/src/90-reference-map.md',
                        'docs/book/src/reference-source/routes.jsonl')
            or name == 'docs/audits/book-reference-selection-20261005/selected-routes.json'
            or (name.startswith('doctrine/') and path.suffix in ('.json', '.jsonl', '.tsv'))
            or name in {str(AUDIT / part) for part in PROGRAMMES})


def source_epoch(revision):
    for staged in (False, True):
        argv = ['git', '--no-replace-objects', 'diff', '--name-only', '-z']
        if staged:
            argv.append('--cached')
        changed = {name.decode() for name in command([*argv, 'HEAD']).split(b'\0') if name}
        assert changed <= MUTABLE, 'unrelated in-flight changes: ' + repr(sorted(changed - MUTABLE))
    rows = source_snapshot(tree(revision))
    assert index_matches(rows, command(['git', '--no-replace-objects', 'ls-files', '--stage', '-z']))
    return rows


def index_matches(rows, entries):
    indexed = {}
    for entry in entries.split(b'\0'):
        if not entry:
            continue
        header, name = entry.split(b'\t', 1)
        mode, oid, stage = header.decode().split()
        assert stage == '0' and name.decode() not in indexed
        indexed[name.decode()] = (mode, oid)
    for name, row in rows.items():
        body = prepare.unblob(row)
        oid = hashlib.sha1(b'blob ' + str(len(body)).encode() + b'\0' + body).hexdigest()
        assert indexed.get(name) == (row['mode'], oid), 'stage exact source input before execution: ' + name
    return True


def source_snapshot(expected):
    rows, total = {}, 0
    manifest_name = 'docs/book/src/reference-source/routes.jsonl'
    manifest = read(manifest_name)
    assert hashlib.sha1(b'blob ' + str(len(manifest)).encode() + b'\0' + manifest).hexdigest() == expected[manifest_name][2]
    routed = {row['source'] for row in map(json.loads, manifest.splitlines())}
    assert routed <= expected.keys()
    for name, (mode, kind, oid) in expected.items():
        if kind != 'blob' or not (selected(name) or name in routed):
            continue  # Gitlinks are opaque; never enumerate a submodule.
        path = safe(name)
        if mode == '120000':
            assert path.is_symlink()
            body = os.fsencode(os.readlink(path))  # Preserve the link; do not inspect its target.
        else:
            assert mode in ('100644', '100755')
            body = read(name)
            assert bool(path.stat().st_mode & 0o111) == (mode == '100755')
        total += len(body)
        assert total <= INPUT_LIMIT, 'bounded current source population'
        if name not in MUTABLE:
            actual = hashlib.sha1(b'blob ' + str(len(body)).encode() + b'\0' + body).hexdigest()
            assert actual == oid, 'source differs from committed preparation: ' + name
        rows[name] = dict(prepare.blob(body), mode=mode)
    assert set(str(AUDIT / name) for name in PROGRAMMES) <= rows.keys()
    plan, _, original, _ = prepare.premises()
    assert prepare.check_contracts(prepare.unblob(rows[prepare.TASK]), original, plan)
    unknown = command(['git', '--no-replace-objects', 'ls-files', '--others', '--exclude-standard', '-z'])
    assert not {name.decode() for name in unknown.split(b'\0') if name and selected(name.decode())} - expected.keys(), 'untracked source input'
    return rows


def source_ref(rows):
    body = gzip.compress(prepare.encoded(rows), mtime=0)
    name = AUDIT / ('execution-sources-' + hashlib.sha256(body).hexdigest() + '.json.gz')
    path = safe(name)
    try:
        with path.open('xb') as stream:
            stream.write(body)
    except FileExistsError:
        assert read(name) == body
    return dict(path=str(name), **prepare.identity(body))


def git_state():
    return dict(head=command(['git', '--no-replace-objects', 'rev-parse', 'HEAD']).decode().strip(),
                entries=prepare.blob(command(['git', '--no-replace-objects', 'ls-files', '--stage', '-z'])),
                index=prepare.blob(read('.git/index')))


def tools():
    result = {}
    for name in ('python3', 'perl', 'git', 'bash', 'mdbook', 'sysctl', 'vm_stat', 'ps'):
        found = shutil.which(name)
        assert found, 'required tool unavailable: ' + name
        path = Path(found).resolve(strict=True)
        result[name] = dict(path=str(path), **prepare.identity(path.read_bytes()))
    return result


def sample(origin):
    result = []
    for argv in RESOURCE_COMMANDS:
        actual = subprocess.run(argv, capture_output=True, cwd=ROOT, timeout=30)
        result.append(dict(command=list(argv), status=actual.returncode,
                           stdout=prepare.blob(actual.stdout), stderr=prepare.blob(actual.stderr)))
    return dict(elapsed_seconds=time.monotonic() - origin, native=result)


def observe(function):
    """Retain observation gaps after launch without abandoning the guarded child."""
    try:
        return dict(value=function(), error=None)
    except Exception:
        return dict(value=None, error=traceback.format_exc())


def book_epoch():
    previous = sys.path[:]
    try:
        sys.path.insert(0, str(ROOT / 'scripts'))
        import book_source_references as plane
    finally:
        sys.path[:] = previous
    rows = plane.expected_rows()
    names = {'13k-isf-feature-support-matrix.html', '90-reference-map.html', 'reference-source/routes.jsonl'}
    names.update(row['asset'] for row in rows)
    names.update(str(asset.relative_to(ROOT / 'docs/book/src')) for _, asset, _ in plane.endpoints(rows))
    result, total = {}, 0
    for name in sorted(names):
        path = safe(Path('docs/book/book') / name)
        assert path.resolve(strict=True).is_relative_to(ROOT)
        assert path.stat().st_dev == ROOT.stat().st_dev and path.is_file()
        body = path.read_bytes()
        total += len(body)
        assert total <= SOURCE_LIMIT
        result[name] = dict(prepare.blob(body), symlink_target=os.readlink(path) if path.is_symlink() else None)
    return result


def main(label):
    assert Path.cwd().resolve() == ROOT and not os.environ.get('PERL5OPT')
    assert label in ORDER
    revision = qualification()
    profile = json.loads(gzip.decompress(read(AUDIT / 'selected-intake.json.gz')))
    inventory = selected_intake.effective(profile)
    assert set(ORDER) == set(inventory['cohorts'])
    import verify_selected as verify_execution
    priors = []
    for previous in ORDER[:ORDER.index(label)]:
        prior = verify_execution.verify(previous)
        assert prior['qualification'] == revision, 'a prior cohort used a different preparation'
        priors.append(prior)
    assert admission(revision)
    before = source_epoch(revision)
    reference, git_before = source_ref(before), git_state()
    assert all(prior['source_before'] == reference and prior['git_before']['head'] == git_before['head']
               and prior['git_before']['entries'] == git_before['entries'] for prior in priors), 'cohort source/index epochs differ'
    task = prepare.nodes(prepare.unblob(before[prepare.TASK]))
    acceptance = inventory['acceptance']
    assert prepare.field(task[acceptance + '.2.1'], 'Status') == 'done'
    assert prepare.field(task[acceptance + '.2.2'], 'Status') == 'active'
    assert prepare.field(task[acceptance + '.2.2.2'], 'Status') == 'done'
    assert prepare.field(task[acceptance + '.2.2.3'], 'Status') == 'active'
    assert prepare.field(task[acceptance + '.2.2.3.2'], 'Status') == 'done'
    assert prepare.field(task[acceptance + '.2.2.3.3'], 'Status') == 'active'
    assert prepare.field(task[acceptance + '.2.2.3.3.1'], 'Status') == 'done'
    assert prepare.field(task[acceptance + '.2.2.3.3.2'], 'Status') == 'active'
    assert prepare.field(task[acceptance + '.2.2.3.3.2.3.1'], 'Status') == 'done'
    assert prepare.field(task[acceptance + '.2.2.3.3.2.3.2'], 'Status') == 'done'
    assert prepare.field(task[acceptance + '.2.2.3.3.2.3.3'], 'Status') == 'active'
    working_directory = selected_intake.cwd(label, profile)
    historical_before = selected_intake.observe_snapshot() if label in selected_intake.HISTORICAL else None
    folder = safe(WORK / label)
    folder.mkdir(parents=True, exist_ok=False)
    started = dict(schema='fsmgen.original_acceptance_execution.v4', owner=acceptance + '.2.2.3.3.2.3.3',
                   working_directory=working_directory, snapshot_before=historical_before,
                   label=label, qualification=revision, scope=SCOPE, command=['scripts/run_with_ram_guard.sh', '--',
                   *inventory['cohorts'][label]['command']], source_before=reference,
                   git_before=git_before, tools_before=tools(), recorder_pid=os.getpid(),
                   book_before=book_epoch() if label in ('native_book', 'source_views') else None)
    save(AUDIT / ('selected-' + label + '-started.json.gz'), started)
    origin = time.monotonic()
    samples = [observe(lambda: sample(origin))]
    status, launch_error = None, None
    with (folder / 'stdout').open('xb', buffering=0) as out, (folder / 'stderr').open('xb', buffering=0) as err:
        ready = samples[0]['value']
        if ready is None or not all(row['status'] == 0 and prepare.unblob(row['stdout'])
                                    and not prepare.unblob(row['stderr']) for row in ready['native']):
            launch_error = 'resource observation failed before cohort launch'
        else:
            try:
                process = subprocess.Popen(started['command'], cwd=ROOT / working_directory, stdout=out, stderr=err)
            except Exception:
                launch_error = traceback.format_exc()
            else:
                while process.poll() is None:
                    try:
                        process.wait(timeout=2)
                    except subprocess.TimeoutExpired:
                        if len(samples) < SAMPLE_LIMIT:
                            samples.append(observe(lambda: sample(origin)))
                status = process.returncode
        samples.append(observe(lambda: sample(origin)))
    # Save native status and streams even if any post-run custody observation fails.
    after = observe(lambda: source_ref(source_epoch(revision)))
    actual = dict(started, status=status, launch_error=launch_error, source_after=after,
                  git_after=observe(git_state), tools_after=observe(tools), samples=samples,
                  resource_complete=len(samples) < SAMPLE_LIMIT,
                  snapshot_after=observe(selected_intake.observe_snapshot) if label in selected_intake.HISTORICAL else None,
                  book_after=observe(book_epoch) if label in ('book', 'native_book', 'source_views') else None,
                  stdout=prepare.blob((folder / 'stdout').read_bytes()),
                  stderr=prepare.blob((folder / 'stderr').read_bytes()))
    save(AUDIT / ('selected-' + label + '-actual.json.gz'), actual)
    print(label, 'actual status', status, flush=True)
    verify_execution.verify(label)


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('cohort', choices=ORDER)
    main(parser.parse_args().cohort)
