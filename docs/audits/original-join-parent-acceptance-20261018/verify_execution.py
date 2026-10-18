"""Read exact saved execution custody; historical replay never reads live task status."""
import argparse
import ast
import contextlib
import gzip
import importlib.abc
import importlib.util
import json
from pathlib import Path
import re
import sys

import execute
import prepare

ROOT, AUDIT = execute.ROOT, execute.AUDIT
MANIFEST = 'docs/book/src/reference-source/routes.jsonl'


def unblob(row):
    assert type(row) is dict
    assert set(row) in ({'bytes', 'sha256', 'body_base64'}, {'bytes', 'sha256', 'body_base64', 'mode'},
                        {'bytes', 'sha256', 'body_base64', 'symlink_target'})
    assert type(row['bytes']) is int and row['bytes'] >= 0
    assert type(row['sha256']) is str and re.fullmatch('[0-9a-f]{64}', row['sha256'])
    assert type(row['body_base64']) is str
    return prepare.unblob(row)


def load(path):
    return json.loads(gzip.decompress(execute.read(path)))


def sources(reference):
    assert set(reference) == {'path', 'bytes', 'sha256'}
    assert type(reference['bytes']) is int and reference['bytes'] > 0
    assert type(reference['sha256']) is str and re.fullmatch('[0-9a-f]{64}', reference['sha256'])
    assert reference['path'] == str(AUDIT / ('execution-sources-' + reference['sha256'] + '.json.gz'))
    body = execute.read(reference['path'])
    assert prepare.identity(body) == {key: reference[key] for key in ('bytes', 'sha256')}
    rows = json.loads(gzip.decompress(body))
    for row in rows.values():
        unblob(row)
    return rows


def validate_sources(rows, revision):
    expected = execute.tree(revision)
    routes = [json.loads(line) for line in prepare.unblob(rows[MANIFEST]).splitlines()]
    wanted = {name for name, (_, kind, _) in expected.items() if kind == 'blob' and execute.selected(name)}
    wanted.update(row['source'] for row in routes)
    assert set(rows) == wanted
    for name, row in rows.items():
        mode, kind, oid = expected[name]
        assert kind == 'blob' and row['mode'] == mode
        body = prepare.unblob(row)
        if name not in execute.MUTABLE:
            assert execute.hashlib.sha1(b'blob ' + str(len(body)).encode() + b'\0' + body).hexdigest() == oid, name
    plan, _, original, _ = prepare.premises()
    task = prepare.unblob(rows[prepare.TASK])
    assert prepare.check_contracts(task, original, plan)
    nodes = prepare.nodes(task)
    assert prepare.field(nodes[plan['acceptance'] + '.2.1'], 'Status') == 'done'
    assert prepare.field(nodes[plan['acceptance'] + '.2.2'], 'Status') == 'active'
    assert all(prepare.field(nodes[plan[key]], 'Status') == 'active'
               for key in ('family', 'join', 'parent', 'acceptance'))
    assert prepare.field(nodes[plan['full_alias']], 'Status') == 'pending'
    return True


@contextlib.contextmanager
def frozen_public(rows, closure):
    """Use the qualified frozen-loader pattern with the separately bound current closure."""
    programmes = {Path(name).stem: (name, prepare.unblob(rows[name])) for name in closure['modules']}
    assert all(prepare.identity(body) == closure['modules'][name] for name, body in programmes.values())
    known = {Path(name).stem for name in closure['available_modules']}

    class Loader(importlib.abc.MetaPathFinder, importlib.abc.Loader):
        def find_spec(self, fullname, path=None, target=None):
            if fullname in programmes:
                return importlib.util.spec_from_loader(fullname, self)
            if fullname in known:
                raise ModuleNotFoundError('uncaptured project module: ' + fullname)
            return None

        def create_module(self, spec):
            return None

        def exec_module(self, module):
            name, body = programmes[module.__name__]
            module.__file__ = name
            exec(compile(body, name, 'exec'), module.__dict__)

    previous = {name: sys.modules[name] for name in known if name in sys.modules}
    finder = Loader()
    try:
        for name in known:
            sys.modules.pop(name, None)
        sys.meta_path.insert(0, finder)
        factory = __import__('check_record_value_publication')
        original_read = factory.plane.local_read

        def read(path, maximum):
            name = str(path.relative_to(ROOT))
            if name in rows:
                body = prepare.unblob(rows[name])
                assert len(body) <= maximum
                return body
            return original_read(path, maximum)

        factory.plane.local_read = read
        yield factory
    finally:
        sys.meta_path.remove(finder)
        for name in known:
            sys.modules.pop(name, None)
        sys.modules.update(previous)


def validate_book(book, rows, inventory):
    for row in book.values():
        unblob(row)
        assert row['symlink_target'] is None, 'native source views are regular copied files'
    routes = [json.loads(line) for line in prepare.unblob(rows[MANIFEST]).splitlines()]
    assert set(book) == {row['asset'] for row in routes} | {
        '13k-isf-feature-support-matrix.html', '90-reference-map.html', 'reference-source/routes.jsonl'}
    assert prepare.unblob(book['reference-source/routes.jsonl']) == prepare.unblob(rows[MANIFEST])
    for route in routes:
        assert prepare.unblob(book[route['asset']]) == prepare.unblob(rows[route['source']])
    with frozen_public(rows, inventory['current_module_closure']) as factory:
        prior = factory.historical()
        factory.check_native(prepare.unblob(book['13k-isf-feature-support-matrix.html']).decode(), prior)
        factory.check_tooling_native(prepare.unblob(book['90-reference-map.html']).decode(), prior)
    return True


def success_text(rows, path):
    tree = ast.parse(prepare.unblob(rows[path]), filename=path)
    values = [node.value.value for node in tree.body if isinstance(node, ast.Assign)
              and any(isinstance(target, ast.Name) and target.id == 'SUCCESS' for target in node.targets)
              and isinstance(node.value, ast.Constant) and isinstance(node.value.value, str)]
    assert len(values) == 1
    return values[0].encode()


def validate_resources(samples, complete):
    assert complete is True and 2 <= len(samples) < execute.SAMPLE_LIMIT
    elapsed = -1
    for sample in samples:
        assert sample['error'] is None
        actual = sample['value']
        assert type(actual['elapsed_seconds']) is float and elapsed < actual['elapsed_seconds']
        elapsed = actual['elapsed_seconds']
        assert len(actual['native']) == len(execute.RESOURCE_COMMANDS)
        for native, command in zip(actual['native'], execute.RESOURCE_COMMANDS, strict=True):
            assert native['command'] == list(command) and type(native['status']) is int and native['status'] == 0
            assert unblob(native['stdout']) and unblob(native['stderr']) == b''
    return True


def validate_tools(tools):
    assert set(tools) == {'python3', 'perl', 'git', 'bash', 'mdbook', 'sysctl', 'vm_stat', 'ps'}
    for tool in tools.values():
        assert set(tool) == {'path', 'bytes', 'sha256'}
        assert type(tool['path']) is str and Path(tool['path']).is_absolute()
        assert type(tool['bytes']) is int and tool['bytes'] > 0
        assert type(tool['sha256']) is str and re.fullmatch('[0-9a-f]{64}', tool['sha256'])
    return True


def validate_streams(label, stdout, stderr, rows, inventory):
    assert re.match(rb'ram-guard: PID \d+; host \d+\.\d+%; host cutoff 88%; descendant RSS cutoff 4096 MiB; poll 2s\n', stderr)
    assert b'ram-guard: terminating PID tree' not in stderr
    if label in ('prerequisites', 'association', 'publication', 'current', 'native_book'):
        path = inventory['cohorts'][label]['command'][2]
        assert stdout == success_text(rows, path)
    elif label == 'focused':
        assert stdout == b'' and re.search(rb'\nRan 33 tests in [\d.]+s\n\nOK\n$', stderr)
    elif label == 'source_views':
        assert stdout == b'book-source-references: complete source/role/member/relative-endpoint/current-byte/ignore contracts hold\n'
    else:
        assert label == 'book'
    return True


def validate(label, row, started):
    assert row['label'] == started['label'] == label and label in execute.ORDER
    assert set(started) == {'schema', 'owner', 'label', 'qualification', 'scope', 'command', 'source_before',
                            'git_before', 'tools_before', 'recorder_pid', 'book_before'}
    assert all(row[key] == value for key, value in started.items())
    assert set(row) == set(started) | {'status', 'launch_error', 'source_after', 'git_after', 'tools_after',
                                      'samples', 'resource_complete', 'book_after', 'stdout', 'stderr'}
    assert row['schema'] == 'fsmgen.original_acceptance_execution.v1' and row['scope'] == execute.SCOPE
    assert label in execute.ORDER and type(row['status']) is int and row['status'] == 0
    assert row['launch_error'] is None
    assert type(row['recorder_pid']) is int and row['recorder_pid'] > 0
    assert re.fullmatch('[0-9a-f]{40}', row['qualification'])
    assert execute.command(['git', '--no-replace-objects', 'show', '-s', '--format=%s', row['qualification']]).decode().strip() == execute.SUBJECT
    rows = sources(row['source_before'])
    assert validate_sources(rows, row['qualification'])
    inventory = json.loads(gzip.decompress(prepare.unblob(rows[str(AUDIT / 'inventory.json.gz')])))
    assert prepare.validate(inventory)
    assert row['owner'] == inventory['acceptance'] + '.2.2'
    assert row['command'] == ['scripts/run_with_ram_guard.sh', '--', *inventory['cohorts'][label]['command']]
    assert row['source_after'] == {'value': row['source_before'], 'error': None}
    assert row['git_after']['error'] is None and row['tools_after'] == {'value': row['tools_before'], 'error': None}
    assert validate_tools(row['tools_before'])
    after = row['git_after']['value']
    assert after['head'] == row['git_before']['head']
    assert after['entries'] == row['git_before']['entries']
    for state in (row['git_before'], after):
        assert set(state) == {'head', 'entries', 'index'} and re.fullmatch('[0-9a-f]{40}', state['head'])
        unblob(state['entries'])
        unblob(state['index'])  # Raw stat-cache changes retain as observations, never entry changes.
        assert execute.index_matches(rows, prepare.unblob(state['entries']))
    assert validate_resources(row['samples'], row['resource_complete'])
    assert validate_streams(label, unblob(row['stdout']), unblob(row['stderr']), rows, inventory)
    if label in ('book', 'native_book', 'source_views'):
        assert row['book_after']['error'] is None
        assert validate_book(row['book_after']['value'], rows, inventory)
    else:
        assert row['book_after'] is None
    if label in ('native_book', 'source_views'):
        assert row['book_before'] == row['book_after']['value']
    else:
        assert row['book_before'] is None
    return True


def verify(label):
    assert label in execute.ORDER
    row = load(AUDIT / (label + '-actual.json.gz'))
    started = load(AUDIT / (label + '-started.json.gz'))
    assert validate(label, row, started)
    return row


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('cohort', choices=execute.ORDER)
    args = parser.parse_args()
    verify(args.cohort)
    print('Complete saved execution source/stream/resource/book custody passes:', args.cohort)
