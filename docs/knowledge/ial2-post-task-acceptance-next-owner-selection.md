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
