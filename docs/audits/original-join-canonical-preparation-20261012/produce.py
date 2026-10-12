"""Save only a source-bound original-join proposal; production remains unchanged."""
import argparse
from model import *

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--prefix', choices=('', 'v3-'), default='')
    args = parser.parse_args()
    save_product(args.prefix + 'candidate.json.gz', propose(context()))
    print('Prepared complete non-growing original-join canonical candidate; production remains unchanged.')
