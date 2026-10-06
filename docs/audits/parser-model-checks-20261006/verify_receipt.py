"""An actual fresh current model execution cannot borrow older successful proof."""
import json
from pathlib import Path

BASE = Path('docs/audits/record-value-parser-path-models-20261006')
CHECKS = Path('docs/audits/parser-model-checks-20261006')
ns = {'__name__': 'parser_model_receipt_identity'}
exec(compile((BASE / 'verify.py').read_bytes(), str(BASE / 'verify.py'), 'exec'), ns)
expected = ['python3', '-B', str(BASE / 'verify.py'), '--current', '--build', '.artifacts/parser-path-models/book']
pins = {p.name: ns['identity'](p.read_bytes()) for p in BASE.iterdir()}


def check(receipt):
    ns['require'](receipt['command'] == expected, 'fresh sealed model current command')
    ns['require'](type(receipt['status']) is int and receipt['status'] == 0, 'actual successful integer current status')
    ns['require'](ns['same'](receipt['programme_and_product_identity'], pins)
                  and receipt['identity_unchanged_after_execution'] is True, 'whole unchanged sealed model programme/products')
    ns['require']('PASS current scoped source meanings/query/guide/capacity' in receipt['stdout'], 'actual scoped current role output')


check(json.loads((CHECKS / 'sealed-reader.json').read_text()))
older = json.loads(Path('docs/audits/parser-source-checks-20261005/superseding-sealed-reader.json').read_text())
assert type(older['status']) is int and older['status'] == 0
try:
    check(older)
except ValueError as error:
    assert str(error) == 'fresh sealed model current command'
else:
    raise ValueError('false-green borrowed inventory-only successful identity')
print('PASS actual fresh sealed current model identity; actual older inventory success rejects')
