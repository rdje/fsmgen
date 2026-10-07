"""Own source spans before public line selection or original-coordinate intake."""
import argparse
import ast
import copy
import hashlib
import json
import re
import subprocess
from pathlib import Path

BASE = Path('docs/audits/record-value-coordinate-source-catalog-20261007')
CAPTURE = Path('docs/audits/record-value-original-candidate-20261004')
REVISION = 'ac6fa991addfc1537603a4d7fd023b69a048c692'
OWNER = 'SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.4.3.3.5.2.1.5.2.2.3.1.2.1.3.1.2.3.2.3.3.3.3.2.3.2.3.3.2.3.2.2.3.2.2.1'
UNITS = {
    'value': 'perl/FSM/Support/ISFRecordPortValues.pm',
    'metadata': 'perl/FSM/Support/ISFInterfacePortMetadata.pm',
    'context': 'perl/FSM/Support/ISFRecordPortContexts.pm',
    'parser': 'perl/FSM/Adapter/ISF/Parser.pm',
    'facade': 'perl/FSM/Adapter/ISF.pm',
    'test': 't/1986-isf-record-port-value-gates.t',
    'observer': str(CAPTURE / 'observe.pl'),
}
MODELS = {
    'value': Path('docs/audits/record-value-original-value-frames-20261005/frame_model.py'),
    'metadata': Path('docs/audits/record-value-original-metadata-frames-20261005/frame_model.py'),
}
OBSERVER_RECIPES = Path('docs/audits/record-value-original-observer-sources-20261005/proofs.json')
PARSER_INVENTORY = Path('docs/audits/record-value-original-parser-sources-20261005/proofs.json')
ORIGIN_DECLARATIONS = Path('docs/audits/record-value-original-class-20261005/verify.py')
OBSERVER_DECLARATIONS = Path('docs/audits/record-value-original-observer-sources-20261005/recipes.py')
ROLE = ('Complete own lexical source spans and generated-observer/invocation custody only. '
        'Runtime call-site line selection, original raw coordinates, private framework and '
        'original formatter/toolchain identity are not established by this catalog.')
SUCCESS = 'PASS complete independently derived own source span catalog and genuine controls; public line selection and original-coordinate join remain pending.\n'


def require(condition, cause):
    if not condition:
        raise ValueError(cause)


def same(left, right):
    return json.dumps(left, sort_keys=True) == json.dumps(right, sort_keys=True)


def identity(raw):
    return dict(bytes=len(raw), sha256=hashlib.sha256(raw).hexdigest())


def git(path, revision=REVISION):
    return subprocess.check_output(['git', 'show', revision + ':' + str(path)])


def load(path):
    return json.loads(path.read_bytes())


def module(path):
    namespace = {'__name__': 'coordinate_source_declaration'}
    exec(compile(git(path), str(path), 'exec'), namespace)
    return namespace


def literal(path, name):
    matches = [node.value for node in ast.parse(git(path)).body
               if isinstance(node, ast.Assign)
               and any(isinstance(target, ast.Name) and target.id == name for target in node.targets)]
    require(len(matches) == 1, 'unique committed literal declaration')
    return ast.literal_eval(matches[0])


def inputs():
    """Select source/recipe fields; no original error/frame coordinate is read."""
    binding = json.loads(git(CAPTURE / 'binding.json'))
    original = binding['sources']
    units = {}
    for unit, path in UNITS.items():
        raw = git(path) if unit == 'observer' else original[path]['body'].encode()
        if unit != 'observer':
            require(same(original[path], dict(body=raw.decode(), **identity(raw)))
                    and raw == git(path, binding['original_revision']),
                    'whole independently committed original own source')
        units[unit] = dict(path=path, body=raw.decode(), identity=identity(raw))
    transform = json.loads(git(CAPTURE / 'observer-transform.json'))
    source = git(transform['source_path'], binding['revision']).decode()
    require(source == transform['before'], 'whole observer generator committed beforeimage')
    for before, after in transform['replacements']:
        require(source.count(before) == 1, 'unique ordered observer generation replacement')
        source = source.replace(before, after)
    require(source == transform['after'] == units['observer']['body'],
            'whole ordered generated observer source')
    execution = json.loads(git(CAPTURE / 'execution.json'))
    modes = []
    expected_sources = {**binding['runtime'], **binding['sources'], **binding['support'],
                        **{str(CAPTURE / name): row for name, row in execution['programs'].items()}}
    for row in execution['modes']:
        pins = {path: {key: value[key] for key in ('bytes', 'sha256')}
                for path, value in expected_sources.items()}
        require(same(row['sources_before'], pins) and same(row['sources_after'], pins),
                'complete original invocation source fixture conservation')
        modes.append({key: row[key] for key in ('mode', 'fixture', 'same_volume', 'command')})
    require([r['mode'] for r in modes] == ['ordinary', 'storable', 'alias', 'controls'],
            'complete source-generated invocation mode domain')
    # These two inventories are qualified source projections. Their native
    # comparison products and raw fields are deliberately not selected here.
    observer = json.loads(git(OBSERVER_RECIPES))['source_recipes']
    parser = json.loads(git(PARSER_INVENTORY))['inventory']
    declarations = {unit: {key: module(path)[key] for key in ('GUARDS', 'CALLS')}
                    for unit, path in MODELS.items()}
    return dict(units=units, observer=observer, parser=parser,
                declarations=declarations, transform=transform, modes=modes,
                origins=literal(ORIGIN_DECLARATIONS, 'GUARDS'),
                observer_statements=literal(OBSERVER_DECLARATIONS, 'STATEMENTS'),
                generator=dict(path=str(CAPTURE / 'capture.py'), body=git(CAPTURE / 'capture.py').decode()),
                source_authority=dict(capture_revision=binding['revision'],
                    original_revision=binding['original_revision']), role=ROLE)


def span(body, text, offset=0):
    """Literal UTF-8 range and source lines, without selecting a runtime line."""
    require(body.count(text) == 1 and text, 'unique complete source span')
    start = body.index(text)
    prefix = body[:start]
    return dict(offset_bytes=offset + len(prefix.encode()), bytes=len(text.encode()),
                start_line=prefix.count('\n') + 1,
                end_line=(prefix + text.rstrip('\n')).count('\n') + 1,
                text=text, identity=identity(text.encode()))


def derive(source):
    require(set(source['units']) == set(UNITS) and source['role'] == ROLE,
            'complete own source unit and catalog scope domain')
    result = {}
    for unit, row in source['units'].items():
        body = row['body']
        require(row['path'] == UNITS[unit] and same(row['identity'], identity(body.encode())),
                'whole source unit path/body identity')
        require(not re.search(r'^\s*#\s*line\b', body, re.M),
                'own source has no line filename remapping directive')
        # The pinned own sources contain both whole single-line predicates
        # and bodies ending at a column-zero closing brace. This finite
        # scanner is checked against every declaration; it is not a general
        # Perl parser and cannot silently omit another authored form.
        functions = list(re.finditer(
            r'^sub ([A-Za-z_]\w*)[^\n]*?\{(?:[^\n]*\}$|\n.*?^})',
            body, re.M | re.S))
        require([m[1] for m in functions] == re.findall(r'^sub ([A-Za-z_]\w*)', body, re.M),
                'complete finite own named function lexical bodies')
        require(len({m[1] for m in functions}) == len(functions),
                'unique own named function lexical owner')
        named = [dict(name=m[1], **span(body, m[0])) for m in functions]
        selected = []
        if unit in source['declarations']:
            for family, declarations in source['declarations'][unit].items():
                for key, statement in declarations.items():
                    located = span(body, statement)
                    owners = [m[1] for m in functions if m.start() <= body.index(statement) < m.end()]
                    require(len(owners) == 1, 'unique guard/call named lexical owner')
                    selected.append(dict(role=family + '.' + key, owner=owners[0], **located))
        result[unit] = dict(path=row['path'], identity=row['identity'], named=named,
                            guard_calls=selected)
    observer = source['observer']
    for unit in ('observer', 'test'):
        require(observer['source_units'][unit]['body'] == source['units'][unit]['body'],
                'whole qualified observer/test source cohort')
    extras = []
    for unit, (path, prefix, statement) in source['origins'].items():
        require(source['units'][unit]['path'] == path, 'source origin family path')
        extras.append(dict(unit=unit, role='confess_origin', prefix=prefix,
                           **span(source['units'][unit]['body'], statement)))
    for role, rows in (('installed_wrapper', observer['wrappers']),
                       ('observer_function', observer['observer_functions']),
                       ('test_function', observer['test_functions'])):
        unit = 'test' if role == 'test_function' else 'observer'
        for row in rows:
            extras.append(dict(unit=unit, role=role, name=row['name'],
                               **span(source['units'][unit]['body'], row['body'])))
    extras.append(dict(unit='observer', role='compiled_helper_wrapper',
        **span(source['units']['observer']['body'], observer['compiled_helper_wrapper'])))
    for row in observer['callbacks']:
        require(type(row['index']) is int and row['index'] >= 0,
                'source callback integer allocation')
        extras.append(dict(unit='test', role='helper_callback', index=row['index'],
            name=row['subtest'], **span(source['units']['test']['body'], row['source_statement'])))
    test = source['units']['test']['body']
    bodies = list(re.finditer(r"^subtest '([^']+)' => sub \{\n.*?^};", test, re.M | re.S))
    require([m[1] for m in bodies] == [r['name'] for r in observer['subtests']],
            'complete qualified named subtest body membership')
    for match in bodies:
        extras.append(dict(unit='test', role='named_subtest_body', name=match[1],
                           **span(test, match[0])))
    for role, statement in source['observer_statements'].items():
        unit = 'test' if role.startswith('helper_') and role not in ('helper_parameters', 'helper_active_scope') else 'observer'
        extras.append(dict(unit=unit, role='qualified_statement.' + role,
                           **span(source['units'][unit]['body'], statement)))
    for unit, row in source['parser']['source_units'].items():
        require(unit in ('facade', 'parser', 'contexts'), 'qualified parser source unit')
        key = 'context' if unit == 'contexts' else unit
        require(row['body'] == source['units'][key]['body'], 'whole qualified parser source cohort')
    for row in source['parser']['functions']:
        unit = 'context' if row['unit'] == 'contexts' else row['unit']
        extras.append(dict(unit=unit, role='parser_function', name=row['name'],
                           **span(source['units'][unit]['body'], row['body'])))
    for row in source['modes']:
        require(type(row['same_volume']) is bool and row['same_volume'],
                'source invocation genuine same-volume Boolean')
        fixture = Path(row['fixture'])
        require(not fixture.is_absolute() and '..' not in fixture.parts
                and fixture.parent == Path('.artifacts/record-value-original-candidate-20261004')
                and fixture.name.startswith(row['mode'] + '-'), 'legitimate original invocation root recipe')
        require(row['command'] == ['perl', UNITS['observer'], row['mode'],
                str(CAPTURE / (row['mode'] + '.json'))], 'exact original invocation command recipe')
    require('cwd=fixture' in source['generator']['body']
            and 'dir=scratch' in source['generator']['body']
            and "scratch = Path('.artifacts/record-value-original-candidate-20261004')" in source['generator']['body'],
            'complete source-declared fixture-root invocation recipe')
    regenerated = source['transform']['before']
    for before, after in source['transform']['replacements']:
        require(regenerated.count(before) == 1, 'unique ordered observer generation replacement')
        regenerated = regenerated.replace(before, after)
    require(regenerated == source['transform']['after'] == source['units']['observer']['body'],
            'whole ordered generated observer source')
    return dict(units=result, qualified_lexical_spans=extras, invocations=source['modes'],
                generated_observer=identity(regenerated.encode()), role=ROLE)


def check(candidate, source, expected):
    rebuilt = derive(source)
    require(same(rebuilt, expected), 'complete independent source catalog reconstruction')
    require(same(candidate, expected), 'whole own lexical source span catalog and integer kinds')


def controls(source, expected):
    mutations = [
        ('wrong-line', lambda c,s: c['units']['value']['guard_calls'][0].update(start_line=999999), 'whole own lexical source span catalog and integer kinds'),
        ('Boolean-line', lambda c,s: c['units']['value']['guard_calls'][0].update(start_line=True), 'whole own lexical source span catalog and integer kinds'),
        ('wrong-owner', lambda c,s: c['units']['value']['guard_calls'][0].update(owner='borrowed'), 'whole own lexical source span catalog and integer kinds'),
        ('lost-call', lambda c,s: c['units']['metadata']['guard_calls'].pop(), 'whole own lexical source span catalog and integer kinds'),
        ('borrowed-source', lambda c,s: s['units']['value'].update(body=s['units']['metadata']['body']), 'whole source unit path/body identity'),
        ('duplicate-statement', lambda c,s: duplicate(s), 'unique complete source span'),
        ('changed-generation', lambda c,s: s['transform']['replacements'][0].__setitem__(1,'borrowed'), 'unique ordered observer generation replacement'),
        ('foreign-root', lambda c,s: s['modes'][0].update(fixture='../foreign/ordinary-root'), 'legitimate original invocation root recipe'),
        ('Boolean-root-proof', lambda c,s: s['modes'][0].update(same_volume=1), 'source invocation genuine same-volume Boolean'),
        ('borrowed-command', lambda c,s: s['modes'][0]['command'].__setitem__(1,'borrowed.pl'), 'exact original invocation command recipe'),
        ('runtime-coordinate-promotion', lambda c,s: c.update(role='All original coordinate meanings are measured.'), 'whole own lexical source span catalog and integer kinds'),
    ]
    result = []
    for name, mutate, cause in mutations:
        candidate, changed = copy.deepcopy(expected), copy.deepcopy(source)
        mutate(candidate, changed)
        require(not same(candidate, expected) or not same(changed, source), 'genuine catalog control')
        try:
            check(candidate, changed, expected)
        except ValueError as error:
            require(str(error) == cause, 'intended source catalog control: ' + name + ': ' + str(error))
            result.append(dict(control=name, status=1, cause=cause))
        else:
            raise ValueError('false-green source catalog control: ' + name)
    return result


def duplicate(source):
    row = source['units']['value']
    text = next(iter(source['declarations']['value']['GUARDS'].values()))
    row['body'] += '\n' + text + '\n'
    row['identity'] = identity(row['body'].encode())


def members():
    require(all(p.is_file() and not p.is_symlink() for p in BASE.iterdir()), 'complete regular catalog members')
    return {p.name: identity(p.read_bytes()) for p in BASE.iterdir() if p.name != 'manifest.json'}


def save(name, value):
    path = BASE / name
    if path.exists():
        require(same(load(path), value), 'whole retained catalog product: ' + name)
    else:
        require(not (BASE / 'manifest.json').exists(), 'sealed catalog cannot publish')
        path.write_text(json.dumps(value, sort_keys=True, indent=2) + '\n')


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--seal', action='store_true')
    args = parser.parse_args()
    if (BASE / 'manifest.json').exists():
        require(same(load(BASE / 'manifest.json'), members()), 'whole immutable source catalog seal')
    source = inputs()
    save('inputs.json', source)
    expected = derive(source)
    save('catalog.json', expected)
    check(expected, source, expected)
    save('controls.json', controls(source, expected))
    if args.seal:
        save('manifest.json', members())
    print(SUCCESS, end='')


if __name__ == '__main__':
    main()
