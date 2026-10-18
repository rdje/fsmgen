"""Inert execution-intake controls, including real retained stream/book oracles."""
import argparse
import copy
import gzip
import json
from pathlib import Path
import time
from unittest.mock import patch

import execute_selected as execute
import selected_intake
import prepare
import verify_selected as reader

ROOT, AUDIT = execute.ROOT, execute.AUDIT


def refused(function, exceptions=(AssertionError, KeyError, ValueError)):
    try:
        function()
    except exceptions:
        return
    raise AssertionError('hostile preflight candidate was admitted')


profile = json.loads(gzip.decompress(execute.read(AUDIT / 'selected-intake.json.gz')))
inventory = selected_intake.effective(profile)
assert prepare.validate(inventory)
assert set(execute.ORDER) == set(inventory['cohorts']) and len(execute.ORDER) == len(set(execute.ORDER))
def slots():
    return {str(path): prepare.identity(path.read_bytes()) if path.exists() else None
            for prefix in ('', 'corrected-', 'snapshot-', 'selected-') for label in execute.ORDER
            for suffix in ('-started.json.gz', '-actual.json.gz', '-source-view.json.gz')
            for path in (ROOT / AUDIT / (prefix + label + suffix),)}


before_slots = slots()
assert not execute.safe(execute.WORK).exists(), 'fresh exclusive output namespace before admission'
assert all(value is None for name, value in before_slots.items()
           if Path(name).name.startswith('selected-')), 'no selected cohort slot has been spent'
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
    ['git', '--no-replace-objects', 'ls-files', '--others', '--exclude-standard', '-z']).split(b'\0')
                   if name and execute.selected(name.decode()))
model_paths.update(name.decode() for name in execute.command(
    ['git', '--no-replace-objects', 'diff', '--name-only', '-z', 'HEAD']).split(b'\0') if name)
for name in model_paths:
    body = execute.read(name)
    oid = execute.hashlib.sha1(b'blob ' + str(len(body)).encode() + b'\0' + body).hexdigest()
    expected[name] = ('100644', 'blob', oid)
rows = execute.source_snapshot(expected)
bad = copy.deepcopy(expected)
name = str(AUDIT / 'execute_selected.py')
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
               acceptance + '.2.2.2': 'done', acceptance + '.2.2.3': 'active',
               acceptance + '.2.2.3.2': 'done', acceptance + '.2.2.3.3': 'active',
               acceptance + '.2.2.3.3.1': 'done', acceptance + '.2.2.3.3.2': 'active',
               acceptance + '.2.2.3.3.2.3.1': 'done', acceptance + '.2.2.3.3.2.3.2': 'done',
               acceptance + '.2.2.3.3.2.3.3': 'active'})
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
    name = str(AUDIT / 'execute_selected.py')
    bad[name] = dict(prepare.blob(prepare.unblob(bad[name]) + b'\n# changed programme\n'), mode='100644')
    refused(lambda: reader.validate_sources(bad, revision))
    bad = copy.deepcopy(prospective)
    original_task = prepare.unblob(bad[task_name])
    goal = prepare.field(prepare.nodes(original_task)[inventory['family']], 'Goal').encode()
    assert original_task.count(goal) == 1
    bad[task_name] = dict(prepare.blob(original_task.replace(goal, b'narrowed original obligation', 1)), mode='100644')
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
for stop in execute.ORDER[:-1]:
    seen.clear()

    def prior_at_every_position(label):
        seen.append(label)
        if label == stop:
            raise PrerequisiteRefusal()
        return {'qualification': revision}

    with patch.object(execute, 'qualification', return_value=revision), \
            patch.object(reader, 'verify', side_effect=prior_at_every_position), \
            patch.object(execute.subprocess, 'Popen', side_effect=no_cohort):
        refused(lambda: execute.main('source_views'), (PrerequisiteRefusal,))
    assert seen == list(execute.ORDER[:execute.ORDER.index(stop) + 1])
assert slots() == before_slots

# The complete source/cwd profile preserves every command and refuses scope borrowing.
for label in ('command', 'current_cwd', 'historical_cwd', 'revision', 'evidence', 'instrument', 'promotion'):
    bad = copy.deepcopy(profile)
    if label == 'command':
        bad['commands']['prerequisites'].append('--core')
    elif label == 'current_cwd':
        bad['working_directories']['current'] = bad['working_directories']['prerequisites']
    elif label == 'historical_cwd':
        bad['working_directories']['association'] = '.'
    elif label == 'revision':
        bad['snapshot_revision'] = revision
    elif label == 'evidence':
        del bad['evidence']['selected-checkout-portable-qualification-actual.json.gz']
    elif label == 'instrument':
        del bad['instruments']['selected_checkout.py']
    else:
        bad['historical_cohorts'].append('current')
    refused(lambda: selected_intake.validate(bad))
for label in execute.ORDER:
    wanted = str(selected_intake.checkout.FOLDER) if label in selected_intake.HISTORICAL else '.'
    assert selected_intake.cwd(label, profile) == wanted
    assert profile['commands'][label] == inventory['cohorts'][label]['command']
refused(lambda: selected_intake.cwd('../prerequisites', profile))

# One fresh whole physical/source/index check qualifies observation only, never semantic execution.
observation = selected_intake.observe_snapshot()
for label in selected_intake.HISTORICAL:
    assert selected_intake.validate_observation(label, observation, profile)
for label in ('current', 'publication', 'book'):
    refused(lambda: selected_intake.validate_observation(label, observation, profile))
for label in ('borrowed_source', 'missing_index', 'typed_index', 'runtime', 'member', 'mode', 'entry'):
    bad = copy.deepcopy(observation)
    if label == 'borrowed_source':
        bad['git']['revision'] = revision
    elif label == 'missing_index':
        del bad['git']['index']
    elif label == 'typed_index':
        bad['git']['index']['bytes'] = float(bad['git']['index']['bytes'])
    elif label == 'runtime':
        bad['runtime_files'] = ['.artifacts/tmp/undeclared']
    elif label == 'member':
        del bad['members'][next(iter(bad['members']))]
    elif label == 'mode':
        first = next(iter(bad['members']))
        bad['members'][first]['mode'] = '100755' if bad['members'][first]['mode'] != '100755' else '100644'
    else:
        bad['git']['entries'] = prepare.blob(b'wrong index entries')
    refused(lambda: selected_intake.validate_observation('prerequisites', bad, profile))
assert slots() == before_slots
assert execute.source_snapshot(expected) == rows, 'complete primary source conservation during inert controls'
assert selected_intake.checkout.matches_prepared(selected_intake.observe_snapshot(), observation)
parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--record', action='store_true')
parser.add_argument('--attempt', choices=('first', 'final'), default='first')
args = parser.parse_args()
if args.record:
    execute.save(AUDIT / ('selected-preflight-' + args.attempt + '-qualified.json.gz'),
                 dict(schema='fsmgen.selected_intake_inert_qualification.v1',
                      profile=profile, primary_source=rows, prospective_source=prospective,
                      historical_source=observation, resource_samples=samples, tools=tools,
                      slots_before=before_slots, slots_after=slots(),
                      scope='All declared complete source/command/cwd/contract/index/resource/tool/book and '
                            'each prior-stop controls execute inertly. Prospective phase/index are explicit '
                            'preparation models, never actual committed admission. No semantic cohort executes.'))
print('Selected-checkout closed source/cwd/command/contract/custody/stop/resource/book controls pass; no semantic reader or acceptance cohort executes.')
