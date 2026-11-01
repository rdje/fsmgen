#!/usr/bin/env python3
"""Verify saved full8 intake only; never launch a query, compiler or full run."""
import argparse
import collections
import copy
import gzip
import hashlib
import io
import json
from pathlib import Path
import re
import tarfile

BASE = Path(__file__).resolve().parent
ROOT = BASE.parents[2]
PACKET = BASE / 'full8-intake-20261101.json.gz'


def digest(data):
    return hashlib.sha256(data).hexdigest()


def encoded(value):
    return json.dumps(value, sort_keys=True, separators=(',', ':')).encode()


def member(packet, name):
    return packet['operational_members'][name]['text']


def record(packet, name):
    return json.loads(member(packet, name))


def status(value, expected):
    assert type(value) is int and value == expected


def verify(packet):
    assert packet['owner'] == 'PUBLICATION-REGRESSION-REPAIRS.20.1'
    assert packet['revision'] == 'f149d74ce6f0be4cb2d1730dc7310bed4e3abeae'
    run = packet['run_record']
    assert run['revision'] == packet['revision']
    assert len(run['commands']) == 1
    status(run['commands'][0]['exit_status'], 143)
    native = gzip.decompress((ROOT / run['log']).read_bytes())
    assert digest(native) == run['retained_log_sha256']
    text = native.decode()
    passed = re.findall(r'^(t/\S+\.t)\s+\.+\s+ok\s*$', text, re.M)
    failed = []
    last = None
    for line in text.splitlines():
        if re.match(r'^t/\S+\.t\s', line):
            last = line.split()[0]
        if line.startswith('Dubious,'):
            failed.append(last)
    census = packet['native_census']
    assert census['reported_passing_files'] == passed and len(passed) == 471
    assert census['observed_failing_files'] == failed and len(failed) == 23
    assert len(set(failed)) == len(failed)
    assert census['native_failed_test_markers'] == text.count('Failed test') == 93
    assert set(packet['repair_owner_by_test']) == set(failed)

    for value in packet['operational_members'].values():
        assert digest(value['text'].encode()) == value['retained_sha256']
    for source in packet['original_source_material']:
        assert digest(source['text'].encode()) == source['sha256']
    assert set(failed) <= {x['path'] for x in packet['original_source_material']}

    for epoch in packet['source_epochs']:
        path = Path(epoch['archive'])
        assert not path.is_absolute() and '..' not in path.parts
        compressed = (ROOT / path).read_bytes()
        assert digest(compressed) == epoch['archive_sha256']
        raw = gzip.decompress(compressed)
        assert digest(raw) == epoch['git_archive_sha256']
        expected = {x['path']: x for x in epoch['regular_blobs']}
        actual = set()
        with tarfile.open(fileobj=io.BytesIO(raw)) as archive:
            for item in archive.getmembers():
                assert not Path(item.name).is_absolute() and '..' not in Path(item.name).parts
                assert item.isdir() or item.isfile()
                if not item.isfile():
                    continue
                data = archive.extractfile(item).read()
                source = expected[item.name]
                assert len(data) == source['bytes'] and digest(data) == source['sha256']
                blob = b'blob ' + str(len(data)).encode() + b'\0' + data
                assert hashlib.sha1(blob).hexdigest() == source['git_blob']
                assert item.name not in actual
                actual.add(item.name)
        assert actual == set(expected)

    settled = record(packet, 'full8-owned-settlement.json')
    assert settled['signal_target'] == 31594 and settled['signal'] == 'SIGTERM'
    assert all(value is None for value in settled['after'].values())
    status(settled['owned_group_lookup']['exit_status'], 1)
    baseline = record(packet, 'full8-baseline-cost/native-outcome-2.json')
    status(baseline['exit_status'], 0)
    assert baseline['stop_reason'] is None and baseline['known_child_identity_after'] is None
    assert baseline['stdout'] == baseline['stderr'] == ''
    assert type(baseline['elapsed_seconds']) is float and 0 < baseline['elapsed_seconds'] < 30
    hdl = member(packet, 'full8-baseline-cost/source/.artifacts/observed-2.sv').encode()
    assert digest(hdl) == baseline['output']['sha256'] and len(hdl) == baseline['output']['bytes']
    for suffix, field in [('schedule', 'complete_schedule_json_equal'),
                          ('carriers', 'complete_generated_carriers_equal')]:
        left = record(packet, 'full8-baseline-cost/baseline-' + suffix + '.json')
        right = record(packet, 'full8-baseline-cost/current-' + suffix + '.json')
        assert encoded(left) == encoded(right)
        comparison = 'generated-input-comparison' if suffix == 'schedule' else 'generated-carrier-comparison'
        result = record(packet, 'full8-baseline-cost/' + comparison + '.json')
        assert result[field] is True and result['difference_paths'] == []

    sampled = record(packet, 'full8-perl-stack-sampling/outcome.json')
    status(sampled['exit_status'], -15)
    assert sampled['stop_reason'] == 'declared_30_second_deadline'
    assert sampled['known_pid_after'] is None
    stacks = [json.loads(line) for line in member(packet, 'full8-perl-stack-sampling/stacks.jsonl').splitlines()]
    assert len(stacks) == sampled['sample_count'] == 120
    counts = collections.Counter()
    for row in stacks:
        frames = [f for f in row['frames'] if (f.get('subroutine') or '').startswith('FSM::')]
        if frames:
            counts[frames[0]['subroutine']] += 1
    assert [list(x) for x in counts.most_common(20)] == sampled['sampled_top_FSM_methods']
    assert counts['FSM::Adapter::FSMGenFull::ExpressionBuilder::_source_tree_allocation_transition'] > 0

    names = ['t1333-contract-counterfactual', 'actor-width-counterfactuals',
             'actor-constant-counterfactuals', 'package-and-default-width-counterfactuals',
             'transaction-local-counterfactual']
    controls = []
    for name in names:
        result = record(packet, 'full8-width-controls/' + name + '.json')
        status(result['native_outcome']['exit_status'], 0)
        cases = result.get('cases', [result])
        for case in cases:
            assert case['inverse_byte_identity'] is True
            assert digest(case['original']['text'].encode()) == case['original']['sha256']
            assert digest(case['counterfactual']['text'].encode()) == case['counterfactual']['sha256']
            controls.append(case['original']['path'])
    assert len(controls) == len(set(controls)) == 17
    assert set(controls) <= set(failed)
    return {'reported_passing_files': len(passed), 'observed_failing_files': len(failed),
            'native_failure_markers': census['native_failed_test_markers'],
            'diagnostic_control_files': len(controls), 'full_ci_pass': False}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--self-test', action='store_true')
    args = parser.parse_args()
    packet = json.loads(gzip.decompress(PACKET.read_bytes()))
    result = verify(packet)
    if args.self_test:
        invalid = copy.deepcopy(packet)
        invalid['run_record']['commands'][0]['exit_status'] = False
        omitted = copy.deepcopy(packet)
        omitted['repair_owner_by_test'].pop(next(iter(omitted['repair_owner_by_test'])))
        changed = copy.deepcopy(packet)
        target = changed['operational_members']['full8-baseline-cost/current-carriers.json']
        data = json.loads(target['text'])
        files = data['generated_ial0']['files']
        files[next(iter(files))] += '\n'
        target['text'] = json.dumps(data)
        target['retained_sha256'] = digest(target['text'].encode())
        for label, value in [('boolean status', invalid), ('unowned failure', omitted),
                             ('changed carrier with refreshed member hash', changed)]:
            try:
                verify(value)
            except AssertionError:
                continue
            raise AssertionError('Accepted invalid control: ' + label)
        result['rejected_controls'] = 3
    print('full8 saved intake: OK ' + json.dumps(result, sort_keys=True))


if __name__ == '__main__':
    main()
