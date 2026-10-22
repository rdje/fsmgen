"""Check saved private complement evidence without replaying any failed probe."""
from pathlib import Path
import copy
import gzip
import hashlib
import json
import subprocess

ROOT = Path(__file__).resolve().parents[2]
AUDIT = ROOT / 'docs/audits/private-complement-reproduction-20261022.json.gz'
NEEDLE = 'scalar width-preserving unary classification follows its known result width'


def digest(raw):
    return hashlib.sha256(raw).hexdigest()


def validate(source, log, products, native):
    lines = source.splitlines()
    assert "core_unary('~', core_signal('one_bit', 1))" in lines[136]
    assert NEEDLE in lines[137]
    assert "Failed test '" + NEEDLE + "'" in log
    assert 'at t/2074-unary-reduction-width-foundation.t line 137.' in log
    assert len(products) == 8
    assert [(r['model'], r['kind']) for r in products[:6]] == [
        (model, kind) for model in ('core', 'runtime', 'substituted') for kind in ('scalar', 'wide')]
    for row in products[:6]:
        assert row['width'] == (1 if row['kind'] == 'scalar' else 8)
        assert row['is_single_bit'] == 0
        assert row['sv'] == ('~(A)' if row['kind'] == 'scalar' else '~(W)')
    for row, expr in zip(products[6:], ('~(A)', '!(~(A))'), strict=True):
        assert row['profile'] == 'vhdl' and row['error'] == ''
        assert expr in row['sv'] and '~' in row['output']
    assert native['exit_code'] == 1
    report = json.loads(native['stdout'])
    assert report['success'] is False
    assert "Unsupported expression operator '~'" in report['diagnostics'][0]['message']


def main():
    audit = json.loads(gzip.decompress(AUDIT.read_bytes()))
    assert audit['schema'] == 'fsmgen.private_complement_reproduction.v1'
    files = {r['path']: r for r in audit['files']}
    assert len(files) == len(audit['files'])
    for row in files.values():
        raw = row['text'].encode()
        assert len(raw) == row['bytes'] and digest(raw) == row['sha256']
    def one(suffix):
        rows = [r for name, r in files.items() if name.endswith(suffix)]
        assert len(rows) == 1
        return rows[0]['text']
    original = json.loads(gzip.decompress((ROOT / audit['historical_provenance']['primary']).read_bytes()))
    source = one('scalar-classification-red-2074.t.source')
    log = one('historical-red.log')
    old_source = next(r for r in original['retained_inputs_and_epochs'] if r['path'].endswith('scalar-classification-red-2074.t.source'))
    old_log = next(r for r in original['checks'] if r['path'].endswith('scalar-classification-red-20261022.txt'))
    assert digest(source.encode()) == old_source['sha256'] and digest(log.encode()) == old_log['sha256']
    products = json.loads(one('settled-products.json'))
    identities = json.loads(one('identity-and-source.json'))
    native = identities['native_source_refusal']
    for row in identities['compiled_methods']:
        assert row['compiled_source'] in ('perl/FSM/Synthesis/EnableGraph/ASTSupport.pm',
                                          'perl/FSM/HDL/FlattenedDT/Backend/VHDL.pm')
        raw = subprocess.check_output(['git', 'show', audit['baseline'] + ':' + row['compiled_source']], cwd=ROOT)
        assert digest(raw) == row['sha256']
    validate(source, log, products, native)
    settled = one('private-complement-settled-red-20261022.log')
    assert 'Failed tests:  2, 10, 18, 25-26' in settled and 'Files=1, Tests=26,' in settled
    assert 'Non-zero exit status: 5' in settled
    assert 'Use of uninitialized value $subroutine' in settled and 'ASTSupport.pm line 83' in settled
    first = json.loads(one('first-epoch/fresh-products.json'))
    assert first[3]['width'] is None
    assert products[3]['width'] == 8
    altered = copy.deepcopy(products)
    altered[0]['width'] = 8
    mutations = [(source, log, altered, native), (source.replace("core_unary('~', core_signal('one_bit', 1))", 'removed'), log, products, native)]
    altered = copy.deepcopy(native)
    altered['exit_code'] = 0
    mutations.append((source, log, products, altered))
    altered = copy.deepcopy(products)
    altered[6]['output'] = 'no foreign token'
    mutations.append((source, log, altered, native))
    for args in mutations:
        try:
            validate(*args)
        except AssertionError:
            continue
        raise AssertionError('Corrupt saved private complement evidence accepted')
    print('Complete historical assertion/source/log join, fresh current scalar/profile failures and source refusal verified; hostile saved controls reject.')


if __name__ == '__main__':
    main()
