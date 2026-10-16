"""Review preservation and scoped native qualification before committing the leaf."""
from pathlib import Path
import base64
import gzip
import hashlib
import json
import re
import subprocess
from qualified_callers import TESTS

BASE = Path('docs/audits/ghdl-test-policy-20261012')


def load(name):
    path = BASE / name
    body = path.read_bytes()
    return json.loads(gzip.decompress(body) if path.suffix == '.gz' else body)


def run(command):
    result = subprocess.run(command, capture_output=True)
    return dict(command=command, status=result.returncode,
                stdout_base64=base64.b64encode(result.stdout).decode(),
                stderr_base64=base64.b64encode(result.stderr).decode())


def body_record(body):
    return dict(body_base64=base64.b64encode(body).decode(), bytes=len(body),
                sha256=hashlib.sha256(body).hexdigest())


def main():
    original_run = load('qualified-callers-20261016-v2-actual.json.gz')
    reset_run = load('qualified-reset-only-20261016-actual.json.gz')
    policy_run = load('focused-policy-actual.json.gz')
    owner = load('owner-final-20261016-actual.json')
    assert original_run['status'] == 1 and original_run['source_conserved']
    assert all(row['status'] == 0 and row['source_conserved']
               for row in [reset_run, policy_run, owner])
    original_sources = load('qualified-callers-20261016-v2-after.json.gz')
    policy_sources = load('focused-policy-after.json.gz')
    rows = {}
    for name in TESTS:
        result = subprocess.run(['git', 'show', 'HEAD:' + name], capture_output=True)
        assert result.returncode == 0
        current = Path(name).read_bytes()
        before, after = result.stdout.decode(), current.decode()
        here = r"<<'([A-Z][A-Z0-9_]*)'[^\n]*\n(.*?)^\1\s*$"
        old_blocks = re.findall(here, before, re.M | re.S)
        new_blocks = re.findall(here, after, re.M | re.S)
        assert old_blocks == new_blocks, name + ': heredoc fixture preservation'
        assertion = r'^\s*(?:ok|is|is_deeply|like|unlike|cmp_ok)\b[^\n]*$'
        assert re.findall(assertion, before, re.M) == re.findall(assertion, after, re.M), name
        unchanged_since_full_run = hashlib.sha256(current).hexdigest() == original_sources[name]['sha256']
        if '1901-' not in name:
            assert unchanged_since_full_run
        rows[name] = dict(head=body_record(result.stdout), current=body_record(current),
                          fixture_blocks_equal=True, assertion_lines_equal=True,
                          unchanged_since_failed_collection=unchanged_since_full_run)
    for name in ['t/lib/FSM/Test/HDLBehaviorRuntime.pm', 't/2069-hdl-behavior-runtime.t']:
        assert hashlib.sha256(Path(name).read_bytes()).hexdigest() == policy_sources[name]['sha256']
    fixture = 't/data/explicit_reset_behavior_tb.vhd'
    external = subprocess.run(['git', 'show', 'HEAD:' + fixture], capture_output=True)
    assert external.returncode == 0 and external.stdout == Path(fixture).read_bytes()
    queries = {}
    for flag in [[], ['--no-cache']]:
        result = run(['knowledge-map/scripts/query_knowledge_map.sh', *flag, '--all'])
        assert result['status'] == 0
        queries['direct' if flag else 'cached'] = result
    assert queries['cached']['stdout_base64'] == queries['direct']['stdout_base64']
    projected = {}
    for line in base64.b64decode(queries['direct']['stdout_base64']).decode().splitlines():
        question, identifiers, paths = line.split('\t')
        # The published query contract permits a question to name several facts.
        projected[question] = (set(identifiers.split(',')), set(paths.split(',')))
    card = load('knowledge-review.json')
    for question in [*card['old_answers'], card['new_answer']]:
        assert question in projected
        identifiers, paths = projected[question]
        assert 'test-subprocess-policy-adapters' in identifiers and card['path'] in paths
    assert Path(card['path']).read_text() == card['after']
    assert len(card['after'].encode()) <= len(card['before'].encode())
    book = load('book-review.json.gz')
    assert Path(book['path']).read_bytes() == base64.b64decode(book['after']['body_base64'])
    stage_records = {}
    for label in ['qualified-callers-20261016-v2', 'qualified-reset-only-20261016']:
        native = load(label + '-native.json.gz')
        records = [value['record'] for value in native['native_records'].values()]
        assert all(row['native']['ok'] and row['native']['cleanup']['leader_reaped']
                   and row['native']['cleanup']['group_gone'] for row in records)
        assert native['provider_before'] == native['provider_after']
        assert native['lint_provider_before'] == native['lint_provider_after']
        stage_records[label] = dict(collection_status=native['status'], stages=len(records),
                                    every_observed_native_stage_successful=True,
                                    providers_conserved=True)
    receipt = dict(owner='TASK-ACCEPTANCE-AUDIT-SOURCE-COVERAGE.1.1.2',
        programme=Path(__file__).resolve().relative_to(Path.cwd()).as_posix(),
        programme_body=body_record(Path(__file__).read_bytes()), caller_review=rows,
        external_oracle=body_record(external.stdout), query_results=queries,
        old_question_routes_retained=len(card['old_answers']), native_stage_review=stage_records,
        policy_watcher_sources_equal_to_passing_epoch=True,
        scope='Post-invocation preservation review against HEAD and actual captured sources. '
              'Eight unchanged caller files reported passing in the failed collection; the '
              'corrected reset-only file separately passed. This does not promote the failed '
              'aggregate to success or reconstruct any unavailable first before-image. '
              'SV runtime skips and full-CI/HIAL/push/visual boundaries retain.')
    with (BASE / 'final-review.json.gz').open('xb') as stream:
        stream.write(gzip.compress(json.dumps(receipt, sort_keys=True).encode(), mtime=0))
    print('Preserved original caller assertions/fixtures, passing policy sources, '
          'all old question routes and identical cached/direct projection.')


if __name__ == '__main__':
    main()
