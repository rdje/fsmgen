"""Bind actual fresh sealed superseding parser source topic publication execution to exact products."""
import copy
import hashlib
import json
from pathlib import Path

BASE = Path('docs/audits/record-value-parser-source-publication-20261005')
CHECKS = Path('docs/audits/parser-source-checks-20261005')


def identity():
    return {name: {'bytes': len(raw), 'sha256': hashlib.sha256(raw).hexdigest()}
            for name in ('verify.py','binding.json','publication.json','collection-proof.json','collection-members.json','book-source-proof.json','book-input.html','current-input.json','controls.json','book-proofs.json','manifest.json')
            for raw in [(BASE / name).read_bytes()]}


def check(receipt):
    assert type(receipt['status']) is int and receipt['status'] == 0, 'successful actual superseding parser source topic publication reader'
    assert receipt['command'] == ['python3', '-B', str(BASE / 'verify.py'), '--current', '--build', '.artifacts/parser-source-publication/book'], 'exact actual current/copy reader role'
    assert json.dumps(receipt['programme_and_product_identity'], sort_keys=True) == json.dumps(identity(), sort_keys=True), 'exact superseding parser source topic publication programme/product receipt identity'
    assert receipt['identity_unchanged_after_execution'] is True, 'unchanged actual superseding parser source topic publication products'
    assert receipt['stdout'].endswith('PASS original source proof plus current fact/query/guide/physical-capacity roles.\n')


def main():
    receipt = json.loads((CHECKS / 'superseding-sealed-reader.json').read_text()); check(receipt)
    old = json.loads(Path('docs/audits/parser-source-checks-20261005/sealed-reader.json').read_text())
    borrowed = copy.deepcopy(receipt); borrowed['programme_and_product_identity'] = old['programme_and_product_identity']
    try:
        check(borrowed)
    except AssertionError as error:
        assert str(error) == 'exact superseding parser source topic publication programme/product receipt identity'
    else:
        raise AssertionError('false-green withdrawn proposed inventory successful identity as current authority')
    print('PASS actual fresh sealed superseding parser source topic publication identity; actual withdrawn proposed inventory successful identity rejects.')


if __name__ == '__main__':
    main()
