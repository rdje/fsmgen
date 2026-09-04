# VIAL Capability, Support, Parity, and Troubleshooting Reference

Use this chapter when the question is “what can I run, inspect, or rely on
today?” It consolidates current status without replacing the normative
contracts, machine-readable capability records, or specialist evidence.

The short answer is:

- public VIAL v1 check, format, plan, and `sv_portable_verilator` run are
  shipped;
- public VIAL v2 capabilities, check, format, opt-in v1 migration, and
  empty-family plan are shipped, while v2 run is unavailable;
- portable VHDL/GHDL and OSVVM have exact private fixture qualifications;
- native UVM has deterministic private emission and a separate tool-limited
  experiment, but no qualified product runtime;
- mixed-language execution is unavailable; and
- the architecture-scale regression gate protects exact workloads without
  claiming general capacity or widening support.

## Query machine truth first

Run both public discovery commands from the repository root:

```bash
./bin/fsmgen vial capabilities --json
./bin/fsmgen vial capabilities --language-version 2 --json
./bin/fsmgen --capability-manifest
```

The first VIAL-only result and the complete manifest carry the byte-stable v1
public tooling record. The explicit v2 result carries its distinct contract at
`capability_evidence.contract`; it is not folded into or confused with the v1
record. The complete manifest carries private evidence at:

```text
language_surface.vial_tooling
language_surface.vial_native_uvm_emission
language_surface.vial_vhdl_emission
support_accounting.catalog_entries
```

The v1 VIAL-only projection must equal the corresponding fields of the complete
public-tooling record, including the complete nested scale contract. The v2
contract instead derives its parser and empty-plan capabilities from the
semantic-family registry and reports `run` unavailable. The full manifest
additionally carries schemas, entrypoints, and API/publication flags.
The private native-UVM and VHDL records are discoverable evidence, not extra
backends accepted by public `fsmgen vial run`.

These terms are deliberately different:

- **public and shipped** means a documented CLI/API route accepts the
  capability;
- **qualified, private** means an exact fixture/provider/tool tuple passed its
  private gates but is not a public CLI backend;
- **review emission** means deterministic generated artifacts passed structural
  checks, not parse, compile, elaboration, or runtime;
- **experimental** means a separately named observation that can expose
  generator or tool limitations and never becomes product support by itself;
- **unavailable** means the requested profile has no accepted execution route;
  and
- **regression evidence** protects named behavior but does not establish
  arbitrary design capacity.

## Exact public version matrix

| Language/tool version | Supported public actions | Unavailable public action | Backend boundary |
| --- | --- | --- | --- |
| v1, the CLI default | `capabilities`, `check`, `format`, `plan`, `run` | none in the action grammar | `run` accepts only the separately negotiated `sv_portable_verilator` profile |
| v2, selected by `--language-version 2` | `capabilities`, `check`, `format`, `migrate`, `plan` | `run` | plan accepts only the inherited empty-family base; no v2 backend, compile, runtime, complete-result, or parity capability exists |

The v2 request/result schemas are `fsmgen.vial_tool_request.v2` and
`fsmgen.vial_tool_result.v2`. Migration returns
`fsmgen.vial_source_migration.v1`; planning returns
`fsmgen.vial_plan.v2` and `fsmgen.vial_tool_manifest.v2` while unchanged HIAL
facts remain in `fsmgen.hial_vial_bridge_manifest.v1`. No v2 capability list
contains a `vial.family.*` identity.

## Exact profile matrix

| Profile | Availability now | Invocation surface | Evidence that exists | Boundary that remains |
| --- | --- | --- | --- | --- |
| `sv_portable_verilator` | public and shipped | `fsmgen vial run --backend sv_portable_verilator` | exact known-value Verilator runtime, normalized result, and selected AHB parity | not complete four-state, complete SystemVerilog/UVM, or general parity |
| `sv_uvm_emit.accellera_2020_3_1` | shipped private review emission | private emitter and checked review gallery | deterministic selected structures, source maps, static validation, mapping matrix, and review workflow | parse, compile, elaboration, runtime, result, parity, and manual review are not claimed |
| `sv_uvm_experimental.verilator_5_046.uvm_verilator_2020_3_1_vlt_656f20d0` | unqualified experimental evidence | `perl scripts/run_vial_native_uvm_experimental_probe.pl --check` | UVM-library control stages and generated-fixture preprocessing passed; fixture parsing reached an unsupported tool feature | fixture compile/elaboration failed in the tool; runtime, result, parity, and product support are absent |
| `sv_uvm_qualified` | unavailable | no public or qualified invocation | future exact PGEN parser plus NEXSIM simulator direction only | no present parse, compile, elaboration, runtime, result, parity, or support claim |
| `vhdl_portable_ghdl` | qualified private fixture profile | private gallery and exact qualification runner | provider-free emission plus exact GHDL LLVM-JIT analysis, elaboration, bounded runtime, four-state probe, normalized result, rerun, cleanup, and selected AHB parity | not accepted by public `vial run`; no complete VHDL, PSL, other-simulator, mixed-language, or general-parity claim |
| `vhdl_osvvm_qualified` | qualified private fixture profile | private gallery and exact combined qualification runner | exact OSVVM provider materialization, adapter and provider compilation, bounded fixture/probe runtime, unchanged normalized result/parity, supplementary reports, rerun, and cleanup | not accepted by public `vial run`; no general OSVVM/provider, mixed-language, or general-parity claim |
| `mixed_language_qualified` | unavailable | no invocation | none; separate SystemVerilog and VHDL successes remain separate | never infer mixed-language binding or execution from single-language qualifications |

Only the first row is a public `vial run` backend. Asking that command for any
other profile returns `VIAL_BACKEND_UNSUPPORTED` and publishes no partial
artifact tree. Private qualification status is still valuable evidence, but it
does not silently add a public backend.

## Support accounting is not backend availability

The complete capability manifest currently derives these VIAL records from the
regression corpus:

| Support ID | Classification | Coverage |
| --- | --- | --- |
| `verification.vial_ahb_subordinate_base_output_arbitration` | `supported_smoke` | `vial_semantic_report_private_api` |
| `feature.vial_public_check_format` | `supported_smoke` | `vial_public_check_format_cli_api` |
| `feature.vial_public_plan` | `supported_smoke` | `vial_public_plan_cli_api` |
| `feature.vial_v2_public_source_migration` | `supported_smoke` | `vial_v2_public_source_migration_cli_api` |
| `feature.vial_v2_public_empty_base_plan` | `supported_smoke` | `vial_v2_public_empty_base_plan_cli_api` |
| `feature.vial_sv_portable_verilator_runtime` | `supported_smoke` | `vial_sv_portable_verilator_runtime_cli_api` |
| `feature.vial_ahb_base_output_runtime_parity` | `supported_smoke` | `vial_ahb_handwritten_oracle_parity` |
| `feature.vial_native_uvm_emission_foundation` | `supported_smoke` | `vial_native_uvm_selected_matrix_review_private_api` |
| `feature.vial_vhdl_portable_semantics` | `supported_smoke` | `vial_vhdl_ghdl_osvvm_qualified_private_api` |

`supported_smoke` describes the repository's exercised evidence class. The
coverage field still says whether that evidence is public CLI/API, private API,
review emission, runtime, or parity. Therefore the native-UVM and VHDL rows do
not contradict the public-backend boundary above.

The default v1 action list is exactly `capabilities`, `check`, `format`,
`plan`, and `run`; the explicit v2 list replaces `run` with `migrate`. See the
[Public VIAL Lifecycle Reference](16dg-vial-public-lifecycle-reference.md) for
request/result fields, artifact publication, and command examples.

## Recheck the evidence appropriate to a profile

Use a non-mutating gallery check when you need deterministic generated-source
and review evidence:

```bash
perl scripts/refresh_vial_native_uvm_gallery.pl --check
perl scripts/refresh_vial_vhdl_portable_gallery.pl --check
perl scripts/refresh_vial_vhdl_osvvm_gallery.pl --check
```

Use the exact private qualification checks only when the repository-local
provider tuple is available:

```bash
scripts/run_with_ram_guard.sh --process-max-rss-mb 4096 -- \
  perl scripts/run_vial_vhdl_portable_ghdl_qualification.pl --check

scripts/run_with_ram_guard.sh --process-max-rss-mb 4096 -- \
  perl scripts/run_vial_vhdl_osvvm_ghdl_qualification.pl --check
```

The provider-free VHDL qualification accepts exactly GHDL `6.0.0` with its
LLVM-JIT backend. The advanced qualification adds the exact OSVVM 2026.05
recursive provider graph. The command validates those identities before use;
do not substitute a shared user cache or infer LLVM-AOT behavior.

Native UVM separates two checks:

```bash
# Deterministic emitter/gallery evidence; no UVM library is required.
perl scripts/refresh_vial_native_uvm_gallery.pl --check

# Reproduce and byte-compare the provider-bound experiment.
perl scripts/run_vial_native_uvm_experimental_probe.pl --check
```

The experimental check requires the exact CHIPS Alliance source at
`.artifacts/cache/uvm-verilator/656f20d087370a7c742e00188d20bbf30fa95339/source`;
it never downloads that provider. If the source is absent, the command reports
`VIAL_UVM_PROBE_PATH_ERROR` rather than accepting the tracked report alone.
When present, the report records a passing UVM-library control and a generated
fixture that preprocesses, reaches unsupported ranged SVA during strict parse,
and then reaches a tool internal failure in a blackboxed compile attempt. Those
outcomes are evidence, not a reason to label the fixture compiled or runnable.

There is no corresponding command for `sv_uvm_qualified` or
`mixed_language_qualified`. Absence is reported as unavailable, never pass.

## Read parity narrowly

Public capability `vial.parity.ahb_base_output_arbitration.v1` names one
bounded oracle. It compares normalized shared AHB outcomes produced from the
same generated DUT source. The qualified portable-VHDL and OSVVM records reuse
that selected oracle; native UVM has no parity result.

Parity does not compare generated HDL text, simulator timestamps, waveforms,
target paths, UVM/VHDL plumbing, or untyped internal counters. A passing
selected oracle is not general cross-backend parity. Follow the
[end-to-end AHB tutorial](16dh-vial-ahb-end-to-end-tutorial.md) for the exact
compared paths and exclusions.

## Read scale evidence without turning it into capacity

Public discovery exposes
`vial.architecture_scale.regression_gate.v1`. It owns exact workload identities,
ordered profiles, provider requirements, correctness projections, immutable
qualified budgets, host/guard applicability, cleanup, and nonclaims.

Inspect its transaction without executing a workload:

```bash
./bin/ci-regression vial-gate --dry-run --no-book
```

Correctness is required wherever the exact profile is available. Performance
budgets apply only when the complete qualified host, tool, guard, and provider
tuple matches; unmatched environments retain correctness with informational
performance. A missing provider is `unavailable`, never pass. There is no
performance override.

The gate does not prove architecture-scale capacity, “big” or “really big”
whole-product capacity, multi-unit/domain capacity, arbitrary-tool capacity,
support promotion, native-UVM runtime, mixed-language execution, or general
cross-backend parity. Read the
[Architecture-Scale Cap Closeout](16df-vial-architecture-scale-cap-closeout.md)
for the exact profiles, budgets, immutable evidence, execution commands, and
latest-result lifecycle. The specialist
[structural emission](16db-vial-structural-backend-emission-matrix.md),
[Verilator runtime](16dc-vial-portable-verilator-runtime-measurement.md),
[VHDL runtime](16dd-vial-portable-vhdl-runtime-measurement.md), and
[OSVVM runtime](16de-vial-osvvm-runtime-execution-plan.md) chapters retain the
measurements rather than duplicating them here.

## Interpret diagnostics by phase

Public human mode prints `Error [CODE]` with sanitized source and semantic
coordinates. JSON mode returns the same closed diagnostic records. Start with
the code family; do not reinterpret an unsupported or unavailable result as a
test failure.

| Phase | Public codes | First check |
| --- | --- | --- |
| request and source | `VIAL_TOOL_INVOCATION_ERROR`, `VIAL_SOURCE_STYLE_ERROR`, `VIAL_HIAL_SOURCE_ERROR` | command shape, source style, and the selected HIAL review route |
| v2 version, imports, migration, and families | `VIAL_VERSION_UNSUPPORTED`, `VIAL_IMPORT_VERSION_MISMATCH`, `VIAL_COMPATIBILITY_ADAPTER_UNAVAILABLE`, `VIAL_COMPATIBILITY_ADAPTER_INVALID`, `VIAL_MIGRATION_ERROR`, `VIAL_FAMILY_UNSUPPORTED`, `VIAL_FAMILY_REVISION_MISMATCH` | explicit version selector, same-version catalog, migration direction, and empty-family boundary |
| v2 parsing and semantics | `VIAL_PARSE_ERROR`, `VIAL_SCHEMA_ERROR`, `VIAL_SEMANTIC_ERROR`, `VIAL_LIMIT_ERROR` | grammar, closed schema, typed meaning, and the first exceeded source limit |
| backend negotiation | `VIAL_BACKEND_UNSUPPORTED` | profile spelling and the public/private matrix above |
| artifact publication | `VIAL_ARTIFACT_PATH_ERROR`, `VIAL_ARTIFACT_COLLISION`, `VIAL_MANIFEST_SCHEMA_ERROR` | repository-relative output, pre-existing content, and schema identity |
| run setup | `VIAL_RUN_INVOCATION_ERROR`, `VIAL_RUN_PATH_ERROR`, `VIAL_RUN_TOOL_ERROR`, `VIAL_RUN_COMMAND_ERROR`, `VIAL_RUN_COLLISION` | option compatibility, provider identity, command evidence, and output ownership |
| compile and execution | `VIAL_RUN_COMPILE_ERROR`, `VIAL_RUN_RUNTIME_ERROR`, `VIAL_RUN_LIMIT_EXCEEDED` | tool transcript, bounded runtime, and the first authoritative limit |
| evidence, cleanup, and host | `VIAL_RUN_TRACE_ERROR`, `VIAL_RUN_RESULT_ERROR`, `VIAL_RUN_CLEANUP_ERROR`, `VIAL_RUN_HOST_ERROR`, `VIAL_HOST_ERROR` | trace/result schema, exact owned roots, process residue, and sanitized host boundary |

For private backends, preserve their own diagnostic and stage names. In
particular, `VIAL_UVM_BACKEND_UNSUPPORTED` is private native-UVM shape
negotiation; it is not public backend availability. The
[public lifecycle reference](16dg-vial-public-lifecycle-reference.md#diagnostics-and-exit-behavior)
owns the complete record shape.

## Artifact and cleanup rules

Capability commands and gallery `--check` commands write no project artifact.
Private qualification commands use repository-derived same-volume staging,
validate the tracked qualification record, and clean operation-owned work
roots. Repository-local GHDL and OSVVM provider caches are persistent verified
inputs, not stray temporary directories; do not delete them as routine cleanup.

For a public plan or run, select an explicit repository-relative output such as
`.artifacts/manual/vial-capability-reference-run`. After the command has
finished and the result has been inspected, remove only that exact owned root:

```bash
rm -rf .artifacts/manual/vial-capability-reference-run
```

V2 migration writes no artifact. A v2 plan follows the same atomic publication
rules under its selected root; `run --language-version 2` creates no root at
all because it rejects at capability negotiation.

The real architecture-scale gate atomically replaces its declared latest
observation at
`.artifacts/qualification/vial-scale/v2/regression-promotion-gate-v1/current/regression-promotion-gate-result.json`,
preserves that result, removes anonymous worker spools, and cleans only
receipt-owned evidence roots. Use its validator and cleanup contract; never broadly
delete `.artifacts`, provider caches, or an ambiguous shared cache.

## Decision guide

1. Need a public source-to-result workflow? Use `sv_portable_verilator` and
   the lifecycle reference.
2. Need deterministic UVM for review? Check
   `sv_uvm_emit.accellera_2020_3_1`; do not call it executable.
3. Need open-tool UVM feasibility evidence? Read or recheck the exact
   `sv_uvm_experimental...` report; keep `product_support=false`.
4. Need VHDL execution evidence? Run the exact private
   `vhdl_portable_ghdl` qualifier if its repository-local provider is present.
5. Need OSVVM services? Use the separate `vhdl_osvvm_qualified` evidence and
   keep portable semantics/result authority unchanged.
6. Need mixed-language or qualified native-UVM runtime? The current answer is
   unavailable; do not compose a claim from separate successes.
7. Need scale confidence? Use the bounded regression gate and retain its
   capacity and support nonclaims.

For architecture and migration context, return to
[HIAL/VIAL Verification: Start Here](16d-hial-vial-verification-architecture.md)
and [Migrating Legacy Verification to VIAL](16di-vial-legacy-migration.md).
The focused machine-derived watcher for this reference is
`t/1800-hial-vial-capability-support-reference.t`.
