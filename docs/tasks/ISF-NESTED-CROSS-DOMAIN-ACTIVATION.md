# ISF-NESTED-CROSS-DOMAIN-ACTIVATION: Cross-Domain `(do)` Inside `when` / `switch` / `repeat` Bodies

## Metadata

- Tree ID: `ISF-NESTED-CROSS-DOMAIN-ACTIVATION`
- Status: `done`
- Roadmap lane: `R14` (ISF Multi-Clock And CDC Semantics — richer crossing primitives)
- Created: `2026-05-31`
- Last updated: `2026-06-05`
- Owner: repo-local workflow

## Goal

Extend cross-domain blocking `(do child)` through a declared
`(crossings (activation child (from SRC)(to DST)))` from the shipped **top-level**
case to **nested** control-flow contexts — a `(do child)` inside a `when` body, a
`switch` branch, or a `repeat` body — reusing the dual-CDC activation routing.

This is a direct follow-up to `ISF-CROSS-DOMAIN-ACTIVATION-VIA-CROSSING` (which
shipped the top-level case end-to-end: parse → validate → dual-CDC lowering → HDL
→ book example → schedule report).

## Ground truth (investigated `2026-05-31`)

- The activation-crossing infrastructure exists and is correct for a top-level
  `(do child)`: `_validate_transaction_clause_domain_refs` accepts a covered
  cross-domain `(do)` (`_activation_crossing_covers`), `_domain_actor_for_scheduled_artifact`
  injects `external_activations`, and `_wire_external_activations`
  (LoweringIR.pm) promotes the handshake to per-domain module ports with the
  await-ready + one-cycle pulse on both the caller and callee, routed through two
  CDC children in `_emit_multi_domain_top`.
- Two restrictions currently scope it to the top level:
  1. The validator relaxation is gated on `($label // '') eq 'transaction body'`
     (LoweringIR.pm, the do/spawn branch of `_validate_transaction_clause_domain_refs`).
  2. The partition's "crossing owns a real activation" check
     (`_build_domain_partition`) only counts a covering `(do child)` whose
     `$ref->{label} eq 'transaction body'`.
- Net effect today: a nested cross-domain `(do worker)` (e.g. inside a `(when
  cond ...)`) fails closed — but with a **misleading** diagnostic: `ISF
  activation crossing for child 'worker' (domain 'core' -> 'bus') is declared but
  no transaction in domain 'core' performs a top-level '(do worker)'`. The
  crossing IS used; it is just used in a nested context, which is not yet
  supported. The message reads as "unused" rather than "nested-use deferred".

## Design

- `.1` select (this doc).
- `.2` (safe, bounded) — **precise deferred diagnostic**: when an activation
  crossing has no covering *top-level* `(do child)` but the source domain DOES
  perform a *nested* `(do child)`, fail closed with an accurate message
  (`... performs a nested '(do worker)' inside a when/switch/repeat body, but
  cross-domain activation is currently supported only for a top-level '(do)';
  nested cross-domain activation remains deferred`), distinct from the
  genuinely-unused case. Mirrors the project's targeted-rejection-diagnostic
  pattern. Lock with a `t/138x` diagnostic test; both the unused and the
  nested-deferred messages asserted.
- `.3`+ (the substantial work) — **support** nested cross-domain `(do)`. Scope
  finding from the `.3` design (investigated `2026-05-31`), see Decisions:

  - `do`/`spawn` are supported clause keywords ONLY in the `transaction`
    (top-level) and `repeat` contexts (`%SUPPORTED_TRANSACTION_CLAUSES`). A plain
    `(do)` directly in a `when`/`switch`/`while`/`until` body is unsupported **even
    same-domain** (rejected at `_validate_supported_transaction_clauses`). So
    "nested `(do)`" means "inside a `repeat` body" (a top-level repeat, or a repeat
    nested in a when/switch/while/until). Plain when/switch/while/until-body
    cross-domain `(do)` is therefore N/A for this tree (it would require a
    same-domain when/switch-body `(do)` feature first — a separate lane); `.2`
    already defers it accurately.
  - So `.3`+ = **cross-domain REPEAT-BODY `(do worker)`** (the local/sibling model
    the activation crossing covers), routed through the crossing's two CDC children
    per loop iteration. A blocking repeat-body `(do)` blocks each iteration until
    `done`, so it is single-outstanding per iteration → the shipped await-`ready` +
    one-cycle-`<start>` + dual-CDC handshake applies per iteration, and the DEST
    worker returns to idle between iterations (callee terminal → idle), ready for
    the next `<start>` pulse.
  - Caller restructure feasibility: `_wire_external_activations` (caller) finds the
    await-state asserting `<start>` and inserts `await <start>_ready` → one-cycle
    `<start>` before it, redirecting predecessors. Inside a `repeat` region the
    do-state's predecessor is the loop entry and the `repeat_check` loops back to
    the do-state; the existing "redirect all transitions targeting the do-state
    (except from the request state) to the ready-await" rule would ALSO redirect
    the `repeat_check` loop-back to the ready-await — exactly right (each iteration
    re-runs the full handshake). So the restructure likely applies in the repeat
    region with little/no change — to be verified empirically in the first
    implementation sub-slice.
  - Gate-lifting: the validator relaxation (currently `$label eq 'transaction
    body'`) and the partition deferral (`_activation_do_use_context` nested →
    confess) must be lifted for the `repeat` body context specifically, while
    keeping plain when/switch/while/until-body `(do)` deferred.
  - Sub-slices (mirroring the same-domain repeat-body frontier), each with a golden
    `.fsm` + HDL evidence: `.3` top-level repeat-body; `.4` when→repeat;
    `.5` switch→repeat; `.6` while/until→repeat; `.7` deeper-nested
    (`when⁺→repeat`, `switch→when⁺→repeat`). Consolidate if the restructure
    generalizes across contexts.

  > **SUPERSEDED (`2026-06-01`):** the premise above — that a plain `(do)` in a
  > `when`/`switch`/`while`/`until` body is "unsupported even same-domain" and
  > therefore N/A — was invalidated when `ISF-CONDITIONAL-CHILD-ACTIVATION` (theme
  > #1) shipped same-domain branch-body `(do)` and closed. The actual shipped
  > frontier is therefore: `.3` top-level **repeat** body, `.4` top-level **branch/
  > loop** body (`when`/`switch`/`while`/`until`), and `.5`+ multi-level nesting. See
  > the Decisions and Changelog entries dated `2026-06-01` and the Current Frontier
  > table, which carry the authoritative current scope.

## Non-Goals

- Cross-domain `(spawn)` (non-blocking) — a separate tree (different drain
  semantics).
- Data-payload crossings.
- Auto-generation of a crossing without an explicit declaration.

## Acceptance Criteria

- `.2`: a nested cross-domain `(do)` covered by a declared crossing fails closed
  with an accurate "nested cross-domain activation remains deferred" diagnostic,
  distinct from the declared-but-unused message; locked by a focused test;
  top-level cross-domain activation and all existing behavior unchanged.
- `.3`+: nested cross-domain `(do)` lowers end-to-end through the dual-CDC routing
  for the supported contexts, with goldens + HDL evidence; unsupported deeper
  nestings still fail closed with accurate diagnostics.
- Each leaf committed via `COMMIT.md`.

## Task Tree

- ID: `ISF-NESTED-CROSS-DOMAIN-ACTIVATION`
  Status: `done`
  Goal: `Cross-domain blocking (do child) inside when/switch/repeat bodies via the activation crossing.`
  Children: `.1` (select), `.2` (precise nested-deferred diagnostic), `.3` (top-level repeat), `.4` (top-level branch/loop), `.5` (split deeper-nesting frontier), `.6` (branch-contained repeat), `.7` (nested when), `.8` (repeat-contained branch deferral), `.9` (nested when-repeat), `.10` (exhaustion audit / close)

- ID: `ISF-NESTED-CROSS-DOMAIN-ACTIVATION.1`
  Status: `done`
  Goal: `Select; record ground truth (top-level-only gates + misleading nested diagnostic) + design + slice plan.`
  Acceptance: `Task tree committed before any code change.`
  Verification: `mdbook build docs/book; git diff --check`
  Commit: `2c081347`

- ID: `ISF-NESTED-CROSS-DOMAIN-ACTIVATION.2`
  Status: `done`
  Goal: `Precise nested-deferred diagnostic — distinguish a nested (do child) use from a genuinely-unused crossing.`
  Acceptance: `A nested cross-domain (do child) (inside when/switch/repeat/while/until) fails closed with "used by a nested (do child) (inside a <ctx>) ... nested cross-domain activation remains deferred", distinct from the declared-but-unused message; the top-level case still lowers; genuinely-unused still says "declared but ... no top-level (do)"; locked by t/1387.`
  Verification: `prove -Iperl t/1387 (9 subtests) t/1386 t/1247 t/1372 t/1374 t/1375 t/1250 t/1305 t/1382 t/1383 t/1110 (11 files, 451) PASS; full ./bin/ci-regression isf --no-book PASS; perl -c; git diff --check`
  Commit: `be4fa262`

- ID: `ISF-NESTED-CROSS-DOMAIN-ACTIVATION.3`
  Status: `done`
  Goal: `Support a cross-domain (do child) directly inside a TOP-LEVEL repeat body — the first supported nested cross-domain context — routed through the dual-CDC per iteration.`
  Acceptance: `The two gates are lifted for the top-level repeat case only: (1) the per-clause validator accepts a covered cross-domain (do) at label 'repeat body' (not just 'transaction body'); (2) the partition's _activation_do_use_context distinguishes a (do child) directly inside a TOP-LEVEL repeat (new top_level_repeat flag) from deeper nesting, and the partition treats top_level_repeat as covered. The caller restructure (_wire_external_activations) applies UNCHANGED in the repeat region: the repeat_init->do edge is redirected to the ready-await, the do-state splits into ready->req->await-done, and the repeat_check loop-back re-runs the full handshake each iteration; the callee returns to idle between iterations. Deeper nestings (when/switch/while/until body, or a repeat nested in another body) still fail closed with the (refined) nested-deferred diagnostic. The top-level (non-repeat) case is unchanged. End-to-end --check-json SUCCEEDS (no composition-scope boundary). 13a/13d/13k updated; t/1387 gains a positive subtest + repoints its 'repeat body' deferral case to a when->repeat.`
  Verification: `Empirical spike: top-level (repeat 2 (do worker)) lowers to 3 domain files; caller restructured to parent_do_N_ready->_req->await-done inside the repeat loop; callee worker_idle_ext gated on start, pulses done, returns to idle; --check-json SUCCEEDS. Deferral preserved for when-body / switch->repeat / when->repeat. prove -Iperl t/1387 (10 subtests) t/1386 t/1247 t/1304 t/1307 t/1305 t/1376 t/1303 PASS; full ./bin/ci-regression isf --no-book PASS; perl -c; mdbook build; git diff --check`
  Commit: `def2156b`

- ID: `ISF-NESTED-CROSS-DOMAIN-ACTIVATION.4`
  Status: `done`
  Goal: `Support a cross-domain (do child) directly inside any TOP-LEVEL branch/loop body (when/switch/while/until) — newly unblocked by ISF-CONDITIONAL-CHILD-ACTIVATION shipping the same-domain branch-body (do).`
  Acceptance: `Validator accepts a covered cross-domain (do) at the branch-body labels (when body / switch branch / while body / until body); _activation_do_use_context gains a top_level_branch_body flag (a (do child) whose immediate container is a when/switch/while/until that is itself a direct transaction clause), and the partition treats it as covered (alongside top_level / top_level_repeat). The caller restructure (_wire_external_activations) now redirects branch/loop ENTRY references to the do-state — a 'branch' state's true_target, a 'switch' branch's body_start, and a loop's loop_body_start — into the inserted ready-await (previously it only redirected transitions[].target, which caught plain predecessors + while/until loop edges but MISSED the when/switch selector, leaving the start handshake unreachable). All four contexts then lower correctly AND --check-json SUCCEEDS. Deeper nestings (container nested in another body) still fail closed (diagnostic refined to name the branch-body supported contexts). t/1387 gains a positive branch-body subtest + repoints its when/switch deferral cases to deeper (when->when / switch->switch) forms.`
  Verification: `Empirical spike: when/switch/while/until top-level branch-body cross-domain (do) all lower (ready-await reachable, one-cycle start, done block) and --check-json SUCCEEDS (with clean fixtures declaring only used signals). when->when / switch->switch / when->repeat still defer. prove -Iperl t/1387 (11 subtests) t/1386 t/1247 t/1304 t/1307 t/1305 t/1376 t/1303 PASS; full ./bin/ci-regression isf --no-book PASS; perl -c; mdbook build; git diff --check`
  Commit: `ship commit (this slice)`

- ID: `ISF-NESTED-CROSS-DOMAIN-ACTIVATION.5`
  Status: `done`
  Goal: `Split the bundled deeper-nesting frontier into exact executable leaves before any new implementation.`
  Acceptance: `The prior .5-.7 frontier is no longer a broad bundle. The next executable leaf is .6: a cross-domain (do child) directly inside a repeat nested in a top-level when body or top-level switch branch, routed through the declared activation crossing. Remaining multi-level nesting stays explicit backlog. No code or user-facing behavior change is made in this split slice.`
  Verification: `passed: memory architecture, Knowledge Map, mdBook build, relative-path audit, and diff checks`
  Commit: `ISF-NESTED-CROSS-DOMAIN-ACTIVATION.5: split deeper nesting frontier`

- ID: `ISF-NESTED-CROSS-DOMAIN-ACTIVATION.6`
  Status: `done`
  Goal: `Support a cross-domain (do child) directly inside a repeat nested in a TOP-LEVEL when body or TOP-LEVEL switch branch.`
  Acceptance: `A declared activation crossing covers (when GUARD (repeat N (do child))) and (switch SEL (CASE (repeat N (do child)))) when the parent transaction is in the source domain and child is in the destination domain. The validator remains unchanged unless evidence shows a narrower gate is needed; the partition classification gains an exact top-level branch-contained repeat context and treats it as covered. The caller module reruns await-start-ready -> one-cycle start -> await-done on each nested-repeat iteration, and the callee returns to start-gated idle between iterations. Existing top-level, top-level-repeat, and top-level-branch/loop cases remain unchanged. Deeper branch->branch, repeat->branch, nested while/until, and deeper branch-repeat combinations still fail closed with an accurate deferred diagnostic. t/1387 gains positive when->repeat and switch->repeat coverage and preserves the deferred cases for the remaining contexts.`
  Verification: `passed: t/1387 (12 subtests), focused ISF cross-domain/control-flow sweep, full ISF no-book regression, perl -c, memory architecture, Knowledge Map, mdBook build, relative-path audit, and diff checks`
  Commit: `ISF-NESTED-CROSS-DOMAIN-ACTIVATION.6: branch-contained repeat cross-domain do`

- ID: `ISF-NESTED-CROSS-DOMAIN-ACTIVATION.7`
  Status: `done`
  Goal: `Support a cross-domain (do child) directly inside a when body reached through one or more branch ancestors.`
  Acceptance: `A declared activation crossing covers (when A (when B (do child))) and (switch SEL (CASE (when B (do child)))) when the parent transaction is in the source domain and child is in the destination domain. The partition classification gains an exact branch-contained-when context for a direct (do child) inside a when body whose when is nested under a top-level when body or switch branch, including longer when-chains that stay within supported nested-control syntax. The caller module redirects the inner branch entry to await-start-ready, pulses start for one cycle, waits for done, and resumes the nested branch exit path. Existing top-level, top-level-repeat, top-level-branch/loop, and branch-contained-repeat cases remain unchanged. Nested switch bodies, repeat->branch, nested while/until, and deeper branch-repeat combinations still fail closed with accurate diagnostics. t/1387 gains positive when->when and switch->when coverage and preserves deferred nested-switch / repeat-body cases.`
  Verification: `passed: t/1387 (13 subtests), focused ISF cross-domain/control-flow sweep, full ISF no-book regression, perl -c, memory architecture, Knowledge Map, mdBook build, relative-path audit, and diff checks`
  Commit: `ISF-NESTED-CROSS-DOMAIN-ACTIVATION.7: nested when cross-domain do`

- ID: `ISF-NESTED-CROSS-DOMAIN-ACTIVATION.8`
  Status: `done`
  Goal: `Support or explicitly close repeat->branch cross-domain (do) contexts.`
  Acceptance: `Closed without behavior change: repeat-body branch contexts are not a cross-domain activation lift because the repeat-body same-domain allow-list does not include when/switch branch clauses. Support requires a separate same-domain repeat-body branch owner before any cross-domain activation crossing can be considered. Existing fail-closed diagnostics and mdBook non-claims remain accurate.`
  Verification: `passed: repeat-body allow-list audit, t/1387, memory architecture, Knowledge Map, mdBook build, relative-path audit, and diff checks`
  Commit: `ISF-NESTED-CROSS-DOMAIN-ACTIVATION.8: defer repeat-contained branch contexts`

- ID: `ISF-NESTED-CROSS-DOMAIN-ACTIVATION.9`
  Status: `done`
  Goal: `Support a cross-domain (do child) directly inside a repeat nested under a supported nested when-chain.`
  Acceptance: `A declared activation crossing covers (when A (when B (repeat N (do child)))) and (switch SEL (CASE (when B (repeat N (do child))))) when the parent transaction is in the source domain and child is in the destination domain. The partition classification gains an exact branch-contained-when-repeat context for a direct (do child) in a repeat body whose repeat is nested under a supported branch-contained when-chain. The caller module reruns await-start-ready -> one-cycle start -> await-done on each nested-repeat iteration, and the callee returns to start-gated idle between iterations. Existing top-level, top-level-repeat, top-level-branch/loop, branch-contained-repeat, and branch-contained-when cases remain unchanged. Nested switch bodies, repeat->branch, nested while/until, and unsupported deeper placements remain fail-closed with accurate diagnostics. t/1387 gains positive when-chain->repeat and switch->when->repeat coverage and preserves the deferred cases for the remaining contexts.`
  Verification: `passed: t/1387 (14 subtests), focused ISF cross-domain/control-flow sweep, full ISF no-book regression, perl -c, memory architecture, Knowledge Map, mdBook build, relative-path audit, and diff checks`
  Commit: `ISF-NESTED-CROSS-DOMAIN-ACTIVATION.9: nested when-repeat cross-domain do`

- ID: `ISF-NESTED-CROSS-DOMAIN-ACTIVATION.10`
  Status: `done`
  Goal: `Audit remaining deeper combinations and close the tree or create new exact owner leaves.`
  Acceptance: `No broad bundled frontier remains; residual unsupported contexts are either shipped, accurately deferred in code/book, or routed to new task-tree-owned leaves.`
  Verification: `passed: residual-context audit, t/1387, memory architecture, Knowledge Map, mdBook build, relative-path audit, and diff checks`
  Commit: `ISF-NESTED-CROSS-DOMAIN-ACTIVATION.10: close nested cross-domain activation tree`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `.1` | `done` | Selection/design (`2c081347`). |
| 2 | `.2` | `done` | Precise nested-deferred diagnostic shipped (`_activation_do_use_context` recursive scan; `t/1387` covers when/switch/repeat + the genuinely-unused case). |
| 3 | `.3` | `done` | Top-level repeat-body cross-domain `(do worker)` LOWERS through the dual-CDC per iteration. Lifted the validator (`repeat body` label) + partition (`top_level_repeat` flag → covered); the caller restructure applied UNCHANGED in the repeat region; `--check-json` SUCCEEDS. Deeper nestings still fail closed (refined diagnostic). `t/1387` (+positive subtest). |
| 4 | `.4` | `done` | Cross-domain `(do)` directly inside any TOP-LEVEL branch/loop body (`when`/`switch`/`while`/`until`) LOWERS through the dual-CDC. Lifted the validator (branch-body labels) + partition (`top_level_branch_body` flag); **extended the caller restructure to redirect branch/loop ENTRY references** (`true_target` / `branches[].body_start` / `loop_body_start`) into the ready-await — the missing piece for when/switch (while/until already worked via `transitions[].target`). All four contexts `--check-json` SUCCEED. Deeper nestings still defer. `t/1387` (+positive subtest). |
| 5 | `.5` | `done` | Split the previously bundled `.5`-`.7` deeper-nesting frontier into exact executable leaves before any new implementation. |
| 6 | `.6` | `done` | Top-level `when`/`switch` branch-contained `repeat` with a cross-domain `(do child)` now lowers through the declared activation crossing; the existing ready/req/done restructure re-runs each nested-repeat iteration. |
| 7 | `.7` | `done` | Cross-domain `(do)` directly inside a supported inner `when` body reached from a top-level `when` or top-level `switch` branch now lowers through the declared activation crossing. |
| 8 | `.8` | `done` | Repeat-contained branch contexts closed without behavior change; repeat-body `when`/`switch` requires a same-domain owner before any cross-domain activation lift. |
| 9 | `.9` | `done` | Last same-domain-supported cross-domain candidate shipped: repeat nested under a supported nested `when` chain (`when+->repeat`, `switch->when+->repeat`). |
| 10 | `.10` | `done` | Exhaustion audit complete: the same-domain-supported blocking cross-domain `(do)` surface through an explicit activation crossing is shipped through all exact leaves in this tree. Residual cross-domain `(spawn)`, payload/auto-crossing work, nested `switch`, repeat-contained branch, nested `while`, nested `until`, and unsupported deeper placements stay fail-closed or prerequisite-bound and require new owner leaves before implementation. |
| 11 | `closed` | `done` | Tree complete; future CDC or prerequisite-control-flow expansion routes through a new exact task-tree owner (for broad CDC, `ISF-REMAINING-BROAD-FRONTIER.11`). |

## Decisions

- `2026-05-31`: split into a safe diagnostic-precision slice (`.2`) before the
  substantial support work (`.3`+), because the current fail-closed message for a
  nested cross-domain `(do)` is misleading (reports "unused" when it is
  nested-use-deferred), and an accurate diagnostic is independently valuable and
  low-risk.
- `2026-05-31` (`.3` design): scoped `.3`+ to **cross-domain repeat-body `(do)`
  only**. `%SUPPORTED_TRANSACTION_CLAUSES` allows `do`/`spawn` only in the
  `transaction` and `repeat` contexts, so a plain `(do)` in a when/switch/while/
  until body is unsupported even same-domain (confirmed: rejected at
  `_validate_supported_transaction_clauses` with "unsupported '(do ...)' clause in
  when body"). Supporting cross-domain plain when/switch-body `(do)` would require
  building same-domain support for it first — out of this tree (a separate lane).
  The viable nested-do context is the `repeat` body, and there the per-iteration
  single-outstanding blocking handshake fits the shipped dual-CDC handshake.
- `2026-06-01` (`.3` shipped — empirical confirmation): the caller restructure
  (`_wire_external_activations`) applied to the repeat region with ZERO change. The
  do-state is found by its `<start>` assertion regardless of position; the
  `repeat_init -> do` edge is redirected to the ready-await; the `repeat_check`
  loop-back already targets `repeat_init` (NOT the do-state), so it was untouched
  and naturally re-runs `init -> ready -> req -> await-done` each iteration. The
  callee terminal->idle chain returns `worker` to idle between iterations, ready for
  the next `<start>` pulse. Crucially `--check-json` SUCCEEDS — the dual-CDC
  composition is sound (no composition-scope boundary, unlike the same-domain
  generated-child / multi-instance-spawn cases). Restricted to a TOP-LEVEL repeat
  via a new `top_level_repeat` flag in `_activation_do_use_context` (the validator's
  `repeat body` label allowance is broader, but the partition gate keeps deeper
  repeats deferred — belt-and-suspenders).
- `2026-06-01` (`.4` re-scope): theme #1 (`ISF-CONDITIONAL-CHILD-ACTIVATION`) closed
  and now lowers same-domain `(do)`/`(spawn)` directly in all four branch/loop
  bodies. This INVALIDATES the `.3`-design premise that a branch-body `(do)` is N/A
  (unsupported even same-domain). So a covered cross-domain `(do)` directly in a
  `when`/`switch`/`while`/`until` body is now a viable supported context and becomes
  `.4` (ahead of the deeper repeat-nestings), reusing the same restructure.
- `2026-06-05` (`.5` split): the old `.5`-`.7` frontier was too broad for the
  task-tree gate. Split it before implementation. `.6` is the first exact deeper
  leaf and intentionally consolidates `when->repeat` and `switch->repeat`, because
  both are repeats directly inside one top-level branch container and should share
  one partition classification plus the already generalized caller restructure.
  Branch->branch, repeat->branch, and residual deeper combinations remain separate
  pending leaves.
- `2026-06-05` (`.6` shipped): only the partition classification needed to cover a
  `(do child)` directly inside a repeat nested in a top-level `when` body or
  top-level `switch` branch was lifted. The validator already allowed the
  crossing-covered `repeat body` label; `_activation_do_use_context` now reports a
  `top_level_branch_repeat` flag for this exact shape. The caller-side
  `_wire_external_activations` restructure needed no change: the nested repeat
  entry/check transitions now target the inserted ready-await, so each iteration
  re-runs await-start-ready -> one-cycle start -> await-done. Branch->branch,
  repeat->branch, nested while/until, and deeper branch-repeat combinations remain
  deferred.
- `2026-06-05` (`.7` shipped): direct cross-domain `(do child)` inside supported
  nested `when` chains now lowers through the explicit activation crossing. The
  partition classification gained a `top_level_branch_when` flag for `when` bodies
  nested under a top-level `when` body or top-level `switch` branch, propagating
  through longer `when` chains. Nested switch bodies, repeat-contained branch
  bodies, nested while/until, and deeper branch-repeat combinations remain
  deferred.
- `2026-06-05` (`.8` closed): repeat-contained branch contexts were not lifted.
  `%SUPPORTED_TRANSACTION_CLAUSES` does not include `when`/`switch` in the
  `repeat` context, so `(repeat ... (when ... (do child)))` is not an eligible
  cross-domain-only activation slice. It stays deferred behind a same-domain
  repeat-body branch owner.
- `2026-06-05` (`.9` shipped): a cross-domain `(do child)` directly inside a
  repeat under a supported nested `when` chain now lowers through the explicit
  activation crossing. `_activation_do_use_context` gained
  `top_level_branch_when_repeat`, leaving nested switches, repeat-contained
  branch bodies, nested while/until, and unsupported deeper placements deferred.
- `2026-06-05` (`.10` close): close this tree after all same-domain-supported
  blocking cross-domain `(do child)` placements through an explicit activation
  crossing are shipped or explicitly closed. Remaining contexts are not hidden
  work in this tree: cross-domain `(spawn)`, payload movement, and auto-crossing
  are separate CDC surfaces; repeat-contained branches require a same-domain
  repeat-body branch owner first; nested switch/while/until and unsupported
  deeper placements remain fail-closed/non-claimed until a new exact owner leaf is
  selected.

## Open Questions

- None for this tree. Future cross-domain activation expansion needs new
  task-tree ownership before implementation.

## Blockers

- None for this tree. Residual contexts are prerequisite-bound or out-of-scope
  for this owner.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-31` | `.1` | `mdbook build docs/book`; `git diff --check` | `PASS` |
| `2026-05-31` | `.2` | `prove -Iperl t/1387` (9 subtests) + clock-domain/crossing/diagnostic/spec-index/feature-matrix sweep (11 files, 451) PASS; full `./bin/ci-regression isf --no-book` PASS; `perl -c`; `git diff --check` | `PASS` |
| `2026-06-01` | `.3` | Empirical spike: `(repeat 2 (do worker))` cross-domain lowers to 3 domain files; caller restructured (`parent_do_N_ready->_req->await-done`) inside the repeat loop; callee gated on `<start>`, pulses `<done>`, returns to idle; `--check-json` **SUCCEEDS**. Deferral preserved (when-body / switch→repeat / when→repeat). `prove -Iperl t/1387` (10 subtests) `t/1386 t/1247 t/1304 t/1307 t/1305 t/1376 t/1303` PASS; full `./bin/ci-regression isf --no-book` PASS; `perl -c`; `mdbook build`; `git diff --check` | `PASS` |
| `2026-06-01` | `.4` | Empirical spike: when/switch/while/until top-level branch-body cross-domain `(do)` all lower (ready-await reachable, one-cycle start, done block) and `--check-json` **SUCCEEDS** (clean fixtures); when→when / switch→switch / when→repeat still defer. Restructure extended to redirect `true_target`/`branches[].body_start`/`loop_body_start` (the when/switch selector fix). `prove -Iperl t/1387` (11 subtests) `t/1386 t/1247 t/1304 t/1307 t/1305 t/1376 t/1303` PASS; full `./bin/ci-regression isf --no-book` PASS; `perl -c`; `mdbook build`; `git diff --check` | `PASS` |
| `2026-06-05` | `.5` | `scripts/check_memory_architecture.sh`; `bash knowledge-map/scripts/check_knowledge_map.sh`; `mdbook build docs/book`; `prove -Iperl t/1414-docs-relative-paths-audit.t`; `git diff --check` | `PASS` |
| `2026-06-05` | `.6` | Failing-first `prove -Iperl t/1387-isf-cross-domain-activation-handshake-lowering.t` confirmed old deferred diagnostic for `when->repeat` / `switch->repeat`; after lift: `prove -Iperl t/1387-isf-cross-domain-activation-handshake-lowering.t` (12 subtests) PASS; focused cross-domain/control-flow sweep PASS; full `./bin/ci-regression isf --no-book` PASS; `perl -c perl/FSM/Scheduler/ISF/LoweringIR.pm`; `scripts/check_memory_architecture.sh`; `bash knowledge-map/scripts/check_knowledge_map.sh`; `mdbook build docs/book`; `prove -Iperl t/1414-docs-relative-paths-audit.t`; `git diff --check` | `PASS` |
| `2026-06-05` | `.7` | Failing-first `prove -Iperl t/1387-isf-cross-domain-activation-handshake-lowering.t` confirmed old deferred diagnostic for `when->when`, `when->when->when`, and `switch->when`; after lift: `prove -Iperl t/1387-isf-cross-domain-activation-handshake-lowering.t` (13 subtests) PASS; focused cross-domain/control-flow sweep PASS; full `./bin/ci-regression isf --no-book` PASS; `perl -Iperl -c perl/FSM/Scheduler/ISF/LoweringIR.pm`; `scripts/check_memory_architecture.sh`; `bash knowledge-map/scripts/check_knowledge_map.sh`; `mdbook build docs/book`; `prove -Iperl t/1414-docs-relative-paths-audit.t`; `git diff --check` | `PASS` |
| `2026-06-05` | `.8` | `rg -n 'repeat =>' perl/FSM/Scheduler/ISF/LoweringIR.pm`; `prove -Iperl t/1387-isf-cross-domain-activation-handshake-lowering.t`; `scripts/check_memory_architecture.sh`; `bash knowledge-map/scripts/check_knowledge_map.sh`; `mdbook build docs/book`; `prove -Iperl t/1414-docs-relative-paths-audit.t`; `git diff --check` | `PASS` |
| `2026-06-05` | `.9` | Failing-first `prove -Iperl t/1387-isf-cross-domain-activation-handshake-lowering.t` confirmed old deferred diagnostic for `when->when->repeat`, `when->when->when->repeat`, and `switch->when->repeat`; after lift: `prove -Iperl t/1387-isf-cross-domain-activation-handshake-lowering.t` (14 subtests) PASS; focused cross-domain/control-flow sweep PASS; full `./bin/ci-regression isf --no-book` PASS; `perl -Iperl -c perl/FSM/Scheduler/ISF/LoweringIR.pm`; `scripts/check_memory_architecture.sh`; `bash knowledge-map/scripts/check_knowledge_map.sh`; `mdbook build docs/book`; `prove -Iperl t/1414-docs-relative-paths-audit.t`; `git diff --check` | `PASS` |
| `2026-06-05` | `.10` | Residual-context audit (`t/1387` deferred cases plus mdBook/spec non-claims); `prove -Iperl t/1387-isf-cross-domain-activation-handshake-lowering.t`; `scripts/check_memory_architecture.sh`; `bash knowledge-map/scripts/check_knowledge_map.sh`; `mdbook build docs/book`; `prove -Iperl t/1414-docs-relative-paths-audit.t`; `git diff --check` | `PASS` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `.1` | `ISF-NESTED-CROSS-DOMAIN-ACTIVATION.1: select nested cross-domain activation` | `2c081347` |
| `.2` | `ISF-NESTED-CROSS-DOMAIN-ACTIVATION.2: precise nested cross-domain (do) deferred diagnostic` | `be4fa262` |
| `.3` design | `ISF-NESTED-CROSS-DOMAIN-ACTIVATION.3 design: scope nested cross-domain (do) to repeat-body contexts` | `e8d44e8d` |
| `.3` | `ISF-NESTED-CROSS-DOMAIN-ACTIVATION.3: top-level repeat-body cross-domain (do) through dual-CDC` | `def2156b` |
| `.4` | `ISF-NESTED-CROSS-DOMAIN-ACTIVATION.4: top-level branch-body cross-domain (do) through dual-CDC` | `a86c31b9` |
| `.5` | `ISF-NESTED-CROSS-DOMAIN-ACTIVATION.5: split deeper nesting frontier` | `e595d8cc` |
| `.6` | `ISF-NESTED-CROSS-DOMAIN-ACTIVATION.6: branch-contained repeat cross-domain do` | `a23bab73` |
| `.7` | `ISF-NESTED-CROSS-DOMAIN-ACTIVATION.7: nested when cross-domain do` | `5de3da3c` |
| `.8` | `ISF-NESTED-CROSS-DOMAIN-ACTIVATION.8: defer repeat-contained branch contexts` | `9ed8efd5` |
| `.9` | `ISF-NESTED-CROSS-DOMAIN-ACTIVATION.9: nested when-repeat cross-domain do` | `3b6955d6` |
| `.10` | `ISF-NESTED-CROSS-DOMAIN-ACTIVATION.10: close nested cross-domain activation tree` | `close-out slice` |

## Changelog

- `2026-05-31`: Created as the direct follow-up to
  `ISF-CROSS-DOMAIN-ACTIVATION-VIA-CROSSING` (top-level cross-domain activation
  shipped). Recorded the two top-level-only gates, the misleading nested
  diagnostic, and the slice plan (`.2` precise diagnostic, `.3`+ nested support).
- `2026-05-31`: `.2` shipped. Added `_activation_do_use_context` (a recursive
  clause scan in `LoweringIR.pm`) that classifies a `(do child)` as top-level vs
  nested (when/switch/repeat/while/until body); `_build_domain_partition` now
  fails a nested cross-domain `(do child)` with an accurate "used by a nested
  '(do child)' (inside a <ctx>) ... nested cross-domain activation remains
  deferred" message, distinct from the genuinely-unused "declared but ... no
  top-level (do)" message. The top-level case still lowers; `t/1387` gained a
  subtest covering when/switch/repeat + the not-misreported-as-unused assertion
  (now 9 subtests). The recursive scan replaced the prior reliance on
  `_live_child_action_refs_from_transaction_clauses`, which only surfaced
  repeat-body do-refs (so when/switch nested uses were previously misreported as
  unused).
- `2026-05-31`: `.3` nested-support DESIGN recorded. Investigated the supported
  nested-`(do)` surface and found `do`/`spawn` are allowed only in the
  `transaction` and `repeat` clause contexts (`%SUPPORTED_TRANSACTION_CLAUSES`);
  plain when/switch/while/until-body `(do)` is unsupported even same-domain. So
  `.3`+ is scoped to **cross-domain repeat-body `(do)`** (per-iteration handshake
  through the dual-CDC; the caller restructure is expected to apply in the repeat
  region with little change). Re-scoped `.3`+ into `.3` top-level repeat-body and
  `.4`–`.7` for the remaining repeat contexts. NOTE: the do/spawn clause-context
  limitation has no fundamental semantic rationale (blocking `await` IS allowed in
  those contexts) — it is an implementation-scoping deferral, tracked separately
  for mdBook documentation and a possible future "conditional `(do)`" language
  feature aligned with the rich-high-level-language goal.
- `2026-06-01`: `.3` shipped — a cross-domain `(do child)` directly inside a
  TOP-LEVEL `(repeat ...)` body now lowers through the dual-CDC, the first supported
  nested cross-domain context. Two gates lifted: (1) the per-clause domain-ref
  validator (`_validate_transaction_clause_domain_refs`) now treats a crossing-
  covered cross-domain `(do)` as covered at label `repeat body` as well as
  `transaction body`; (2) `_activation_do_use_context`/`_scan_activation_do_use`
  gained a `top_level_repeat` flag (a `(do child)` whose immediate container is a
  `repeat` that is itself a direct transaction-body clause), and the partition
  (`_build_domain_partition`) treats `top_level_repeat` as a covered activation.
  The caller restructure (`_wire_external_activations`) applied to the repeat region
  with NO change: it finds the do-state by its `<start>` assertion, redirects the
  `repeat_init -> do` edge to the inserted `<do>_ready` await, splits the do-state
  into `ready -> req(one-cycle <start>) -> await <done>`, and leaves the
  `repeat_check -> repeat_init` loop-back untouched (it never targeted the do-state),
  so the full handshake re-runs every iteration; the callee's terminal->idle chain
  returns the worker to idle between iterations. Verified end-to-end: the
  3-domain-file lowering is correct AND `--check-json` SUCCEEDS (the dual-CDC
  composition is sound — no composition-scope boundary). Deeper nestings (when/
  switch/while/until body, or a repeat nested in another body) still fail closed,
  with the diagnostic refined to name both supported contexts ("a top-level
  '(do)' or a '(do)' directly inside a top-level '(repeat ...)' body; deeper nested
  ... remains deferred"). 13a/13d/13k updated (the cross-domain staging now lists
  top-level-repeat as shipped; the feature matrix row + non-claims updated). `t/1387`
  gains a positive top-level-repeat subtest (now 10) and repoints its `repeat body`
  deferral case to a `when->repeat` (still deferred); `t/1305` non-claims updated.
- `2026-06-01`: `.4` re-scoped. Closing theme #1
  (`ISF-CONDITIONAL-CHILD-ACTIVATION`) shipped same-domain `(do)`/`(spawn)` directly
  in `when`/`switch`/`while`/`until` bodies, which invalidates the `.3`-design
  premise that a branch-body `(do)` is N/A even same-domain. A covered cross-domain
  `(do)` directly in a branch body is therefore now a viable supported context and
  is promoted to `.4` (ahead of the deeper repeat-nestings), reusing the same
  restructure + a branch-body analog of the `top_level_repeat` partition flag.
- `2026-06-01`: `.4` shipped — a cross-domain `(do child)` directly inside any
  TOP-LEVEL branch/loop body (`when`/`switch`/`while`/`until`) now lowers through the
  dual-CDC, newly unblocked by `ISF-CONDITIONAL-CHILD-ACTIVATION` shipping the
  same-domain branch-body `(do)`. Validator: a covered cross-domain `(do)` is now
  accepted at the branch-body labels (`when body`/`switch branch`/`while body`/
  `until body`). Partition: `_activation_do_use_context` gained a
  `top_level_branch_body` flag (a `(do child)` whose immediate container is a
  when/switch/while/until that is itself a direct transaction clause; the
  `_scan_activation_do_use` `top_level_container` recursion arg was generalized to
  carry this), and the partition treats it as covered alongside `top_level` /
  `top_level_repeat`. The substantive fix was in the caller restructure
  (`_wire_external_activations`): it previously redirected only `transitions[].target`
  references to the do-state, which caught plain predecessors AND the while/until
  loop edges, but MISSED the `when` selector's `true_target` and the `switch`
  branch's `body_start` (those are rendered from dedicated fields, not `transitions`)
  — so the inserted ready/req states were unreachable and the start handshake was
  skipped. The redirect now also rewrites `true_target`, `branches[].body_start`,
  and `loop_body_start`. All four branch/loop contexts then lower correctly AND
  `--check-json` SUCCEEDS. Deeper nestings (a container itself nested inside another
  body) still fail closed, with the diagnostic refined to name the branch-body
  supported contexts. 13a/13d/13k updated (cross-domain `(do)` now lists all
  top-level bodies as shipped; the non-claim list tracks the remaining deeper-nesting
  deferral). `t/1387` gains a positive branch-body subtest (now 11) and repoints its
  `when body`/`switch branch` deferral cases to deeper `when->when`/`switch->switch`
  forms (deferral-lift cascade). Cross-domain top-level activation is now fully
  orthogonal to the same-domain top-level + repeat + branch/loop surface; only
  multi-level nesting remains for `.5`+.
- `2026-06-05`: `.5` split the multi-level frontier before any new code. The next
  executable leaf is `.6`, covering a cross-domain `(do child)` directly inside a
  repeat nested in a top-level `when` body or top-level `switch` branch. Remaining
  branch->branch, repeat->branch, and residual deeper combinations stay pending.
- `2026-06-05`: `.6` shipped. A cross-domain `(do child)` through a declared
  activation crossing now lowers inside a repeat nested directly in a top-level
  `when` body or top-level `switch` branch. The partition recognizes only that
  branch-contained repeat shape; branch->branch, repeat->branch, nested
  while/until, and residual deeper branch-repeat shapes still defer.
- `2026-06-05`: `.7` shipped. A cross-domain `(do child)` through a declared
  activation crossing now lowers inside supported nested `when` chains reached
  from a top-level `when` body or top-level `switch` branch. Nested switches,
  repeat-contained branch contexts, nested while/until, and residual deeper
  branch-repeat shapes still defer.
- `2026-06-05`: `.8` closed repeat-contained branch contexts without code. A
  repeat-body branch is not currently same-domain-supported, so cross-domain
  activation there remains deferred behind a separate same-domain owner.
- `2026-06-05`: `.9` shipped. A cross-domain `(do child)` through a declared
  activation crossing now lowers inside a repeat under a supported nested `when`
  chain. The only remaining contexts are unsupported/prerequisite-bound and are
  audited in `.10`.
- `2026-06-05`: `.10` closed the tree without behavior change. The code, tests,
  mdBook, and live spec agree on the shipped bounded cross-domain blocking `(do)`
  surface and on the remaining non-claims. Future cross-domain `(spawn)`,
  payload/auto-crossing, nested switch/while/until, repeat-contained branch, or
  broader deeper placement work requires a new exact task-tree owner before code
  changes.
