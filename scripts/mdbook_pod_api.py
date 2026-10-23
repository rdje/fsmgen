#!/usr/bin/env python3
"""mdBook preprocessor: prepare the validated POD asset tree for HTML copying."""
import json
from pathlib import Path
import sys

from generate_pod_reference import ROOT, ReferenceError, generate


def main():
    if len(sys.argv) == 3 and sys.argv[1] == 'supports':
        return 0 if sys.argv[2] == 'html' else 1
    if len(sys.argv) != 1:
        raise ReferenceError('Expected mdBook preprocessor input or supports html')
    context, book = json.load(sys.stdin)
    if Path(context['root']).resolve() != ROOT / 'docs/book':
        raise ReferenceError('POD preprocessor requires this repository\'s docs/book root')
    if context['config']['book'].get('src', 'src') != 'src':
        raise ReferenceError('POD preprocessor requires the configured src asset directory')
    status = generate()
    print(f'pod-reference: {status}', file=sys.stderr)
    json.dump(book, sys.stdout, ensure_ascii=False)
    sys.stdout.write('\n')
    return 0


if __name__ == '__main__':
    try:
        sys.exit(main())
    except (ReferenceError, OSError, ValueError, KeyError, TypeError) as error:
        print(f'pod-reference: ERROR: {error}', file=sys.stderr)
        sys.exit(1)
