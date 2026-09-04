# Public VIAL Lifecycle Reference

This is the task-oriented reference for the public VIAL path that ships now.
It follows one verification source from discovery and checking through HIAL
review, target-neutral planning, the selected public backend, and normalized
results. Read [HIAL/VIAL Verification: Start Here](16d-hial-vial-verification-architecture.md)
first when you need the availability boundary between public, private,
review-only, experimental, and unavailable profiles.

The public lifecycle is:

```text
.vial source -> check/format -> reviewed HIAL bridge -> public plan
             -> selected backend run -> normalized result
```

Private compiler objects exist between those steps, but they are not an API.
Use only the command family, the portable request/result records, and the
sanitized artifacts documented here.

## Start with machine truth

Ask the installed FSMGen tree what the public VIAL surface advertises:

```bash
./bin/fsmgen vial capabilities --json
```

The result uses `fsmgen.vial_tool_result.v1`. Inspect
`capability_evidence.supported_actions`, `capability_evidence.capabilities`,
`capability_evidence.diagnostics`, and
`capability_evidence.explicit_nonclaims` before selecting a backend or making a
support claim. Discovery describes the selected product contract; `run` still
validates the required external tool and exact profile before execution.

The public actions have deliberately different effects:

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
qualified host/tool conditions.
