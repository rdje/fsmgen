"""Prospective source/data admission; saved verification never executes fixtures."""
from __future__ import annotations

import argparse
import copy
import hashlib
import json
import os
import re
import subprocess

from support import BASE, ROOT, LOG, MODEL, CONTRACT, OLD_MODEL, authenticate, canonical, digest, document, pin, write
import consume
import oracle
from prepare import build


def rejects(callback):
    try:
        callback()
    except (AssertionError, KeyError, TypeError, ValueError, IndexError):
        return True
    return False


def selection_checks(selection, domain):
    assert selection['source_revision'] == 'f451fda60b2761441deb3429bef6aac5852c458f'
    assert selection['execution_owner'] == selection['owner'].removesuffix('.1') + '.2'
    assert selection['execution_admitted'] is False and selection['runtime_qualification'] is False
    assert selection['bounds'] == dict(case_wall_seconds=30, cases=8, cleanup_wall_seconds=10,
        file_bytes=65536, fixture_roots=32, record_bytes=4194304, total_record_bytes=67108864,
        total_wall_seconds=300, tree_bytes=4194304, tree_depth=8, tree_nodes=128)
    assert selection['trace_limits'] == dict(calls=32768, handles=2048)
    assert len(selection['cases']) == 8
    names, roots, stages = [], [], []
    for case in selection['cases']:
        assert dict(profile=case['profile'], order=case['order']) in domain['schedules']
        assert re.fullmatch('[a-z_]+', case['name']) and case['name'] not in names
        names.append(case['name']); stem = 'fsmgen-LifetimeFiles20260913_' + case['name']
        expected = dict(store='.artifacts/tmp/native-proxy-image-custody/cases/' + stem,
            target='.artifacts/tmp/process-supervisor-tests/' + stem + '_target',
            other='.artifacts/tmp/process-supervisor-tests/' + stem + '_other',
            evidence='.artifacts/logs/native-proxy-observation-acquisition-20260910/cases/' + stem)
        assert case['roots'] == expected; roots.extend(expected.values())
        stages.append(dict(case=case['name'], names=consume.stage_names(case)))
    assert len(set(roots)) == 32
    assert all(not first.startswith(second + '/') for first in roots for second in roots if first != second)
    assert [case['profile'] for case in selection['cases']].count('same_image') == 4
    assert [case['profile'] for case in selection['cases']].count('different_image') == 4
    assert any(case['order'].index('maintain_target') < case['order'].index('retire_other')
               for case in selection['cases'] if case['profile'] == 'different_image')
    return dict(cases=8, fixture_roots=roots, stages=stages,
        stage_count=sum(len(row['names']) for row in stages),
        repeated_observations=sum(name.startswith('reuse_') for row in stages for name in row['names']))


def source_checks(sources):
    main, trace, files, data, emit = [sources[name] for name in
        ('qualify.pl', 'LifetimeTrace.pm', 'LifetimeFiles.pm', 'qualify_data.t', 'admit_execution.py')]
    for token in ('--execute-admitted', 'execution-admission.json', 'admission_commit', 'task_sha256',
                  'preflight_sha256', 'active_work_unit:', 'normal user required', 'total_wall_seconds',
                  'case_wall_seconds', 'cleanup_wall_seconds', "journal('case-primary'", "journal('case-final'",
                  "journal('run-final'", 'cleanup_case($context)', 'last unless $ok && $clean',
                  'main() unless caller;', 'runtime_qualification => 0'):
        assert token in main, token
    assert main.index('use LifetimeTrace;') < main.index('use Coordination;')
    assert main.index('authenticate();', main.index('sub main')) < main.index('ensure_project_artifact_dir(qw(tmp')
    assert main.index("journal('case-primary'") < main.index('$cleanup = cleanup_case($context)')
    assert "sub (*$;$$)" in trace and 'CORE::syswrite($_[0], $_[1]);' in trace
    assert trace.index('push @HELD, $row') < trace.index('observed descriptor bound exceeded')
    assert trace.index('push @OBSERVER_HELD') < trace.index('@native = stat($probe)')
    assert trace.index('$copy{closed_at_return}') < trace.index('owner_kind => \'implementation\'')
    for token in ('O_NOFOLLOW', 'O_NONBLOCK', 'FD_CLOEXEC', 'sub cleanup_exact',
                  'owned cleanup identity changed', 'owned cleanup file bytes changed',
                  'owned cleanup directory gained members', '4194304', '65536'):
        assert token in files, token
    assert 'fixture_attempts' in data and 'process_attempts' in data and 'O_EXCL' in data
    for token in ('git', 'show', "Status: `done`", "Status: `active`", 'preflight-pins.json',
                  'execution-admission.json', "open('xb')", 'os.lstat', '--emit'):
        assert token in emit, token
    return dict(guarded_main=True, descriptor_ownership_before_validation=True,
                first_outcome_before_cleanup=True, actual_execution_requires_committed_admission=True)


def layout_checks(plan):
    layout = document(BASE / 'task-layout.json')
    raw = subprocess.check_output(['git', 'show', plan['source_revision'] + ':' + layout['source_task']], cwd=ROOT)
    assert hashlib.sha256(raw).hexdigest() == layout['source_git_sha256']
    old = raw.decode(); edit = layout['source_edit']
    expanded = old[:edit['start']] + edit['replacement'] + old[edit['end']:]
    assert hashlib.sha256(expanded.encode()).hexdigest() == layout['expanded_sha256']
    result = expanded
    for offset in sorted(layout['removed_empty_line_offsets'], reverse=True):
        assert expanded[offset:offset + 8] == '\n\n- ID: '
        result = result[:offset] + result[offset + 1:]
    assert hashlib.sha256(result.encode()).hexdigest() == layout['normalized_sha256']
    assert [row for row in expanded.splitlines() if row] == [row for row in result.splitlines() if row]
    assert result.count('\n') == layout['live_lines'] == 6366
    return dict(removed_empty_separators=len(layout['removed_empty_line_offsets']), nonempty_loss=0, ceiling_increase=0)


def first_failure():
    failure = document(BASE / 'first-main-syntax-failure.json')
    original = {}
    for row in failure['copies']:
        assert pin(row['copy']['path']) == row['copy']
        raw = (ROOT / row['copy']['path']).read_bytes()
        assert len(raw) == row['original']['size_bytes']
        assert hashlib.sha256(raw).hexdigest() == row['original']['sha256']
        original[row['original']['path']] = raw
    prefix = str(BASE.relative_to(ROOT)) + '/'
    old = original[prefix + 'LifetimeTrace.pm'].decode()
    corrected = old.replace('*CORE::GLOBAL::syswrite = sub (*$$;$)', '*CORE::GLOBAL::syswrite = sub (*$;$$)', 1).replace(
        'my $count = @_ == 4 ? CORE::syswrite($_[0], $_[1], $_[2], $_[3]) : CORE::syswrite($_[0], $_[1], $_[2]);',
        'my $count = @_ == 4 ? CORE::syswrite($_[0], $_[1], $_[2], $_[3])\n'
        '            : @_ == 3 ? CORE::syswrite($_[0], $_[1], $_[2]) : CORE::syswrite($_[0], $_[1]);', 1).replace(
        "handle => $handle->{ordinal}, requested => $_[2],",
        "handle => $handle->{ordinal}, requested => @_ >= 3 ? $_[2] : length($_[1]),", 1)
    assert corrected == (BASE / 'LifetimeTrace.pm').read_text() and corrected != old
    assert original[prefix + 'qualify_data.t'].decode().replace("'data-pins.json'", "'corrected-data-pins.json'", 1) == (BASE / 'qualify_data.t').read_text()
    assert failure['first_exit'] == 2 and failure['actual_fixture_operations'] == 0
    for row in failure['raw_captures']:
        raw = bytes.fromhex(row['bytes_hex'])
        assert len(raw) == row['size_bytes'] and hashlib.sha256(raw).hexdigest() == row['sha256']
    stderr = next(bytes.fromhex(row['bytes_hex']) for row in failure['raw_captures'] if row['path'].endswith('main-syntax.stderr'))
    assert b'Not enough arguments for CORE::GLOBAL::syswrite' in stderr and b'IO/Handle.pm line 461' in stderr
    return dict(first_exit=2, source_copies=len(original), preserved_raw_captures=len(failure['raw_captures']),
                cause='native optional syswrite length rejected by observer signature', corrected_signature='*$;$$')


def inert_checks(selection):
    data = document(BASE / 'prepared.json'); seeds = document(MODEL / 'prepared.json')['seeds']
    assert data == build(selection, seeds)
    results = document(BASE / 'data-qualification.json')
    assert results['fixture_attempts'] == results['process_attempts'] == 0
    for row in results['checks']:
        if 'returned' in row:
            assert row['returned'] == row['expected']
            assert bool(row['error_hex']) != bool(row['returned'])
        else:
            assert row['actual_sha256'] == row['expected_sha256']
    vectors = [row for row in results['checks'] if 'expected_sha256' in row]
    assert len(vectors) == len(data['vectors']) == 64
    assert [row['expected_sha256'] for row in vectors] == [row['expected_sha256'] for row in data['vectors']]
    payloads = {name: bytes.fromhex(data['payloads'][name + '_hex']) for name in ('wrapper', 'c', 'image')}
    controls = []
    for profile, context in data['contexts'].items():
        bounds = selection['bounds']; before = digest(context)
        consume.snapshot(context['initial'], context['roots'], bounds, 501, 1)
        seed = consume.initial(context, payloads, bytes.fromhex(data['different_image_suffix_hex']))
        assert OLD_MODEL.initial(seed) == OLD_MODEL.initial(seeds[profile])
        assert digest(context) == before
        wrapper = context['paths']['target'] + '/rust-tool-resolution'
        for name in ('missing_member', 'changed_bytes', 'authority', 'runtime_identity'):
            changed = copy.deepcopy(context)
            if name == 'missing_member': del changed['initial']['nodes'][wrapper]
            if name == 'changed_bytes': changed['initial']['nodes'][wrapper]['bytes_hex'] += '00'
            if name == 'authority': changed['runtimes']['target']['runtime_authorized'] = 1
            if name == 'runtime_identity': changed['runtimes']['target']['reference']['global']['identity']['inode'] += 1
            assert rejects(lambda: consume.initial(changed, payloads, bytes.fromhex(data['different_image_suffix_hex'])))
            controls.append(profile + ':' + name)
        for name in ('wrong_uid', 'wrong_mode', 'wrong_native_inode', 'wrong_bytes', 'wrong_absence'):
            changed = copy.deepcopy(context['initial']); node = changed['nodes'][wrapper]
            if name == 'wrong_uid': node['uid'] += 1
            if name == 'wrong_mode': node['mode'] = 0o777
            if name == 'wrong_native_inode': node['native_before'][1] += 1
            if name == 'wrong_bytes': node['bytes_hex'] += '00'
            if name == 'wrong_absence': changed['absent_roots'].append(context['paths']['target'])
            assert rejects(lambda: consume.snapshot(changed, context['roots'], bounds, 501, 1))
            controls.append(profile + ':' + name)
    return dict(contexts=2, prefixes=64, perl_record_checks=len(results['checks']) - 64,
                independent_consumer_controls=controls, fixture_attempts=0, process_attempts=0)


def trace_controls():
    root = '.artifacts/tmp/inert-only'; path = root + '/file'
    close = dict(caller='synthetic', returned=1, errno=25, closed_after_call=1, cloexec_before_close=1)
    value = dict(returned=1, error_hex='', ownership_registration_error_hex='', recovery=[], result=None,
        handles=[dict(ordinal=0, opening_call=0, path=path, open_caller='synthetic', kind='file', descriptor=5,
            native_at_open=[1, 1, 0o100400, 1, 501, 501, 0, 0, 0, 0, 0, 4096, 0],
            closed_at_return=1, close=copy.deepcopy(close))], metadata_observers=[],
        calls=[dict(operation='sysopen', path=path, flags=os.O_RDONLY | os.O_NOFOLLOW,
                    caller='synthetic', returned=1, errno=25, handle=0),
               dict(operation='close', handle=0, **close)])
    limits = dict(handles=2048, calls=32768)
    assert consume.trace(value, [root], limits, readonly=True) == {}
    controls = []
    for name in ('open_at_return', 'recovered', 'failed_close', 'unowned_close', 'missing_open', 'wrong_path', 'primary_error', 'writable_probe'):
        changed = copy.deepcopy(value)
        if name == 'open_at_return': changed['handles'][0]['closed_at_return'] = 0
        if name == 'recovered': changed['recovery'] = [dict(returned=1)]
        if name == 'failed_close': changed['calls'][1]['returned'] = 0
        if name == 'unowned_close': changed['calls'][1]['handle'] = 1
        if name == 'missing_open': changed['calls'].pop(0)
        if name == 'wrong_path': changed['calls'][0]['path'] = '.artifacts/tmp/foreign/file'
        if name == 'primary_error': changed['error_hex'] = '78'
        if name == 'writable_probe': changed['calls'][0]['flags'] |= os.O_WRONLY
        assert rejects(lambda: consume.trace(changed, [root], limits, readonly=True)), name
        controls.append(name)
    return dict(synthetic_positive=1, successful_errno=25, rejected=controls, actual_descriptor_operations=0)


def verify(plan):
    selection = document(BASE / 'selection.json'); domain = document(CONTRACT / 'corrected-contracts.json')
    sources = {name: (BASE / name).read_text() for name in
        ('qualify.pl', 'LifetimeTrace.pm', 'LifetimeFiles.pm', 'qualify_data.t', 'admit_execution.py')}
    result = dict(selection=selection_checks(selection, domain), source=source_checks(sources), layout=layout_checks(plan),
                  first_failure=first_failure(), inert=inert_checks(selection), traces=trace_controls())
    falsifiers = []
    for name in ('duplicate_case', 'invalid_order', 'foreign_root', 'runtime_authority'):
        changed = copy.deepcopy(selection)
        if name == 'duplicate_case': changed['cases'][1] = copy.deepcopy(changed['cases'][0])
        if name == 'invalid_order': changed['cases'][0]['order'].reverse()
        if name == 'foreign_root': changed['cases'][0]['roots']['store'] = '.artifacts/tmp/other'
        if name == 'runtime_authority': changed['runtime_qualification'] = True
        assert rejects(lambda: selection_checks(changed, domain)), name
        falsifiers.append(name)
    for name, path, token in [('missing_execution_barrier', 'qualify.pl', '--execute-admitted'),
                             ('missing_task_pin', 'qualify.pl', 'task_sha256'),
                             ('wrong_syswrite_prototype', 'LifetimeTrace.pm', 'sub (*$;$$)')]:
        changed = dict(sources); changed[path] = changed[path].replace(token, 'OMITTED')
        assert rejects(lambda: source_checks(changed)), name
        falsifiers.append(name)
    result.update(schema='fsmgen.inactive_lifetime_files_admission_review.v1', owner=plan['owner'],
        source_revision=plan['source_revision'], input_files=len(plan['inputs']),
        input_bytes=sum(row['size_bytes'] for row in plan['inputs']), admission_falsifiers=falsifiers,
        prospective_source_admitted=True, actual_fixture_execution=False, runtime_qualification=False,
        missing_legs=['actual isolated filesystem effects', 'native process authentication', 'live canonical-store integration'])
    result['audit_failures'] = [document(BASE / name) for name in ('first-audit-failure.json', 'second-audit-failure.json')]
    for failure in result['audit_failures']:
        for row in failure['source_copies']:
            raw = (ROOT / row['copy']).read_bytes()
            assert len(raw) == row['size_bytes'] and hashlib.sha256(raw).hexdigest() == row['sha256']
        for row in failure['raw_captures']:
            raw = bytes.fromhex(row['bytes_hex'])
            assert len(raw) == row['size_bytes'] and hashlib.sha256(raw).hexdigest() == row['sha256']
        assert failure['first_exit'] == 1
    return result


def raw_checks(rows):
    assert len(rows) == 12
    by_name = {}
    for row in rows:
        raw = bytes.fromhex(row['bytes_hex'])
        assert len(raw) == row['size_bytes'] and hashlib.sha256(raw).hexdigest() == row['sha256']
        by_name[row['path'].rsplit('/', 1)[1]] = raw
    assert by_name['prepare.exit'] == by_name['corrected-syntax.exit'] == by_name['data.exit'] == b'0\n'
    assert by_name['main-syntax.exit'] == b'2\n'
    tap = by_name['data.stdout'].decode()
    assert tap.splitlines()[-1] == '1..96' and len(re.findall(r'^ok [0-9]+ - ', tap, re.M)) == 96
    assert not re.search(r'^(not ok|Bail out!)', tap, re.M)
    assert b'qualify.pl syntax OK' in by_name['corrected-syntax.stderr']


def main():
    parser = argparse.ArgumentParser(); group = parser.add_mutually_exclusive_group(required=True)
    group.add_argument('--retain', action='store_true'); group.add_argument('--verify-saved', action='store_true')
    args = parser.parse_args(); plan = document(BASE / 'plan.json')
    authenticate(plan, document(BASE / 'preflight-pins.json'))
    result = verify(plan)
    if args.retain:
        rows = []
        for stage in ('prepare', 'main-syntax', 'corrected-syntax', 'data'):
            for suffix in ('stdout', 'stderr', 'exit'):
                path = LOG / (stage + '.' + suffix)
                rows.append(dict(pin(path), bytes_hex=path.read_bytes().hex()))
        raw_checks(rows); result['raw_captures'] = rows
        write(BASE / 'review.json', result)
    else:
        saved = document(BASE / 'review.json'); raw_checks(saved['raw_captures'])
        assert {key: value for key, value in saved.items() if key != 'raw_captures'} == result
    print('lifetime source admission: OK; cases=%d prefixes=%d stages=%d actual_fixture_execution=0' %
          (result['selection']['cases'], result['inert']['prefixes'], result['selection']['stage_count']))


if __name__ == '__main__':
    main()
