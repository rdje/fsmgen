"""Independent complete writer source/cause/control and conserved semantic join."""
import argparse
import difflib
import hashlib
import json
import re
import subprocess
from pathlib import Path

BASE = Path(__file__).parent
parser = argparse.ArgumentParser()
parser.add_argument('--omit-cause', action='store_true')
parser.add_argument('--trust-filename', action='store_true')
parser.add_argument('--trust-bypass', action='store_true')
parser.add_argument('--omit-product', action='store_true')
parser.add_argument('--trust-private-product', action='store_true')
args = parser.parse_args()
subprocess.run(['python3', '-B', 'docs/audits/interface-metadata-cause-repair-20261004/verify.py'], check=True)
if (BASE / 'manifest.json').exists():
    manifest = json.loads((BASE / 'manifest.json').read_text())
    assert {p.name for p in BASE.iterdir()} == set(manifest) | {'manifest.json'}
    for name, row in manifest.items():
        raw = (BASE / name).read_bytes()
        assert len(raw) == row['bytes'] and hashlib.sha256(raw).hexdigest() == row['sha256']
binding = json.loads((BASE / 'binding-before.json').read_text())
after = json.loads((BASE / 'sources-after.json').read_text())
for name, row in binding['sources'].items():
    raw = subprocess.check_output(['git', 'show', binding['revision'] + ':' + name])
    assert raw.decode() == row['body'] and len(raw) == row['bytes'] and hashlib.sha256(raw).hexdigest() == row['sha256']
    if name != 't/1983-isf-interface-port-metadata.t':
        assert after[name] == row['body']
assert len(binding['sources']) == 15
assert set(after) == set(binding['sources']) | {'t/2065-isf-record-writer-diagnostic-context.t'}
old_source = binding['sources']['t/1983-isf-interface-port-metadata.t']['body']
source = after['t/1983-isf-interface-port-metadata.t']
old_block = """    ok(!$ok, 'record output field writer remains deferred');
    like($@, qr/record output field writes are not yet admitted/,
        'existing authored-field refusal remains precise');"""
new_block = """    my $error = $@;
    ok(!$ok, 'record output field writer remains deferred');
    ok(diagnostic_cause_matches($error,
        "Invalid ISF record context: transaction 'main' set target record output field writes are not yet admitted; "
        . "target 'packet.flag' requires output-field writer qualification"),
        'existing authored-field refusal remains precise');"""
assert old_source.count(old_block) == 1 and source == old_source.replace(old_block, new_block)
assert source == (BASE / 'test-after.t').read_text()
permanent = after['t/2065-isf-record-writer-diagnostic-context.t']
assert permanent == (BASE / 'context-test-after.t').read_text()
expected = "Invalid ISF record context: transaction 'main' set target record output field writes are not yet admitted; target 'packet.flag' requires output-field writer qualification"
assert json.loads((BASE / 'expected-cause.json').read_text())['primary'] == expected
context_source = after['perl/FSM/Support/ISFRecordPortContexts.pm']
assert '"transaction \'$tx->{name}\'"' in context_source
assert '"$context target"' in context_source and '"$context $head"' in context_source
assert '"$context record output field writes are not yet admitted; "' in context_source
assert '"target \'$token\' requires output-field writer qualification"' in context_source
assert 'confess "Invalid ISF record context: $_[1]\\n" unless $_[0]' in context_source
assert 'confess "Error: no (actor ...) root found in \'$source_label\'\\n"' in after['perl/FSM/Adapter/ISF/Parser.pm']

def equal(a, b):
    if type(a) is not type(b):
        return False
    if isinstance(a, dict):
        return a.keys() == b.keys() and all(equal(a[k], b[k]) for k in a)
    if isinstance(a, list):
        return len(a) == len(b) and all(equal(x, y) for x, y in zip(a, b))
    return a == b

def primary(error):
    return error.splitlines()[:1]

def graph(value):
    if isinstance(value, dict):
        return ['hash', {k: graph(v) for k, v in value.items()}]
    if isinstance(value, list):
        return ['array', [graph(v) for v in value]]
    return value

# Exact whole source transformation defines the permissible current caller
# coordinate changes. Runtime-generated import directories remain actual data.
line_map = {}
matcher = difflib.SequenceMatcher(a=old_source.splitlines(), b=source.splitlines(), autojunk=False)
for block in matcher.get_matching_blocks():
    for offset in range(block.size):
        line_map[block.a + offset + 1] = block.b + offset + 1
old_start = old_source[:old_source.index(old_block)].count('\n') + 1
line_map[old_start + 1] = old_start + 2
line_map[old_start + 2] = old_start + 5

def caller(current, previous):
    assert len(current) == len(previous)
    expected_caller = list(previous)
    if current[1] == './t/1983-isf-interface-port-metadata.t':
        expected_caller[2] = line_map[previous[2]]
    elif 'interface-metadata-cause-repair-20261004/observe.pl' in previous[1]:
        # Observer frames are instrumentation, not a source consumer locator.
        assert current[1].endswith('interface-metadata-writer-cause-repair-20261004/observe.pl')
        expected_caller[1:3] = current[1:3]
    assert equal(current, expected_caller)

previous = json.loads(Path('docs/audits/interface-metadata-cause-repair-20261004/ordinary.json').read_text())
data = {m: json.loads((BASE / (m + '.json')).read_text()) for m in ('ordinary', 'bypass')}
ordinary = data['ordinary']
for mode, row in data.items():
    assert row['sources_before'] == row['sources_after'] == {k: after[k] for k in binding['sources']}
    assert len(row['api']) == (105 if mode == 'ordinary' else 129)
    assert len(row['copies']) == (144 if mode == 'ordinary' else 168)
    assert len(row['helpers']) == 44 and len(row['parses']) == 3
    assert len(row['consumers']) == 336 and len(row['cause_consumers']) == 47
    assert row['changed'] == (0 if mode == 'ordinary' else 1)
    assert int((BASE / (mode + '.status')).read_text()) == (0 if mode == 'ordinary' else 1)
for current, old in zip(ordinary['api'], previous['api']):
    caller(current['caller'], old['caller'])
    for k in ('kind', 'helper', 'before', 'after', 'result', 'accepted', 'warnings'):
        assert equal(current[k], old[k]), ('whole ordinary API', k)
    assert primary(current['error']) == primary(old['error'])
for current, old in zip(ordinary['copies'], previous['copies']):
    caller(current['caller'], old['caller'])
    for k in ('kind', 'api', 'before', 'after', 'copy', 'original_reference_count', 'copy_reference_count', 'shared_with_original'):
        assert equal(current[k], old[k]), ('whole ordinary copy', k)
for current, old in zip(ordinary['consumers'], previous['consumers']):
    caller(current['caller'], old['caller'])
    assert current['label'] == old['label'] and current['helper'] == old['helper'] and current['passed'] == old['passed'] == 1
    if current['label'] == 'existing authored-field refusal remains precise':
        assert old['kind'] == 'like' and current['kind'] == 'ok' and current['actual'] == 1
    elif current['kind'] == 'like':
        assert current['expected'] == old['expected'] and primary(current['actual']) == primary(old['actual'])
    else:
        assert current['kind'] == old['kind'] and equal(current['actual'], old['actual'])
        if 'expected' in current:
            assert equal(current['expected'], old['expected'])
for current, old in zip(ordinary['parses'], previous['parses']):
    caller(current['caller'], old['caller'])
    assert current['kind'] == old['kind'] and current['accepted'] == old['accepted']
    assert equal(current['result'], old['result']) and primary(current['error']) == primary(old['error'])
    assert equal(current['before'], current['after']) and current['documents_before'] == current['documents_after']
    assert {Path(k).name: v for k, v in current['documents_before'].items()} == {Path(k).name: v for k, v in old['documents_before'].items()}
assert equal(ordinary['cycles'], previous['cycles'])
selected = ordinary['cause_consumers'][:-1] if args.omit_cause else ordinary['cause_consumers']
assert len(selected) == 47, 'complete metadata helper/first-read and adjacent writer cause membership'
writer = [r for r in selected if r['expected'] == expected]
assert len(writer) == 1 and writer[0]['helper'] is None
assert writer[0]['error'] == ordinary['parses'][1]['error'] and writer[0]['matched'] == 1
assert primary(writer[0]['error']) == [expected]
for current, old in zip([r for r in selected if r['expected'] != expected], previous['cause_consumers']):
    caller(current['caller'], old['caller'])
    assert current['helper'] == old['helper'] and current['expected'] == old['expected'] and current['matched'] == old['matched'] == 1
    assert primary(current['error']) == primary(old['error'])

models = json.loads((BASE / 'source-models.json').read_text())
products = models['products'][:-1] if args.omit_product else models['products']
assert len(products) == 4, 'complete authored writer/internal value metadata product models'
assert equal(data['bypass']['parses'][1]['result'], graph(models['actor'])), 'whole authored counterfactual actor model'
metadata_authority = graph(models['actor']['interface_port_metadata'])
if args.trust_private_product:
    candidates = [r for r in data['bypass']['copies'] if r['parse'] == 1
        and data['bypass']['api'][r['api']]['kind'] == 'snapshot'
        and equal(data['bypass']['api'][r['api']]['result'], metadata_authority)
        and not equal(r['copy'], metadata_authority)]
    assert candidates, 'actual distinct private output-metadata clone control exists'
    metadata_authority = candidates[0]['copy']
assert equal(data['bypass']['parses'][1]['result'][1]['interface_port_metadata'], metadata_authority), 'private copy cannot replace complete numeric final metadata authority'
assert ordinary['parses'][1]['accepted'] == 0 and data['bypass']['parses'][1]['accepted'] == 1 and data['bypass']['parses'][1]['error'] == ''
def same_parse(current, old):
    a, b = dict(current), dict(old)
    if current['kind'] == 'file':
        for row in (current, old):
            assert equal(row['before'], row['after']) and row['documents_before'] == row['documents_after']
            path = row['before'][1][0]
            assert re.fullmatch(r'\$\{REPO_ROOT\}/\.artifacts/tmp/tests/[A-Za-z0-9_]+/imported\.isf', path)
            assert set(row['documents_before']) == {path, path.rsplit('/', 1)[0] + '/shared.fsm'}
        for target, row in ((a, current), (b, old)):
            for k in ('before', 'after'):
                target[k] = ['array', ['qualified exact imported.isf fixture']]
            for k in ('documents_before', 'documents_after'):
                target[k] = {Path(p).name: body for p, body in row[k].items()}
    assert equal(a, b), 'complete parser products/causes/documents with only authenticated generated fixture coordinates'
for i in (0, 2):
    same_parse(data['bypass']['parses'][i], ordinary['parses'][i])
for r in data['bypass']['api']:
    if r['parse'] == 1:
        assert r['accepted'] == 1 and r['warnings'] == [] and r['error'] == ''
        assert any(equal(r['result'], graph(p)) for p in products), 'complete numeric authored flag/port/value metadata'
        assert any(equal(r['before'], graph(p)) for p in models[r['kind'] + '_inputs']), 'whole independently declared private/source input spelling'
        assert equal(r['before'], r['after'])
for role in (None, 0, 2):
    old_rows = [r for r in ordinary['api'] if r['parse'] == role]
    new_rows = [r for r in data['bypass']['api'] if r['parse'] == role]
    assert len(old_rows) == len(new_rows)
    for current, old in zip(new_rows, old_rows):
        # Native stack referent addresses vary across real interpreter runs;
        # complete primary cause and actual incoming native errors bind below.
        a, b = dict(current), dict(old)
        a['error'], b['error'] = primary(current['error']), primary(old['error'])
        assert equal(a, b), 'complete control API products/source/caller and primary cause'
ordinary_writer = [r for r in ordinary['api'] if r['parse'] == 1]
bypass_writer = [r for r in data['bypass']['api'] if r['parse'] == 1]
assert len(ordinary_writer) == 34 and len(bypass_writer) == 58
assert equal(ordinary_writer, bypass_writer[:34]), 'all pre-guard native metadata roles conserve in order'
api_map = {}
for role in (None, 0, 1, 2):
    old_indices = [i for i, r in enumerate(ordinary['api']) if r['parse'] == role]
    new_indices = [i for i, r in enumerate(data['bypass']['api']) if r['parse'] == role]
    api_map.update(zip(old_indices, new_indices))
for role in (None, 0, 1, 2):
    old_copies = [r for r in ordinary['copies'] if r['parse'] == role]
    new_copies = [r for r in data['bypass']['copies'] if r['parse'] == role]
    assert len(new_copies) == len(old_copies) + (24 if role == 1 else 0)
    for old, current in zip(old_copies, new_copies):
        rebased = dict(old)
        rebased['api'] = api_map[old['api']] if old['api'] is not None else None
        assert equal(current, rebased), 'whole common control copy/caller/kind/isolation/parent-API roles'
for r in data['bypass']['copies']:
    assert r['original_reference_count'] == r['copy_reference_count'] and r['shared_with_original'] == 0
    assert equal(r['before'], r['after'])
def private_clone(before, copied, path=''):
    if equal(before, copied):
        return
    if isinstance(before, list) and isinstance(copied, list) and len(before) == len(copied) == 2 and before[0] == copied[0] == 'hash':
        assert before[1].keys() == copied[1].keys()
        for name in before[1]:
            private_clone(before[1][name], copied[1][name], path + '/' + name)
    elif isinstance(before, list) and isinstance(copied, list) and len(before) == len(copied) == 2 and before[0] == copied[0] == 'array':
        assert len(before[1]) == len(copied[1])
        for index, (a, b) in enumerate(zip(before[1], copied[1])):
            private_clone(a, b, path + '/' + str(index))
    else:
        assert path.endswith('/width') and type(before) is int and before == 1 and type(copied) is str and copied == '1', 'only independently authored unit-width private numeric spelling may change'
for r in [r for r in data['bypass']['copies'] if r['parse'] == 1][34:]:
    assert r['kind'] == 'provider' and r['api'] is not None
    api = data['bypass']['api'][r['api']]
    assert api['parse'] == 1 and equal(r['before'], api['before'][1][0])
    private_clone(r['before'], r['copy'])
assert equal(data['bypass']['cycles'], ordinary['cycles'])
for current, old in zip(data['bypass']['consumers'], ordinary['consumers']):
    assert current['kind'] == old['kind'] and current['label'] == old['label'] and current['caller'] == old['caller'] and current['helper'] == old['helper']
    if current['label'] not in ('record output field writer remains deferred', 'existing authored-field refusal remains precise'):
        assert current['passed'] == old['passed'] == 1
        if current['kind'] == 'like':
            assert current['expected'] == old['expected'] and primary(current['actual']) == primary(old['actual'])
        else:
            assert equal(current['actual'], old['actual'])
            if 'expected' in current:
                assert equal(current['expected'], old['expected'])
for current, old in zip(data['bypass']['cause_consumers'], ordinary['cause_consumers']):
    assert current['caller'] == old['caller'] and current['helper'] == old['helper'] and current['expected'] == old['expected']
    if current['expected'] == expected:
        assert current['error'] == '' and current['matched'] == 0
    else:
        assert primary(current['error']) == primary(old['error']) and current['matched'] == old['matched'] == 1
for row in data.values():
    helper_causes = [r for r in row['cause_consumers'] if r['helper'] is not None]
    assert [r['helper'] for r in helper_causes] == list(range(44))
    for helper, cause in zip(row['helpers'], helper_causes):
        api = row['api'][helper['api_start']]
        assert cause['error'] == api['error'] and api['accepted'] == 0 and cause['matched'] == 1
        assert cause['expected'] == 'Invalid ISF interface port metadata: ' + helper['reason']
    adjacent = [r for r in row['cause_consumers'] if r['helper'] is None]
    assert len(adjacent) == 3
    for cause in adjacent:
        if cause['expected'] == expected:
            assert cause['error'] == row['parses'][1]['error']
        else:
            assert any(cause['error'] == api['error'] for api in row['api'])
failures = [r for r in data['bypass']['consumers'] if not r['passed']]
assert [r['label'] for r in failures] == ['record output field writer remains deferred', 'existing authored-field refusal remains precise']
safe = bool(failures)
if args.trust_bypass:
    safe = all(r['passed'] for r in data['bypass']['consumers'])
assert safe, 'real writer guard bypass cannot qualify passing refusal/cause assurance'
context = json.loads((BASE / 'context-native.json').read_text())
assert context['probe_source_before'] == context['probe_source_after'] == permanent
assert context['prior_source'] == old_source and context['current_source'] == source and context['expected'] == expected
assert context['prior_consumer'] == old_block
assert context['current_consumer'] == new_block.split('\n', 1)[1]
assert int((BASE / 'context-native.status').read_text()) == 0
assert 'Files=1, Tests=28' in (BASE / 'context-native.txt').read_text() and 'All tests successful' in (BASE / 'context-native.txt').read_text()
assert [r['id'] for r in context['rows']] == ['real_output_writer', 'real_writer_wanted_filename', 'earlier_missing_actor', 'earlier_wanted_filename']
for r in context['rows']:
    real = r['id'].startswith('real_')
    assert r['accepted'] == 0 and r['warnings'] == [] and r['result'] is None
    assert r['current_bits'] == [1, int(real)]
    assert r['prior_bits'] == [1, int(real or r['id'] == 'earlier_wanted_filename')]
    assert r['causes'] == [[r['error'], expected]]
    assert r['before'] == r['after'] == [r['source'], r['filename']]
    submitted = context['source'] if real else context['source'].replace('(actor ', '(library ', 1)
    assert r['source'] == submitted
    assert primary(r['error']) == ([expected] if real else ["Error: no (actor ...) root found in '" + r['filename'] + "'"])
    if r['id'] == 'earlier_wanted_filename':
        accepted = r['prior_bits'][1] if args.trust_filename else r['current_bits'][1]
        assert not accepted, 'actual earlier primary filename echo cannot establish complete writer cause'
print('PASS complete exact prior/current writer cause, four real parser contexts and unchanged metadata helper/copy/source streams. Whole ordinary105 API/144 copy/336 consumers/47 causes conserve; real guard bypass129 API/168 copy/whole authored actor and four numeric metadata models fail both refusal/cause checks. Permanent native28-check filename proof rejects old false GREEN; diagnostic join/outcome remain separately owned.')
