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
SELF = AUDIT + 'live_operand_route.py'
HELPER = frozen.HELPER
OUTPUT = AUDIT + 'live-operand-route-qualified.json.gz'
TERMINAL = ['python3', '-B', SELF, '--current']
OPTIONAL = [['python3', '-B', AUDIT + name + '.py'] for name in
            ('frozen_operand_route', 'check_frozen_route_independence')]
DEPENDENCIES = [AUDIT + 'frozen_operand_route.py', AUDIT + 'rollover_source_card.py',
                'scripts/check_source_recovery_card.sh']
SCOPE = ('Current source/archive/question/reverify and ordered reader membership only. '
         'Original and already-published child readers retain their exact order and '
         'native source identities; the obsolete terminal is replaced. Only the '
         'explicit native-qualified optional readers may be added. Actual helper '
         'listing and public queries execute, never listed readers or original '
         'models/recipes/cohorts. Whole sequence success and original semantic, '
         'custody, native/private, HIAL and full-CI gates remain separately owned.')


def native(path):
    entry = frozen.git('ls-tree', '--full-tree', '-l', '-z', BASE, '--', path)
    assert entry.count(b'\0') == 1, 'one native admitted source'
    header, name = entry[:-1].split(b'\t')
    mode, kind, oid, size = header.decode().split()
    assert mode in ('100644', '100755') and kind == 'blob' and name.decode() == path, 'regular native admitted source: ' + path
    body = frozen.git('show', BASE + ':' + path)
    assert size.isdecimal() and len(body) == int(size)
    assert body == frozen.git('cat-file', 'blob', oid)
    assert hashlib.sha1(b'blob ' + str(len(body)).encode() + b'\0' + body).hexdigest() == oid
    return dict(revision=BASE, path=path, mode=mode, oid=oid,
                retention_contract='fsmgen_required_history', body=frozen.blob(body))


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
    names = sorted({command[-1] for command in required} | {row[-1] for row in OPTIONAL} | set(DEPENDENCIES))
    # The prove command's file is also its last argument. Every referenced
    # source is a primary-repository regular blob, not a submodule interface.
    sources = {name: native(name) for name in names}
    proof = native(str(card.PATH))
    baseline_card = native(frozen.CARD)
    return dict(helper=helper, sources=sources, required=required,
                source_card_proof=proof, baseline_card=baseline_card)


def commands_review(commands, required):
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


def helper_review(body, native_helper, required):
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
    commands_review(commands, required)
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
                          'sources', 'listing', 'queries', 'programme', 'scope'}
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
    commands = helper_review(unblob(value['helper']), unblob(fixed['helper']['body']), fixed['required'])
    needed = {command[-1] for command in commands[:-1]} | set(DEPENDENCIES)
    assert value['sources'].keys() == needed, 'complete admitted current source population'
    for path in needed:
        frozen.equal(value['sources'][path], fixed['sources'][path]['body'])
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
    helper_review(body, unblob(fixed['helper']['body']), required)
    command = ['bash', HELPER, '--list']
    result = subprocess.run(command, cwd=ROOT, stdin=subprocess.DEVNULL, capture_output=True, timeout=30)
    return dict(command=command, status=result.returncode, stdout=result.stdout.decode(), stderr=result.stderr.decode())


def current_value(fixed):
    helper = card.read_file(HELPER)
    commands = helper_review(helper, unblob(fixed['helper']['body']), fixed['required'])
    current = card.read_file(card.SOURCE)
    needed = {command[-1] for command in commands[:-1]} | set(DEPENDENCIES)
    value = dict(authority=fixed, card=frozen.blob(current), archive=frozen.blob(card.read_file(card.ARCHIVE)),
        descriptor=card.selected_descriptor(), caps=card.limits(), helper=frozen.blob(helper),
        sources={path: frozen.blob(card.read_file(path)) for path in sorted(needed)},
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


def controls(value, fixed):
    result = []
    helper = unblob(value['helper'])
    loop = re.search(rb'^for task_reader in (.*); do$', helper, re.M)
    assert loop
    words = loop[1].split()
    for label, mutation in (
        ('omitted-reader', lambda x: rewritten_listing(x, helper[:loop.start(1)] + b' '.join(words[1:]) + helper[loop.end(1):])),
        ('reordered-readers', lambda x: rewritten_listing(x, helper[:loop.start(1)] + b' '.join(reversed(words)) + helper[loop.end(1):])),
        ('wrong-terminal-role', lambda x: rewritten_listing(x, helper.replace(b'/live_operand_route.py"', b'/verify_operand_route.py"'))),
        ('changed-helper-protocol', lambda x: x.__setitem__('helper', frozen.blob(helper + b'echo extra\n'))),
        ('missing-source', lambda x: x['sources'].pop(next(iter(x['sources'])))),
        ('changed-source', lambda x: x['sources'].__setitem__(next(iter(x['sources'])), frozen.blob(b'changed source\n'))),
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
    product = dict(schema='fsmgen.live_operand_route.v1', inputs=value,
                   result=review(value, fixed), controls=controls(value, fixed))
    if args.write:
        card.save_record(OUTPUT, product)
    print('Current card/archive/query and admitted ordered reader routes qualify; whole sequence remains separately gated.')


if __name__ == '__main__':
    main()
