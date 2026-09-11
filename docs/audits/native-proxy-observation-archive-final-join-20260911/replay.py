"""Reconstruct recorded replay relationships without opening old log directories."""
from __future__ import annotations

import json
from pathlib import PurePosixPath
import re

import evidence as E

NAMES = ['records', 'files', 'boundaries', 'ordinary-fresh', 'ordinary-existing', 'equal-fresh', 'equal-existing']
CONTROLS = ['missing tracked input', 'altered tracked input', 'missing catalogue dependency',
            'wrong seed digest', 'wrong expected audit', 'unknown matrix', 'duplicate matrix',
            'symlink output parent', 'legacy-log content access forbidden', 'auditor failure',
            'altered audit result', 'non-root caller working directory',
            'repeated invocation uses a distinct output', 'original evidence remains unchanged']
BASE = 'docs/audits/native-proxy-observation-archive-replay-20260911'
OLD_LOG = '.artifacts/logs/native-proxy-observation-archive-replay-20260911'
REVISION = '698f99da3ca3dfe47b89fc17db142b3784f37907'
AUXILIARY = {'book.exit', 'claim-inventory.stderr', 'claim-inventory.stdout', 'commit.stderr', 'commit.stdout',
             'staged-doctrines.exit', 'staged-doctrines.stderr', 'staged-doctrines.stdout',
             'task-integrity.stderr', 'task-integrity.stdout', 'document-checks.stderr', 'document-checks.stdout'}


def verify(plan, report, inventory, scope, *, recovery=None):
    assert plan['source_revision'] == REVISION and set(plan['matrices']) == set(NAMES)
    if recovery is None:
        recovery = E.document(BASE + '/result/recovery-copies.json')
    assert recovery['all_copies_byte_exact'] is True
    assert recovery['schema'] == 'fsmgen.inactive_archive_replay_recovery.v1'
    raw_map = {row['source']: row['destination'] for row in inventory['recovery_receipts']}
    assert len(raw_map) == len(inventory['recovery_receipts'])
    tracked = {row['path']: row for row in inventory['inputs']}
    bindings = recovery['reconstructed_seeds']
    seeds = {row['output']: row for row in bindings}; assert len(seeds) == len(bindings)
    for row in bindings:
        assert set(row) == {'output', 'tracked_source', 'size_bytes', 'sha256'}
        assert row['tracked_source'] in tracked
        assert E.digest(E.read(row['tracked_source'])[0]) == {key: row[key] for key in ('size_bytes', 'sha256')}
        assert row['output'] not in raw_map

    def raw(path):
        # This is a data mapping, never a redirect of a filesystem syscall.
        if path in raw_map:
            return E.read(raw_map[path])[0]
        assert path in seeds, 'unretained replay input: ' + path
        return E.read(seeds[path]['tracked_source'])[0]

    def document(path): return json.loads(raw(path))

    before = E.document(BASE + '/result/original-before.json')
    after = E.document(BASE + '/result/original-after.json')
    assert before == after
    assert {pin['path'] for pin in plan['inputs']} <= before.keys()
    body_files = 0; census_only = []; directories = []
    for path, row in before.items():
        assert row['kind'] in ('file', 'directory')
        assert type(row['device']) is type(row['inode']) is int and min(row['device'], row['inode']) > 0
        if row['kind'] == 'directory':
            directories.append(path); continue
        assert re.fullmatch('[0-9a-f]{64}', row['sha256']) and type(row['size_bytes']) is int and row['size_bytes'] >= 0
        if path in tracked:
            contents = E.read(path)[0]
        elif path in raw_map:
            contents = raw(path)
        else:
            assert path.startswith('.artifacts/logs/') and PurePosixPath(path).name in AUXILIARY
            census_only.append(dict(path=path, **row)); continue
        assert E.digest(contents) == {key: row[key] for key in ('size_bytes', 'sha256')}
        body_files += 1
    assert scope['before_after_equal'] is scope['all_declared_replay_seed_sources_tracked'] is True
    assert scope['objects'] == len(before) and scope['files'] == body_files + len(census_only)
    assert scope['tracked_raw_files'] == body_files and scope['census_only_files'] == census_only
    assert scope['allowed_auxiliary_names'] == sorted(AUXILIARY)

    assert report['schema'] == 'fsmgen.inactive_archive_saved_replay_qualification.v1'
    assert report['success'] is report['original_evidence_unchanged'] is True
    assert report['prospective_pins'] == E.document(BASE + '/result/preflight-pins.json')
    cause = report['root_cause']
    assert cause['read_line'] == 32 and cause['initialize_line'] == 46
    assert cause['original_producer_executed'] is False and cause['missing_read'] == 'FileNotFoundError'
    assert cause['source'] == 'docs/audits/native-proxy-observation-archive-existing-calls-20260911/qualify.t'
    assert not (E.ROOT / cause['missing_path']).exists()
    guard = report['guard']
    assert guard['content_opens'] > 0 and guard['git_commands']
    assert guard['forbidden_content_attempts'] == guard['forbidden_process_attempts'] == []
    for command in guard['git_commands']:
        assert command[0] == 'git' and ((len(command) == 4 and command[1:3] == ['cat-file', '-s'])
                                        or (len(command) == 3 and command[1] == 'show'))
        assert re.fullmatch(r'[0-9a-f]{40}:(?:docs|perl|t)/[A-Za-z0-9_./-]+', command[-1])
    controls = report['controls']; assert [row['name'] for row in controls] == CONTROLS
    for row in controls[:8]:
        assert row['rejected'] is True and row['allocated_output'] is False and row['error']
    probe = controls[8]['probe']
    assert controls[8]['rejected'] is True and len(probe['forbidden_content_attempts']) == 1
    assert probe['content_opens'] == 0 and probe['git_commands'] == probe['forbidden_process_attempts'] == []
    for row in controls[11:]: assert row['accepted'] is True
    assert controls[11]['cwd'] == OLD_LOG + '/runs' and controls[13]['entries'] == len(before)

    runs = []; expected_seeds = []; admissions = []
    def run(value, selected, success):
        assert value['schema'] == 'fsmgen.inactive_archive_saved_replay.v1'
        assert value['success'] is success and value['source_revision'] == REVISION
        assert value['scope'] == 'saved evidence revalidation; no original producer, compiler, native experiment or release authority'
        output = value['output']
        assert re.fullmatch(re.escape(OLD_LOG) + r'/runs/run-[A-Za-z0-9_]+', output)
        assert output not in runs; runs.append(output)
        assert document(output + '/report.json') == value
        admission = document(output + '/admission.json')
        assert set(admission) == {'schema', 'path', 'device', 'inode', 'matrices', 'source_revision'}
        assert admission['schema'] == 'fsmgen.inactive_archive_replay_admission.v1'
        assert admission['path'] == output and admission['matrices'] == selected and admission['source_revision'] == REVISION
        assert type(admission['device']) is type(admission['inode']) is int and min(admission['device'], admission['inode']) > 0
        admissions.append((admission['device'], admission['inode']))
        for name in selected:
            matrix = plan['matrices'][name]
            for pin in matrix['seed']:
                path = output + '/' + name + '/' + PurePosixPath(pin['path']).name
                expected = dict(output=path, tracked_source=pin['path'], size_bytes=pin['size_bytes'], sha256=pin['sha256'])
                assert seeds[path] == expected; expected_seeds.append(expected)
                assert raw(path) == E.read(pin['path'])[0]
        if not success:
            assert value['matrices'] == []; return
        assert value['source_inputs'] == len({path for name in selected for path in plan['matrices'][name]['source_paths']})
        assert [row['name'] for row in value['matrices']] == selected
        for row in value['matrices']:
            matrix = plan['matrices'][row['name']]; prefix = output + '/' + row['name']
            assert row['result'] == prefix + '/audit.json'
            contents = raw(row['result']); assert contents == E.read(matrix['expected_audit']['path'])[0]
            assert E.digest(contents) == {key: row[key] for key in ('size_bytes', 'sha256')}
            assert row['reconstructed_inputs'] == len(matrix['seed'])
            assert raw(prefix + '/replay.stderr') == b''
            assert json.loads(raw(prefix + '/replay.stdout')) == json.loads(contents)

    assert len(report['executions']) == 3
    for execution, selected in zip(report['executions'], [NAMES, ['records'], ['records']], strict=True):
        assert execution['exit'] == 0 and json.loads(execution['stdout']) == execution['report']
        run(execution['report'], selected, True)
    for row, fragment in zip(controls[9:11], ['saved audit failed', 'regenerated audit differs'], strict=True):
        value = row['failure_report']
        assert row['rejected'] is True and fragment in value['error']
        run(value, ['records'], False)
    cli = E.document(BASE + '/result/cli-review.json')
    assert cli['exit_code'] == 0 and cli['all_matrices_byte_exact'] is True
    assert cli['original_entries_unchanged'] == len(before)
    assert E.read(BASE + '/result/cli.exit')[0] == b'0\n'
    value = json.loads(E.read(BASE + '/result/cli.stdout')[0]); assert value['output'] == cli['new_output']
    run(value, NAMES, True)
    assert len(admissions) == len(set(admissions))
    assert len(expected_seeds) == len(seeds)
    assert {row['output']: row for row in expected_seeds} == seeds
    return dict(controls=len(controls), recorded_runs=len(runs), successful_recorded_runs=4,
                failed_recorded_runs=2, seed_bindings=len(bindings), source_inputs=len(plan['inputs']),
                preservation_objects=len(before), rehashed_preservation_files=body_files,
                census_only_auxiliary_files=len(census_only), recorded_preservation_directories=len(directories),
                old_log_content_reads=0, new_replay_invocations=0)
