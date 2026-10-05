"""Bind the actual fresh sealed source-reader execution to its complete products."""
import copy
import hashlib
import json
from pathlib import Path

BASE = Path('docs/audits/record-value-own-subtest-boundaries-20261005')
CHECKS = Path('docs/audits/record-value-own-subtest-checks-20261005')


def identity():
    return {name: {'bytes': len(raw), 'sha256': hashlib.sha256(raw).hexdigest()}
            for name in ('verify.py', 'model.py', 'proofs.json', 'manifest.json', 'verify_public.py',
                         'public-interface.json', 'verify_book.py', 'book-transform.json')
            for raw in [(BASE / name).read_bytes()]}


def check(receipt):
    assert type(receipt['status']) is int and receipt['status'] == 0, 'successful actual sealed source reader'
    assert receipt['command'] == ['python3', '-B', str(BASE / 'verify.py')], 'exact invoked sealed source reader'
    assert receipt['programme_and_product_identity'] == identity(), 'exact own-subtest programme/product receipt identity'
    assert receipt['identity_unchanged_after_execution'] is True, 'unchanged executed programme/products'
    assert receipt['stdout'].endswith('PASS complete finite own subtest/body/delegate/do-load roles and rejecting controls; framework/display/native identity remain open.\n')


def main():
    receipt = json.loads((CHECKS / 'sealed-reader.json').read_text())
    check(receipt)
    old = json.loads(Path('docs/audits/record-value-original-helper-join-checks-20261005/sealed-reader.json').read_text())
    borrowed = copy.deepcopy(receipt)
    borrowed['programme_and_product_identity'] = old['programme_and_product_identity']
    try:
        check(borrowed)
    except AssertionError as error:
        assert str(error) == 'exact own-subtest programme/product receipt identity'
    else:
        raise AssertionError('false-green older successful source-reader identity')
    print('PASS actual fresh sealed own-subtest programme/products identity; older actual successful identity rejects.')


if __name__ == '__main__':
    main()
