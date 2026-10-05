"""Bind actual fresh sealed current parser source inventory execution to exact products."""
import copy
import hashlib
import json
from pathlib import Path

BASE = Path('docs/audits/record-value-original-parser-sources-20261005')
CHECKS = Path('docs/audits/parser-source-checks-20261005')


def identity():
    return {name: {'bytes': len(raw), 'sha256': hashlib.sha256(raw).hexdigest()}
            for name in ('binding.json','verify.py','recipes.py','proofs.json','manifest.json','publication.py','publication.json','current-input.json','current-controls.json','book-proofs.json','book-input.html')
            for raw in [(BASE / name).read_bytes()]}


def check(receipt):
    assert type(receipt['status']) is int and receipt['status'] == 0, 'successful actual current parser source inventory reader'
    assert receipt['command'] == ['python3', '-B', str(BASE / 'verify.py'), '--current', '--build', '.artifacts/parser-source-inventory/book'], 'exact actual current/copy reader role'
    assert json.dumps(receipt['programme_and_product_identity'], sort_keys=True) == json.dumps(identity(), sort_keys=True), 'exact current parser source inventory programme/product receipt identity'
    assert receipt['identity_unchanged_after_execution'] is True, 'unchanged actual current parser source inventory products'
    assert receipt['stdout'].endswith('PASS complete finite original own parser source inventory and genuine controls; active/native path meanings remain separately owned.\n')


def main():
    receipt = json.loads((CHECKS / 'sealed-reader.json').read_text()); check(receipt)
    old = json.loads(Path('docs/audits/helper-reader-role-adapter-checks-20261005/sealed-reader.json').read_text())
    borrowed = copy.deepcopy(receipt); borrowed['programme_and_product_identity'] = old['programme_and_product_identity']
    try:
        check(borrowed)
    except AssertionError as error:
        assert str(error) == 'exact current parser source inventory programme/product receipt identity'
    else:
        raise AssertionError('false-green earlier semantic successful identity as current authority')
    print('PASS actual fresh sealed current parser source inventory identity; actual earlier semantic successful identity rejects.')


if __name__ == '__main__':
    main()
