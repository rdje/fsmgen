"""Check whole current native scalar values and source-selected trace hypotheses."""
from common import BASE, load, save
import oracle


if __name__ == '__main__':
    save('native-proof.json', oracle.verify_native(load('plan.json'), load('native.json'),
         (BASE / 'native.pl').read_bytes()))
    print('PASS independent complete current public scalar values, profiles, headers and trace bodies.')
