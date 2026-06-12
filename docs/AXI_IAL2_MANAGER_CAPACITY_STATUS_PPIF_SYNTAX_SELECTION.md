# AXI IAL2 Manager Capacity/Status PPIF Syntax Selection

Status: public `.ppif` capacity/status syntax selected; no parser, CLI, sample,
manifest, check JSON, semantic JSON, or HDL behavior changed by this note.

Follow-on implementation:
[docs/AXI_IAL2_MANAGER_CAPACITY_STATUS_PPIF_FIRST_SLICE.md](AXI_IAL2_MANAGER_CAPACITY_STATUS_PPIF_FIRST_SLICE.md)
shipped the first public parser/CLI slice for this selected syntax.

Task tree:
[docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md](tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md).

Builds on:

- [docs/AXI_IAL2_MANAGER_CAPACITY_STATUS_GENERATOR_FIRST_SLICE.md](AXI_IAL2_MANAGER_CAPACITY_STATUS_GENERATOR_FIRST_SLICE.md)
- [docs/IAL2_PPIF_PARSER_CLI_FIRST_SLICE.md](IAL2_PPIF_PARSER_CLI_FIRST_SLICE.md)
- [docs/IAL2_PPIF_VALID_READY_BUNDLE_FIRST_SLICE.md](IAL2_PPIF_VALID_READY_BUNDLE_FIRST_SLICE.md)
- [docs/IAL2_PPIF_BUNDLE_SEMANTIC_JSON_FIRST_SLICE.md](IAL2_PPIF_BUNDLE_SEMANTIC_JSON_FIRST_SLICE.md)
- [docs/IAL2_PPIF_BUNDLE_HDL_ENTRY_FIRST_SLICE.md](IAL2_PPIF_BUNDLE_HDL_ENTRY_FIRST_SLICE.md)

## Purpose

The in-process generator now proves that the selected AXI manager
outstanding-capacity and acceptance/status shell can lower through:

```text
IAL2 contract -> generated .isf -> generated .fsm -> SystemVerilog
```

This selector chooses the first public `.ppif` syntax for that object and the
exact next implementation boundary before parser or CLI behavior changes.

## Current Public PPIF Findings

The current public `.ppif` adapter is shaped around Valid-Ready objects:

- `FSM::Adapter::IAL2::PPIF` accepts one top-level
  `(protocol-platform-intent ...)` form;
- the required top-level clauses are `(profile ...)`, `(source ...)`, and one
  or more `(valid-ready-channel ...)` clauses;
- one Valid-Ready channel returns a single-object generator result with
  `generated_ial1`, `generated_ial0`, `generated_ial1_schedule_report`, and an
  IAL2 report;
- multiple Valid-Ready channels return the aggregate
  `protocol_intent.valid_ready_bundle` result, including per-channel review
  artifacts and an aggregate wrapper/top HDL entry.

`bin/fsmgen` already has a generic single-object `.ppif` branch after parsing:
it emits `--emit-schedule-json` from the IAL2 report, materializes generated
`.isf` and `.fsm` artifacts with `--outdir`, feeds the selected generated
`.fsm` into the normal HDL path, and keeps successful check JSON and
normalized semantic JSON source identity on the public `.ppif` input. That
single-object branch can carry the capacity/status generator result shape.

The missing work is parser dispatch and public accounting, not IAL1 or
IAL0/SystemVerilog substrate.

## Selected Source Shape

The first public capacity/status object syntax is:

```text
(protocol-platform-intent axi0_capacity_status
  (profile axi4)
  (source
    (object axi-manager-capacity-status)
    (anchor (document IHI0022_L_2025-08) (section A1.1) (page A1-1))
    (anchor (document IHI0022_L_2025-08) (section A1.2) (page A1-1))
    (anchor (document IHI0022_L_2025-08) (section A5.1) (page A5-1)))
  (manager-capacity-status axi0
    (clock clk)
    (reset (rst_n active_low async))
    (read-max-pending 4)
    (write-max-pending 2)
    (submit-policy try)
    (read-submit axi0_read_submit)
    (read-complete axi0_read_complete)
    (write-submit axi0_write_submit)
    (write-complete axi0_write_complete)
    (status
      (read-can-accept axi0_read_can_accept)
      (write-can-accept axi0_write_can_accept)
      (read-full axi0_read_full)
      (write-full axi0_write_full)
      (pending-reads axi0_pending_reads)
      (pending-writes axi0_pending_writes)
      (read-slots-available axi0_read_slots_available)
      (write-slots-available axi0_write_slots_available))))
```

Mapping to the in-process contract:

| PPIF clause | Generator contract field |
| --- | --- |
| Top-level `(profile axi4)` | `protocol => 'axi4'` |
| Top-level intent name | `intent_name` |
| Top-level `(source ...)` | `source.object_id` and `source.anchors` |
| `(manager-capacity-status axi0 ...)` | `name => 'axi0'` |
| `(clock clk)` | `clock => 'clk'` |
| `(reset (rst_n active_low async))` | `reset => { signal => 'rst_n', active_low => 1, async => 1 }` |
| `(read-max-pending 4)` | `read_max_pending => 4` |
| `(write-max-pending 2)` | `write_max_pending => 2` |
| `(submit-policy try)` | `submit_policy => 'try'` |
| `(read-submit ...)`, `(read-complete ...)`, `(write-submit ...)`, `(write-complete ...)` | abstract event bindings |
| `(status (...))` | optional status-output overrides |

The public clause names use hyphenated `.ppif` spelling. The parser maps them
to the generator's structured Perl keys before calling
`FSM::IAL2::ProtocolIntent::AxiManagerCapacityStatus`.

## First Parser/CLI Boundary

The next implementation leaf should support exactly one
`(manager-capacity-status ...)` object per `.ppif` file.

It should not support, in the first public slice:

- mixing `(manager-capacity-status ...)` with `(valid-ready-channel ...)`,
- multiple manager capacity/status objects,
- manager bundles,
- object-local source overrides,
- public `actor-name` overrides,
- public `.pif`, `.ppi`, `.axi`, or other profile suffix aliases,
- IDs, ordering, response matching, bursts, or channel expansion,
- `blocking` or `queued` submit policy,
- HDL blocked-reason output encoding,
- VHDL backend behavior.

These exclusions keep the first public capacity/status slice aligned with the
already-shipped in-process shell and avoid changing the existing Valid-Ready
bundle contract.

## Required Public Behavior For The Next Leaf

The next implementation leaf should add a checked-in runnable sample, likely:

```text
ppif/axi_manager_capacity_status.ppif
```

The public CLI behavior should match the single-object `.ppif` path:

```bash
./bin/fsmgen --emit-schedule-json ppif/axi_manager_capacity_status.ppif
./bin/fsmgen --outdir generated ppif/axi_manager_capacity_status.ppif
./bin/fsmgen --strict --check --json ppif/axi_manager_capacity_status.ppif
./bin/fsmgen --strict --emit-semantic-json ppif/axi_manager_capacity_status.ppif
./bin/fsmgen --outdir generated --verify-hdl ppif/axi_manager_capacity_status.ppif
```

Expected behavior:

- `--emit-schedule-json` emits the IAL2 report schema
  `fsmgen.ial2.protocol_intent.axi_manager_capacity_status.v1`;
- `--outdir` writes the generated `.isf` and `.fsm` review artifacts before
  HDL generation;
- default HDL generation and `--verify-hdl` use the generated `.fsm` entry;
- check JSON keeps `source.resolved_path` on the public `.ppif` source and
  matches a new support-accounting corpus entry;
- normalized semantic JSON keeps `source.resolved_path` on the public `.ppif`
  source and still reports the generated `.fsm` semantic root;
- the capability manifest/language-surface `.ppif` boundary mentions the
  shipped capacity/status object after the implementation lands.

## Diagnostics Boundary

The parser/CLI slice should fail closed before generation when:

- `(profile ...)` is missing or is not `axi4`;
- `(source ...)` is missing or lacks an object/anchor;
- no `(manager-capacity-status ...)` object is present;
- a manager object is mixed with Valid-Ready objects;
- more than one manager object is present;
- required manager clauses are missing;
- `read-max-pending` or `write-max-pending` is non-positive or non-scalar;
- `submit-policy` is not `try`;
- status-output clauses are unknown, duplicated, or malformed;
- unsupported clauses request IDs, ordering, responses, bursts, channels,
  queued/blocking policy, actor names, profile aliases, or VHDL behavior;
- generator-level identifier/name-collision checks fail.

## Validation Gates For The Next Leaf

The implementation leaf should extend `t/1436-ial2-ppif-parser-cli.t` or add a
focused sibling test proving:

- parser acceptance for the selected source shape;
- parser rejection for mixed object families and multiple manager objects;
- targeted diagnostics for missing/invalid required clauses;
- generated `.isf` and `.fsm` review artifact materialization;
- schedule JSON report schema and source anchors;
- check JSON support-accounting source identity for the new sample;
- normalized semantic JSON source identity for the new sample;
- default HDL and `--verify-hdl` reach the generated capacity/status module;
- `.pif`, `.ppi`, `.axi`, IDs, ordering, response matching, bursts, and
  queued/blocking policies stay rejected.

Broader gates should include the focused generator test, PPIF parser/CLI test,
support corpus check JSON test, normalized semantic JSON corpus test,
capability manifest/language-surface tests, mdBook build, Knowledge Map check,
memory architecture check, and diff hygiene.

## Selection Conclusion

Proceed with a public `.ppif` parser/CLI first slice for exactly one
`manager-capacity-status` object. No new IAL1 or IAL0/SystemVerilog
prerequisite is required first. The slice must include parser/CLI behavior,
runnable sample, support-accounting corpus entry, language-surface/capability
manifest update, check JSON and normalized semantic JSON source-identity
coverage, focused diagnostics, mdBook sync, and Knowledge Map sync in the same
task-scoped commit.
