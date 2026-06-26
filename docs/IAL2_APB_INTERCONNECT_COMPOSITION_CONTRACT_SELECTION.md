# IAL2 APB Interconnect/Composition Contract Selection

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.565`

Date: 2026-06-26

## Outcome

`IAL2-FEATURE-COMPLETENESS-FRONTIER.565` selects the first generated APB
composition public contract.

The selected first behavior is a fixed one-requester/one-completer APB
composition under the generic `.ppif` IAL2 container. The public source uses
one `(apb-requester ...)` object, one `(apb-completer ...)` object, and one
explicit `(apb-composition ...)` object that references those endpoint objects.
It is a composition contract, not a multi-peripheral APB interconnect/decode
contract.

The next exact owner is `IAL2-FEATURE-COMPLETENESS-FRONTIER.566`, direct
bounded APB `.ppif` composition implementation. `.566` may implement only this
selected contract and must keep APB completer `.apb` alias exposure, APB
composition `.apb` alias exposure, multi-peripheral interconnect/decode,
multi-register decode, sidebands/strobes, alternate widths, requester busy
status exposure, back-to-back policy, direct backend lowering,
verification-output generation, backend-language variants, AXI behavior, and
VHDL behavior deferred.

No parser behavior, generator behavior, samples, support-accounting catalog,
validation behavior, generated artifacts, tests, schedule/check/semantic JSON
behavior, HDL/runtime behavior, suffix acceptance, direct backend lowering,
verification-output generation, backend-language variants, AXI behavior, APB
behavior, or VHDL behavior changed in this selection slice.

## Evidence Read

The selector read the `.564` readiness audit, `.563` post-completer selector,
`.562` APB `.ppif` completer behavior, `.561` IAL1 expression entry-guard
repair, `.560` APB completer substrate audit, `.559` split APB
completer/interconnect contract, `.558` APB completer/interconnect readiness
audit, `.554` APB `.apb` requester-transfer behavior, `.550` APB `.ppif`
requester-transfer behavior, generated APB endpoint samples and live reports,
`fsm/apb_tb.fsm`, `fsm/apb_requester.fsm`, `RegressionCorpus`,
`LanguageSurfaceSection`, the Valid-Ready bundle aggregate-top precedent,
README, ROADMAP_V2, mdBook, task tree, Memory, and Knowledge Map.

The live APB endpoint reports preserve these public endpoint surfaces:

```text
ppif/apb_requester_transfer.ppif
  schema: fsmgen.ial2.protocol_intent.apb_requester_transfer.v1
  mode: requester-transfer
  hdl_entry: apb_requester.fsm
  request keys: address, start, write, write_data
  response keys: done, error, read_data
  bus keys: address, enable, error, read_data, ready, select, write, write_data

ppif/apb_completer.ppif
  schema: fsmgen.ial2.protocol_intent.apb_completer.v1
  mode: completer
  hdl_entry: apb_completer.fsm
  control keys: wait_cycles
  bus keys: address, enable, error, read_data, ready, select, write, write_data
```

The lower-layer composition evidence remains `fsm/apb_tb.fsm`. It wires
`apb_requester` and `apb_completer` through `PSEL`, `PENABLE`, `PWRITE`,
`PADDR`, `PWDATA`, `PREADY`, `PRDATA`, and `PSLVERR` and is
support-accounted as `protocol.apb_tb`, `source_kind => composition`,
expected top `apb_tb`, and expected child modules `apb_requester` and
`apb_completer`.

## Selected Source Shape

The selected first source path is:

```text
ppif/apb_composition.ppif
```

The selected top-level intent name is:

```text
apb_composition
```

The selected generated composition top is:

```text
apb_tb
```

The first public source uses explicit APB profile selection and a self-contained
endpoint-plus-composition body:

```text
(protocol-platform-intent apb_composition
  (profile apb)
  (source
    (object fsmgen-apb-composition)
    (anchor
      (document FSMGEN-APB-REQUESTER-CAPTURE-WORKSHEET)
      (section requester-completer-composition)
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
      (latency (min 2) (max 16))))
  (apb-completer apb_completer
    (role completer)
    (clock clk)
    (reset (rst_n active_low async))
    (control
      (wait-cycles wait_cycles width 4))
    (bus
      (select PSEL)
      (enable PENABLE)
      (write PWRITE)
      (address PADDR width 32)
      (write-data PWDATA width 32)
      (ready PREADY)
      (read-data PRDATA width 32)
      (error PSLVERR))
    (storage
      (register reg0
        (address 0 width 32)
        (data reg_data_q width 32 reset 0)))
    (transfer apb_complete
      (setup-detect (select 1) (enable 0))
      (wait-cycles wait_cycles)
      (read register)
      (write register)
      (unmapped-address error)))
  (apb-composition apb_tb
    (role composition)
    (clock clk)
    (reset (rst_n active_low async))
    (children
      (requester requester apb_requester)
      (completer completer apb_completer))
    (wiring apb_bus
      (select PSEL)
      (enable PENABLE)
      (write PWRITE)
      (address PADDR width 32)
      (write-data PWDATA width 32)
      (ready PREADY)
      (read-data PRDATA width 32)
      (error PSLVERR))))
```

The first implementation must require exactly one `(apb-requester ...)`, one
`(apb-completer ...)`, and one `(apb-composition ...)` under `(profile apb)`.
The endpoint objects are embedded in the same authored file; the composition
object references those endpoint objects by name. Cross-file endpoint
references, binding to pre-existing generated artifacts, and implicit
composition from a mixed requester/completer source are not selected.

The generated top interface is derived from the shared clock/reset, requester
request inputs, completer control inputs, and requester response outputs:

```text
clk
rst_n
=start
=req_write
=req_addr<32
=req_wdata<32
=wait_cycles<4
=done>
=last_error>
=last_read_data>32
```

APB bus signals are internal child wiring in this first public contract. The
hand-authored lower-layer `fsm/apb_tb.fsm` also exposes `busy`, but the shipped
public APB requester `.ppif` response contract does not contain a `busy`
binding. The first generated composition therefore does not expose `busy`.
Requester busy/status output is explicitly deferred to a later endpoint
contract widening owner.

## Generated Artifact Contract

The selected implementation must reuse the endpoint generators and keep the
reviewable generated chain:

```text
.ppif / IAL2
  -> apb_requester.isf
  -> apb_requester.fsm
  -> apb_completer.isf
  -> apb_completer.fsm
  -> apb_tb.fsm
  -> HDL root apb_tb
```

The generated composition top is an IAL0 `?top` review artifact. Directly
copying `fsm/apb_tb.fsm` is not selected; `.566` must synthesize a generated
top from the selected source, endpoint reports, child artifact names, and
composition wiring. The generated top may mirror the lower-layer fixture's
child instance names `requester` and `completer`.

The selected generated top shape is:

```text
(?top:apb_tb
  (?ports:public_io
    clk
    rst_n
    =start
    =req_write
    =req_addr<32
    =req_wdata<32
    =wait_cycles<4
    =done>
    =last_error>
    =last_read_data>32)
  (?fsmc:requester apb_requester)
  (?fsmc:completer apb_completer)
  (?wiring:apb_bus
    (requester.PSEL completer.PSEL)
    (requester.PENABLE completer.PENABLE)
    (requester.PWRITE completer.PWRITE)
    (requester.PADDR completer.PADDR)
    (requester.PWDATA completer.PWDATA)
    (completer.PREADY requester.PREADY)
    (completer.PRDATA requester.PRDATA)
    (completer.PSLVERR requester.PSLVERR)))
```

The selected HDL entry report is:

```text
generated_artifacts.hdl_entry.selected       = 1
generated_artifacts.hdl_entry.kind           = generated_composition_top
generated_artifacts.hdl_entry.entry_artifact = apb_tb.fsm
generated_artifacts.hdl_entry.module         = apb_tb
```

`--outdir` must materialize all review artifacts:

```text
apb_requester.isf
apb_requester.fsm
apb_completer.isf
apb_completer.fsm
apb_tb.fsm
```

## Report And Support Contract

The selected future adapter result kind is:

```text
protocol_intent.apb_composition
```

The selected future report schema is:

```text
fsmgen.ial2.protocol_intent.apb_composition.v1
```

The selected future report mode is:

```text
requester-completer-composition
```

The report must include:

- `layering.source_layer = IAL2`;
- `layering.generated_ial1_format = isf`;
- `layering.generated_ial0_format = fsm`;
- `layering.direct_ial2_to_ial0 = 0`;
- `source_object.id = "fsmgen-apb-composition"`;
- `source_object.intent_name = "apb_composition"`;
- `target_protocol.profile = "apb"`;
- `target_protocol.object = "apb-composition"`;
- `target_protocol.role = "composition"`;
- requester and completer child summaries, including child instance names,
  child object names, generated endpoint artifact names, and cloned endpoint
  report summaries;
- APB wiring summary for `PSEL`, `PENABLE`, `PWRITE`, `PADDR`, `PWDATA`,
  `PREADY`, `PRDATA`, and `PSLVERR`;
- generated IAL1 and IAL0 artifact summaries;
- selected HDL entry summary;
- enforced static rules; and
- explicit unsupported residue.

The selected future support-accounting identity is:

```text
entry_id: intent.ppif_apb_composition
coverage: ial2_ppif_apb_composition_pipeline_cli
source_kind: ppif
expected_top_name: apb_tb
expected_child_modules: [apb_requester, apb_completer]
expected_semantic_source_root_kind: composition
```

The existing direct lower-layer fixture remains separately support-accounted:

```text
entry_id: protocol.apb_tb
source_kind: composition
expected_top_name: apb_tb
expected_child_modules: [apb_requester, apb_completer]
```

## Diagnostics

`.566` should fail closed with targeted diagnostics for:

- missing, duplicate, or unsupported `(apb-composition ...)` objects;
- `(apb-requester ...)` plus `(apb-completer ...)` without an explicit
  `(apb-composition ...)` object;
- duplicate requester or completer endpoint objects;
- endpoint names referenced by composition children that do not exist;
- child instance aliases that are missing, duplicate, or not HDL identifiers;
- shared clock/reset mismatch between composition, requester, and completer;
- APB bus signal name or width mismatch between requester, completer, and
  composition wiring;
- attempts to use `(apb-interconnect ...)` for the first fixed composition;
- attempts to expose requester `busy` before the requester endpoint contract is
  widened;
- any `.apb` APB composition source before profile-alias widening is selected;
  and
- sidebands/strobes, alternate widths, multi-peripheral decode,
  multi-register decode, back-to-back transfer policy, direct backend,
  verification-output generation, backend-language variants, AXI, and VHDL.

## Residue Movement

When `.566` ships, APB requester/completer residues should no longer imply that
fixed one-requester/one-completer composition is unselected. Public residue
should move toward narrower IDs such as:

```text
apb_interconnect_multi_peripheral_decode_deferred
apb_profile_alias_composition_deferred
apb_profile_alias_completer_deferred
apb_requester_busy_status_deferred
apb_multi_register_decode_deferred
apb_protection_and_strobes_deferred
apb_alternate_widths_deferred
apb_back_to_back_policy_deferred
```

Residue movement is behavior/report-surface work and is not performed in
`.565`.

## Rejected Alternatives

`(apb-interconnect ...)` is rejected for the first implementation name because
it suggests multi-peripheral decode and routing. The selected source name is
`(apb-composition ...)` because the first behavior wires exactly one generated
requester to exactly one generated completer.

Implicit composition from a mixed requester/completer source is rejected. A
mixed source without an explicit composition object would make endpoint-only
sources and aggregate-top sources indistinguishable.

Cross-file endpoint references are rejected for the first slice. They would
require source-path resolution, artifact freshness rules, and partial failure
semantics that are not needed for a bounded self-contained APB composition
sample.

Binding directly to existing generated endpoint artifacts is rejected. The
public source must regenerate review artifacts from the same authored `.ppif`
file so schedule, check, semantic JSON, `--outdir`, and HDL output agree.

APB `.apb` composition alias exposure is rejected until a profile-alias owner
widens `.apb` beyond requester-transfer.

## Selected `.566` Scope

`.566` should implement only the contract selected here:

- add `ppif/apb_composition.ppif`;
- parse explicit `(profile apb)` with exactly one requester, one completer, and
  one composition object;
- generate `apb_requester.isf`, `apb_requester.fsm`, `apb_completer.isf`,
  `apb_completer.fsm`, and `apb_tb.fsm`;
- select `apb_tb.fsm` as the HDL entry;
- support default HDL, `--outdir`, `--emit-schedule-json`,
  `--check --json`, `--emit-semantic-json`, and `--verify-hdl` for the new
  sample as feasible under the existing backend gates;
- add focused tests and support-accounting coverage;
- update docs, mdBook, Knowledge Map, and Memory; and
- keep all deferred APB/AXI/backend/VHDL surfaces locked.

If `.566` finds a lower-layer blocker while implementing, it should stop at the
smallest exact prerequisite and record that owner before changing unrelated
behavior.

## Validation

Closeout for this no-behavior selector is documentation-only plus live
read-only evidence:

```bash
./bin/fsmgen --quiet --emit-schedule-json ppif/apb_requester_transfer.ppif
./bin/fsmgen --quiet --emit-schedule-json ppif/apb_completer.ppif
./bin/fsmgen --quiet --strict --emit-semantic-json fsm/apb_tb.fsm
knowledge-map/scripts/gen_knowledge_map.sh
knowledge-map/scripts/check_knowledge_map.sh
mdbook build docs/book
scripts/check_docs_relative_paths.sh
scripts/check_memory_architecture.sh
git --no-pager diff --check
scripts/check_doctrines.sh
```

## Rollback

Rollback is documentation-only: remove this contract selection, its Knowledge
Map fact, task-tree advancement, README/ROADMAP_V2/mdBook sync, Memory pointer
update, and regenerated Knowledge Map entries. No runtime behavior is affected.
