# IAL2 Post APB Public Sync Next Slice Selection

Date: 2026-06-27

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.575`

## Summary

`IAL2-FEATURE-COMPLETENESS-FRONTIER.575` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.576`, APB requester named status-field
public contract selection, before any parser, generator, sample,
support-accounting, validation, generated-artifact, JSON, HDL/runtime, direct
backend, verification-output, backend-language variant, AXI, APB, or VHDL
behavior change.

The selected next slice is intentionally a contract-selection slice, not an
implementation slice. The busy-capable APB requester and fixed-composition
reports now remove `apb_requester_busy_status_deferred` and keep the narrower
`apb_requester_status_field_deferred` residue. That is the smallest current
APB residue tied directly to the just-shipped busy public surface.

## Read Inputs

- `.574` public-surface/import-tree synchronization:
  `docs/knowledge/ial2-apb-public-surface-import-tree-sync.md`,
  `docs/BIN_FSMGEN_IMPORT_TREE.md`, and mdBook language-surface prose.
- `.573` post-busy selector:
  `docs/IAL2_POST_APB_BUSY_OUTPUT_NEXT_SLICE_SELECTION.md`.
- `.572` APB busy output behavior:
  `docs/IAL2_APB_REQUESTER_BUSY_OUTPUT_BEHAVIOR.md`.
- `.571` APB busy/status contract:
  `docs/IAL2_APB_REQUESTER_BUSY_STATUS_CONTRACT_SELECTION.md`.
- Current APB behavior pages:
  `docs/IAL2_APB_PPIF_REQUESTER_TRANSFER_BEHAVIOR.md`,
  `docs/IAL2_APB_PPIF_COMPLETER_BEHAVIOR.md`,
  `docs/IAL2_APB_PPIF_COMPOSITION_BEHAVIOR.md`, and
  `docs/IAL2_APB_PROFILE_ALIAS_BEHAVIOR.md`.
- Public roadmap and continuity surfaces:
  `README.md`, `ROADMAP_V2.md`, `docs/book/src/14-feature-backlog.md`,
  `docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md`,
  `docs/TASK_TREE.md`, `MEMORY.md`, and `KNOWLEDGE_MAP.md`.

## Selection

`.576` will choose the public contract for APB requester named status-field
exposure.

The contract-selection leaf must settle:

- exact APB requester response syntax for an optional named status field;
- whether the first status-field behavior is a one-bit summary, a bounded
  multi-bit status code, an enum-like public symbol set, or explicitly deferred
  again;
- how the field appears in generated `.isf`, `.fsm`, HDL ports, check JSON,
  semantic JSON, support accounting, and residue;
- whether fixed composition propagates the named field to the top level in the
  first implementation or requires a separate composition owner;
- diagnostics for duplicate response bindings, unsupported status shapes, width
  mismatches, and collisions with `busy`, `done`, `last_error`, or
  `last_read_data`;
- validation gates, docs/fact requirements, rollback, and non-goals before any
  behavior-bearing implementation starts.

## Why Not The Other APB Residue First

APB multi-peripheral decode and interconnect work changes topology and address
decode ownership. Multi-register decode changes completer storage and address
selection. Sidebands/strobes, alternate widths, and back-to-back policy change
bus semantics. Those remain important, but they need broader readiness and
contract work than the named status-field residue left directly by the busy
slice.

APB report-only cleanup is also deferred because the current busy-capable
reports already have the correct narrower named-status residue. Cleaning that
surface further before choosing the named status contract would risk moving
wording without settling the next user-visible APB field.

## Non-Goals

`.575` and the selected `.576` contract-selection slice do not implement a
status field and do not change parser behavior, generator behavior, samples,
support-accounting, validation behavior, generated artifacts, tests,
schedule/check/semantic JSON behavior, HDL/runtime behavior, direct backend
lowering, verification-output generation, backend-language variants, AXI
behavior, APB behavior, or VHDL behavior.

The following remain deferred behind future exact owners unless `.576`
explicitly selects otherwise:

- Status-field implementation.
- Existing no-busy sample migration.
- APB report-only cleanup beyond named-status contract selection.
- Multi-peripheral APB interconnect/decode.
- Multi-register APB decode.
- APB sidebands or strobes.
- Alternate APB widths.
- APB back-to-back transfer policy.
- Direct backend lowering.
- Verification-output generation.
- Backend-language variants.
- AXI follow-on behavior.
- VHDL behavior.

## Validation Plan

`.575` closeout should run:

```sh
rg -n 'apb_requester_status_field_deferred|apb_multi_register_decode_deferred|apb_protection_and_strobes_deferred|apb_alternate_widths_deferred|apb_back_to_back_policy_deferred' docs/IAL2_APB_REQUESTER_BUSY_OUTPUT_BEHAVIOR.md docs/IAL2_APB_REQUESTER_BUSY_STATUS_CONTRACT_SELECTION.md docs/IAL2_APB_PPIF_REQUESTER_TRANSFER_BEHAVIOR.md docs/IAL2_APB_PPIF_COMPLETER_BEHAVIOR.md docs/IAL2_APB_PPIF_COMPOSITION_BEHAVIOR.md docs/IAL2_APB_PROFILE_ALIAS_BEHAVIOR.md
bash knowledge-map/scripts/gen_knowledge_map.sh
bash knowledge-map/scripts/check_knowledge_map.sh
scripts/check_memory_architecture.sh
env -u PERL5LIB prove -Iperl t/1414-docs-relative-paths-audit.t
mdbook build docs/book
git --no-pager diff --check
scripts/check_doctrines.sh
```

## Rollback Boundary

Rollback is documentation-only: revert the `.575` selector commit and leave the
`.572` APB busy output behavior plus `.574` public-surface/import-tree sync
unchanged.
