"""Authenticate the actual fresh sealed-reader receipt at its complete boundary."""
import copy
import hashlib
import json
from pathlib import Path

BASE = Path('docs/audits/record-value-original-helper-join-20261005')
CHECKS = Path('docs/audits/record-value-original-helper-join-checks-20261005')


def identity():
    return {name: {'bytes': len(raw), 'sha256': hashlib.sha256(raw).hexdigest()}
            for name in ('verify.py', 'proofs.json', 'manifest.json')
            for raw in [(BASE / name).read_bytes()]}


def check(receipt):
    assert receipt['status'] == 0, 'successful actual sealed reader'
    assert receipt['command'] == ['python3', '-B', str(BASE / 'verify.py')], 'exact invoked sealed reader'
    assert receipt['programme_and_product_identity'] == identity(), 'exact current programme/proof/manifest receipt identity'
    assert receipt['stdout'].endswith('PASS complete finite source helper allocation/input/default/return/throw-phase and callback/refusal path join; full framework/display/native identity remains open.\n'), 'complete joint helper success output'


def main():
    receipt = json.loads((CHECKS / 'sealed-reader.json').read_text())
    check(receipt)
    old = json.loads(Path('docs/audits/record-value-original-callback-path-checks-20261005/sealed-reader.json').read_text())
    borrowed = copy.deepcopy(receipt)
    borrowed['programme_and_product_identity'] = old['programme_and_product_identity']
    try:
        check(borrowed)
    except AssertionError as error:
        assert str(error) == 'exact current programme/proof/manifest receipt identity', 'intended borrowed-successful-receipt control'
    else:
        raise AssertionError('false-green borrowed successful receipt')
    print('PASS exact fresh invoked helper-join programme/proof/manifest receipt; actual older successful programme identity rejects.')


if __name__ == '__main__':
    main()
