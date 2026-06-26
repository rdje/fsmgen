# IAL2 APB PPIF Source-Shape Contract Selection

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.549`

Date: 2026-06-26

## Outcome

`IAL2-FEATURE-COMPLETENESS-FRONTIER.549` selects the public APB `.ppif`
source-shape contract for a first bounded APB requester-transfer object and
selects `IAL2-FEATURE-COMPLETENESS-FRONTIER.550`, direct bounded
implementation of that contract.

The contract keeps `.ppif` as the generic Protocol/Platform Intent Format
IAL2 container. It does not introduce `.apb`, `.pif`, `.ppi`, `.chi`, `.ace`,
`.ahb`, `.atb`, `.smbus`, `.i2s`, or any other suffix. AXI remains only the
first shipped profile-alias example; APB becomes the next selected non-AXI
protocol profile under `.ppif` after implementation.

This selector changes no parser behavior, generator behavior, PPIF sample,
support-accounting catalog, validation behavior, generated artifact, test,
schedule/check/semantic JSON behavior, HDL/runtime behavior, backend behavior,
verification-output generation, backend-language variant, external converter
dependency, scoreboard, AXI behavior, non-AXI behavior, common construct
promotion, profile-alias suffix syntax, generic-container alias syntax, direct
backend lowering, or VHDL behavior.

## Selected Source Shape

The first APB source uses a required profile clause:

```text
(profile apb)
```

No-profile `.ppif` input remains unsupported. `.apb` suffix input remains
unsupported. The APB profile is selected inside `.ppif` so the first APB
implementation proves non-AXI IAL2 source-shape behavior without adding a new
file suffix.

The selected first source shape is:

```text
(protocol-platform-intent apb_requester_transfer
  (profile apb)
  (source
    (object fsmgen-apb-requester-transfer)
    (anchor (document FSMGEN-APB-REQUESTER-CAPTURE-WORKSHEET)
            (section transfer-protocol)
            (page stage-1)))
  (apb-requester apb_requester
    (role requester)
    (clock clk)
    (reset (rst_n active_low async))
    (request
      (start start)
      (write req_write)
      (address req_addr width 32)
      (write-data req_wdata width 32))
    (response
      (done done)
      (read-data last_read_data width 32)
      (error last_error))
    (bus
      (address PADDR width 32)
      (write PWRITE)
      (write-data PWDATA width 32)
      (select PSEL)
      (enable PENABLE)
      (ready PREADY)
      (read-data PRDATA width 32)
      (error PSLVERR))
    (transfer apb_transfer
      (setup (select 1) (enable 0))
      (access (select 1) (enable 1))
      (complete-on ready)
      (sample read-data error)
      (latency (min 2) (max 16)))))
```

The selected sample path for the implementation owner is:

```text
ppif/apb_requester_transfer.ppif
```

The selected support-accounting identity is:

```text
intent.ppif_apb_requester_transfer
```

The expected generated IAL1 and IAL0 review artifacts are:

```text
apb_requester.isf
apb_requester.fsm
```

The expected HDL entry module remains:

```text
apb_requester
```

## Vocabulary Contract

The first APB object type is:

```text
(apb-requester NAME ...)
```

`NAME` is the generated requester actor/module identity. For the first sample,
`NAME` is `apb_requester`.

The first object accepts:

- `(role requester)` only. APB completer/target and interconnect objects remain
  future exact-owner work.
- `(clock NAME)` using the existing scalar clock naming expectation.
- `(reset (NAME active_low async))` for the first slice. Active-high or sync
  reset variants remain future APB contract extensions.
- `(request ...)` for local requester inputs.
- `(response ...)` for local completion outputs.
- `(bus ...)` for APB bus pins.
- `(transfer NAME ...)` for the single APB transfer.

The first request block accepts:

```text
(start NAME)
(write NAME)
(address NAME width 32)
(write-data NAME width 32)
```

The first response block accepts:

```text
(done NAME)
(read-data NAME width 32)
(error NAME)
```

The first bus block accepts:

```text
(address NAME width 32)
(write NAME)
(write-data NAME width 32)
(select NAME)
(enable NAME)
(ready NAME)
(read-data NAME width 32)
(error NAME)
```

The first transfer block accepts:

```text
(setup (select 1) (enable 0))
(access (select 1) (enable 1))
(complete-on ready)
(sample read-data error)
(latency (min 2) (max 16))
```

The selected object is intentionally narrower than full APB. It covers one
requester, one transfer at a time, direct single-peripheral select, 32-bit
address/data, `PREADY` wait, `PRDATA` sampling, and `PSLVERR` capture. APB3/
APB4 protection, strobes, multi-peripheral address decoding, APB completer
generation, interconnect generation, alternate widths, back-to-back transfer
policy, and arbitrary wait-state timeout policy remain residue.

## Source Anchors

The first sample uses the internal APB capture worksheet as its source anchor:

```text
(anchor (document FSMGEN-APB-REQUESTER-CAPTURE-WORKSHEET)
        (section transfer-protocol)
        (page stage-1))
```

That worksheet records the APB source document, scoped APB2/APB3 requester
baseline, signal set, setup/access transfer protocol, safety invariants, and
explicit abstractions. A future owner may add a repo-local raw APB
specification reference and source anchors to the external document, but the
first sample should not block on that because the existing worksheet and APB
fixtures already carry the bounded public contract evidence.

## Generated Review Artifacts

The implementation owner should lower the selected APB source through
generated `.isf` before generated `.fsm`.

The generated `.isf` should be equivalent in behavior to the existing
`isf/apb_requester.isf` fixture for the selected shape:

- local request inputs `start`, `req_write`, `req_addr`, and `req_wdata`;
- local response outputs `done`, `last_read_data`, and `last_error`;
- APB bus outputs `PADDR`, `PWRITE`, `PWDATA`, `PSEL`, and `PENABLE`;
- APB bus inputs `PREADY`, `PRDATA`, and `PSLVERR`;
- setup phase, access phase, `PREADY` await, response sampling, done phase, and
  completion pulse; and
- selected latency minimum 2 and maximum 16.

The generated `.fsm` should remain the scheduled IAL0 review artifact. No
direct `.ppif -> .fsm` lowering is allowed.

## Report Contract

The selected report schema is:

```text
fsmgen.ial2.protocol_intent.apb_requester_transfer.v1
```

The report should include:

- `source_object.id = "fsmgen-apb-requester-transfer"`;
- `source_object.intent_name = "apb_requester_transfer"`;
- `target_protocol.profile = "apb"`;
- `target_protocol.object = "apb-requester"`;
- `target_protocol.role = "requester"`;
- `target_protocol.transfer = "apb_transfer"`;
- request, response, and bus signal summaries with widths;
- generated IAL1 and IAL0 artifact names;
- enforced static rules; and
- explicit unsupported residue.

The selected unsupported residue IDs are:

```text
apb_multi_peripheral_decode_deferred
apb_protection_and_strobes_deferred
apb_completer_and_interconnect_generation_deferred
apb_alternate_widths_deferred
apb_back_to_back_policy_deferred
```

The first implementation may add optional report fields if needed for
diagnostic clarity, but it must not reuse the AXI manager schema and must not
rename existing generic `.ppif`, `.axi`, Valid-Ready, or AXI manager fields.

## Diagnostics

The implementation owner should fail closed with APB-specific diagnostics for:

- `.ppif` sources whose APB object appears under a non-APB profile;
- `(profile apb)` sources with unsupported top-level objects;
- duplicate APB object clauses;
- missing required `request`, `response`, `bus`, or `transfer` blocks;
- missing required APB bus signals;
- non-32-bit address, write-data, or read-data in the first slice;
- unsupported APB roles other than `requester`;
- unsupported transfer clauses; and
- `.apb` suffix input, which must continue to use the known unsupported IAL2
  alias diagnostic until a future exact owner selects `.apb`.

## Selected `.550` Scope

`.550` should directly implement the selected APB `.ppif` source-shape first
slice.

The implementation owner should add the sample
`ppif/apb_requester_transfer.ppif`, parse `(profile apb)` plus one
`(apb-requester ...)` object, generate reviewable `.isf` and `.fsm` artifacts,
emit the selected APB report, support-account the sample as
`intent.ppif_apb_requester_transfer`, document runnable mdBook commands, and
add focused parser, CLI/report, support-accounting, check JSON, semantic JSON,
and preservation coverage.

`.550` must not accept `.apb`, `.pif`, `.ppi`, `.chi`, `.ace`, `.ahb`, `.atb`,
`.smbus`, `.i2s`, or any other suffix; must not extend `.axi`; must not change
existing APB `.isf`/`.fsm` behavior except through preservation coverage; must
not add APB completer, APB interconnect, APB profile alias suffix behavior,
verification-output generation, direct backend lowering, or VHDL behavior.

## Validation

Closeout for this selector is documentation-only:

```bash
bash knowledge-map/scripts/gen_knowledge_map.sh
bash knowledge-map/scripts/check_knowledge_map.sh
mdbook build docs/book
scripts/check_docs_relative_paths.sh
scripts/check_memory_architecture.sh
git --no-pager diff --check
scripts/check_doctrines.sh
```

## Rollback

Rollback is documentation-only: remove this contract selector, its Knowledge
Map fact, task-tree advancement, README/ROADMAP_V2/mdBook sync, and Memory
pointer. No parser, generator, sample, support-accounting, generated HDL,
runtime, or backend artifact rollback is required.
