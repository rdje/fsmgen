#!/usr/bin/env python3
"""Review retained failed-job summaries; never run a producer or contact GitHub."""
import argparse
import copy
import hashlib
import json
from pathlib import Path
import re
import subprocess

ROOT = Path(__file__).resolve().parents[3]
HERE = Path(__file__).resolve().parent
RAW = ROOT / '.artifacts/tmp/hosted-ci-20260923'
RUN = 35782532228
TREE = 'HOSTED-VIAL-REGRESSION-GATE-RESULT'
OWNERS = {
    350: [4, 5], 1676: [17], 1677: [18], 1679: [19], 1756: [23],
    1765: [6], 1766: [6], 1767: [9], 1768: [2], 1769: [2],
    1770: [25], 1771: [10], 1772: [11], 1773: [2], 1775: [15],
    1776: [7], 1777: [8], 1782: [12], 1783: [13], 1784: [14],
    1792: [16], 1796: [24], 1799: [22], 1800: [22],
}
OWNERS.update({n: [20] for n in range(1740, 1748)})
OWNERS.update({n: [21] for n in (1515, 1516, 1523, 1524, 1525, 1526,
                                1534, 1537, 1538, 1539, 1540)})
ROW = re.compile(r'\b(t/(\d+)-[a-z0-9-]+\.t)\s+\(Wstat: (\d+) Tests: (\d+) Failed: (\d+)\)')


def digest(data):
    return hashlib.sha256(data).hexdigest()


def read(path, limit=262144):
    assert path.is_file() and not path.is_symlink(), str(path)
    assert path.stat().st_dev == ROOT.stat().st_dev, 'off-volume input'
    assert path.stat().st_size <= limit, 'oversized input'
    return path.read_bytes()


def summary(text):
    assert text.count('Test Summary Report') == 1
    start = text.index('Test Summary Report')
    finish = text.index('Result: FAIL', start) + len('Result: FAIL')
    return text[start:finish]


def record(path, excerpt):
    data = read(path)
    return {'path': str(path.relative_to(ROOT)), 'bytes': len(data),
            'sha256': digest(data), 'excerpt': excerpt(data.decode()),
            'job_name': path.stem.replace('_', ' ')}


def gate_excerpt(text):
    return '\n'.join(line for line in text.splitlines()
                     if 'calibration closure publication root is absent' in line
                     or 'validate_complete_publication' in line
                     or 'ArchitectureScaleRegressionPromotionPolicy.pm line 236' in line)


def derive_failures():
    evidence = {}
    for number, index in ((1768, 7), (1769, 8), (1773, 13)):
        text = read(RAW / f'Perl_files_{index}_16.log').decode()
        lines = text.splitlines()
        start = next(n for n, line in enumerate(lines)
                     if 'calibration closure publication root is absent' in line)
        finish = next(n for n in range(start, len(lines))
                      if f'called at t/{number}-' in lines[n])
        evidence[str(number)] = '\n'.join(lines[start:finish + 1])
    return evidence


def capture():
    jobs = dict(line.split('\t', 1)[::-1]
                for line in read(RAW / 'failed-jobs.tsv').decode().splitlines())
    shards = []
    for index in range(16):
        item = record(RAW / f'Perl_files_{index}_16.log', summary)
        item.update(index=index, job_name=f'Perl files {index}/16',
                    job_id=jobs[f'Perl files {index}/16'])
        shards.append(item)
    gate = record(RAW / 'VIAL_regression-promotion_gate.log', gate_excerpt)
    gate.update(job_name='VIAL regression-promotion gate', job_id=jobs['VIAL regression-promotion gate'])
    build = record(RAW / 'build.log', lambda text: text)
    build.update(job_name='build', job_id=jobs['build'])
    data = {'schema': 'fsmgen.hosted_failure_census.v1', 'run_id': RUN,
            'baseline_revision': subprocess.check_output(['git', 'rev-parse', 'HEAD'], cwd=ROOT, text=True).strip(),
            'released_jobs': jobs, 'shards': shards, 'gate': gate, 'build': build,
            'policy_derive_failures': derive_failures(),
            'scope': 'Dated released-log projections, not repaired hosted qualification. Raw log bytes remain ignored and their durable availability is not claimed.'}
    verify(data, raw=True)
    with (HERE / 'census.json').open('x') as handle:
        handle.write(json.dumps(data, indent=2, sort_keys=True) + '\n')
    return data


def verify(data, raw=False):
    assert set(data) == {'schema', 'run_id', 'baseline_revision', 'released_jobs',
                         'shards', 'gate', 'build', 'policy_derive_failures', 'scope'}
    assert data['schema'] == 'fsmgen.hosted_failure_census.v1' and data['run_id'] == RUN
    assert re.fullmatch('[0-9a-f]{40}', data['baseline_revision'])
    jobs = data['released_jobs']
    assert set(jobs) == {f'Perl files {n}/16' for n in range(16)} | {'build', 'VIAL regression-promotion gate'}
    assert len(set(jobs.values())) == len(jobs)
    assert all(re.fullmatch(r'[1-9][0-9]+', value) for value in jobs.values())
    assert data['gate']['path'] == '.artifacts/tmp/hosted-ci-20260923/VIAL_regression-promotion_gate.log'
    assert data['gate']['job_name'] == 'VIAL regression-promotion gate'
    assert data['build']['path'] == '.artifacts/tmp/hosted-ci-20260923/build.log'
    assert data['build']['job_name'] == 'build'
    assert [item['index'] for item in data['shards']] == list(range(16))
    found = {}
    for index, item in enumerate(data['shards']):
        assert item['job_name'] == f'Perl files {index}/16'
        assert item['path'] == f'.artifacts/tmp/hosted-ci-20260923/Perl_files_{index}_16.log'
        text = item['excerpt']
        assert summary(text) == text
        rows = ROW.findall(text)
        assert rows and len(rows) == text.count('(Wstat:'), 'unparsed summary row'
        for path, number, wait, tests, failed in rows:
            number = int(number)
            assert number in OWNERS and number not in found, 'unowned or repeated failed test'
            assert (ROOT / path).is_file(), 'substituted test filename'
            assert int(wait) != 0 or int(failed) != 0, 'successful row in failed census'
            found[number] = {'path': path, 'owners': [f'{TREE}.{n}' for n in OWNERS[number]]}
        if raw:
            assert summary(read(ROOT / item['path']).decode()) == text
    assert set(found) == set(OWNERS), 'missing failed test'
    for item in [*data['shards'], data['gate'], data['build']]:
        fields = {'path', 'bytes', 'sha256', 'excerpt', 'job_name', 'job_id'}
        assert set(item) == (fields | {'index'} if item in data['shards'] else fields)
        assert item['job_id'] == jobs[item['job_name']]
        assert re.fullmatch('[0-9a-f]{64}', item['sha256'])
        assert isinstance(item['bytes'], int) and 0 < item['bytes'] <= 262144
        if raw:
            original = read(ROOT / item['path'])
            assert len(original) == item['bytes'] and digest(original) == item['sha256']
    assert 'calibration closure publication root is absent' in data['gate']['excerpt']
    assert 'ArchitectureScaleRegressionPromotionPolicy.pm line 236' in data['gate']['excerpt']
    assert 'failure' in data['build']['excerpt']
    assert set(data['policy_derive_failures']) == {'1768', '1769', '1773'}
    for number, excerpt in data['policy_derive_failures'].items():
        assert 'calibration closure publication root is absent' in excerpt
        assert 'ArchitectureScaleRegressionPromotionPolicy::derive' in excerpt
        assert f'called at t/{number}-' in excerpt
    if raw:
        assert data['policy_derive_failures'] == derive_failures()
        assert data['gate']['excerpt'] == gate_excerpt(read(ROOT / data['gate']['path']).decode())
        assert data['build']['excerpt'] == read(ROOT / data['build']['path']).decode()
        assert jobs == dict(line.split('\t', 1)[::-1]
                            for line in read(RAW / 'failed-jobs.tsv').decode().splitlines())
    task = read(ROOT / f'docs/tasks/{TREE}.md').decode()
    for row in found.values():
        for owner in row['owners']:
            assert f'- ID: `{owner}`' in task, owner
    policy = read(ROOT / 'perl/FSM/VIAL/ArchitectureScaleRegressionPromotionPolicy.pm').decode()
    derive = re.search(r'^sub derive\(.*?(?=^sub )', policy, re.M | re.S).group()
    assert '_load_sealed_policy' in derive and 'validate_complete_publication' not in derive
    return {'released_perl_jobs': len(data['shards']), 'failed_test_files': len(found),
            'unowned_failed_tests': 0, 'gate_owner': f'{TREE}.2',
            'hosted_requalification_owner': f'{TREE}.27', 'hosted_pass': False}


def qualify(data):
    mutations = [
        lambda x: x['shards'].pop(),
        lambda x: x['shards'].reverse(),
        lambda x: x['shards'][0].update(job_id='1'),
        lambda x: x.update(run_id=RUN + 1),
        lambda x: x['shards'][0].update(excerpt=x['shards'][0]['excerpt'].replace('t/1526-', 't/9999-')),
        lambda x: x['shards'][0].update(excerpt=x['shards'][0]['excerpt'].replace('t/1526-', 't/1526-substituted-')),
        lambda x: x.update(hosted_pass=True),
        lambda x: x['gate'].update(excerpt='success'),
        lambda x: x['policy_derive_failures'].pop('1768'),
        lambda x: x['policy_derive_failures'].update({'1769': 'unrelated failure'}),
    ]
    for mutate in mutations:
        changed = copy.deepcopy(data)
        verify(changed)
        mutate(changed)
        try:
            verify(changed)
        except AssertionError:
            continue
        raise AssertionError('altered census was accepted')
    print('hosted-census: independent altered-census controls reject')


if __name__ == '__main__':
    if not __debug__:
        raise RuntimeError('assertion checking must remain enabled')
    parser = argparse.ArgumentParser(description=__doc__)
    mode = parser.add_mutually_exclusive_group(required=True)
    for operation in ('capture', 'verify-saved', 'verify-raw', 'qualify'):
        mode.add_argument('--' + operation, action='store_true')
    args = parser.parse_args()
    data = capture() if args.capture else json.loads(read(HERE / 'census.json'))
    result = verify(data, raw=args.verify_raw)
    if args.qualify:
        qualify(data)
    print(json.dumps(result, sort_keys=True))
