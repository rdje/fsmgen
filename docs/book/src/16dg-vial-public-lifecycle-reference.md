# Public VIAL Lifecycle Reference

This is the task-oriented reference for both public VIAL versions. Version 1
follows one verification source from discovery and checking through HIAL
review, target-neutral planning, the selected public backend, and normalized
results. Version 2 accepts the `lifecycle_control@1` family through typed,
target-neutral planning and normalized-result validation, but still has no
backend or `run` route. Read
[HIAL/VIAL Verification: Start Here](16d-hial-vial-verification-architecture.md)
first when you need the availability boundary between public, private,
review-only, experimental, and unavailable profiles.

The complete v1 lifecycle is:

```text
.vial source -> check/format -> reviewed HIAL bridge -> public plan
             -> selected backend run -> normalized result
```

Private compiler objects exist between those steps, but they are not an API.
Use only the command family, the portable request/result records, and the
sanitized artifacts documented here.

## Select the language/tool contract explicitly

Commands without a version selector retain the complete v1 behavior described
below. Select the additive v2 foundation with `--language-version 2`:

```bash
./bin/fsmgen vial capabilities --language-version 2 --json
./bin/fsmgen vial check --language-version 2 \
  vial/ahb_subordinate_base_output_arbitration_v2.vial
./bin/fsmgen vial format --language-version 2 --style terse \
  vial/ahb_subordinate_base_output_arbitration_v2.vial
./bin/fsmgen vial migrate --language-version 2 --json \
  vial/ahb_subordinate_base_output_arbitration.vial
```

The base v2 fixture has the same base meaning as the v1 AHB fixture and keeps
the explicit empty-family `(intents)` planning boundary. Its maintained
`ahb_subordinate_base_output_arbitration_lifecycle_v2.vial` companion adds the
implemented lifecycle block below. `check` and `format` write no artifact, and
formatting preserves language version 2. Normal and terse output
report `normal_v2` and `terse_v2` and reparse to one
`fsmgen.vial_semantic_projection.v2` digest.

The public v2 action matrix is:

| Action | Current state | Output boundary |
| --- | --- | --- |
| `capabilities` | supported smoke | exact v2 contract, including unavailable states |
| `check` / `format` | supported smoke | sanitized v2 report or canonical v2 source; no artifacts |
| `migrate` | supported smoke | non-mutating whole-catalog v1-to-v2 result; no artifacts |
| `plan` | supported smoke for the base and lifecycle family | atomic v2 plan tree or virtual sink with typed lifecycle records |
| `run` | unavailable | `VIAL_VERSION_UNSUPPORTED`; no plan, workspace, or artifact |

Plan the checked v2 fixture with:

```bash
./bin/fsmgen vial plan --language-version 2 \
  --dut ppif/ahb_lite_subordinate.ppif \
  --fixture base_output_arbitration \
  --profile core_directed_single_clock_execution_v2 \
  --outdir .artifacts/manual/vial-v2-foundation-plan \
  --json \
  vial/ahb_subordinate_base_output_arbitration_v2.vial
```

The tree uses `fsmgen.vial_plan.v2` and
`fsmgen.vial_tool_manifest.v2`; unchanged HIAL facts stay in
`fsmgen.hial_vial_bridge_manifest.v1`. Remove only the example root after
inspection:

```bash
rm -rf .artifacts/manual/vial-v2-foundation-plan
```

V2 public requests and results are `fsmgen.vial_tool_request.v2` and
`fsmgen.vial_tool_result.v2`. The v2 result retains the v1 field family and adds
nullable `source_migration`. Embedding code uses
`vial_tool_capabilities_v2()` for v2 discovery and the common
`execute_vial_tool_request(...)` entrypoint with an exact v2 request schema.
The legacy `vial_tool_capabilities()` entrypoint remains byte-exact v1.
The maintained emission contract checks fixed, authenticated DUT input to
separate VIAL byte stability from later HIAL code-generation changes. It also
checks emission with the current DUT. This emission-only check does not run
the historical DUT or qualify simulator execution.
Successful migration records use `fsmgen.vial_source_migration.v1`; see the
[legacy migration guide](16di-vial-legacy-migration.md) before adopting any
returned source bytes.

## Implemented lifecycle-control compiler

The public command lifecycle described by this chapter is distinct from the
VIAL v2 `lifecycle_control` intent family. Revision 1 is accepted by `check`,
`format`, and `plan`. Public capability discovery names
`vial.family.lifecycle_control.v1` and
`vial.family.lifecycle_control.deadline.v1`. All version-2 backends and `run`
remain unavailable, so this is a compiler and planning contract rather than a
runtime-support claim.

The compact family form owns one fixture's dependencies, readiness, background
service, stimulus start, completion, drain, shutdown, finalization, deadlines,
and failure policy:

```vial
(family lifecycle_control
  (revision 1)
  (lifecycle fixture_flow
    (fixture base_output_arbitration)
    (domain bus)
    (dependencies
      (dependency configured_gate (when (configured)))
      (dependency reset_gate (when (reset_inactive bus))))
    (readiness ready)
    (services
      (service background (target fixture_background)))
    (stimulus_start stimulus)
    (completion complete)
    (drain drained)
    (shutdown stopped)
    (finalize finalized)
    (deadlines
      (deadline total
        (from (lifecycle_entered))
        (until (lifecycle_point finalized))
        (within 1024)))
    (failure lifecycle_failure)))
```

Normal source wraps this exact block in `(intents ...)`; terse source places the
same block directly in package declaration order. No family-specific alias or
hidden target default exists. Check, format, and plan the maintained complete
fixture directly:

```bash
./bin/fsmgen vial check --language-version 2 \
  vial/ahb_subordinate_base_output_arbitration_lifecycle_v2.vial

./bin/fsmgen vial format --language-version 2 --style terse \
  vial/ahb_subordinate_base_output_arbitration_lifecycle_v2.vial

./bin/fsmgen vial plan --language-version 2 \
  --dut ppif/ahb_lite_subordinate.ppif \
  --fixture base_output_arbitration \
  --profile core_directed_single_clock_execution_v2 \
  --outdir .artifacts/manual/vial-v2-lifecycle-plan \
  --json \
  vial/ahb_subordinate_base_output_arbitration_lifecycle_v2.vial
```

After reviewing the plan, remove only that example root. The executable
contract watcher runs the same complete fixture through all compiler phases:

```bash
prove -Iperl t/1808-vial-v2-lifecycle-compiler-phases.t
rm -rf .artifacts/manual/vial-v2-lifecycle-plan
```

The compiler supplies only fixed semantic
defaults: all dependencies and services precede readiness; readiness precedes
stimulus; selected scenarios must terminate before completion; transactions,
scoreboards, and services must settle before drain; shutdown precedes service
stop; finalization waits for stopped services. Optional conditions can add
constraints but cannot weaken this chain.

Every lifecycle has one full logical-cycle deadline and bounded failure
finalization. An expired deadline or service failure stops new stimulus,
requests cooperative cancellation and service stop, preserves the first cause
plus ordered evidence, and can never become pass. All time remains the VIAL
`(domain, cycle, phase, ordinal)` model; target schedules and host wall time are
not source semantics.

For the block above, `plan.semantic_families` contains twelve records: two
dependencies, one service, six lifecycle points, two deadlines, and one
failure policy. Every record carries its semantic node, two typed bindings
(fixture and domain), explicit operation IDs, required capabilities, and a
cumulative source map from authored span through HIAL bridge, execution, and
plan paths. Result validation requires those exact plan records, adds one
result-bearing map for every record, and accepts only the closed
`fsmgen.vial_lifecycle_result.v1` shape. It rejects omitted or substituted
record identities, changed deadline bounds or provenance, target timestamps,
process identifiers, exclusive or overrun deadline endpoints, regressed
logical-time chronology, and any pass result that retains a failure cause or
incomplete dependency, service, or lifecycle point.

Normalized conditions also stay closed across compiler stages: `reference_id`
and `domain_id` are scalar or null, while nested conditions exist only in the
`operands` array. Readiness therefore retains its dependency checks and
`service_ready` check as distinct ordered operands; malformed object-valued
references fail before backend admission.

Read the normative
[lifecycle-control family contract](../../vial-spec/lifecycle-control-v2.md)
for the complete grammar, conditions, exact defaults, typed record/result
shapes, bounds, diagnostics, backend-private mapping boundary, and nonclaims.
Do not infer emission or runtime support from successful planning; inspect
capability discovery and require a separately qualified version-2 backend.

## Portable-SystemVerilog lifecycle mapping: selected, not implemented

Decision `0100` selects the future `sv_portable_verilator` mapping without
changing current availability. The normative
[portable-SystemVerilog lifecycle mapping contract](../../vial-spec/portable-systemverilog-lifecycle-v2.md)
defines one finite, statically emitted fixture controller beside the existing
scenario scheduler. It emits no interpreter, class framework, callback, UVM
phase/objection mechanism, DPI/VPI escape, or host semantic callback.

The controller advances only at compiler-owned check seams: once after
initialization, after each inactive-edge barrier has committed its work, and
after a scenario becomes terminal. At one seam it repeatedly evaluates records
in semantic rank and ID order until no state changes. Later records can observe
earlier same-seam commits; each transition advances its ordinal, not its cycle.

Scenario and lifecycle time remain deliberately separate:

- scenario-local cycles keep the existing operation/deadline/result meaning;
- one monotone lifecycle cycle spans the fixture and every selected scenario;
- both use the reviewed domain identity, but comparison stays inside the owning
  scenario or lifecycle result scope.

This prevents a later selected scenario from resetting fixture lifecycle time.
The scenario scheduler remains the sole owner of drive/sample/react/check
operations, fibers, transactions, models, scoreboards, coverage, and faults.
The lifecycle controller gates scenario admission and observes only terminal,
transaction-active, and scoreboard-settled facts.

On the normal path, configured/reset dependencies and background-service
readiness open stimulus. Terminal scenarios permit completion; settled
transactions, scoreboards, and service work permit drain; shutdown permits
service stop and finalization. All plan-ready transitions may commit at one
check seam in distinct ordinal slots. Deadline milestones commit before expiry
is evaluated, so a bound starting at cycle `C` includes `C + N - 1`.

The first scenario, service, deadline, trace, or controller failure closes
admission, latches one primary cause, requests cooperative cancellation and
service stop, cancels unreached normal records, and runs the independently
bounded failure cleanup. Cleanup does not forge normal drain, shutdown, or
finalize milestones. A failure can never become pass.

The selected evidence route is version-isolated:

| Evidence | Selected schema |
| --- | --- |
| backend manifest | `fsmgen.vial_backend.sv_portable_verilator.v2` |
| backend source map | `fsmgen.vial_backend_source_map.v2` |
| runtime trace | `fsmgen.vial_sv_runtime_trace.v2` |
| trace projection | `fsmgen.vial_sv_trace_projection.v2` |
| normalized result manifest | `fsmgen.verification_result_manifest.v2` |
| nested lifecycle result | `fsmgen.vial_lifecycle_result.v1` |

The v2 result preserves v1 field meanings and adds only
`lifecycle_results`. The target-neutral lifecycle validator still requires
exact plan identities, deadlines, chronology, terminal completeness, and
one-for-one cumulative source maps. The selected contract forbids labeling v2
data as a v1 trace or result.

One private prerequisite remains before emission: the current standalone v1
trace validator checks the ExecutionIR object type but not its v1
schema/version/profile envelope. A canonical v1-shaped stream can therefore
be parsed against v2 IR in a direct private call. The adapter, emitter, runner,
result producer, and public v2 route still reject v2, so this cannot currently
publish a false public result. Task `.19.2.3.1.2.1` owns the required validator
guard and must close before emitter implementation.

Run the selection watcher with:

```bash
prove -Iperl t/1809-vial-v2-portable-sv-lifecycle-contract.t
```

It derives the exact record-to-controller operation map from the maintained v2
plan, checks every public/backend v2 route remains unavailable and
artifact-free, characterizes the private trace-validator prerequisite, and
freezes the complete v1 emitted graph and normalized-result bytes. Emission,
compile, runtime, result production, parity, and public v2 `run` remain
unavailable until their separately owned implementation and qualification
slices complete.

## Start with machine truth

Ask the installed FSMGen tree what the public VIAL surface advertises:

```bash
./bin/fsmgen vial capabilities --json
```

Without the version selector, the result uses `fsmgen.vial_tool_result.v1`. Inspect
`capability_evidence.supported_actions`, `capability_evidence.capabilities`,
`capability_evidence.diagnostics`, and
`capability_evidence.explicit_nonclaims` before selecting a backend or making a
support claim. Discovery describes the selected product contract; `run` still
validates the required external tool and exact profile before execution.

The complete v1 public actions have deliberately different effects:

| Action | Needs HIAL | Writes artifacts | Meaning |
| --- | --- | --- | --- |
| `capabilities` | no | no | Discover the exact public contract. |
| `check` | no | no | Parse, type, validate, and return a sanitized semantic report. |
| `format` | no | no | Write canonical normal or terse source to standard output. |
| `plan` | yes | virtual API or atomic CLI tree | Bind a reviewed HIAL route and publish target-neutral evidence. |
| `run` | yes | virtual API or atomic CLI tree | Plan, negotiate the named backend, execute its qualified profile, and publish normalized results. |

## One meaning, normal or terse source

`normal_v1` and `terse_v1` are reversible projections of the same typed VIAL
meaning. Normal form keeps the version, declaration-family, scenario, and step
wrappers. Terse form removes only those selected wrappers. It does not infer a
type, value, clock, timeout, seed, binding, event, capability, or target
behavior.

Check the canonical normal source without binding a DUT or writing a file:

```bash
./bin/fsmgen vial check --style auto --json \
  vial/ahb_subordinate_base_output_arbitration.vial
```

Render either canonical projection to standard output:

```bash
./bin/fsmgen vial format --style normal \
  vial/ahb_subordinate_base_output_arbitration.vial

./bin/fsmgen vial format --style terse \
  vial/ahb_subordinate_base_output_arbitration.vial
```

Formatting is deterministic and preserves authored order. Reparsing either
projection produces the same provenance-free semantic meaning digest; raw
source identities and spans remain different. `check --style normal` or
`check --style terse` makes the expected authored projection explicit, and a
mismatch fails with `VIAL_SOURCE_STYLE_ERROR`.

A model-state read selects an instance: `(model accepts count)` and
`(model completions count)` refer to different counters even when both
instances use the same model declaration. Their semantic meaning digests now
distinguish that choice in both VIAL versions, while formatting preserves each
choice. Earlier tooling lost the instance identity in these references; rerun
checking to refresh cached semantic or compatibility digests for affected
sources. Public summary/result shapes are unchanged. This correction does not
extend the bounded runtime backend profile.

A fault target also selects a fixture binding. If `write` and `alternate`
are aliases of the same transaction declaration, `(target (transaction write
size))` and `(target (transaction alternate size))` mean different targets.
Checking now distinguishes them in semantic and migration compatibility
digests. Rerun checking for affected cached results; single-binding fixtures
retain their existing identities and public summaries keep their shape. Source
acceptance alone does not establish backend support for multiple bindings.

The fixed AHB bridge declares `transaction/ahb_write`; a second VIAL alias
naming `transaction/alternate_write` fails planning with
`VIAL_BIND_REFERENCE_ERROR`. Reusing `transaction/ahb_write` for both aliases
fails source validation as a duplicate bridge reference. An ordinary IAL1
transaction's `declaration_order` metadata is likewise insufficient: the
execution binder requires `single_active` and reports `VIAL_BIND_EVENT_ERROR`.
These failures return no partial plan or artifacts. The separate private
balanced qualification route does not grant public multi-binding runtime
support. Deep source inspection can still describe authored intent before
binding is possible.

## Plan through a reviewable HIAL route

VIAL source describes verification intent. `--dut` separately names the HIAL
source that supplies reviewable units, domains, endpoints, transactions,
events, observations, probes, and backend-neutral bindings.

The public planner accepts these routes:

| Authored HIAL source | Review route used by planning | Boundary |
| --- | --- | --- |
| `.fsm` | direct IAL0 | Structural facts only; a transaction-bearing VIAL fixture cannot invent missing transaction truth. |
| `.isf` | direct IAL1, then generated IAL0 | May carry reviewed transactions and observation metadata. |
| `.ppif` | generated and reparsed IAL1, then generated IAL0 | Protocol facts reach VIAL through the generated IAL1 verification-bridge annotation, never a direct PPIF-to-verification shortcut. |

Plan the checked AHB fixture and choose an explicit repository-local output
root:

```bash
./bin/fsmgen vial plan \
  --dut ppif/ahb_lite_subordinate.ppif \
  --fixture base_output_arbitration \
  --scenario success \
  --profile core_directed_single_clock_execution_v1 \
  --outdir .artifacts/manual/vial-lifecycle-plan \
  --json \
  vial/ahb_subordinate_base_output_arbitration.vial
```

`plan` stops before target emission, compilation, simulation, or result
production. Its public tree contains:

```text
.artifacts/manual/vial-lifecycle-plan/
  vial-tool-manifest.json
  source/vial-normal.vial
  review/ahb_lite_subordinate.isf
  review/ahb_lite_subordinate.fsm
  hial-vial-bridge.json
  vial-plan.json
```

The review files appear because this example starts at IAL2. A direct IAL1
route generates only its IAL0 review file. A direct IAL0 input is referenced by
identity and digest rather than copied as a generated review artifact.

Generated review files contain the exact bytes from the current public HIAL
lowering route. The tool manifest's digest and byte count describe each file's
content. Public planning checks compare those bytes with current lowering,
alongside the complete artifact graph and deterministic publication checks.

Without `--outdir`, the CLI chooses a content-addressed root below
`.artifacts/vial/` using the fixture slug and complete plan digest. Every
persisted path remains repository-root-relative and on the repository volume.

## Run the selected public backend

The public run backend is `sv_portable_verilator`. Run verifies its required
tool profile; absence or mismatch is an explicit diagnosed failure, not a
downgraded success.

```bash
./bin/fsmgen vial run \
  --dut ppif/ahb_lite_subordinate.ppif \
  --backend sv_portable_verilator \
  --fixture base_output_arbitration \
  --scenario success \
  --profile core_directed_single_clock_execution_v1 \
  --outdir .artifacts/manual/vial-lifecycle-run \
  --json \
  vial/ahb_subordinate_base_output_arbitration.vial
```

`run` performs the same planning operation, then adds the selected backend
artifacts, recorded compile/run commands, validated trace evidence,
`verification-output-manifest.json`, and one content-addressed
`verification-result-manifest.json`. The result manifest is the portable
outcome boundary: it carries scenario outcomes, logical time, decisions,
events, drives, samples, transactions, expectations, models, scoreboards,
coverage, faults, fibers, diagnostics, and semantic metrics.

An ordinary public run does not produce a general parity report. The checked
AHB parity capability is separate qualification evidence, and success on one
backend does not imply mixed-language or general cross-backend support.

## Portable in-memory API

Embedding hosts use `FSM::VIAL::Tool::execute_vial_tool_request($request,
$environment)` in the reference implementation. The portability contract is
the JSON-safe data boundary, not the Perl package name.

The closed request uses `fsmgen.vial_tool_request.v1` and contains `action`,
`vial_source`, `hial_source`, and `options`. Source envelopes carry source
identity, kind hint, text, encoding, origin, display name, optional canonical
and relative identities, and JSON-safe metadata. `hial_source` is null for
discovery, checking, and formatting; it is required for planning and running.

The options record always contains:

```text
source_style
output_style
fixture_id
scenario_ids
execution_profile
backend_profile
replay_manifest
native_extension_catalogs
artifact_policy
quiet
```

Inapplicable values are explicit nulls or empty arrays. Host callbacks,
filehandles, temporary-file paths, private objects, and host-language values do
not enter the request.

For `plan` and `run`, choose one artifact policy:

```text
{ mode: virtual,    artifact_root: null }
{ mode: repository, artifact_root: repository/relative/path }
```

`virtual` requires an initially empty caller-owned artifact sink and returns
the complete ordered graph without claiming a filesystem commit. `repository`
uses the same graph but delegates its atomic publication to a host adapter; the
shipped CLI is that adapter. The caller also supplies a source catalog for VIAL
imports. The root source is carried in `vial_source`, not duplicated in the
catalog.

Every action returns the same closed `fsmgen.vial_tool_result.v1` envelope:

```text
schema, schema_version, action, success, status
source_identities, source_style, semantic_report, formatted_source
bridge_manifest, plan, tool_manifest, verification_output_manifest
result_manifest, artifacts, capability_evidence, support_accounting
diagnostics, implementation
```

Fields that do not apply are null; `artifacts` and `diagnostics` remain arrays.
The result is defensive and JSON-safe. It never exposes parser forms,
`VIALSemanticIR`, bridge-builder objects, `VIALExecutionIR`, backend objects,
raw exceptions, code references, filehandles, or absolute host paths.

## Check a filesystem source from an embedding host

Use `FSM::VIAL::Tool::check_vial_source_file($invocation)` when the host owns a
workspace directory and wants the same complete result as `vial check --json`.
The function returns data without printing, creating artifacts, planning, or
running a backend. For example, from the repository root:

```bash
perl -Iperl -MFSM::VIAL::Tool=check_vial_source_file -MJSON::PP -e '
  my $result = check_vial_source_file({
    workspace_root => ".",
    source_id => "vial/ahb_subordinate_base_output_arbitration_v2.vial",
    language_version => 2,
    source_style => "auto",
  });
  print JSON::PP->new->canonical->pretty->encode($result);
  exit($result->{success} ? 0 : 1);
'
```

The invocation is closed: `workspace_root` and `source_id` are required scalar
strings; only `language_version` and `source_style` are optional. Version
defaults to `1` and accepts `1` or `2`; style defaults to `auto` and accepts
`auto`, `normal`, or `terse`. The result uses the selected
`fsmgen.vial_tool_result.v1` or `fsmgen.vial_tool_result.v2` schema, including
`semantic_report`, source identities, support evidence, and diagnostics.
An invalid invocation returns a structured `VIAL_TOOL_INVOCATION_ERROR`.

The source and its imports must be root-relative regular files, with no
symlink components, on the workspace volume. Imports resolve from the workspace
root. Loading enforces the public source byte, combined byte, and imported-file
limits before admitting content to semantic validation, including a bounded
stream check for growth after filesystem inspection. Combined bytes include
the root once; the filesystem import count excludes the root and counts
distinct loaded files. The parser additionally retains its import-edge and
cycle checks. Excess input returns `VIAL_LIMIT_ERROR` without partial semantic
success. Missing imports and empty source files retain the portable parser's
diagnostics. These loading bounds cover VIAL source files, not HIAL or JSON
inputs to other commands.

Discover this additive contract with
`FSM::Support::VIALToolingContract::build_vial_source_file_check_contract()`
or the capability manifest at
`semantic_introspection.contract_surface_map.vial_source_file_check.file_query_contract`.
Its `loading_limits` gives the exact admitted bounds. The frozen v1 capability
record and the portable text request API remain unchanged.

The read-only MCP adapter exposes this API with explicit version selection;
see [VIAL semantic queries](11-extensions-and-embedding.md#vial-semantic-queries-and-version-selection).

## Public reports and persisted schemas

Use explicit schema fields rather than filenames or permissive key probing:

| Public value or file | Contract |
| --- | --- |
| semantic report | Sanitized, versioned check result; private semantic IR is excluded. |
| `hial-vial-bridge.json` | `fsmgen.hial_vial_bridge_manifest.v1` |
| `vial-plan.json` | `fsmgen.vial_plan.v1` |
| `vial-tool-manifest.json` | `fsmgen.vial_tool_manifest.v1` |
| `verification-output-manifest.json` from VIAL run | `fsmgen.verification_output_manifest.v2` |
| `verification-result-manifest.json` | `fsmgen.verification_result_manifest.v1` |

The tool manifest inventories every other declared artifact but does not hash
itself, which avoids a recursive self-digest. Exact-tree validation still
includes the manifest. The legacy `.isf` observation-skeleton output keeps its
distinct verification-output manifest contract; consumers select by schema,
not by the shared filename.

## Atomic publication and cleanup

The CLI validates the complete artifact graph in memory and stages only below
the repository-local `.artifacts/tmp/vial/` area. It commits the final root
only after every file, digest, schema, and path check succeeds.

- Repeating an operation against an identical complete tree returns
  `unchanged` without rewriting it.
- A partial tree, changed file, undeclared file, symlink, traversal, case-fold
  collision, or file/directory collision fails without overwrite.
- A failed check or format writes no artifact. A failed plan or run returns no
  partial bridge, plan, result, or committed tree.
- Failure after staging begins removes only the exact operation-owned staging
  root. There is no public force-overwrite or broad-cleanup option.

After inspecting the two explicit manual roots above, remove only those owned
trees:

```bash
rm -rf .artifacts/manual/vial-lifecycle-plan
rm -rf .artifacts/manual/vial-lifecycle-run
```

Do not delete an output while its command is running. The command's internal
execution and publication staging is already cleaned before it returns.

## Diagnostics and exit behavior

Human mode writes stable errors such as:

```text
Error [CODE] source:line:column semantic_path: message
```

JSON mode returns the same closed diagnostic records in `diagnostics`. Each
record has code, severity, message, source locations, semantic path, related
records, notes, and hints. Source locations and filesystem identities are
repository-relative; stacks, raw exceptions, and machine-local paths are
sanitized.

The machine contract enumerates these supported diagnostic codes:

```text
VIAL_TOOL_INVOCATION_ERROR
VIAL_SOURCE_STYLE_ERROR
VIAL_HIAL_SOURCE_ERROR
VIAL_BACKEND_UNSUPPORTED
VIAL_ARTIFACT_PATH_ERROR
VIAL_ARTIFACT_COLLISION
VIAL_MANIFEST_SCHEMA_ERROR
VIAL_RUN_INVOCATION_ERROR
VIAL_RUN_PATH_ERROR
VIAL_RUN_TOOL_ERROR
VIAL_RUN_COMMAND_ERROR
VIAL_RUN_COLLISION
VIAL_RUN_COMPILE_ERROR
VIAL_RUN_RUNTIME_ERROR
VIAL_RUN_LIMIT_EXCEEDED
VIAL_RUN_TRACE_ERROR
VIAL_RUN_RESULT_ERROR
VIAL_RUN_CLEANUP_ERROR
VIAL_RUN_HOST_ERROR
VIAL_HOST_ERROR
```

The explicit v2 contract uses the same closed record shape and enumerates:

```text
VIAL_TOOL_INVOCATION_ERROR
VIAL_SOURCE_STYLE_ERROR
VIAL_VERSION_UNSUPPORTED
VIAL_IMPORT_VERSION_MISMATCH
VIAL_COMPATIBILITY_ADAPTER_UNAVAILABLE
VIAL_COMPATIBILITY_ADAPTER_INVALID
VIAL_MIGRATION_ERROR
VIAL_FAMILY_UNSUPPORTED
VIAL_FAMILY_REVISION_MISMATCH
VIAL_PARSE_ERROR
VIAL_SCHEMA_ERROR
VIAL_SEMANTIC_ERROR
VIAL_LIMIT_ERROR
VIAL_BIND_REFERENCE_ERROR
VIAL_LIFECYCLE_DEADLINE_EXPIRED
VIAL_LIFECYCLE_SERVICE_ERROR
VIAL_LIFECYCLE_DRAIN_INCOMPLETE
VIAL_LIFECYCLE_CLEANUP_TIMEOUT
VIAL_HIAL_SOURCE_ERROR
VIAL_ARTIFACT_PATH_ERROR
VIAL_ARTIFACT_COLLISION
VIAL_MANIFEST_SCHEMA_ERROR
VIAL_HOST_ERROR
```

Unsupported means the requested capability was not proven; it never means
pass.

## Boundary and further reference

This lifecycle does not make private IR or backend construction APIs public.
It also does not claim complete four-state behavior, native-UVM runtime, public
VHDL-methodology execution, mixed-language execution, general cross-backend parity,
architecture-scale capacity, whole-product capacity, arbitrary-tool capacity,
full-language coverage, synthesis, or support promotion.

For normative fields and invariants, use:

- [VIAL source and semantic contract](../../VIAL_SOURCE_AND_SEMANTIC_IR_V1_CONTRACT.md)
- [HIAL/VIAL bridge contract](../../HIAL_VIAL_BRIDGE_MANIFEST_V1_CONTRACT.md)
- [VIAL execution, plan, and result contract](../../VIAL_EXECUTION_IR_V1_CONTRACT.md)
- [VIAL public tooling contract](../../VIAL_PUBLIC_TOOLING_V1_CONTRACT.md)
- [portable SystemVerilog backend contract](../../VIAL_PORTABLE_SYSTEMVERILOG_BACKEND_V1_CONTRACT.md)

The focused regression for this reference is
`t/1797-hial-vial-public-lifecycle-reference.t`. The backend runtime route is
independently executed by `t/1558-vial-verilator-run-integration.t` under its
qualified host/tool conditions. Continue with the
[end-to-end AHB tutorial](16dh-vial-ahb-end-to-end-tutorial.md) to apply this
lifecycle to the checked fixture, public result, bounded parity oracle, and
separate VHDL/OSVVM qualification routes.

Use the
[capability and support reference](16dj-vial-capability-support-reference.md)
to compare public, private, review, experimental, unavailable, parity, and
scale evidence without widening any claim.

For side-by-side use with IAL1 observation metadata, inert UVM/VHDL outputs,
and handwritten fixtures, continue with the
[legacy migration guide](16di-vial-legacy-migration.md).
