"""Authenticate bounded output source/carrier admission without HDL replay."""
import copy
import hashlib
import json
import subprocess
from pathlib import Path

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[2]
BASE = '0d4bb1801006235d816ebf519eb437752c303849'


def sha(raw):
    return hashlib.sha256(raw).hexdigest()


def validate_probe(before, current):
    names = ['whole', 'ordered', 'competing', 'unused', 'field']
    assert [r['case'] for r in before['cases']] == [r['case'] for r in current['cases']] == names
    for old, new in zip(before['cases'], current['cases']):
        assert old['source'] == new['source'] and old['parsed'] is False
        assert 'references aggregate type' in old['parse_reason']
        assert type(new['parsed']) is bool and new['parsed'] is (new['case'] != 'field')
        if new['case'] == 'field':
            assert 'record output field writes are not yet admitted' in new['parse_reason']
            assert 'results' not in new
            continue
        assert new['before_json'] == new['after_json']
        port = next(p for p in new['actor']['interface_port_metadata'] if p['name'] == 'packet')
        assert port == dict(name='packet', direction='output', width=5, type='frame', type_kind='record', fields=[
            dict(path='tag', width=2, msb=4, lsb=3, signed=0),
            dict(path='payload', width=3, msb=2, lsb=0, signed=1, state_model='four_state')])
        assert len(new['inventory']['writers']) == {'whole': 1, 'ordered': 2, 'competing': 2, 'unused': 0}[new['case']]
        assert [r['method'] for r in new['results']] == ['lower', 'report']
        for r in new['results']:
            expected = new['case'] != 'competing'
            assert type(r['accepted']) is bool and r['accepted'] is expected
            if expected:
                assert r['product'] is not None and r['reason'] == ''
            else:
                assert r['product'] is None
                assert "record output 'packet' cannot admit overlapping writers" in r['reason']
                assert 'transaction/left/state:' in r['reason'] and 'transaction/right/state:' in r['reason']
    assert [r['case'] for r in before['prototypes']] == [r['case'] for r in current['prototypes']] == ['whole', 'competing']
    for old, new in zip(before['prototypes'], current['prototypes']):
        assert old['actor'] == new['actor'] and old['ir'] == new['ir'] and old['inventory'] == new['inventory']
        assert old['before_json'] == old['after_json'] == new['before_json'] == new['after_json']
        assert len(new['inventory']['writers']) == (1 if new['case'] == 'whole' else 2)
        for previous, r in zip(old['results'], new['results']):
            assert previous['accepted'] is True and previous['product'] is not None
            if new['case'] == 'whole':
                assert r == previous
            else:
                assert r['accepted'] is False and r['product'] is None
                assert "record output 'packet' cannot admit overlapping writers" in r['reason']


def main():
    m = json.loads((HERE / 'manifest.json').read_bytes())
    assert m['baseline_revision'] == BASE
    assert set(m['sha256']) == {p.name for p in HERE.iterdir() if p.is_file() and p.name != 'manifest.json'}
    for name, digest in m['sha256'].items():
        assert sha((HERE / name).read_bytes()) == digest
    for path, item in m['baseline_sources'].items():
        blob = subprocess.check_output(['git', 'rev-parse', BASE + ':' + path], cwd=ROOT).decode().strip()
        assert blob == item['git_blob']
        assert sha(subprocess.check_output(['git', 'cat-file', 'blob', blob], cwd=ROOT)) == item['sha256'] == sha((HERE / item['snapshot']).read_bytes())
    for dirname, members in m['parent_members'].items():
        parent = ROOT / 'docs/audits' / dirname
        assert set(members) == {p.name for p in parent.iterdir() if p.is_file()}
        for name, digest in members.items():
            assert sha((parent / name).read_bytes()) == digest
    for name, p in m['receipt_projections'].items():
        assert len((HERE / name).read_bytes()) == p['raw_bytes'] - p['replacement_count'] * (p['root_prefix_bytes'] - len(b'<repo>'))
    assert m['terminal_exit_codes'] == dict(red=1, draft_focus=1, draft_regex=1, focused_initial=0,
        focused_complete=0, broad_initial=1, repaired=0, docs_initial=1, docs=0, book=0,
        syntax=0, book_example=0, probe=0, baseline_probe=0, parent_verifier=0,
        history_consumer=0, history_producer=0, wrong_baseline_harness=1, baseline_child=1)
    for name, count in [('focused.txt', 'Files=5, Tests=30'), ('repaired.txt', 'Files=2, Tests=11'), ('docs.txt', 'Files=3, Tests=310')]:
        text = (HERE / name).read_text()
        assert count in text and 'All tests successful.' in text and 'Result: PASS' in text
    broad = (HERE / 'broad-initial.txt').read_text()
    assert 'Files=11, Tests=94' in broad and 'Result: FAIL' in broad
    assert set(m['broad_pass_paths']) == {
        't/1983-isf-interface-port-metadata.t', 't/1984-isf-interface-port-report-integration.t',
        't/1985-isf-interface-port-public-qualification.t', 't/1987-isf-record-port-declaration-scopes.t',
        't/1990-isf-record-port-sample-facts.t', 't/1991-isf-record-port-sample-contexts.t',
        't/1997-isf-record-port-gate-integration.t', 't/2014-isf-record-input-public-sources.t',
        't/2016-isf-record-input-public-refusals.t'}
    for path in m['broad_pass_paths']:
        line = next(line for line in broad.splitlines() if line.startswith(path + ' '))
        assert line.endswith(' ok')
    assert 'HTML book written to' in (HERE / 'book.txt').read_text()
    assert (HERE / 'syntax.txt').read_text().count('syntax OK') == 3
    baseline_child = (HERE / 'context-map-baseline-child.txt').read_text()
    assert "got->[5] = 'scalar_parameter_roots'" in baseline_child
    assert 'ok 6 - closed context selection' in baseline_child and 'failed 1 test of 6' in baseline_child
    for name in ['context-map-history.txt', 'context-map-producer-history.txt']:
        assert 'ee81704239ca86545804eee4af357ffb3a838404' in (HERE / name).read_text()
    old_root = (HERE / 'reconstructed-broad-root-classification.t.source').read_text()
    root = (HERE / '1989-isf-record-port-root-classification.t.source').read_text()
    assert root == old_root.replace('[qw(aggregate_roots enum_exclusion_roots namespaces roots rule_declared_roots)]', '[qw(aggregate_roots enum_exclusion_roots namespaces roots rule_declared_roots scalar_parameter_roots)]').replace(
        "        'complete projection has only the selected consumer maps');", "        'complete projection has only the selected consumer maps');\n    is_deeply($context->{scalar_parameter_roots}, {}, 'outer actor statics do not invent lexical drive masks');").replace(
        "    my $context = record_context_scope(actor => $actor, drive => $actor->{drives}{publish});", "    my $context = record_context_scope(actor => $actor, drive => $actor->{drives}{publish});\n    is_deeply($context->{scalar_parameter_roots}, {packet => 1}, 'explicit drive formal supplies its exact scalar mask');")
    parser = (HERE / 'parser.pm.source').read_text()
    old_parser = (HERE / 'baseline-parser.pm.source').read_text()
    assert parser == old_parser.replace("allow_record => ($direction eq 'inputs' ? 1 : 0)", 'allow_record => 1').replace('packed record actor inputs\\n', 'packed record actor ports\\n')
    assert set((HERE / 'production-paths.txt').read_text().splitlines()) == {'perl/FSM/Adapter/ISF/Parser.pm', 'perl/FSM/Scheduler/ISF.pm'}
    for path, item in m['unchanged_sources'].items():
        assert sha(subprocess.check_output(['git', 'show', BASE + ':' + path], cwd=ROOT)) == item['baseline_sha256'] == item['captured_current_sha256']
    example = json.loads((HERE / 'book-example.json').read_bytes())
    assert example['success'] is True
    port = next(p for p in example['source']['interface_ports'] if p['name'] == 'packet')
    assert port['direction'] == 'output' and port['type'] == 'frame' and port['width'] == 5
    before = json.loads((HERE / 'baseline-probe.json').read_bytes())
    current = json.loads((HERE / 'probe.json').read_bytes())
    validate_probe(before, current)
    for mutate in [lambda p: p['cases'][2]['results'][0].update(accepted=True),
                   lambda p: p['cases'][2]['inventory']['writers'].pop(),
                   lambda p: p['cases'][0]['actor']['interface_port_metadata'][2].update(direction='input'),
                   lambda p: p['cases'][4].update(parsed=True),
                   lambda p: p['prototypes'][1]['results'][1].update(product={})]:
        bad = copy.deepcopy(current)
        mutate(bad)
        try:
            validate_probe(before, bad)
        except AssertionError:
            continue
        raise AssertionError('Hostile publication, writer omission, role, field or partial-product substitution accepted')
    print('Actual output source and strict carrier receipts authenticate bounded declarations/copies and mandatory direct/domain writer publication gates. Identical baseline/current prototype IR retains complete writers; unproved overlap now refuses. Historical private-map drift and exact repaired assertions authenticate; split broad/focused/docs receipts preserve honest revision boundaries. Hostile publication, omission, role, field and partial-product substitutions reject. No HDL execution or complete output delivery claim.')


if __name__ == '__main__':
    main()
