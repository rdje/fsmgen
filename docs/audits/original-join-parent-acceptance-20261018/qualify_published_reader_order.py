"""Qualify the dated published-reader order contract without executing readers."""
import argparse
import ast
import contextlib
import copy
import gzip
import hashlib
import json
import shlex
import subprocess

import live_operand_route as route

ROOT, AUDIT = route.ROOT, route.AUDIT
SELF = AUDIT + 'qualify_published_reader_order.py'
OUTPUT = AUDIT + 'published-reader-order-qualified.json.gz'
BASE = 'd5ea1fc9ed7e3fc502bcf4aeaf4b0da89226281a'
PUBLISHED = '89890bacf79c3f70e5efb905ff793a5ddca4ab4a'
CALLER = AUDIT + 'qualify_caller_modules.py'
FUNCTIONS = ('commands_review', 'helper_review', 'rewritten_listing', 'changed_published_helper')
SCOPE = ('Dated original/published helper membership and relative order, including established '
         'optional qualifiers, with qualified additive extensions retained. Listing/query and a '
         'dated current-source authorizer probe execute; the latter retains the caller refusal. '
         'Candidate helpers and listed saved child readers never execute. Whole-review structural probes '
         'supply only the original admitted caller source bytes as metadata while its replacement '
         'awaits separate admission. Saved replay reruns the native helper/order predicates and '
         'checks current predicate compatibility; broader whole-review observations remain dated '
         'capture evidence. Full current source admission, complete helper and original '
         'model/recipe/cohort/runtime/custody/native/private/HIAL/full-CI remain separate.')


def equal(left, right):
    return route.frozen.equal(left, right)


def native(revision, path):
    entry = route.frozen.git('ls-tree', '--full-tree', '-l', '-z', revision, '--', path)
    assert entry.count(b'\0') == 1
    header, name = entry[:-1].split(b'\t')
    mode, kind, oid, size = header.decode().split()
    assert mode in ('100644', '100755') and kind == 'blob' and name.decode() == path
    raw = route.frozen.git('show', revision + ':' + path)
    assert size.isdecimal() and len(raw) == int(size)
    assert raw == route.frozen.git('cat-file', 'blob', oid)
    assert hashlib.sha1(b'blob ' + str(len(raw)).encode() + b'\0' + raw).hexdigest() == oid
    return dict(revision=revision, path=path, mode=mode, oid=oid,
                body=route.frozen.blob(raw), retention_contract='fsmgen_required_history')


def reference():
    return dict(original_helper=native(BASE, route.HELPER),
                published_helper=native(PUBLISHED, route.HELPER),
                original_caller=native(BASE, CALLER))


def functions(body):
    tree = ast.parse(body)
    result = {node.name: ast.get_source_segment(body.decode(), node)
              for node in tree.body if isinstance(node, ast.FunctionDef) and node.name in FUNCTIONS}
    assert set(result) == set(FUNCTIONS)
    return result


@contextlib.contextmanager
def original_caller_image(raw):
    read = route.card.read_file
    seen = []

    def supplied(path):
        if str(path) == CALLER:
            seen.append(str(path))
            return raw
        return read(path)

    try:
        route.card.read_file = supplied
        yield seen
    finally:
        route.card.read_file = read


def changed(value, label, published):
    candidate = copy.deepcopy(value)
    if label in ('reordered', 'omitted', 'moved'):
        route.rewritten_listing(candidate, route.changed_published_helper(
            route.unblob(candidate['helper']), published, label))
    elif label == 'wrong-epoch':
        candidate['authority']['published_helper']['revision'] = BASE
    elif label == 'changed-snapshot':
        candidate['authority']['published_helper']['body'] = route.frozen.blob(b'changed published helper\n')
    elif label == 'missing-snapshot-reader':
        candidate['authority']['published'].pop()
    elif label == 'reordered-snapshot':
        candidate['authority']['published'].reverse()
    else:
        raise AssertionError('closed published-order candidate')
    return candidate


LABELS = ('reordered', 'omitted', 'moved', 'wrong-epoch', 'changed-snapshot',
          'missing-snapshot-reader', 'reordered-snapshot')


def order_review(value, fixed):
    original = route.unblob(fixed['original_helper']['body'])
    published_body = route.unblob(fixed['published_helper']['body'])
    required = route.frozen.helper_commands(original)[:-1]
    published = route.frozen.helper_commands(published_body)[:-1]
    equal(value['authority']['helper'], fixed['original_helper'])
    equal(value['authority']['published_helper'], fixed['published_helper'])
    equal(value['authority']['required'], required)
    equal(value['authority']['published'], published)
    return route.helper_review(route.unblob(value['helper']), original, required, published)


def collect():
    fixed = reference()
    equal(route.card.read_file(route.HELPER), route.unblob(fixed['published_helper']['body']))
    authority = route.authority()
    with original_caller_image(route.unblob(fixed['original_caller']['body'])) as reads:
        value = route.current_value(authority)
        route.review(value, authority)
    equal(reads, [CALLER])
    published = authority['published']
    controls = []
    for label in LABELS:
        candidate = changed(value, label, published)
        try:
            route.review(candidate, authority)
        except AssertionError as error:
            refusal = str(error)
        else:
            raise AssertionError('changed established order admitted: ' + label)
        controls.append(dict(label=label, candidate=candidate, refusal=refusal))
    positive = copy.deepcopy(value)
    helper = route.unblob(positive['helper'])
    # A reviewed additive structural candidate retains every published reader.
    amended = helper.replace(b'; do\n', b' frozen_operand_route; do\n', 1)
    route.rewritten_listing(positive, amended)
    path = route.OPTIONAL[0][-1]
    positive['sources'][path] = authority['sources'][path]['body']
    route.review(positive, authority)
    command = ['python3', '-B', route.SELF, '--current']
    actual = subprocess.run(command, cwd=ROOT, stdin=subprocess.DEVNULL, capture_output=True)
    assert actual.returncode == 1 and actual.stdout == b'' and b'AssertionError' in actual.stderr
    return dict(schema='fsmgen.published_reader_order.v1', scope=SCOPE, reference=fixed,
                programmes={path: route.frozen.blob(route.card.read_file(path)) for path in (SELF, route.SELF)},
                source_image=dict(role='original admitted caller bytes supplied only as structural metadata',
                                  reference=fixed['original_caller'], reads=reads),
                baseline=value, controls=controls, additive=positive,
                current_source_gap=dict(command=command, status=actual.returncode,
                    stdout=route.frozen.blob(actual.stdout),
                    stderr=route.frozen.blob(actual.stderr.replace(str(ROOT).encode(), b'.'))))


def review(value):
    assert set(value) == {'schema', 'scope', 'reference', 'programmes', 'source_image',
                          'baseline', 'controls', 'additive', 'current_source_gap'}
    equal(value['schema'], 'fsmgen.published_reader_order.v1')
    equal(value['scope'], SCOPE)
    fixed = reference()
    equal(value['reference'], fixed)
    equal(value['source_image'], dict(role='original admitted caller bytes supplied only as structural metadata',
                                    reference=fixed['original_caller'], reads=[CALLER]))
    assert set(value['programmes']) == {SELF, route.SELF}
    equal(functions(route.unblob(value['programmes'][route.SELF])),
          functions(route.card.read_file(route.SELF)))
    commands = order_review(value['baseline'], fixed)
    equal(route.unblob(value['baseline']['helper']), route.unblob(fixed['published_helper']['body']))
    listing = value['baseline']['listing']
    equal(listing['command'], ['bash', route.HELPER, '--list'])
    equal(listing['status'], 0)
    equal(listing['stderr'], '')
    equal([shlex.split(line) for line in listing['stdout'].splitlines()], commands)
    equal([row['label'] for row in value['controls']], list(LABELS))
    published = route.frozen.helper_commands(route.unblob(fixed['published_helper']['body']))[:-1]
    for row in value['controls']:
        equal(row['candidate'], changed(value['baseline'], row['label'], published))
        try:
            order_review(row['candidate'], fixed)
        except AssertionError as error:
            if row['label'] in ('reordered', 'omitted', 'moved'):
                equal(str(error), 'complete published reader membership and order')
        else:
            raise AssertionError('changed retained order admitted: ' + row['label'])
        assert type(row['refusal']) is str
    order_review(value['additive'], fixed)
    assert value['additive']['helper'] != value['baseline']['helper']
    gap = value['current_source_gap']
    equal(gap['command'], ['python3', '-B', route.SELF, '--current'])
    equal(gap['status'], 1)
    equal(route.unblob(gap['stdout']), b'')
    assert b'AssertionError' in route.unblob(gap['stderr'])


def publication(raw, value):
    """Bind historical programme frames to their proof's native publication."""
    revision = route.frozen.git('log', '-1', '--format=%H', '--', OUTPUT).decode().strip()
    if revision:
        equal(route.unblob(native(revision, OUTPUT)['body']), raw)
        for path, blob in value['programmes'].items():
            equal(native(revision, path)['body'], blob)
    else:
        # The first owned candidate is not native evidence before its commit.
        for path, blob in value['programmes'].items():
            equal(route.frozen.blob(route.card.read_file(path)), blob)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--write', action='store_true')
    args = parser.parse_args()
    if args.write:
        value = collect()
        review(value)
        with (ROOT / OUTPUT).open('xb') as target:
            with gzip.GzipFile(filename='', mode='wb', fileobj=target, mtime=0) as stream:
                for chunk in json.JSONEncoder(sort_keys=True, separators=(',', ':')).iterencode(value):
                    stream.write(chunk.encode())
    else:
        raw = route.card.read_file(OUTPUT)
        value = json.loads(gzip.decompress(raw))
        publication(raw, value)
        review(value)
    print('Dated published-reader membership/order and production predicate compatibility qualify; current source and complete-helper acceptance remain separate.')


if __name__ == '__main__':
    if not __debug__:
        raise SystemExit('Acceptance assertions must be enabled.')
    main()
