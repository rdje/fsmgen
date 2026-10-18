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

import execute_corrected as execute
import corrected_intake
import prepare
import verify_corrected as reader

AUDIT = execute.AUDIT
QUALIFICATION = '766d0fef0214fbd82b8bd1fb7499e42cc5bfa71d'
CONTAINER = Path('docs/audits/primary-raw-cause-container-acceptance-20261012')
FACTORY = 'scripts/check_record_value_publication.py'
CAUSE = 'only owned metadata selector/qualification/publication evidence and activation input advance'


def failed(row, started):
    assert all(row[key] == value for key, value in started.items())
    assert set(row) == set(started) | {'status', 'launch_error', 'source_after', 'git_after', 'tools_after',
                                      'samples', 'resource_complete', 'book_after', 'stdout', 'stderr', 'historical_source'}
    assert row['schema'] == 'fsmgen.original_acceptance_execution.v2'
    assert row['label'] == 'prerequisites' and row['qualification'] == QUALIFICATION
    assert row['scope'] == execute.SCOPE and type(row['status']) is int and row['status'] == 1
    assert row['launch_error'] is None and row['book_before'] is row['book_after'] is None
    rows = reader.sources(row['source_before'])
    assert reader.validate_sources(rows, QUALIFICATION)
    inventory = json.loads(gzip.decompress(reader.unblob(rows[str(AUDIT / 'corrected-intake.json.gz')])))
    assert corrected_intake.validate(inventory) and row['owner'] == inventory['acceptance'] + '.2.2.3'
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
    assert row['historical_source']['error'] is None
    receipt = json.loads(gzip.decompress(reader.unblob(row['historical_source']['value'])))
    assert receipt['error'].endswith(('ValueError: ' + CAUSE + '\n'))
    proof = receipt['proof']
    image = inventory['historical_source_image']
    old_identity = prepare.identity(prepare.unblob(image['historical_imports']['modules'][FACTORY]))
    live_identity = {key: image['current_factory'][key] for key in ('bytes', 'sha256')}
    assert receipt == dict(schema='fsmgen.original_historical_source_view.v1', role='prerequisites',
                           command=inventory['cohorts']['prerequisites']['original_command'],
                           proof=proof, error=receipt['error'], restored=True,
                           live_factory_before=live_identity, live_factory_after=live_identity)
    assert receipt['restored'] is True
    assert proof == dict(role='prerequisites', reads=proof['reads'], historical_factory=old_identity,
                         live_factory=live_identity,
                         scope='Historical source view only; no live factory currency or semantic qualification is implied.')
    assert type(proof['reads']) is list and proof['reads']
    assert all(value == dict(path=FACTORY, role='prerequisites', source=old_identity) for value in proof['reads'])
    return rows


def diagnosis(rows):
    source_name = str(CONTAINER / 'verify.py')
    source = reader.unblob(rows[source_name])
    function = next(node for node in ast.parse(source).body
                    if isinstance(node, ast.FunctionDef) and node.name == 'repaired_preflight')
    position = next(i for i, node in enumerate(function.body)
                    if isinstance(node, ast.Assign) and any(isinstance(t, ast.Name) and t.id == 'changed' for t in node.targets))
    predicate = ast.Module(body=function.body[position:position + 2], type_ignores=[])
    first_name = str(CONTAINER / 'development-preflight-actual.json')
    first_body = execute.command(['git', '--no-replace-objects', 'show', QUALIFICATION + ':' + first_name])
    first = json.loads(first_body)
    programme_names = set(first['programmes'])
    expected = {str(CONTAINER / name) for name in ('verify.py', 'container_publish.py', 'plan.json')}
    test_name = 't/python/test_record_value_current_publication.py'
    inventory = json.loads(gzip.decompress(reader.unblob(rows[str(AUDIT / 'corrected-intake.json.gz')])))
    historical_revision = inventory['historical_source_image']['historical_roles']['prerequisites']['revision']
    historical = {name: execute.command(['git', '--no-replace-objects', 'show', historical_revision + ':' + name])
                  for name in programme_names}
    qualified = {name: execute.command(['git', '--no-replace-objects', 'show', QUALIFICATION + ':' + name])
                 for name in programme_names}
    assert all(reader.unblob(rows[name]) == body for name, body in qualified.items() if name in rows)
    captured_view = dict(qualified)
    captured_view[FACTORY] = prepare.unblob(inventory['historical_source_image']['historical_imports']['modules'][FACTORY])
    old = {name: value['body'].encode() if 'body' in value else bytes.fromhex(value['body_hex'])
           for name, value in first['programmes'].items()}
    assert {name for name in programme_names if historical[name] != old[name]} == expected
    assert {name for name in programme_names if captured_view[name] != old[name]} == expected | {test_name}

    def probe(files, wanted):
        class PathImage:
            def __init__(self, name):
                self.name = str(name)
            def __str__(self):
                return self.name
            def __truediv__(self, part):
                return PathImage(self.name + '/' + part)
            def read_bytes(self):
                return files[self.name]
        def need(condition, message):
            if not condition:
                raise ValueError(message)
        namespace = dict(Path=PathImage, BASE=PathImage(CONTAINER), first=first, need=need)
        try:
            exec(compile(predicate, source_name, 'exec'), namespace)
        except (ValueError, KeyError) as error:
            assert wanted is not None and str(error) == wanted
            return dict(error_type=type(error).__name__, error=str(error))
        assert wanted is None
        return dict(error_type=None, error=None, changed=sorted(namespace['changed']))

    outcomes = dict(captured=probe(captured_view, CAUSE), dated=probe(historical, None))
    one_repair = dict(captured_view, **{test_name: historical[test_name]})
    outcomes['only_test_epoch_changed'] = probe(one_repair, None)
    missing = dict(historical)
    del missing[test_name]
    outcomes['missing_input'] = probe(missing, repr(test_name))
    extra = dict(historical, **{test_name: historical[test_name] + b'\n# altered retained input\n'})
    outcomes['changed_retained'] = probe(extra, CAUSE)
    removed_repair = dict(historical, **{str(CONTAINER / 'verify.py'): old[str(CONTAINER / 'verify.py')]})
    outcomes['missing_declared_repair'] = probe(removed_repair, CAUSE)
    history = execute.command(['git', '--no-replace-objects', 'log', '-1', '-S',
                               'original_join', '--format=%H %s', '--', test_name]).decode()
    assert history.startswith('a0561d999b0354ed261289f66657bf8704c75ec9 ')
    return dict(schema='fsmgen.corrected_failed_runtime_epoch.v1', qualification=QUALIFICATION,
                historical_revision=historical_revision, source=prepare.blob(source),
                first_development=prepare.blob(first_body), expected_changed=sorted(expected),
                captured_changed=sorted(expected | {test_name}),
                historical_inputs={name: prepare.blob(body) for name, body in historical.items()},
                qualified_inputs={name: prepare.blob(body) for name, body in qualified.items()},
                captured_source_members=sorted(programme_names & rows.keys()),
                factory_view=prepare.identity(captured_view[FACTORY]),
                controls=outcomes, publication_history=history,
                test_diff=''.join(difflib.unified_diff(historical[test_name].decode().splitlines(True),
                    qualified[test_name].decode().splitlines(True), fromfile='historical/' + test_name,
                    tofile='qualified/' + test_name)),
                scope='Exact dated repair changed-set predicate only, executed inertly with complete programme inputs. '
                      'Selected input bytes are also present in the native source snapshot; remaining qualified inputs '
                      'are explicitly reconstructed from fixed Git. No semantic reader or cohort executes. '
                      'The factory-only view was incomplete for this runtime input comparison; native1 stays failed. '
                      'Complete runtime source-role repair and every original qualification remain pending.')


def controls(row, started):
    for label in ('promotion', 'source', 'gap', 'stderr', 'index', 'tool_kind', 'restoration', 'borrowed_read'):
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
        elif label == 'tool_kind':
            key = next(iter(bad['tools_before']))
            bad['tools_before'][key]['bytes'] = float(bad['tools_before'][key]['bytes'])
        else:
            receipt = json.loads(gzip.decompress(reader.unblob(bad['historical_source']['value'])))
            if label == 'restoration':
                receipt['restored'] = False
            else:
                receipt['proof']['reads'][0]['role'] = 'current'
            bad['historical_source']['value'] = prepare.blob(gzip.compress(prepare.encoded(receipt), mtime=0))
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
    row = reader.load(AUDIT / 'corrected-prerequisites-actual.json.gz')
    started = reader.load(AUDIT / 'corrected-prerequisites-started.json.gz')
    source = failed(row, started)
    controls(row, started)
    result = diagnosis(source)
    path = AUDIT / 'corrected-failed-prerequisites-diagnosis.json.gz'
    if args.write:
        execute.save(path, result)
    else:
        assert reader.load(path) == result
    print('Corrected failed prerequisite custody and exact dated runtime-input diagnosis pass; native1 remains failed and later execution is gated.')
