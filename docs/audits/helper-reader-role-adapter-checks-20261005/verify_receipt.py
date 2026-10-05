"""Bind the actual sealed historical adapter execution to its exact products."""
import copy
import hashlib
import json
from pathlib import Path

BASE = Path('docs/audits/record-value-helper-reader-role-adapter-20261005')
CHECKS = Path('docs/audits/helper-reader-role-adapter-checks-20261005')


def identity():
    return {name: {'bytes': len(raw), 'sha256': hashlib.sha256(raw).hexdigest()}
            for name in ('adapter.py', 'verify.py', 'proofs.json', 'control-proofs.json', 'manifest.json',
                         'binding.json', 'coupling.json', 'candidate-adapter.json', 'verify_book.py', 'book-transform.json')
            for raw in [(BASE / name).read_bytes()]}


def check(receipt):
    assert type(receipt['status']) is int and receipt['status'] == 0, 'successful actual historical adapter'
    assert receipt['command'] == ['python3', '-B', str(BASE / 'adapter.py'), '--snapshot'], 'exact invoked historical role'
    assert json.dumps(receipt['programme_and_product_identity'], sort_keys=True) == json.dumps(identity(), sort_keys=True), 'exact historical adapter programme/product receipt identity'
    assert receipt['identity_unchanged_after_execution'] is True, 'unchanged executed historical adapter products'
    assert receipt['stdout'].endswith('PASS unchanged historical source-plane predicates with exact helper snapshot role; current semantic/source currency remains separately required.\n')


def main():
    receipt = json.loads((CHECKS / 'sealed-reader.json').read_text())
    check(receipt)
    old = json.loads(Path('docs/audits/record-value-own-subtest-checks-20261005/sealed-reader.json').read_text())
    borrowed = copy.deepcopy(receipt)
    borrowed['programme_and_product_identity'] = old['programme_and_product_identity']
    try:
        check(borrowed)
    except AssertionError as error:
        assert str(error) == 'exact historical adapter programme/product receipt identity'
    else:
        raise AssertionError('false-green older successful source-reader identity')
    print('PASS actual fresh sealed historical adapter identity; actual older successful source-reader identity rejects.')


if __name__ == '__main__':
    main()
