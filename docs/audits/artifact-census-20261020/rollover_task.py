"""Retain the completed T1983 qualification subtree before census publication."""
import argparse
import base64
import gzip
import importlib.util
import json
from pathlib import Path
import sys

sys.path.insert(0, 'docs/audits/task-terminal-rollover-20261011')
import common

BASE = Path('docs/audits/artifact-census-20261020')
INITIAL = BASE / 'task-rollover.json.gz'
OUTPUT = BASE / 'task-rollover-qualified.json.gz'
SELF = BASE / 'rollover_task.py'
REVISION = 'fc5962a88f1dae8b2e05f4eca3e7fa884dfd4b41'
SEALED = 'SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.4.3.3.5.2.1.5.2.2.3.1.2.1.3.1.2.3.2.3.3.3.2'
OWNER = 'SEMANTIC-INTROSPECTION-MCP-FRONTIER.87'
LIBRARY = 'docs/audits/task-terminal-rollover-20261011/'
SCOPE = ('Complete fixed native source and closed semantic T1983 subtree retention only. '
         'Whole source, selected nodes and live view overlap; no original bytes or facts '
         'are lost. Captured complete registry-owner admission is dated. Saved replay '
         'does not compare historical task/census snapshots with future progress. '
         'No semantic producer, historical module, original cohort or spent fixture runs.')


def packed(raw):
    return dict(**common.pin(raw), body_base64=base64.b64encode(raw).decode())


def unpacked(value):
    raw = base64.b64decode(value['body_base64'], validate=True)
    same(value, packed(raw))
    return raw


def same(left, right):
    assert common.canonical(left) == common.canonical(right), 'exact JSON primitive types and values'


def primitive_controls():
    rows = []
    for label, size in (('float-size', 1.0), ('boolean-size', True)):
        candidate = packed(b'X')
        candidate['bytes'] = size
        try:
            unpacked(candidate)
        except AssertionError as error:
            rows.append(dict(label=label, candidate=candidate, refusal=str(error)))
        else:
            raise AssertionError('aliased primitive admitted: ' + label)
    return rows


def registries():
    names = common.git('ls-files', '-z', '--', 'doctrine/').decode().split('\0')
    return {name: Path(name).read_bytes() for name in sorted(names)
            if name.endswith(('.json', '.jsonl'))}


def fixed_sources():
    names = common.git('ls-tree', '-r', '--name-only', REVISION).decode().splitlines()
    names = [name for name in names if name.startswith('doctrine/') and name.endswith(('.json', '.jsonl'))]
    names += [common.TASK, common.HISTORY, common.RETENTION, common.CHECKER,
              LIBRARY + 'common.py', LIBRARY + 'verify.py']
    common.REVISION = REVISION
    sources = common.frozen_sources(set(names))
    for name in (common.CHECKER, LIBRARY + 'common.py', LIBRARY + 'verify.py'):
        assert Path(name).read_bytes() == sources[name], 'unchanged native bookkeeping instrument'
    return sources


def terminal(original, count):
    goal = common.field(common.nodes(original)[SEALED], 'Goal')
    return (f'- ID: `{SEALED}`\n  Status: `done`\n  Goal: `{goal}`\n'
            '  Terminal: `version_object`\n'
            f'  Revision: `{REVISION}`\n  Retrieval path: `{common.TASK}`\n'
            f'  Retrieved SHA256: `{common.pin(original)["sha256"]}`\n'
            f'  Archived node count: `{count}`\n  Retention contract: `fsmgen_required_history`\n'
            '  Verification: `Complete fixed T1983 source, nodes, goals and owners retain; '
            'independent Perl reconstruction and genuine native checker controls are in '
            'docs/audits/artifact-census-20261020/task-rollover.json.gz. No fact or live obligation is lost.`\n'
            f'  Commit: `{OWNER}: retain due artifact census and evidence`\n\n').encode()


def structural(before, after, sources, admission):
    original = sources[common.TASK]
    graph = common.nodes(original)
    selected = common.eligible(graph, SEALED, common.owner_census(sources))
    assert all(common.field(raw, 'Status') == 'done' for raw in selected.values())
    assert not any(common.selected(row['owner'], SEALED) for row in common.owner_census(admission))
    prior, live = common.nodes(before), common.nodes(after)
    assert all(prior[name] == raw for name, raw in selected.items()), 'complete native selected node bytes'
    expected = before
    for name, raw in selected.items():
        expected = expected.replace(raw, terminal(original, len(selected)) if name == SEALED else b'', 1)
    assert after == expected, 'exact whole-file projection; unrelated prefix/footer unchanged'
    assert live[SEALED] == terminal(original, len(selected))
    reconstructed = {name: raw for name, raw in live.items() if name != SEALED}
    reconstructed.update(selected)
    assert reconstructed == prior, 'every complete current node reconstructs'
    assert after.count(b'\n') < before.count(b'\n')
    return selected


def oracle():
    spec = importlib.util.spec_from_file_location('census_rollover_native_oracle', LIBRARY + 'verify.py')
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    module.REVISION, module.ROOTS, module.BASE = REVISION, (SEALED,), BASE / 'rollover-controls'
    module.SCRATCH = Path('.artifacts/artifact-census-20261020-rollover')
    return module


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--write', action='store_true')
    args = parser.parse_args()
    sources = fixed_sources()
    native = oracle()
    if args.write:
        assert not OUTPUT.exists() and not OUTPUT.is_symlink()
        initial = json.loads(gzip.decompress(INITIAL.read_bytes()))
        same(initial['schema'], 'fsmgen.census_task_rollover.v1')
        same(initial['scope'], SCOPE)
        assert {name: unpacked(row) for name, row in initial['sources'].items()} == sources
        admission = {name: unpacked(row) for name, row in initial['admission'].items()}
        before, after = unpacked(initial['before']), unpacked(initial['after'])
        structural(before, after, sources, admission)
        independent = native.independent(sources, dict(original=sources[common.TASK], before=before, after=after))
        controls = native.controls(after, sources, retain=True)
        same(independent, initial['independent'])
        same(controls, initial['controls'])
        value = dict(schema='fsmgen.census_task_rollover.v1', scope=SCOPE,
                     programme=packed(SELF.read_bytes()), sources={name: packed(raw) for name, raw in sources.items()},
                     admission={name: packed(raw) for name, raw in admission.items()}, before=packed(before),
                     after=packed(after), independent=independent, controls=controls,
                     initial_identity=common.pin(INITIAL.read_bytes()), primitive_controls=primitive_controls())
        common.save(OUTPUT, gzip.compress(common.canonical(value), mtime=0))
    else:
        value = json.loads(gzip.decompress(OUTPUT.read_bytes()))
        assert set(value) == {'schema', 'scope', 'programme', 'sources', 'admission', 'before',
                              'after', 'independent', 'controls', 'initial_identity', 'primitive_controls'}
        assert value['schema'] == 'fsmgen.census_task_rollover.v1' and value['scope'] == SCOPE
        assert unpacked(value['programme']) == SELF.read_bytes()
        assert {name: unpacked(row) for name, row in value['sources'].items()} == sources
        before, after = unpacked(value['before']), unpacked(value['after'])
        structural(before, after, sources, {name: unpacked(row) for name, row in value['admission'].items()})
        same(common.pin(INITIAL.read_bytes()), value['initial_identity'])
        same(primitive_controls(), value['primitive_controls'])
        same(native.independent(sources, dict(original=sources[common.TASK], before=before, after=after)), value['independent'])
        same(native.controls(after, sources), value['controls'])
    print('Exact completed T1983 source/node/owner retention, independent reconstruction and native controls verify.')


if __name__ == '__main__':
    if not __debug__:
        raise SystemExit('Rollover assertions must be enabled.')
    main()
