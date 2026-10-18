"""Authenticate the failed first cohort and discriminate its exact source-epoch guard."""
import argparse
import ast
import copy
import difflib
import gzip
import hashlib
import io
import subprocess
import json
from pathlib import Path
import sys

import execute_snapshot as execute
import snapshot_intake
import prepare
import verify_snapshot as reader

AUDIT = execute.AUDIT
QUALIFICATION = '528dc123c69ab59b35f65a5bf1065d8a56a20395'
CONTAINER = Path('docs/audits/original-consumer-parent-acceptance-20261012')
FACTORY = 'scripts/check_record_value_publication.py'
CAUSE = 'every unchanged current canonical source byte'
GAP_SHA256 = 'be2f4ed22ce6d4e420f6bce7672d5ceae196a63cf19bfdc504598f40fbbd34f2'


def failed(row, started):
    assert all(row[key] == value for key, value in started.items())
    assert set(row) == set(started) | {'status', 'launch_error', 'source_after', 'git_after', 'tools_after',
                                      'samples', 'resource_complete', 'book_after', 'stdout', 'stderr', 'snapshot_after'}
    assert row['schema'] == 'fsmgen.original_acceptance_execution.v3'
    assert row['label'] == 'prerequisites' and row['qualification'] == QUALIFICATION
    assert row['scope'] == execute.SCOPE and type(row['status']) is int and row['status'] == 1
    assert row['launch_error'] is None and row['book_before'] is row['book_after'] is None
    rows = reader.sources(row['source_before'])
    assert reader.validate_sources(rows, QUALIFICATION)
    inventory = json.loads(gzip.decompress(reader.unblob(rows[str(AUDIT / 'inventory.json.gz')])))
    assert prepare.validate(inventory) and row['owner'] == inventory['acceptance'] + '.2.2.3.3.2'
    assert row['command'] == ['scripts/run_with_ram_guard.sh', '--', *inventory['cohorts']['prerequisites']['command']]
    assert row['source_after'] == {'value': row['source_before'], 'error': None}
    assert row['git_after']['error'] is None
    before, after = row['git_before'], row['git_after']['value']
    assert before['head'] == after['head'] == QUALIFICATION and before['entries'] == after['entries']
    for state in (before, after):
        reader.unblob(state['index'])
        assert execute.index_matches(rows, reader.unblob(state['entries']))
    assert reader.validate_tools(row['tools_before'])
    assert row['tools_after'] == {'value': row['tools_before'], 'error': None}
    assert reader.validate_resources(row['samples'], row['resource_complete'])
    assert reader.unblob(row['stdout']) == b''
    stderr = reader.unblob(row['stderr'])
    assert stderr.startswith(b'ram-guard: PID ') and b'ram-guard: terminating PID tree' not in stderr
    assert b'original-consumer-parent-acceptance-20261012/model.py' in stderr
    assert stderr.endswith(('ValueError: ' + CAUSE + '\n').encode())
    profile = json.loads(gzip.decompress(reader.unblob(rows[str(AUDIT / 'snapshot-intake.json.gz')])))
    assert snapshot_intake.validate(profile)
    assert row['working_directory'] == snapshot_intake.cwd('prerequisites', profile)
    assert snapshot_intake.validate_observation('prerequisites', row['snapshot_before'], profile)
    assert row['snapshot_after']['value'] is None
    gap = row['snapshot_after']['error']
    assert type(gap) is str and gap.endswith('AssertionError: unexpected directory boundary\n')
    assert hashlib.sha256(gap.encode()).hexdigest() == GAP_SHA256
    fresh = reader.load(AUDIT / 'snapshot-postrun-sources.json.gz')
    prepared = reader.load(AUDIT / 'historical-checkout-prepared.json.gz')
    assert fresh['schema'] == 'fsmgen.later_snapshot_source_verification.v1'
    assert fresh['revision'] == profile['snapshot_revision'] and fresh['members'] == prepared['members']
    assert fresh['runtime_directories'] == ['.artifacts', '.artifacts/build', '.artifacts/cache', '.artifacts/logs', '.artifacts/tmp']
    # The artifact root contains four empty leaf directories; no added runtime files exist.
    assert prepare.unblob(fresh['locality_programme']) == batch(profile['snapshot_revision'],
        ['scripts/project_data_locality_env.sh'])['scripts/project_data_locality_env.sh']
    return rows


def batch(revision, names):
    names = list(names)
    request = b''.join((revision + ':' + name + '\n').encode() for name in names)
    native = subprocess.run(['git', '--no-replace-objects', 'cat-file', '--batch'], input=request,
                            capture_output=True, cwd=execute.ROOT)
    assert native.returncode == 0 and not native.stderr
    stream, result = io.BytesIO(native.stdout), {}
    for name in names:
        header = stream.readline().split()
        assert len(header) == 3 and header[1] == b'blob'
        body = stream.read(int(header[2]))
        assert len(body) == int(header[2]) and stream.read(1) == b'\n'
        assert hashlib.sha1(b'blob ' + str(len(body)).encode() + b'\0' + body).hexdigest() == header[0].decode()
        assert name not in result
        result[name] = body
    assert not stream.read(1)
    return result


def diagnosis(rows):
    plan_name = str(CONTAINER / 'plan.json')
    plan_body = batch(QUALIFICATION, [plan_name])[plan_name]
    plan = json.loads(plan_body)
    expected_revision = plan['revision']
    listing = execute.command(['git', '--no-replace-objects', 'ls-tree', '-r', '--name-only', expected_revision,
                               '--', 'docs/knowledge', 'docs/decisions'])
    names = [name for name in listing.decode().splitlines() if name.endswith('.md')]
    expected = batch(expected_revision, names)
    profile = json.loads(gzip.decompress(reader.unblob(rows[str(AUDIT / 'snapshot-intake.json.gz')])))
    actual_revision = profile['snapshot_revision']
    captured = batch(actual_revision, names)
    source_name = str(CONTAINER / 'model.py')
    source = reader.unblob(rows[source_name])
    assert source == batch(actual_revision, [source_name])[source_name]
    common_name = str(CONTAINER / 'parent_common.py')
    common = reader.unblob(rows[common_name])
    declaration = next(node for node in ast.parse(common).body
                       if isinstance(node, ast.FunctionDef) and node.name == 'canonical_sources')
    assert "'docs/knowledge', 'docs/decisions'" in ast.get_source_segment(common.decode(), declaration)
    function = next(node for node in ast.parse(source).body
                    if isinstance(node, ast.FunctionDef) and node.name == 'inputs')
    guard = next(node for node in function.body if isinstance(node, ast.Expr)
                 and isinstance(node.value, ast.Call) and any(isinstance(arg, ast.Constant)
                 and arg.value == CAUSE for arg in node.value.args))
    predicate = ast.Module(body=[guard], type_ignores=[])

    def probe(files, wanted):
        class PathImage:
            def __init__(self, name):
                self.name = str(name)
            def read_bytes(self):
                return files[self.name]
        def need(condition, message):
            if not condition:
                raise ValueError(message)
        namespace = dict(Path=PathImage, canonical=expected, need=need)
        try:
            exec(compile(predicate, source_name, 'exec'), namespace)
        except (ValueError, KeyError) as error:
            assert wanted is not None and str(error) == wanted
            return dict(error_type=type(error).__name__, error=str(error))
        assert wanted is None
        return dict(error_type=None, error=None)

    changed = sorted(name for name in names if captured[name] != expected[name])
    assert changed
    outcomes = dict(captured=probe(captured, CAUSE), declared=probe(expected, None))
    missing = dict(expected)
    del missing[names[0]]
    outcomes['missing'] = probe(missing, repr(names[0]))
    altered = dict(expected, **{names[0]: expected[names[0]] + b'\n# changed canonical byte\n'})
    outcomes['altered'] = probe(altered, CAUSE)
    history = execute.command(['git', '--no-replace-objects', 'log', '-1', '-S', CAUSE,
                               '--format=%H %s', '--', source_name]).decode()
    assert history
    return dict(schema='fsmgen.failed_whole_checkout_canonical_epoch.v1', qualification=QUALIFICATION,
                actual_source_revision=actual_revision, canonical_revision=expected_revision,
                source=prepare.blob(source), common_source=prepare.blob(common), plan=prepare.blob(plan_body),
                whole_canonical_listing=prepare.blob(listing), expected={name: prepare.blob(body) for name, body in expected.items()},
                captured={name: prepare.blob(body) for name, body in captured.items()}, differing_members=changed,
                controls=outcomes, guard_history=history,
                scope='Exact unchanged consumer canonical-byte predicate and complete fixed canonical input domain only. '
                      'Actual canonical bytes derive from the whole physical checkout revision bound before/after in native custody. '
                      'No semantic reader or cohort executes. The chosen pre-publication checkout is not this reader canonical epoch. '
                      'Native1 stays failed; complete conjunction of all namespace/runtime/canonical constraints is still required.')


def controls(row, started):
    for label in ('promotion', 'source', 'gap', 'stderr', 'index', 'tool_kind', 'cwd', 'snapshot'):
        bad = copy.deepcopy(row)
        if label == 'promotion':
            bad['status'] = 0
        elif label == 'source':
            bad['source_after']['value'] = None
        elif label == 'gap':
            bad['samples'][0]['error'] = 'lost observation'
        elif label == 'stderr':
            bad['stderr'] = prepare.blob(b'ValueError: unrelated failure\n')
        elif label == 'index':
            bad['git_after']['value']['entries'] = prepare.blob(b'changed index entries')
        elif label == 'cwd':
            bad['working_directory'] = '.'
        elif label == 'snapshot':
            bad['snapshot_after'] = {'value': bad['snapshot_before'], 'error': None}
        else:
            key = next(iter(bad['tools_before']))
            bad['tools_before'][key]['bytes'] = float(bad['tools_before'][key]['bytes'])
        try:
            failed(bad, started)
        except (AssertionError, KeyError, ValueError):
            continue
        raise AssertionError('hostile failed-custody record admitted: ' + label)
    try:
        reader.validate('prerequisites', row, started)
    except AssertionError:
        return
    raise AssertionError('successful reader promoted the first failed cohort')


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--write', action='store_true')
    args = parser.parse_args()
    row = reader.load(AUDIT / 'snapshot-prerequisites-actual.json.gz')
    started = reader.load(AUDIT / 'snapshot-prerequisites-started.json.gz')
    source = failed(row, started)
    controls(row, started)
    result = diagnosis(source)
    path = AUDIT / 'snapshot-failed-prerequisites-diagnosis.json.gz'
    if args.write:
        execute.save(path, result)
    else:
        assert reader.load(path) == result
    print('Whole-checkout failed native/source/cwd/index/resource custody and complete canonical-epoch diagnosis pass; native1 remains failed and later execution is gated.')
