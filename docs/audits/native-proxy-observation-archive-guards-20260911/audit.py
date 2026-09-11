"""Derive pure guard outcomes, call prefixes and source-bound reachability."""
from __future__ import annotations

import copy
import hashlib
import json
from pathlib import Path
import re
import subprocess

BASE = Path(__file__).resolve().parent
ROOT = BASE.parents[2]
LOG = ROOT / '.artifacts/logs/native-proxy-observation-archive-guards-20260911'
ORIGINAL = 'docs/audits/native-proxy-observation-archive-20260911'
REVISION = '94e66c8c68017e49ea7bf59017fe67d4a53e5c2c'
ROLES = ['wrapper', 'private_reference', 'global_reference', 'c', 'image']


def domain(plan):
    assert plan['schema'] == 'fsmgen.inactive_archive_guards_plan.v1'
    assert plan['source_revision'] == REVISION
    assert plan['limits'] == dict(files=64, file_bytes=65536, aggregate_bytes=4194304)
    cases = []
    def raw(size, pattern='x'): return dict(kind='raw', size=size, pattern=pattern)
    def add(name, values, error=''):
        cases.append(dict(name=name, values=values, returned=not bool(error), error=error))
    count_error = 'archive unique-file capacity exceeded\n'; invalid_error = 'expected bounded bytes\n'
    add('empty structural list', [])
    add('one empty payload', [raw(0)])
    add('one binary payload', [raw(256, 'binary')])
    for count in range(63, 66):
        add(f'count {count} empty payloads', [raw(0)] * count, count_error if count == 65 else '')
    add('aggregate one below ceiling', [raw(65536)] * 63 + [raw(65535)])
    add('aggregate exact ceiling', [raw(65536)] * 64)
    add('aggregate excess via count', [raw(65536)] * 65, count_error)
    add('aggregate excess via payload', [raw(65536)] * 63 + [raw(65537)], invalid_error)
    add('count precedes invalid byte form', [dict(kind='undefined')] * 65, count_error)
    for kind in ['undefined', 'reference', 'utf8', 'oversized']:
        for index in [0, 31, 63]:
            values = [raw(0) for _ in range(64)]
            values[index] = raw(65537) if kind == 'oversized' else dict(kind=kind)
            add(f'{kind} payload at {index}', values, invalid_error)
    assert plan['cases'] == cases and len({case['name'] for case in cases}) == len(cases)


def signature(recipe):
    kind = recipe['kind']; raw = None
    if kind == 'raw':
        raw = bytes(range(256)) if recipe['pattern'] == 'binary' else b'x' * recipe['size']
        assert len(raw) == recipe['size']
    elif kind == 'utf8': raw = b'u' * 12
    else: assert kind in ('undefined', 'reference')
    return dict(defined=int(kind != 'undefined'), reference='ARRAY' if kind == 'reference' else '',
        utf8=int(kind == 'utf8'), size_bytes=len(raw) if raw is not None else None,
        sha256=hashlib.sha256(raw).hexdigest() if raw is not None else None,
        reference_value='[1]' if kind == 'reference' else None)


def expected(recipe, limits):
    values = [signature(value) for value in recipe['values']]
    calls = []; error = ''
    if len(values) > limits['files']:
        error = 'archive unique-file capacity exceeded\n'
    else:
        total = 0
        for index, value in enumerate(values):
            accepted = value['defined'] and not value['reference'] and not value['utf8'] and value['size_bytes'] <= limits['file_bytes']
            error = '' if accepted else 'expected bounded bytes\n'
            calls.append(dict(index=index, limit=limits['file_bytes'], input=value, returned=int(bool(accepted)), error=error))
            if not accepted: break
            total += value['size_bytes']
            # This implication, not an invented branch hit, is the claim.
            assert total <= (index + 1) * limits['file_bytes'] <= limits['aggregate_bytes']
    assert recipe['returned'] == (not bool(error)) and recipe['error'] == error
    return dict(name=recipe['name'], before=values, after=values, calls=calls, returned=int(not bool(error)), error=error)


def verify(plan, report):
    assert report['schema'] == 'fsmgen.inactive_archive_guards_qualification.v1'
    assert report['success'] is True and report['forbidden_process_attempts'] == report['forbidden_lookup_attempts'] == 0
    rows = [expected(case, plan['limits']) for case in plan['cases']]
    assert report['cases'] == rows
    for row in report['cases']:
        assert type(row['returned']) is int
        for value in row['before'] + row['after']:
            assert type(value['defined']) is type(value['utf8']) is int
        for call in row['calls']:
            assert type(call['index']) is type(call['limit']) is type(call['returned']) is int
    calls = [call for row in rows for call in row['calls']]
    return dict(cases=len(rows), admitted=sum(row['returned'] for row in rows), rejected=sum(not row['returned'] for row in rows),
        validator_calls=len(calls), accepted_validator_calls=sum(call['returned'] for call in calls),
        validator_rejections=sum(not call['returned'] for call in calls),
        validated_byte_instances=sum(call['input']['size_bytes'] for call in calls if call['returned']),
        count_rejections=sum(row['error'] == 'archive unique-file capacity exceeded\n' for row in rows),
        aggregate_excess_branch_hits=sum(row['error'] == 'archive aggregate-byte capacity exceeded\n' for row in rows))


def relationship(count, file_bytes, total, roles, equal_references):
    assert type(count) is type(file_bytes) is type(total) is int and min(count, file_bytes, total) > 0
    assert count * file_bytes <= total, 'earlier guards no longer imply the aggregate bound'
    assert roles == ROLES and equal_references is True
    before_dedup = 3 * file_bytes + 2 * 4096
    unique_bytes = 3 * file_bytes + 4096
    assert 4 <= count and unique_bytes <= total
    return dict(helper_count_limit=count, helper_file_byte_limit=file_bytes, helper_total_byte_limit=total,
        helper_implied_aggregate_max=count * file_bytes, aggregate_excess_reachable_after_earlier_guards=False,
        public_ordered_sources=len(roles), public_unique_file_upper_bound=4,
        public_before_dedup_byte_upper_bound=before_dedup, public_unique_byte_upper_bound=unique_bytes,
        public_count_excess_reachable=False, public_aggregate_excess_reachable=False,
        domain='Ordinary finite raw values; public bounds apply only after the unchanged acquisition and archive specification validators. These are conservative upper bounds, not claims of an achievable maximum payload.')


def source_relationship():
    archive = (ROOT / ORIGINAL / 'ObservationArchive.pm').read_text()
    custody = (ROOT / 'docs/audits/native-proxy-image-custody-20260910/ImageCustody.pm').read_text()
    record = (ROOT / 'docs/audits/native-proxy-observation-archive-records-20260911/ArchiveRecord.pm').read_text()
    acquired = (ROOT / 'docs/audits/native-proxy-observation-acquisition-20260910/ObservationAcquisition.pm').read_text()
    count = int(re.findall(r'^my \$FILE_LIMIT = ([0-9]+);$', archive, re.M)[0])
    factors = re.findall(r'^my \$TOTAL_LIMIT = ([0-9]+) \* ([0-9]+) \* ([0-9]+);$', archive, re.M)
    assert len(factors) == 1
    total = 1
    for factor in factors[0]: total *= int(factor)
    body = re.findall(r'^sub _limits \{\n(.*?)^\}', archive, re.S | re.M); assert len(body) == 1
    statements = ['if @{$spec->{files}} > $FILE_LIMIT', 'for my $file',
                  'NativeProxyImageCustody::_bytes($file->{bytes}, 65_536)',
                  '$total += length($file->{bytes})', 'if $total > $TOTAL_LIMIT']
    positions = [body[0].index(statement) for statement in statements]; assert positions == sorted(positions)
    assert 'unless defined($value) && !ref($value) && !utf8::is_utf8($value)' in custody
    assert '&& length($value) <= $limit' in custody
    roles = re.findall(r'^my @ROLES = qw\(([^)]+)\);$', record, re.M); assert len(roles) == 1
    assert "ref($sources) eq 'ARRAY' && @$sources == 5" in acquired
    assert '($_ == 1 || $_ == 2) ? 4096 : 65_536' in acquired and 'for 0..4;' in acquired
    assert 'unless $sources->[1]{bytes} eq $sources->[2]{bytes};' in acquired
    assert 'for my $index (0..$#ROLES)' in record and 'if (exists($seen{$path}))' in record
    assert '$files[$seen{$path}]{bytes} eq $snapshot->{bytes}' in record
    return relationship(count, 65536, total, roles[0].split(), True)


def reject(name, callback, rejected):
    try: callback()
    except (AssertionError, KeyError, IndexError): rejected.append(name)
    else: raise AssertionError('guard oracle accepted falsifier: ' + name)


def main():
    plan = json.loads((BASE / 'plan.json').read_bytes()); domain(plan)
    previous = json.loads((ROOT / ORIGINAL / 'plan.json').read_bytes())
    paths = {pin['path'] for pin in previous['inputs']} | {ORIGINAL + '/plan.json', ORIGINAL + '/ObservationArchive.pm'}
    assert [pin['path'] for pin in plan['inputs']] == sorted(paths)
    for pin in plan['inputs']:
        raw = (ROOT / pin['path']).read_bytes()
        assert len(raw) == pin['size_bytes'] and hashlib.sha256(raw).hexdigest() == pin['sha256']
        assert raw == subprocess.check_output(['git', 'show', REVISION + ':' + pin['path']], cwd=ROOT)
    pins = json.loads((BASE / 'preflight-pins.json').read_bytes())
    assert [pin['path'] for pin in pins] == [str((BASE / name).relative_to(ROOT)) for name in ['plan.py', 'plan.json', 'qualify.t', 'audit.py']]
    for pin in pins:
        raw = (ROOT / pin['path']).read_bytes()
        assert len(raw) == pin['size_bytes'] and hashlib.sha256(raw).hexdigest() == pin['sha256']
    proof = source_relationship()
    report = json.loads((LOG / 'qualification.json').read_bytes()); counts = verify(plan, report)
    tap = (LOG / 'qualify.tap').read_text(); assertions = len(plan['cases']) * 3 + 2
    assert re.findall(r'^1\.\.([0-9]+)$', tap, re.M) == [str(assertions)]
    assert re.findall(r'^ok ([0-9]+) - ', tap, re.M) == [str(index) for index in range(1, assertions + 1)]
    assert not re.search(r'^(?:not ok|Bail out!)|#\s*(?:SKIP|TODO)\b', tap, re.M | re.I)
    assert (LOG / 'qualify.exit').read_text().strip() == '0'
    def admitted(value): return next(row for row in value['cases'] if row['name'] == 'aggregate exact ceiling')
    def invalid(value): return next(row for row in value['cases'] if row['name'] == 'utf8 payload at 31')
    changes = [
        ('missing case', lambda value: value['cases'].pop()),
        ('duplicate case', lambda value: value['cases'].append(copy.deepcopy(value['cases'][0]))),
        ('changed case order', lambda value: value['cases'].reverse()),
        ('rejected exact ceiling', lambda value: admitted(value).update(returned=0)),
        ('accepted invalid bytes', lambda value: invalid(value).update(returned=1)),
        ('wrong first error', lambda value: invalid(value).update(error='archive aggregate-byte capacity exceeded\n')),
        ('missing validator call', lambda value: admitted(value)['calls'].pop()),
        ('extra validator call', lambda value: admitted(value)['calls'].append(copy.deepcopy(admitted(value)['calls'][0]))),
        ('wrong validator index', lambda value: admitted(value)['calls'][0].update(index=1)),
        ('changed validator limit', lambda value: admitted(value)['calls'][0].update(limit=65537)),
        ('wrong validator return', lambda value: admitted(value)['calls'][0].update(returned=0)),
        ('wrong validator error', lambda value: invalid(value)['calls'][-1].update(error='other error\n')),
        ('changed input digest', lambda value: admitted(value)['before'][0].update(sha256='0' * 64)),
        ('changed output size', lambda value: admitted(value)['after'][0].update(size_bytes=0)),
        ('lost UTF8 flag', lambda value: invalid(value)['before'][31].update(utf8=0)),
        ('lost reference type', lambda value: next(row for row in value['cases'] if row['name']=='reference payload at 0')['before'][0].update(reference='')),
        ('wrong validated bytes', lambda value: admitted(value)['calls'][0]['input'].update(size_bytes=65535)),
        ('filesystem helper attempt', lambda value: value.update(forbidden_lookup_attempts=1)),
        ('process attempt', lambda value: value.update(forbidden_process_attempts=1)),
    ]
    rejected = []
    for name, change in changes:
        altered = copy.deepcopy(report); change(altered); reject(name, lambda: verify(plan, altered), rejected)
    domain_falsifiers = []
    for name in ['missing case', 'duplicate case', 'changed count', 'lost late invalid value', 'changed binary recipe']:
        changed = copy.deepcopy(plan)
        if name == 'missing case': changed['cases'].pop()
        elif name == 'duplicate case': changed['cases'].append(copy.deepcopy(changed['cases'][0]))
        elif name == 'changed count': changed['cases'][5]['values'].pop()
        elif name == 'lost late invalid value': changed['cases'][-1]['values'][-1] = dict(kind='raw',size=0,pattern='x')
        else: changed['cases'][2]['values'][0]['pattern'] = 'x'
        reject(name, lambda: domain(changed), domain_falsifiers)
    relationship_falsifiers = []
    for name, arguments in [('larger count cap', (65,65536,4194304,ROLES,True)),
                            ('larger byte cap', (64,65537,4194304,ROLES,True)),
                            ('smaller aggregate cap', (64,65536,4194303,ROLES,True)),
                            ('extra public source', (64,65536,4194304,ROLES+['other'],True)),
                            ('unequal reference bytes', (64,65536,4194304,ROLES,False))]:
        reject(name, lambda: relationship(*arguments), relationship_falsifiers)
    output = dict(schema='fsmgen.inactive_archive_guards_audit.v1', success=True, **counts,
        tap_assertions=assertions, reachability=proof, report_falsifiers=rejected,
        domain_falsifiers=domain_falsifiers, relationship_falsifiers=relationship_falsifiers,
        predecessor_inputs_unchanged=len(plan['inputs']), predecessor_perl_modules=sum(pin['path'].endswith('.pm') for pin in plan['inputs']),
        prospective_inputs_unchanged=len(pins), limits=plan['nonclaims'])
    (LOG / 'audit.json').write_text(json.dumps(output, indent=2, sort_keys=True)+'\n')
    print(json.dumps(output,sort_keys=True))


if __name__ == '__main__':
    main()
