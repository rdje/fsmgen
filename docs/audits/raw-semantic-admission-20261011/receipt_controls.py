"""Exercise the actual native receipt reader, including the original doubled path."""
import copy
from common import *
import verify


def main():
    path = next(BASE.glob('actual-native-census-*.json'))
    source = dict(receipt=str(path), identity=pin(path.read_bytes()))
    outcomes = {}
    for name, pointer in (
        ('positive', str(path)),
        ('original-doubled-path', str(BASE / str(path))),
        ('foreign-path', '.git/foreign-admission-control'),
        ('missing-own-receipt', str(BASE / 'missing-native-receipt.json'))):
        candidate = copy.deepcopy(source)
        candidate['receipt'] = pointer
        diagnostic = None
        status = None
        try:
            status = verify.native_record(candidate)['status']
        except ValueError as error:
            diagnostic = str(error)
        outcomes[name] = dict(candidate=candidate, actual_diagnostic=diagnostic, actual_status=status)
    save('native-receipt-controls.json', dict(programmes=programs(), outcomes=outcomes))
    need(outcomes['positive']['actual_status'] == 0 and outcomes['positive']['actual_diagnostic'] is None,
         'actual full receipt positive')
    for name in ('original-doubled-path', 'foreign-path'):
        need(outcomes[name]['actual_diagnostic'] == 'own complete native source census receipt',
             'actual native receipt ownership refusal')
    need(outcomes['missing-own-receipt']['actual_diagnostic'] == 'complete ordinary admission member',
         'actual missing native receipt refusal')
    print('PASS actual native receipt positive, original doubled path, foreign path and missing-member controls; all complete candidates and outcomes retain.')


if __name__ == '__main__':
    main()
