"""Verify dated cleanup with strict primitive kinds; never repeat deletion."""
import argparse
from datetime import datetime
import gzip
import json
import stat

import cleanup as c


def validate(value):
    expected_keys = {'owner', 'revision', 'authority', 'utc', 'prior_utc', 'programme', 'before', 'outcomes',
                     'protected_before', 'protected_after', 'census_before', 'census_after', 'extra_member_control',
                     'protected_path_control', 'residue', 'post_saved_reader'}
    assert type(value) is dict and set(value) == expected_keys
    assert type(value['outcomes']) is dict and set(value['outcomes']) == set(c.TARGETS)
    for outcome in value['outcomes'].values():
        assert type(outcome) is dict and set(outcome) == {'removed', 'absent_after'}
        assert outcome['removed'] is True and outcome['absent_after'] is True
    for key in ('extra_member_control', 'protected_path_control'):
        assert value[key]['refused'] is True
    assert value['extra_member_control']['diagnostic'] == 'whole committed file/body/mode/node/member authority'
    assert value['protected_path_control']['diagnostic'] == 'only the fixed private regular fixture population is disposable'
    native = value['post_saved_reader']
    assert set(native) == {'command', 'status', 'stdout', 'stderr'}
    assert type(native['status']) is int and native['status'] == 0
    assert native['command'] == ['scripts/run_with_ram_guard.sh', '--', 'python3', '-B',
                                 'docs/audits/original-join-parent-acceptance-20261018/verify_runtime_cache.py']
    assert c.prepare.unblob(value['programme']) == c.execute.read(c.BASE / 'cleanup.py')
    for label, relative in zip(c.LABELS, c.TARGETS):
        snapshot = value['before'][relative]
        assert set(snapshot) == {'state', 'identities', 'rg'}
        state = snapshot['state']
        assert set(state) == {'files', 'directories'}
        assert set(snapshot['identities']) == set(state['files']) | set(state['directories']) | {'.'}
        root_device = snapshot['identities']['.'][0]
        for name, row in snapshot['identities'].items():
            assert type(row) is list and len(row) == 8
            assert all(type(item) is int and item >= 0 for item in row)
            assert row[0] == root_device
            if name in state['files']:
                file = state['files'][name]
                assert stat.S_ISREG(row[2]) and row[3] == 1
                assert row[1] == file['inode'] and row[4:] == [file['uid'], file['bytes'], file['mtime_ns'], file['ctime_ns']]
                assert stat.S_IMODE(row[2]) == file['mode']
            else:
                assert stat.S_ISDIR(row[2])
        rg = snapshot['rg']
        assert set(rg) == {'command', 'status', 'stdout', 'stderr'}
        assert type(rg['status']) is int and rg['status'] == 0
        assert rg['command'] == ['rg', '--files', '--hidden', '--no-ignore', '--', relative]
        assert c.prepare.unblob(rg['stderr']) == b''
        assert sorted(c.prepare.unblob(rg['stdout']).decode().splitlines()) == sorted(relative + '/' + name for name in state['files'])
        outcome_path = c.BASE / ('removed-' + label + '.json.gz')
        outcome = json.loads(gzip.decompress(c.execute.read(outcome_path)))
        assert set(outcome) == {'before', 'outcome'}
        assert c.exact(outcome['before']['state'], c.authority(label))
        assert c.exact(outcome['outcome'], value['outcomes'][relative])
    assert len(value['census_before']['rust']) == 6
    assert c.replay(value)
    return True


def changed(value, path, transform):
    if not path:
        return transform(value)
    result = value.copy()
    key, *tail = path
    result[key] = changed(value[key], tail, transform)
    return result


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--write', action='store_true')
    args = parser.parse_args()
    value = json.loads(gzip.decompress(c.execute.read(c.RESULT)))
    assert validate(value)
    first = c.TARGETS[0]
    source = next(name for name, node in value['before'][first]['state']['files'].items() if node['bytes'])

    def flip(node):
        raw = c.prepare.unblob(node)
        altered = (b'x' if raw[:1] != b'x' else b'y') + raw[1:]
        return dict(node, **c.prepare.blob(altered))

    mutations = [('native_kind', ('post_saved_reader', 'status'), lambda _: False),
                 ('removal_kind', ('outcomes', first, 'removed'), lambda _: 1),
                 ('source_bytes', ('before', first, 'state', 'files', source), flip),
                 ('mode', ('before', first, 'state', 'files', source, 'mode'), lambda _: 0o777),
                 ('missing_target', ('outcomes',), lambda rows: {key: item for key, item in rows.items() if key != first}),
                 ('non_due', ('utc',), lambda _: value['prior_utc']),
                 ('residue', ('residue',), lambda _: []),
                 ('protection', ('protected_after',), lambda _: {})]
    outcomes = []
    for label, path, transform in mutations:
        candidate = changed(value, path, transform)
        try:
            validate(candidate)
        except (AssertionError, KeyError):
            outcomes.append(label)
        else:
            raise AssertionError('invalid saved cleanup admitted: ' + label)
    if args.write:
        c.execute.save(c.BASE / 'qualification.json.gz', dict(
            input=c.prepare.identity(c.execute.read(c.RESULT)), programme=c.prepare.blob(c.execute.read(c.BASE / 'verify.py')),
            controls=outcomes, scope='Complete immutable authority, independent actual membership, typed dated deletion/residue/protection '
            'and actual post-disposal saved-reader evidence. Source/record snapshots are retained; no deletion repeats, '
            'physical disk reclamation measurement or future absence guarantee is inferred.'))
    else:
        saved = json.loads(gzip.decompress(c.execute.read(c.BASE / 'qualification.json.gz')))
        assert saved['input'] == c.prepare.identity(c.execute.read(c.RESULT))
        assert c.prepare.unblob(saved['programme']) == c.execute.read(c.BASE / 'verify.py')
        assert saved['controls'] == outcomes
    print('Complete typed cleanup authority, actual removal/residue/protection and genuine saved-record controls pass; no deletion repeats.')
