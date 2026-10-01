"""Authenticate emitter/parser scope from saved native receipts and text only."""
import copy
import hashlib
import json
import re
import subprocess
from pathlib import Path

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[2]
BASELINE = '40a51936ed3424acccd65d9812cbc0c1e892da5b'
CASES = {
    'direct': 't/data/isf_record_input_runtime.isf',
    'domains': 't/data/isf_record_input_generated_domains_runtime.isf',
    'blocking': 't/data/isf_record_input_generated_blocking_runtime.isf',
}
ORIGINAL = {
    'record-input-direct-observation-20261001': ['design_systemverilog.sv', 'design_verilog.sv', 'unsigned.sv'],
    'record-input-generated-observation-complete-20261001': ['domains_systemverilog.sv', 'domains_verilog.sv', 'blocking_systemverilog.sv', 'blocking_verilog.sv', 'unsigned.sv'],
}


def sha(raw):
    return hashlib.sha256(raw).hexdigest()


def validate_argv(argv, filename):
    assert argv[:10] == ['verilator', '--binary', '--timing', '--assert', '-Wno-fatal',
                         '-j', '1', '--top-module', 'tb', '--Mdir']
    assert len(argv) == 13 and Path(argv[11]).name == filename
    assert Path(argv[12]).suffix == '.sv'
    assert not any(arg.startswith(('--language', '--default-language', '+1364-', '+1800-')) for arg in argv)


def validate_products(rows, texts):
    assert [(row['case'], row['target']) for row in rows] == [
        (case, target) for case in CASES for target in ('systemverilog', 'verilog')]
    for row in rows:
        case, target = row['case'], row['target']
        output = f'.artifacts/record-input-language-profile/{case}_{target}.sv'
        assert row['source'] == CASES[case]
        assert row['argv'] == ['perl', 'bin/fsmgen', '--quiet', '--strict', '--language', target,
                               '--output', output, CASES[case]]
        assert type(row['exit_code']) is int and row['exit_code'] == 0
        assert row['stderr'] == ''
        text = texts[case + '_' + target]
        assert 'typedef struct packed {' in text
        assert re.search(r'logic \[1:0\] tag;\s*struct packed \{\s*logic signed \[4:0\] data;\s*struct packed \{\s*bit item_0;\s*bit \[1:0\] item_1;', text)
        assert not re.search(r'`(?:begin_keywords|include)', text)
        if target == 'verilog':
            assert not re.search(r'\balways_(?:ff|comb)\b', text)
            assert 'always @*' in text and 'always @(' in text
        else:
            assert 'always_comb' in text and 'always_ff' in text


def must_reject(callback):
    try:
        callback()
    except AssertionError:
        return
    raise AssertionError('hostile scope mutation was accepted')


def main():
    manifest = json.loads((HERE / 'manifest.json').read_bytes())
    assert manifest['schema'] == 'fsmgen.record_input_language_profile.v1'
    assert manifest['baseline_revision'] == BASELINE
    assert {p.name for p in HERE.iterdir() if p.is_file() and p.name != 'manifest.json'} == set(manifest['sha256'])
    for name, expected in manifest['sha256'].items():
        assert sha((HERE / name).read_bytes()) == expected
    for path, identity in manifest['producers'].items():
        blob = subprocess.check_output(['git', 'rev-parse', BASELINE + ':' + path], cwd=ROOT).decode().strip()
        assert blob == identity['git_blob']
        assert sha(subprocess.check_output(['git', 'cat-file', 'blob', blob], cwd=ROOT)) == identity['sha256']
    for path, expected in manifest['prerequisites'].items():
        parentpath = ROOT / path
        assert sha(parentpath.read_bytes()) == expected
        parent = json.loads(parentpath.read_bytes())
        for name, digest in parent['sha256'].items():
            assert sha((parentpath.parent / name).read_bytes()) == digest
    for folder, filenames in ORIGINAL.items():
        records = [json.loads((ROOT / 'docs/audits' / folder / 'observation' / name).read_bytes())
                   for name in ('compile_a.json', 'compile_c.json', 'compile_e.json', 'compile_g.json', 'compile_i.json')[:len(filenames)]]
        for record, filename in zip(records, filenames):
            validate_argv(record['arguments'][0], filename)
            assert record['result']['ok'] == 1 and record['result']['exit_code'] == 0
            assert 'Verilator 5.050 ' in record['result']['stdout']
        bad = records[0]['arguments'][0][:]
        bad.insert(1, '--default-language=1364-2005')
        must_reject(lambda: validate_argv(bad, filenames[0]))
    tool = json.loads((HERE / 'tool-contract.json').read_bytes())
    assert tool['version'] == 'v5.050'
    assert tool['url'] == 'https://raw.githubusercontent.com/verilator/verilator/v5.050/docs/guide/exe_verilator.rst'
    assert tool['bounded_quote'] == 'the latest SystemVerilog language (IEEE 1800-2023) is used.'
    rows = json.loads((HERE / 'emissions.json').read_bytes())
    texts = {case + '_' + target: (HERE / (case + '_' + target + '.hdl.source')).read_text()
             for case in CASES for target in ('systemverilog', 'verilog')}
    validate_products(rows, texts)
    must_reject(lambda: validate_products(rows[:-1], texts))
    bad = dict(texts)
    bad['direct_verilog'] = bad['direct_verilog'].replace('typedef struct packed', 'typedef erased')
    must_reject(lambda: validate_products(rows, bad))
    bad = dict(texts)
    bad['domains_verilog'] = bad['domains_verilog'].replace('logic signed [4:0] data;', 'logic [4:0] data;')
    must_reject(lambda: validate_products(rows, bad))
    bad = copy.deepcopy(rows)
    bad[0]['exit_code'] = False
    must_reject(lambda: validate_products(bad, texts))
    same = json.loads((HERE / 'source-equivalence.json').read_bytes())
    assert same == {'argv': ['git', 'diff', '--exit-code', BASELINE, '--', 'bin', 'perl', 't', 'isf'],
                    'exit_code': 0, 'stdout': '', 'stderr': ''}
    history = json.loads((HERE / 'history.json').read_bytes())
    assert history[0]['stdout'].startswith('f69a464cfdcbe00128bb3923cbd6921a913887c4 ')
    assert history[1]['stdout'].startswith('5de2f44d8e68b1124a3736c30e8479a005188768 ')
    assert history[2]['stdout'].startswith('aa2404ebe7822c53c048460abf7d10961924da12 ')
    book = (HERE / 'book.md.source').read_text()
    original_book = subprocess.check_output(['git', 'show', BASELINE + ':docs/book/src/13j-type-enum-aggregate.md'], cwd=ROOT).decode()
    replacements = json.loads((HERE / 'book-replacements.json').read_bytes())
    assert len(replacements) == 2
    expected_book = original_book
    for row in replacements:
        assert expected_book.count(row['old']) == 1
        expected_book = expected_book.replace(row['old'], row['new'])
    assert book == expected_book
    assert 'Use `systemverilog` for the qualified record-input HDL profile.' in book
    assert 'do not qualify IEEE 1364 Verilog-2005 syntax.' in book
    assert 'are not yet accepted as interface or transaction ports.' not in book
    assert 'Record outputs, root-list inputs and transaction\naggregate ports remain deferred.' in book
    for old in ['record-input-direct-observation-20261001', 'record-input-generated-observation-complete-20261001']:
        receipt = (HERE / ('direct-saved.txt' if 'direct' in old else 'generated-saved.txt')).read_text()
        assert 'verified with exact sources, original bounds/results and cleanup' in receipt and 'Traceback' not in receipt
    assert 'All tests successful.' in (HERE / 'docs.txt').read_text()
    print('Original version-matched argv and complete prior evidence authenticate; current direct/domain/blocking text retains packed SystemVerilog types for both emitter options. Missing pairs, language selectors, type erasure and wrong JSON kinds reject. Current profile and walkthrough scope are reconciled; pure Verilog-2005 admission remains owned. No HDL tool or spent capture runs.')


if __name__ == '__main__':
    main()
