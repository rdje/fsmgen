"""One-shot, data-only author of the prospective interruption control matrix."""
from pathlib import Path
import hashlib
import json
import re
import subprocess

BASE = Path(__file__).resolve().parent
ROOT = BASE.parents[2]
REVISION = '486f980ff3d0b5206a5ee93ec5765b5f86bd00cd'
OWNER = 'HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.3.1.2.2.5.5.2.3.1.2.2.3.2.15.7.3.12.4.1.3.6.4.1.1'
A = ROOT / 'docs/audits/native-proxy-lifetime-files-admission-20260913'
B = ROOT / 'docs/audits/native-proxy-lifetime-files-20260913'


def pin(path):
    path = Path(path)
    if not path.is_absolute(): path = ROOT / path
    raw = path.read_bytes()
    return dict(path=path.relative_to(ROOT).as_posix(), size_bytes=len(raw), sha256=hashlib.sha256(raw).hexdigest())


def write(name, value):
    with (BASE / name).open('xb') as stream:
        stream.write(json.dumps(value, sort_keys=True, indent=2, ensure_ascii=True).encode() + b'\n')


def main():
    # Expectations are authored from lifecycle roles, separately checked against
    # the unchanged earlier model and the retained successful call-prefix data.
    aa, ab, rt, ro, ra, rb = 'archive_a archive_b retire_target retire_other release_a release_b'.split()
    matrix = [
        ('runtime_pins', [aa,ab,ro,ra,rb], 'maintain_target', None, None, 'runtime_holds_image'),
        ('observation_a_pins', [aa,ab,rt,ro,rb], 'maintain_target', None, None, 'observation_a_holds_image'),
        ('observation_b_pins', [aa,ab,rt,ro,ra], 'maintain_target', None, None, 'observation_b_holds_image'),
        ('other_runtime_pins', [aa,ab,rt,ra,rb], 'maintain_target', None, None, 'other_runtime_holds_same_image'),
        ('release_before_archive', [], ra, None, None, 'release_before_archive'),
        ('repeated_release', [aa,ra], ra, None, None, 'repeated_release_rejects_absence'),
        ('unreaped_runtime', [], rt, 'unreaped_runtime', None, 'unreaped_runtime_leader'),
        ('unsettled_work', [aa], ra, 'unsettled_work', None, 'unknown_worker_group'),
        ('unsealed_work', [aa], ra, 'unsealed_work', None, 'unsealed_work'),
        ('reuse_after_retirement', [rt,aa], 'reuse_a', None, None, 'archive_after_retirement'),
        ('unknown_reference', [aa,ab,rt,ro,ra,rb], 'maintain_target', 'unknown_reference', None, 'unknown_reference_blocks_maintenance'),
        ('after_private_rmdir', [aa,ab,ra,rb,ro], rt, None, 'private_root', None),
        ('after_global_unlink', [aa,ab,ra,rb,ro], rt, None, 'runtime_global', None),
        ('after_last_observation_unlink', [aa,ab,rt,ro,ra], rb, None, 'observation_hold', 'post_unlink_failure'),
    ]
    cases = []
    for name, prefix, event, mutation, fault, model_control in matrix:
        refs = {'target','other','a','b'}
        workspaces = {'target','other'}
        for step in prefix:
            if step.startswith('retire_'):
                label = step.removeprefix('retire_'); refs.remove(label); workspaces.remove(label)
            elif step.startswith('release_'): refs.remove(step[-1])
        if mutation == 'unknown_reference': refs.add('unknown')
        before = dict(references=sorted(refs), workspaces=sorted(workspaces), image_present=True)
        if fault in ('private_root','runtime_global'): workspaces.remove('target')
        if fault == 'runtime_global': refs.remove('target')
        if fault == 'observation_hold': refs.remove('b')
        stem = 'fsmgen-LifetimeControls20260913_' + name
        roots = dict(store='.artifacts/tmp/native-proxy-image-custody/cases/' + stem,
            target='.artifacts/tmp/process-supervisor-tests/' + stem + '_target',
            other='.artifacts/tmp/process-supervisor-tests/' + stem + '_other',
            evidence='.artifacts/logs/native-proxy-observation-acquisition-20260910/cases/' + stem)
        after = dict(references=sorted(refs), workspaces=sorted(workspaces), image_present=True)
        cases.append(dict(name=name, profile='same_image', prefix=prefix, event=event, mutation=mutation,
            fault=fault, prior_model_control=model_control, roots=roots, before=before, after=after,
            expected_call_returned=event.startswith('release_'), expected_success=False,
            followup_maintenance=None if event=='maintain_target' else not refs,
            release_effect=None if not event.startswith('release_') else dict(unlink_attempted=int(bool(fault)),
                unlink_completed=0, reference_absence_verified=0, last_reference_check=None)))
    witnesses = []
    for label, number, ordinal in [('private_root',76,102),('runtime_global',76,163),('observation_hold',86,147)]:
        path = B / f'records/event-{number:06d}.json'
        record = json.loads(path.read_bytes()); stage = record['value']; call = stage['operation']['calls'][ordinal]
        removed = []
        for row in stage['operation']['calls'][:ordinal+1]:
            if row['operation']=='unlink' and row['returned']: removed.extend(row['paths'])
            if row['operation']=='rmdir' and row['returned']: removed.append(row['path'])
        witnesses.append(dict(role=label, record=pin(path), stage=stage['name'], case=stage['case'],
            ordinal=ordinal, call=call, successful_prefix_removals=removed,
            actual_interruption_observed=False))
    modules = {
        'maintenance': ('native-proxy-image-maintenance-20260910/ImageMaintenance.pm', ['_referenced','_admit_locked']),
        'retirement': ('native-proxy-runtime-retirement-20260910/RuntimeRetirement.pm', ['_request','_retire_locked','_release_locked']),
        'release': ('native-proxy-observation-archive-release-20260911/ObservationRelease.pm', ['_prepare','_admit_locked','_unlink_exact','release_observation_reference']),
        'work': ('native-proxy-observation-work-records-20260911/WorkRecord.pm', ['_sealed','_cleanup_settled','validate_work_settlement']),
        'reuse': ('native-proxy-observation-acquisition-20260910/ObservationAcquisition.pm', ['_admit_locked']),
        'coordination': ('native-proxy-image-coordination-20260910/Coordination.pm', ['_transaction']),
    }
    source = []
    for label, (relative, names) in modules.items():
        path = ROOT / 'docs/audits' / relative; text = path.read_text()
        matches = list(re.finditer(r'^sub ([A-Za-z_][A-Za-z0-9_]*)\s*\{', text, re.M))
        for name in names:
            index = next(i for i, match in enumerate(matches) if match[1]==name)
            start = matches[index].start(); end = matches[index+1].start() if index+1<len(matches) else text.rfind('\n1;')
            body = text[start:end]
            source.append(dict(role=label, name=name, path=path.relative_to(ROOT).as_posix(),
                first_line=text[:start].count('\n')+1, body=body, sha256=hashlib.sha256(body.encode()).hexdigest()))
    selection = json.loads((A/'selection.json').read_bytes())
    selection.update(schema='fsmgen.inactive_lifetime_control_selection.v1', owner=OWNER,
        execution_owner=OWNER.rsplit('.1.1',1)[0]+'.2', source_revision=REVISION, cases=cases,
        journal='.artifacts/logs/native-proxy-lifetime-controls-20260913/records',
        scope='Prospective source-bound selection only. Harness, independent journal reader and final execution admission are still unqualified.',
        repeated_observations='Healthy prefix follows the complete-file policy; the selected negative operation and explicit maintenance follow-up do not add implicit reuse calls.')
    selection['bounds'].update(cases=len(cases), fixture_roots=4*len(cases), total_wall_seconds=600, total_record_bytes=134217728)
    inputs = json.loads((A/'plan.json').read_bytes())['inputs']
    paths = {row['path'] for row in inputs}
    paths.update(str(p.relative_to(ROOT)) for p in [A/'qualify.pl',A/'LifetimeTrace.pm',A/'LifetimeFiles.pm',
        A/'support.py',A/'consume.py',A/'oracle.py',A/'selection.json',A/'prepared.json',B/'review.json'])
    paths.update(row['record']['path'] for row in witnesses)
    pins = [pin(path) for path in sorted(paths)]
    for row in pins:
        assert subprocess.check_output(['git','show',REVISION+':'+row['path']],cwd=ROOT)==(ROOT/row['path']).read_bytes()
    write('selection.json',selection)
    write('source-contracts.json',source)
    write('call-witnesses.json',witnesses)
    write('plan.json',dict(schema='fsmgen.inactive_lifetime_control_matrix.v1',owner=OWNER,source_revision=REVISION,inputs=pins,
        scope='Read-only source and inert data; no original main, fixture allocation, new actual control, native process, compiler, collector or live store.',
        fault_policy='Invoke the original successful syscall and record it before a one-shot exact operation/path selector throws. Scope selectors only to the selected API operation; disarm before probes, follow-up and cleanup. Missing or duplicate hits fail qualification.',
        mutation_policy='Only cloned receipt fields change, except unknown_reference creates one exclusive new owned file containing {} plus LF at references/'+('f'*64)+'.json, mode 0400. Existing shared objects are never replaced.',
        descriptor_policy='Retain primary outcome and all observed descriptors before separately recorded recovery. Recovery never promotes a failed or incomplete primary operation. Cleanup requires fresh exact owned identities and full membership; uncertainty or journal failure retains objects.',
        missing_legs=['New harness and independent journal reader source/data qualification','Committed final execution permit','Actual interruption effects and descriptor closure'],
        claim_legs=dict(rederivation='Current producer bodies and unchanged original pure model, with retained successful syscall-prefix witnesses.',falsification='Changed call selectors, incorrect ownership/effect predictions, missing cases and premature maintenance must reject.',durability='Pinned source epoch, exact first outputs, saved-only review, task tree, book, Knowledge Map and Git. Actual interruption qualification remains missing.')))
    print(json.dumps(dict(source_inputs=len(pins),cases=len(cases),source_functions=len(source),call_witnesses=len(witnesses),actual_controls_executed=0),sort_keys=True))


if __name__=='__main__': main()
