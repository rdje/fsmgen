#!/usr/bin/env python3
"""Closed read-only Git transport for a project-owned plain epoch fixture."""
import json
import os
import sys
from pathlib import Path

READS = {'archive', 'cat-file', 'check-ignore', 'diff', 'for-each-ref',
         'hash-object', 'log', 'ls-files', 'ls-tree', 'rev-parse', 'show', 'status'}
CONFIG = {'core.quotePath=false', 'core.fsmonitor=false',
          'core.untrackedCache=false', 'log.showSignature=false'}
FORBIDDEN = {'-w', '-o', '--filters', '--textconv', '--ext-diff', '--refresh',
             '--update', '--reset', '--unresolve', '--reupdate'}


def main():
    args = sys.argv[1:]
    root = Path(os.environ['FSMGEN_EPOCH_ROOT']).resolve(strict=True)
    index = 0
    while index < len(args):
        value = args[index]
        if value in ('--no-replace-objects', '--no-pager'):
            index += 1
        elif value == '-C' and index + 1 < len(args):
            if not Path(args[index + 1]).resolve(strict=True).is_relative_to(root):
                raise ValueError('foreign Git working root')
            index += 2
        elif value == '-c' and index + 1 < len(args) and args[index + 1] in CONFIG:
            index += 2
        else:
            break
    operation = args[index] if index < len(args) else ''
    if operation not in READS or any(
            arg in FORBIDDEN or arg.startswith(('--output', '--remote', '--exec', '--upload-archive'))
            or (operation == 'archive' and arg.startswith('-o'))
            or (operation == 'diff' and arg == '--no-index')
            for arg in args[index + 1:]):
        raise ValueError('Git command refused: ' + operation)
    log = root / '.artifacts/readonly-git-calls.jsonl'
    with log.open('a') as stream:
        stream.write(json.dumps({'arguments': args, 'operation': operation}, sort_keys=True) + '\n')
    environment = dict(os.environ, GIT_OPTIONAL_LOCKS='0', GIT_NO_LAZY_FETCH='1')
    binary = environment['FSMGEN_EPOCH_GIT_BINARY']
    operation_args = args[index + 1:]
    if operation in ('diff', 'show', 'log'):
        operation_args = ['--no-ext-diff', '--no-textconv', *operation_args]
    os.execve(binary, [binary, '--no-replace-objects', '--no-pager', '-c', 'core.fsmonitor=false',
                      '-c', 'core.untrackedCache=false', *args[:index], operation,
                      *operation_args], environment)


if __name__ == '__main__':
    try:
        main()
    except (OSError, KeyError, ValueError) as error:
        print('readonly epoch replay: ' + str(error), file=sys.stderr)
        sys.exit(2)
