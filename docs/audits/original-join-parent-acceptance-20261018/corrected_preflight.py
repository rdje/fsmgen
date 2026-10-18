"""Inert execution-intake controls, including real retained stream/book oracles."""
import copy
import gzip
import json
from pathlib import Path
import time
from unittest.mock import patch

import execute_corrected as execute
import corrected_intake
import prepare
import verify_corrected as reader

ROOT, AUDIT = execute.ROOT, execute.AUDIT


def refused(function, exceptions=(AssertionError, KeyError, ValueError)):
    try:
        function()
    except exceptions:
        return
    raise AssertionError('hostile preflight candidate was admitted')


inventory = json.loads(gzip.decompress(execute.read(AUDIT / 'corrected-intake.json.gz')))
assert corrected_intake.validate(inventory)
assert set(execute.ORDER) == set(inventory['cohorts']) and len(execute.ORDER) == len(set(execute.ORDER))
def slots():
    return {str(path): prepare.identity(path.read_bytes()) if path.exists() else None
            for prefix in ('', 'corrected-') for label in execute.ORDER
            for suffix in ('-started.json.gz', '-actual.json.gz', '-source-view.json.gz')
            for path in (ROOT / AUDIT / (prefix + label + suffix),)}


before_slots = slots()
# A controlled changed source must refuse even once the genuine preparation is committed.
original_read = execute.read
first = str(AUDIT / execute.PROGRAMMES[0])
model_revision = '1' * 40


def declared(command):
    if command[1:4] == ['--no-replace-objects', 'log', '-1']:
        return (model_revision + '\n').encode()
    if command[1:4] == ['--no-replace-objects', 'show', '-s']:
        return (execute.SUBJECT + '\n').encode()
    assert command[:3] == ['git', '--no-replace-objects', 'show']
    return original_read(command[3].split(':', 1)[1])


def changed_read(path):
    body = original_read(path)
    return body + b'\n# substituted source\n' if str(path) == first else body


with patch.object(execute, 'command', side_effect=declared):
    assert execute.qualification() == model_revision
    with patch.object(execute, 'read', side_effect=changed_read):
        refused(execute.qualification)

# Model only the prospective committed input tree; no Git object or source file is changed.
revision = execute.command(['git', '--no-replace-objects', 'rev-parse', 'HEAD']).decode().strip()
expected = execute.tree(revision)
model_paths = set(str(AUDIT / part) for part in execute.PROGRAMMES)
model_paths.update(name.decode() for name in execute.command(
    ['git', '--no-replace-objects', 'diff', '--name-only', '-z', 'HEAD']).split(b'\0') if name)
for name in model_paths:
    body = execute.read(name)
    oid = execute.hashlib.sha1(b'blob ' + str(len(body)).encode() + b'\0' + body).hexdigest()
    expected[name] = ('100644', 'blob', oid)
rows = execute.source_snapshot(expected)
bad = copy.deepcopy(expected)
name = str(AUDIT / 'execute_corrected.py')
mode, kind, oid = bad[name]
bad[name] = (mode, kind, '0' * len(oid))
refused(lambda: execute.source_snapshot(bad))

# Complete source shape accepts legitimate future task progress, then refuses actual goal loss.
prospective = copy.deepcopy(rows)
task_name = prepare.TASK
body = prepare.unblob(prospective[task_name])
acceptance = inventory['acceptance']
plan = prepare.premises()[0]
phases = {plan[key]: 'active' for key in ('family', 'join', 'parent', 'acceptance')}
phases.update({plan['full_alias']: 'pending', acceptance + '.2.1': 'done', acceptance + '.2.2': 'active',
               acceptance + '.2.2.2': 'done', acceptance + '.2.2.3': 'active'})
for unit, after in phases.items():
    before = prepare.field(prepare.nodes(body)[unit], 'Status')
    old = ('- ID: `' + unit + '`\n  Status: `' + before + '`').encode()
    assert body.count(old) == 1
    body = body.replace(old, old.replace(('`' + before + '`').encode(), ('`' + after + '`').encode()), 1)
prospective[task_name] = dict(prepare.blob(body), mode='100644')
entries = b''.join((row['mode'] + ' ' + execute.hashlib.sha1(
    b'blob ' + str(len(prepare.unblob(row))).encode() + b'\0' + prepare.unblob(row)).hexdigest()
    + ' 0\t' + name + '\0').encode() for name, row in prospective.items())
assert execute.index_matches(prospective, entries)
refused(lambda: execute.index_matches(prospective, entries.replace(b'100644 ', b'100755 ', 1)))
with patch.object(execute, 'tree', return_value=expected):
    assert reader.validate_sources(prospective, revision)
    bad = copy.deepcopy(prospective)
    del bad[next(name for name in bad if name.endswith('.pm'))]
    refused(lambda: reader.validate_sources(bad, revision))
    bad = copy.deepcopy(prospective)
    name = str(AUDIT / 'execute_corrected.py')
    bad[name] = dict(prepare.blob(prepare.unblob(bad[name]) + b'\n# changed programme\n'), mode='100644')
    refused(lambda: reader.validate_sources(bad, revision))

refused(lambda: reader.unblob(dict(prepare.blob(b''), bytes=False)))
refused(lambda: reader.unblob(dict(prepare.blob(b'a'), bytes=1.0)))
tools = execute.tools()
assert reader.validate_tools(tools)
bad_tools = copy.deepcopy(tools)
bad_tools['git']['bytes'] = float(bad_tools['git']['bytes'])
refused(lambda: reader.validate_tools(bad_tools))

# Real native host-counter calls qualify only the observation route, never a cohort.
origin = time.monotonic()
samples = [execute.observe(lambda: execute.sample(origin)), execute.observe(lambda: execute.sample(origin))]
assert reader.validate_resources(samples, True)
for label in ('gap', 'missing', 'status_kind', 'empty', 'order'):
    bad = copy.deepcopy(samples)
    if label == 'gap':
        bad[0]['error'] = 'explicit observation gap'
    elif label == 'missing':
        bad[0]['value']['native'].pop()
    elif label == 'status_kind':
        bad[0]['value']['native'][0]['status'] = False
    elif label == 'empty':
        bad[0]['value']['native'][0]['stdout'] = prepare.blob(b'')
    else:
        bad[1]['value']['elapsed_seconds'] = bad[0]['value']['elapsed_seconds']
    refused(lambda: reader.validate_resources(bad, True))
refused(lambda: reader.validate_resources(samples, 1))

# Retained actual focused output is a historical oracle, not a new test execution.
old = json.loads(gzip.decompress(execute.read(prepare.CLOSEOUT / 'focused-actual.json.gz')))
assert old['status'] == 0
stdout = prepare.unblob(old['streams']['stdout'])
stderr = prepare.unblob(old['streams']['stderr'])
assert reader.validate_streams('focused', stdout, stderr, rows, inventory)
refused(lambda: reader.validate_streams('focused', stdout, stderr.replace(b'Ran 33 tests', b'Ran 32 tests'), rows, inventory))
refused(lambda: reader.validate_streams('focused', stdout, b'Ran 33 tests in 1.0s\n\nOK\n', rows, inventory))

# The current retained native render qualifies the independent copied-byte/HTML oracle.
book = execute.book_epoch()
book_rows = copy.deepcopy(rows)
routes = [json.loads(line) for line in prepare.unblob(rows[reader.MANIFEST]).splitlines()]
for route in routes:
    # The retained render has its own dated operational-state epoch.
    book_rows[route['source']] = dict(prepare.blob(prepare.unblob(book[route['asset']])),
                                      mode=rows[route['source']]['mode'])
assert reader.validate_book(book, book_rows, inventory)
bad = copy.deepcopy(book)
bad[routes[0]['asset']] = dict(prepare.blob(b'borrowed source'), symlink_target=None)
refused(lambda: reader.validate_book(bad, book_rows, inventory))
bad = copy.deepcopy(book)
bad['13k-isf-feature-support-matrix.html'] = dict(prepare.blob(b'<html></html>'), symlink_target=None)
refused(lambda: reader.validate_book(bad, book_rows, inventory))

# A prerequisite refusal stops before the current slot or any cohort process begins.
class PrerequisiteRefusal(Exception):
    pass


seen = []


def prior(label):
    seen.append(label)
    if label == 'native_book':
        raise PrerequisiteRefusal()
    return {'qualification': revision}


original_popen = execute.subprocess.Popen


def no_cohort(command, *args, **kwargs):
    assert command[0] != 'scripts/run_with_ram_guard.sh', 'no cohort may launch'
    return original_popen(command, *args, **kwargs)


with patch.object(execute, 'qualification', return_value=revision), patch.object(reader, 'verify', side_effect=prior), \
        patch.object(execute.subprocess, 'Popen', side_effect=no_cohort):
    refused(lambda: execute.main('source_views'), (PrerequisiteRefusal,))
assert seen == list(execute.ORDER[:-1])
assert slots() == before_slots

# Closed intake candidates cannot add a current-role view or narrow original obligations.
for label in ('historical_command', 'current_command', 'promote', 'missing_import', 'contract', 'native_scope'):
    bad = copy.deepcopy(inventory)
    if label == 'historical_command':
        bad['cohorts']['prerequisites']['command'] = bad['cohorts']['prerequisites']['original_command']
    elif label == 'current_command':
        bad['cohorts']['current']['command'] = bad['cohorts']['prerequisites']['command']
    elif label == 'promote':
        bad['historical_source_image']['proposal']['historical_cohorts'].append('current')
    elif label == 'missing_import':
        del bad['historical_source_image']['historical_imports']['modules']['scripts/check_record_value_publication.py']
    elif label == 'contract':
        del bad['original_contracts'][next(iter(bad['original_contracts']))]
    else:
        bad['limits']['fresh_original_native_assurance'] = True
    refused(lambda: corrected_intake.validate(bad))

# Delegate only to inert runners. Exercise the actual wrapper's argv/source/restoration boundary.
import replay_historical
import historical_factory
import sys

prior_path, prior_argv = sys.path[:], sys.argv[:]
prior_read = Path.read_bytes
receipts = []


def inert_runner(entry, run_name):
    assert entry == inventory['cohorts'][role]['original_command'][2]
    assert run_name == '__main__' and sys.argv == [entry]
    assert sys.path[0] == str(ROOT / Path(entry).parent)
    assert Path(historical_factory.FACTORY).read_bytes() == historical_factory.check_image(
        inventory['historical_source_image'])


for role in ('prerequisites', 'association'):
    with patch.object(replay_historical.execute, 'save', side_effect=lambda path, value: receipts.append((path, value))):
        replay_historical.replay(role, inert_runner)
    path, receipt = receipts[-1]
    assert path == replay_historical.receipt_path(role)
    assert reader.validate_historical(role, receipt, inventory)
    other = 'association' if role == 'prerequisites' else 'prerequisites'
    refused(lambda: reader.validate_historical(other, receipt, inventory))
    for label in ('no_reads', 'live_source', 'not_restored', 'exception', 'borrowed_role'):
        bad = copy.deepcopy(receipt)
        if label == 'no_reads':
            bad['proof']['reads'] = []
        elif label == 'live_source':
            bad['proof']['historical_factory'] = bad['proof']['live_factory']
        elif label == 'not_restored':
            bad['restored'] = False
        elif label == 'exception':
            bad['error'] = 'semantic replay failed'
        else:
            bad['proof']['reads'][0]['role'] = other
        refused(lambda: reader.validate_historical(role, bad, inventory))
    assert Path.read_bytes is prior_read and sys.path == prior_path and sys.argv == prior_argv


class ReplayFailure(Exception):
    pass


def failed_runner(entry, run_name):
    assert Path(historical_factory.FACTORY).read_bytes()
    raise ReplayFailure('inert first failure')


with patch.object(replay_historical.execute, 'save', side_effect=lambda path, value: receipts.append((path, value))):
    refused(lambda: replay_historical.replay('association', failed_runner), (ReplayFailure,))
assert receipts[-1][1]['error'] and receipts[-1][1]['restored'] is True
refused(lambda: reader.validate_historical('association', receipts[-1][1], inventory))
refused(lambda: replay_historical.replay('current', inert_runner))
assert Path.read_bytes is prior_read and sys.path == prior_path and sys.argv == prior_argv
assert slots() == before_slots
print('Corrected closed source/command/intake/stop/resource/book and historical receipt controls pass; no semantic reader or acceptance cohort executes.')
