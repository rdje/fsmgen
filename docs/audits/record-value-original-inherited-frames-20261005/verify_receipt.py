"""Reject successful legacy stdout as a substitute for this exact revision."""
import copy
import hashlib
import json
from pathlib import Path

BASE = Path('docs/audits/record-value-original-inherited-frames-20261005')
CHECKS = Path('docs/audits/record-value-original-inherited-frame-checks-20261005')
COMMAND = ['python3', '-B', str(BASE / 'verify.py')]


def identity(path):
    raw = path.read_bytes()
    return {'bytes': len(raw), 'sha256': hashlib.sha256(raw).hexdigest()}


def check(receipt):
    if receipt.get('command') != COMMAND or receipt.get('status') != 0 or receipt.get('stderr') != '':
        raise ValueError('successful exact invoked reader receipt')
    wanted = {name: identity(BASE / name) for name in ('verify.py', 'frame_model.py', 'proofs.json', 'manifest.json')}
    if receipt.get('programme_and_product_identity') != wanted:
        raise ValueError('exact current programme/proof/manifest receipt identity')
    return wanted


def main():
    receipt = json.loads((CHECKS / 'sealed-reader.json').read_text())
    wanted = check(receipt)
    controls = []
    old = json.loads((CHECKS / 'initial-reader.json').read_text())
    changed = copy.deepcopy(receipt)
    changed['programme_and_product_identity']['verify.py'] = identity(BASE / 'initial-verify.py')
    for name, bad in (('actual-initial-successful-receipt', old), ('borrowed-initial-programme-pin', changed)):
        try:
            check(bad)
        except ValueError as error:
            assert str(error) == 'exact current programme/proof/manifest receipt identity'
            controls.append({'control': name, 'status': 1, 'cause': str(error)})
        else:
            raise ValueError('false-green current-revision receipt: ' + name)
    print(json.dumps({'status': 0, 'current_identity': wanted, 'controls': controls,
                      'scope': 'Fresh executed sealed reader pins; identical legacy successful stdout is insufficient.'}, sort_keys=True))


if __name__ == '__main__':
    main()
