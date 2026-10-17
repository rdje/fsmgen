"""Replay first failed intake and its inert copy discriminator; never qualify it."""
from pathlib import Path
import copy
import gzip
import hashlib
import json
import subprocess
import sys

if not __debug__:
    raise SystemExit('Verification assertions must be enabled.')
ROOT = Path(__file__).resolve().parents[3]
AUDIT = Path('docs/audits/task-acceptance-index-prospective-20261018')
ORIGINAL = Path('docs/audits/task-acceptance-index-observer-20261017')
sys.path.insert(0, str(ROOT / ORIGINAL))
from verify import unblob, verify, letters
from run import blob


def validate(record):
    assert record['action'] == 'controls'
    assert record['source_conserved'] and record['git_conserved']
    assert record['sources_before'] == record['sources_after'] and record['git_before'] == record['git_after']
    for group in ('sources_before', 'sources_after', 'captures', 'admissions'):
        for row in record[group].values():
            unblob(row)
    for field in ('entries', 'index', 'fixture_baseline'):
        unblob(record['git_before'][field])
    assert len(record['rows']) == 1
    row = record['rows'][0]
    assert row['selector'] == 'control_healthy' and row['status'] == 25
    assert unblob(row['stdout']) == b''
    assert unblob(row['stderr']) == b'selected test error: observer changed result fields\n\n'
    assert str(AUDIT / 'observe.pl') in row['command']
    captured = {name: unblob(row) for name, row in record['captures'].items()}
    prefix = 'control_healthy/'
    summary = json.loads(captured[prefix + 'summary.json'])
    admission_body = unblob(record['admissions']['control_healthy-admission.json'])
    admission = json.loads(admission_body)
    assert admission['sha256'] == {name: row['sha256'] for name, row in record['sources_before'].items()}
    canonical = json.dumps(admission, sort_keys=True, separators=(',', ':'), ensure_ascii=False).encode()
    assert summary['admission_sha256'] == hashlib.sha256(canonical).hexdigest()
    assert summary['actual'] == [1, 10, 1]
    assert summary['input_error'] is None
    assert summary['test_error'] == 'observer changed result fields\n'
    assert summary['coverage_error'] == 'fixed population differs'
    assert summary['receipt_coverage_error'] is None
    assert not summary['capture_gaps'] and not summary['retention_errors']
    expected = ['stage_' + letters(i) for i in range(1, 12)] + ['case_a']
    assert [row['label'] for row in summary['receipts']] == expected
    retained = {}
    for row in summary['receipts']:
        body = captured[prefix + row['label'] + '.json']
        assert hashlib.sha256(body).hexdigest() == row['sha256']
        retained[row['label']] = json.loads(body)
    native = []
    for i in range(1, 12):
        stage = retained['stage_' + letters(i)]
        result = stage['result']
        kind = 'index_checker' if i == 11 else 'index_git'
        cap = 4_194_304 if i == 11 else 1_048_576
        assert stage['arguments']['stage'] == result['stage'] == kind
        assert stage['arguments']['bounds'] == {'timeout_seconds': 10, 'capture_limit_bytes': cap}
        assert result['timeout_seconds'] == 10 and result['capture_limit_bytes'] == cap
        assert result['ok'] == 1 and result['status'] == 'success' and result['exit_code'] == 0
        assert result['exec_error'] is None
        assert result['timed_out'] == result['output_limited'] == result['signal'] == 0
        cleanup = result['cleanup']
        assert cleanup['leader_reaped'] == cleanup['group_gone'] == 1 and cleanup['surviving_descendants'] == 0
        native.append(result)
    case = retained['case_a']['result']
    assert case['status'] == 'checker_returned' and case['main_index_conserved'] == 1
    assert case['stages'] == native[:-1] and case['checker'] == native[-1]
    assert case['cleanup'] == {'retained': 0, 'retired': 1}
    assert captured[prefix + 'events.jsonl'] == b''
    children = [json.loads(body) for name, body in captured.items() if name.startswith(prefix + 'ordinary-')]
    assert len(children) == 11 and len({row['pid'] for row in children}) == 11
    assert all(row['calls'] == 1 and row['queries'] == row['writes'] == 0 and row['result'] == '0 but true' for row in children)
    try:
        verify(record)
    except AssertionError:
        return True
    raise AssertionError('failed intake promoted to qualified')


def probe_source(source):
    # Compile the supplied private module, then call only its pure predicate
    # on a decoded literal. No supervisor or fixture is invoked.
    probe = r'''
use strict; use warnings; use JSON::PP (); use Storable qw(dclone);
my $source = do {local $/; <STDIN>};
eval $source; die $@ if $@;
my $r = JSON::PP->new->decode(q({"stage":"index_checker","ok":1,"exit_code":0,"signal":0,"timed_out":0,"output_limited":0,"exec_error":null,"cleanup":{"leader_reaped":1,"group_gone":1,"surviving_descendants":0}}));
my $before = dclone($r);
my $stop = ProspectiveIndexObserver::unexpected($r, 0);
print IndexObserver::encode({before=>$before, direct=>$r, later_copy=>dclone($r), stop=>$stop});
'''
    command = ['perl', '-Iperl', '-It/lib', '-Idocs/audits/native-group-witness-20260927',
               '-Idocs/audits/native-group-witness-20260927/failure-only', '-I' + str(ORIGINAL), '-e', probe]
    result = subprocess.run(command, input=source, capture_output=True, check=True, timeout=30, cwd=ROOT)
    assert result.stderr == b''
    return json.loads(result.stdout)


def copy_discriminator(record):
    source = unblob(record['sources_before'][str(AUDIT / 'ProspectiveIndexObserver.pm')])
    witness = probe_source(source)
    assert witness['stop'] == 0 and witness['before'] == witness['direct']
    expected = copy.deepcopy(witness['before'])
    assert type(expected['exit_code']) is int
    expected['exit_code'] = '0'
    assert witness['later_copy'] == expected
    return witness


if __name__ == '__main__':
    record = json.loads(gzip.decompress((ROOT / AUDIT / 'controls.json.gz').read_bytes()))
    started = json.loads(gzip.decompress((ROOT / AUDIT / 'controls-started.json.gz').read_bytes()))
    assert all(record[key] == value for key, value in started.items())
    assert validate(record)
    for mutation in ('promote', 'source', 'cleanup', 'native'):
        bad = copy.deepcopy(record)
        if mutation == 'promote':
            bad['rows'][0]['status'] = 0
        elif mutation == 'source':
            next(iter(bad['sources_before'].values()))['sha256'] = '0' * 64
        else:
            name = 'control_healthy/stage_a.json'
            stage = json.loads(unblob(bad['captures'][name]))
            if mutation == 'cleanup':
                stage['result']['cleanup']['group_gone'] = 0
            else:
                stage['result']['exec_error'] = 'invented native rejection'
            body = json.dumps(stage, sort_keys=True, separators=(',', ':')).encode()
            bad['captures'][name] = blob(body)
            summary_name = 'control_healthy/summary.json'
            summary = json.loads(unblob(bad['captures'][summary_name]))
            summary['receipts'][0]['sha256'] = hashlib.sha256(body).hexdigest()
            bad['captures'][summary_name] = blob(json.dumps(summary, sort_keys=True).encode())
        try:
            validate(bad)
        except AssertionError:
            continue
        raise AssertionError('hostile failed-result promotion admitted: ' + mutation)
    print(json.dumps(copy_discriminator(record), sort_keys=True))
    print('Failed intake custody, settled native success, hostile controls and exact-source inert copy defect verified; qualification remains failed.')
