# IAL2 AHB Requester PPIF Public Contract Selection

- Work unit: `IAL2-FEATURE-COMPLETENESS-FRONTIER.696`
- Date: `2026-06-29`
- Status: selected
- Scope: no-behavior selection of the first AHB requester `.ppif` public
  contract

## Decision

`IAL2-FEATURE-COMPLETENESS-FRONTIER.696` selects the first AHB requester
generic `.ppif` public contract.

The first future source is `ppif/ahb_requester.ppif`. It must use the generic
`.ppif` suffix, declare `(profile ahb)`, and contain exactly one bounded
`(ahb-requester amba_requester ...)` object. `.696` does not add that file and
does not implement parser or generator behavior.

`.696` selects `IAL2-FEATURE-COMPLETENESS-FRONTIER.697` as the implementation
owner for the selected first AHB requester `.ppif` behavior slice.

## Selected Future Source Shape

The future checked-in example must use this source shape:

```text
(protocol-platform-intent ahb_requester
  (profile ahb)
  (source
    (object fsmgen-ahb-requester)
    (anchor
      (document FSMGEN-AHB-REQUESTER-CAPTURE-WORKSHEET)
      (section bounded-requester)
      (page stage-1)))
  (ahb-requester amba_requester
    (role requester)
    (clock clk)
    (reset (rst_n active_low async))
    (local-command
      (valid cmd_valid)
      (ready cmd_ready)
      (write cmd_write)
      (address cmd_addr width 32)
      (write-data cmd_wdata width 32)
      (write-data-step cmd_wdata_step width 32)
      (size cmd_size width 3)
      (protection cmd_prot width 4)
      (lock cmd_lock)
      (burst cmd_burst width 3)
      (length cmd_len width 5))
    (local-status
      (busy busy)
      (beat-done beat_done)
      (done done)
      (burst-active burst_active)
      (wrap-active wrap_active)
      (beat-index beat_index width 5)
      (beats-remaining beats_remaining width 5)
      (active-address active_addr width 32)
      (active-burst active_hburst width 3)
      (last-error last_error)
      (last-retry last_retry)
      (last-split last_split)
      (last-response last_resp width 2)
      (last-read-data last_read_data width 32))
    (bus
      (grant HGRANT)
      (ready HREADY)
      (response HRESP width 2)
      (read-data HRDATA width 32)
      (request HBUSREQ)
      (lock HLOCK)
      (address HADDR width 32)
      (transfer HTRANS width 2)
      (write HWRITE)
      (size HSIZE width 3)
      (burst HBURST width 3)
      (protection HPROT width 4)
      (write-data HWDATA width 32))
    (burst
      (single 3'b000)
      (incr 3'b001)
      (wrap4 3'b010)
      (incr4 3'b011)
      (wrap8 3'b100)
      (incr8 3'b101)
      (wrap16 3'b110)
      (incr16 3'b111)
      (length-zero-means-one 1)
      (max-beats 16))
    (transfer
      (idle 2'b00)
      (nonseq 2'b10)
      (seq 2'b11)
      (first-beat nonseq)
      (later-beats seq)
      (advance-on ready))
    (response
      (okay 2'b00)
      (error 2'b01)
      (retry 2'b10)
      (split 2'b11)
      (error-action complete-error)
      (retry-action re-request)
      (split-action re-request)
      (read-sample last-read-data))))
```

The source shape intentionally mirrors the bounded direct
`fsm/amba_requester.fsm` seed rather than claiming complete AHB manager
coverage.

## Required Contract Rules

The implementation owner must enforce these public rules:

- source suffix: `.ppif` only;
- profile: exactly `(profile ahb)`;
- object: exactly one `(ahb-requester NAME ...)` object;
- object name selected for the first public source: `amba_requester`;
- role: `(role requester)` only;
- required blocks: `clock`, `reset`, `local-command`, `local-status`, `bus`,
  `burst`, `transfer`, and `response`;
- duplicate required blocks and duplicate fields fail closed;
- unsupported top-level clauses and unsupported `ahb-requester` clauses fail
  closed;
- selected widths: 32-bit address/data, 3-bit AHB size and burst, 4-bit AHB
  protection, 5-bit local length/index/count, 2-bit transfer and response;
- selected burst encodings: `SINGLE`, `INCR`, `WRAP4`, `INCR4`, `WRAP8`,
  `INCR8`, `WRAP16`, and `INCR16`;
- selected transfer behavior: first accepted beat uses `NONSEQ`, later
  accepted beats use `SEQ`, and `HREADY` is the transfer advance condition;
- selected response behavior: `OKAY` completes or advances, `ERROR` completes
  with error status, `RETRY` re-requests, and `SPLIT` re-requests;
- the source remains backend-language-neutral and must not depend on Perl-only
  semantics.

## Generated Artifacts

The first implementation must preserve the mandatory IAL2 lowering chain:

```text
ppif/ahb_requester.ppif -> generated amba_requester.isf -> generated amba_requester.fsm -> HDL
```

The generated IAL1 review artifact name is `amba_requester.isf`.

The generated IAL0 HDL entry artifact name is `amba_requester.fsm`.

The HDL module name is `amba_requester`.

No direct `.ppif` to `.fsm`, `.ppif` to HDL, or `.ahb` to `.fsm` lowering is
selected.

## Report And Support Accounting

The selected future IAL2 result kind is:

```text
protocol_intent.ahb_requester
```

The selected schedule/report schema is:

```text
fsmgen.ial2.protocol_intent.ahb_requester.v1
```

The report must include:

- `layering.source_layer = IAL2`;
- `layering.generated_ial1_format = isf`;
- `layering.generated_ial0_format = fsm`;
- `layering.direct_ial2_to_ial0 = 0`;
- source object id and anchors;
- target protocol profile `ahb`, object `ahb-requester`, and role
  `requester`;
- requester name and HDL actor name;
- normalized clock/reset, local-command, local-status, bus, burst, transfer,
  and response bindings;
- generated IAL1 and IAL0 artifact metadata;
- unsupported residue.

The selected support-accounting entry for the future public sample is:

```text
id: intent.ppif_ahb_requester
relpath: ppif/ahb_requester.ppif
family: protocol_fixture
classification: supported_smoke
coverage: ial2_ppif_ahb_requester_pipeline_cli
source_kind: ppif
strict_supported: 1
expected_module_name: amba_requester
expected_semantic_source_root_kind: fsm
```

The existing direct seed keeps its current support identity:
`protocol.amba_requester`, `source_kind: fsm`.

## Diagnostics

The implementation owner must add static diagnostics for:

- missing `(profile ahb)`;
- non-`ahb` profile on an `ahb-requester`;
- missing `(source ...)`;
- missing `(ahb-requester ...)`;
- duplicate `ahb-requester` objects;
- mixing `ahb-requester` with AXI Valid-Ready, AXI manager, or APB objects;
- missing required `ahb-requester` blocks;
- duplicate block or field names;
- unsupported block or field names;
- malformed width bindings;
- unsupported widths outside the selected first contract;
- unsupported burst, transfer, or response encodings;
- `.ahb` suffix use, which must keep the current unsupported-alias diagnostic.

## Later Implementation Examples

The implementation slice must add a checked-in `ppif/ahb_requester.ppif`
example and validate at least:

```bash
./bin/fsmgen --quiet --strict --check --json ppif/ahb_requester.ppif
./bin/fsmgen --quiet --emit-schedule-json ppif/ahb_requester.ppif
./bin/fsmgen --quiet --strict --emit-semantic-json ppif/ahb_requester.ppif
./bin/fsmgen --quiet --outdir /tmp/fsmgen-ahb-requester-out ppif/ahb_requester.ppif
./bin/fsmgen --quiet -o /tmp/fsmgen-ahb-requester.sv ppif/ahb_requester.ppif
```

The implementation closeout must also validate support accounting, generated
artifact names, mdBook coverage, Knowledge Map facts, memory architecture,
docs path audit, diff check, and the doctrine driver.

## `.ahb` Alias Deferral

`.ahb` remains unsupported after `.696`.

Future `.ahb` alias support requires a separate exact task-tree owner. That
owner must prove suffix/profile parity with the generic `.ppif` source and
must preserve the same generated `.isf`, generated `.fsm`, reports, support
accounting, diagnostics, and residue.

## Selected `.697` Boundary

`.697` is the first implementation owner for this selected contract. It may
change parser, generator, public source/sample, support accounting, report,
diagnostic, mdBook, and test behavior only for the bounded AHB requester
`.ppif` surface selected here.

`.697` must not implement `.ahb`, AHB completers/subordinates, AHB
interconnect/decode, scoreboards, full AHB manager behavior, direct IAL2
lowering, direct backend behavior, verification-output generation,
backend-language variants, AXI behavior, APB behavior, or VHDL behavior.

## Residue

The following remain deferred:

- `.ahb` profile-alias acceptance;
- AHB completer/subordinate behavior;
- AHB interconnect/decode or bus-matrix behavior;
- AHB scoreboards;
- broader AHB manager behavior beyond the bounded requester;
- configurable AHB address/data widths beyond the selected 32-bit first
  contract;
- optional AHB HPROT policy families beyond binding propagation;
- alternate response policies;
- direct IAL2-to-IAL0 or IAL2-to-HDL lowering;
- verification-output generation;
- direct backend behavior;
- backend-language variants;
- VHDL behavior.

## Validation

Closeout for `.696` should include:

- fact-card reverify;
- Knowledge Map generation/check;
- mdBook build;
- docs relative-path audit;
- memory architecture check;
- whitespace diff check;
- doctrine driver.

## Rollback

Rollback removes this contract-selection note, its Knowledge Map fact card,
task-tree updates for `.696`/`.697`, mdBook boundary wording, README/ROADMAP,
MEMORY/Knowledge Map updates, and generated Knowledge Map changes. No behavior
changes are part of `.696`.
