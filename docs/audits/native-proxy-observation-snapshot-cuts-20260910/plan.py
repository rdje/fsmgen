"""Prospective source-flow enumeration, independent of the Perl event recorder."""
from __future__ import annotations

import json
from pathlib import Path

OWNER = 'HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.3.1.2.2.5.5.2.3.1.2.2.3.2.15.7.3.12.4.1.3.3.2.2.2.1'
REVISION = '730b8b3a2bb1e918d24a03d23a19b0066d159508'
TARGET_ROLES = ['wrapper','private','global','c','image']
DIRECTORY_ROLES = ['workspace','evidence','tools','image']


def trace(route: str) -> list[str]:
    roles = TARGET_ROLES + (['hold'] if route == 'reuse' else [])
    events = ['admit:enter','admit:prior:workspace','admit:prior:evidence',
              'admit:directory:tools','admit:directory:image']
    events += ['admit:read:'+role for role in roles]
    for phase in ('admit','acquire','finish'):
        if phase != 'admit': events.append(phase+':enter')
        if phase == 'finish':
            events += ['finish:hold:enter','finish:hold:read','finish:hold:check','finish:hold:return']
        events.append(phase+':sources:enter')
        for role in roles:
            events += [phase+':sources:original:'+role,phase+':sources:read:'+role,phase+':sources:fresh:'+role]
        events.append(phase+':directories:enter')
        events += [phase+':directory:'+role for role in DIRECTORY_ROLES]
    return events


def build() -> dict:
    traces = {route:trace(route) for route in ('fresh','reuse')}
    cases = []
    for route,events in traces.items():
        cases.append(dict(id=route+':complete',route=route,cut=None,returns=True,hold='complete'))
        for event in events:
            cases.append(dict(id=route+':'+event,route=route,cut=event,returns=False,
                hold='complete' if route == 'reuse' or event.startswith('finish:') else 'absent'))
    return dict(schema='fsmgen.inactive_observation_snapshot_cut_plan.v1',owner=OWNER,source_revision=REVISION,
        target_roles=TARGET_ROLES,directory_roles=DIRECTORY_ROLES,traces=traces,cases=cases,
        mutants=[dict(id=route+':omit_target_close',route=route) for route in ('fresh','reuse')],
        fixture='Four immediately recorded same-volume private roots per case. Acquire two original inert runtime images and independently seed another observation hold for the other image; reuse also begins with its exact successful primary acquisition. Keep all unrelated runtime/observation holds and bytes unchanged. Evidence directories use the already admitted observation-acquisition cases prefix. No process, compiler, native query, helper, archive or release is admitted.',
        checkpoints='Inject a synchronous exception at each declared function-entry event; finish:hold:return is after the temporary hold reader has explicitly closed and transfers only a byte snapshot. Source-read events fire before invoking the reader, never after it returns but before its caller can own the handle. Caller-sealed admission/acquire/finish wrappers tail-goto their originals. Complete event order must equal the independently enumerated source flow. These are finite called-function boundaries, not every instruction or an asynchronous crash model.',
        descriptors='Retain independent aliases to every returned ImageCustody source handle, the canonical writer when selected, and the permanent lock. Check all explicit closes before observer cleanup. Reconstruct the exact per-path source count: each structural-plus-semantic census phase reads every reference three times and each of two images as C four times, executable four times, manifest twice. Add only completed target/read-hold events and the fresh writer readback; post-publication census is complete before finish:enter. The writer and lock have separate exact counts. Deliberately omitted target closes must leave precisely five fresh or six reuse handles open, which the observer explicitly recovers.',
        publication_boundary='Fresh source failures before publication leave no primary hold. Every finish checkpoint follows complete exclusive publication and both post-publication censuses, so the complete hold remains despite no returned result. Reuse always preserves its original exact hold without publication. Empty/partial publication, census and final coordinator/close-report cuts belong to the sibling matrix slice.',
        limits='Inert snapshot interruptions only. Lower-reader failures before handoff, publication/coordinator cuts, real asynchronous crashes, archive/capture settlement, exact release, actual process ownership and native activation are not established by this slice.')


if __name__ == '__main__':
    path = Path(__file__).with_name('plan.json')
    path.write_text(json.dumps(build(),sort_keys=True,indent=2)+'\n')
