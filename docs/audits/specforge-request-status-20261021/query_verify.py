"""Recheck the retained query incident and bounded diagnostics, without a retry."""
import ast
import copy
import gzip
import hashlib
import json
import re
import subprocess
from pathlib import Path

AUDIT = Path(__file__).resolve().parent
ROOT = AUDIT.parents[2]
BASE = '15a9dceec64f26ba514102abbaf80bd9b367a7c4'
QUESTION = 'why did native0 prerequisites fail after custody?'
QUERY = ['knowledge-map/scripts/query_knowledge_map.sh', '--no-cache', QUESTION]
ROUTE = QUESTION + '\tclaim-verification-record-enforcement\tdocs/knowledge/claim-verification-record-enforcement.md\n'


def identity(raw):
    return dict(bytes=len(raw), sha256=hashlib.sha256(raw).hexdigest())


def historical(value):
    assert value['revision'] == BASE, 'incident native revision'
    assert type(value['status']) is int and value['status'] == 1, 'actual failed gate'
    log = value['log']['text']
    assert 'surface shipped_behavior transition debt exceeded' in log, 'separate book refusal'
    assert "subprocess.TimeoutExpired: Command '" + repr(QUERY) + "' timed out after 60 seconds" in log, 'exact query timeout'
    assert '[doctrine] one or more doctrine checks failed' in log, 'complete failed driver'
    names = ['scripts/check_source_recovery_card.sh',
             'docs/audits/original-join-parent-acceptance-20261018/rollover_source_card.py',
             'knowledge-map/scripts/query_knowledge_map.sh',
             'knowledge-map/scripts/knowledge_map.pl']
    for name in names:
        source = value['sources'][name]
        raw = source['text'].encode()
        assert identity(raw) == {key: source[key] for key in ('bytes', 'sha256')}, 'retained incident source'
        assert raw == subprocess.check_output(['git', 'show', BASE + ':' + name], cwd=ROOT), 'native incident source'
    tree = ast.parse(value['sources'][names[1]]['text'])
    function = next(node for node in tree.body
                    if isinstance(node, ast.FunctionDef) and node.name == 'command_output')
    call = next(node for node in ast.walk(function)
                if isinstance(node, ast.Call) and isinstance(node.func, ast.Attribute)
                and node.func.attr == 'run')
    limit = next(item.value for item in call.keywords if item.arg == 'timeout')
    assert isinstance(limit, ast.Constant) and type(limit.value) is int and limit.value == 60, 'original deadline'


def diagnostic(value):
    assert [row['label'] for row in value['cases']] == ['git-root', 'wrapper', 'direct-query'], 'distinct controls'
    for row in value['cases']:
        assert type(row['status']) is int and row['status'] == 0, 'integer diagnostic success'
        assert row['timed_out'] is False and row['group_absent'] is True, 'deadline and settlement outcome'
        assert row['owned_session'] is True and row['stderr'] == '', 'declared diagnostic placement'
    assert value['cases'][0]['stdout'] == '.\n', 'project Git root'
    assert value['cases'][1]['argv'] == QUERY, 'actual wrapper control'
    assert value['cases'][1]['stdout'] == value['cases'][2]['stdout'] == ROUTE, 'literal complete route'
    assert value['controller'] == identity((AUDIT / 'query-diagnostic-controller.py.source').read_bytes()), 'actual controller bytes'
    assert value['guard'] == {
        'FSMGEN_RAM_GUARD_ACTIVE': '1',
        'FSMGEN_RAM_GUARD_EFFECTIVE_HOST_MAX_PCT': '88',
        'FSMGEN_RAM_GUARD_EFFECTIVE_PROCESS_MAX_RSS_MB': '4096'}, 'unchanged memory envelope'


def standard(value):
    assert value['command'] == ['scripts/run_with_ram_guard.sh', '--', 'scripts/check_source_recovery_card.sh'], 'standard component command'
    assert type(value['status']) is int and value['status'] == 0, 'standard component status'
    lines = value['stdout_stderr'].splitlines()
    assert len(lines) == 2 and re.fullmatch(
        r'ram-guard: PID [0-9]+; host [0-9.]+%; host cutoff 88%; descendant RSS cutoff 4096 MiB; poll 2s',
        lines[0]), 'actual unchanged standard guard'
    assert lines[1] == ('source-recovery-card: exact retained source, live original questions, '
                        'current canonical/replay routes and public query results hold'), 'complete standard result'


if __name__ == '__main__':
    if not __debug__:
        raise SystemExit('Acceptance assertions must be enabled.')
    failure = json.loads(gzip.decompress((AUDIT / 'second-gate-refusal.json.gz').read_bytes()))
    controls = json.loads((AUDIT / 'query-diagnostic.json').read_bytes())
    current = json.loads((AUDIT / 'standard-query-qualification.json').read_bytes())
    historical(failure)
    diagnostic(controls)
    standard(current)
    for label in ('failure-status', 'timeout', 'source', 'success-kind', 'settlement', 'route', 'standard-status'):
        before, after = copy.deepcopy(failure), copy.deepcopy(controls)
        present = copy.deepcopy(current)
        if label == 'failure-status':
            before['status'] = True
        elif label == 'timeout':
            before['log']['text'] = before['log']['text'].replace('timed out after 60 seconds', 'timed out after 61 seconds')
        elif label == 'source':
            before['sources']['knowledge-map/scripts/query_knowledge_map.sh']['text'] += '\n'
        elif label == 'success-kind':
            after['cases'][1]['status'] = False
        elif label == 'settlement':
            after['cases'][1]['group_absent'] = False
        elif label == 'route':
            after['cases'][1]['stdout'] = 'borrowed route\n'
        else:
            present['status'] = False
        try:
            historical(before)
            diagnostic(after)
            standard(present)
        except AssertionError:
            pass
        else:
            raise AssertionError('changed incident evidence admitted: ' + label)
    print('Native failed gate and distinct current query controls qualify; altered source/status/type/route/settlement controls refuse. Historical timeout causality remains open under SEM.93.')
