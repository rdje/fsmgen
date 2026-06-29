# IAL2 Post Tri-Mode mdBook Next Slice Selection

- Work unit: `IAL2-FEATURE-COMPLETENESS-FRONTIER.694`
- Date: `2026-06-29`
- Status: selected
- Scope: no-behavior selection of the next IAL2 feature-completeness owner
  after the AXI/APB/AHB tri-mode mdBook documentation chain

## Decision

`IAL2-FEATURE-COMPLETENESS-FRONTIER.694` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.695`, an AHB IAL2 source-shape readiness
audit, as the next executable IAL2 owner.

The next slice must not implement AHB `.ppif` or `.ahb` behavior. It must audit
the current direct AHB requester seed, the IAL2 new-protocol workflow, suffix
and alias handling, PPIF parser/report surfaces, generated IAL1/IAL0 artifact
requirements, support-accounting requirements, and existing AHB residue before
contract selection or implementation.

## Evidence Read

This selector read:

- `MEMORY.md`, `docs/TASK_TREE.md`, and the active
  `docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md` frontier;
- the IAL2 new-protocol workflow in
  `docs/book/src/15a-ial2-new-protocol-support.md`;
- the current AHB user-facing boundary in
  `docs/book/src/16c-ial2-ahb.md`;
- the AHB boundary fact card
  `docs/knowledge/ial2-ahb-current-boundary-mdbook-coverage.md`;
- the tri-mode coverage audit
  `docs/IAL2_AXI_APB_AHB_TRIMODE_MDBOOK_COVERAGE_AUDIT.md`;
- profile-extension and non-AXI profile-alias facts, including `.ahb` as a
  future profile-alias candidate rather than a shipped surface;
- the APB interconnect/decode reusable-view fact that AXI, APB, and AHB must
  remain protocol-specific because their signal sets and contracts differ;
- direct AHB seed evidence in `fsm/amba_requester.fsm`, `bin/fsmgen`, and
  `perl/FSM/Support/RegressionCorpus.pm`.

## Rationale

The tri-mode documentation chain completed the user-facing map for AXI, APB,
and AHB. AXI and APB already have shipped IAL2 source surfaces. AHB is the
remaining protocol in that map with useful current support but no IAL2 source
surface: it has only the direct `fsm/amba_requester.fsm` fixture, and `.ahb`
still fails closed as an unsupported IAL2 alias candidate.

The IAL2 new-protocol workflow requires readiness or contract selection before
behavior. A direct implementation slice would be premature because the AHB
source object vocabulary, explicit profile policy, generated `.isf` shape,
generated `.fsm` shape, report schema, support identity, diagnostics, examples,
and residue are not selected.

The smallest safe next step is therefore an AHB source-shape readiness audit.

## Selected `.695` Boundary

`.695` must answer whether the next task should be:

- an AHB requester `.ppif` public contract selection;
- a smaller AHB evidence/source-vocabulary prerequisite;
- a `.ahb` profile-alias policy prerequisite;
- or a deferral in favor of a different exact IAL2 feature-completeness owner.

The audit must preserve current behavior:

- no parser changes;
- no generator changes;
- no public source or sample additions;
- no support-accounting catalog additions;
- no suffix behavior changes;
- no generated artifact changes;
- no HDL/runtime behavior changes;
- no AXI, APB, AHB, backend-language, verification-output, direct-backend, or
  VHDL behavior changes.

## Validation

Closeout for this selector should include:

- fact-card reverify;
- Knowledge Map generation/check;
- mdBook build;
- docs relative-path audit;
- memory architecture check;
- whitespace diff check;
- doctrine driver.

## Rollback

Rollback removes this selector note, its Knowledge Map fact card, task-tree
updates for `.694`/`.695`, README/ROADMAP/MEMORY/Knowledge Map updates, and
the generated Knowledge Map changes. No behavior changes are part of this
selector.
