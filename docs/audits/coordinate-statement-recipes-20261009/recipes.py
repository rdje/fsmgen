"""Finite own-source statements; never execute producers or inspect raw traces.

The admitted bank remains lexical evidence. This product adds executable
statement boundaries, without selecting a runtime line or filename alternative.
"""
import hashlib
import json
import re
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
BASE = Path('docs/audits/coordinate-statement-recipes-20261009')
REVISION = '663489aa0a15bfde83c3dfc137fde65c5cd3952a'
BANK = Path('docs/audits/coordinate-source-sites-20261008')
PATHS = Path('docs/audits/coordinate-refusal-path-inputs-20261009')
ADMISSION = Path('docs/audits/coordinate-source-admission-20261008/proof.json')
ROLE = 'Finite complete own-source statement alternatives; ordered refusal binding and original coordinate selections remain successor-owned.'


def need(ok, cause):
    if not ok:
        raise ValueError(cause)


def pin(raw):
    return {'bytes': len(raw), 'sha256': hashlib.sha256(raw).hexdigest()}


def fixed(path):
    result = subprocess.run(['git', '--no-replace-objects', 'show', REVISION + ':' + str(path)],
                            cwd=ROOT, capture_output=True)
    need(result.returncode == 0 and not result.stderr, 'complete fixed own-source input')
    live = ROOT / path
    need(live.is_file() and not live.is_symlink() and live.stat().st_dev == ROOT.stat().st_dev
         and live.read_bytes() == result.stdout, 'unchanged regular same-volume own input')
    for parent in live.parents:
        if parent == ROOT:
            break
        need(not parent.is_symlink() and not (parent / '.git').exists(), 'own plain input ancestry')
    return result.stdout


def inputs():
    authorities = {}
    for folder in (BANK, PATHS):
        raw = fixed(folder / 'seal.json')
        authorities[str(folder / 'seal.json')] = pin(raw)
        members = json.loads(raw)
        need({p.name for p in (ROOT / folder).iterdir()} == set(members) | {'seal.json'},
             'complete sealed input member domain')
        for name, identity in members.items():
            need(pin(fixed(folder / name)) == identity, 'whole sealed source input identity')
    raw = fixed(ADMISSION)
    authorities[str(ADMISSION)] = pin(raw)
    return (json.loads(fixed(BANK / 'sites.json')), json.loads(fixed(PATHS / 'paths.json')),
            json.loads(raw)['inputs']['source'], authorities)


def derive(bank, paths, source, authorities):
    sites = {s['id']: s for s in bank['sites']}
    owner = (ROOT / BASE / 'scope.txt').read_text().strip()
    need(owner == paths['unresolved']['statement_hypotheses'] + '.1', 'exact statement recipe owner')
    result = []

    def add(key, site, text, kind='statement'):
        whole = source['units'][site['unit']]['body'].encode()
        span = site['span']
        container = whole[span['offset_bytes']:span['offset_bytes'] + span['bytes']]
        raw = text.encode()
        need(container.count(raw) == 1, 'unique complete statement in qualified container: ' + key)
        start = span['offset_bytes'] + container.index(raw)
        first = whole[:start].count(b'\n') + 1
        closing = whole[:start + len(raw.rstrip(b'\n'))].count(b'\n') + 1
        result.append({'id': key, 'container': site['id'], 'unit': site['unit'], 'kind': kind,
                       'source_path': site['source_path'], 'source_identity': pin(whole),
                       'lexical_owner': site['lexical_owner'], 'offset_bytes': start,
                       'text': text, 'identity': pin(raw),
                       'line_alternatives': {'first': first, 'closing': closing},
                       'equivalent_line_labels': [['first', 'closing']] if first == closing else [],
                       'filename_alternatives': site['filename_alternatives'], 'original_selection': None})

    def exact(key, container, text):
        add(key, sites[container], text)

    # Retain all admitted statements, distinguishing a statement sequence and
    # the parser's deliberately lexical (incomplete) confess-expression span.
    for site in bank['sites']:
        if site['kind'] != 'statement':
            continue
        if site['id'] == 'qualified/3':
            continue
        kind = 'statement_sequence' if site['role'] == 'qualified_statement.test_error_capture' else 'statement'
        add('admitted/' + site['id'], site, site['span']['text'], kind)

    for name in ('scope_for', 'reference', 'copy'):
        site = sites['named/test/' + name]
        matches = re.findall(r'^    (return .*?;)\n}', site['span']['text'], re.M | re.S)
        need(len(matches) == 1, 'complete finite named helper return')
        add('helper-return/' + name, site, matches[0])

    for site in bank['sites']:
        if site['role'] == 'helper_callback':
            match = re.fullmatch(r'refuses\(sub \{\s*(.*?)\s*\},\s*(?:qr/|\$).*',
                                 site['span']['text'], re.S)
            need(match is not None, 'whole finite parameterless callback syntax')
            add('callback/' + str(site['span']['index']), site, match[1], 'callback_expression')
            add('helper-invocation/' + str(site['span']['index']), site, site['span']['text'])
        elif site['role'] == 'named_subtest_body':
            add('subtest-invocation/' + site['span']['name'], site, site['span']['text'])
        elif site['role'] == 'installed_wrapper':
            matches = re.findall(r'^\s*(return (?:call_api|parse|copy_value)\([^\n]+;)$',
                                 site['span']['text'], re.M)
            for index, text in enumerate(matches):
                add('wrapper-delegate/' + site['span']['name'] + '/' + str(index), site, text)

    for name in ('call_api', 'parse'):
        exact('observer-operation/' + name, 'named/observer/' + name, '$result = $operation->(@args);')
        text = '$ok = eval {$result = $operation->(@args); 1};'
        exact('observer-eval/' + name, 'named/observer/' + name, ('my ' if name == 'parse' else '') + text)

    exact('value-capture', 'named/value/_validate_type',
          "capture_interface_port_metadata({inputs => [{name => 'value', type => 'resolved_value',\n"
          '            width => $checked->{width}, type_spec => $checked}], outputs => []});')
    exact('value-capture-eval', 'named/value/_validate_type',
          "my $ok = eval {\n        capture_interface_port_metadata({inputs => [{name => 'value', type => 'resolved_value',\n"
          '            width => $checked->{width}, type_spec => $checked}], outputs => []});\n        1;\n    };')
    exact('value-capture-guard', 'named/value/_validate_type',
          '_require($ok, "$context has invalid resolved type: $error");')

    entries = [
        ('facade-parse', 'facade', 'parse_source', 'my $result = $self->{parser}->parse_source($source_text, $source_label);'),
        ('parser-build', 'parser', 'parse_source', 'my $result = $self->_build_actor($actor_ast, $source_label);'),
        ('parser-finalize', 'parser', '_build_actor', '$self->_finalize_actor_type_references($result);'),
        ('parser-context', 'parser', '_build_actor', 'validate_actor_record_contexts(actor => $result, whole_output_writes_only => 1)\n        if actor_has_record_port(actor => $result);'),
        ('parser-port', 'parser', '_finalize_actor_type_references', '$self->_resolve_typed_width_entry(\n                $actor,\n                $port,\n                "actor \'$actor_name\' interface port \'$port->{name}\'",\n                allow_record => 1,\n            );'),
        ('context-clauses', 'context', 'validate_actor_record_contexts', '_clauses($tx->{clauses}, $local, $actor, "transaction \'$tx->{name}\'");'),
        ('context-assignment', 'context', '_clauses', '_assignment($clause->[1], $clause->[2], $scope, "$context $head");'),
        ('context-reference', 'context', '_assignment', 'my $to = _reference($target, $scope, \'write\', "$context target");'),
        ('context-write-guard', 'context', '_reference', '_require(!($scope->{whole_output_writes_only} && $access eq \'write\' && $value\n            && $value->{role} eq \'output\' && length($value->{path_text})\n            && _port_root($roots->{$name})),\n        "$context record output field writes are not yet admitted; "\n            . "target \'$token\' requires output-field writer qualification");'),
    ]
    for key, unit, name, text in entries:
        exact(key, 'named/' + unit + '/' + name, text)
    parser_origin = sites['qualified/3']['span']['text']
    exact('parser-confess-statement', 'named/parser/_resolve_typed_width_entry', parser_origin +
          "\n        if $is_aggregate && !$options{allow_aggregate}\n            && !($options{allow_record} && $kind eq 'record');")
    wrapper = sites['qualified/19']['span']['text']
    start = wrapper.index('return $subtest->(')
    end = wrapper.index('}, @args);', start) + len('}, @args);')
    add('saved-subtest-delegate', sites['qualified/19'], wrapper[start:end])

    need(len({s['id'] for s in result}) == len(result), 'unique complete statement recipe domain')
    return {'role': ROLE, 'revision': REVISION, 'owner': owner, 'authorities': authorities,
            'statements': result, 'invocation_custody': pin(json.dumps(paths['invocations'], sort_keys=True).encode()),
            'generation_custody': pin(json.dumps(paths['generation'], sort_keys=True).encode()),
            'public_examples': pin(json.dumps(bank['public_examples'], sort_keys=True).encode()),
            'unresolved': {**paths['unresolved'], 'statement_hypotheses': owner.rsplit('.', 1)[0] + '.2'}}


def main():
    need(Path.cwd().resolve() == ROOT, 'invoke statement recipes from repository root')
    need(not (BASE / 'seal.json').exists(), 'sealed statement producer never reruns')
    product = derive(*inputs())
    (BASE / 'recipes.json').write_text(json.dumps(product, sort_keys=True, indent=2) + '\n')
    print('PASS complete finite own-source statements; phase allocation and original coordinate selection remain pending.')


if __name__ == '__main__':
    main()
