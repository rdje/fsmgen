"""Qualify actual producer behavior and exact fixed derived-output evidence."""
import argparse
import ast
import gzip
import hashlib
import json
from pathlib import Path
import re

import bounded_runtime_inventory as typed
import execute
import prepare
import runtime_cache_producer as producer

PATH = execute.AUDIT / 'runtime-cache-producer-final-qualified.json.gz'


def load(suffix):
    return json.loads(gzip.decompress(execute.read(Path(str(producer.PREFIX) + '-' + suffix + '.json.gz'))))


def independent_rows(bodies):
    digest, rows = hashlib.sha256(), []
    for name in sorted(bodies):
        if Path(name).parent == Path('knowledge-map/generated') and name.endswith('.md'):
            body = bodies[name]
            digest.update(name.encode() + b'\0' + body + b'\0')
            for line in body.decode('utf-8').splitlines():
                if not line.startswith('- q='):
                    continue
                question, separator, links = line[4:].partition(' · facts=')
                assert separator
                value = json.loads(question)
                assert type(value) is str
                owners, sources = [], []
                for match in re.finditer(r'\[([a-z0-9]+(?:-[a-z0-9]+)*)\]\(\.\./\.\./([^\)]+)\)', links):
                    owners.append(match[1])
                    sources.append(match[2])
                assert owners
                rows.append(dict(record_type='question', question=value, ids=owners, sources=sources))
    rows = sorted(rows, key=lambda row: row['question'])
    return [dict(record_type='cache', schema_version=1, fingerprint=digest.hexdigest()), *rows]


def full_body(node):
    assert type(node['bytes']) is int and node['bytes'] >= 0
    return prepare.unblob(node)


def source_nodes(state, bodies, modes):
    for name, body in bodies.items():
        node = state['files'][name]
        assert node['kind'] == 'file' and node['mode'] == modes[name]
        assert set(node) == {'kind', 'mode', 'uid', 'inode', 'links', 'mtime_ns', 'ctime_ns', 'bytes', 'sha256', 'body_base64'}
        assert all(type(node[key]) is int and node[key] >= 0 for key in ('mode', 'uid', 'inode', 'links', 'mtime_ns', 'ctime_ns'))
        assert node['links'] == 1 and full_body(node) == body


def fixed_output(state, bodies, modes, canonical):
    """Evidence predicate only; the complete default runtime contract is separate."""
    try:
        source_nodes(state, bodies, modes)
        assert set(state['files']) == set(bodies) | {str(producer.CACHE)}
        expected_dirs = {str(parent) for name in state['files'] for parent in Path(name).parents if str(parent) != '.'}
        assert state['directories'] == sorted(expected_dirs)
        cache = state['files'][str(producer.CACHE)]
        assert cache['kind'] == 'file' and type(cache['mode']) is int and cache['mode'] == 0o644
        assert type(cache['links']) is int and cache['links'] == 1
        assert all(cache['uid'] == state['files'][name]['uid'] for name in bodies)
        actual = [json.loads(line) for line in full_body(cache).splitlines()]
        assert typed.strict_equal(actual, canonical)
        assert full_body(cache) == producer.wire(canonical)
    except (AssertionError, KeyError, ValueError):
        return False
    return True


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--write', action='store_true')
    args = parser.parse_args()
    start, finish = load('started'), load('actual')
    tree, members, bodies = producer.projection()
    assert start['revision'] == producer.epoch.REVISION and prepare.unblob(start['tree']) == tree
    assert start['members'] == members and set(start['bodies']) == set(bodies)
    assert all(full_body(start['bodies'][name]) == body for name, body in bodies.items())
    assert set(start['sources']) == set(producer.NAMES)
    assert all(full_body(start['sources'][name]) == execute.read(execute.AUDIT / name) for name in producer.NAMES)
    assert finish['started'] == prepare.identity(execute.read(Path(str(producer.PREFIX) + '-started.json.gz')))
    assert finish['completed'] == list(producer.LABELS) and finish['error'] is None
    assert finish['sources_after'] == dict(value=start['sources'], error=None)
    assert finish['tools_after'] == dict(value=start['tools'], error=None)
    assert finish['protected_after'] == dict(value=start['protected'], error=None)
    assert finish['primary_after']['error'] is None
    assert all(finish['primary_after']['value'][key] == start['primary'][key] for key in ('head', 'entries'))
    records = independent_rows(bodies)
    assert typed.strict_equal(records, producer.derive(bodies))
    modes = {name: 0o755 if row['mode'] == '100755' else 0o644 for name, row in members.items()}
    before_refuse, after_refuse, preserved_noncanonical = [], [], []
    cases = {}
    for label in producer.LABELS:
        row = load(label)
        assert row['label'] == label and row['working_directory'] == str(producer.ROOT / label)
        assert row['resource_guard'] == 'scripts/run_with_ram_guard.sh'
        assert type(row['root_probe']['status']) is int and row['root_probe']['status'] != 0
        assert full_body(row['root_probe']['stdout']) == b''
        expected_env = dict(git_search_ceiling='.artifacts', temporary_directory='.artifacts/tmp', inherited_KM_GIT_removed=True)
        if label in ('traversal', 'symlink'):
            expected_env['KM_QUERY_CACHE_DIR'] = '../escape' if label == 'traversal' else 'link-cache/query'
        assert typed.strict_equal(row['environment'], expected_env)
        expected_args = ['MeMoRy'] if label == 'filtered' else ['--all']
        if label.startswith('no_cache'): expected_args.append('--no-cache')
        assert row['command'] == ['knowledge-map/scripts/query_knowledge_map.sh', *expected_args]
        active, active_modes = dict(bodies), dict(modes)
        if label == 'source_bytes':
            name = next(name for name in sorted(bodies) if name.startswith('knowledge-map/generated/') and name.endswith('.md'))
            active[name] += b'\n'
        elif label == 'extra_member':
            name = 'knowledge-map/generated/zz-cache-control.md'
            active[name] = b'- q="__isolated cache member control__" \xc2\xb7 facts=[cache-control](../../docs/knowledge/cache-control.md)\n'
            active_modes[name] = 0o644
        assert type(row['source_is_fixed']) is bool and row['source_is_fixed'] == (active == bodies)
        expected = independent_rows(active)
        assert full_body(row['derived_input']) == producer.wire(expected)
        absent_before = label in ('cold', 'no_cache_absent', 'traversal', 'symlink')
        absent_after = label in ('no_cache_absent', 'traversal', 'symlink')
        for state, absent in ((row['before'], absent_before), (row['after'], absent_after)):
            source_nodes(state, active, active_modes)
            names = set(active) | (set() if absent else {str(producer.CACHE)})
            if label == 'symlink': names.add('link-cache')
            assert set(state['files']) == names, 'complete control fixture file membership'
            directories = {str(parent) for name in names for parent in Path(name).parents if str(parent) != '.'}
            if label == 'symlink':
                directories.add('protected')
                assert state['files']['link-cache'] == dict(kind='symlink', target='protected')
            assert state['directories'] == sorted(directories), 'complete directory membership'
        if not absent_before:
            cache_before = row['before']['files'][str(producer.CACHE)]
            assert cache_before['kind'] == 'file' and cache_before['mode'] == (0o777 if label == 'mode' else 0o644)
            initial = records
            changes = {
                'schema_value': ((0, 'schema_version'), lambda _: 2),
                'schema_kind': ((0, 'schema_version'), lambda _: '1'),
                'fingerprint': ((0, 'fingerprint'), lambda _: '0' * 64),
                'missing_row': ((), lambda rows: rows[:-1]),
                'extra_row': ((), lambda rows: [*rows, rows[-1]]),
                'owner': ((1, 'ids', 0), lambda _: 'wrong-owner'),
                'source': ((1, 'sources', 0), lambda _: 'docs/knowledge/wrong-source.md'),
                'row_kind': ((1, 'ids'), lambda _: 'wrong-type'),
                'unknown_field': ((0,), lambda header: dict(header, unexpected=True)),
            }
            if label in changes:
                path, transform = changes[label]
                initial = typed.changed(records, path, transform)
            wanted_before = b'not-json\n' if label in ('invalid_json', 'no_cache_invalid') else producer.wire(initial)
            assert full_body(cache_before) == wanted_before, 'actual separating cache intervention'
        assert all(row['before']['files'][name] == row['after']['files'][name] for name in active)
        stderr = full_body(row['stderr'])
        assert re.match(rb'ram-guard: PID [0-9]+; host [0-9.]+%; host cutoff 88%; descendant RSS cutoff 4096 MiB; poll 2s\n', stderr)
        assert b'ram-guard: terminating PID tree' not in stderr
        assert type(row['status']) is int
        if label in ('traversal', 'symlink'):
            assert row['status'] != 0 and full_body(row['stdout']) == b''
            assert b'unsafe KM_QUERY_CACHE_DIR ' in stderr and row['before'] == row['after']
        else:
            assert row['status'] == 0
            wanted = b''.join(('\t'.join((item['question'], ','.join(item['ids']), ','.join(item['sources']))) + '\n').encode()
                              for item in expected[1:] if label != 'filtered' or 'memory' in item['question'].lower())
            assert full_body(row['stdout']) == wanted
        before = fixed_output(row['before'], bodies, modes, records)
        after = fixed_output(row['after'], bodies, modes, records)
        if not before: before_refuse.append(label)
        if not after: after_refuse.append(label)
        cache = str(producer.CACHE)
        if label in ('warm', 'filtered', 'no_cache_invalid'):
            assert row['before'] == row['after']
        if row['status'] == 0 and not after and cache in row['before']['files'] and row['before'] == row['after']:
            preserved_noncanonical.append(label)
        cases[label] = dict(status=row['status'], before_fixed_output=before, after_fixed_output=after)
    assert set(before_refuse) == set(producer.LABELS) - {'warm', 'filtered'}
    assert set(after_refuse) == {'no_cache_absent', 'no_cache_invalid', 'schema_kind', 'unknown_field', 'mode',
                                 'source_bytes', 'extra_member', 'traversal', 'symlink'}
    assert preserved_noncanonical == ['no_cache_invalid', 'schema_kind', 'unknown_field', 'mode']
    cold = load('cold')['after']['files'][str(producer.CACHE)]
    assert full_body(cold) == full_body(start['protected'][str(producer.selected_postrun.checkout.FOLDER)])
    refusal = load('instrument-refusal')
    assert type(refusal['status']) is int and refusal['status'] == 1
    assert full_body(refusal['stdout']) == b'' and b'protected_cache' in full_body(refusal['stderr'])
    # Recovery consumes the original actual refusal and source. Repeating its
    # function against a live worktree would make this saved reader depend on
    # an ignored fixture and could change the historical refusal mechanism.
    original = ast.parse(full_body(refusal['programme']))
    function = next(node for node in original.body if isinstance(node, ast.FunctionDef) and node.name == 'protected_cache')
    assert any(isinstance(node, ast.Call) and isinstance(node.func, ast.Attribute)
               and isinstance(node.func.value, ast.Name) and node.func.value.id == 'execute'
               and node.func.attr == 'safe' for node in ast.walk(function))
    assert b'assert not (parent /' in full_body(refusal['stderr'])
    inputs = ['started', 'actual', 'instrument-refusal', *producer.LABELS]
    product = dict(inputs={suffix: prepare.identity(execute.read(Path(str(producer.PREFIX) + '-' + suffix + '.json.gz'))) for suffix in inputs},
                                programme=prepare.blob(execute.read(execute.AUDIT / 'verify_runtime_cache.py')),
                                cases=cases, before_refuse=before_refuse, after_refuse=after_refuse,
                                preserved_noncanonical=preserved_noncanonical,
                                scope='Actual unchanged public producer and complete fixed bundle/projection only. '
                                      'Independent full input/row/fingerprint/native/source/custody and exact derived-output evidence. '
                                      'Consumer preserves equivalent noncanonical schema kind/extra header/mode; no-cache bypass preserves invalid data. '
                                      'Fixed typed output evidence refuses these and changed sources. Full default execution roles/source-output contract '
                                      'remain separately owned; no semantic cohort, spent-cache mutation, new checkout or runtime permission.')
    if args.write:
        execute.save(PATH, product)
    else:
        saved = json.loads(gzip.decompress(execute.read(PATH)))
        assert typed.strict_equal(saved, product)
    print('Full unchanged public cache matrix and closed fixed derived-output evidence pass; permissive consumer shapes and default roles stay explicit.')
