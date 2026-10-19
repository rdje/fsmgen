"""Qualify canonical task recovery without executing original semantic cohorts."""
import argparse
import gzip
import json
from pathlib import Path
import re

import prepare

ROOT, AUDIT = prepare.ROOT, prepare.AUDIT
PATH = AUDIT / 'canonical-contracts-qualified.json.gz'


def equal(actual, expected):
    assert type(actual) is type(expected), 'exact primitive kind'
    if isinstance(expected, dict):
        assert actual.keys() == expected.keys(), 'complete object population'
        for key in expected:
            equal(actual[key], expected[key])
    elif isinstance(expected, list):
        assert len(actual) == len(expected), 'complete array population'
        for left, right in zip(actual, expected):
            equal(left, right)
    else:
        assert actual == expected, 'exact value'


def changed_field(body, key, value):
    expression = rb'^  ' + re.escape(key.encode()) + rb': `(.*)`$'
    result, count = re.subn(expression, lambda _: ('  ' + key + ': `' + value + '`').encode(), body, flags=re.M)
    assert count == 1 and result != body
    return result


def derive(current):
    plan, _, original, _ = prepare.premises()
    graph = prepare.nodes(current)
    roots = [name for name, body in graph.items() if prepare.field(body, 'Terminal') == 'version_object'
             and any(member == name or member.startswith(name + '.') for member in original)]
    assert roots, 'actual original obligations have compact terminals'
    assert prepare.check_contracts(current, original, plan)
    snapshots = {}
    reconstructed = dict(graph)
    for root in roots:
        descriptor = graph[root]
        revision, path = (prepare.field(descriptor, key) for key in ('Revision', 'Retrieval path'))
        source = prepare._read_task_version(revision, path)
        # Independent whole-file node membership and literal field comparison;
        # the actual task-tree checker separately validates the canonical form.
        source_graph = prepare.nodes(source)
        selected = {name: body for name, body in source_graph.items()
                    if name == root or name.startswith(root + '.')}
        assert len(selected) == int(prepare.field(descriptor, 'Archived node count'))
        for name, body in selected.items():
            if name in original:
                for key in ('Goal', 'Acceptance'):
                    expression = rb'^  ' + key.encode() + rb': `(.*)`$'
                    assert re.findall(expression, body, re.M) == re.findall(expression, original[name].encode(), re.M)
        reconstructed.update(selected)
        snapshots[root] = dict(revision=revision, path=path, source=prepare.blob(source),
                               descriptor=prepare.blob(descriptor), members=sorted(selected))
    assert all(name in reconstructed for name in original)
    root = roots[0]
    descriptor = graph[root]
    reference = snapshots[root]
    source = prepare.unblob(reference['source'])
    archived = prepare.nodes(source)
    controls = []

    def reject(label, candidate, supplied=None, expected=None):
        provider = None if supplied is None else lambda revision, path: supplied
        try:
            prepare.check_contracts(candidate, original, plan, read_version=provider)
        except AssertionError as error:
            if expected is not None:
                assert expected in str(error), (label, str(error), expected)
            controls.append(dict(label=label, task=prepare.blob(candidate),
                archive=None if supplied is None else prepare.blob(supplied), refusal=str(error)))
        else:
            raise AssertionError('changed canonical obligation admitted: ' + label)

    for label, key, value in (
        ('wrong-revision', 'Revision', '0' * 40),
        ('wrong-source-path', 'Retrieval path', 'docs/tasks/other.md'),
        ('wrong-source-digest', 'Retrieved SHA256', '0' * 64),
        ('wrong-count', 'Archived node count', str(len(reference['members']) + 1)),
        ('boolean-shaped-count', 'Archived node count', 'True'),
        ('wrong-retention', 'Retention contract', 'other_history'),
        ('live-terminal', 'Status', 'in_progress'),
        ('pending-evidence', 'Verification', 'pending')):
        reject(label, current.replace(descriptor, changed_field(descriptor, key, value), 1))
    reject('duplicate-revision', current.replace(descriptor,
        descriptor + ('  Revision: `' + reference['revision'] + '`\n').encode(), 1))
    family = graph[plan['family']]
    reject('changed-inline-goal', current.replace(family, changed_field(family, 'Goal', 'narrowed original scope'), 1), expected='Goal')
    reject('omitted-inline-contract', current.replace(family, b'', 1), expected='missing original contract')

    def image(label, changed_source, changed_descriptor=descriptor, expected=None):
        changed_descriptor = changed_field(changed_descriptor, 'Retrieved SHA256', prepare.identity(changed_source)['sha256'])
        reject(label, current.replace(descriptor, changed_descriptor, 1), changed_source, expected)

    image('rehashed-changed-acceptance', source.replace(archived[root],
          changed_field(archived[root], 'Acceptance', 'narrowed archived scope'), 1), expected='Acceptance')
    image('rehashed-borrowed-goal', source.replace(archived[root],
          changed_field(archived[root], 'Goal', 'borrowed source Goal'), 1),
          changed_field(descriptor, 'Goal', 'borrowed source Goal'), expected='Goal')
    leaves = [name for name in reference['members'] if name in original and
              not any(other.startswith(name + '.') for other in reference['members'])]
    assert leaves
    leaf = leaves[0]
    image('rehashed-nonterminal-leaf', source.replace(archived[leaf],
          changed_field(archived[leaf], 'Status', 'pending'), 1), expected='terminal archived')
    image('rehashed-nested-terminal', source.replace(archived[leaf],
          archived[leaf] + b'  Terminal: `version_object`\n', 1), expected='flat archived')
    root_children = prepare.field(archived[root], 'Children')
    assert root_children
    image('rehashed-child-closure', source.replace(archived[root],
          changed_field(archived[root], 'Children', root_children + ', ' + root + '.999999'), 1), expected='direct-child closure')
    reject('live-archive-collision', current.replace(descriptor, descriptor + archived[leaf], 1), expected='archive/live contract collision')
    reject('physical-compact-acceptance', current.replace(descriptor,
        descriptor + b'  Acceptance: `borrowed physical acceptance`\n', 1), expected='belongs to its archive')
    # A coherent omission must reach the original membership predicate rather
    # than merely a stale hash or broken declared child index.
    omission = next(name for name in leaves if len([member for member in reference['members']
        if member.startswith(name.rsplit('.', 1)[0] + '.') and '.' not in member[len(name.rsplit('.', 1)[0]) + 1:]]) > 1)
    parent = omission.rsplit('.', 1)[0]
    children = prepare.field(archived[parent], 'Children').split(', ')
    narrowed = source.replace(archived[omission], b'', 1).replace(archived[parent],
        changed_field(archived[parent], 'Children', ', '.join(name for name in children if name != omission)), 1)
    image('coherent-original-member-omission', narrowed,
          changed_field(descriptor, 'Archived node count', str(len(reference['members']) - 1)),
          expected='missing original contract')
    # Already-captured inline task snapshots continue through the exact same
    # source/obligation contract; unrelated current roots are never requested.
    inventory = json.loads(gzip.decompress((ROOT / AUDIT / 'inventory.json.gz').read_bytes()))
    historical = prepare.unblob(inventory['current_task_snapshot'])
    calls = []

    def denied(revision, path):
        calls.append((revision, path))
        raise AssertionError('inline saved recovery must not need task-version lookup')

    assert prepare.check_contracts(historical, original, plan, read_version=denied)
    assert calls == []
    return dict(schema='fsmgen.canonical_original_contracts.v1', original=original,
        captured_compact_task=prepare.blob(current),
        captured_inline_task=prepare.blob(historical), compact_snapshots=snapshots,
        controls=controls, inline_native_reads=calls,
        programme=prepare.blob(Path(__file__).read_bytes()),
        library=prepare.blob((ROOT / AUDIT / 'prepare.py').read_bytes()),
        scope='Exact original Goal/Acceptance and membership conservation through admitted flat task-version objects. Native digest/path/revision/retention/closed-node/child/provenance fields qualify; rehashed source-image controls are inert injected bytes, never new native observations or original semantic/cohort execution. Historical inline recovery consults no version provider. Current progress and task status may evolve below the original acceptance frontier; no original scope, native/private, runtime or full-CI permission follows.')


def main():
    if not __debug__:
        raise SystemExit('Acceptance assertions must be enabled.')
    parser = argparse.ArgumentParser(description=__doc__)
    mode = parser.add_mutually_exclusive_group()
    mode.add_argument('--write', action='store_true')
    mode.add_argument('--current', action='store_true')
    args = parser.parse_args()
    saved = None
    if not args.write:
        with gzip.open(ROOT / PATH, 'rt', encoding='utf-8') as stream:
            saved = json.load(stream)
    current = (ROOT / prepare.TASK).read_bytes() if args.write else prepare.unblob(saved['captured_compact_task'])
    value = derive(current)
    if args.write:
        with (ROOT / PATH).open('xb') as raw:
            with gzip.GzipFile(filename='', mode='wb', fileobj=raw, mtime=0) as stream:
                encoder = json.JSONEncoder(sort_keys=True, separators=(',', ':'), allow_nan=False)
                for chunk in encoder.iterencode(value):
                    stream.write(chunk.encode())
                stream.write(b'\n')
    else:
        equal(saved, value)
    if args.current:
        plan, _, original, _ = prepare.premises()
        assert prepare.check_contracts((ROOT / prepare.TASK).read_bytes(), original, plan)
    print('Saved canonical Goal/Acceptance, complete membership and archive/inline controls qualify; original semantic admission remains unchanged.')
    if args.current:
        print('Current original obligations also conserve through canonical task storage.')


if __name__ == '__main__':
    main()
