"""Authenticate the failed first cohort and discriminate its exact source-epoch guard."""
import argparse
import ast
import copy
import difflib
import gzip
import hashlib
import json
from pathlib import Path
import sys

import execute
import prepare
import verify_execution as reader

AUDIT = execute.AUDIT
QUALIFICATION = 'c40d67863302eebcfd1e1ff23fdd78abbc75d02b'
CONTAINER = Path('docs/audits/primary-raw-cause-container-acceptance-20261012')
FACTORY = 'scripts/check_record_value_publication.py'
CAUSE = 'whole unchanged current canonical factory'


def failed(row, started):
    assert all(row[key] == value for key, value in started.items())
    assert set(row) == set(started) | {'status', 'launch_error', 'source_after', 'git_after', 'tools_after',
                                      'samples', 'resource_complete', 'book_after', 'stdout', 'stderr'}
    assert row['schema'] == 'fsmgen.original_acceptance_execution.v1'
    assert row['label'] == 'prerequisites' and row['qualification'] == QUALIFICATION
    assert row['scope'] == execute.SCOPE and type(row['status']) is int and row['status'] == 1
    assert row['launch_error'] is None and row['book_before'] is row['book_after'] is None
    rows = reader.sources(row['source_before'])
    assert reader.validate_sources(rows, QUALIFICATION)
    inventory = json.loads(gzip.decompress(reader.unblob(rows[str(AUDIT / 'inventory.json.gz')])))
    assert prepare.validate(inventory) and row['owner'] == inventory['acceptance'] + '.2.2'
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
    assert b'primary-raw-cause-container-acceptance-20261012/container_common.py' in stderr
    assert stderr.endswith(('ValueError: ' + CAUSE + '\n').encode())
    return rows


def diagnosis(rows):
    plan = json.loads(execute.read(CONTAINER / 'plan.json'))
    integration_name = str(CONTAINER / 'integration-contract.json')
    integration = execute.command(['git', '--no-replace-objects', 'show', QUALIFICATION + ':' + integration_name])
    retained = json.loads(integration)['retained_dependencies']
    assert len(retained) == 12
    names = [*retained, FACTORY]
    old = {name: execute.command(['git', '--no-replace-objects', 'show', plan['revision'] + ':' + name]) for name in names}
    current = {name: reader.unblob(rows[name]) for name in names}
    assert all(prepare.identity(old[name]) == retained[name] and current[name] == old[name] for name in retained)
    assert old[FACTORY] != current[FACTORY]
    source_name = str(CONTAINER / 'container_common.py')
    source = reader.unblob(rows[source_name])
    tree = ast.parse(source, filename=source_name)
    public = next(node for node in tree.body if isinstance(node, ast.FunctionDef) and node.name == 'public')
    function = ast.Module(body=[public], type_ignores=[])
    archive = {integration_name: integration}

    def probe(actual, expected_error):
        files = dict(archive, **actual)
        compiled = []

        class PathImage:
            def __init__(self, name):
                self.name = str(name)

            def __truediv__(self, part):
                return PathImage(self.name + '/' + part)

            def read_bytes(self):
                return files[self.name]

        def need(condition, message):
            if not condition:
                raise ValueError(message)

        namespace = dict(Path=PathImage, BASE=PathImage(CONTAINER), json=json, sys=sys,
                         fixed=lambda requested: {name: old[name] for name in requested},
                         pin=prepare.identity, need=need, exec=lambda code, result: compiled.append(code))
        exec(compile(function, source_name, 'exec'), namespace)
        previous = sys.path[:]
        try:
            namespace['public']()
        except (ValueError, KeyError) as error:
            assert expected_error is not None and str(error) == expected_error
            assert not compiled
            outcome = dict(error_type=type(error).__name__, error=str(error), delegate_count=0)
        else:
            assert expected_error is None and len(compiled) == 1
            outcome = dict(error_type=None, error=None, delegate_count=1)
        assert sys.path == previous
        return outcome

    outcomes = {'captured_current': probe(current, CAUSE), 'qualified_historical': probe(old, None)}
    helper = next(iter(retained))
    changed = dict(old, **{helper: old[helper] + b'\n# wrong source\n'})
    outcomes['changed_helper'] = probe(changed, 'all twelve unchanged maintained source interfaces')
    missing = dict(old)
    del missing[helper]
    outcomes['missing_helper'] = probe(missing, repr(helper))
    history = execute.command(['git', '--no-replace-objects', 'log', '-1', '-S',
                               'import record_value_original_join_fact', '--format=%H %s', '--', FACTORY]).decode()
    assert history.startswith('a0561d999b0354ed261289f66657bf8704c75ec9 ')
    return dict(schema='fsmgen.failed_original_acceptance_epoch.v1', qualification=QUALIFICATION,
                expected_revision=plan['revision'], factory=FACTORY, guard_source=prepare.blob(source),
                old_factory=prepare.blob(old[FACTORY]), captured_factory=prepare.blob(current[FACTORY]),
                integration=prepare.blob(integration), retained_helpers={name: prepare.identity(body) for name, body in old.items() if name in retained},
                diff=''.join(difflib.unified_diff(old[FACTORY].decode().splitlines(True), current[FACTORY].decode().splitlines(True),
                                               fromfile='qualified/' + FACTORY, tofile='captured/' + FACTORY)),
                publication_history=history, guard_controls=outcomes,
                scope='Exact unchanged source guard only: historical factory reaches an intercepted compile/exec delegation; '
                      'captured current factory refuses exactly as the native failure. No semantic reader, original producer '
                      'or acceptance cohort executes. This diagnoses the epoch mismatch, not a repair or parent qualification.')


def controls(row, started):
    for label in ('promotion', 'source', 'gap', 'stderr', 'index', 'tool_kind'):
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
    row = reader.load(AUDIT / 'prerequisites-actual.json.gz')
    started = reader.load(AUDIT / 'prerequisites-started.json.gz')
    source = failed(row, started)
    controls(row, started)
    result = diagnosis(source)
    path = AUDIT / 'failed-prerequisites-diagnosis.json.gz'
    if args.write:
        execute.save(path, result)
    else:
        assert reader.load(path) == result
    print('Failed prerequisite custody and exact-source epoch diagnosis pass; the cohort remains failed and later execution is gated.')
