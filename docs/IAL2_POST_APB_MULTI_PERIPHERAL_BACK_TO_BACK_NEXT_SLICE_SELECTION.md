# IAL2 Post APB Multi-Peripheral Back-To-Back Next Slice Selection

- Work unit: `IAL2-FEATURE-COMPLETENESS-FRONTIER.610`
- Date: `2026-06-28`
- Status: selected
- Scope: next IAL2/APB owner selection only

## Summary

`IAL2-FEATURE-COMPLETENESS-FRONTIER.610` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.611`, an APB sideband-aware
back-to-back timing-policy readiness audit, as the next exact owner after the
selected no-sideband multi-peripheral back-to-back family shipped in `.609`.

This selector changes no parser behavior, generator behavior, samples,
support-accounting catalog entries, validation behavior, generated artifacts,
schedule/check/semantic JSON, HDL/runtime behavior, suffix acceptance, direct
backend lowering, verification-output generation, backend-language variants,
APB behavior, AXI behavior, AHB behavior, or VHDL behavior.

## Evidence Read

This selector reads the shipped `.609` behavior and the APB timing residue left
by:

- `docs/IAL2_APB_MULTI_PERIPHERAL_BACK_TO_BACK_BEHAVIOR.md`
- `docs/IAL2_APB_MULTI_PERIPHERAL_BACK_TO_BACK_READINESS_AUDIT.md`
- `docs/IAL2_APB_BACK_TO_BACK_BEHAVIOR.md`
- `docs/IAL2_APB_BACK_TO_BACK_CONTRACT_SELECTION.md`
- `docs/IAL2_APB_SIDEBAND_STROBE_BEHAVIOR.md`
- `docs/IAL2_APB_ALTERNATE_WIDTH_DATA16_BEHAVIOR.md`
- `docs/IAL2_APB_DATA16_PPROT_EFFECTS_BEHAVIOR.md`
- `perl/FSM/IAL2/ProtocolIntent/ApbRequesterTransfer.pm`
- `perl/FSM/IAL2/ProtocolIntent/ApbCompleter.pm`
- `perl/FSM/IAL2/ProtocolIntent/ApbComposition.pm`
- `perl/FSM/Support/RegressionCorpus.pm`
- `perl/FSM/Support/LanguageSurfaceSection.pm`
- focused APB composition/profile-alias/support tests
- `README.md`, `ROADMAP_V2.md`, and `docs/book/src/14-feature-backlog.md`
- `docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md`
- `docs/TASK_TREE.md`, `MEMORY.md`, and `KNOWLEDGE_MAP.md`

Live report residue review confirmed that selected no-sideband fixed and
multi-peripheral back-to-back surfaces now remove the broad
`apb_back_to_back_policy_deferred` residue, while the shipped sideband,
data16, and protection APB families still keep explicit back-to-back timing
residue.

## Selection

The next owner is an audit, not an implementation:

```text
IAL2-FEATURE-COMPLETENESS-FRONTIER.611
```

The audit target is sideband-aware APB back-to-back timing-policy support. This
is the nearest APB timing residue after `.607` and `.609` proved the
no-sideband fixed-composition and multi-peripheral propagation paths.

Sideband-aware back-to-back support is selected before data16/protection
back-to-back variants because the existing data16 and protection APB families
are sideband-aware extensions. The requester queued payload currently stores
the no-sideband request fields only, so sideband-aware back-to-back work first
needs an exact audit of queued `PPROT` and `PSTRB` capture, propagation, report
movement, diagnostics, validation, and rollback.

## Audit Scope For `.611`

`.611` must decide the exact implementation boundary before behavior changes.
The audit must cover:

- requester queued payload storage for address, write bit, write data, `PPROT`,
  and `PSTRB`;
- fixed-composition propagation of the selected sideband-aware requester and
  completer policies;
- multi-peripheral propagation only if it is safe in the same implementation
  owner;
- completer adjacent setup admission when sideband byte-lane writes and
  endpoint-local protection policies are present;
- report and unsupported-residue movement for selected sideband-aware surfaces;
- support-accounting and profile-alias impact if a behavior owner is selected;
- diagnostics for incompatible sideband/data16/protection timing-policy shapes;
- focused parser/generator/profile/support tests and direct CLI probes;
- docs, mdBook, README, ROADMAP_V2, task tree, Memory, and Knowledge Map sync;
- rollback boundary.

The audit may select a direct implementation owner, a narrower contract
selector, or a prerequisite if the code review finds that sideband-aware queued
payload capture should be split from composition propagation.

## Deferred Work

This selector does not select implementation for:

- data16/protection back-to-back variants;
- queue depths other than 1;
- overflow policies other than `reject`;
- accepted-less requester surfaces;
- multiple active APB bus transfers;
- multi-requester interconnects, bus matrices, scoreboards, or backend-owned
  APB arbitration;
- direct backend lowering or verification-output generation;
- backend-language variants, AXI, AHB, or VHDL behavior.

## Validation

This selector is documentation and task-tree only. Closeout validation is:

```bash
bash knowledge-map/scripts/gen_knowledge_map.sh
bash knowledge-map/scripts/check_knowledge_map.sh
mdbook build docs/book
prove -Iperl t/1414-docs-relative-paths-audit.t
scripts/check_memory_architecture.sh
git --no-pager diff --check
scripts/check_doctrines.sh
```

## Rollback

Rollback removes this selection document and the matching fact card, then
restores README, ROADMAP_V2, mdBook, task tree, Memory, and Knowledge Map to
the `.609` frontier with `.610` active. Because no parser, generator, sample,
support-accounting, generated artifact, JSON, HDL/runtime, backend, APB, AXI,
AHB, or VHDL behavior changes are made, rollback has no source or runtime
compatibility effect.
