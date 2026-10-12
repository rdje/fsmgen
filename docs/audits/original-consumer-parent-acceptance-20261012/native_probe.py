"""Run each actual source, meaning or full original-parent independent reader."""
import argparse
from parent_common import *
import interfaces
import reader

SUCCESS = dict(parent=reader.SUCCESS,
    source='PASS freshly rederived isolated complete original source contracts; original parent closure is separate.\n',
    meaning='PASS freshly rederived isolated complete original consumer meanings; original parent closure is separate.\n')


def payload(candidate, role):
    return candidate if role == 'parent' else candidate['source_contracts' if role == 'source' else 'meanings']


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--role', choices=tuple(SUCCESS), required=True)
    parser.add_argument('--candidate', required=True)
    args = parser.parse_args()
    need(Path(args.candidate).name == args.candidate and args.candidate.endswith('.json.gz'), 'ordinary own complete original consumer control candidate')
    candidate = load_product(args.candidate)
    if args.role == 'parent':
        reader.check(candidate)
    elif args.role == 'source':
        interfaces.source_contracts(candidate)
    else:
        interfaces.meanings(candidate)
    print(SUCCESS[args.role], end='')
