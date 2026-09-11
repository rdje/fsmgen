"""Verify direct lower-reader rejection, controlled reads and lexical cleanup."""
from __future__ import annotations

import copy
import errno
import hashlib
import importlib.util
import json
import os
from pathlib import Path
import re
import subprocess

BASE = Path(__file__).resolve().parent
ROOT = BASE.parents[2]
LOG = ROOT / '.artifacts/logs/native-proxy-observation-archive-lower-reader-failures-20260911'
REVISION = '05957842d584b6b3f434e2b2d20c65316e16e39c'
SEAM_BASE = BASE.parent / 'native-proxy-observation-archive-lower-reader-seam-20260911'
module = importlib.util.spec_from_file_location('qualified_lower_reader_observer_oracle', SEAM_BASE / 'audit.py')
SEAM = importlib.util.module_from_spec(module); module.loader.exec_module(SEAM)
SEAM_FILES = ('plan.py', 'plan.json', 'LowerReaderTrace.pm', 'qualify.t', 'audit.py', 'toolchain-reference.json',
              'preflight-pins.json', 'result/qualification.json', 'result/audit.json', 'result/recovery-copies.json')


def domain(plan):
    cases = [dict(name=name, profile=profile, control=control, keep_open=1,
                  fail_read=control == 'first-eio', strong_alias=False) for name, profile, control in
             [('empty', 'empty', 'none'), ('binary', 'binary', 'none'), ('maximum', 'maximum', 'none'),
              ('directory', 'directory', 'none'), ('oversized', 'oversized', 'none'),
              ('first-eio', 'binary', 'first-eio'), ('partial-eio', 'binary', 'partial-eio'),
              ('early-eof', 'binary', 'early-eof'), ('named-replacement', 'binary', 'named-replacement')]]
    assert plan['cases'] == cases and len({row['name'] for row in cases}) == len(cases)


def source_proof(reader, observer, controls):
    SEAM.source_proof(reader, observer)
    body = reader.split('sub _read_file {', 1)[1].split('\nsub ', 1)[0]
    assert body.index('sysopen(') < body.index('S_ISREG($before[2])') < body.index('my $count = sysread(')
    assert '$before[7] <= $LIMIT;' in body and 'length($body) == $before[7]' in body
    assert 'my @named = lstat($absolute);' in body
    assert r'my $original_read = \&CORE::GLOBAL::sysread;' in controls
    assert controls.count('goto &$original_read;') == 1
    assert "goto &$original_read unless $NativeProxyLowerReaderTrace::ACTIVE\n            && caller eq 'FSM::Test::RustProxyFixture';" in controls
    assert 'caller_requested => 0 + $_[2]' in controls
    assert "splice @_, 2, 1, 1 if $action eq 'one-byte-delegation';" in controls
    assert 'rename($path, $retained)' in controls
    assert "open my $writer, '>:raw', $path" in controls


def native(actual, node):
    if node['kind'] == 'file':
        SEAM.native(actual, node)
    else:
        assert type(actual) is list and len(actual) == 13 and all(type(value) is int for value in actual)
        assert actual[0] == node['device'] and actual[1] == node['inode']
        assert actual[2] == (0o040000 | node['mode']) and actual[4] == node['uid']


def physical(selection, row):
    before, after = row['before'], row['after']; root = row['root']
    assert set(before) == set(after) == {'root', 'files'}
    assert before['root'] == after['root'] == dict(device=root['device'], inode=root['inode'], mode=0o700, uid=os.getuid())
    assert set(before['files']) == {'source.data', 'other.data'}
    profile = selection['profile']
    raw = b'' if profile == 'empty' else bytes(range(256)) if profile == 'binary' else b'M' * 65536 if profile == 'maximum' else b'O' * 65537 if profile == 'oversized' else None
    for name, expected in [('source.data', raw), ('other.data', b'untouched\0observer\xff')]:
        node = before['files'][name]
        assert node['device'] == root['device'] and node['uid'] == os.getuid()
        assert type(node['inode']) is int and node['inode'] > 0
        if expected is None:
            assert set(node) == {'device', 'inode', 'mode', 'uid', 'kind', 'members'}
            assert node['kind'] == 'directory' and node['mode'] == 0o700 and node['members'] == []
        else:
            assert set(node) == {'device', 'inode', 'mode', 'uid', 'kind', 'links', 'size_bytes', 'bytes_hex', 'sha256'}
            assert node['kind'] == 'file' and node['mode'] == 0o400 and node['links'] == 1
            assert node['bytes_hex'] == expected.hex() and node['size_bytes'] == len(expected)
            assert node['sha256'] == hashlib.sha256(expected).hexdigest()
    original = before['files']['source.data']; bystander = before['files']['other.data']
    assert len({root['inode'], original['inode'], bystander['inode']}) == 3
    operation = row['operation']
    if selection['control'] != 'named-replacement':
        assert before == after and 'named_replacement' not in operation
        return raw
    assert set(after['files']) == {'source.data', 'other.data', 'source.data.retained-original'}
    assert after['files']['source.data.retained-original'] == original and after['files']['other.data'] == bystander
    replacement = after['files']['source.data']
    assert set(replacement) == set(original)
    assert type(replacement['inode']) is int and replacement['inode'] > 0
    assert replacement['inode'] not in {root['inode'], original['inode'], bystander['inode']}
    assert {k: v for k, v in replacement.items() if k != 'inode'} == {k: v for k, v in original.items() if k != 'inode'}
    record = operation['named_replacement']
    assert set(record) == {'complete', 'source_before', 'descriptor_before', 'bytes_sha256', 'retained_basename',
                          'named_after', 'retained_after', 'descriptor_after'}
    assert record['complete'] == 1 and record['retained_basename'] == 'source.data.retained-original'
    assert record['bytes_sha256'] == original['sha256']
    for key in ['source_before', 'descriptor_before', 'retained_after', 'descriptor_after']:
        native(record[key], original)
    native(record['named_after'], replacement)
    assert record['source_before'] == record['descriptor_before']
    assert record['retained_after'] == record['descriptor_after']
    assert record['descriptor_after'][:2] != record['named_after'][:2]
    return raw


def reads(selection, operation, raw):
    profile, control = selection['profile'], selection['control']
    expected = []; controls = []
    if profile in ('directory', 'oversized'):
        assert operation['reads'] == operation['read_controls'] == []
        return []
    if control == 'first-eio': chunks = [None]
    elif control == 'partial-eio': chunks = [raw[:1], None]
    elif control == 'early-eof': chunks = [b'']
    else: chunks = [raw, b''] if raw else [b'']
    consumed = 0
    for index, chunk in enumerate(chunks):
        caller_requested = 65537 - consumed
        action = 'one-byte-delegation' if control == 'partial-eio' and index == 0 else 'injected-eio' if control == 'partial-eio' and index == 1 else 'injected-eof' if control == 'early-eof' else 'replace-then-delegate' if control == 'named-replacement' and index == 1 else 'delegate'
        delegated = None if action.startswith('injected-') else 1 if action == 'one-byte-delegation' else caller_requested
        controls.append(dict(index=index, caller_requested=caller_requested, delegated_requested=delegated, action=action))
        injected = chunk is None or control == 'early-eof'
        error = errno.EIO if chunk is None else 0 if control == 'early-eof' else operation['reads'][index]['errno']
        assert type(error) is int
        expected.append(dict(index=index, requested=delegated if delegated is not None else caller_requested,
            returned=None if chunk is None else len(chunk), errno=error, injected=int(injected),
            chunk_defined=int(chunk is not None), chunk_hex=None if chunk is None else chunk.hex()))
        consumed += len(chunk) if chunk is not None else 0
    assert operation['reads'] == expected and operation['read_controls'] == controls
    return expected


def verify(plan, report):
    assert report['schema'] == 'fsmgen.inactive_archive_lower_reader_failures_qualification.v1'
    assert report['success'] is True and report['forbidden_process_attempts'] == 0
    assert [row['name'] for row in report['cases']] == [row['name'] for row in plan['cases']]
    counts = dict(cases=0, direct_reader_calls=0, successful_handoffs=0, failed_handoffs=0,
                  type_size_rejections=0, eio_rejections=0, read_agreement_rejections=0,
                  actual_read_syscalls=0, controlled_read_returns=0, observed_read_calls=0, actual_read_bytes=0,
                  caller_closes=0, lexical_failure_closures=0, observer_duplicates_closed=0, retained_originals=0)
    allocations = []
    for selection, row in zip(plan['cases'], report['cases'], strict=True):
        assert row['selection'] == selection and row['root_absent'] == 1
        root = row['root']; allocations.append(root)
        assert set(root) == {'path', 'device', 'inode'}
        assert re.fullmatch(r'\.artifacts/tmp/native-proxy-observation-archive-lower-reader-failures-20260911/cases/fsmgen-[A-Za-z0-9_]+', root['path'])
        raw = physical(selection, row); operation = row['operation']; opened = operation['opened']; descriptor = opened['descriptor']
        native(opened['metadata'], row['before']['files']['source.data'])
        assert type(descriptor) is int and descriptor >= 0 and opened['cloexec'] in (0, 1)
        assert operation['observer_completed'] == 1 and operation['observer_error'] == ''
        assert operation['open_return'] == 1 and type(operation['open_errno']) is int
        assert operation['alias_is_weak'] == 1 and 'weak_alias' not in operation and 'strong_alias' not in operation
        observed_reads = reads(selection, operation, raw)
        events = ['sysopen:before', 'sysopen:after']
        for index in range(len(observed_reads)): events += [f'sysread:{index}:before', f'sysread:{index}:after']
        events += ['reader:return']; assert operation['events'] == events and operation['reader_closes'] == []
        profile, control = selection['profile'], selection['control']
        failed = profile in ('directory', 'oversized') or control != 'none'
        if profile in ('directory', 'oversized'):
            error = 'fixture must be an owned bounded regular file\n'; counts['type_size_rejections'] += 1
        elif control in ('first-eio', 'partial-eio'):
            error = 'cannot read fixture bytes: ' + os.strerror(errno.EIO) + '\n'; counts['eio_rejections'] += 1
        elif failed:
            error = 'fixture changed during its bounded read\n'; counts['read_agreement_rejections'] += 1
        else: error = ''
        assert operation['reader_returned'] == int(not failed) and operation['reader_error'] == error
        assert operation['result'] == (None if failed else dict(bytes_hex=raw.hex(), metadata=opened['metadata'], descriptor=descriptor))
        assert operation['weak_alive_at_return'] == operation['weak_open_at_return'] == int(not failed)
        assert operation['cloexec_at_reader_return'] == (None if failed else opened['cloexec'])
        counts['observer_duplicates_closed'] += SEAM.probe(operation['at_reader_return'], descriptor, not failed, opened['metadata'])
        SEAM.probe(operation['after_cleanup'], descriptor, False, opened['metadata'])
        assert operation['cleanup'] == ([] if failed else [dict(role='returned', descriptor=descriptor, returned=1, errno=0, closed_after_call=1)])
        counts['failed_handoffs' if failed else 'successful_handoffs'] += 1
        counts['lexical_failure_closures'] += int(failed); counts['caller_closes'] += int(not failed)
        counts['retained_originals'] += int(control == 'named-replacement')
        counts['observed_read_calls'] += len(observed_reads)
        counts['actual_read_syscalls'] += sum(not r['injected'] for r in observed_reads)
        counts['controlled_read_returns'] += sum(r['injected'] for r in observed_reads)
        counts['actual_read_bytes'] += sum((r['returned'] or 0) for r in observed_reads if not r['injected'])
        counts['cases'] += 1; counts['direct_reader_calls'] += 1
    assert allocations == report['allocated'] and len({row['path'] for row in allocations}) == len(allocations)
    return dict(counts, roots=len(allocations))


def main():
    plan = json.loads((BASE / 'plan.json').read_bytes()); assert plan['source_revision'] == REVISION
    prior_plan = json.loads((SEAM_BASE / 'plan.json').read_bytes())
    expected = {row['path'] for row in prior_plan['inputs']}
    expected.update(str((SEAM_BASE / name).relative_to(ROOT)) for name in SEAM_FILES)
    assert [pin['path'] for pin in plan['inputs']] == sorted(expected)
    pins = json.loads((BASE / 'preflight-pins.json').read_bytes())
    assert [row['path'] for row in pins] == [str((BASE / name).relative_to(ROOT)) for name in
                                          ('plan.py', 'plan.json', 'LowerReadControls.pm', 'qualify.t', 'audit.py')]
    def authenticate():
        for pin in plan['inputs'] + pins:
            raw = (ROOT / pin['path']).read_bytes()
            assert len(raw) == pin['size_bytes'] and hashlib.sha256(raw).hexdigest() == pin['sha256']
            if pin in plan['inputs']:
                assert raw == subprocess.check_output(['git', 'show', REVISION + ':' + pin['path']], cwd=ROOT)
    authenticate(); domain(plan)
    prior_report = json.loads((SEAM_BASE / 'result/qualification.json').read_bytes())
    SEAM.domain(prior_plan); prior_counts = SEAM.verify(prior_plan, prior_report)
    prior_audit = json.loads((SEAM_BASE / 'result/audit.json').read_bytes())
    assert all(prior_audit[key] == value for key, value in prior_counts.items())
    reader = (ROOT / 't/lib/FSM/Test/RustProxyFixture.pm').read_text()
    observer = (SEAM_BASE / 'LowerReaderTrace.pm').read_text(); controls = (BASE / 'LowerReadControls.pm').read_text()
    source_proof(reader, observer, controls)
    report = json.loads((LOG / 'qualification.json').read_bytes()); counts = verify(plan, report)
    journal = [json.loads(line) for line in (LOG / 'admission.jsonl').read_text().splitlines()]
    assert journal == report['allocated']; device = ROOT.stat().st_dev
    assert not ({r['path'] for r in journal} & {r['path'] for r in prior_report['allocated']})
    for row in journal:
        path = ROOT / row['path']; assert not path.exists() and not path.is_symlink() and row['device'] == device
        parent = path.parent
        while parent != ROOT:
            assert parent.is_dir() and not parent.is_symlink() and parent.stat().st_dev == device
            parent = parent.parent
    assertions = len(plan['cases']) * 6 + 1; tap = (LOG / 'qualify.tap').read_text()
    assert re.findall(r'^1\.\.([0-9]+)$', tap, re.M) == [str(assertions)]
    assert [int(value) for value in re.findall(r'^ok ([0-9]+) - ', tap, re.M)] == list(range(1, assertions + 1))
    assert not re.search(r'^(?:not ok|Bail out!)|#\s*(?:SKIP|TODO)', tap, re.M)
    assert (LOG / 'qualify.exit').read_text().strip() == '0'
    def case(r, name): return next(row for row in r['cases'] if row['name'] == name)
    def op(r, name): return case(r, name)['operation']
    def partial(r): return op(r, 'partial-eio')
    def replaced(r): return op(r, 'named-replacement')['named_replacement']
    changes = [
        ('missing case', lambda r: r['cases'].pop()),
        ('duplicate case', lambda r: r['cases'].append(copy.deepcopy(r['cases'][0]))),
        ('changed selection', lambda r: case(r, 'partial-eio')['selection'].update(control='first-eio')),
        ('hidden observer failure', lambda r: partial(r).update(observer_error='observer failure')),
        ('strong source alias', lambda r: partial(r).update(alias_is_weak=0)),
        ('lost open observation', lambda r: partial(r).update(open_return=0)),
        ('hidden successful handoff', lambda r: partial(r).update(reader_returned=1)),
        ('replaced original error', lambda r: partial(r).update(reader_error='cleanup error\n')),
        ('unperformed first byte', lambda r: partial(r)['reads'][0].update(returned=0)),
        ('wrong partial byte', lambda r: partial(r)['reads'][0].update(chunk_hex='ff')),
        ('unhit partial error', lambda r: partial(r)['reads'][1].update(injected=0)),
        ('changed caller request', lambda r: partial(r)['read_controls'][0].update(caller_requested=1)),
        ('changed delegated request', lambda r: partial(r)['read_controls'][0].update(delegated_requested=65537)),
        ('wrong early EOF', lambda r: op(r, 'early-eof')['reads'][0].update(returned=1)),
        ('late type rejection', lambda r: op(r, 'directory')['reads'].append({})),
        ('oversize input shrunk', lambda r: case(r, 'oversized')['before']['files']['source.data'].update(size_bytes=65536)),
        ('wrong directory native type', lambda r: op(r, 'directory')['opened']['metadata'].__setitem__(2, 0o100700)),
        ('missing replacement', lambda r: replaced(r).update(complete=0)),
        ('hidden named identity change', lambda r: replaced(r).update(named_after=replaced(r)['descriptor_after'][:])),
        ('lost retained original', lambda r: case(r, 'named-replacement')['after']['files'].pop('source.data.retained-original')),
        ('changed retained original bytes', lambda r: case(r, 'named-replacement')['after']['files']['source.data.retained-original'].update(bytes_hex='00')),
        ('live failed descriptor', lambda r: partial(r)['at_reader_return'].update(duplicate=7)),
        ('wrong closed-descriptor errno', lambda r: partial(r)['at_reader_return'].update(errno=errno.EIO)),
        ('manufactured failure cleanup', lambda r: partial(r)['cleanup'].append({})),
        ('missing successful caller close', lambda r: op(r, 'binary')['cleanup'].clear()),
        ('unclosed observer duplicate', lambda r: op(r, 'binary')['at_reader_return']['duplicate_close'].update(returned=0)),
        ('changed bystander', lambda r: case(r, 'partial-eio')['after']['files']['other.data'].update(bytes_hex='00')),
        ('fixture residue', lambda r: r['cases'][0].update(root_absent=0)),
        ('lost allocation', lambda r: r['allocated'].pop()),
        ('process attempt', lambda r: r.update(forbidden_process_attempts=1)),
    ]
    for name, change in changes:
        altered = copy.deepcopy(report); change(altered); assert SEAM.rejects(lambda: verify(plan, altered)), name
    domain_changes = [
        ('missing size excess', lambda p: p['cases'].pop(4)),
        ('missing partial error', lambda p: p['cases'].pop(6)),
        ('changed caller ownership', lambda p: p['cases'][0].update(keep_open=0)),
        ('biased failure observer', lambda p: p['cases'][5].update(strong_alias=True)),
    ]
    for name, change in domain_changes:
        altered = copy.deepcopy(plan); change(altered); assert SEAM.rejects(lambda: domain(altered)), name
    source_changes = [
        ('changed product bound', 0, 'my $LIMIT = 65_536;', 'my $LIMIT = 65_537;'),
        ('lost weak observation', 1, 'weaken($ROW->{weak_alias});', '# retain alias'),
        ('lost sealed caller', 2, 'goto &$original_read;', 'return $original_read->(@_);'),
        ('unrecorded caller request', 2, 'caller_requested => 0 + $_[2]', 'caller_requested => 1'),
    ]
    for name, index, old, new in source_changes:
        altered = [reader, observer, controls]; assert old in altered[index]; altered[index] = altered[index].replace(old, new)
        assert SEAM.rejects(lambda: source_proof(*altered)), name
    authenticate()
    output = dict(schema='fsmgen.inactive_archive_lower_reader_failures_audit.v1', success=True, **counts,
        tap_assertions=assertions, report_falsifiers=[name for name, _ in changes],
        domain_falsifiers=[name for name, _ in domain_changes], source_falsifiers=[row[0] for row in source_changes],
        predecessor_inputs_unchanged=len(plan['inputs']), prospective_inputs_unchanged=len(pins),
        prior_observer_counts=prior_counts, all_allocations_absent=True, original_observer_unchanged=True, limits=plan['limits'])
    (LOG / 'audit.json').write_text(json.dumps(output, indent=2, sort_keys=True) + '\n')
    print(json.dumps(output, sort_keys=True))


if __name__ == '__main__':
    main()
