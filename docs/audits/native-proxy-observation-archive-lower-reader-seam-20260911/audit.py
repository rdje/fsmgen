"""Verify weak ownership, actual descriptor probes and separate caller cleanup."""
from __future__ import annotations

import copy
import errno
import hashlib
import json
import os
from pathlib import Path
import re
import subprocess

BASE = Path(__file__).resolve().parent
ROOT = BASE.parents[2]
LOG = ROOT / '.artifacts/logs/native-proxy-observation-archive-lower-reader-seam-20260911'
REVISION = '94ba98609063049d44a46f1dddd19fd065e130cd'
CLOSE = BASE.parent / 'native-proxy-observation-archive-close-reports-20260911'
NATIVE_FIELDS = (0, 1, 2, 3, 4, 5, 6, 7, 9, 10, 11, 12)  # Access time may change on a read.


def domain(plan):
    cases = []
    for profile in ['empty', 'binary', 'maximum']:
        for keep in [0, 1]:
            cases.append(dict(name=f'{profile}:{keep}', profile=profile, keep_open=keep, fail_read=False, strong_alias=False))
    cases.append(dict(name='read-failure:weak', profile='binary', keep_open=1, fail_read=True, strong_alias=False))
    cases.append(dict(name='read-failure:strong-counterexample', profile='binary', keep_open=1, fail_read=True, strong_alias=True))
    assert plan['cases'] == cases
    assert len({row['name'] for row in cases}) == len(cases)


def source_proof(reader, observer):
    body = reader.split('sub _read_file {', 1)[1].split('\nsub ', 1)[0]
    assert 'my $LIMIT = 65_536;' in reader
    assert 'sysopen(my $fh, $absolute, O_RDONLY | O_NOFOLLOW | O_NONBLOCK)' in body
    assert 'my $count = sysread($fh, my $chunk, $LIMIT + 1 - length($body));' in body
    assert 'close($fh) or die "cannot close fixture: $!\\n" unless $keep_open;' in body
    assert r'return ($body, \@before, $keep_open ? $fh : undef);' in body
    assert 'weaken($ROW->{weak_alias});' in observer
    assert '$ROW->{strong_alias} = $_[0] if $SELECTION->{strong_alias};' in observer
    assert 'POSIX::dup($descriptor)' in observer
    assert 'POSIX::close($descriptor)' not in observer
    assert observer.index('$ROW->{at_reader_return} = _probe(') < observer.index('my @owned =') < observer.index('$ROW->{after_cleanup} = _probe(')


def native(actual, file):
    assert type(actual) is list and len(actual) == 13 and all(type(value) is int for value in actual)
    assert actual[0] == file['device'] and actual[1] == file['inode']
    assert actual[2] == (0o100000 | file['mode']) and actual[3] == file['links']
    assert actual[4] == file['uid'] and actual[7] == file['size_bytes']


def probe(row, descriptor, expected_open, opened):
    assert set(row) == {'descriptor', 'duplicate', 'errno', 'metadata', 'duplicate_close', 'duplicate_closed_probe'}
    assert row['descriptor'] == descriptor
    if not expected_open:
        assert row['duplicate'] is None and row['errno'] == errno.EBADF
        assert row['metadata'] is row['duplicate_close'] is row['duplicate_closed_probe'] is None
        return 0
    assert type(row['duplicate']) is int and row['duplicate'] >= 0 and row['duplicate'] != descriptor
    assert row['errno'] == 0
    assert type(row['metadata']) is list and len(row['metadata']) == 13
    assert all(row['metadata'][index] == opened[index] for index in NATIVE_FIELDS)
    assert row['duplicate_close'] == dict(returned=1, errno=0, attached_closed=1)
    assert row['duplicate_closed_probe'] == dict(duplicate=None, errno=errno.EBADF)
    return 1


def verify(plan, report):
    assert report['schema'] == 'fsmgen.inactive_archive_lower_reader_seam_qualification.v1'
    assert report['success'] is True and report['forbidden_process_attempts'] == 0
    assert [row['name'] for row in report['cases']] == [row['name'] for row in plan['cases']]
    allocations = []
    counts = dict(cases=0, direct_reader_calls=0, returned_reads=0, failed_reads=0, explicit_reader_closes=0,
                  caller_closes=0, strong_control_recoveries=0, reader_return_open=0, reader_return_closed=0,
                  observer_duplicates_closed=0, observed_read_calls=0, actual_read_syscalls=0, injected_read_errors=0,
                  actual_read_bytes=0, strong_bias_detected=0)
    for selection, row in zip(plan['cases'], report['cases'], strict=True):
        assert row['selection'] == selection and row['root_absent'] == 1
        root = row['root']; allocations.append(root)
        assert set(root) == {'path', 'device', 'inode'}
        assert re.fullmatch(r'\.artifacts/tmp/native-proxy-observation-archive-lower-reader-seam-20260911/cases/fsmgen-[A-Za-z0-9_]+', root['path'])
        before = row['before']; assert row['after'] == before
        assert set(before) == {'root', 'files'} and set(before['files']) == {'source.data', 'other.data'}
        assert before['root'] == dict(device=root['device'], inode=root['inode'], mode=0o700, uid=os.getuid())
        raw = b'' if selection['profile'] == 'empty' else bytes(range(256)) if selection['profile'] == 'binary' else b'M' * 65536
        for name, expected in [('source.data', raw), ('other.data', b'untouched\0observer\xff')]:
            file = before['files'][name]
            assert set(file) == {'device', 'inode', 'mode', 'uid', 'links', 'size_bytes', 'bytes_hex', 'sha256'}
            assert file['device'] == root['device'] and file['uid'] == os.getuid() and file['mode'] == 0o400 and file['links'] == 1
            assert type(file['inode']) is int and file['inode'] > 0
            assert file['bytes_hex'] == expected.hex() and file['size_bytes'] == len(expected)
            assert file['sha256'] == hashlib.sha256(expected).hexdigest()
        assert len({before['root']['inode'], *(file['inode'] for file in before['files'].values())}) == 3
        op = row['operation']; opened = op['opened']; descriptor = opened['descriptor']
        assert op['observer_completed'] == 1 and op['observer_error'] == ''
        assert op['open_return'] == 1 and type(op['open_errno']) is int
        assert type(descriptor) is int and descriptor >= 0
        assert op['alias_is_weak'] == 1 and 'weak_alias' not in op and 'strong_alias' not in op
        assert opened['cloexec'] in (0, 1)
        native(opened['metadata'], before['files']['source.data'])
        failed = selection['fail_read']; keep = selection['keep_open']; strong = selection['strong_alias']
        assert op['reader_returned'] == int(not failed)
        assert op['reader_error'] == ('cannot read fixture bytes: ' + os.strerror(errno.EIO) + '\n' if failed else '')
        if failed:
            assert op['result'] is None
        else:
            assert op['result'] == dict(bytes_hex=raw.hex(), metadata=opened['metadata'], descriptor=descriptor if keep else None)
        expected_reads = []
        if failed:
            expected_reads.append(dict(index=0, requested=65537, returned=None, errno=errno.EIO,
                                       injected=1, chunk_defined=0, chunk_hex=None))
        else:
            chunks = [raw, b''] if raw else [b'']
            consumed = 0
            for index, chunk in enumerate(chunks):
                # Successful calls may preserve an earlier errno; the unchanged
                # reader uses errno only when the return is undefined.
                actual_errno = op['reads'][index]['errno']; assert type(actual_errno) is int
                expected_reads.append(dict(index=index, requested=65537 - consumed, returned=len(chunk), errno=actual_errno,
                                           injected=0, chunk_defined=1, chunk_hex=chunk.hex()))
                consumed += len(chunk)
        assert op['reads'] == expected_reads
        expected_events = ['sysopen:before', 'sysopen:after']
        for index in range(len(expected_reads)):
            expected_events += [f'sysread:{index}:before', f'sysread:{index}:after']
        if not failed and not keep:
            assert len(op['reader_closes']) == 1
            close = op['reader_closes'][0]
            assert set(close) == {'returned', 'errno', 'closed_after_call'}
            assert close['returned'] == close['closed_after_call'] == 1 and type(close['errno']) is int
            expected_events += ['reader_close:before', 'reader_close:after']
            counts['explicit_reader_closes'] += 1
        else:
            assert op['reader_closes'] == []
        expected_events += ['reader:return']; assert op['events'] == expected_events
        is_open = strong or (not failed and bool(keep))
        assert op['weak_alive_at_return'] == op['weak_open_at_return'] == int(is_open)
        assert op['cloexec_at_reader_return'] == (opened['cloexec'] if is_open else None)
        counts['observer_duplicates_closed'] += probe(op['at_reader_return'], descriptor, is_open, opened['metadata'])
        counts['observer_duplicates_closed'] += probe(op['after_cleanup'], descriptor, False, opened['metadata'])
        role = 'strong_counterexample' if strong else 'returned'
        assert op['cleanup'] == ([dict(role=role, descriptor=descriptor, returned=1, errno=0, closed_after_call=1)] if is_open else [])
        counts['caller_closes'] += int(not failed and bool(keep))
        counts['strong_control_recoveries'] += int(strong)
        counts['strong_bias_detected'] += int(failed and strong and is_open)
        counts['reader_return_open' if is_open else 'reader_return_closed'] += 1
        counts['returned_reads' if not failed else 'failed_reads'] += 1
        counts['observed_read_calls'] += len(expected_reads)
        counts['actual_read_syscalls'] += sum(not read['injected'] for read in expected_reads)
        counts['injected_read_errors'] += sum(read['injected'] for read in expected_reads)
        counts['actual_read_bytes'] += sum(read['returned'] or 0 for read in expected_reads)
        counts['cases'] += 1; counts['direct_reader_calls'] += 1
    assert allocations == report['allocated'] and len({row['path'] for row in allocations}) == len(allocations)
    weak, strong = report['cases'][-2:]
    assert weak['operation']['reader_error'] == strong['operation']['reader_error']
    assert weak['operation']['reader_returned'] == strong['operation']['reader_returned'] == 0
    assert weak['operation']['at_reader_return']['duplicate'] is None
    assert strong['operation']['at_reader_return']['duplicate'] is not None
    return dict(counts, roots=len(allocations))


def rejects(call):
    try: call()
    except (AssertionError, KeyError, TypeError, ValueError, IndexError): return True
    return False


def main():
    plan = json.loads((BASE / 'plan.json').read_bytes()); assert plan['source_revision'] == REVISION
    prior = json.loads((CLOSE / 'plan.json').read_bytes()); expected = {row['path'] for row in prior['inputs']}
    expected.update(str((CLOSE / name).relative_to(ROOT)) for name in ('plan.json', 'audit.py'))
    assert [row['path'] for row in plan['inputs']] == sorted(expected)
    pins = json.loads((BASE / 'preflight-pins.json').read_bytes())
    assert [row['path'] for row in pins] == [str((BASE / name).relative_to(ROOT)) for name in
        ('plan.py', 'plan.json', 'LowerReaderTrace.pm', 'qualify.t', 'audit.py', 'toolchain-reference.json')]
    def authenticate():
        for pin in plan['inputs'] + pins:
            raw = (ROOT / pin['path']).read_bytes()
            assert len(raw) == pin['size_bytes'] and hashlib.sha256(raw).hexdigest() == pin['sha256']
            if pin in plan['inputs']:
                assert raw == subprocess.check_output(['git', 'show', REVISION + ':' + pin['path']], cwd=ROOT)
    authenticate(); domain(plan)
    reader = (ROOT / 't/lib/FSM/Test/RustProxyFixture.pm').read_text(); observer = (BASE / 'LowerReaderTrace.pm').read_text()
    source_proof(reader, observer)
    report = json.loads((LOG / 'qualification.json').read_bytes()); counts = verify(plan, report)
    journal = [json.loads(line) for line in (LOG / 'admission.jsonl').read_text().splitlines()]
    assert journal == report['allocated']
    device = ROOT.stat().st_dev
    for row in journal:
        path = ROOT / row['path']; assert not path.exists() and not path.is_symlink() and row['device'] == device
        parent = path.parent
        while parent != ROOT:
            assert parent.is_dir() and not parent.is_symlink() and parent.stat().st_dev == device
            parent = parent.parent
    assertions = len(plan['cases']) * 6 + 1
    tap = (LOG / 'qualify.tap').read_text()
    assert re.findall(r'^1\.\.([0-9]+)$', tap, re.M) == [str(assertions)]
    assert [int(value) for value in re.findall(r'^ok ([0-9]+) - ', tap, re.M)] == list(range(1, assertions + 1))
    assert not re.search(r'^(?:not ok|Bail out!)|#\s*(?:SKIP|TODO)', tap, re.M)
    assert (LOG / 'qualify.exit').read_text().strip() == '0'
    def weak(r): return r['cases'][-2]['operation']
    def strong(r): return r['cases'][-1]['operation']
    def kept(r): return r['cases'][3]['operation']
    def closed(r): return r['cases'][0]['operation']
    changes = [
        ('missing case', lambda r: r['cases'].pop()),
        ('duplicate case', lambda r: r['cases'].append(copy.deepcopy(r['cases'][0]))),
        ('changed selection', lambda r: r['cases'][-1]['selection'].update(strong_alias=False)),
        ('hidden observer error', lambda r: weak(r).update(observer_error='observer failure')),
        ('missing weak alias proof', lambda r: weak(r).update(alias_is_weak=0)),
        ('lost open observation', lambda r: weak(r).update(open_return=0)),
        ('wrong source inode', lambda r: kept(r)['opened']['metadata'].__setitem__(1, 7)),
        ('wrong returned bytes', lambda r: kept(r)['result'].update(bytes_hex='00')),
        ('hidden reader failure', lambda r: weak(r).update(reader_returned=1)),
        ('replaced original error', lambda r: weak(r).update(reader_error='cleanup error\n')),
        ('missing actual read', lambda r: kept(r)['reads'].pop()),
        ('wrong read bound', lambda r: kept(r)['reads'][0].update(requested=65538)),
        ('unhit read error', lambda r: weak(r)['reads'][0].update(injected=0)),
        ('missing explicit reader close', lambda r: closed(r)['reader_closes'].clear()),
        ('failed explicit reader close', lambda r: closed(r)['reader_closes'][0].update(returned=0)),
        ('hidden strong liveness', lambda r: strong(r)['at_reader_return'].update(duplicate=None)),
        ('weak observer retained ownership', lambda r: weak(r).update(weak_alive_at_return=1)),
        ('changed returned CLOEXEC', lambda r: kept(r).update(cloexec_at_reader_return=1-kept(r)['opened']['cloexec'])),
        ('wrong closed-descriptor errno', lambda r: weak(r)['at_reader_return'].update(errno=errno.EIO)),
        ('probe aliases original descriptor', lambda r: kept(r)['at_reader_return'].update(duplicate=kept(r)['opened']['descriptor'])),
        ('unclosed observer duplicate', lambda r: kept(r)['at_reader_return']['duplicate_close'].update(returned=0)),
        ('open duplicate after close', lambda r: kept(r)['at_reader_return']['duplicate_closed_probe'].update(duplicate=7)),
        ('lost caller cleanup', lambda r: kept(r)['cleanup'].clear()),
        ('unperformed strong recovery', lambda r: strong(r)['cleanup'][0].update(returned=0)),
        ('healed pre-recovery truth', lambda r: strong(r).update(at_reader_return=copy.deepcopy(strong(r)['after_cleanup']))),
        ('post-cleanup source still open', lambda r: weak(r)['after_cleanup'].update(duplicate=7)),
        ('changed bystander', lambda r: r['cases'][0]['after']['files']['other.data'].update(bytes_hex='00')),
        ('lost allocation', lambda r: r['allocated'].pop()),
        ('fixture residue', lambda r: r['cases'][0].update(root_absent=0)),
        ('process attempt', lambda r: r.update(forbidden_process_attempts=1)),
    ]
    for name, change in changes:
        altered = copy.deepcopy(report); change(altered); assert rejects(lambda: verify(plan, altered)), name
    domain_changes = [
        ('missing strong counterexample', lambda p: p['cases'].pop()),
        ('missing weak failure', lambda p: p['cases'].pop(-2)),
        ('lost maximum boundary', lambda p: p['cases'][4].update(profile='binary')),
        ('changed keep-open route', lambda p: p['cases'][0].update(keep_open=1)),
    ]
    for name, change in domain_changes:
        altered = copy.deepcopy(plan); change(altered); assert rejects(lambda: domain(altered)), name
    source_changes = [
        ('lost lexical source ownership', True, 'sysopen(my $fh,', 'sysopen($fh,'),
        ('lost weak alias', False, 'weaken($ROW->{weak_alias});', '# retain strong alias'),
        ('unconditional strong retention', False, 'if $SELECTION->{strong_alias};', ';'),
        ('original numeric descriptor close', False, 'POSIX::dup($descriptor)', 'POSIX::close($descriptor)'),
    ]
    for name, change_reader, old, new in source_changes:
        altered = [reader, observer]; index = 0 if change_reader else 1; assert old in altered[index]
        altered[index] = altered[index].replace(old, new); assert rejects(lambda: source_proof(*altered)), name
    authenticate()
    output = dict(schema='fsmgen.inactive_archive_lower_reader_seam_audit.v1', success=True, **counts,
        tap_assertions=assertions, report_falsifiers=[name for name, _ in changes],
        domain_falsifiers=[name for name, _ in domain_changes], source_falsifiers=[row[0] for row in source_changes],
        predecessor_inputs_unchanged=len(plan['inputs']), prospective_inputs_unchanged=len(pins),
        all_allocations_absent=True, limits=plan['limits'])
    (LOG / 'audit.json').write_text(json.dumps(output, indent=2, sort_keys=True) + '\n')
    print(json.dumps(output, sort_keys=True))


if __name__ == '__main__':
    main()
