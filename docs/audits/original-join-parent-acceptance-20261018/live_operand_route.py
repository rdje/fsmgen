"""Check current reader routes without imposing the capture-era card layout."""
import argparse
import base64
import copy
import gzip
import hashlib
import json
from pathlib import Path
import re
import shlex
import subprocess

import frozen_operand_route as frozen
import rollover_source_card as card

ROOT = Path(__file__).resolve().parents[3]
AUDIT = frozen.AUDIT
BASE = 'd5ea1fc9ed7e3fc502bcf4aeaf4b0da89226281a'
PUBLISHED_REVISION = '89890bacf79c3f70e5efb905ff793a5ddca4ab4a'
CONTRACT_REVISION = 'ff44aaf3c04fc8d7904d11f5e0f7cd9b664a6292'
CONTRACT_SOURCES = {AUDIT + name + '.py' for name in
                    ('prepare', 'canonical_contracts', 'check_canonical_progress')}
INTAKE_REVISION = '8e4116bcd5063c699a3b6a8793042a3564e26cd9'
INTAKE_SOURCES = {AUDIT + name + '.py' for name in
                  ('selected_intake', 'verify_selected_failed', 'qualify_selected_intake_roles')}
INTAKE_PROOF = AUDIT + 'selected-intake-roles-qualified.json.gz'
CACHE_REVISION = '260f5e023bb34ed93fb60c32730123f01f17b991'
CACHE_SOURCES = {AUDIT + name + '.py' for name in
                 ('verify_runtime_cache', 'qualify_runtime_cache_roles')}
CACHE_DEPENDENCIES = {AUDIT + name + '.py' for name in
                      ('runtime_cache_producer', 'epoch_constraints', 'execute',
                       'selected_postrun', 'selected_checkout')}
CACHE_PROOF = AUDIT + 'runtime-cache-source-roles-qualified.json.gz'
DISPATCH_REVISION = 'c3434d27c76d21936b968d15df6d4b9cc7b89932'
DISPATCH_SOURCES = {AUDIT + name + '.py' for name in
                    ('default_dispatch', 'saved_reader_sources', 'qualify_default_dispatch_roles')}
DISPATCH_PROOF = AUDIT + 'default-dispatch-source-roles-qualified.json.gz'
FIXED_GAP_REVISION = '7e588f8d84df65aee3afc0344f000f2aee672ecc'
FIXED_GAP_SOURCES = {AUDIT + name + '.py' for name in
                     ('qualify_fixed_module_gap', 'qualify_fixed_gap_roles')}
FIXED_GAP_PROOF = AUDIT + 'fixed-gap-source-roles-qualified.json.gz'
CALLER_REVISION = '8bf1c8bbce8d9f2b0ef8abd2ec9dff2c59378e2a'
CALLER_SOURCES = {AUDIT + name + '.py' for name in
                  ('qualify_caller_modules', 'saved_source_roles', 'qualify_caller_roles')}
CALLER_PROOF = AUDIT + 'caller-source-roles-qualified.json.gz'
CALLER_COMMAND = ['python3', '-B', AUDIT + 'qualify_caller_roles.py']
OPERAND_REVISION = '1030bbb3bdd386a0c5bdf34d32a796053fa9cdfe'
OPERAND_SOURCES = {AUDIT + name + '.py' for name in
                   ('operand_inventory', 'qualify_operand_roles')}
OPERAND_PROOF = AUDIT + 'operand-source-roles-qualified.json.gz'
OPERAND_COMMAND = ['python3', '-B', AUDIT + 'qualify_operand_roles.py']
AST_INPUT_REVISION = '82f0a5661eb79061dbb874fcb45b1066c29051a5'
AST_INPUT_SOURCES = {AUDIT + name + '.py' for name in
                     ('ast_model_inputs', 'qualify_ast_input_roles')}
AST_INPUT_PROOF = AUDIT + 'ast-input-source-roles-qualified.json.gz'
AST_INPUT_COMMAND = ['python3', '-B', AUDIT + 'qualify_ast_input_roles.py']
PREPARATION_REVISION = 'fecc3ff3b4d81d25f1bd9c357d7d2af7b743eb65'
PREPARATION_SOURCES = {AUDIT + name + '.py' for name in
                       ('preparation_correction', 'qualify_preparation_roles')}
PREPARATION_PROOF = AUDIT + 'preparation-source-roles-qualified.json.gz'
PREPARATION_COMMAND = ['python3', '-B', AUDIT + 'qualify_preparation_roles.py']
COMPILE_ONLY_REVISION = '5600ebe362bf42fc7fffcd407884f4b1dbd0d8fd'
COMPILE_ONLY_SOURCES = {AUDIT + name + '.py' for name in
                       ('compile_only_inputs', 'qualify_compile_only_roles')}
COMPILE_ONLY_PROOF = AUDIT + 'compile-only-source-roles-qualified.json.gz'
COMPILE_ONLY_COMMAND = ['python3', '-B', AUDIT + 'qualify_compile_only_roles.py']
FROZEN_INPUTS = [AUDIT + name + '.json.gz' for name in
                 ('canonical-contracts-qualified', 'canonical-contract-progress-qualified')] + [INTAKE_PROOF, CACHE_PROOF, DISPATCH_PROOF, FIXED_GAP_PROOF, CALLER_PROOF, OPERAND_PROOF, AST_INPUT_PROOF, PREPARATION_PROOF, COMPILE_ONLY_PROOF]
SELF = AUDIT + 'live_operand_route.py'
HELPER = frozen.HELPER
OUTPUT = AUDIT + 'compile-only-live-route-qualified.json.gz'
TERMINAL = ['python3', '-B', SELF, '--current']
OPTIONAL = [['python3', '-B', AUDIT + name + '.py'] for name in
            ('frozen_operand_route', 'check_frozen_route_independence',
             'canonical_contracts', 'check_canonical_progress', 'qualify_selected_intake_roles',
             'qualify_runtime_cache_roles', 'qualify_default_dispatch_roles',
             'qualify_fixed_gap_roles', 'qualify_caller_roles', 'qualify_operand_roles',
             'qualify_ast_input_roles', 'qualify_preparation_roles', 'qualify_compile_only_roles')]
DEPENDENCIES = [AUDIT + 'frozen_operand_route.py', AUDIT + 'rollover_source_card.py',
                'scripts/check_source_recovery_card.sh',
                *sorted(CONTRACT_SOURCES | INTAKE_SOURCES | CACHE_SOURCES | CACHE_DEPENDENCIES | DISPATCH_SOURCES | FIXED_GAP_SOURCES | CALLER_SOURCES | OPERAND_SOURCES | AST_INPUT_SOURCES | PREPARATION_SOURCES | COMPILE_ONLY_SOURCES)]
SCOPE = ('Current source/archive/question/reverify and ordered reader membership only. '
         'Original and already-published child readers retain their exact order. '
         'Only the named canonical, selected-intake, runtime-cache, default-dispatch, fixed-gap, caller, operand, AST-input, preparation and compile-only source replacements bind to '
         'separately qualified immutable revisions; unchanged entrypoint identities '
         'and complete original versions of replaced published sources retain. Only the '
         'explicit native-qualified optional readers may be added. The named '
         'published helper snapshot additionally binds complete established reader membership '
         'and relative order, including previously admitted optional qualifiers. The named '
         'caller addition must itself remain after every established reader; the operand '
         'addition must follow the caller; the AST-input addition must follow the operand; '
         'the preparation addition must follow the AST-input qualifier; '
         'the compile-only addition must follow preparation. '
         'Other qualified additive extensions remain permitted. The named '
         'canonical, intake, cache, dispatch, fixed-gap, caller, operand, AST-input, preparation and compile-only library/readers and their frozen proof inputs bind '
         'to separately qualified immutable revisions. Named unchanged cache decode '
         'dependencies retain their original native epoch. The unchanged shared metadata getter '
         'retains its dispatch admission epoch; other transitive '
         'dependencies are outside this route claim. Actual helper '
         'listing and public queries execute, never listed readers or original '
         'models/recipes/cohorts. Whole sequence success and original semantic, '
         'custody, native/private, HIAL and full-CI gates remain separately owned.')


def native(path, *, identity_only=False, revision=None):
    if revision is None:
        revision = (COMPILE_ONLY_REVISION if path in COMPILE_ONLY_SOURCES or path == COMPILE_ONLY_PROOF else
                    PREPARATION_REVISION if path in PREPARATION_SOURCES or path == PREPARATION_PROOF else
                    AST_INPUT_REVISION if path in AST_INPUT_SOURCES or path == AST_INPUT_PROOF else
                    OPERAND_REVISION if path in OPERAND_SOURCES or path == OPERAND_PROOF else
                    CALLER_REVISION if path in CALLER_SOURCES or path == CALLER_PROOF else
                    FIXED_GAP_REVISION if path in FIXED_GAP_SOURCES or path == FIXED_GAP_PROOF else
                    DISPATCH_REVISION if path in DISPATCH_SOURCES or path == DISPATCH_PROOF else
                    CACHE_REVISION if path in CACHE_SOURCES or path == CACHE_PROOF else
                    INTAKE_REVISION if path in INTAKE_SOURCES or path == INTAKE_PROOF else
                    CONTRACT_REVISION if path in CONTRACT_SOURCES or path in FROZEN_INPUTS else BASE)
    assert revision in (BASE, PUBLISHED_REVISION, CONTRACT_REVISION, INTAKE_REVISION, CACHE_REVISION, DISPATCH_REVISION, FIXED_GAP_REVISION, CALLER_REVISION, OPERAND_REVISION, AST_INPUT_REVISION, PREPARATION_REVISION, COMPILE_ONLY_REVISION), 'closed native source epochs'
    entry = frozen.git('ls-tree', '--full-tree', '-l', '-z', revision, '--', path)
    assert entry.count(b'\0') == 1, 'one native admitted source'
    header, name = entry[:-1].split(b'\t')
    mode, kind, oid, size = header.decode().split()
    assert mode in ('100644', '100755') and kind == 'blob' and name.decode() == path, 'regular native admitted source: ' + path
    body = frozen.git('show', revision + ':' + path)
    assert size.isdecimal() and len(body) == int(size)
    assert body == frozen.git('cat-file', 'blob', oid)
    assert hashlib.sha1(b'blob ' + str(len(body)).encode() + b'\0' + body).hexdigest() == oid
    result = dict(revision=revision, path=path, mode=mode, oid=oid,
                  retention_contract='fsmgen_required_history')
    if identity_only:
        # Exact immutable references recover the full committed proof. Do not
        # duplicate large binary bodies in every structural control candidate.
        result['identity'] = identity(body)
    else:
        result['body'] = frozen.blob(body)
    return result


def identity(body):
    return dict(bytes=len(body), sha256=hashlib.sha256(body).hexdigest())


def unblob(value):
    body = base64.b64decode(value['body_base64'], validate=True)
    frozen.equal(value, frozen.blob(body))
    return body


def authority():
    helper = native(HELPER)
    required = frozen.helper_commands(unblob(helper['body']))[:-1]
    original = frozen.reconstruct(frozen.native_inputs())['commands'][:-1]
    cursor = iter(required)
    assert all(any(command == current for current in cursor) for command in original)
    published_helper = native(HELPER, revision=PUBLISHED_REVISION)
    published_body = unblob(published_helper['body'])
    published = frozen.helper_commands(published_body)[:-1]
    helper_review(published_body, unblob(helper['body']), required, published)
    names = sorted({command[-1] for command in required} | {row[-1] for row in OPTIONAL} | set(DEPENDENCIES))
    # The prove command's file is also its last argument. Every referenced
    # source is a primary-repository regular blob, not a submodule interface.
    sources = {name: native(name) for name in names}
    proof = native(str(card.PATH))
    baseline_card = native(frozen.CARD)
    return dict(helper=helper, published_helper=published_helper, published=published,
                sources=sources, required=required,
                replaced_sources={path: native(path, revision=BASE) for path in sorted(
                    {command[-1] for command in required} & (INTAKE_SOURCES | CACHE_SOURCES | DISPATCH_SOURCES | FIXED_GAP_SOURCES | CALLER_SOURCES | OPERAND_SOURCES | AST_INPUT_SOURCES | PREPARATION_SOURCES | COMPILE_ONLY_SOURCES))},
                frozen_inputs={path: native(path, identity_only=True) for path in FROZEN_INPUTS},
                source_card_proof=proof, baseline_card=baseline_card)


def commands_review(commands, required, published):
    assert type(commands) is list and commands, 'complete current command array'
    frozen.equal(commands[-1], TERMINAL)
    mandatory = []
    optional_seen = []
    for command in commands[:-1]:
        if command in OPTIONAL:
            assert command not in optional_seen, 'unique optional reader'
            optional_seen.append(command)
        else:
            mandatory.append(command)
    frozen.equal(mandatory, required)
    assert type(published) is list and published, 'complete published reader snapshot'
    cursor = iter(commands[:-1])
    assert all(any(command == current for current in cursor) for command in published), 'complete published reader membership and order'


def helper_review(body, native_helper, required, published):
    def protocol(value):
        text = value.decode()
        text, count = re.subn(r'^for task_reader in .*; do$', 'for task_reader in READERS; do', text, flags=re.M)
        assert count == 1, 'one bounded literal reader loop'
        text, count = re.subn(r'^run_saved_reader python3 -B "\$task_reader_audit/[a-z_]+\.py" --current$',
                             'TERMINAL', text, flags=re.M)
        assert count == 1, 'one terminal current authorizer'
        return text

    assert protocol(body) == protocol(native_helper), 'complete helper listing/execution protocol'
    commands = frozen.helper_commands(body)
    commands_review(commands, required, published)
    return commands


def query_review(rows, current):
    expected = card.questions(current)
    frozen.equal([row['question'] for row in rows], expected)
    for row in rows:
        assert set(row) == {'question', 'command', 'stdout'}
        frozen.equal(row['command'], ['knowledge-map/scripts/query_knowledge_map.sh', '--no-cache', row['question']])
        line = '\t'.join((row['question'], card.SOURCE_ID, card.SOURCE)).encode()
        assert line in unblob(row['stdout']).splitlines(), 'actual public query target'


def review(value, fixed):
    assert set(value) == {'authority', 'card', 'archive', 'descriptor', 'caps', 'helper',
                          'sources', 'frozen_inputs', 'listing', 'queries', 'programme', 'scope'}
    frozen.equal(value['authority'], fixed)
    frozen.equal(value['scope'], SCOPE)
    programme = unblob(value['programme'])
    assert programme, 'retained current checker programme'
    initial_proof = json.loads(gzip.decompress(unblob(fixed['source_card_proof']['body'])))
    card.saved_check(initial_proof)
    original = card.unblob(initial_proof['inputs']['original'])
    current = unblob(value['card'])
    result = card.validate(original, unblob(value['archive']), current, value['descriptor'], value['caps'])
    card.live_questions_retained(unblob(fixed['baseline_card']['body']), current)
    blocks = re.findall(r'^reverify: >-\n((?:  .*\n)+)', card.header(current), re.M)
    assert len(blocks) == 1, 'one current reverify command'
    frozen.equal(shlex.split(' '.join(line.strip() for line in blocks[0].splitlines())),
                 ['scripts/run_with_ram_guard.sh', '--', 'bash', HELPER])
    commands = helper_review(unblob(value['helper']), unblob(fixed['helper']['body']), fixed['required'], fixed['published'])
    # The published snapshot predates this newly admitted wrapper. Its native
    # source qualification authorizes addition, not subsequent omission/movement.
    cursor = iter(commands[:-1])
    assert all(any(command == current for current in cursor)
               for command in [*fixed['published'], CALLER_COMMAND]), 'complete admitted caller membership and order'
    cursor = iter(commands[:-1])
    assert all(any(command == current for current in cursor)
               for command in [*fixed['published'], CALLER_COMMAND, OPERAND_COMMAND]), 'complete admitted operand membership and order'
    cursor = iter(commands[:-1])
    assert all(any(command == current for current in cursor)
               for command in [*fixed['published'], CALLER_COMMAND, OPERAND_COMMAND, AST_INPUT_COMMAND]), 'complete admitted AST-input membership and order'
    cursor = iter(commands[:-1])
    assert all(any(command == current for current in cursor)
               for command in [*fixed['published'], CALLER_COMMAND, OPERAND_COMMAND, AST_INPUT_COMMAND, PREPARATION_COMMAND]), 'complete admitted preparation membership and order'
    cursor = iter(commands[:-1])
    assert all(any(command == current for current in cursor)
               for command in [*fixed['published'], CALLER_COMMAND, OPERAND_COMMAND, AST_INPUT_COMMAND, PREPARATION_COMMAND, COMPILE_ONLY_COMMAND]), 'complete admitted compile-only membership and order'
    needed = {command[-1] for command in commands[:-1]} | set(DEPENDENCIES)
    assert value['sources'].keys() == needed, 'complete admitted current source population'
    for path in needed:
        frozen.equal(value['sources'][path], fixed['sources'][path]['body'])
    assert value['frozen_inputs'].keys() == fixed['frozen_inputs'].keys(), 'complete frozen proof population'
    for path in FROZEN_INPUTS:
        frozen.equal(value['frozen_inputs'][path], fixed['frozen_inputs'][path]['identity'])
    receipt = value['listing']
    assert set(receipt) == {'command', 'status', 'stdout', 'stderr'}
    frozen.equal(receipt['command'], ['bash', HELPER, '--list'])
    frozen.equal(receipt['status'], 0)
    frozen.equal(receipt['stderr'], '')
    frozen.equal([shlex.split(line) for line in receipt['stdout'].splitlines()], commands)
    query_review(value['queries'], current)
    return dict(card=result, commands=commands)


def listing(body, required, fixed):
    # Check the complete protocol before executing the new helper's list mode.
    helper_review(body, unblob(fixed['helper']['body']), required, fixed['published'])
    command = ['bash', HELPER, '--list']
    result = subprocess.run(command, cwd=ROOT, stdin=subprocess.DEVNULL, capture_output=True, timeout=30)
    return dict(command=command, status=result.returncode, stdout=result.stdout.decode(), stderr=result.stderr.decode())


def current_value(fixed):
    helper = card.read_file(HELPER)
    commands = helper_review(helper, unblob(fixed['helper']['body']), fixed['required'], fixed['published'])
    current = card.read_file(card.SOURCE)
    needed = {command[-1] for command in commands[:-1]} | set(DEPENDENCIES)
    value = dict(authority=fixed, card=frozen.blob(current), archive=frozen.blob(card.read_file(card.ARCHIVE)),
        descriptor=card.selected_descriptor(), caps=card.limits(), helper=frozen.blob(helper),
        sources={path: frozen.blob(card.read_file(path)) for path in sorted(needed)},
        frozen_inputs={path: identity(card.read_file(path)) for path in FROZEN_INPUTS},
        listing=listing(helper, fixed['required'], fixed), queries=card.public_queries(current),
        programme=frozen.blob(card.read_file(SELF)), scope=SCOPE)
    review(value, fixed)
    return value


def rewritten_listing(value, helper):
    """Structural candidate receipt, never reported as a new observation."""
    value['helper'] = frozen.blob(helper)
    commands = frozen.helper_commands(helper)
    value['listing']['stdout'] = ''.join(' '.join(command) + ' \n' for command in commands)
    return value


def changed_published_helper(helper, published, change):
    """Construct a genuine changed established-qualifier candidate, never run it."""
    loop = re.search(rb'^for task_reader in (.*); do$', helper, re.M)
    assert loop
    words = loop[1].split()
    optional = [Path(command[-1]).stem.encode() for command in published if command in OPTIONAL]
    assert len(optional) >= 2, 'separate established qualifier operands'
    left, right = words.index(optional[-2]), words.index(optional[-1])
    assert left < right
    if change == 'reordered':
        words[left], words[right] = words[right], words[left]
    elif change == 'omitted':
        words.pop(right)
    elif change == 'moved':
        words.insert(0, words.pop(right))
    else:
        raise AssertionError('closed established-reader control')
    return helper[:loop.start(1)] + b' '.join(words) + helper[loop.end(1):]


def controls(value, fixed):
    result = []
    helper = unblob(value['helper'])
    loop = re.search(rb'^for task_reader in (.*); do$', helper, re.M)
    assert loop
    words = loop[1].split()
    for label, mutation in (
        ('omitted-reader', lambda x: rewritten_listing(x, helper[:loop.start(1)] + b' '.join(words[1:]) + helper[loop.end(1):])),
        ('reordered-readers', lambda x: rewritten_listing(x, helper[:loop.start(1)] + b' '.join(reversed(words)) + helper[loop.end(1):])),
        ('reordered-published-qualifiers', lambda x: rewritten_listing(x, changed_published_helper(helper, fixed['published'], 'reordered'))),
        ('omitted-published-qualifier', lambda x: rewritten_listing(x, changed_published_helper(helper, fixed['published'], 'omitted'))),
        ('moved-published-qualifier', lambda x: rewritten_listing(x, changed_published_helper(helper, fixed['published'], 'moved'))),
        ('wrong-published-helper-revision', lambda x: x['authority']['published_helper'].__setitem__('revision', BASE)),
        ('changed-published-helper', lambda x: x['authority']['published_helper'].__setitem__('body', frozen.blob(b'changed published helper\n'))),
        ('missing-published-reader', lambda x: x['authority']['published'].pop()),
        ('reordered-published-snapshot', lambda x: x['authority']['published'].reverse()),
        ('reordered-admitted-caller', lambda x: rewritten_listing(x, changed_published_helper(helper, [*fixed['published'], CALLER_COMMAND], 'reordered'))),
        ('omitted-admitted-caller', lambda x: rewritten_listing(x, changed_published_helper(helper, [*fixed['published'], CALLER_COMMAND], 'omitted'))),
        ('moved-admitted-caller', lambda x: rewritten_listing(x, changed_published_helper(helper, [*fixed['published'], CALLER_COMMAND], 'moved'))),
        ('reordered-admitted-operand', lambda x: rewritten_listing(x, changed_published_helper(helper, [*fixed['published'], CALLER_COMMAND, OPERAND_COMMAND], 'reordered'))),
        ('omitted-admitted-operand', lambda x: rewritten_listing(x, changed_published_helper(helper, [*fixed['published'], CALLER_COMMAND, OPERAND_COMMAND], 'omitted'))),
        ('moved-admitted-operand', lambda x: rewritten_listing(x, changed_published_helper(helper, [*fixed['published'], CALLER_COMMAND, OPERAND_COMMAND], 'moved'))),
        ('changed-operand-reader', lambda x: x['sources'].__setitem__(AUDIT + 'operand_inventory.py', frozen.blob(b'changed operand reader\n'))),
        ('changed-operand-role-wrapper', lambda x: x['sources'].__setitem__(AUDIT + 'qualify_operand_roles.py', frozen.blob(b'changed operand wrapper\n'))),
        ('wrong-operand-source-revision', lambda x: x['authority']['sources'][AUDIT + 'operand_inventory.py'].__setitem__('revision', BASE)),
        ('wrong-operand-wrapper-revision', lambda x: x['authority']['sources'][AUDIT + 'qualify_operand_roles.py'].__setitem__('revision', CALLER_REVISION)),
        ('lost-original-operand-reader', lambda x: x['authority']['replaced_sources'].pop(AUDIT + 'operand_inventory.py')),
        ('missing-operand-role-proof', lambda x: x['frozen_inputs'].pop(OPERAND_PROOF)),
        ('changed-operand-role-proof', lambda x: x['frozen_inputs'][OPERAND_PROOF].__setitem__('sha256', '0' * 64)),
        ('borrowed-operand-role-proof', lambda x: x['frozen_inputs'].__setitem__(OPERAND_PROOF, copy.deepcopy(x['frozen_inputs'][CALLER_PROOF]))),
        ('wrong-operand-proof-revision', lambda x: x['authority']['frozen_inputs'][OPERAND_PROOF].__setitem__('revision', CALLER_REVISION)),
        ('boolean-operand-proof-size', lambda x: x['frozen_inputs'][OPERAND_PROOF].__setitem__('bytes', True)),
        ('float-operand-proof-size', lambda x: x['frozen_inputs'][OPERAND_PROOF].__setitem__('bytes', float(x['frozen_inputs'][OPERAND_PROOF]['bytes']))),
        ('reordered-admitted-ast-input', lambda x: rewritten_listing(x, changed_published_helper(helper, [*fixed['published'], CALLER_COMMAND, OPERAND_COMMAND, AST_INPUT_COMMAND], 'reordered'))),
        ('omitted-admitted-ast-input', lambda x: rewritten_listing(x, changed_published_helper(helper, [*fixed['published'], CALLER_COMMAND, OPERAND_COMMAND, AST_INPUT_COMMAND], 'omitted'))),
        ('moved-admitted-ast-input', lambda x: rewritten_listing(x, changed_published_helper(helper, [*fixed['published'], CALLER_COMMAND, OPERAND_COMMAND, AST_INPUT_COMMAND], 'moved'))),
        ('changed-ast-input-reader', lambda x: x['sources'].__setitem__(AUDIT + 'ast_model_inputs.py', frozen.blob(b'changed AST-input reader\n'))),
        ('changed-ast-input-role-wrapper', lambda x: x['sources'].__setitem__(AUDIT + 'qualify_ast_input_roles.py', frozen.blob(b'changed AST-input wrapper\n'))),
        ('wrong-ast-input-source-revision', lambda x: x['authority']['sources'][AUDIT + 'ast_model_inputs.py'].__setitem__('revision', BASE)),
        ('wrong-ast-input-wrapper-revision', lambda x: x['authority']['sources'][AUDIT + 'qualify_ast_input_roles.py'].__setitem__('revision', OPERAND_REVISION)),
        ('lost-original-ast-input-reader', lambda x: x['authority']['replaced_sources'].pop(AUDIT + 'ast_model_inputs.py')),
        ('missing-ast-input-role-proof', lambda x: x['frozen_inputs'].pop(AST_INPUT_PROOF)),
        ('changed-ast-input-role-proof', lambda x: x['frozen_inputs'][AST_INPUT_PROOF].__setitem__('sha256', '0' * 64)),
        ('borrowed-ast-input-role-proof', lambda x: x['frozen_inputs'].__setitem__(AST_INPUT_PROOF, copy.deepcopy(x['frozen_inputs'][OPERAND_PROOF]))),
        ('wrong-ast-input-proof-revision', lambda x: x['authority']['frozen_inputs'][AST_INPUT_PROOF].__setitem__('revision', OPERAND_REVISION)),
        ('boolean-ast-input-proof-size', lambda x: x['frozen_inputs'][AST_INPUT_PROOF].__setitem__('bytes', True)),
        ('float-ast-input-proof-size', lambda x: x['frozen_inputs'][AST_INPUT_PROOF].__setitem__('bytes', float(x['frozen_inputs'][AST_INPUT_PROOF]['bytes']))),
        ('reordered-admitted-preparation', lambda x: rewritten_listing(x, changed_published_helper(helper, [*fixed['published'], CALLER_COMMAND, OPERAND_COMMAND, AST_INPUT_COMMAND, PREPARATION_COMMAND], 'reordered'))),
        ('omitted-admitted-preparation', lambda x: rewritten_listing(x, changed_published_helper(helper, [*fixed['published'], CALLER_COMMAND, OPERAND_COMMAND, AST_INPUT_COMMAND, PREPARATION_COMMAND], 'omitted'))),
        ('moved-admitted-preparation', lambda x: rewritten_listing(x, changed_published_helper(helper, [*fixed['published'], CALLER_COMMAND, OPERAND_COMMAND, AST_INPUT_COMMAND, PREPARATION_COMMAND], 'moved'))),
        ('changed-preparation-reader', lambda x: x['sources'].__setitem__(AUDIT + 'preparation_correction.py', frozen.blob(b'changed preparation reader\n'))),
        ('changed-preparation-role-wrapper', lambda x: x['sources'].__setitem__(AUDIT + 'qualify_preparation_roles.py', frozen.blob(b'changed preparation wrapper\n'))),
        ('wrong-preparation-source-revision', lambda x: x['authority']['sources'][AUDIT + 'preparation_correction.py'].__setitem__('revision', BASE)),
        ('wrong-preparation-wrapper-revision', lambda x: x['authority']['sources'][AUDIT + 'qualify_preparation_roles.py'].__setitem__('revision', AST_INPUT_REVISION)),
        ('lost-original-preparation-reader', lambda x: x['authority']['replaced_sources'].pop(AUDIT + 'preparation_correction.py')),
        ('missing-preparation-role-proof', lambda x: x['frozen_inputs'].pop(PREPARATION_PROOF)),
        ('changed-preparation-role-proof', lambda x: x['frozen_inputs'][PREPARATION_PROOF].__setitem__('sha256', '0' * 64)),
        ('borrowed-preparation-role-proof', lambda x: x['frozen_inputs'].__setitem__(PREPARATION_PROOF, copy.deepcopy(x['frozen_inputs'][AST_INPUT_PROOF]))),
        ('wrong-preparation-proof-revision', lambda x: x['authority']['frozen_inputs'][PREPARATION_PROOF].__setitem__('revision', AST_INPUT_REVISION)),
        ('boolean-preparation-proof-size', lambda x: x['frozen_inputs'][PREPARATION_PROOF].__setitem__('bytes', True)),
        ('float-preparation-proof-size', lambda x: x['frozen_inputs'][PREPARATION_PROOF].__setitem__('bytes', float(x['frozen_inputs'][PREPARATION_PROOF]['bytes']))),
        ('reordered-admitted-compile-only', lambda x: rewritten_listing(x, changed_published_helper(helper, [*fixed['published'], CALLER_COMMAND, OPERAND_COMMAND, AST_INPUT_COMMAND, PREPARATION_COMMAND, COMPILE_ONLY_COMMAND], 'reordered'))),
        ('omitted-admitted-compile-only', lambda x: rewritten_listing(x, changed_published_helper(helper, [*fixed['published'], CALLER_COMMAND, OPERAND_COMMAND, AST_INPUT_COMMAND, PREPARATION_COMMAND, COMPILE_ONLY_COMMAND], 'omitted'))),
        ('moved-admitted-compile-only', lambda x: rewritten_listing(x, changed_published_helper(helper, [*fixed['published'], CALLER_COMMAND, OPERAND_COMMAND, AST_INPUT_COMMAND, PREPARATION_COMMAND, COMPILE_ONLY_COMMAND], 'moved'))),
        ('changed-compile-only-reader', lambda x: x['sources'].__setitem__(AUDIT + 'compile_only_inputs.py', frozen.blob(b'changed compile-only reader\n'))),
        ('changed-compile-only-role-wrapper', lambda x: x['sources'].__setitem__(AUDIT + 'qualify_compile_only_roles.py', frozen.blob(b'changed compile-only wrapper\n'))),
        ('wrong-compile-only-source-revision', lambda x: x['authority']['sources'][AUDIT + 'compile_only_inputs.py'].__setitem__('revision', BASE)),
        ('wrong-compile-only-wrapper-revision', lambda x: x['authority']['sources'][AUDIT + 'qualify_compile_only_roles.py'].__setitem__('revision', PREPARATION_REVISION)),
        ('lost-original-compile-only-reader', lambda x: x['authority']['replaced_sources'].pop(AUDIT + 'compile_only_inputs.py')),
        ('missing-compile-only-role-proof', lambda x: x['frozen_inputs'].pop(COMPILE_ONLY_PROOF)),
        ('changed-compile-only-role-proof', lambda x: x['frozen_inputs'][COMPILE_ONLY_PROOF].__setitem__('sha256', '0' * 64)),
        ('borrowed-compile-only-role-proof', lambda x: x['frozen_inputs'].__setitem__(COMPILE_ONLY_PROOF, copy.deepcopy(x['frozen_inputs'][PREPARATION_PROOF]))),
        ('wrong-compile-only-proof-revision', lambda x: x['authority']['frozen_inputs'][COMPILE_ONLY_PROOF].__setitem__('revision', PREPARATION_REVISION)),
        ('boolean-compile-only-proof-size', lambda x: x['frozen_inputs'][COMPILE_ONLY_PROOF].__setitem__('bytes', True)),
        ('float-compile-only-proof-size', lambda x: x['frozen_inputs'][COMPILE_ONLY_PROOF].__setitem__('bytes', float(x['frozen_inputs'][COMPILE_ONLY_PROOF]['bytes']))),
        ('wrong-terminal-role', lambda x: rewritten_listing(x, helper.replace(b'/live_operand_route.py"', b'/verify_operand_route.py"'))),
        ('changed-helper-protocol', lambda x: x.__setitem__('helper', frozen.blob(helper + b'echo extra\n'))),
        ('missing-source', lambda x: x['sources'].pop(next(iter(x['sources'])))),
        ('changed-source', lambda x: x['sources'].__setitem__(next(iter(x['sources'])), frozen.blob(b'changed source\n'))),
        ('changed-contract-library', lambda x: x['sources'].__setitem__(AUDIT + 'prepare.py', frozen.blob(b'changed library\n'))),
        ('wrong-contract-source-revision', lambda x: x['authority']['sources'][AUDIT + 'prepare.py'].__setitem__('revision', BASE)),
        ('changed-selected-intake', lambda x: x['sources'].__setitem__(AUDIT + 'selected_intake.py', frozen.blob(b'changed intake\n'))),
        ('changed-failed-custody-consumer', lambda x: x['sources'].__setitem__(AUDIT + 'verify_selected_failed.py', frozen.blob(b'changed custody\n'))),
        ('wrong-intake-source-revision', lambda x: x['authority']['sources'][AUDIT + 'selected_intake.py'].__setitem__('revision', BASE)),
        ('lost-original-intake-source', lambda x: x['authority']['replaced_sources'].pop(AUDIT + 'selected_intake.py')),
        ('missing-intake-role-proof', lambda x: x['frozen_inputs'].pop(INTAKE_PROOF)),
        ('changed-runtime-cache-reader', lambda x: x['sources'].__setitem__(AUDIT + 'verify_runtime_cache.py', frozen.blob(b'changed cache reader\n'))),
        ('changed-cache-decode-library', lambda x: x['sources'].__setitem__(AUDIT + 'runtime_cache_producer.py', frozen.blob(b'changed cache library\n'))),
        ('wrong-cache-source-revision', lambda x: x['authority']['sources'][AUDIT + 'verify_runtime_cache.py'].__setitem__('revision', BASE)),
        ('lost-original-cache-reader', lambda x: x['authority']['replaced_sources'].pop(AUDIT + 'verify_runtime_cache.py')),
        ('missing-cache-role-proof', lambda x: x['frozen_inputs'].pop(CACHE_PROOF)),
        ('boolean-cache-proof-size', lambda x: x['frozen_inputs'][CACHE_PROOF].__setitem__('bytes', True)),
        ('changed-dispatch-reader', lambda x: x['sources'].__setitem__(AUDIT + 'default_dispatch.py', frozen.blob(b'changed dispatch\n'))),
        ('changed-native-source-reader', lambda x: x['sources'].__setitem__(AUDIT + 'saved_reader_sources.py', frozen.blob(b'changed getter\n'))),
        ('changed-dispatch-role-qualifier', lambda x: x['sources'].__setitem__(AUDIT + 'qualify_default_dispatch_roles.py', frozen.blob(b'changed qualifier\n'))),
        ('wrong-dispatch-source-revision', lambda x: x['authority']['sources'][AUDIT + 'default_dispatch.py'].__setitem__('revision', BASE)),
        ('wrong-getter-source-revision', lambda x: x['authority']['sources'][AUDIT + 'saved_reader_sources.py'].__setitem__('revision', BASE)),
        ('lost-original-dispatch-reader', lambda x: x['authority']['replaced_sources'].pop(AUDIT + 'default_dispatch.py')),
        ('missing-dispatch-role-proof', lambda x: x['frozen_inputs'].pop(DISPATCH_PROOF)),
        ('changed-dispatch-role-proof', lambda x: x['frozen_inputs'][DISPATCH_PROOF].__setitem__('sha256', '0' * 64)),
        ('wrong-dispatch-proof-revision', lambda x: x['authority']['frozen_inputs'][DISPATCH_PROOF].__setitem__('revision', BASE)),
        ('boolean-dispatch-proof-size', lambda x: x['frozen_inputs'][DISPATCH_PROOF].__setitem__('bytes', True)),
        ('changed-fixed-gap-reader', lambda x: x['sources'].__setitem__(AUDIT + 'qualify_fixed_module_gap.py', frozen.blob(b'changed fixed-gap reader\n'))),
        ('changed-fixed-gap-role-qualifier', lambda x: x['sources'].__setitem__(AUDIT + 'qualify_fixed_gap_roles.py', frozen.blob(b'changed qualifier\n'))),
        ('wrong-fixed-gap-source-revision', lambda x: x['authority']['sources'][AUDIT + 'qualify_fixed_module_gap.py'].__setitem__('revision', BASE)),
        ('wrong-fixed-gap-qualifier-revision', lambda x: x['authority']['sources'][AUDIT + 'qualify_fixed_gap_roles.py'].__setitem__('revision', BASE)),
        ('lost-original-fixed-gap-reader', lambda x: x['authority']['replaced_sources'].pop(AUDIT + 'qualify_fixed_module_gap.py')),
        ('missing-fixed-gap-role-proof', lambda x: x['frozen_inputs'].pop(FIXED_GAP_PROOF)),
        ('changed-fixed-gap-role-proof', lambda x: x['frozen_inputs'][FIXED_GAP_PROOF].__setitem__('sha256', '0' * 64)),
        ('wrong-fixed-gap-proof-revision', lambda x: x['authority']['frozen_inputs'][FIXED_GAP_PROOF].__setitem__('revision', BASE)),
        ('boolean-fixed-gap-proof-size', lambda x: x['frozen_inputs'][FIXED_GAP_PROOF].__setitem__('bytes', True)),
        ('changed-caller-reader', lambda x: x['sources'].__setitem__(AUDIT + 'qualify_caller_modules.py', frozen.blob(b'changed caller reader\n'))),
        ('changed-caller-role-wrapper', lambda x: x['sources'].__setitem__(AUDIT + 'qualify_caller_roles.py', frozen.blob(b'changed wrapper\n'))),
        ('changed-shared-role-verifier', lambda x: x['sources'].__setitem__(AUDIT + 'saved_source_roles.py', frozen.blob(b'changed shared verifier\n'))),
        ('wrong-caller-source-revision', lambda x: x['authority']['sources'][AUDIT + 'qualify_caller_modules.py'].__setitem__('revision', BASE)),
        ('wrong-shared-verifier-revision', lambda x: x['authority']['sources'][AUDIT + 'saved_source_roles.py'].__setitem__('revision', FIXED_GAP_REVISION)),
        ('lost-original-caller-reader', lambda x: x['authority']['replaced_sources'].pop(AUDIT + 'qualify_caller_modules.py')),
        ('missing-caller-role-proof', lambda x: x['frozen_inputs'].pop(CALLER_PROOF)),
        ('changed-caller-role-proof', lambda x: x['frozen_inputs'][CALLER_PROOF].__setitem__('sha256', '0' * 64)),
        ('borrowed-caller-role-proof', lambda x: x['frozen_inputs'].__setitem__(CALLER_PROOF, copy.deepcopy(x['frozen_inputs'][FIXED_GAP_PROOF]))),
        ('wrong-caller-proof-revision', lambda x: x['authority']['frozen_inputs'][CALLER_PROOF].__setitem__('revision', FIXED_GAP_REVISION)),
        ('boolean-caller-proof-size', lambda x: x['frozen_inputs'][CALLER_PROOF].__setitem__('bytes', True)),
        ('missing-frozen-proof', lambda x: x['frozen_inputs'].pop(FROZEN_INPUTS[0])),
        ('changed-frozen-proof', lambda x: x['frozen_inputs'][FROZEN_INPUTS[0]].__setitem__('sha256', '0' * 64)),
        ('boolean-frozen-proof-size', lambda x: x['frozen_inputs'][FROZEN_INPUTS[1]].__setitem__('bytes', True)),
        ('wrong-native-provenance', lambda x: x['authority']['helper'].__setitem__('revision', '0' * 40)),
        ('lost-baseline-question', lambda x: x.__setitem__('card', frozen.blob(unblob(x['card']).replace(
            ('  - ' + json.dumps(card.questions(unblob(fixed['baseline_card']['body']))[-1]) + '\n').encode(), b'', 1)))),
        ('missing-query', lambda x: x['queries'].pop()),
        ('wrong-query-command', lambda x: x['queries'][0]['command'].__setitem__(1, '--all')),
        ('wrong-query-target', lambda x: x['queries'][0].__setitem__('stdout', frozen.blob(b'wrong target\n'))),
        ('boolean-receipt', lambda x: x['listing'].__setitem__('status', False)),
        ('missing-listing-command', lambda x: x['listing'].__setitem__('stdout', '')),
        ('wrong-receipt-source', lambda x: x['listing']['command'].__setitem__(1, frozen.CREATOR)),
        ('changed-archive', lambda x: x.__setitem__('archive', frozen.blob(unblob(x['archive']) + b'x'))),
        ('wrong-descriptor', lambda x: x['descriptor'].__setitem__('schema_version', True)),
        ('wrong-reverify', lambda x: x.__setitem__('card', frozen.blob(unblob(x['card']).replace(b'reverify: >-', b'other: >-', 1)))),
    ):
        candidate = copy.deepcopy(value)
        mutation(candidate)
        try:
            review(candidate, fixed)
        except AssertionError as error:
            if label in ('reordered-admitted-operand', 'omitted-admitted-operand', 'moved-admitted-operand'):
                assert str(error) == 'complete admitted operand membership and order'
            if label in ('reordered-admitted-ast-input', 'omitted-admitted-ast-input', 'moved-admitted-ast-input'):
                assert str(error) == 'complete admitted AST-input membership and order'
            if label in ('reordered-admitted-preparation', 'omitted-admitted-preparation', 'moved-admitted-preparation'):
                assert str(error) == 'complete admitted preparation membership and order'
            if label in ('reordered-admitted-compile-only', 'omitted-admitted-compile-only', 'moved-admitted-compile-only'):
                assert str(error) == 'complete admitted compile-only membership and order'
            result.append(dict(label=label, candidate=candidate, refusal=str(error)))
        else:
            raise AssertionError('changed current route admitted: ' + label)
    positive = copy.deepcopy(value)
    amended = helper[:loop.end(1)] + b' frozen_operand_route' + helper[loop.end(1):]
    rewritten_listing(positive, amended)
    positive['sources'][OPTIONAL[0][-1]] = fixed['sources'][OPTIONAL[0][-1]]['body']
    review(positive, fixed)
    result.append(dict(label='native-qualified-additive-reader', candidate=positive,
        result='accepted structural candidate; no candidate helper or child reader executes'))
    return result


def main():
    if not __debug__:
        raise SystemExit('Acceptance assertions must be enabled.')
    parser = argparse.ArgumentParser(description=__doc__)
    mode = parser.add_mutually_exclusive_group()
    mode.add_argument('--current', action='store_true')
    mode.add_argument('--write', action='store_true')
    args = parser.parse_args()
    fixed = authority()
    value = current_value(fixed)
    product = dict(schema='fsmgen.live_operand_route.v10', inputs=value,
                   result=review(value, fixed), controls=controls(value, fixed))
    if args.write:
        card.save_record(OUTPUT, product)
    print('Current card/archive/query and admitted ordered reader routes qualify; whole sequence remains separately gated.')


if __name__ == '__main__':
    main()
