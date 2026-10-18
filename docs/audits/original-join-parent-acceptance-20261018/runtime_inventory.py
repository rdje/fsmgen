"""Inventory fixed source and static call sites; do not infer runtime permission."""
import argparse
import ast
import copy
import gzip
import io
import json
from pathlib import Path
import posixpath
import sys
import tokenize

import epoch_constraints as epoch
import execute
import prepare
import selected_checkout

PATH = execute.AUDIT / 'runtime-source-inventory.json.gz'
CONTROLS = execute.AUDIT / 'runtime-source-inventory-controls.json.gz'
CODE_SUFFIXES = {'.py', '.pl', '.pm', '.sh', '.t'}
CONFIGS = {'.knowledge_map.conf', 'knowledge-map/scripts/knowledge_map.conf'}
MAX_CODE_BYTES = 192 * 1024 * 1024
IO_HINTS = {
    'open', 'read', 'read_bytes', 'read_text', 'readlines', 'write', 'write_bytes', 'write_text',
    'mkdir', 'makedirs', 'rmdir', 'unlink', 'remove', 'rename', 'replace', 'touch', 'chmod',
    'link', 'symlink', 'copy', 'copyfile', 'copytree', 'rmtree', 'walk', 'glob', 'rglob',
    'iterdir', 'stat', 'lstat', 'exists', 'resolve', 'readlink', 'fdopen', 'mkstemp', 'mkdtemp',
    'TemporaryDirectory', 'TemporaryFile', 'NamedTemporaryFile', 'run', 'Popen', 'check_call',
    'check_output', 'system', 'exec', 'eval', 'compile', '__import__', 'import_module', 'run_path',
}
SCOPE = ('Complete selected Git input membership and declared code-projection/static-site census only. '
         'Every Python Call/Import/ImportFrom is retained, including calls without an I/O hint; '
         'other code retains complete bytes and raw LF line addresses. Hints are navigation, not '
         'filesystem classifiers. Parse failures, dynamic execution and delegated tools remain '
         'unresolved execution/data boundaries. No site count establishes default reachability, '
         'write permission, complete expanded dynamic code, or actual producer behavior. '
         'No semantic cohort, new checkout, spent fixture mutation or original native/private producer runs.')


def spelling(node):
    if isinstance(node, ast.Name):
        return node.id
    if isinstance(node, ast.Attribute):
        return spelling(node.value) + '.' + node.attr
    return '<' + type(node).__name__ + '>'


def python_sites(body, name):
    try:
        encoding, _ = tokenize.detect_encoding(io.BytesIO(body).readline)
        text = body.decode(encoding)
        parsed = ast.parse(body, filename=name)
    except (SyntaxError, UnicodeError, LookupError) as error:
        return dict(encoding=None, parse_error=dict(kind=type(error).__name__, message=str(error)),
                    calls=[], imports=[], definitions=[])
    calls, imports, definitions = [], [], []

    def address(node):
        segment = ast.get_source_segment(text, node)
        assert segment is not None
        return dict(line=node.lineno, column=node.col_offset, end_line=node.end_lineno,
                    end_column=node.end_col_offset, text=prepare.identity(segment.encode('utf-8')))

    class Collector(ast.NodeVisitor):
        def __init__(self):
            self.owners = []

        def definition(self, node):
            label = '.'.join([*self.owners, node.name])
            definitions.append(dict(address(node), kind=type(node).__name__, name=label))
            self.owners.append(node.name)
            self.generic_visit(node)
            self.owners.pop()

        visit_FunctionDef = definition
        visit_AsyncFunctionDef = definition
        visit_ClassDef = definition

        def visit_Call(self, node):
            name = spelling(node.func)
            calls.append(dict(address(node), owner='.'.join(self.owners), callee=name,
                              io_hint=name.rsplit('.', 1)[-1] in IO_HINTS))
            self.generic_visit(node)

        def imported(self, node):
            imports.append(dict(address(node), owner='.'.join(self.owners), kind=type(node).__name__,
                                module=getattr(node, 'module', None), level=getattr(node, 'level', 0),
                                names=[dict(name=item.name, alias=item.asname) for item in node.names]))
            self.generic_visit(node)

        visit_Import = imported
        visit_ImportFrom = imported

    Collector().visit(parsed)
    key = lambda row: (row['line'], row['column'], row['end_line'], row['end_column'])
    calls.sort(key=key)
    imports.sort(key=key)
    definitions.sort(key=key)
    # Independent traversal detects collector omissions; parser semantics remain
    # the declared standard-library premise, not an oracle for actual effects.
    wanted_calls = sorted((address(node) for node in ast.walk(parsed) if isinstance(node, ast.Call)), key=key)
    assert [{field: row[field] for field in wanted_calls[0]} for row in calls] == wanted_calls if calls else not wanted_calls
    wanted_imports = sorted((address(node) for node in ast.walk(parsed)
                             if isinstance(node, (ast.Import, ast.ImportFrom))), key=key)
    assert [{field: row[field] for field in wanted_imports[0]} for row in imports] == wanted_imports if imports else not wanted_imports
    return dict(encoding=encoding, parse_error=None, calls=calls, imports=imports, definitions=definitions)


def code_members(members, bodies=None):
    names = {name for name, row in members.items()
             if Path(name).suffix in CODE_SUFFIXES or name.startswith('bin/')
             or row['mode'] == '100755' or name in CONFIGS}
    links = {name for name in names if members[name]['mode'] == '120000'}
    if links:
        raw = epoch.batch(epoch.REVISION, links) if bodies is None else bodies
        for name in links:
            target = raw[name].decode('utf-8')
            assert not target.startswith('/')
            endpoint = posixpath.normpath(str(Path(name).parent / target))
            assert endpoint in members and members[endpoint]['mode'] in ('100644', '100755')
            names.add(endpoint)
    return sorted(names)


def build():
    selection = selected_checkout.selection()
    raw_tree, members = epoch.tree(epoch.REVISION)
    assert raw_tree == prepare.unblob(selection['tree'])
    names = code_members(members)
    assert sum(members[name]['bytes'] for name in names) <= MAX_CODE_BYTES
    bodies = epoch.batch(epoch.REVISION, names)
    entries = {row['command'][-1] for label, row in selection['commands'].items()
               if label in selection['roles']['historical']}
    records = {}
    for name in names:
        body, mode = bodies[name], members[name]['mode']
        assert len(body) == members[name]['bytes']
        roles = ['declared_source_member'] if name in selection['required_members'] else []
        roles += ['formal:' + role for role, values in selection['formal_programmes'].items() if name in values]
        if name in selection['imports']:
            roles.append('factory_import')
        if name in entries:
            roles.append('historical_entry_candidate')
        first = body.split(b'\n', 1)[0]
        python = mode != '120000' and (name.endswith('.py') or (first.startswith(b'#!') and b'python' in first))
        line_starts = [0] + [index + 1 for index, value in enumerate(body) if value == 10 and index + 1 < len(body)]
        records[name] = dict(source=prepare.blob(body), mode=mode, roles=sorted(roles),
                             language='python' if python else 'symlink' if mode == '120000' else 'opaque_code',
                             raw_lf_line_starts=line_starts,
                             sites=python_sites(body, name) if python else None)
    census = dict(source_members=len(members), code_members=len(records),
                  code_bytes=sum(row['source']['bytes'] for row in records.values()),
                  python_members=sum(row['language'] == 'python' for row in records.values()),
                  parse_failures=sum(row['sites'] is not None and row['sites']['parse_error'] is not None for row in records.values()),
                  calls=sum(len(row['sites']['calls']) for row in records.values() if row['sites']),
                  imports=sum(len(row['sites']['imports']) for row in records.values() if row['sites']))
    return dict(schema='fsmgen.fixed_runtime_source_site_inventory.v1', revision=epoch.REVISION,
                selection=prepare.identity(execute.read(epoch.PATH)), full_tree=prepare.blob(raw_tree),
                members=members, commands=selection['commands'], source_graphs=selection['source_graphs'],
                formal_programmes=selection['formal_programmes'], records=records, census=census,
                coordinate_contract='Python AST UTF-8 columns in decoded source; source text digests use UTF-8. Original encoded bytes remain separate. Other code uses raw LF byte-line starts.',
                runtime_permission=False, reachability_qualified=False, scope=SCOPE)


def validate(value, expected):
    assert type(value.get('runtime_permission')) is bool and value['runtime_permission'] is False
    assert type(value.get('reachability_qualified')) is bool and value['reachability_qualified'] is False
    assert prepare.encoded(value) == prepare.encoded(expected), 'complete fixed input/source/site/type/scope inventory'
    return True


def controls(value):
    outcomes = []
    python = next(name for name, row in value['records'].items() if row['sites'] and row['sites']['calls'])
    for label in ('missing_source', 'extra_source', 'source_bytes', 'source_mode', 'missing_site', 'coordinate', 'role', 'kind', 'permission'):
        bad = copy.deepcopy(value)
        if label == 'missing_source': del bad['records'][python]
        elif label == 'extra_source': bad['records']['undeclared.py'] = bad['records'][python]
        elif label == 'source_bytes': bad['records'][python]['source'] = prepare.blob(b'changed source')
        elif label == 'source_mode': bad['records'][python]['mode'] = '100755' if bad['records'][python]['mode'] != '100755' else '100644'
        elif label == 'missing_site': bad['records'][python]['sites']['calls'].pop()
        elif label == 'coordinate': bad['records'][python]['sites']['calls'][0]['column'] += 1
        elif label == 'role': bad['records'][python]['roles'].append('executed')
        elif label == 'kind': bad['census']['source_members'] = float(bad['census']['source_members'])
        else: bad['runtime_permission'] = True
        try:
            validate(bad, value)
        except AssertionError:
            outcomes.append(label)
        else:
            raise AssertionError('invalid candidate inventory admitted: ' + label)
    return outcomes


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--write', action='store_true')
    args = parser.parse_args()
    if args.write:
        assert not execute.safe(PATH).exists() and not execute.safe(CONTROLS).exists()
    expected = build()
    value = expected if args.write else json.loads(gzip.decompress(execute.read(PATH)))
    assert validate(value, expected)
    outcomes = controls(value)
    if args.write:
        execute.save(PATH, value)
        execute.save(CONTROLS, dict(outcomes=outcomes, programme=prepare.blob(Path(__file__).read_bytes()),
                                   parser=sys.version, scope='Candidate/site completeness and genuine corruption controls only; no runtime permission or reachability claim.'))
    print('Complete fixed source/static-site candidate inventory and genuine refusal controls pass; runtime execution/data roles remain unresolved.')
