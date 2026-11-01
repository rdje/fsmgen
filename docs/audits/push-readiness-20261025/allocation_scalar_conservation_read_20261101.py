#!/usr/bin/env python3
"""Verify retained public allocation evidence; never run a compiler or query."""
import argparse
import copy
import gzip
import hashlib
import json
from pathlib import Path

BASE = Path(__file__).resolve().parent
ROOT = BASE.parents[2]
PACKET = BASE / 'allocation-scalar-conservation-20261101.json.gz'


def digest(data):
    return hashlib.sha256(data).hexdigest()


def encoded(value):
    return json.dumps(value, sort_keys=True, separators=(',', ':'))


def verify(packet):
    assert packet['owner'] == 'PUBLICATION-REGRESSION-REPAIRS.20.2.2.4'
    reference = packet['baseline_packet']
    assert reference['path'] == 'docs/audits/push-readiness-20261025/full8-intake-20261101.json.gz'
    saved = (ROOT / reference['path']).read_bytes()
    assert digest(saved) == reference['sha256']
    predecessor = json.loads(gzip.decompress(saved))
    native = packet['native_record']
    assert native['revision'] == packet['revision'] == packet['public_outcome']['revision']
    assert native['complete'] is True and len(native['commands']) == 1
    status = native['commands'][0]['exit_status']
    assert type(status) is int and status == 0
    assert '--verify-hdl' in native['commands'][0]['command']
    assert native['log'] == 'docs/audits/push-readiness-20261025/allocation-scalar-native-20261101.log.gz'
    log = gzip.decompress((ROOT / native['log']).read_bytes())
    assert digest(log) == native['retained_log_sha256'] == packet['native_log_sha256']
    assert b'real 64.40\n' in log
    commands = packet['public_outcome']['commands']
    assert [row['label'] for row in commands] == ['carriers', 'schedule']
    for row in commands:
        assert type(row['exit_status']) is int and row['exit_status'] == 0
    for row in packet['members'].values():
        assert digest(row['text'].encode()) == row['retained_sha256']
    for label in ['carriers', 'schedule']:
        assert packet['members'][label + '-stderr.log']['text'] == ''
        before = json.loads(predecessor['operational_members'][
            'full8-baseline-cost/current-' + label + '.json']['text'])
        after = json.loads(packet['members'][label + '-stdout.json']['text'])
        assert encoded(before) == encoded(after)
    hdl = packet['hdl']
    assert hdl['bytes'] == len(hdl['text'].encode()) > 0
    assert digest(hdl['text'].encode()) == hdl['retained_sha256']
    before = predecessor['operational_members'][
        'full8-baseline-cost/source/.artifacts/observed-2.sv']['text']
    left, right = before.splitlines(True), hdl['text'].splitlines(True)
    assert len(left) == len(right) and hdl['date_header_line'] == 4
    assert left[3] == hdl['before_date_header'] and right[3] == hdl['after_date_header']
    assert left[3].startswith('// Date: ') and right[3].startswith('// Date: ')
    right[3] = left[3]
    assert ''.join(right) == before and hdl['all_other_bytes_equal'] is True
    producer = packet['date_producer']
    assert digest(producer['text'].encode()) == producer['sha256']
    assert '"// Date: " . localtime()' in producer['text']
    assert packet['settlement']['residue'] == []
    return {'native_exit': status, 'public_products_equal': True,
            'hdl_equal_except_generation_date': True, 'full_ci_pass': False}


def change_number_kind(value):
    if isinstance(value, dict):
        for key, child in value.items():
            if type(child) is int and abs(child) < 2 ** 53:
                value[key] = float(child)
                return True
            if change_number_kind(child):
                return True
    elif isinstance(value, list):
        for index, child in enumerate(value):
            if type(child) is int and abs(child) < 2 ** 53:
                value[index] = float(child)
                return True
            if change_number_kind(child):
                return True
    return False


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--self-test', action='store_true')
    args = parser.parse_args()
    packet = json.loads(gzip.decompress(PACKET.read_bytes()))
    result = verify(packet)
    if args.self_test:
        boolean_status = copy.deepcopy(packet)
        boolean_status['native_record']['commands'][0]['exit_status'] = False
        changed_hdl = copy.deepcopy(packet)
        changed_hdl['hdl']['text'] += '// changed output body\n'
        changed_hdl['hdl']['bytes'] = len(changed_hdl['hdl']['text'].encode())
        changed_hdl['hdl']['retained_sha256'] = digest(changed_hdl['hdl']['text'].encode())
        changed_kind = copy.deepcopy(packet)
        row = changed_kind['members']['schedule-stdout.json']
        value = json.loads(row['text'])
        assert change_number_kind(value)
        row['text'] = json.dumps(value)
        row['retained_sha256'] = digest(row['text'].encode())
        for invalid in [boolean_status, changed_hdl, changed_kind]:
            try:
                verify(invalid)
            except AssertionError:
                continue
            raise AssertionError('Distinguishing corruption was accepted')
        result['distinguishing_corruptions_rejected'] = 3
    print(json.dumps(result, sort_keys=True))


if __name__ == '__main__':
    main()
