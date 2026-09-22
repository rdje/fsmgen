"""Inventory current receipt producers and the closed launch frontier."""
import hashlib
import json
from pathlib import Path
import subprocess

BASE = Path(__file__).resolve().parent
ROOT = BASE.parents[2]
SCOPE = json.loads((BASE / 'scope.json').read_bytes())
PATHS = (
    'perl/FSM/Support/ProcessSupervisor.pm',
    't/lib/FSM/Test/ProcessSupervisor.pm',
    't/lib/FSM/Test/RustProxyFixture.pm',
    't/lib/FSM/Test/RustParityRuntime.pm',
    't/1669-task-acceptance-fixture-runtime.t',
    't/1816-rust-proxy-integration.t',
    'docs/audits/native-proxy-cleanup-receipts-20260910/CleanupReceipts.pm',
    'docs/audits/native-proxy-runtime-retirement-20260910/RuntimeRetirement.pm',
    'docs/audits/native-proxy-compiler-census-policy-admission-20260913/CompilerProfile.pm',
    'docs/audits/native-proxy-compiler-census-policy-admission-20260913/compile_profile.pl',
    'docs/audits/native-proxy-populated-worker-protocol-20260913/Protocol.pm',
    'docs/audits/native-proxy-compiler-census-policy-execution-20260913/first-results/inner/journal.jsonl',
    'docs/audits/native-proxy-compiler-census-policy-execution-20260913/first-results/inner/accepted-profile.json',
    'docs/audits/native-proxy-populated-worker-execution-20260914/review.json',
    'docs/audits/native-proxy-populated-lifetime-join-20260914/review.json',
)


def pin(relative):
    body = (ROOT / relative).read_bytes()
    committed = subprocess.check_output(
        ['git', 'show', SCOPE['source_revision'] + ':' + relative], cwd=ROOT)
    if body != committed:
        raise ValueError('inventory source differs from the selected revision: ' + relative)
    return dict(path=relative, size_bytes=len(body), sha256=hashlib.sha256(body).hexdigest())


def load():
    pins = [pin(path) for path in PATHS]
    return pins, {row['path']: (ROOT / row['path']).read_text() for row in pins}


def between(text, start, end):
    start_at = text.index(start)
    end_at = text.index(end, start_at)
    return text[start_at:end_at]


def derive(texts):
    public = between(texts['perl/FSM/Support/ProcessSupervisor.pm'],
                     'sub _finish_result {', 'sub _new_cleanup {')
    returned = [line.split('=>', 1)[0].strip()
                for line in public.split('return {', 1)[1].split('};', 1)[0].splitlines()
                if '=>' in line]
    private = between(texts['perl/FSM/Support/ProcessSupervisor.pm'],
                      'my $state = {', 'for my $entry (')
    cleanup = between(texts['docs/audits/native-proxy-cleanup-receipts-20260910/CleanupReceipts.pm'],
                      'sub cleanup_receipts_settled {', 'sub _settled_owner {')
    retirement = between(texts['docs/audits/native-proxy-runtime-retirement-20260910/RuntimeRetirement.pm'],
                         'sub retire_runtime_reference {', 'sub _snapshot_fields {')
    compiler = between(texts['docs/audits/native-proxy-compiler-census-policy-admission-20260913/CompilerProfile.pm'],
                       'sub state_receipt {', 'sub observe {')
    producer = between(texts['t/1669-task-acceptance-fixture-runtime.t'],
                       'sub retire_rust_proxy_workspace {', 'sub capture_error {')
    protocol = between(texts['docs/audits/native-proxy-populated-worker-protocol-20260913/Protocol.pm'],
                       'sub _cleanup {', 'sub _request {')
    journal = [json.loads(line) for line in texts[
        'docs/audits/native-proxy-compiler-census-policy-execution-20260913/first-results/inner/journal.jsonl'
    ].splitlines()]
    settled = [row for row in journal if row['event'] == 'compiler_settled']
    profile = json.loads(texts[
        'docs/audits/native-proxy-compiler-census-policy-execution-20260913/first-results/inner/accepted-profile.json'])
    populated = json.loads(texts['docs/audits/native-proxy-populated-worker-execution-20260914/review.json'])
    joined = json.loads(texts['docs/audits/native-proxy-populated-lifetime-join-20260914/review.json'])
    if tuple(case['compiler_pid'] for case in profile['cases']) != tuple(
            row['receipt']['pid'] for row in settled):
        raise ValueError('retained compiler profile and journal identities disagree')
    if any('pid' in row['receipt']['result'] for row in settled):
        raise ValueError('a retained public compiler result already carries process identity')
    if any(row['receipt']['ownership_scope'] !=
           'original direct fork and wait state; not loaded-image or general receipt authentication'
           for row in settled):
        raise ValueError('retained compiler ownership scope changed')
    return dict(
        schema='fsmgen.receipt_ownership_inventory.v1',
        owner=SCOPE['owner'],
        parent_owner=SCOPE['parent_owner'],
        next_owner=SCOPE['next_owner'],
        source_revision=SCOPE['source_revision'],
        public_result_keys=returned,
        public_result_carries_process_identity='pid' in returned,
        private_supervisor_state_records_pid='pid => $pid' in private,
        supervisor_callers=['FSM::Support::HDLExternalValidation', 'FSM::Test::ProcessSupervisor'],
        cleanup_predicate_requires_caller_supplied_array='my ($compiler, $outer, $stages) = @_;' in cleanup,
        cleanup_predicate_authenticates_owner=False,
        retirement_accepts_caller_cleanup_array='complete cleanup receipts' in retirement,
        compiler_observer_reads_private_supervisor_state='_start_supervision' in texts[
            'docs/audits/native-proxy-compiler-census-policy-admission-20260913/CompilerProfile.pm'],
        compiler_receipt_scope=compiler.split("ownership_scope => '", 1)[1].split("'", 1)[0],
        current_builder_returns_public_compilation_only='compilation => supervise_process(' in texts[
            't/lib/FSM/Test/RustProxyFixture.pm'],
        parity_stages_are_public_results='stages => \\@stages' in texts[
            't/lib/FSM/Test/RustParityRuntime.pm'],
        retirement_transport_uses_cleanup_flags_only='leader_started' in producer and 'pid' not in producer,
        populated_worker_retirement_tuple_is_synthetic='deliberately synthetic' in protocol,
        retained_compiler_receipts=[dict(
            mode=row['workspace'].rsplit('_', 1)[1],
            private_pid=row['receipt']['pid'],
            public_result_has_pid='pid' in row['receipt']['result'],
            cleanup_flags=row['receipt']['result']['cleanup'],
            ownership_scope=row['receipt']['ownership_scope']) for row in settled],
        populated_worker_evidence=dict(
            workers=populated['counts']['workers'],
            native_absence_receipts=populated['native_absence_receipts'],
            group_absence_receipts=populated['group_absence_receipts'],
            synthetic_retirement_and_work_records=populated['synthetic_retirement_and_work_records'],
            compiler_execution=populated['compiler_execution']),
        cooperative_join_still_marks_receipts_synthetic=joined['synthetic_retirement_and_work_records'],
        launch_frontier_closed=False,
        adapter_implemented=False,
        process_or_compiler_executed=False,
        missing_legs=SCOPE['missing_legs'])
