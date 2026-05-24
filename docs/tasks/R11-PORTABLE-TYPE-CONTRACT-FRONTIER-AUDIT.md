# R11-PORTABLE-TYPE-CONTRACT-FRONTIER-AUDIT: Portable-Type Contract Frontier Audit

## Metadata

- Tree ID: `R11-PORTABLE-TYPE-CONTRACT-FRONTIER-AUDIT`
- Status: `done`
- Roadmap lane: `R11`
- Created: `2026-05-24`
- Last updated: `2026-05-24`
- Owner: repo-local workflow

## Goal

Audit the shipped portable synthesizable type surface and select one bounded
next contract slice or an explicit deferral from evidence.

## Non-Goals

- Do not implement new portable-type behavior in the activation leaf.
- Do not add new `+types` syntax, inference, aggregate member/index access,
  backend lowering, or VHDL behavior before the audit selects one exact
  surface.
- Do not change parser, type validation, composition planning, backend
  lowering, HDL emission, or generated artifacts during the activation leaf.

## Acceptance Criteria

- The activation leaf creates clear task-tree ownership before any
  portable-type behavior-bearing work.
- The audit leaf maps shipped evidence across scalar widths, enums, aggregate
  aliases, declared type identity, structural nets/ports, composition typed
  bindings, backend-owned typedef emission, package imports, direct roots,
  generated children, and explicit deferrals.
- The audit leaf records one next implementation slice or an explicit deferral
  if the remaining work depends on a stronger portable-type, inference,
  member/index access, backend-lowering, VHDL, or architecture contract.
- Focused validation passes.
- Live docs and roadmap status are updated where project state changed.
- Each completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `R11-PORTABLE-TYPE-CONTRACT-FRONTIER-AUDIT`
  Status: `done`
  Goal: `Audit the R11 portable synthesizable type frontier and choose the next bounded slice.`
  Children: `R11-PORTABLE-TYPE-CONTRACT-FRONTIER-AUDIT.1`,
    `R11-PORTABLE-TYPE-CONTRACT-FRONTIER-AUDIT.2`

- ID: `R11-PORTABLE-TYPE-CONTRACT-FRONTIER-AUDIT.1`
  Status: `done`
  Goal: `Activate the portable-type contract frontier audit task tree.`
  Acceptance: `The active tree, roadmap status, task-tree table, live docs, and README index name this tree, and the next leaf is limited to an evidence-gathering audit before any portable-type behavior change.`
  Verification: `passed: feature-backlog audit, mdBook build, and diff check`
  Commit: `R11-PORTABLE-TYPE-CONTRACT-FRONTIER-AUDIT.1: select portable-type frontier`

- ID: `R11-PORTABLE-TYPE-CONTRACT-FRONTIER-AUDIT.2`
  Status: `done`
  Goal: `Audit shipped portable-type behavior and choose the next bounded slice or deferral.`
  Acceptance: `The audit records current evidence, remaining gaps, and one implementation direction or deferral decision before any portable-type behavior change.`
  Verification: `passed: focused portable-type evidence, feature-backlog audit, mdBook build, and diff check`
  Commit: `R11-PORTABLE-TYPE-CONTRACT-FRONTIER-AUDIT.2: audit portable-type frontier`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `R11-PORTABLE-TYPE-CONTRACT-FRONTIER-AUDIT.2` | `done` | The next R11 left item is the portable synthesizable-type contract family, and the remaining directions required an evidence-led bounded selection before code. |

Current frontier: `closed`.

## Decisions

- `2026-05-24`: Select a portable-type contract frontier audit after the
  reusable-module audit closed. The roadmap names several remaining
  directions across type-core settlement, future `+types` coexistence with
  enums, inference extent, inferred declarations, member/field and fixed-size
  array access, explicit type overrides, SystemVerilog lowering, and future
  VHDL lowering, so the next safe step is to map shipped evidence and choose
  one bounded implementation slice or deferral.
- `2026-05-24`: Defer new portable-type implementation for now. The shipped
  bounded contract is already regression-backed across scalar aliases, signed
  and two-state/four-state scalar intent, positive scalar width symbols,
  enum values, package-qualified type/value references, packed list/record
  aliases, declared type identity through direct roots and composition tops,
  aggregate member/list-item access on direct and composition source paths,
  bounded aggregate target inference, backend-owned SystemVerilog packed
  typedef emission, symbol contracts, `Intent HIR`, `Structural RTL IR`, and
  VHDL fail-closed diagnostics. Broader portable-type work should wait for
  one exact frontend type-core, inference, member/index, backend-lowering,
  VHDL, or public API contract.

## Audit Result

Supported shipped evidence:

- Scalar type aliases cover `bit`, `(bits N)`, `(bits WIDTH_SYMBOL)`,
  `(signed TYPE)`, `(two_state TYPE)`, `(four_state TYPE)`, and local or
  imported scalar aliases. The symbol contract preserves width, signedness,
  and state-model intent, and SystemVerilog declarations choose `bit` or
  `logic` carriers from that semantic contract.
- `+enums`, scalar constants, aggregate constants, and package-qualified
  values remain separate semantic declaration families that feed typed width
  positions, aggregate values, direct expressions, and composition structural
  actuals without becoming textual includes.
- Packed aggregate aliases cover exact `list` and `record` contracts with
  stable authored record order and deterministic list item fields. Direct
  roots and composition tops preserve those contracts into backend-owned
  SystemVerilog packed typedefs when a stable declared or inferred aggregate
  contract exists.
- Direct roots support typed aggregate signal member/list-item reads and
  partial aggregate LHS writes when the aggregate root has a declared type.
  The pre-generation type gate rejects unknown members, scalar roots used as
  records, undeclared aggregate roots, unsupported list ranges, and
  list-vs-record shape mismatches before HDL emission.
- Composition supports typed aggregate top-port and generated-child output
  member/list-item source paths, whole aggregate actuals, source concat
  inference from declared or safely inferred aggregate roots, and typed
  structural connection expressions that preserve resolved leaf width/type
  metadata.
- Forward metadata preserves the bounded type surface through direct and
  composition symbol contracts, `Intent HIR`, `module_info`, direct and
  composition `Structural RTL IR`, realized child interface ports, and
  inferred carrier nets.
- The VHDL target remains an explicit fail-closed boundary for composition and
  aggregate lowering. The current portable-type contract is therefore
  SystemVerilog-backed, with future VHDL record/array lowering deferred until
  the VHDL backend and composition target support are active.

Deferred surfaces:

- a single frontend portable type core spanning bits/vectors, enum-as-type
  semantics, records, fixed-size arrays, arrays of records, aliases/subtypes,
  signedness, state model, and backend-neutral value/category roles;
- broad inference-first scalar declarations and aggregate member/index
  autogrowth beyond complete compile-time shape evidence;
- fixed-size array and array-of-record syntax/lowering;
- full enum/type unification between `+types` and the existing `+enums`
  declaration family;
- arbitrary subaggregate runtime operators, aggregate paths in all expression
  operator positions, and mixed scalar/aggregate operator domains;
- portable VHDL record/array lowering and VHDL generic-map composition paths;
- richer public type/export APIs for embedders.

No implementation slice is selected from this tree. The next R11 activity
should move to another roadmap family, while future portable-type work should
be task-tree-selected only when one prerequisite is ready.

## Open Questions

- None. `.2` owns the evidence-gathering audit and next-frontier decision.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-24` | `R11-PORTABLE-TYPE-CONTRACT-FRONTIER-AUDIT.1` | `prove -Iperl t/1256-feature-backlog-status-audit.t`; `mdbook build docs/book`; `git diff --check` | `passed: feature-backlog audit Files=1, Tests=15` |
| `2026-05-24` | `R11-PORTABLE-TYPE-CONTRACT-FRONTIER-AUDIT.2` | `prove -Iperl t/279-declarative-scalar-types.t t/280-declarative-aggregate-types.t t/281-structural-declared-type-contracts.t t/282-composition-aggregate-source-expression-contracts.t t/283-composition-aggregate-path-support.t t/284-package-aggregate-path-support.t t/285-aggregate-expression-type-support.t t/288-composition-aggregate-top-expression-inference.t t/277-direct-symbol-contract-forward-ir.t t/278-composition-symbol-contract-forward-ir.t t/1333-direct-structural-rtl-ir-projection.t t/114-composition-target-support-diagnostics.t t/386-hdl-generator-facade-target-language-boundary-audit.t`; `prove -Iperl t/1256-feature-backlog-status-audit.t`; `mdbook build docs/book`; `git diff --check` | `passed: focused portable-type evidence Files=13, Tests=59; feature-backlog audit Files=1, Tests=15` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `R11-PORTABLE-TYPE-CONTRACT-FRONTIER-AUDIT.1` | `R11-PORTABLE-TYPE-CONTRACT-FRONTIER-AUDIT.1: select portable-type frontier` | `selection slice` |
| `R11-PORTABLE-TYPE-CONTRACT-FRONTIER-AUDIT.2` | `R11-PORTABLE-TYPE-CONTRACT-FRONTIER-AUDIT.2: audit portable-type frontier` | `audit/deferral slice` |

## Changelog

- `2026-05-24`: Created active `R11` portable-type contract frontier audit
  tree and selected `.2` as the evidence-gathering frontier.
- `2026-05-24`: Completed `.2`, recorded that no new portable-type
  implementation slice is selected now, and closed the tree.
