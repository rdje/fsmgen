"""Conserve the complete prior fact card and saved reverify command sequence."""
import argparse
import gzip
import json
import re
import shlex
import subprocess

import bounded_runtime_inventory as bounded
import epoch_constraints as epoch
import execute
import prepare

REVISION = '3ecd34eaab9061eb5e39e63fd64e946d99995afe'
CARD = 'docs/knowledge/claim-verification-record-enforcement.md'
HELPER = execute.AUDIT / 'verify_claim_readers.sh'
PATH = execute.AUDIT / 'executable-operand-route-qualified.json.gz'
QUESTION = 'where are compile exec operands inventoried?'
FACT = ('\noperand_inventory.py: whole fixed-graph compile/exec syntax and token census;\n'
        'source/data bindings and runtime stay unqualified.\n')


def proposed(before):
    text = before.decode()
    start = text.index('reverify: >-\n')
    end = text.index('\n---\n', start)
    command = ('reverify: >-\n  scripts/run_with_ram_guard.sh -- bash\n  ' + str(HELPER))
    text = text[:start] + command + text[end:]
    text = text.replace('\ndate:', '\n  - ' + json.dumps(QUESTION) + '\ndate:', 1)
    return (text + FACT).encode()


def review_card(candidate, before):
    assert len(candidate) <= len(before), 'non-growing Knowledge Map card bytes'
    assert candidate == proposed(before), 'all prior facts/questions/metadata exact; one finite addition'


def review_commands(candidate, expected):
    bounded.strict_equal(candidate, expected)


def select_card(saved_after, read_current, current):
    return read_current() if current else saved_after


def derive(after):
    before = epoch.read(REVISION, CARD)
    review_card(after, before)
    old_reverify = before.decode().split('reverify: >-\n', 1)[1].split('\n---\n', 1)[0]
    parts = shlex.split(' '.join(line.strip() for line in old_reverify.splitlines()))
    assert len(parts) == 11
    assert parts[:10] == ['scripts/check_claim_verification.pl', '&&', 'prove', '-Iperl',
        't/1636-claim-verification-doctrine.t', '&&', 'scripts/run_with_ram_guard.sh', '--', 'bash', '-c']
    loop = re.fullmatch(r'for r in ([a-z_,{} ]+); do python3 -B\s+'
                       r'docs/audits/original-join-parent-acceptance-20261018/\$r.py \|\| exit; done', parts[10])
    assert loop, 'exact committed saved-reader loop grammar'
    # This executes only a whitelisted brace expansion, never the old command.
    expansion = subprocess.run(['bash', '-c', "printf '%s\\n' " + loop[1]], capture_output=True, cwd=execute.ROOT)
    assert expansion.returncode == 0 and not expansion.stderr
    names = expansion.stdout.decode().splitlines()
    assert all(re.fullmatch(r'[a-z_]+', name) for name in names)
    expected = [parts[:1], parts[2:5]] + [
        ['python3', '-B', str(execute.AUDIT / (name + '.py'))]
        for name in [*names, 'operand_inventory']]
    expected.append(['python3', '-B', str(execute.AUDIT / 'verify_operand_route.py'), '--current'])
    command = ['bash', str(HELPER), '--list']
    actual = subprocess.run(command, capture_output=True, cwd=execute.ROOT)
    assert actual.returncode == 0 and not actual.stderr
    review_commands([shlex.split(line) for line in actual.stdout.decode().splitlines()], expected)
    controls = []
    for label, candidate in (
        ('card-overflow', after + b'x' * (len(before) - len(after) + 1)),
        ('lost-prior-question', after.replace(b'  - "where is the claim template review?"\n', b'', 1)),
        ('lost-prior-fact', after.replace(b'Module readers: retained stop; fixed closure qualified; data/effects open.\n', b'', 1))):
        assert candidate != after
        try:
            review_card(candidate, before)
        except AssertionError as error:
            controls.append(dict(label=label, candidate=prepare.blob(candidate), refusal=str(error)))
        else:
            raise AssertionError('changed card admitted: ' + label)
    for label, candidate in (('omitted-command', expected[1:]), ('reordered-command', list(reversed(expected)))):
        try:
            review_commands(candidate, expected)
        except AssertionError as error:
            controls.append(dict(label=label, candidate=candidate, refusal=str(error)))
        else:
            raise AssertionError('changed command list admitted: ' + label)
    # A later, valid-shaped card edit must leave saved recovery independent of
    # the current observer, while current-card qualification must reject drift.
    future = after.replace(b'  - "where are compile exec operands inventoried?"\n', b'', 1)
    assert future != after
    observations = []

    def observe_future():
        observations.append('current card read')
        return future

    historical = select_card(after, observe_future, False)
    review_card(historical, before)
    assert observations == [], 'saved selection never consults current card'
    try:
        review_card(select_card(after, observe_future, True), before)
    except AssertionError as error:
        assert observations == ['current card read']
        controls.append(dict(label='future-card-current-refusal', candidate=prepare.blob(future),
            saved_selected=prepare.blob(historical), observations=observations, refusal=str(error),
            scope='Real selector/reviewer intervention; no physical card mutation or historical reader.'))
    else:
        raise AssertionError('future current-card drift admitted')
    return dict(schema='fsmgen.executable_operand_fact_route.v1', revision=REVISION,
        before=prepare.blob(before), after=prepare.blob(after), question=QUESTION,
        commands=expected, controls=controls, actual=dict(command=command, status=actual.returncode,
            stdout=actual.stdout.decode(), stderr=actual.stderr.decode(),
            scope='Actual helper listing only; no listed reader, historical code or recipe executes.'),
        programme=prepare.blob(execute.read(execute.AUDIT / 'verify_operand_route.py')),
        helper=prepare.blob(execute.read(HELPER)),
        guard_placement='The new outer RAM guard covers prior claim/prove checks as well as the saved readers; their ordered child commands remain exact. This is no whole execution/effect equivalence claim.',
        scope='Exact prior source/metadata/question/fact conservation, non-growing card and unchanged ordered prior child commands plus finite operand/route readers. Actual listing and genuine changed card/command candidates qualify only this route. Shared shell/shlex grammar is explicit.')


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--write', action='store_true')
    parser.add_argument('--current', action='store_true', help='also require the live card to match the capture')
    args = parser.parse_args()
    assert not (args.write and args.current), 'capture and current verification are separate modes'
    saved = None if args.write else json.loads(gzip.decompress(execute.read(PATH)))
    after = (execute.read(CARD) if args.write else select_card(
        prepare.unblob(saved['after']), lambda: execute.read(CARD), args.current))
    value = derive(after)
    if args.write:
        execute.save(PATH, value)
    else:
        bounded.strict_equal(saved, value)
    print('Prior fact/card/command order conserves exactly; the operand query is added without card growth or historical execution.')
