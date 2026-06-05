# COMPOSITION-TYPE-BACKLOG-EXHAUSTION: Composition And Type Backlog Exhaustion

## Metadata

- Tree ID: `COMPOSITION-TYPE-BACKLOG-EXHAUSTION`
- Status: `active`
- Roadmap lane: `Composition` / `Aggregate Types And Data`
- Created: `2026-06-05`
- Last updated: `2026-06-05`
- Owner: repo-local workflow

## Goal

Exhaust the combined Composition/type backlog by selecting and completing
bounded, reviewable leaves until no executable Composition/type backlog item
remains or a real prerequisite blocker is reached.

## Non-Goals

- Do not treat this broad tree as permission to change behavior without a
  selected executable leaf.
- Do not widen public composition, type, aggregate, or VHDL contracts without
  synchronized mdBook/public documentation and focused regression coverage.
- Do not bypass the existing R11/R14 audit evidence; use it as the starting
  boundary for each selected leaf.

## Acceptance Criteria

- Every Composition/type backlog item named in the remaining-work inventory is
  represented as a leaf or explicit deferral/blocker.
- The current frontier always points to one executable next leaf.
- Each behavior-bearing leaf updates source, tests, public docs/mdBook, and
  downstream-visible contracts as warranted.
- Focused validation passes for each leaf; broader gates run when the blast
  radius warrants them.
- Each completed leaf is committed through `COMMIT.md` before selecting the
  next one.

## Task Tree

- ID: `COMPOSITION-TYPE-BACKLOG-EXHAUSTION`
  Status: `active`
  Goal: `Exhaust the Composition/type backlog through bounded task-scoped leaves.`
  Children: `COMPOSITION-TYPE-BACKLOG-EXHAUSTION.1`,
    `COMPOSITION-TYPE-BACKLOG-EXHAUSTION.2`,
    `COMPOSITION-TYPE-BACKLOG-EXHAUSTION.3`,
    `COMPOSITION-TYPE-BACKLOG-EXHAUSTION.4`,
    `COMPOSITION-TYPE-BACKLOG-EXHAUSTION.5`,
    `COMPOSITION-TYPE-BACKLOG-EXHAUSTION.6`,
    `COMPOSITION-TYPE-BACKLOG-EXHAUSTION.7`,
    `COMPOSITION-TYPE-BACKLOG-EXHAUSTION.8`,
    `COMPOSITION-TYPE-BACKLOG-EXHAUSTION.9`,
    `COMPOSITION-TYPE-BACKLOG-EXHAUSTION.10`,
    `COMPOSITION-TYPE-BACKLOG-EXHAUSTION.11`,
    `COMPOSITION-TYPE-BACKLOG-EXHAUSTION.12`,
    `COMPOSITION-TYPE-BACKLOG-EXHAUSTION.13`

- ID: `COMPOSITION-TYPE-BACKLOG-EXHAUSTION.1`
  Status: `done`
  Goal: `Activate the Composition/type backlog tree and inventory the named leaves.`
  Acceptance: `The tree exists, is active in docs/TASK_TREE.md, and lists every Composition/type item from the remaining-work inventory.`
  Verification: `passed: memory architecture, mdBook, feature-backlog status, doc path, knowledge-map, and diff checks`
  Commit: `PROJECT-REMAINING-WORK-TASKTREE-OWNERSHIP.1: track remaining backlog owners`

- ID: `COMPOSITION-TYPE-BACKLOG-EXHAUSTION.2`
  Status: `done`
  Goal: `Select the first executable Composition/type implementation or deferral leaf from evidence.`
  Acceptance: `Existing R11/R14 audit evidence and the mdBook backlog are reviewed, one bounded next behavior/doc/test slice is selected, and the selected leaf is either made executable in this tree or explicitly deferred with a prerequisite.`
  Verification: `passed: memory architecture, mdBook, feature-backlog status, doc path, knowledge-map, and diff checks`
  Commit: `COMPOSITION-TYPE-BACKLOG-EXHAUSTION.2: select aggregate equality leaf`

- ID: `COMPOSITION-TYPE-BACKLOG-EXHAUSTION.3`
  Status: `done`
  Goal: `Select the next shared-datapath route/storage/protocol contract or blocker from evidence.`
  Acceptance: `Existing R11 shared-datapath evidence, mdBook text, and regression coverage are reviewed; one exact executable leaf is added or activated, or the backlog item is explicitly deferred with a prerequisite. No code/test/source change may occur under this leaf unless that exact executable owner exists first.`
  Verification: `passed: focused shared-datapath evidence, memory architecture, mdBook, feature-backlog status, doc path, knowledge-map, and diff checks`
  Commit: `COMPOSITION-TYPE-BACKLOG-EXHAUSTION.3: defer shared-datapath widening`

- ID: `COMPOSITION-TYPE-BACKLOG-EXHAUSTION.4`
  Status: `done`
  Goal: `Select the next reusable standalone-DT module interface/export or lookup contract or blocker from evidence.`
  Acceptance: `Existing reusable standalone-DT/module evidence, mdBook text, and regression coverage are reviewed; one exact executable leaf is added or activated, or the backlog item is explicitly deferred with a prerequisite. No code/test/source change may occur under this leaf unless that exact executable owner exists first.`
  Verification: `passed: focused reusable-module evidence, memory architecture, mdBook, feature-backlog status, doc path, knowledge-map, and diff checks`
  Commit: `COMPOSITION-TYPE-BACKLOG-EXHAUSTION.4: defer reusable-module widening`

- ID: `COMPOSITION-TYPE-BACKLOG-EXHAUSTION.5`
  Status: `done`
  Goal: `Select the next top-boundary convention, re-export, conflict, interface-bundle, or protocol-group contract or blocker from evidence.`
  Acceptance: `Existing top-boundary convention evidence, mdBook text, and regression coverage are reviewed; one exact executable leaf is added or activated, or the backlog item is explicitly deferred with a prerequisite. No code/test/source change may occur under this leaf unless that exact executable owner exists first.`
  Verification: `passed: focused top-boundary convention evidence, memory architecture, mdBook, feature-backlog status, doc path, knowledge-map, and diff checks`
  Commit: `COMPOSITION-TYPE-BACKLOG-EXHAUSTION.5: defer top-boundary widening`

- ID: `COMPOSITION-TYPE-BACKLOG-EXHAUSTION.6`
  Status: `done`
  Goal: `Select the next generated-child top instantiation surface or blocker from evidence.`
  Acceptance: `Existing generated-child top-instantiation evidence, mdBook text, and regression coverage are reviewed; one exact executable leaf is added or activated, or the backlog item is explicitly deferred with a prerequisite. No code/test/source change may occur under this leaf unless that exact executable owner exists first.`
  Verification: `passed: focused generated-child top evidence, memory architecture, mdBook, feature-backlog status, doc path, knowledge-map, and diff checks`
  Commit: `COMPOSITION-TYPE-BACKLOG-EXHAUSTION.6: defer generated-child top widening`

- ID: `COMPOSITION-TYPE-BACKLOG-EXHAUSTION.7`
  Status: `done`
  Goal: `Select the next spawn/blocking-do parameter or value binding contract or blocker from evidence.`
  Acceptance: `Existing activation-parameter/value-binding evidence, mdBook text, and regression coverage are reviewed; one exact executable leaf is added or activated, or the backlog item is explicitly deferred with a prerequisite. No code/test/source change may occur under this leaf unless that exact executable owner exists first.`
  Verification: `passed: focused activation parameter/value-binding evidence, memory architecture, mdBook, feature-backlog status, doc path, knowledge-map, and diff checks`
  Commit: `COMPOSITION-TYPE-BACKLOG-EXHAUSTION.7: defer activation binding widening`

- ID: `COMPOSITION-TYPE-BACKLOG-EXHAUSTION.8`
  Status: `done`
  Goal: `Select the next repeat-body child-activation variant or blocker from evidence.`
  Acceptance: `Existing repeat-body child-activation evidence, mdBook text, and regression coverage are reviewed; one exact executable leaf is added or activated, or the backlog item is explicitly deferred with a prerequisite. No code/test/source change may occur under this leaf unless that exact executable owner exists first.`
  Verification: `passed: focused repeat-body/cross-domain activation evidence, mdBook truth-sync, memory architecture, mdBook, feature-backlog status, doc path, knowledge-map, and diff checks`
  Commit: `COMPOSITION-TYPE-BACKLOG-EXHAUSTION.8: defer repeat activation widening`

- ID: `COMPOSITION-TYPE-BACKLOG-EXHAUSTION.9`
  Status: `done`
  Goal: `Select the next portable type-core contract or blocker from evidence.`
  Acceptance: `Existing portable type-core evidence, mdBook text, and regression coverage are reviewed; one exact executable leaf is added or activated, or the backlog item is explicitly deferred with a prerequisite. No code/test/source change may occur under this leaf unless that exact executable owner exists first.`
  Verification: `passed: focused portable-type evidence, memory architecture, mdBook, feature-backlog status, doc path, knowledge-map, and diff checks`
  Commit: `COMPOSITION-TYPE-BACKLOG-EXHAUSTION.9: defer portable type-core widening`

- ID: `COMPOSITION-TYPE-BACKLOG-EXHAUSTION.10`
  Status: `done`
  Goal: `Select the next aggregate member/index autogrowth proof surface or blocker from evidence.`
  Acceptance: `Existing aggregate member/index autogrowth evidence, mdBook text, and regression coverage are reviewed; one exact executable leaf is added or activated, or the backlog item is explicitly deferred with a prerequisite. No code/test/source change may occur under this leaf unless that exact executable owner exists first.`
  Verification: `passed: focused aggregate autogrowth/member-path evidence, memory architecture, mdBook, feature-backlog status, doc path, knowledge-map, and diff checks`
  Commit: `COMPOSITION-TYPE-BACKLOG-EXHAUSTION.10: defer member autogrowth`

- ID: `COMPOSITION-TYPE-BACKLOG-EXHAUSTION.11`
  Status: `done`
  Goal: `Implement binary semantic parameter/generic aggregate equality and inequality.`
  Acceptance: `Direct +params, .rtlif defaults, external RTL overrides, and generated-child overrides accept binary (== A B) and (!= A B) only when both operands resolve to aggregate values with matching shape. The operators fold before HDL lowering to exact-width scalar literals 1'b1 or 1'b0. Bad arity, mixed scalar/aggregate operands, mismatched shapes, runtime direct .fsm aggregate expressions, ISF runtime aggregate expressions, VHDL aggregate lowering, scalar/aggregate mixing, and mismatched-shape operators remain fail-closed or deferred.`
  Verification: `passed: focused language/composition/corpus checks, mdBook, feature-backlog status, doc path, knowledge-map, memory-architecture, and diff checks`
  Commit: `COMPOSITION-TYPE-BACKLOG-EXHAUSTION.11: implement aggregate comparison operators`

- ID: `COMPOSITION-TYPE-BACKLOG-EXHAUSTION.12`
  Status: `done`
  Goal: `Broaden backend-owned struct/record default lowering policy.`
  Acceptance: `One exact aggregate-like value class is selected for backend-owned lowering or explicit fail-closed deferral, with docs and regression coverage.`
  Verification: `passed: focused backend-owned typedef evidence, memory architecture, mdBook, feature-backlog status, doc path, knowledge-map, and diff checks`
  Commit: `COMPOSITION-TYPE-BACKLOG-EXHAUSTION.12: defer struct default lowering`

- ID: `COMPOSITION-TYPE-BACKLOG-EXHAUSTION.13`
  Status: `pending`
  Goal: `Track VHDL aggregate lowering and VHDL generic-map lowering prerequisites.`
  Acceptance: `The VHDL-backed Composition/type work is either activated under a VHDL backend owner or explicitly blocked behind that prerequisite with the book and task tree synchronized.`
  Verification: `pending`
  Commit: `pending`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `COMPOSITION-TYPE-BACKLOG-EXHAUSTION.13` | `pending` | Backend-owned struct/record default lowering is explicitly deferred beyond exact contract-backed Verilog-family surfaces; the next Composition/type item tracks VHDL aggregate/generic-map prerequisites. |

## Selection Result

`COMPOSITION-TYPE-BACKLOG-EXHAUSTION.2` selected
`COMPOSITION-TYPE-BACKLOG-EXHAUSTION.11` as the first executable
Composition/type implementation leaf.

The selected slice is intentionally narrow:

- It stays in `FSM::ParameterValueSupport`, the existing fold-before-HDL
  normalizer for semantic parameter/generic aggregate values.
- It applies only to direct `+params`, `.rtlif` defaults, external RTL
  parameter/generic overrides, and generated-child parameter overrides after
  those values resolve to semantic payloads.
- It adds only binary `(== A B)` and `(!= A B)` for matching aggregate
  shapes, returning one scalar exact-width literal.
- It does not add runtime direct `.fsm` aggregate operators, ISF runtime
  aggregate operators, mixed scalar/aggregate operators, mismatched-shape
  operators, VHDL aggregate lowering, or backend-rendered aggregate operators.

Other candidates remain deferred for now:

- VHDL aggregate and generic-map lowering are still blocked by the full VHDL
  backend/composition target prerequisite.
- Member/index-root autogrowth remains unsafe without a complete root-shape
  proof source.
- Shared-datapath, reusable-module, top-boundary, generated-child top, and
  parameter-binding broadenings still need a more specific route/storage,
  reusable-module, convention, or activation contract before code.

## Implementation Result

`COMPOSITION-TYPE-BACKLOG-EXHAUSTION.11` shipped binary semantic
parameter/generic aggregate comparison:

- `(== A B)` and `(!= A B)` are accepted by the existing
  `FSM::ParameterValueSupport` fold-before-HDL normalizer when both operands
  resolve to matching list/record aggregate shapes.
- The result folds to scalar exact-width `1'b1` or `1'b0`.
- The supported surfaces are direct `+params`, `.rtlif` parameter/generic
  defaults, external RTL parameter/generic overrides, and generated-child
  parameter overrides.
- Bad arity, scalar/aggregate mixing, mismatched shapes, runtime aggregate
  expressions, ISF runtime aggregate expressions, and VHDL aggregate lowering
  remain fail-closed or deferred.
- The user-facing contract is documented in `docs/book/` and indexed by
  `docs/knowledge/aggregate-parameter-comparison.md`.

## Shared-Datapath Selection Result

`COMPOSITION-TYPE-BACKLOG-EXHAUSTION.3` reviewed the closed
`R11-SHARED-DATAPATH-CONTRACT-FRONTIER-AUDIT`, the current mdBook boundary,
and the focused shared-datapath regression suite.

No new shared-datapath implementation leaf is selected from this tree. The
existing shipped contract already covers the bounded same-name generated-FSM
output family surface, candidate metadata, helper wiring, guard assertions,
registered lifted runtimes, combinational lifted carriers, public/internal
visibility cases, typed contributor compatibility, CLI summaries, and
forward-IR exports.

The remaining shared-datapath backlog stays deferred until an exact
route/storage/protocol, reusable-module, portable-type, VHDL/backend, or
architecture prerequisite is explicit. Deferred items include arbitrary route
mux/storage, general fan-in/fan-out protocols, ready/backpressure, payload
protocols, dynamic scheduling, external-RTL or standalone-DT contributors,
mixed registered/combinational runtime lifting, and broader shared-data
movement.

## Reusable Standalone-DT Selection Result

`COMPOSITION-TYPE-BACKLOG-EXHAUSTION.4` reviewed the closed
`R11-REUSABLE-MODULE-CONTRACT-FRONTIER-AUDIT`, the current mdBook boundary,
and the focused reusable standalone-DT/module regression suite.

No new reusable-module implementation leaf is selected from this tree. The
existing shipped contract already covers canonical `?dt:name` roots,
compatibility aliases outside strict child-source checks, composition-facing
`?dtc` children, explicit standalone-DT system metadata, generated-child
lookup through embedded roots / repeated `--path DIR` roots / `FSMLIB` /
local source context, block-enable families, grouped multi-drive target
metadata, SystemVerilog assertion hooks, composition child exports,
generated-child defaults and parameter overrides, CLI summaries, and
forward-IR exports.

The remaining reusable-module backlog stays deferred until an exact
reusable-module, lookup, package/import, enable-control, portable-type,
VHDL/backend, or architecture prerequisite is explicit. Deferred items include
unnamed reusable roots, authored DT enable-control, declarative reusable
packages, advanced reusable-module interface/export rules, broader lookup
policy, external activation/deactivation, advanced same-target merge/priority,
and debug-reporting semantics.

## Top-Boundary Convention Selection Result

`COMPOSITION-TYPE-BACKLOG-EXHAUSTION.5` reviewed the closed
`R11-TOP-BOUNDARY-CONVENTION-FRONTIER-AUDIT`, the current mdBook boundary,
and the focused top-boundary convention regression suite.

No new top-boundary convention implementation leaf is selected from this tree.
The existing shipped contract already covers single-child passthrough,
explicit-link omitted/empty `?ports` inference, same-name top-input fanout,
same-name top-output adoption, internal-carrier inference and compatible
top-output re-export, declared compact `=name` and verbose
`:same-name`/`:connect-by-name`, generated/RTL/mixed child lanes,
declared-type compatibility checks, explicit `?wiring` overrides,
provenance/block reporting, `Intent HIR`, and `Structural RTL IR`.

The remaining top-boundary backlog stays deferred until one exact composition,
interface-bundle, protocol-group, re-export, arbitration, portable-type,
VHDL/backend, or architecture prerequisite is explicit. Deferred items include
broader hidden child-to-child inference, interface bundles, protocol groups,
automatic priority/merge/arbitration for same-name conflicts, wider public
re-export policy, non-top-boundary convention semantics, and richer local
override syntax not already covered by `?ports` and `?wiring`.

## Generated-Child Top Selection Result

`COMPOSITION-TYPE-BACKLOG-EXHAUSTION.6` reviewed the current generated-child
composition book boundary and focused generated-child top regressions.

No new generated-child top implementation leaf is selected from this tree. The
existing shipped contract already covers bounded generated composition tops for
spawn, generated blocking `do`, and generated rule-trigger activation
surfaces, including scheduled parent/child artifacts, generated top `.fsm`
emission, composition-pipeline HDL lowering, start/done handoffs, named-drive
handoffs, explicit port-binding handoffs, per-instance parameter overrides,
generated-child override lowering, and public schedule-report
`generated_composition` discovery metadata.

The remaining generated-child top backlog stays deferred until an exact
activation/top/composition, route/storage/protocol, reusable-module,
portable-type, VHDL/backend, or architecture prerequisite is explicit.
Deferred items include broader generated-child top forms beyond the shipped
spawn/generated-do/rule-trigger patterns, generalized child lifecycle
semantics, recursive or dynamic child generation, wider generated-child data
routes outside already selected ATL route slices, and new protocol-like
generated-top behavior.

## Activation Parameter And Value-Binding Selection Result

`COMPOSITION-TYPE-BACKLOG-EXHAUSTION.7` reviewed
`ISF-ACTIVATION-PARAM-OVERRIDES`,
`ISF-ACTIVATION-BIND-EXPRESSIONS`,
`ISF-RULE-TRIGGER-GENERATED-OUTPUT-BINDINGS`, the current mdBook boundary,
and focused activation parameter/value-binding regressions.

No new implementation leaf is selected from this tree. Existing shipped
contracts already cover static activation-site parameter overrides for spawn,
generated blocking `do`, and rule `trigger`; actor constants, actor-local
scalar parameter defaults, enum members, qualified package scalar constants,
and compatible aggregate/list literal leaves as static override sources;
expression-valued input bindings for shipped activation sites; generated-child
rule-trigger scalar output bindings; binding timing metadata; and fail-closed
direct `(on ...)` parameter specialization.

The remaining activation parameter/value-binding backlog stays deferred until
an exact activation/binding, completion-identity, snapshot/live timing,
portable-type, VHDL/backend, or architecture prerequisite is explicit.
Deferred items include direct/local rule-trigger output bindings, direct
`(on ...)` activation-site parameter overrides, runtime-valued parameter
overrides, arbitrary expression static-override values outside the shipped
domain, non-scalar actor parameters as override values, output binding
expression targets, and behavior-changing snapshot-vs-live timing conversion.

## Repeat-Body Child-Activation Selection Result

`COMPOSITION-TYPE-BACKLOG-EXHAUSTION.8` reviewed the closed
`ISF-REPEAT-BODY-CHILD-ACTIVATION` tree, the loop/deeper repeat-body
frontier trees, the active `ISF-NESTED-CROSS-DOMAIN-ACTIVATION` frontier, the
current mdBook boundary, and focused repeat-body/cross-domain regressions.

No new implementation leaf is selected from this broad Composition/type tree.
Existing shipped surfaces already cover same-domain child activation at the
transaction top level, repeat body, and direct top-level branch/loop bodies;
top-level repeat-body local/generated `do`, generated-child `do`, static
parameter/bind/same-domain metadata generated `do`, spawn with same-body
drains, source-order samples, and multi-pending `await_any` with later
same-body `await_all`; branch-contained nested repeat generated-spawn and
generated-do variants documented in the mdBook; loop-contained/deeper-nested
local/generated `do`, basic spawn + drain, and multi-pending `await_any` +
later drain; and cross-domain blocking `do` through an activation crossing at
the transaction top level or directly inside top-level bodies.

The remaining repeat-body backlog stays deferred until an exact activation,
CDC, outstanding-child, full-HDL composition-wiring, portable-type,
VHDL/backend, or architecture prerequisite is explicit. Deeper-nested
cross-domain blocking `do` is already owned by
`ISF-NESTED-CROSS-DOMAIN-ACTIVATION.5` and later. Cross-domain `spawn`,
deeper-nested cross-domain activation outside that active owner,
mismatched-domain generated-do metadata, undrained spawn forms, broader
outstanding-child semantics, nested `stage`/`contract`, and the repeat-spawn
full-HDL `--check-json` composition-wiring boundary remain deferred until a
more exact owner selects them. This leaf also synced stale mdBook wording so
the book distinguishes shipped activation-crossing `do` from deferred
deeper-nested/cross-domain-spawn/generated-domain cases.

## Portable Type-Core Selection Result

`COMPOSITION-TYPE-BACKLOG-EXHAUSTION.9` reviewed the closed
`R11-PORTABLE-TYPE-CONTRACT-FRONTIER-AUDIT`, the current mdBook type/backlog
boundary, and focused portable-type regressions.

No new implementation leaf is selected from this broad Composition/type tree.
Existing shipped surfaces already cover scalar aliases for `bit`, `(bits N)`,
positive symbolic widths, signed variants, explicit two-state/four-state
intent, local/imported scalar aliases, packed list/record aliases, declared
type identity through direct roots and composition tops, backend-owned
SystemVerilog packed typedef emission, direct typed aggregate member/list-item
reads and partial scalar-leaf writes, composition typed aggregate source paths
and whole-aggregate actuals, bounded aggregate-root inference when a declared
or safely inferred root exists, symbol-contract / `Intent HIR` /
`Structural RTL IR` preservation, and the ISF enum/type clarity rule that enum
families are value families rather than implicit type aliases.

The remaining portable type-core backlog stays deferred until an exact
frontend type-core, inference, member/index, backend-lowering, VHDL, public
API, or architecture prerequisite is explicit. Deferred items include
enum-as-type unification, fixed-size arrays, arrays of records, aggregate
interface ports, transaction-local aggregate ports, aggregate storage banks,
broad inference-first scalar declarations, broad aggregate member/index
autogrowth without complete shape evidence, arbitrary subaggregate runtime
operators, backend-neutral signedness/state-model policy across every inferred
site, VHDL record/array/generic-map lowering, and richer public type/export
APIs.

## Aggregate Member/Index Autogrowth Selection Result

`COMPOSITION-TYPE-BACKLOG-EXHAUSTION.10` reviewed the closed
`AGGREGATE-AUTOGROWTH-FROM-USAGE` tree, the current mdBook aggregate-growth
boundary, and focused aggregate member/path regressions.

No new implementation leaf is selected from this broad Composition/type tree.
Existing shipped surfaces already cover declared aggregate aliases, canonical
aggregate constants, direct typed aggregate member/list-item reads, partial
scalar-leaf writes against declared aggregate roots, whole-signal aggregate
contract inference from complete aggregate constant roots, list-only direct
RHS concat target autogrowth, composition typed aggregate source paths, and
bounded composition top-port aggregate inference when a declared or safely
inferred root contract already exists.

The remaining member/index-root autogrowth backlog stays deferred until an
exact complete root-shape proof source or explicit syntax contract is
selected. A partial use such as `FRAME.flag` or `in_frame.tag` proves only one
leaf path; it does not prove the full record/list shape, record member order,
list length, conflict policy, anonymous type name, packed layout, or backend
lowering contract. Current diagnostics that require a declared or safely
inferred aggregate root remain the signoff-level behavior. The mdBook already
states this boundary in `docs/book/src/08-type-inference-and-aggregate-data.md`
and `docs/book/src/14-feature-backlog.md`, so this leaf required no book
source change.

## Backend-Owned Struct/Record Selection Result

`COMPOSITION-TYPE-BACKLOG-EXHAUSTION.12` reviewed the closed
`BACKEND-OWNED-STRUCT-RECORD-DEFAULT-LOWERING` tree, the current mdBook
backend-owned typedef boundary, the shared Verilog-family typedef renderer,
and focused backend-owned typedef regressions.

No new implementation leaf is selected from this broad Composition/type tree.
Existing shipped surfaces already preserve stable aggregate contracts through
backend-owned SystemVerilog packed typedefs for direct generated-module ports,
direct internal/helper declarations, structural composition ports and nets,
projected child aggregate carriers, bounded inferred direct targets, and ISF
actor-owned aggregate storage after scheduled `.fsm` lowering.

The remaining default-lowering backlog stays deferred until one exact
aggregate-like value class has a complete frontend contract and a proven
synthesizable backend contract. Deferred classes include VHDL aggregate
lowering, ISF aggregate aliases on interface ports, transaction ports, and
banks, backend-owned struct creation from partial member/index use,
width-only evidence, anonymous record/list guesses, and public type/export API
stabilization. The mdBook already states this boundary in
`docs/book/src/08-type-inference-and-aggregate-data.md` and
`docs/book/src/14-feature-backlog.md`, so this leaf required no book source
change.

## Evidence To Reuse

- `R11-COMPOSITION-CONTRACT-FRONTIER-AUDIT`
- `R11-SHARED-DATAPATH-CONTRACT-FRONTIER-AUDIT`
- `R11-REUSABLE-MODULE-CONTRACT-FRONTIER-AUDIT`
- `R11-TOP-BOUNDARY-CONVENTION-FRONTIER-AUDIT`
- `R11-PORTABLE-TYPE-CONTRACT-FRONTIER-AUDIT`
- `R11-PARAMETER-GENERIC-FRONTIER-AUDIT`
- `AGGREGATE-AUTOGROWTH-FROM-USAGE`
- `BACKEND-OWNED-STRUCT-RECORD-DEFAULT-LOWERING`
- `RICHER-AGGREGATE-OPERATORS`
- `ISF-SPAWN-IN-REPEAT` and later repeat-body child-activation trees

## Decisions

- `2026-06-05`: Activate this tree as the user-selected focus after the
  remaining-work inventory. It owns the combined Composition/type bullet until
  exhaustion.
- `2026-06-05`: Start with an evidence-led selection leaf because the shipped
  R11 audit trees explicitly deferred new implementation until a precise
  route/storage/protocol, reusable-module, portable-type, VHDL, or architecture
  contract is selected.
- `2026-06-05`: Select binary semantic parameter/generic aggregate equality
  and inequality as the first code-bearing leaf. This is the smallest
  non-blocked Composition/type widening found in the evidence sweep: it uses
  the existing aggregate value normalizer, has a precise type/shape/result
  contract, and avoids VHDL/runtime aggregate-expression blockers.
- `2026-06-05`: Do not select a new shared-datapath implementation leaf from
  `.3`. The R11 audit, book boundary, and focused regressions already cover
  the bounded shipped surface; broader work remains blocked until one exact
  route/storage/protocol or adjacent prerequisite is selected.
- `2026-06-05`: Do not select a new reusable-module implementation leaf from
  `.4`. The R11 audit, book boundary, and focused regressions already cover
  the bounded shipped surface; broader work remains blocked until one exact
  reusable-module, lookup, package/import, enable-control, portable-type, or
  architecture prerequisite is selected.
- `2026-06-05`: Do not select a new top-boundary convention implementation
  leaf from `.5`. The R11 audit, book boundary, and focused regressions
  already cover the bounded shipped surface; broader work remains blocked
  until one exact composition contract is selected.
- `2026-06-05`: Do not select a new generated-child top implementation leaf
  from `.6`. The current book boundary and focused regressions already cover
  the bounded shipped spawn, generated blocking `do`, and generated
  rule-trigger top surfaces; broader work remains blocked until one exact
  generated-child top contract is selected.
- `2026-06-05`: Do not select a new activation parameter/value-binding
  implementation leaf from `.7`. Closed ISF trees, the current book boundary,
  and focused regressions already cover the bounded shipped spawn,
  generated-do, rule-trigger, input-binding, generated-output-binding, and
  direct-on fail-closed surfaces; broader work remains blocked until one exact
  activation/binding contract is selected.
- `2026-06-05`: Do not select a new repeat-body child-activation
  implementation leaf from `.8`. Closed repeat-body trees, the active nested
  cross-domain owner, the current book boundary, and focused regressions
  already cover the bounded shipped same-domain and top-level activation-crossing
  surfaces; broader work remains blocked until one exact activation, CDC,
  outstanding-child, or composition-wiring contract is selected.
- `2026-06-05`: Do not select a new portable type-core implementation leaf
  from `.9`. The R11 audit, current book boundary, and focused regressions
  already cover the bounded shipped scalar/aggregate/type-identity surface;
  broader work remains blocked until one exact frontend type, inference,
  backend-lowering, VHDL, public API, or architecture contract is selected.
- `2026-06-05`: Do not select a new aggregate member/index autogrowth
  implementation leaf from `.10`. The closed autogrowth tree, current book
  boundary, and focused regressions already cover complete-shape autogrowth
  sources; partial member/index use remains blocked until one exact complete
  root-shape proof or explicit syntax contract is selected.
- `2026-06-05`: Do not select a new backend-owned struct/record
  default-lowering implementation leaf from `.12`. The closed struct-lowering
  audit, current book boundary, and focused regressions already cover exact
  contract-backed Verilog-family typedef surfaces; broader default lowering
  remains blocked until one exact value class has complete frontend and
  backend contracts.

## Open Questions

- None before the next evidence-selection leaf. Any VHDL aggregate or
  generic-map lowering code must first get an exact VHDL backend/composition
  owner under this tree or an existing narrower backend tree.

## Blockers

- VHDL aggregate and generic-map lowering remain blocked until the full VHDL
  backend/composition target is active enough to validate generated behavior.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- |
| `2026-06-05` | `COMPOSITION-TYPE-BACKLOG-EXHAUSTION.1` | `scripts/check_memory_architecture.sh`; `mdbook build docs/book`; `prove -Iperl t/1256-feature-backlog-status-audit.t t/1414-docs-relative-paths-audit.t`; `bash knowledge-map/scripts/check_knowledge_map.sh`; `git diff --check` | `passed` |
| `2026-06-05` | `COMPOSITION-TYPE-BACKLOG-EXHAUSTION.2` | `scripts/check_memory_architecture.sh`; `mdbook build docs/book`; `prove -Iperl t/1256-feature-backlog-status-audit.t t/1414-docs-relative-paths-audit.t`; `bash knowledge-map/scripts/check_knowledge_map.sh`; `git diff --check` | `passed` |
| `2026-06-05` | `COMPOSITION-TYPE-BACKLOG-EXHAUSTION.11` | `prove -Iperl t/30-language-contract-symbol-definitions.t t/51-language-contract-symbol-definition-boundary.t t/88-rtlif-typed-port-contract.t t/91-composition-multi-rtl-children.t t/248-regression-corpus-accounting.t t/261-regression-corpus-supported-language-features.t t/292-composition-generated-child-parameter-overrides.t`; `scripts/check_memory_architecture.sh`; `mdbook build docs/book`; `prove -Iperl t/1256-feature-backlog-status-audit.t t/1414-docs-relative-paths-audit.t`; `bash knowledge-map/scripts/check_knowledge_map.sh`; `git diff --check` | `passed` |
| `2026-06-05` | `COMPOSITION-TYPE-BACKLOG-EXHAUSTION.3` | `prove -Iperl t/139-composition-shared-datapath-candidate-metadata.t t/140-composition-shared-datapath-drive-intent-metadata.t t/141-composition-shared-datapath-aggregate-enable-metadata.t t/142-composition-shared-datapath-assertion-metadata.t t/143-composition-shared-datapath-visibility-metadata.t t/144-composition-shared-datapath-combinational-peer-read-policy.t t/145-composition-shared-datapath-runtime-hdl.t t/146-composition-shared-datapath-lifted-register-runtime.t t/147-composition-shared-datapath-internal-lifted-register-runtime.t t/148-composition-shared-datapath-mixed-reexport-runtime.t t/149-composition-shared-datapath-combinational-runtime.t t/150-composition-shared-datapath-combinational-internal-runtime.t t/151-composition-shared-datapath-assertion-runtime-hdl.t t/152-composition-shared-datapath-public-fanout-register-runtime.t t/153-composition-shared-datapath-combinational-public-fanout-runtime.t t/159-composition-shared-datapath-forward-ir-exports.t t/178-composition-shared-datapath-support.t t/183-composition-shared-datapath-candidate-builder.t`; `scripts/check_memory_architecture.sh`; `mdbook build docs/book`; `prove -Iperl t/1256-feature-backlog-status-audit.t t/1414-docs-relative-paths-audit.t`; `bash knowledge-map/scripts/check_knowledge_map.sh`; `git diff --check` | `passed` |
| `2026-06-05` | `COMPOSITION-TYPE-BACKLOG-EXHAUSTION.4` | `prove -Iperl t/48-language-contract-standalone-dt-classification.t t/82-standalone-dt-root-support.t t/83-reusable-source-path-resolution.t t/85-composition-standalone-dt-children.t t/86-composition-single-child-connect-by-name.t t/130-composition-generated-child-source-shape-diagnostics.t t/133-standalone-dt-root-aliases.t t/134-standalone-dt-explicit-system-support.t t/135-composition-generated-child-default-source-names.t t/136-standalone-dt-enable-family-metadata.t t/137-standalone-dt-multi-drive-family-metadata.t t/138-composition-standalone-dt-export-metadata.t t/154-standalone-dt-assertion-runtime-hdl.t t/157-composition-standalone-dt-forward-ir-exports.t t/171-forward-lowered-rtl-ir-standalone-dt-target-helpers.t t/292-composition-generated-child-parameter-overrides.t`; `scripts/check_memory_architecture.sh`; `mdbook build docs/book`; `prove -Iperl t/1256-feature-backlog-status-audit.t t/1414-docs-relative-paths-audit.t`; `bash knowledge-map/scripts/check_knowledge_map.sh`; `git diff --check` | `passed` |
| `2026-06-05` | `COMPOSITION-TYPE-BACKLOG-EXHAUSTION.5` | `prove -Iperl t/24-composition-connect-by-name.t t/86-composition-single-child-connect-by-name.t t/87-composition-mixed-connect-by-name.t t/92-composition-multi-rtl-connect-by-name.t t/94-composition-multi-generated-plus-rtl-connect-by-name.t t/95-composition-connect-by-name-input-fanout.t t/96-composition-implicit-single-child-ports.t t/97-composition-implicit-multi-child-inputs.t t/98-composition-implicit-multi-child-outputs.t t/99-composition-implicit-internal-carriers.t t/100-composition-internal-carrier-top-reexport.t t/101-composition-explicit-link-implicit-ports.t t/102-composition-explicit-port-convention.t t/103-composition-provenance-metadata.t t/104-composition-provenance-reporting.t t/105-composition-override-reporting.t t/106-composition-blocked-reporting.t t/160-composition-top-forward-ir-surface.t t/162-composition-top-structural-rtl-ir-surface.t`; `scripts/check_memory_architecture.sh`; `mdbook build docs/book`; `prove -Iperl t/1256-feature-backlog-status-audit.t t/1414-docs-relative-paths-audit.t`; `bash knowledge-map/scripts/check_knowledge_map.sh`; `git diff --check` | `passed` |
| `2026-06-05` | `COMPOSITION-TYPE-BACKLOG-EXHAUSTION.6` | `prove -Iperl t/1216-isf-generated-composition-top.t t/1217-isf-generated-composition-schedule-report.t t/1215-isf-spawn-parameter-binding.t t/1248-isf-rule-trigger-parameter-binding.t t/1255-isf-schedule-report-golden-matrix.t t/292-composition-generated-child-parameter-overrides.t`; `scripts/check_memory_architecture.sh`; `mdbook build docs/book`; `prove -Iperl t/1256-feature-backlog-status-audit.t t/1414-docs-relative-paths-audit.t`; `bash knowledge-map/scripts/check_knowledge_map.sh`; `git diff --check` | `passed` |
| `2026-06-05` | `COMPOSITION-TYPE-BACKLOG-EXHAUSTION.7` | `prove -Iperl t/1215-isf-spawn-parameter-binding.t t/1248-isf-rule-trigger-parameter-binding.t t/1241-isf-transaction-port-bindings.t t/1242-isf-port-binding-conflict-semantics.t t/1243-isf-port-binding-schedule-report.t t/1195-isf-sample-clause-boundary.t t/1181-isf-rule-action-boundary.t t/1351-isf-activation-param-package-constants.t t/1369-isf-timing-param-activation-override-gates.t t/1370-isf-data-op-activation-override-width-gate.t t/1371-isf-transaction-port-activation-override-width-gate.t`; `scripts/check_memory_architecture.sh`; `mdbook build docs/book`; `prove -Iperl t/1256-feature-backlog-status-audit.t t/1414-docs-relative-paths-audit.t`; `bash knowledge-map/scripts/check_knowledge_map.sh`; `git diff --check` | `passed` |
| `2026-06-05` | `COMPOSITION-TYPE-BACKLOG-EXHAUSTION.8` | `prove -Iperl t/1215-isf-spawn-parameter-binding.t t/1304-isf-repeat-body-doc-truth-audit.t t/1305-isf-book-feature-matrix-audit.t t/1307-isf-loop-body-doc-truth-audit.t t/1376-isf-book-example-lowering-audit.t t/1379-isf-loop-contained-repeat-body-local-do.t t/1380-isf-loop-contained-repeat-body-generated-do.t t/1381-isf-deeper-nested-repeat-body-local-do.t t/1382-isf-deeper-nested-repeat-body-generated-do.t t/1383-isf-loop-and-deeper-repeat-body-spawn.t t/1384-isf-loop-and-deeper-repeat-body-multi-pending-awaitany.t t/1387-isf-cross-domain-activation-handshake-lowering.t`; `scripts/check_memory_architecture.sh`; `mdbook build docs/book`; `prove -Iperl t/1256-feature-backlog-status-audit.t t/1414-docs-relative-paths-audit.t`; `bash knowledge-map/scripts/check_knowledge_map.sh`; `git diff --check` | `passed` |
| `2026-06-05` | `COMPOSITION-TYPE-BACKLOG-EXHAUSTION.9` | `prove -Iperl t/279-declarative-scalar-types.t t/280-declarative-aggregate-types.t t/281-structural-declared-type-contracts.t t/282-composition-aggregate-source-expression-contracts.t t/283-composition-aggregate-path-support.t t/284-package-aggregate-path-support.t t/285-aggregate-expression-type-support.t t/288-composition-aggregate-top-expression-inference.t t/277-direct-symbol-contract-forward-ir.t t/278-composition-symbol-contract-forward-ir.t t/1333-direct-structural-rtl-ir-projection.t t/114-composition-target-support-diagnostics.t t/386-hdl-generator-facade-target-language-boundary-audit.t t/1378-isf-enum-type-relationship.t t/1257-isf-scalar-type-aliases.t t/1259-isf-aggregate-storage-type-aliases.t t/1260-isf-aggregate-storage-leaf-reads.t t/1261-isf-aggregate-storage-leaf-writes.t t/1262-isf-aggregate-storage-leaf-expression-reads.t`; `scripts/check_memory_architecture.sh`; `mdbook build docs/book`; `prove -Iperl t/1256-feature-backlog-status-audit.t t/1414-docs-relative-paths-audit.t`; `bash knowledge-map/scripts/check_knowledge_map.sh`; `git diff --check` | `passed` |
| `2026-06-05` | `COMPOSITION-TYPE-BACKLOG-EXHAUSTION.10` | `prove -Iperl t/276-direct-local-aggregate-values.t t/280-declarative-aggregate-types.t t/282-composition-aggregate-source-expression-contracts.t t/288-composition-aggregate-top-expression-inference.t t/1321-direct-aggregate-autogrowth.t`; `scripts/check_memory_architecture.sh`; `mdbook build docs/book`; `prove -Iperl t/1256-feature-backlog-status-audit.t t/1414-docs-relative-paths-audit.t`; `bash knowledge-map/scripts/check_knowledge_map.sh`; `git diff --check` | `passed` |
| `2026-06-05` | `COMPOSITION-TYPE-BACKLOG-EXHAUSTION.12` | `prove -Iperl t/198-systemverilog-scaffold-emitter.t t/204-enable-graph-module-planning-support.t t/280-declarative-aggregate-types.t t/167-structural-connection-expr-helpers.t t/282-composition-aggregate-source-expression-contracts.t t/1259-isf-aggregate-storage-type-aliases.t t/1321-direct-aggregate-autogrowth.t`; `scripts/check_memory_architecture.sh`; `mdbook build docs/book`; `prove -Iperl t/1256-feature-backlog-status-audit.t t/1414-docs-relative-paths-audit.t`; `bash knowledge-map/scripts/check_knowledge_map.sh`; `git diff --check` | `passed` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `COMPOSITION-TYPE-BACKLOG-EXHAUSTION.1` | `PROJECT-REMAINING-WORK-TASKTREE-OWNERSHIP.1: track remaining backlog owners` | `activated by the remaining-work ownership slice` |
| `COMPOSITION-TYPE-BACKLOG-EXHAUSTION.2` | `COMPOSITION-TYPE-BACKLOG-EXHAUSTION.2: select aggregate equality leaf` | `selected .11 as the first executable Composition/type implementation leaf` |
| `COMPOSITION-TYPE-BACKLOG-EXHAUSTION.11` | `COMPOSITION-TYPE-BACKLOG-EXHAUSTION.11: implement aggregate comparison operators` | `shipped binary matching-shape aggregate equality/inequality for semantic parameter/generic values; next frontier .3` |
| `COMPOSITION-TYPE-BACKLOG-EXHAUSTION.3` | `COMPOSITION-TYPE-BACKLOG-EXHAUSTION.3: defer shared-datapath widening` | `closed shared-datapath selection as prerequisite-bound deferral; next frontier .4` |
| `COMPOSITION-TYPE-BACKLOG-EXHAUSTION.4` | `COMPOSITION-TYPE-BACKLOG-EXHAUSTION.4: defer reusable-module widening` | `closed reusable standalone-DT selection as prerequisite-bound deferral; next frontier .5` |
| `COMPOSITION-TYPE-BACKLOG-EXHAUSTION.5` | `COMPOSITION-TYPE-BACKLOG-EXHAUSTION.5: defer top-boundary widening` | `closed top-boundary convention selection as prerequisite-bound deferral; next frontier .6` |
| `COMPOSITION-TYPE-BACKLOG-EXHAUSTION.6` | `COMPOSITION-TYPE-BACKLOG-EXHAUSTION.6: defer generated-child top widening` | `closed generated-child top selection as prerequisite-bound deferral; next frontier .7` |
| `COMPOSITION-TYPE-BACKLOG-EXHAUSTION.7` | `COMPOSITION-TYPE-BACKLOG-EXHAUSTION.7: defer activation binding widening` | `closed activation parameter/value-binding selection as prerequisite-bound deferral; next frontier .8` |
| `COMPOSITION-TYPE-BACKLOG-EXHAUSTION.8` | `COMPOSITION-TYPE-BACKLOG-EXHAUSTION.8: defer repeat activation widening` | `closed repeat-body child-activation selection as prerequisite-bound deferral; synced stale book wording; next frontier .9` |
| `COMPOSITION-TYPE-BACKLOG-EXHAUSTION.9` | `COMPOSITION-TYPE-BACKLOG-EXHAUSTION.9: defer portable type-core widening` | `closed portable type-core selection as prerequisite-bound deferral; next frontier .10` |
| `COMPOSITION-TYPE-BACKLOG-EXHAUSTION.10` | `COMPOSITION-TYPE-BACKLOG-EXHAUSTION.10: defer member autogrowth` | `closed aggregate member/index autogrowth selection as prerequisite-bound deferral; next frontier .12` |
| `COMPOSITION-TYPE-BACKLOG-EXHAUSTION.12` | `COMPOSITION-TYPE-BACKLOG-EXHAUSTION.12: defer struct default lowering` | `closed backend-owned struct/record selection as prerequisite-bound deferral; next frontier .13` |

## Changelog

- `2026-06-05`: Created active Composition/type backlog exhaustion tree.
- `2026-06-05`: Selected binary semantic parameter/generic aggregate equality
  and inequality as the first executable Composition/type implementation leaf.
- `2026-06-05`: Shipped binary semantic parameter/generic aggregate equality
  and inequality and advanced the frontier to shared-datapath evidence
  selection.
- `2026-06-05`: Closed shared-datapath selection as an explicit prerequisite
  deferral and advanced the frontier to reusable standalone-DT evidence
  selection.
- `2026-06-05`: Closed reusable standalone-DT selection as an explicit
  prerequisite deferral and advanced the frontier to top-boundary convention
  evidence selection.
- `2026-06-05`: Closed top-boundary convention selection as an explicit
  prerequisite deferral and advanced the frontier to generated-child
  top-instantiation evidence selection.
- `2026-06-05`: Closed generated-child top selection as an explicit
  prerequisite deferral and advanced the frontier to spawn/blocking-do
  parameter and value-binding evidence selection.
- `2026-06-05`: Closed activation parameter/value-binding selection as an
  explicit prerequisite deferral and advanced the frontier to repeat-body
  child-activation evidence selection.
- `2026-06-05`: Closed repeat-body child-activation selection as an explicit
  prerequisite deferral, synced stale book wording for cross-domain activation
  and loop/deeper repeat-spawn status, and advanced the frontier to portable
  type-core evidence selection.
- `2026-06-05`: Closed portable type-core selection as an explicit
  prerequisite deferral and advanced the frontier to aggregate member/index
  autogrowth evidence selection.
- `2026-06-05`: Closed aggregate member/index autogrowth selection as an
  explicit prerequisite deferral and advanced the frontier to backend-owned
  struct/record default-lowering evidence selection.
- `2026-06-05`: Closed backend-owned struct/record default-lowering selection
  as an explicit prerequisite deferral and advanced the frontier to VHDL
  aggregate/generic-map prerequisite tracking.
