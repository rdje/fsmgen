---
id: ial2-post-task-acceptance-next-owner-selection
title: Public ISF presence-key synchronization follows portable TASK-ACCEPTANCE adoption
answers:
  - "what does IAL2-FEATURE-COMPLETENESS-FRONTIER.836 select?"
  - "what follows the portable TASK-ACCEPTANCE doctrine work?"
  - "why is public-sync leaf one selected before the mdBook rustdoc fence repair?"
  - "which ISF public presence keys are missing?"
  - "are the other public-sync failures still current?"
  - "does the post-doctrine selector activate the four-document lifecycle review?"
date: 2026-07-30
status: current
tags: [ial2, selector, public-contract, isf, documentation, tests]
evidence: docs/IAL2_POST_TASK_ACCEPTANCE_NEXT_OWNER_SELECTION.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/tasks/PUBLIC-SYNC-TEST-DRIFT-REPAIR.md; docs/tasks/MDBOOK-RUSTDOC-NON-RUST-FENCE-REPAIR.md; perl/FSM/Support/ISFPublicInterfaceContract.pm; t/1131-isf-public-top-level-discovery-audit.t; t/1250-isf-spec-focused-test-index-audit.t; t/1474-ial2-ahb-profile-alias.t
reverify: perl -Iperl -MFSM::Support::ISFPublicInterfaceContract=build_isf_public_interface_contract,isf_public_interface_public_top_level_keys -E 'my $c=build_isf_public_interface_contract(); my %k=map { $_=>1 } @{isf_public_interface_public_top_level_keys()}; say for sort grep { !$k{$_} } keys %$c;'
---

Parent selector `.836` chooses proposed
`PUBLIC-SYNC-TEST-DRIFT-REPAIR.1`. Current HEAD's public ISF contract payload
contains three verification-observation discovery families absent from
`isf_public_interface_public_top_level_keys()`:

- `schedule_report_verification_observation_keys`;
- `schedule_report_verification_observation_role_values`;
- `schedule_report_verification_observation_signal_keys`.

The correction is one authoritative-list edit and restores the failing t1131
public discovery gate without changing payload or product behavior. Current-
HEAD probes also keep public-sync `.2`/`.3` and the four-fence mdBook rustdoc
repair real, but they remain sequential or independent owners.

The scheduled four-document lifecycle review stays proposed and both status
files stay untouched. Explicitly director-gated items remain inactive.

Clean selector commit `06c03e6bf` activates only public-sync `.1`
continuity-only. The authoritative list and every product behavior remain
unchanged during activation; `.2` and `.3` stay pending.

Selected leaf `.1` now synchronizes all three names and restores an empty
payload/list difference plus t1131. `.2` and `.3` remain sequentially pending.

Clean `.1` commit `012660f90` activates only `.2`; the current ISF spec index
has five missing focused-test links and zero extras. `.3` stays pending.

Completed `.2` restores the exact 332/332 focused-test index and passes t1250
plus the guarded 295-file / 2,037-test ISF regression. `.3` remains pending.

Clean `.2` commit `4ba108b3d` activates only `.3`: current t1474 has one stale
aggregate-cardinality regex while the canonical public `.ahb` strict check is
green.

Completed `.3` restores t1474 and the six-file alias gate. Adjacent verification
roots four stale t1475/t1482 generated-IAL0 expectations to named-drive priority
commit `1dbff8fc6`; pending `.4` owns that separate repair.

Clean `.3` commit `ce891bbd7` activates only `.4` continuity-only for those
four rooted expectations; tests and implementation remain unchanged.
