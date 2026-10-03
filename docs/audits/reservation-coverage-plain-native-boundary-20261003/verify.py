"""Cold, typed graph/source reader for the finite prospective helper boundary."""
import argparse
import copy
import hashlib
import json
import re
import subprocess
from pathlib import Path

BASE = Path('docs/audits/reservation-coverage-plain-native-boundary-20261003')
CAPTURE = Path('docs/audits/reservation-coverage-snapshot-capture-20261003')
parser = argparse.ArgumentParser()
for name in ('storable', 'alias', 'cycle', 'native'):
    parser.add_argument('--trust-' + name, action='store_true')
options = parser.parse_args()


def same(a, b):
    if type(a) is not type(b): return False
    if isinstance(a, dict): return a.keys() == b.keys() and all(same(a[k], b[k]) for k in a)
    if isinstance(a, list): return len(a) == len(b) and all(same(x, y) for x, y in zip(a, b))
    return a == b


def graph_census(node):
    # Traverse descriptors independently of the Perl native-address census.
    seen, pending = {}, [('', node)]
    while pending:
        path, value = pending.pop()
        if not isinstance(value, list):
            assert value is None or type(value) in (int, str), ('undeclared primitive', path)
            continue
        assert len(value) == 2, ('malformed plain descriptor', path)
        kind, fields = value
        if kind == 'reference':
            assert type(fields) is str and fields in seen, ('unbound backedge', path, fields)
            continue
        assert kind in ('hash', 'array') and path not in seen
        seen[path] = kind
        if kind == 'hash':
            assert type(fields) is dict
            children = [(path + '/' + k.replace('~', '~0').replace('/', '~1'), fields[k]) for k in sorted(fields)]
        else:
            assert type(fields) is list
            children = [(path + '/' + str(i), v) for i, v in enumerate(fields)]
        pending.extend(reversed(children))
    return len(seen)


if (BASE / 'manifest.json').exists():
    manifest = json.loads((BASE / 'manifest.json').read_text())
    assert {p.name for p in BASE.iterdir()} == set(manifest) | {'manifest.json'}
    for name, row in manifest.items():
        raw = (BASE / name).read_bytes()
        assert len(raw) == row['bytes'] and hashlib.sha256(raw).hexdigest() == row['sha256'], name
subprocess.run(['python3', '-B', 'docs/audits/reservation-coverage-value-only-controls-20261003/verify.py'], check=True)
binding = json.loads((BASE / 'bindings.json').read_text())
raw = subprocess.check_output(['git', 'show', binding['revision'] + ':' + binding['source_path']])
assert binding['source_path'] == 't/1959-isf-prepared-formal-reservations.t'
assert raw.decode() == binding['source_body'] and len(raw) == binding['source_bytes']
assert hashlib.sha256(raw).hexdigest() == binding['source_sha256']
source = raw.decode()
helper = source[source.index('sub source_value_copy {'):source.index('\nmy $lowerer =')]
assert helper == binding['helper_original'] and helper.count('PreparedCauseSentinel') == 1
assert (BASE / 'helper-body.pl').read_text() == helper.replace('PreparedCauseSentinel', 'CoverageCauseSentinel')
for contract in (
    'return $value unless ref($value);',
    "die 'unexpected source reference' if blessed($value)",
    'return $copies->{$address} if exists $copies->{$address};',
    '$copies->{$address} = $copy;',
    "return ['reference', $seen->{$address}] if exists $seen->{$address};",
    "&& reftype($value) eq 'HASH' && !keys %$value;",
    "return ['empty_native_hash', ref($value), $address];",
    "die 'unexpected snapshot reference';",
):
    assert contract in helper, ('missing source contract', contract)
observation = json.loads((BASE / 'observations.json').read_text())
original = json.loads((CAPTURE / 'ordinary.json').read_text())
assert set(observation) == {'copies', 'plain', 'isolation_before', 'isolation_after', 'isolation_copy_after',
    'alias_break', 'cycle_break', 'native_before', 'native_stable', 'native_replacement',
    'native_original_identity', 'native_replacement_identity', 'refusals'}
assert len(observation['copies']) == len(original['copies']) == 62
for ordinal, (row, prior) in enumerate(zip(observation['copies'], original['copies'])):
    assert set(row) == {'ordinal', 'before', 'after', 'copy', 'source_references', 'copy_references', 'overlap'}
    assert row['ordinal'] == ordinal and same(row['before'], prior['before']), ('source reconstruction drift', ordinal)
    assert same(row['after'], row['before']) and same(row['copy'], row['before']), ('candidate graph/kind drift', ordinal)
    assert row['overlap'] == 0 and type(row['overlap']) is int
    assert row['source_references'] == row['copy_references'] == graph_census(row['before']) > 0
    graph_census(row['copy'])
plain = ['hash', {'left': ['hash', {'kind/~': ['array', [1, '1', 0, '0', None]]}],
    'loop': ['reference', ''], 'right': ['reference', '/left']}]
assert [r['name'] for r in observation['plain']] == ['candidate', 'storable']
for row in observation['plain']:
    assert same(row['before'], plain) and same(row['copy'], plain)
    assert row['alias_retained'] == row['cycle_retained'] == 1
    assert row['source_references'] == row['copy_references'] == graph_census(plain) == 3 and row['overlap'] == 0
assert same(observation['isolation_before'], plain) and same(observation['isolation_after'], plain)
mutated = copy.deepcopy(plain); mutated[1]['left'][1]['kind/~'][1][0] = 9
assert same(observation['isolation_copy_after'], mutated), 'declared copy mutation did not occur'
alias = copy.deepcopy(plain); alias[1]['right'] = copy.deepcopy(plain[1]['left'])
cycle = copy.deepcopy(plain); cycle[1]['loop'] = ['hash', {}]
assert same(observation['alias_break'], alias) and same(observation['cycle_break'], cycle)
assert graph_census(alias) == 5 and graph_census(cycle) == 4
assert not same(alias, plain) and not same(cycle, plain)
identity, replacement = observation['native_original_identity'], observation['native_replacement_identity']
assert type(identity) is type(replacement) is int and identity > 0 and replacement > 0 and identity != replacement
native = ['hash', {'left': ['empty_native_hash', 'CoverageCauseSentinel', identity], 'right': ['reference', '/left']}]
changed = ['hash', {'left': ['empty_native_hash', 'CoverageCauseSentinel', replacement],
    'right': ['empty_native_hash', 'CoverageCauseSentinel', identity]}]
assert same(observation['native_before'], native) and same(observation['native_stable'], native)
assert same(observation['native_replacement'], changed) and not same(changed, native)
refusals = [('nonempty marker', 'unexpected native snapshot reference'),
    ('wrong marker class', 'unexpected native snapshot reference'),
    ('scalar native snapshot', 'unexpected snapshot reference'),
    ('blessed source copy', 'unexpected source reference'), ('scalar source copy', 'unexpected source reference')]
assert len(observation['refusals']) == len(refusals)
for row, (name, cause) in zip(observation['refusals'], refusals):
    assert set(row) == {'name', 'accepted', 'error'} and row['name'] == name and same(row['accepted'], 0)
    assert re.fullmatch(re.escape(cause) + r' at \(eval [0-9]+\) line [0-9]+\.\n', row['error']), ('wrong complete helper cause', name)
assert (BASE / 'probe.status').read_text().strip() == '0'
assert 'PASS native candidate copy/snapshot probes completed' in (BASE / 'probe.txt').read_text()
# Each competing authority is an actual retained native observation, never a
# fabricated expected graph or a replacement for the original kind evidence.
if options.trust_storable:
    assert same(original['copies'][2]['copy'], original['copies'][2]['before']), 'actual Storable kind authority changes first-touch primitive kinds'
if options.trust_alias:
    assert same(observation['alias_break'], plain), 'actual alias-break authority changes first-touch sharing'
if options.trust_cycle:
    assert same(observation['cycle_break'], plain), 'actual cycle-break authority changes first-touch root backedge'
if options.trust_native:
    assert same(observation['native_replacement'], native), 'actual empty-native replacement authority changes original identity/sharing'
print('PASS exact Git-bound T1959 helper and single class adaptation; all62 reconstructed native plain graphs conserve kinds/sharing and independently counted deep-isolated references.')
print('PASS actual candidate/Storable alias-cycle fixture, actual copy mutation isolation, actual broken alias/root backedge and empty marker identity replacement; unsupported shape/class/referents refuse with complete helper causes.')
print('SCOPE: native reconstruction validates captured descriptors, not hidden original Perl scalar flags or arbitrary constructors. Storable topology does not establish its general kind authority. Actual coverage native replay/full snapshot and final joins precede P2 repair.')
if not any(vars(options).values()):
    for name, reason in (
        ('storable', 'actual Storable kind authority changes first-touch primitive kinds'),
        ('alias', 'actual alias-break authority changes first-touch sharing'),
        ('cycle', 'actual cycle-break authority changes first-touch root backedge'),
        ('native', 'actual empty-native replacement authority changes original identity/sharing'),
    ):
        assert (BASE / ('trust-' + name + '.status')).read_text().strip() == '1'
        assert (BASE / ('trust-' + name + '.txt')).read_text().splitlines()[-1] == 'AssertionError: ' + reason
