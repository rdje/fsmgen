"""Read-only verifier for the bounded reduction predecessor identity audit.

Run from repository root. This checks retained source-only observations and Git
objects; it never launches a historical test, compiler, simulator or workload.
"""
import copy
import gzip
import hashlib
import json
from pathlib import Path
import re
import subprocess
import sys

BASE = 'f7e4b59687239db8fc0f6e326abb1b4be8d19e0f'
WORK = '.artifacts/tmp/reduction-replay-audit-f7e4b5968-20261022/'
CAP = 'docs/audits/'
WIDTH = CAP + 'unary-reduction-width-foundation-20261021.json'
PARAM = CAP + 'reduction-parameter-scopes-20261022.json.gz'
DOMAIN = CAP + 'domain-static-count-scopes-20261022.json.gz'
METHODS = {
    'FSM/Adapter/FSMGenFull/ExpressionBuilder.pm': ['infer_exact_expression_width'],
    'FSM/ExpressionNamer.pm': ['infer_ast_width'],
    'FSM/HDL/FlattenedDT/Backend/SystemVerilog/IntermediateSignalWidthSupport.pm':
        ['infer_width_from_intermediate_ast'],
    'FSM/Synthesis/EnableGraph/ASTSupport.pm': ['_expression_width'],
}
CLASSIFICATIONS = {
    (DOMAIN, '/predecessor_identity_correction/invalid_command_order/1'): 'documented_invalid_count_order',
    (DOMAIN, '/predecessor_identity_correction/qualified_command_order/0'): 'documented_qualified_count_order',
    (PARAM, '/predecessor_reproduction/2'): 'invalid_count_launch_already_superseded_by_domain_audit',
    (CAP + 'reduction-target-profiles-quiet-red-20261022.json.gz', '/files/2/root_normalized_text'):
        'captured_cli_help_extension_examples_not_predecessor_launch',
    (CAP + 'reduction-target-profiles-quiet-repair-20261022.json.gz', '/files/0/root_normalized_text'):
        'captured_cli_help_extension_examples_not_predecessor_launch',
    (CAP + 'unary-reduction-source-integration-20261022.json.gz', '/retained_inputs_and_epochs/36/path'):
        'before_edit_module_snapshot_not_reconstructed_launch',
    (CAP + 'unary-reduction-source-integration-20261022.json.gz', '/retained_inputs_and_epochs/37/path'):
        'before_edit_generated_text_not_reconstructed_launch',
    (CAP + 'unary-reduction-source-integration-20261022.json.gz', '/retained_inputs_and_epochs/43/text'):
        'archive_producer_references_before_edit_files_not_module_selector',
    (WIDTH, '/final_native_control/wrapper'): 'qualified_strengthened_width_wrapper',
    (WIDTH, '/native_capsule/insertion'): 'width_wrapper_precedence_explanation',
    (WIDTH, '/native_wrapper'): 'qualified_corrected_width_wrapper',
}
SELECTOR = re.compile(r'@INC|PERL5LIB|-I[^\s,\]\"\']*(?:native|predecessor|overlay)|before-scalar-classification|before_scalar')


def require(condition, message):
    if not condition:
        raise ValueError(message)


def digest(data):
    return hashlib.sha256(data).hexdigest()


def git_bytes(revision, path):
    require(re.fullmatch(r'[0-9a-f]{40}', revision) is not None, 'invalid source revision')
    require(path and not path.startswith('/') and '..' not in Path(path).parts, 'invalid source path')
    return subprocess.check_output(['git', 'show', revision + ':' + path])


def original(path):
    raw = git_bytes(BASE, path)
    return json.loads(gzip.decompress(raw) if path.endswith('.gz') else raw)


def source_paths():
    paths = subprocess.check_output(['git', 'ls-tree', '-r', '--name-only', BASE, 'docs/audits'], text=True)
    return [p for p in paths.splitlines() if Path(p).parent == Path('docs/audits')
            and Path(p).suffix in ('.json', '.gz') and ('reduction' in Path(p).name
            or Path(p).name.startswith(('domain-static-count-scopes-', 'intermediate-namespace-')))]


def selector_hits(value, capsule, pointer=''):
    result = []
    if isinstance(value, dict):
        for key, item in value.items():
            result.extend(selector_hits(item, capsule, pointer + '/' + key.replace('~', '~0').replace('/', '~1')))
    elif isinstance(value, list):
        for index, item in enumerate(value):
            result.extend(selector_hits(item, capsule, pointer + '/' + str(index)))
    elif isinstance(value, str):
        matches = [{'line': n, 'text': line} for n, line in enumerate(value.splitlines(), 1) if SELECTOR.search(line)]
        if matches:
            result.append({'capsule': capsule, 'pointer': pointer, 'value_sha256': digest(value.encode()), 'matches': matches})
    return result


def verify(data):
    require(data['base_revision'] == BASE and data['owner'] == 'ISF-REDUCTION-DELIVERY.10', 'wrong audit owner/base')
    require(data['verifier_sha256'] == digest(Path(__file__).read_bytes()), 'verifier bytes differ')
    files = data['files']
    for path, row in files.items():
        encoded = row['text'].encode()
        require(digest(encoded) == row['normalized_sha256'], 'retained artifact text/hash differs')
        if row['normalization'] == 'none':
            require((len(encoded), digest(encoded)) == (row['raw_bytes'], row['raw_sha256']),
                    'unnormalized artifact bytes/hash differ')
        else:
            require(row['normalization'] == 'external_perl_lookup_directories', 'unknown normalization')

    def text(name):
        return files[WORK + name]['text']

    def product(name):
        return json.loads(text(name))

    inventory = product('inventory-v2.json')
    expected_paths = source_paths()
    require([row['path'] for row in inventory['capsules']] == expected_paths, 'incomplete capsule allocation/order')
    hits = []
    for row in inventory['capsules']:
        raw = git_bytes(BASE, row['path'])
        require((len(raw), digest(raw)) == (row['bytes'], row['sha256']), 'capsule bytes/hash mismatch')
        require(subprocess.check_output(['git', 'rev-parse', BASE + ':' + row['path']], text=True).strip()
                == row['git_blob'], 'capsule Git object mismatch')
        require(Path(row['path']).read_bytes() == raw, 'original capsule changed')
        hits.extend(selector_hits(original(row['path']), row['path']))
    require(inventory['selector_hits'] == hits, 'incomplete decoded selector census')
    require({(h['capsule'], h['pointer']) for h in hits} == set(CLASSIFICATIONS), 'unclassified selector')
    require(data['classifications'] == [dict(capsule=h['capsule'], pointer=h['pointer'],
            classification=CLASSIFICATIONS[(h['capsule'], h['pointer'])]) for h in hits], 'classification drift')

    width = original(WIDTH)
    meta = width['native_capsule']
    insertion = "BEGIN { unshift @INC, '.artifacts/tmp/reduction-width-foundation-20261021/native'; }\n"
    for field, wrapper_file, original_hash, body_hash in (
        ('native_wrapper', 'width-old.t', meta['native_wrapper_sha256'], meta['current_test_sha256']),
        ('final_native_control', 'width-final-old.t', width['final_native_control']['wrapper_sha256'],
         width['final_native_control']['test_sha256']),
    ):
        wrapper = width[field] if field == 'native_wrapper' else width[field]['wrapper']
        require(digest(wrapper.encode()) == original_hash and wrapper.count(insertion) == 1, 'wrapper source identity')
        require(digest(wrapper.replace(insertion, '').encode()) == body_hash, 'assertion body changed')
        require(text(wrapper_file) == wrapper.replace('.artifacts/tmp/reduction-width-foundation-20261021/native',
                WORK + 'width-native'), 'relocated wrapper differs beyond its library path')
    require(text('width-current.t') == width['native_wrapper'].replace(insertion, ''), 'root-first control body changed')

    def binding_errors(observed, expectations, methods):
        errors = []
        actual = {row['inc_key']: row for row in observed['targets']}
        if set(actual) != set(expectations):
            return ['target allocation differs']
        for key, expected in expectations.items():
            row = actual[key]
            if row['loaded'] != expected:
                errors.append(key + ' INC binding')
            if [method['name'] for method in row['methods']] != methods[key]:
                errors.append(key + ' method allocation')
            for method in row['methods']:
                if method.get('compiled_source') != expected:
                    errors.append(key + ' compiled method ' + method['name'])
            if observed['all_FSM_modules'].get(key) != expected:
                errors.append(key + ' footprint binding')
        return errors

    old = {}; current = {}
    for path, row in meta['modules'].items():
        raw = git_bytes(meta['revision'], path)
        require((len(raw), digest(raw)) == (row['bytes'], row['sha256']), 'width predecessor payload differs')
        key = path.removeprefix('perl/')
        old[key] = {'path': WORK + 'width-native/' + key, 'sha256': row['sha256']}
        current[key] = {'path': path, 'sha256': digest(git_bytes(BASE, path))}
    for label in ('old', 'final-old'):
        run = product(label + '-width-run.json'); observation = product(label + '-identity.json')
        require(not binding_errors(observation, old, METHODS), 'width predecessor binding failed')
        require(run['exit_status'] == 4, 'unexpected old private-test status')
        require(re.findall(r'^not ok ([0-9]+) -', run['stdout'], re.M) == ['1', '2', '3', '4'], 'old semantic failure groups differ')
        require(re.search(r'^ok 5 -', run['stdout'], re.M) is not None and run['stdout'].rstrip().endswith('1..5'), 'old control/plan missing')
        require("got: '8'" in run['stderr'] and "expected: '1'" in run['stderr'], 'independent old width mismatch absent')
        require(not re.search(r'Compilation failed|Can.t locate|Undefined subroutine|observer failed', run['stderr']), 'harness/import error mistaken for semantic RED')
        for key, row in observation['all_FSM_modules'].items():
            expected = old[key] if key in old else {'path': 'perl/' + key, 'sha256': digest(git_bytes(BASE, 'perl/' + key))}
            require(row == expected, 'undeclared mixed width dependency')
    control = product('root-first-control-width-run.json'); observed = product('root-first-control-identity.json')
    require(not binding_errors(observed, current, METHODS), 'current width control source differs')
    require(binding_errors(observed, old, METHODS), 'root-first control falsely accepted as old')
    require(control['exit_status'] == 1 and re.findall(r'^not ok ([0-9]+) -', control['stdout'], re.M) == ['5'], 'obsolete arity control cause differs')
    require(all(re.search(r'^ok ' + str(n) + r' -', control['stdout'], re.M) for n in range(1, 5)), 'current width groups do not pass')
    require('unary source admission remains closed' in control['stderr'] and 'requires at least 2 operands' in control['stderr'], 'later source-admission boundary not distinguished')

    for label, capsule, field in (('c51', original(PARAM), 'predecessor_modules'), ('300b', original(DOMAIN), 'base_modules')):
        revision = capsule['base_revision']
        for row in capsule[field]:
            raw = git_bytes(revision, row['path'])
            require(digest(raw) == row['sha256'] and raw.decode() == row['utf8'], 'prepared old module payload differs')
            require(subprocess.check_output(['git', 'rev-parse', revision + ':' + row['path']], text=True).strip()
                    == row['git_blob'], 'prepared old Git blob differs')
        config = product('count-' + label + '-config.json')
        observed = product('count-' + label + '-identity.json'); run = product('count-' + label + '-run.json')
        require(run['exit_status'] == 0 and run['stderr'] == '', 'count source-only load failed')
        expectations = {'FSM/Scheduler/ISF/LoweringIR.pm': {'path': WORK + 'count-' + label + '/perl/FSM/Scheduler/ISF/LoweringIR.pm',
            'sha256': digest(git_bytes(revision, 'perl/FSM/Scheduler/ISF/LoweringIR.pm'))}}
        methods = {'FSM/Scheduler/ISF/LoweringIR.pm': ['build_module', '_validate_transaction_clause_domain_refs']}
        require(not binding_errors(observed, expectations, methods), 'old count compiled identity differs')
        for key, row in observed['all_FSM_modules'].items():
            require(row == {'path': WORK + 'count-' + label + '/perl/' + key,
                    'sha256': digest(git_bytes(revision, 'perl/' + key))}, 'count dependency is not coherent historical source')
        require(config['revision'] == revision, 'count source manifest revision differs')
    count_control = product('count-root-first-identity.json')
    current_lowerer = {'FSM/Scheduler/ISF/LoweringIR.pm': {'path': 'perl/FSM/Scheduler/ISF/LoweringIR.pm',
        'sha256': digest(git_bytes(BASE, 'perl/FSM/Scheduler/ISF/LoweringIR.pm'))}}
    methods = {'FSM/Scheduler/ISF/LoweringIR.pm': ['build_module', '_validate_transaction_clause_domain_refs']}
    require(not binding_errors(count_control, current_lowerer, methods), 'root-first count current binding differs')
    require(product('count-root-first-run.json')['exit_status'] == 0, 'count identity control did not settle')
    prior_lowerer = next(row for row in original(PARAM)['predecessor_modules']
                         if row['path'] == 'perl/FSM/Scheduler/ISF/LoweringIR.pm')
    require(count_control['targets'][0]['loaded']['sha256'] != prior_lowerer['sha256'], 'root-first count accepted as predecessor')
    correction = original(DOMAIN)['predecessor_identity_correction']
    require(correction['invalid_command_order'] == ['-Iperl', '-Ioverlay', '-MFSM::Scheduler::ISF::LoweringIR']
            and correction['qualified_command_order'] == ['-Ioverlay', '-Iperl', '-MFSM::Scheduler::ISF::LoweringIR'], 'retained correction drift')
    require(original(PARAM)['predecessor_reproduction'][1].startswith('-Iperl'), 'original invalid launch is not retained')
    return {'capsules': len(expected_paths), 'classified_selector_fields': len(hits),
            'scope': 'Declared retained source/private replays and named module identities; full original environment/footprints remain unrecorded. No HDL/runtime replay.'}


def rewrite(value, name, changed):
    """Keep a counterfactual internally hash-consistent before checking semantics."""
    row = value['files'][WORK + name]
    row['text'] = changed
    row['raw_bytes'] = len(changed.encode())
    row['raw_sha256'] = row['normalized_sha256'] = digest(changed.encode())
    row['normalization'] = 'none'


def main():
    path = Path(sys.argv[1] if len(sys.argv) == 2 else 'docs/audits/reduction-replay-identity-20261022.json.gz')
    require(len(sys.argv) <= 2 and not path.is_absolute() and '..' not in path.parts, 'use a repository-relative receipt path')
    data = json.loads(gzip.decompress(path.read_bytes()))
    result = verify(data)
    for mutate in (
        lambda value: rewrite(value, 'inventory-v2.json', json.dumps(dict(
            json.loads(value['files'][WORK + 'inventory-v2.json']['text']), capsules=[]))),
        lambda value: value['classifications'].pop(),
        lambda value: rewrite(value, 'old-identity.json',
            value['files'][WORK + 'old-identity.json']['text'].replace('afc3d5d3b5bbee93cd82e93c30de110c7dc61b337d503014855b95ca3e970376', '0' * 64)),
    ):
        bad = copy.deepcopy(data); mutate(bad)
        try:
            verify(bad)
        except (ValueError, KeyError, AssertionError):
            continue
        raise ValueError('hostile receipt mutation was accepted')
    print('replay-identity: complete frozen capsule census, compiled/Git source joins and hostile controls verified')
    print(json.dumps(result, sort_keys=True))


if __name__ == '__main__':
    main()
