"""Exercise the original and corrected input directory graph on isolated copies."""
import argparse
import ast
import json
import tempfile
from pathlib import Path

import intake
from common import BASE, canonical, load, need, pin, save

SUCCESS = ('PASS complete original empty-directory false green and corrected '
           'positive/empty-directory/nested-file/symlink/missing input-graph controls.\n')


def original_scanner():
    source = (BASE / 'intake-before-directory-graph.py.txt').read_bytes()
    tree = ast.parse(source)
    procedure = next(node for node in tree.body
                     if isinstance(node, ast.FunctionDef) and node.name == 'derive')
    assignments = {node.targets[0].id: index
                   for index, node in enumerate(procedure.body)
                   if isinstance(node, ast.Assign)
                   and isinstance(node.targets[0], ast.Name)}
    fragment = ast.Module(body=procedure.body[
        assignments['observed']:assignments['recovered']], type_ignores=[])
    return compile(fragment, str(BASE / 'intake-before-directory-graph.py.txt'), 'exec')


def graph(directory):
    return {str(path.relative_to(directory)): {
        'kind': ('symlink' if path.is_symlink() else
                 'directory' if path.is_dir() else 'file'),
        'identity': pin(path.read_bytes())
        if path.is_file() and not path.is_symlink() else None}
        for path in sorted(directory.rglob('*'))}


def exercise(corrected, observe=False):
    local = Path('.artifacts/raw-stack-prerequisites-20261011')
    local.mkdir(parents=True, exist_ok=True)
    results = []
    with tempfile.TemporaryDirectory(dir=local, prefix='input-directory-') as temporary:
        directory = Path(temporary).resolve().relative_to(Path.cwd().resolve())
        known, recovered = directory / 'known.txt', directory / 'retained.tar.gz'
        known.write_bytes(b'Complete declared input.\n')
        recovered.write_bytes(b'Explicit graph-only recovery fixture.\n')
        entries = {str(known): {'mode': '100644'}}
        cases = ('complete', 'empty-directory', 'nested-file', 'symlink', 'missing')
        for name in cases if corrected else cases[:2]:
            extra = None
            if name in ('empty-directory', 'nested-file'):
                extra = directory / 'unexpected'
                extra.mkdir()
                if name == 'nested-file':
                    (extra / 'payload.txt').write_bytes(b'Undeclared input.\n')
            elif name == 'symlink':
                extra = directory / 'borrowed'
                extra.symlink_to('known.txt')
            elif name == 'missing':
                known.unlink()
            candidate = graph(directory)
            try:
                if corrected:
                    observed = intake.source_graph([str(directory)], entries,
                                                   str(recovered))
                else:
                    namespace = dict(os=__import__('os'), Path=Path, need=need,
                                     selected=[str(directory)], entries=entries,
                                     RECOVERY=str(recovered))
                    exec(original_scanner(), namespace)
                    observed = namespace['observed']
                outcome = {'kind': 'returned', 'observed_files': sorted(
                    str(Path(path).relative_to(directory)) for path in observed)}
            except ValueError as error:
                outcome = {'kind': 'refused', 'exception': 'ValueError',
                           'cause': str(error)}
            row = {'case': name, 'candidate': candidate, 'outcome': outcome}
            if observe:
                print(json.dumps(row, sort_keys=True), flush=True)
            expected = 'returned' if name == 'complete' or not corrected else 'refused'
            need(outcome['kind'] == expected, 'intended actual input-graph outcome')
            if expected == 'refused':
                cause = ('complete raw prerequisite directory population'
                         if name in ('empty-directory', 'nested-file') else
                         'own raw prerequisite file graph' if name == 'symlink' else
                         'complete current and fixed raw prerequisite member graph plus exact owned recovery')
                need(outcome['cause'] == cause, 'intended actual input-graph refusal')
            results.append(row)
            if extra is not None:
                if extra.is_symlink():
                    extra.unlink()
                else:
                    if (extra / 'payload.txt').exists():
                        (extra / 'payload.txt').unlink()
                    extra.rmdir()
            if name == 'missing':
                known.write_bytes(b'Complete declared input.\n')
    return results


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--diagnose', action='store_true')
    parser.add_argument('--replay', action='store_true')
    args = parser.parse_args()
    original = exercise(False, observe=not args.replay)
    need(original[0]['outcome'] == original[1]['outcome']
         and original[0]['candidate'] != original[1]['candidate'],
         'genuine original empty-directory false green')
    product = {'original': original,
               'original_programme': pin((BASE / 'intake-before-directory-graph.py.txt').read_bytes()),
               'scope': 'Actual in-process original AST scanner and corrected graph procedure; '
                        'isolated same-volume graph fixtures only, no archive semantics or '
                        'original native recapture. Outcomes are returned values/exceptions, '
                        'not invented subprocess exit statuses.'}
    if args.diagnose:
        save('intake-directory-diagnosis.json', product)
        print('CONFIRMED original input file census accepts a genuine unexpected empty directory.')
        return
    product['corrected'] = exercise(True, observe=not args.replay)
    product['corrected_programme'] = pin((BASE / 'intake.py').read_bytes())
    if args.replay:
        need(canonical(load('intake-directory-controls.json')) == canonical(product),
             'complete unchanged actual input-directory control replay')
    else:
        save('intake-directory-controls.json', product)
    print(SUCCESS, end='')


if __name__ == '__main__':
    main()
