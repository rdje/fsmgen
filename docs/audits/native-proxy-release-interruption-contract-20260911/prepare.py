"""Prospective finite release transitions and exact source-boundary inventory."""
from __future__ import annotations

import hashlib
import json
from pathlib import Path
import re
import subprocess

BASE = Path(__file__).resolve().parent
ROOT = BASE.parents[2]
REVISION = 'da27b5cbaf01af7cbe294c8f851c8273dd750856'
RELEASE = 'docs/audits/native-proxy-observation-archive-release-20260911'
OWNER = 'HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.3.1.2.2.5.5.2.3.1.2.2.3.2.15.7.3.12.4.1.3.4.4.1'


def pin(path):
    raw = (ROOT / path).read_bytes()
    assert raw == subprocess.check_output(['git', 'show', REVISION + ':' + path], cwd=ROOT)
    return dict(path=path, size_bytes=len(raw), sha256=hashlib.sha256(raw).hexdigest())


def body(path, name):
    raw = (ROOT / path).read_bytes(); token = ('sub ' + name + ' {').encode()
    matches = list(re.finditer(rb'^' + re.escape(token), raw, re.M)); assert len(matches) == 1
    start = matches[0].start(); first_end = raw.index(b'\n', start) + 1
    end = first_end if raw[start:first_end].rstrip().endswith(b'}') else raw.index(b'\n}\n', first_end) + 3
    source = raw[start:end]
    return dict(path=path, symbol=name, start_line=raw[:start].count(b'\n') + 1,
                lines=source.count(b'\n'), size_bytes=len(source), sha256=hashlib.sha256(source).hexdigest())


def stages():
    attempt = dict(kind='unlink_attempt'); complete = dict(kind='unlink_complete')
    first_begin = dict(kind='absence_begin', phase='after_unlink')
    first_absent = dict(kind='absence_result', state='absent')
    finish_begin = dict(kind='absence_begin', phase='finish')
    finish_absent = dict(kind='absence_result', state='absent')
    unlinked = [attempt, complete]; first = unlinked + [first_begin, first_absent]
    finished = first + [finish_begin, finish_absent]
    return [
        ('before_prepare', [], [], ['original', 'absent', 'replacement']),
        ('before_lock', [], ['archive_sources'], ['original', 'absent', 'replacement']),
        ('before_unlink', [], ['lock', 'archive_sources', 'live_sources'], ['original']),
        ('unlink_rejected', [attempt], ['lock', 'archive_sources', 'live_sources'], ['original']),
        ('after_unlink', unlinked, ['lock', 'archive_sources', 'live_sources'], ['original']),
        ('first_absence_error', unlinked + [first_begin], ['lock', 'archive_sources', 'live_sources'], ['original']),
        ('first_absence_present', unlinked + [dict(kind='replacement_appears'), first_begin, dict(kind='absence_result', state='present')], ['lock', 'archive_sources', 'live_sources'], ['original']),
        ('after_first_absence', first, ['lock', 'archive_sources', 'live_sources'], ['original']),
        ('finish_absence_error', first + [finish_begin], ['lock', 'archive_sources', 'live_sources'], ['original']),
        ('finish_absence_present', first + [dict(kind='replacement_appears'), finish_begin, dict(kind='absence_result', state='present')], ['lock', 'archive_sources', 'live_sources'], ['original']),
        ('after_finish_absence', finished, ['lock', 'archive_sources', 'live_sources'], ['original']),
        ('complete', finished, ['lock', 'archive_sources', 'live_sources'], ['original']),
    ]


def build():
    cases = []
    for name, prefix, owners, initial_names in stages():
        # Enumerate only reports from a closure that exists at this abstract
        # phase. Each category is aggregate; concrete per-handle cases follow.
        for initial in initial_names:
            for bits in range(1 << len(owners)):
                errors = [owner for index, owner in enumerate(owners) if bits & (1 << index)]
                events = prefix + ([] if name == 'complete' else [dict(kind='error', error='primary:' + name)])
                cases.append(dict(name=name + ':' + initial + ':' + str(bits), stage=name, initial_name=initial,
                                  events=events, owned_closures=owners, close_errors=errors))
    sources = [
        (RELEASE + '/ObservationRelease.pm', {
            'safe_before_after': ['_prepare', '_archive_closure', '_coordinator_request', '_current_image', '_retain_live_sources', '_admit_locked', '_unlink_exact', '_assert_absent', '_release_locked', '_finish_locked'],
            'pure_not_selected': ['_same', '_copy'], 'closure_category_only': ['_close_owned'], 'public_envelope_only': ['release_observation_reference']}),
        ('docs/audits/native-proxy-image-coordination-20260910/Coordination.pm', {'safe_before_after': ['_names', '_structure', '_census', '_lock_identity'], 'coordinator_envelope_only': ['_transaction']}),
        ('docs/audits/native-proxy-image-custody-20260910/ImageCustody.pm', {'safe_before_after': ['_directory', '_members', '_recheck_source', 'read_entry'], 'before_only_returned_handle': ['_source']}),
        ('docs/audits/native-proxy-observation-archive-20260911/ObservationArchive.pm', {'safe_before_after': ['_limits', '_members', '_directory_closure', '_source_closure', '_receipt']}),
        ('docs/audits/native-proxy-runtime-census-20260910/ReferenceCensus.pm', {'safe_before_after': ['_image', '_inspect_locked', '_closure', '_matches_image', '_decode_record', '_filename_key'], 'pure_not_selected': ['_snapshot']}),
        ('docs/audits/native-proxy-runtime-retirement-20260910/PrivateWorkspace.pm', {'safe_before_after': ['_absent']}),
    ]
    boundaries = []
    for path, groups in sources:
        for category, names in groups.items():
            for name in names: boundaries.append(dict(body(path, name), category=category))
    prior = json.loads((ROOT / RELEASE / 'plan.json').read_bytes())
    paths = {row['path'] for row in prior['inputs']}
    paths.update(path for path, _ in sources)
    paths.update(RELEASE + '/' + name for name in ['ObservationRelease.pm', 'ReleaseTrace.pm', 'ReleaseFixture.pm', 'qualify.t', 'audit.py', 'plan.json', 'preflight-pins.json', 'corrected-auditor-pin.json', 'coordination-extension.json', 'contract.json', 'result/qualification.json', 'result/audit.json', 'result/admission.jsonl', 'result/qualify.tap', 'result/qualify.exit'])
    return dict(schema='fsmgen.inactive_release_interruption_contract.v1', owner=OWNER, source_revision=REVISION,
                inputs=[pin(path) for path in sorted(paths)], source_boundaries=boundaries, cases=cases,
                source_applicability='Every listed current input equals the exact completed release revision. Original prospective and separately corrected auditor pins retain their original timing; no retroactive rewrite or original producer rerun.',
                profiles=['ordinary_retired_other_observation', 'equal_reference_retired_other_observation', 'ordinary_active_runtime', 'ordinary_retired_last_observation'],
                phase_contract='Unlink attempt, successful unlink and checked absence are distinct monotonic facts. A precondition failure makes no new statement that the original hold is named. The latest absence check may be unknown or present while an earlier successful absence observation remains true. Actual fixture state and modeled reports must remain separate. Primary errors precede lock-close reports, which precede outer retained-source close reports.',
                transfer_contract='Retain actual returned source/lock/directory handles through the original verdict. A _source return is ownership observation, not a safe injected throw before its caller stores the handle. Lower-reader pre-handoff failures need their own observation/composition evidence. No faults around aggregate _close_owned or the public/coordinator return envelopes; close returns and deliberate omissions have dedicated domains. Caller-sealed helpers require caller-preserving instrumentation, proven against unchanged healthy behavior.',
                qualification_order=['healthy_call_and_handle_domain', 'call_readback_unlink_and_absence_interruptions', 'actual_close_then_modeled_error', 'omitted_close_then_separate_recovery', 'complete_saved_domain_and_source_join'],
                requirements=['unique planned and observed occurrence IDs', 'exact actual physical state before and after every selected operation', 'preserve first errors and all original failures', 'source/lock/directory descriptor identities and real close verdicts', 'every absent/disjoint allocated root and original admission journal', 'no private target read or archive reconstruction from live store', 'no publication, arbitrary process/callback or native execution', 'failed/cancelled outcomes retain their exact selected-work receipt bindings'],
                limits='Finite symbolic transitions and exact saved-case/source binding only. Each close category stands for owned handles; concrete per-handle reachability and cleanup coverage belong to later leaves. Replacement events are explicit model assumptions for future owned controls, not evidence of asynchronous-writer atomicity. No original matrix, new filesystem fixture, compiler/native/helper/collector, authenticated cleanup transport, prevention of later starts or product activation.')


if __name__ == '__main__':
    plan = build()
    with (BASE / 'contract.json').open('x') as stream: stream.write(json.dumps(plan, indent=2, sort_keys=True) + '\n')
    print(json.dumps(dict(cases=len(plan['cases']), sources=len(plan['inputs']), boundaries=len(plan['source_boundaries'])), sort_keys=True))
