"""Authenticate native0 with failed after custody; never promote it to acceptance."""
import argparse
import copy
import gzip
import hashlib
import json
from pathlib import Path
import re

import execute_selected as execute
import prepare
import selected_intake
import selected_postrun
import verify_selected as reader

QUALIFICATION = '6123e88d18f3fd22cadae5e754de80c8193248ed'
GAP_SHA256 = '7b4c76abd633011a88011398b0b0383fc5f3f5018baa90788980f86f16dceb86'
OWNER = prepare.premises()[0]['acceptance'] + '.2.2.3.3.2.3.3.1'
SUBJECT = OWNER + ': retain native0 prerequisite after-cache gap'


def member_types(members):
    for row in members.values():
        assert set(row) == {'bytes', 'mode', 'oid', 'sha256'}
        assert type(row['bytes']) is int and row['bytes'] >= 0
        assert row['mode'] in ('100644', '100755', '120000')
        assert type(row['oid']) is str and re.fullmatch('[0-9a-f]{40}', row['oid'])
        assert type(row['sha256']) is str and re.fullmatch('[0-9a-f]{64}', row['sha256'])


def later(value, before, instruments):
    assert value['schema'] == 'fsmgen.selected_later_source_cache_observation.v1'
    assert value['revision'] == selected_intake.checkout.constraints.REVISION
    member_types(value['members'])
    assert value['members'] == before['members']
    assert set(value['source_instruments']) == set(instruments)
    assert all(reader.unblob(value['source_instruments'][name]) == body for name, body in instruments.items())
    source = dict(git=value['git'], members=value['members'],
                  runtime_directories=before['runtime_directories'], runtime_files=[])
    assert selected_intake.checkout.matches_prepared(source, before)
    assert value['runtime_directories'] == before['runtime_directories'] + selected_postrun.EXTRA_DIRECTORIES
    cache_name = selected_postrun.CACHE
    assert set(value['runtime_files']) == {cache_name}
    cache = value['runtime_files'][cache_name]
    assert type(cache['mode']) is int and 0 <= cache['mode'] <= 0o777
    assert value['cache_after'] == cache
    data = reader.unblob(cache)
    records = [json.loads(line) for line in data.splitlines()]
    assert set(records[0]) == {'record_type', 'schema_version', 'fingerprint'}
    assert records[0]['record_type'] == 'cache' and type(records[0]['schema_version']) is int
    assert records[0]['schema_version'] == 1
    shards = sorted(name for name in before['members']
                    if Path(name).parent == Path('knowledge-map/generated') and name.endswith('.md'))
    material = b''
    for name in shards:
        body = execute.command(['git', '--no-replace-objects', 'show', value['revision'] + ':' + name])
        material += name.encode() + b'\0' + body + b'\0'
    assert records[0]['fingerprint'] == hashlib.sha256(material).hexdigest()
    direct = b''
    for row in records[1:]:
        assert set(row) == {'record_type', 'question', 'ids', 'sources'} and row['record_type'] == 'question'
        assert type(row['question']) is str and row['question']
        assert all(type(row[key]) is list and row[key] and all(type(item) is str for item in row[key])
                   for key in ('ids', 'sources'))
        direct += ('\t'.join((row['question'], ','.join(row['ids']), ','.join(row['sources']))) + '\n').encode()
    native = value['direct_query']
    assert native['command'] == ['scripts/run_with_ram_guard.sh', '--', 'knowledge-map/scripts/query_knowledge_map.sh', '--all', '--no-cache']
    assert type(native['status']) is int and native['status'] == 0
    assert reader.unblob(native['stdout']) == direct
    stderr = reader.unblob(native['stderr'])
    assert stderr.startswith(b'ram-guard: PID ') and b'ram-guard: terminating PID tree' not in stderr
    directories = {str(parent) for name in before['members'] for parent in Path(name).parents if str(parent) != '.'}
    assert value['membership'] == value['membership_after'] == dict(
        files=sorted(set(before['members']) | {'.git', cache_name}),
        directories=sorted(directories | set(value['runtime_directories'])))
    assert set(value['programmes']) == set(selected_postrun.SOURCES)
    for name, row in value['programmes'].items():
        assert reader.unblob(row) == execute.command(['git', '--no-replace-objects', 'show', value['revision'] + ':' + name])
    assert set(value['optional_programmes']) == set(selected_postrun.OPTIONAL)
    for name, row in value['optional_programmes'].items():
        if name in before['members']:
            assert reader.unblob(row) == execute.command(['git', '--no-replace-objects', 'show', value['revision'] + ':' + name])
        else:
            assert row is None
    return True


def failed(row, started, observation, instruments):
    assert set(started) == {'schema', 'owner', 'label', 'qualification', 'scope', 'command', 'source_before',
                            'git_before', 'tools_before', 'recorder_pid', 'book_before', 'working_directory', 'snapshot_before'}
    assert set(row) == set(started) | {'status', 'launch_error', 'source_after', 'git_after', 'tools_after',
                                      'samples', 'resource_complete', 'book_after', 'stdout', 'stderr', 'snapshot_after'}
    assert all(row[key] == value for key, value in started.items())
    assert type(row['recorder_pid']) is int and row['recorder_pid'] > 0
    assert row['schema'] == 'fsmgen.original_acceptance_execution.v4'
    assert row['label'] == 'prerequisites' and row['qualification'] == QUALIFICATION
    assert row['scope'] == execute.SCOPE and type(row['status']) is int and row['status'] == 0
    assert row['launch_error'] is None and row['book_before'] is row['book_after'] is None
    assert set(row['snapshot_after']) == {'value', 'error'} and row['snapshot_after']['value'] is None
    gap = row['snapshot_after']['error']
    assert type(gap) is str and gap.endswith('AssertionError: unexpected directory\n')
    assert hashlib.sha256(gap.encode()).hexdigest() == GAP_SHA256
    rows = reader.sources(row['source_before'])
    assert reader.validate_sources(rows, QUALIFICATION)
    inventory = json.loads(gzip.decompress(reader.unblob(rows[str(execute.AUDIT / 'inventory.json.gz')])))
    assert prepare.validate(inventory)
    assert row['owner'] == inventory['acceptance'] + '.2.2.3.3.2.3.3'
    assert row['command'] == ['scripts/run_with_ram_guard.sh', '--', *inventory['cohorts']['prerequisites']['command']]
    assert row['source_after'] == dict(value=row['source_before'], error=None)
    assert row['git_after']['error'] is None
    assert row['tools_after'] == dict(value=row['tools_before'], error=None)
    assert reader.validate_tools(row['tools_before'])
    before, after = row['git_before'], row['git_after']['value']
    assert before['head'] == after['head'] == QUALIFICATION and before['entries'] == after['entries']
    for state in (before, after):
        assert set(state) == {'head', 'entries', 'index'}
        reader.unblob(state['index'])
        assert execute.index_matches(rows, reader.unblob(state['entries']))
    assert reader.validate_resources(row['samples'], row['resource_complete'])
    assert reader.validate_streams('prerequisites', reader.unblob(row['stdout']), reader.unblob(row['stderr']), rows, inventory)
    profile = json.loads(gzip.decompress(reader.unblob(rows[str(execute.AUDIT / 'selected-intake.json.gz')])))
    assert selected_intake.validate(profile, captured=True)
    assert row['working_directory'] == selected_intake.cwd('prerequisites', profile, captured=True)
    member_types(row['snapshot_before']['members'])
    reader.unblob(row['snapshot_before']['git']['index'])
    reader.unblob(row['snapshot_before']['git']['entries'])
    assert selected_intake.validate_observation('prerequisites', row['snapshot_before'], profile, captured=True)
    assert later(observation, row['snapshot_before'], instruments)
    return True


def controls(row, started, observation, instruments):
    outcomes = []
    for label in ('false_after', 'native_status', 'source', 'index', 'tool_kind', 'resource_gap', 'cwd'):
        bad = copy.deepcopy(row)
        if label == 'false_after': bad['snapshot_after'] = dict(value=bad['snapshot_before'], error=None)
        elif label == 'native_status': bad['status'] = False
        elif label == 'source': bad['source_after']['value'] = None
        elif label == 'index': bad['git_after']['value']['entries'] = prepare.blob(b'changed entries')
        elif label == 'tool_kind': bad['tools_before']['git']['bytes'] = float(bad['tools_before']['git']['bytes'])
        elif label == 'resource_gap': bad['samples'][0]['error'] = 'lost observation'
        else: bad['working_directory'] = '.'
        try:
            failed(bad, started, observation, instruments)
        except (AssertionError, KeyError, ValueError):
            outcomes.append(label)
        else:
            raise AssertionError('invalid failed-custody candidate admitted: ' + label)
    missing_pid = dict(started)
    missing_pid.pop('recorder_pid')
    missing_row = dict(row)
    missing_row.pop('recorder_pid')
    try:
        failed(missing_row, missing_pid, observation, instruments)
    except AssertionError:
        outcomes.append('missing_pid_both_records')
    else:
        raise AssertionError('lost recorder identity was admitted')
    for label in ('missing_source', 'missing_cache', 'query_status_kind', 'cache_bytes', 'member_kind', 'producer'):
        bad = copy.deepcopy(observation)
        if label == 'missing_source': del bad['members'][next(iter(bad['members']))]
        elif label == 'missing_cache': bad['runtime_files'] = {}
        elif label == 'query_status_kind': bad['direct_query']['status'] = False
        elif label == 'cache_bytes': bad['runtime_files'][selected_postrun.CACHE]['bytes'] = False
        elif label == 'member_kind':
            name = next(name for name, member in bad['members'].items() if member['bytes'] == 0)
            bad['members'][name]['bytes'] = False
        else:
            name = next(iter(bad['source_instruments']))
            bad['source_instruments'][name] = prepare.blob(b'changed producing instrument')
        try:
            later(bad, row['snapshot_before'], instruments)
        except (AssertionError, KeyError, ValueError):
            outcomes.append(label)
        else:
            raise AssertionError('invalid later source/cache candidate admitted: ' + label)
    try:
        reader.validate('prerequisites', row, started)
    except AssertionError:
        outcomes.append('successful_reader_refuses')
    else:
        raise AssertionError('native0 was promoted despite its exact after gap')
    return outcomes


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--prospective', action='store_true', help='explicit pre-commit validation only')
    parser.add_argument('--write-controls', action='store_true')
    args = parser.parse_args()
    if args.prospective:
        read = execute.read
    else:
        revision = execute.command(['git', '--no-replace-objects', 'log', '-1', '--format=%H', '--fixed-strings', '--grep=' + SUBJECT]).decode().strip()
        assert len(revision) == 40
        assert execute.command(['git', '--no-replace-objects', 'show', '-s', '--format=%s', revision]).decode().strip() == SUBJECT
        def read(path):
            return execute.command(['git', '--no-replace-objects', 'show', revision + ':' + str(path)])
    row = json.loads(gzip.decompress(read(execute.AUDIT / 'selected-prerequisites-actual.json.gz')))
    started = json.loads(gzip.decompress(read(execute.AUDIT / 'selected-prerequisites-started.json.gz')))
    observation = json.loads(gzip.decompress(read(selected_postrun.PATH)))
    instruments = {name: read(execute.AUDIT / name)
                   for name in ('selected_postrun.py', 'selected_checkout.py', 'execute.py', 'prepare.py')}
    assert failed(row, started, observation, instruments)
    outcomes = controls(row, started, observation, instruments)
    if args.write_controls:
        assert args.prospective
        execute.save(execute.AUDIT / 'selected-failed-custody-controls-final.json.gz',
                     dict(owner=OWNER, inputs={str(path): prepare.identity(read(path)) for path in (
                         execute.AUDIT / 'selected-prerequisites-actual.json.gz',
                         execute.AUDIT / 'selected-prerequisites-started.json.gz', selected_postrun.PATH)},
                          programme=prepare.blob(Path(__file__).read_bytes()), outcomes=outcomes,
                          scope='Failed custody authenticates native0, not acceptance; later full source/cache truth never replaces the immediate-after gap.'))
    print('Retained native0 prerequisites and exact after-cache custody gap qualify as failed acceptance; complete later source/cache/query and genuine refusal controls pass.')
