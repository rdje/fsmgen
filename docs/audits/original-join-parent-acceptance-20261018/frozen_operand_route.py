"""Recover the original route from native frozen inputs; never run its code.

The creator and helper are data. Only Git is launched. Current route checks
and complete helper execution belong to separate task leaves.
"""
import argparse
import ast
import base64
import copy
import gzip
import hashlib
import json
from pathlib import Path
import re
import shlex
import subprocess

ROOT = Path(__file__).resolve().parents[3]
AUDIT = 'docs/audits/original-join-parent-acceptance-20261018/'
REVISION = 'dccd681e075c3b9df74811109de8a7cc427dae7a'
BEFORE_REVISION = '3ecd34eaab9061eb5e39e63fd64e946d99995afe'
CARD = 'docs/knowledge/claim-verification-record-enforcement.md'
PROOF = AUDIT + 'executable-operand-route-qualified.json.gz'
CREATOR = AUDIT + 'verify_operand_route.py'
HELPER = AUDIT + 'verify_claim_readers.sh'
OUTPUT = AUDIT + 'frozen-operand-route-qualified.json.gz'
QUESTION = 'where are compile exec operands inventoried?'
FACT = ('\noperand_inventory.py: whole fixed-graph compile/exec syntax and token census;\n'
        'source/data bindings and runtime stay unqualified.\n')
INPUTS = ((REVISION, PROOF), (REVISION, CREATOR), (REVISION, HELPER),
          (BEFORE_REVISION, CARD))


def equal(value, expected):
    assert type(value) is type(expected), 'JSON value kind'
    if isinstance(expected, dict):
        assert value.keys() == expected.keys(), 'complete object membership'
        for key in expected:
            equal(value[key], expected[key])
    elif isinstance(expected, list):
        assert len(value) == len(expected), 'complete array membership'
        for left, right in zip(value, expected):
            equal(left, right)
    else:
        assert value == expected, 'exact scalar'


def blob(body):
    return dict(bytes=len(body), sha256=hashlib.sha256(body).hexdigest(),
                body_base64=base64.b64encode(body).decode())


def git(*args):
    result = subprocess.run(['git', '--no-replace-objects', *args], cwd=ROOT,
                            stdin=subprocess.DEVNULL, capture_output=True, timeout=30)
    assert result.returncode == 0 and not result.stderr, 'native Git read'
    return result.stdout


def native_inputs():
    rows = []
    for revision, path in INPUTS:
        entry = git('ls-tree', '--full-tree', '-l', '-z', revision, '--', path)
        assert entry.count(b'\0') == 1, 'one native source member'
        header, name = entry[:-1].split(b'\t')
        mode, kind, oid, size = header.decode().split()
        assert mode == '100644' and kind == 'blob' and name.decode() == path
        body = git('show', revision + ':' + path)
        assert size.isdecimal() and len(body) == int(size)
        assert hashlib.sha1(b'blob ' + str(len(body)).encode() + b'\0' + body).hexdigest() == oid
        assert body == git('cat-file', 'blob', oid), 'independent native body retrieval'
        rows.append(dict(revision=revision, path=path, mode=mode, oid=oid,
                         retention_contract='fsmgen_required_history', body=blob(body)))
    return rows


def bodies(rows):
    assert type(rows) is list and len(rows) == len(INPUTS), 'complete native input population'
    result = {}
    for row, (revision, path) in zip(rows, INPUTS):
        assert type(row) is dict
        assert set(row) == {'revision', 'path', 'mode', 'oid', 'retention_contract', 'body'}
        equal(row['revision'], revision)
        equal(row['path'], path)
        equal(row['mode'], '100644')
        equal(row['retention_contract'], 'fsmgen_required_history')
        body = base64.b64decode(row['body']['body_base64'], validate=True)
        equal(row['body'], blob(body))
        equal(row['oid'], hashlib.sha1(b'blob ' + str(len(body)).encode() + b'\0' + body).hexdigest())
        result[path] = body
    return result


def proposed(before):
    text = before.decode()
    start = text.index('reverify: >-\n')
    end = text.index('\n---\n', start)
    text = text[:start] + 'reverify: >-\n  scripts/run_with_ram_guard.sh -- bash\n  ' + HELPER + text[end:]
    text = text.replace('\ndate:', '\n  - ' + json.dumps(QUESTION) + '\ndate:', 1)
    return (text + FACT).encode()


def review_card(candidate, before):
    assert len(candidate) <= len(before), 'non-growing Knowledge Map card bytes'
    assert candidate == proposed(before), 'all prior facts/questions/metadata exact; one finite addition'


def select_card(saved, read_current, current):
    return read_current() if current else saved


def expand_words(text):
    """Finite literal shell vocabulary only; no interpreter or substitution."""
    assert re.fullmatch(r'[a-z_,{} ]+', text), 'literal brace-word domain'
    result = []
    for word in text.split():
        match = re.fullmatch(r'([a-z_]+)\{([a-z_,]+)\}', word)
        words = [match[1] + suffix for suffix in match[2].split(',')] if match else [word]
        assert all(re.fullmatch(r'[a-z_]+', item) for item in words)
        result.extend(words)
    return result


def card_commands(before):
    block = before.decode().split('reverify: >-\n', 1)[1].split('\n---\n', 1)[0]
    parts = shlex.split(' '.join(line.strip() for line in block.splitlines()))
    equal(parts[:10], ['scripts/check_claim_verification.pl', '&&', 'prove', '-Iperl',
        't/1636-claim-verification-doctrine.t', '&&', 'scripts/run_with_ram_guard.sh', '--', 'bash', '-c'])
    assert len(parts) == 11
    loop = re.fullmatch(r'for r in ([a-z_,{} ]+); do python3 -B\s+' +
        re.escape(AUDIT) + r'\$r.py \|\| exit; done', parts[10])
    assert loop, 'original card loop grammar'
    commands = [parts[:1], parts[2:5]]
    commands += [['python3', '-B', AUDIT + name + '.py']
                 for name in [*expand_words(loop[1]), 'operand_inventory']]
    return commands + [['python3', '-B', CREATOR, '--current']]


def helper_commands(body):
    """Independent command population from the native helper's source sites."""
    text = body.decode()
    equal(re.findall(r'^task_reader_audit=(.*)$', text, re.M), [AUDIT.rstrip('/')])
    loops = re.findall(r'^for task_reader in (.*); do$', text, re.M)
    assert len(loops) == 1
    assert text.count('    run_saved_reader python3 -B "$task_reader_audit/$task_reader.py"\n') == 1
    singles = re.findall(r'^run_saved_reader (.*)$', text, re.M)
    assert len(singles) == 3
    commands = [shlex.split(line) for line in singles[:2]]
    commands += [['python3', '-B', AUDIT + name + '.py'] for name in expand_words(loops[0])]
    commands += [shlex.split(singles[2].replace('"$task_reader_audit/', '"' + AUDIT))]
    return commands


def refusal(check, *args):
    try:
        check(*args)
    except AssertionError as error:
        return str(error)
    raise AssertionError('changed candidate admitted')


def creator_text(creator, key):
    """Read descriptive literal fields without evaluating the creator."""
    functions = [node for node in ast.parse(creator).body
                 if isinstance(node, ast.FunctionDef) and node.name == 'derive']
    assert len(functions) == 1
    returns = [node for node in functions[0].body if isinstance(node, ast.Return)]
    assert len(returns) == 1 and isinstance(returns[0].value, ast.Call)
    values = [node.value for node in returns[0].value.keywords if node.arg == key]
    assert len(values) == 1 and isinstance(values[0], ast.Constant) and type(values[0].value) is str
    return values[0].value


def reconstruct(rows):
    source = bodies(rows)
    before, creator, helper = source[CARD], source[CREATOR], source[HELPER]
    after = proposed(before)
    review_card(after, before)
    commands = card_commands(before)
    equal(helper_commands(helper), commands)
    controls = []
    for label, candidate in (
        ('card-overflow', after + b'x' * (len(before) - len(after) + 1)),
        ('lost-prior-question', after.replace(b'  - "where is the claim template review?"\n', b'', 1)),
        ('lost-prior-fact', after.replace(b'Module readers: retained stop; fixed closure qualified; data/effects open.\n', b'', 1))):
        assert candidate != after
        controls.append(dict(label=label, candidate=blob(candidate), refusal=refusal(review_card, candidate, before)))
    for label, candidate in (('omitted-command', commands[1:]), ('reordered-command', list(reversed(commands)))):
        controls.append(dict(label=label, candidate=candidate, refusal=refusal(equal, candidate, commands)))
    future = after.replace(b'  - "where are compile exec operands inventoried?"\n', b'', 1)
    observations = []

    def observe_future():
        observations.append('current card read')
        return future

    historical = select_card(after, observe_future, False)
    review_card(historical, before)
    assert observations == [], 'saved selection never consults current card'
    current_refusal = refusal(review_card, select_card(after, observe_future, True), before)
    equal(observations, ['current card read'])
    controls.append(dict(label='future-card-current-refusal', candidate=blob(future),
        saved_selected=blob(historical), observations=observations,
        refusal=current_refusal,
        scope='Real selector/reviewer intervention; no physical card mutation or historical reader.'))
    return dict(schema='fsmgen.executable_operand_fact_route.v1', revision=BEFORE_REVISION,
        before=blob(before), after=blob(after), question=QUESTION, commands=commands, controls=controls,
        actual=dict(command=['bash', HELPER, '--list'], status=0,
            stdout=''.join(''.join(word + ' ' for word in command) + '\n' for command in commands),
            stderr='', scope='Actual helper listing only; no listed reader, historical code or recipe executes.'),
        programme=blob(creator), helper=blob(helper),
        guard_placement=creator_text(creator, 'guard_placement'), scope=creator_text(creator, 'scope'))


def validate(rows, proof, authority):
    # Full native identity, not a re-sealable candidate's self-declared digest.
    equal(rows, authority)
    expected = reconstruct(rows)
    equal(proof, expected)
    return expected


def qualify():
    rows = native_inputs()
    source = bodies(rows)
    proof = json.loads(gzip.decompress(source[PROOF]))
    value = validate(rows, proof, rows)
    controls = []

    def reject(label, candidate_rows, candidate_proof):
        controls.append(dict(label=label, inputs=candidate_rows, proof=candidate_proof,
            refusal=refusal(validate, candidate_rows, candidate_proof, rows)))

    for index, (_, path) in enumerate(INPUTS):
        candidate = copy.deepcopy(rows)
        changed = source[path] + b'\n'
        candidate[index]['body'] = blob(changed)
        candidate[index]['oid'] = hashlib.sha1(b'blob ' + str(len(changed)).encode() + b'\0' + changed).hexdigest()
        reject('rehashed-source-' + str(index), candidate, proof)
    reject('missing-input', rows[:-1], proof)
    candidate = copy.deepcopy(rows)
    candidate[0]['revision'] = BEFORE_REVISION
    reject('wrong-source-revision', candidate, proof)
    for label, change in (
        ('lost-control', lambda x: x['controls'].pop()),
        ('wrong-receipt-status', lambda x: x['actual'].__setitem__('status', 1)),
        ('boolean-status', lambda x: x['actual'].__setitem__('status', False)),
        ('wrong-receipt-command', lambda x: x['actual']['command'].pop()),
        ('wrong-receipt-stream', lambda x: x['actual'].__setitem__('stdout', '')),
        ('omitted-command', lambda x: x['commands'].pop()),
        ('wrong-card', lambda x: x.__setitem__('after', blob(b'changed card'))),
        ('boolean-dimension', lambda x: x['before'].__setitem__('bytes', True))):
        candidate = copy.deepcopy(proof)
        change(candidate)
        reject(label, rows, candidate)

    # Actual read interception on this whole recovery path. Live card/helper
    # mutations and missing files are represented by a reader that always fails.
    # Native Git reads remain allowed; no current path can be read unnoticed.
    original = Path.open
    attempted = []

    def deny_open(path, *args, **kwargs):
        attempted.append(str(path))
        raise AssertionError('live filesystem input forbidden')

    try:
        Path.open = deny_open
        fresh = native_inputs()
        equal(validate(fresh, json.loads(gzip.decompress(bodies(fresh)[PROOF])), rows), value)
    finally:
        Path.open = original
    assert attempted == [], 'frozen recovery reads no live source/card/helper'
    return dict(schema='fsmgen.frozen_operand_route.v1', native_inputs=rows,
        original=value, controls=controls, denied_current_reads=attempted,
        programme=blob(Path(__file__).read_bytes()),
        scope='Complete native-pinned original route reconstruction only. New pure parsers and typed comparisons rederive the card transform, ordered child commands, complete captured listing receipt and original controls. Git object authenticity, Python AST/shlex and the declared finite shell vocabulary remain premises. The historical receipt is reconstructed, never a new execution observation. No original creator/helper/reader/model/recipe runs; live dispatch and whole sequence success remain separately owned.')


def main():
    if not __debug__:
        raise SystemExit('Acceptance assertions must be enabled.')
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--write', action='store_true')
    args = parser.parse_args()
    value = qualify()
    output = ROOT / OUTPUT
    for member in (*reversed(output.parents), output):
        if member == ROOT or not member.is_relative_to(ROOT):
            continue
        assert not member.is_symlink(), 'ordinary local publication path'
        if member.exists():
            assert member.stat().st_dev == ROOT.stat().st_dev, 'same-volume publication'
            assert not (member.is_dir() and (member / '.git').exists()), 'primary repository only'
    if args.write:
        body = (json.dumps(value, sort_keys=True, separators=(',', ':'), allow_nan=False) + '\n').encode()
        with output.open('xb') as stream:
            stream.write(gzip.compress(body, mtime=0))
    else:
        equal(json.loads(gzip.decompress(output.read_bytes())), value)
    print('Frozen original route reconstructs completely; live filesystem reads are denied.')


if __name__ == '__main__':
    main()
