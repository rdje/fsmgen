"""Audit named prerequisite sources without launching fixtures or promoting scope."""

import argparse
import ast
import copy
import hashlib
import json
from pathlib import Path
import re
import subprocess

BASE = Path(__file__).resolve().parent
ROOT = BASE.parents[2]
CONTRACT = 'docs/audits/native-proxy-canonical-contract-20260910/contract.json'
PRIVATE = 'docs/audits/native-proxy-runtime-retirement-20260910/PrivateWorkspace.pm'
FIXTURE = 'docs/audits/native-proxy-runtime-retirement-20260910/audit.py'
PRODUCER = 't/1669-task-acceptance-fixture-runtime.t'


def read(path):
    return json.loads(path.read_bytes())


def pin(path):
    body = path.read_bytes()
    return dict(path=path.relative_to(ROOT).as_posix(), size_bytes=len(body),
                sha256=hashlib.sha256(body).hexdigest())


def source_profile(sources):
    producer = sources[PRODUCER].decode()
    rust = producer.split("subtest 'Rust parity rejects unresolved and misleading tool identities before building'", 1)[1]
    rust = rust.split("subtest 'legacy RAM-guard capture", 1)[0]
    assert "my $probe = File::Spec->catfile($mode_workspace, 'rust-tool-resolution');" in rust
    assert "write_executable($probe, <<'PROBE');" in rust
    writer = producer.split('sub write_executable {', 1)[1].split('\n}\n', 1)[0]
    modes = re.findall(r'chmod (0[0-7]+), \$path', writer)
    assert len(modes) == 1
    actual = int(modes[0], 8)
    private = sources[PRIVATE].decode()
    accepted = [int(mode, 8) for mode in re.findall(r'\$mode == (0[0-7]+)', private)]
    assert len(accepted) == len(set(accepted)) == 4
    wrappers = []
    for node in ast.walk(ast.parse(sources[FIXTURE])):
        if (isinstance(node, ast.Tuple) and len(node.elts) == 3
                and isinstance(node.elts[0], ast.Constant)
                and node.elts[0].value == 'rust-tool-resolution'):
            wrappers.append(ast.literal_eval(node))
    assert len(wrappers) == 1
    wrapper = wrappers[0]
    assert wrapper[1] == b'inert wrapper; never executed'
    assert wrapper[2] in accepted and actual not in accepted
    constants = {}
    for name in ('NODE_LIMIT', 'DEPTH_LIMIT', 'TOTAL_LIMIT'):
        match = re.search(r'my \$' + name + r' = ([0-9_]+);', private)
        assert match
        constants[name.lower()] = int(match[1].replace('_', ''))
    limits = re.findall(r'_source\("\$ROOT/\$path", \$mode, ([0-9_]+)\)', private)
    assert len(limits) == 1
    constants['file_limit'] = int(limits[0].replace('_', ''))
    return dict(producer_mode=format(actual, '04o'),
        accepted_modes=[format(value, '04o') for value in accepted],
        inert_wrapper_mode=format(wrapper[2], '04o'),
        producer_mode_rejected=True, inert_wrapper_mode_accepted=True,
        selected_policy_limits=constants, actual_compiler_capacity_established=False)


def validate(plan, finding, sources, task):
    contract = json.loads(sources[CONTRACT])
    assert plan['new_worker_compiler_native_or_collector_run'] is False
    assert len(plan['coverage']) == len(contract['required_falsifiers']) == 9
    assert len({row['id'] for row in plan['coverage']}) == 9
    for index, row in enumerate(plan['coverage']):
        assert row['contract_pointer'] == '/required_falsifiers/' + str(index)
        assert row['requirement'] == contract['required_falsifiers'][index]
        assert row['established_scope'] and row['missing_scope']
        assert row['closure'] == 'partial_or_pending'
        assert row['evidence'] and all(path in sources for path in row['evidence'])
        assert row['required_owners']
        for owner in row['required_owners']:
            assert task.count('- ID: `' + owner + '`\n') == 1
    names = ('workspace_profile', 'populated_workers', 'owner_receipts', 'inactive_composition', 'final_join')
    assert plan['prerequisite_owners'] == {name: plan['parent'] + '.' + str(index + 2)
                                         for index, name in enumerate(names)}
    assert plan['next_owner'] == plan['prerequisite_owners']['workspace_profile']
    for owner in plan['prerequisite_owners'].values():
        assert task.count('- ID: `' + owner + '`\n') == 1
    profile = source_profile(sources)
    assert finding['owner'] == plan['next_owner']
    assert finding['observed_producer_mode'] == profile['producer_mode']
    assert finding['accepted_prototype_modes'] == profile['accepted_modes']
    assert finding['inert_wrapper_mode'] == profile['inert_wrapper_mode']
    assert finding['status'] == 'owned_fix_pending'
    assert finding['actual_fixture_or_compiler_run'] is False
    assert finding['selected_empty_store_coordination_invalidated'] is False
    assert finding['retirement_capacity_still_unqualified'] is True

    workers = json.loads(sources['docs/audits/native-proxy-language-coordination-admission-20260913/plan.json'])
    actual = json.loads(sources['docs/audits/native-proxy-language-coordination-20260913/review.json'])
    assert workers['bounds']['fixture_file_bytes'] == 0
    assert {case['kind'] for case in workers['cases']} == {'pair', 'inheritance'}
    assert 'NativeProxyImageCoordination::inspect_store' in sources[
        'docs/audits/native-proxy-language-coordination-admission-20260913/worker.pl'].decode()
    assert actual['result']['cases'] == len(workers['cases']) == 12
    assert actual['result']['first_outcome_success']
    assert actual['result']['native_proxy_execution'] is False
    assert 'preinitialized empty stores' in actual['scope']
    builder = sources['t/lib/FSM/Test/RustProxyFixture.pm'].decode()
    assert "schema => 'fsmgen.test.rust_proxy_fixture.v1'" in builder
    assert 'fsmgen.test.rust_proxy_fixture.v2' not in builder
    assert '.artifacts/cache/rust-proxy-images/v1' not in builder
    sampler = sources['scripts/fixture_kernel_sampler.py'].decode()
    assert 'fixture = workspace / "rust-tools/rustup"' in sampler
    assert '.artifacts/cache/rust-proxy-images/v1' not in sampler
    collector = sources['scripts/fixture_policy_log.py'].decode()
    assert 'prefix = str(root / ".artifacts/tmp/process-supervisor-tests") + "/"' in collector
    assert '.artifacts/cache/rust-proxy-images/v1' not in collector
    cleanup = sources['docs/audits/native-proxy-cleanup-receipts-20260910/CleanupReceipts.pm'].decode()
    assert 'Neither receipt authenticity nor completeness' in cleanup
    assert "my ($compiler, $outer, $stages) = @_;" in cleanup
    return dict(workspace_profile=profile,
        selected_actual_empty_store_cases=actual['result']['cases'],
        actual_populated_worker_qualification_established=False,
        supplied_receipts_authenticate_owners=False,
        production_preparation_schema='fsmgen.test.rust_proxy_fixture.v1',
        live_native_path='private_workspace', live_path_filter='private_workspace',
        shared_preparation_native_observer_integration_established=False,
        public_collector_projection_integration_established=False,
        final_protocol_closure_established=False, new_live_execution=False)


def verify():
    for row in read(BASE / 'audit-pins.json'):
        assert pin(ROOT / row['path']) == row
    plan = read(BASE / 'plan.json')
    sources = {}
    for row in plan['inputs']:
        path = ROOT / row['path']
        assert pin(path) == row
        body = subprocess.check_output(['git', 'show', plan['source_revision'] + ':' + row['path']], cwd=ROOT)
        assert body == path.read_bytes()
        sources[row['path']] = body
    assert len(sources) == len(plan['inputs'])
    finding = read(BASE / 'workspace-compatibility-finding.json')
    original = (BASE / finding['correction']['original_annotation']).read_bytes()
    assert hashlib.sha256(original).hexdigest() == finding['correction']['original_sha256']
    assert json.loads(original)['inert_wrapper_mode'] == '0500'
    task = (BASE / 'frontier-task.md.source').read_text()
    result = validate(plan, finding, sources, task)
    mutations = (
        ('omitted_contract_clause', lambda p, f: p['coverage'].pop()),
        ('changed_contract_requirement', lambda p, f: p['coverage'][0].update(requirement='substituted')),
        ('missing_required_owner', lambda p, f: p['coverage'][1].update(required_owners=[])),
        ('untracked_required_owner', lambda p, f: p['coverage'][1].update(required_owners=['UNKNOWN-OWNER'])),
        ('source_scope_promoted_to_complete', lambda p, f: p['coverage'][1].update(closure='complete')),
        ('omitted_workspace_prerequisite', lambda p, f: p['prerequisite_owners'].pop('workspace_profile')),
        ('new_live_execution_promoted', lambda p, f: p.update(new_worker_compiler_native_or_collector_run=True)),
        ('inert_exec_mode_substituted_for_wrapper', lambda p, f: f.update(inert_wrapper_mode='0500')),
        ('producer_mode_normalized_to_fixture', lambda p, f: f.update(observed_producer_mode='0700')),
        ('unqualified_capacity_promoted', lambda p, f: f.update(retirement_capacity_still_unqualified=False)),
    )
    rejected = []
    for name, mutate in mutations:
        p, f = copy.deepcopy(plan), copy.deepcopy(finding)
        mutate(p, f)
        try:
            validate(p, f, sources, task)
        except (AssertionError, KeyError, ValueError):
            rejected.append(name)
        else:
            raise AssertionError('incorrect frontier accepted: ' + name)
    return dict(schema='fsmgen.native_proxy_protocol_frontier_review.v1',
        owner=plan['owner'], source_revision=plan['source_revision'],
        source_inputs=len(sources), source_bytes=sum(map(len, sources.values())),
        indexed_contract_clauses=len(plan['coverage']), result=result,
        next_owner=plan['next_owner'], prerequisite_owners=plan['prerequisite_owners'],
        rejected_controls=rejected, first_wrong_fixture_annotation_preserved=True,
        remaining_native_owners=[plan['native_admission_owner'], plan['native_execution_owner'],
                                 plan['disposition_and_activation_owner']], scope=plan['scope'])


def main():
    parser = argparse.ArgumentParser()
    group = parser.add_mutually_exclusive_group(required=True)
    group.add_argument('--retain', action='store_true')
    group.add_argument('--verify-saved', action='store_true')
    args = parser.parse_args()
    result = verify()
    if args.retain:
        with (BASE / 'review.json').open('x') as stream:
            json.dump(result, stream, sort_keys=True, indent=2)
            stream.write('\n')
    else:
        assert result == read(BASE / 'review.json')
    print(json.dumps(dict(source_inputs=result['source_inputs'],
        indexed_contract_clauses=result['indexed_contract_clauses'],
        rejected_controls=len(result['rejected_controls']),
        workspace_mode_mismatch=True, final_protocol_closure=False, new_live_execution=False), sort_keys=True))


if __name__ == '__main__':
    main()
