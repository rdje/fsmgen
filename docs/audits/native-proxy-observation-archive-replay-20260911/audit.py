"""Independently verify saved-replay coverage, copied inputs and original preservation."""
from __future__ import annotations

import copy
import hashlib
import json
import os
from pathlib import Path
import re
import stat
import subprocess

BASE = Path(__file__).resolve().parent
ROOT = BASE.parents[2]
LOG = ROOT / '.artifacts/logs/native-proxy-observation-archive-replay-20260911'
REVISION = '698f99da3ca3dfe47b89fc17db142b3784f37907'
NAMES = ['records', 'files', 'boundaries', 'ordinary-fresh', 'ordinary-existing', 'equal-fresh', 'equal-existing']
CONTROLS = ['missing tracked input', 'altered tracked input', 'missing catalogue dependency',
            'wrong seed digest', 'wrong expected audit', 'unknown matrix', 'duplicate matrix',
            'symlink output parent', 'legacy-log content access forbidden', 'auditor failure',
            'altered audit result', 'non-root caller working directory',
            'repeated invocation uses a distinct output', 'original evidence remains unchanged']


def describe(raw):
    return dict(size_bytes=len(raw), sha256=hashlib.sha256(raw).hexdigest())


def load(path):
    return json.loads(path.read_bytes())


def authenticate(plan):
    assert plan['source_revision'] == REVISION and set(plan['matrices']) == set(NAMES)
    catalogue = {pin['path']: pin for pin in plan['inputs']}
    assert len(catalogue) == len(plan['inputs'])
    dependencies = set()
    for name in NAMES:
        matrix = plan['matrices'][name]
        directory = ROOT / 'docs/audits' / matrix['component']
        old = load(directory / 'plan.json')
        prospective = load(directory / 'result/preflight-pins.json')
        recovery = load(directory / 'result/recovery-copies.json')
        expected = {row['path'] for row in old['inputs'] + prospective}
        expected.update(str((directory / suffix).relative_to(ROOT)) for suffix in
                        ['plan.json', 'audit.py', 'result/preflight-pins.json', 'result/recovery-copies.json'])
        assert recovery['all_copies_byte_exact'] is True
        saved = {}
        for row in recovery['files']:
            path = ROOT / row['destination']
            assert path.parent == directory / 'result'
            assert row['source'] == matrix['historical_log'] + '/' + path.name
            assert path.name not in saved
            saved[path.name] = dict(path=row['destination'], size_bytes=row['size_bytes'], sha256=row['sha256'])
            assert saved[path.name] == catalogue[row['destination']]
            expected.add(row['destination'])
        assert matrix['source_paths'] == sorted(expected)
        dependencies.update(expected)
        names = ['preflight-pins.json', 'qualification.json', 'qualify.tap', 'qualify.exit']
        if name != 'records':
            names.append('admission.jsonl')
        assert matrix['seed'] == [saved[key] for key in names]
        assert matrix['expected_audit'] == saved['audit.json']
    assert dependencies == set(catalogue)
    for path, pin in catalogue.items():
        source = ROOT / path
        assert source.is_relative_to(ROOT) and not any(part == '..' for part in Path(path).parts)
        for parent in [source, *source.parents]:
            if parent == ROOT:
                break
            assert not parent.is_symlink() and parent.stat().st_dev == ROOT.stat().st_dev
        assert source.is_file()
        raw = source.read_bytes()
        assert describe(raw) == {key: pin[key] for key in ('size_bytes', 'sha256')}
        assert raw == subprocess.check_output(['git', 'show', REVISION + ':' + path], cwd=ROOT)
    return catalogue


def check_run(run, selected, plan):
    assert run['schema'] == 'fsmgen.inactive_archive_saved_replay.v1'
    assert run['success'] is True and run['source_revision'] == REVISION
    assert run['scope'] == 'saved evidence revalidation; no original producer, compiler, native experiment or release authority'
    directory = ROOT / run['output']
    assert directory.parent == LOG / 'runs' and re.fullmatch(r'run-[A-Za-z0-9_]+', directory.name)
    info = directory.lstat()
    assert stat.S_ISDIR(info.st_mode) and stat.S_IMODE(info.st_mode) == 0o700
    assert info.st_uid == os.getuid() and info.st_dev == ROOT.stat().st_dev
    assert load(directory / 'report.json') == run
    admission = load(directory / 'admission.json')
    assert admission == dict(schema='fsmgen.inactive_archive_replay_admission.v1', path=run['output'],
        device=info.st_dev, inode=info.st_ino, matrices=selected, source_revision=REVISION)
    assert [row['name'] for row in run['matrices']] == selected
    assert run['source_inputs'] == len({path for name in selected for path in plan['matrices'][name]['source_paths']})
    assert {path.name for path in directory.iterdir()} == {'admission.json', 'report.json', *selected}
    for row in run['matrices']:
        matrix = plan['matrices'][row['name']]
        output = directory / row['name']
        assert row['result'] == str((output / 'audit.json').relative_to(ROOT))
        raw = (output / 'audit.json').read_bytes()
        assert raw == (ROOT / matrix['expected_audit']['path']).read_bytes()
        assert describe(raw) == {key: row[key] for key in ('size_bytes', 'sha256')}
        assert row['reconstructed_inputs'] == len(matrix['seed'])
        assert {path.name for path in output.iterdir()} == {
            'audit.json', 'replay.stdout', 'replay.stderr', *(Path(pin['path']).name for pin in matrix['seed'])}
        for pin in matrix['seed']:
            source = ROOT / pin['path']
            assert (output / source.name).read_bytes() == source.read_bytes()
        assert (output / 'replay.stderr').read_bytes() == b''
        assert load(output / 'audit.json') == json.loads((output / 'replay.stdout').read_bytes())


def verify(plan, report, before, after):
    assert report['schema'] == 'fsmgen.inactive_archive_saved_replay_qualification.v1'
    assert report['success'] is True and report['original_evidence_unchanged'] is True
    assert before == after
    assert set(pin['path'] for pin in plan['inputs']) <= before.keys()
    assert report['prospective_pins'] == load(LOG / 'preflight-pins.json')
    root = report['root_cause']
    assert root['read_line'] == 32 and root['initialize_line'] == 46
    assert root['original_producer_executed'] is False and root['missing_read'] == 'FileNotFoundError'
    assert not (ROOT / root['missing_path']).exists()
    assert root['source'] == 'docs/audits/native-proxy-observation-archive-existing-calls-20260911/qualify.t'
    guard = report['guard']
    assert guard['content_opens'] > 0 and guard['git_commands']
    assert guard['forbidden_content_attempts'] == guard['forbidden_process_attempts'] == []
    for command in guard['git_commands']:
        assert command[0] == 'git' and ((len(command) == 4 and command[1:3] == ['cat-file', '-s'])
                                     or (len(command) == 3 and command[1] == 'show'))
        assert re.fullmatch(r'[0-9a-f]{40}:(?:docs|perl|t)/[A-Za-z0-9_./-]+', command[-1])
    controls = report['controls']
    assert [row['name'] for row in controls] == CONTROLS
    for row in controls[:8]:
        assert row['rejected'] is True and row['allocated_output'] is False and row['error']
    probe = controls[8]['probe']
    assert controls[8]['rejected'] is True and len(probe['forbidden_content_attempts']) == 1
    assert probe['content_opens'] == 0 and probe['git_commands'] == [] and probe['forbidden_process_attempts'] == []
    for row, fragment in zip(controls[9:11], ['saved audit failed', 'regenerated audit differs'], strict=True):
        failed = row['failure_report']
        assert row['rejected'] is True and failed['success'] is False and fragment in failed['error']
        assert failed['matrices'] == [] and load(ROOT / failed['output'] / 'report.json') == failed
    for row in controls[11:]:
        assert row['accepted'] is True
    assert controls[11]['cwd'] == str((LOG / 'runs').relative_to(ROOT))
    assert controls[13]['entries'] == len(before)
    assert len(report['executions']) == 3
    outputs = []
    for execution, selection in zip(report['executions'], [NAMES, ['records'], ['records']], strict=True):
        assert execution['exit'] == 0 and json.loads(execution['stdout']) == execution['report']
        check_run(execution['report'], selection, plan)
        outputs.append(execution['report']['output'])
    assert len(set(outputs)) == len(outputs)


def main():
    plan, report = load(BASE / 'plan.json'), load(LOG / 'qualification.json')
    catalogue = authenticate(plan)
    for pin in load(LOG / 'preflight-pins.json'):
        assert describe((ROOT / pin['path']).read_bytes()) == {key: pin[key] for key in ('size_bytes', 'sha256')}
    before, after = load(LOG / 'original-before.json'), load(LOG / 'original-after.json')
    # Independently reread original objects: do not trust the qualifier's equality flag.
    for path, row in after.items():
        current = ROOT / path
        info = current.lstat()
        assert (info.st_dev, info.st_ino, stat.S_IMODE(info.st_mode), info.st_size, info.st_mtime_ns) == (
            row['device'], row['inode'], row['mode'], row['size_bytes'], row['mtime_ns'])
        if row['kind'] == 'file':
            assert describe(current.read_bytes()) == {key: row[key] for key in ('size_bytes', 'sha256')}
        else:
            assert row['kind'] == 'directory' and stat.S_ISDIR(info.st_mode)
    verify(plan, report, before, after)
    mutations = [
        ('false success', lambda value: value.update(success=False)),
        ('false preservation', lambda value: value.update(original_evidence_unchanged=False)),
        ('producer executed', lambda value: value['root_cause'].update(original_producer_executed=True)),
        ('legacy content access', lambda value: value['guard']['forbidden_content_attempts'].append('forbidden')),
        ('non-Git process', lambda value: value['guard']['forbidden_process_attempts'].append('forbidden')),
        ('missing control', lambda value: value['controls'].pop()),
        ('accepted rejection', lambda value: value['controls'][0].update(rejected=False)),
        ('allocated rejection', lambda value: value['controls'][1].update(allocated_output=True)),
        ('missing matrix', lambda value: value['executions'][0]['report']['matrices'].pop()),
        ('wrong result digest', lambda value: value['executions'][0]['report']['matrices'][0].update(sha256='0' * 64)),
        ('failed CLI', lambda value: value['executions'][0].update(exit=1)),
        ('missing repeated execution', lambda value: value['executions'].pop()),
    ]
    rejected = []
    for name, mutate in mutations:
        changed = copy.deepcopy(report)
        mutate(changed)
        try:
            verify(plan, changed, before, after)
        except AssertionError:
            rejected.append(name)
        else:
            raise AssertionError('oracle accepted mutation: ' + name)
    changed = copy.deepcopy(after)
    changed[next(iter(changed))]['inode'] += 1
    try:
        verify(plan, report, before, changed)
    except AssertionError:
        rejected.append('changed original identity')
    else:
        raise AssertionError('oracle accepted changed original')
    assert (LOG / 'qualify.exit').read_text().strip() == '0'
    output = dict(schema='fsmgen.inactive_archive_saved_replay_audit.v1', success=True,
        matrices=len(NAMES), source_inputs=len(catalogue), input_bytes=sum(pin['size_bytes'] for pin in catalogue.values()),
        reconstructed_inputs=sum(len(matrix['seed']) for matrix in plan['matrices'].values()),
        qualification_controls=len(CONTROLS), report_falsifiers=rejected, original_entries=len(before),
        original_evidence_unchanged=True, legacy_content_attempts=0, forbidden_process_attempts=0,
        scope='Unchanged saved audit mains revalidate tracked first-run evidence. No historical producer or native experiment reruns, fresh fixture qualification, archive release, partial-write/close or startup-repair claim.')
    (LOG / 'audit.json').write_text(json.dumps(output, indent=2, sort_keys=True) + '\n')
    print(json.dumps(output, sort_keys=True))


if __name__ == '__main__':
    main()
