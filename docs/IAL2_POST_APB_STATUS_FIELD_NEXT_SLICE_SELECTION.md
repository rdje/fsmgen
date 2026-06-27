# IAL2 Post APB Status Field Next Slice Selection

Task-tree owner:
`IAL2-FEATURE-COMPLETENESS-FRONTIER.578`

Date: 2026-06-27

## Summary

`.578` selects `IAL2-FEATURE-COMPLETENESS-FRONTIER.579`, a no-behavior APB
multi-register decode readiness audit. The audit must decide the precise next
owner before any parser, generator, sample, support-accounting, validation,
schedule/check/semantic JSON, HDL/runtime, direct backend, verification-output,
backend-language, AXI, APB, or VHDL behavior changes.

## Read Inputs

The selector read the active resume/task context, APB status behavior and
contract records, the APB busy/public-sync predecessor records, APB
requester-transfer/completer/composition/profile-alias behavior records, the
current APB sources, focused APB tests, README, ROADMAP_V2, mdBook backlog and
language-surface chapters, task tree, Memory, Knowledge Map, and relevant IAL2
decisions.

The selector also rechecked current APB schedule reports for:

```bash
./bin/fsmgen --quiet --emit-schedule-json ppif/apb_requester_transfer_status.ppif
./bin/fsmgen --quiet --emit-schedule-json ppif/apb_composition_status.ppif
./bin/fsmgen --quiet --emit-schedule-json ppif/apb_completer.ppif
```

## Evidence

Status-capable APB requester-transfer and fixed-composition reports no longer
carry the requester busy/status deferral residues. The remaining status-capable
composition report still carries `apb_multi_register_decode_deferred` because
the shipped fixed APB completer endpoint remains a single address-0 register
shape.

The APB completer public surface is intentionally narrow today:

- `ppif/apb_completer.ppif` describes one register named `data`.
- The PPIF parser accepts exactly one `(register ...)` clause in an APB
  completer storage block.
- `ApbCompleter` normalizes one storage register at address 0 and emits the
  corresponding single-register schedule and report metadata.
- `ApbComposition` composes the same fixed one-requester/one-completer shape
  and keeps the multi-register decode residue in composition reports.
- `fsm/apb_completer.fsm` is the lower-layer generated-FSM review target for
  that single-register completer shape.

This residue is now narrower than the already-shipped requester status work.
It is also smaller than multi-peripheral topology, APB sideband/strobe
semantics, alternate data/address widths, back-to-back transfer policy, direct
backend lowering, verification-output generation, backend-language variants,
AXI follow-on work, or VHDL expansion.

## Selection

`.579` shall audit APB multi-register decode readiness. It must decide whether
the next owned slice should be:

- a public contract selection for multiple APB completer registers;
- a lower-layer/storage prerequisite;
- parser/report/static-validation readiness work;
- a generated-completer/composition implementation slice; or
- an explicit deferral with a better-supported successor.

The audit must read the `.578` selector, `.577` status behavior, `.576` status
contract, current APB requester/completer/composition/profile-alias behavior
records, current APB schedule reports, APB samples, `fsm/apb_completer.fsm`,
PPIF parser, `ApbCompleter`, `ApbComposition`, `RegressionCorpus`,
`LanguageSurfaceSection`, focused APB tests, README, ROADMAP_V2, mdBook, task
tree, Memory, Knowledge Map, and relevant IAL2 decisions.

## Non-Goals

`.578` changes no APB behavior. It does not change source syntax, parser
acceptance, diagnostics, generator logic, samples, support-accounting,
validation behavior, generated artifacts, JSON schemas, HDL/runtime behavior,
direct backend lowering, verification-output generation, backend-language
variants, AXI behavior, APB behavior, or VHDL behavior.

`.579` is also selected as an audit, not as an implementation. It must not
ship multi-register decode unless a later owned contract/implementation leaf
explicitly selects that behavior.

## Deferred Work

APB status-only samples, enum/custom status encodings, sticky status registers,
multi-peripheral APB decode/topology, sidebands/strobes, alternate APB widths,
back-to-back transfer policy, direct backend lowering, verification-output
generation, backend-language variants, AXI follow-on behavior, and VHDL remain
deferred outside `.578`.

## Validation Plan

The closeout validation for `.578` is documentation and doctrine focused:

```bash
./bin/fsmgen --quiet --emit-schedule-json ppif/apb_requester_transfer_status.ppif
./bin/fsmgen --quiet --emit-schedule-json ppif/apb_composition_status.ppif
./bin/fsmgen --quiet --emit-schedule-json ppif/apb_completer.ppif
rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\.578|IAL2-FEATURE-COMPLETENESS-FRONTIER\.579|apb_multi_register_decode_deferred|supports exactly one \(register|storage.register|address 0' docs/IAL2_POST_APB_STATUS_FIELD_NEXT_SLICE_SELECTION.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md perl/FSM/Adapter/IAL2/PPIF.pm perl/FSM/IAL2/ProtocolIntent/ApbCompleter.pm perl/FSM/IAL2/ProtocolIntent/ApbComposition.pm fsm/apb_completer.fsm
bash knowledge-map/scripts/gen_knowledge_map.sh
bash knowledge-map/scripts/check_knowledge_map.sh
scripts/check_memory_architecture.sh
env -u PERL5LIB prove -Iperl t/1414-docs-relative-paths-audit.t
mdbook build docs/book
git --no-pager diff --check
scripts/check_doctrines.sh
```

## Rollback

Rollback is doc-only: revert this selector, the corresponding fact card, the
task-tree frontier update, README, ROADMAP_V2, mdBook, Memory, and generated
Knowledge Map changes. The `.577` APB requester status behavior remains
unchanged.
