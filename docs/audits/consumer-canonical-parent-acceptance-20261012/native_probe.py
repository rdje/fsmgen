"""Fresh native complete parent or original meaning reader; no archive writes."""
import argparse
from parent_common import *
import reader
import interfaces

SUCCESS = {
    'canonical': reader.SUCCESS,
    'meaning': 'PASS freshly rederived isolated complete original consumer meanings; canonical/original parent closure is separate.\n'}

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--role', choices=tuple(SUCCESS), required=True)
    parser.add_argument('--candidate', required=True)
    args = parser.parse_args()
    need(Path(args.candidate).name == args.candidate and args.candidate.endswith('.json.gz'), 'ordinary own native separating candidate')
    candidate = load_product(args.candidate)
    if args.role == 'canonical':
        reader.check(candidate)
    else:
        interfaces.meanings(candidate)
    print(SUCCESS[args.role], end='')
