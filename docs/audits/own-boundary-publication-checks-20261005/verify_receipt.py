"""Bind actual fresh sealed current publication execution to exact products."""
import copy
import hashlib
import json
from pathlib import Path

BASE = Path('docs/audits/record-value-own-boundary-publication-20261005')
CHECKS = Path('docs/audits/own-boundary-publication-checks-20261005')


def identity():
    return {name: {'bytes': len(raw), 'sha256': hashlib.sha256(raw).hexdigest()}
            for name in ('verify.py', 'publish.py', 'publication.json', 'binding.json', 'current-queries.json',
                         'control-proofs.json', 'fidelity-proofs.json', 'book-proofs.json', 'manifest.json')
            for raw in [(BASE / name).read_bytes()]}


def check(receipt):
    assert type(receipt['status']) is int and receipt['status'] == 0, 'successful actual current publication reader'
    assert receipt['command'] == ['python3', '-B', str(BASE / 'verify.py'), '--current', '--build', '.artifacts/own-boundary-publication/book'], 'exact actual current/copy reader role'
    assert json.dumps(receipt['programme_and_product_identity'], sort_keys=True) == json.dumps(identity(), sort_keys=True), 'exact current publication programme/product receipt identity'
    assert receipt['identity_unchanged_after_execution'] is True, 'unchanged actual current publication products'
    assert receipt['stdout'].endswith('PASS authenticated historical snapshots plus independent complete current source/question/book/source-plane roles; formatter/native identity remain open.\n')


def main():
    receipt = json.loads((CHECKS / 'sealed-reader.json').read_text()); check(receipt)
    old = json.loads(Path('docs/audits/helper-reader-role-adapter-checks-20261005/sealed-reader.json').read_text())
    borrowed = copy.deepcopy(receipt); borrowed['programme_and_product_identity'] = old['programme_and_product_identity']
    try:
        check(borrowed)
    except AssertionError as error:
        assert str(error) == 'exact current publication programme/product receipt identity'
    else:
        raise AssertionError('false-green historical-only successful identity as current authority')
    print('PASS actual fresh sealed current publication identity; actual historical-only successful identity rejects.')


if __name__ == '__main__':
    main()
