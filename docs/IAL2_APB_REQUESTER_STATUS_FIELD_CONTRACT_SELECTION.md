# IAL2 APB Requester Status Field Contract Selection

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.576`

Date: 2026-06-27

## Outcome

`IAL2-FEATURE-COMPLETENESS-FRONTIER.576` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.577`, direct bounded implementation of an
additive APB requester named status-field contract for generated
requester-transfer and fixed requester/completer composition IAL2 sources.

This selector changes no parser, generator, sample, support-accounting,
validation, generated-artifact, schedule/check/semantic JSON, HDL/runtime,
direct backend, verification-output, backend-language variant, AXI, APB, or
VHDL behavior.

## Evidence Read

The selector read the current APB requester/composition surface and residue:

- `.575` post-public-sync selector;
- `.574` public-surface/import-tree sync;
- `.572` APB requester busy output behavior;
- `.571` APB busy/status contract selection;
- APB requester-transfer, completer, composition, and profile-alias behavior
  records;
- current busy-capable requester/composition reports and
  `apb_requester_status_field_deferred`;
- `FSM::Adapter::IAL2::PPIF` response parsing;
- `FSM::IAL2::ProtocolIntent::ApbRequesterTransfer` and
  `FSM::IAL2::ProtocolIntent::ApbComposition`;
- `RegressionCorpus`, `LanguageSurfaceSection`, and focused APB tests; and
- README, ROADMAP_V2, mdBook backlog/language-surface prose, task tree,
  Memory, and Knowledge Map.

The current busy-capable APB public response surface exposes:

```text
busy
done
last_error
last_read_data
```

Busy-capable requester-transfer and fixed-composition reports remove
`apb_requester_busy_status_deferred` and keep:

```text
apb_requester_status_field_deferred
```

The PPIF parser still rejects `(status ...)` in APB requester response blocks
at `.576` selection time.

## Selected Public Contract

The next behavior slice must be additive. Existing no-busy APB
requester-transfer and fixed-composition samples remain unchanged, and existing
busy-only samples remain unchanged.

The first status-field widening is selected as a bounded 2-bit code field, not
a one-bit summary, not a public enum/symbol set, and not a sticky status
register.

The selected source syntax adds a required-width status binding to the
busy-capable APB requester `response` block:

```text
(response
  (busy busy)
  (status status width 2)
  (done done)
  (read-data last_read_data width 32)
  (error last_error))
```

For the first implementation, `(status NAME width 2)` is accepted only when
the same APB requester response block also includes `(busy NAME)`. This keeps
the residue and sample matrix bounded while extending the shipped busy-capable
surface. Status-only requester samples remain deferred.

The selected status encoding is:

```text
0 idle
1 busy
2 done_ok
3 done_error
```

`idle` means no accepted transfer is in progress. `busy` covers generated setup
and access progress, including wait cycles before `PREADY`. `done_ok` is driven
on the completion pulse cycle when sampled `PSLVERR` is `0`. `done_error` is
driven on the completion pulse cycle when sampled `PSLVERR` is `1`. The field
returns to `idle` after the generated requester reaches idle again.

The existing `done`, `last_error`, and `last_read_data` outputs remain
authoritative. The named status field is a compact phase/result summary; it
does not replace those existing outputs.

## Generated Artifact Expectations

The status requester-transfer samples must lower through:

```text
.ppif/.apb -> generated apb_requester.isf -> generated apb_requester.fsm -> HDL
```

The generated requester interface must expose:

```text
busy
status[1:0]
done
last_error
last_read_data[31:0]
```

The generated `.isf` review artifact must declare the 2-bit status output and
drive status code `1` during setup/access progress. The implementation may use
split done drives, guarded transaction branches, or an equivalent existing IAL1
lowering pattern to drive `2` for successful completion and `3` for error
completion. It must not require a new IAL1 expression feature as a hidden
prerequisite.

The generated `.fsm` review artifact must make the status code visible with a
deterministic idle clear to `0`, transfer-state drive to `1`, and completion
drive to `2` or `3`.

The fixed-composition status samples must lower through the generated endpoint
review artifacts plus generated top `apb_tb.fsm`, and the generated top must
propagate the requester `status[1:0]` output alongside `busy`, `done`,
`last_error`, and `last_read_data[31:0]`.

## Support And Source Identity

The selected public samples are:

```text
ppif/apb_requester_transfer_status.ppif
ppif/apb_requester_transfer_status.apb
ppif/apb_composition_status.ppif
ppif/apb_composition_status.apb
```

The selected support-accounting entries are:

```text
intent.ppif_apb_requester_transfer_status
intent.apb_profile_alias_requester_transfer_status
intent.ppif_apb_composition_status
intent.apb_profile_alias_composition_status
```

The selected coverage names are:

```text
ial2_ppif_apb_requester_transfer_status_pipeline_cli
ial2_apb_profile_alias_requester_transfer_status_pipeline_cli
ial2_ppif_apb_composition_status_pipeline_cli
ial2_apb_profile_alias_composition_status_pipeline_cli
```

The `.ppif` samples use `source_kind: ppif`. The `.apb` samples use
`source_kind: ial2_profile_alias`. Check JSON and semantic JSON must preserve
the authored `.ppif` or `.apb` source path and the expected semantic root kind:
`fsm` for requester-transfer and `top` for fixed composition.

## Report And Residue Policy

Status-capable requester-transfer reports must preserve the normalized
`response.status` binding with name `status`, width `2`, and the selected
encoding metadata. Status-capable fixed-composition reports must expose the
same requester response binding in child metadata and in the generated top port
list.

Status-capable requester-transfer and fixed-composition reports must remove
`apb_requester_status_field_deferred`. Because the first status-capable samples
also include `busy`, they must also omit `apb_requester_busy_status_deferred`.

Existing no-busy APB requester-transfer and composition samples keep
`apb_requester_busy_status_deferred`. Existing busy-only requester-transfer and
composition samples keep `apb_requester_status_field_deferred`.

The following APB owners remain deferred:

```text
apb_multi_peripheral_decode_deferred
apb_interconnect_multi_peripheral_decode_deferred
apb_multi_register_decode_deferred
apb_protection_and_strobes_deferred
apb_alternate_widths_deferred
apb_back_to_back_policy_deferred
```

## Diagnostics

The implementation owner must keep fail-closed diagnostics for:

- `(status ...)` without `(busy ...)` in the same response block;
- malformed status syntax other than `(status NAME width 2)`;
- missing `width`;
- widths other than `2`;
- non-identifier status signal names;
- duplicate response clauses;
- status names colliding with `busy`, `done`, `error`, `read-data`, request,
  bus, or generated local names; and
- enum-like status declarations, custom encodings, multiple status fields, and
  status-only requester/composition samples.

Existing `.apb` missing-profile, wrong-profile, unsupported-object, and mixed
APB shape diagnostics remain in force.

## Validation Plan

The implementation owner should add focused coverage for:

```bash
./bin/fsmgen --quiet --emit-schedule-json ppif/apb_requester_transfer_status.ppif
./bin/fsmgen --quiet --strict --check --json ppif/apb_requester_transfer_status.ppif
./bin/fsmgen --quiet --strict --emit-semantic-json ppif/apb_requester_transfer_status.ppif
./bin/fsmgen --quiet --emit-schedule-json ppif/apb_requester_transfer_status.apb
./bin/fsmgen --quiet --strict --check --json ppif/apb_requester_transfer_status.apb
./bin/fsmgen --quiet --strict --emit-semantic-json ppif/apb_requester_transfer_status.apb
./bin/fsmgen --quiet --emit-schedule-json ppif/apb_composition_status.ppif
./bin/fsmgen --quiet --strict --check --json ppif/apb_composition_status.ppif
./bin/fsmgen --quiet --strict --emit-semantic-json ppif/apb_composition_status.ppif
./bin/fsmgen --quiet --emit-schedule-json ppif/apb_composition_status.apb
./bin/fsmgen --quiet --strict --check --json ppif/apb_composition_status.apb
./bin/fsmgen --quiet --strict --emit-semantic-json ppif/apb_composition_status.apb
```

Focused tests should cover requester/composition `.ppif` behavior, `.apb`
alias identity, support accounting, capability manifest/source-kind alignment,
generated `.isf`/`.fsm`/HDL status output shape, residue movement, no-busy and
busy-only sample preservation, targeted negative diagnostics, mdBook sync,
Knowledge Map sync, memory/doc path checks, and doctrine gates.

## Non-Goals

This selector does not implement status behavior. The selected implementation
also does not migrate existing no-busy or busy-only samples in place, accept
status without busy, add enum declarations, add custom status encoding, add a
sticky status register, add multi-peripheral APB interconnect/decode, add
multi-register decode, add APB sidebands or strobes, add alternate widths, add
back-to-back transfer policy, add direct IAL2-to-IAL0 lowering, add direct
backend lowering, add verification-output generation, add backend-language
variants, change AXI behavior, or add VHDL behavior.

## Rollback

Rollback of `.576` is documentation-only: revert this selector, its fact card,
and the task-tree/roadmap/book/memory updates. The `.572` APB busy output
behavior and `.574` public-surface/import-tree sync remain unchanged.
