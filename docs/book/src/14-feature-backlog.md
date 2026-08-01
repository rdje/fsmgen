# Feature Backlog

This chapter is the canonical book-facing backlog for user-visible features
that are discussed elsewhere as future work, deferred, not fully shipped, or
not yet a fully frozen public contract.

When another chapter mentions a limitation of that kind, the item must also be
listed here. Local chapters may keep short contextual notes, but this chapter
is the consolidated review list.

### 2026-05-29 Status Snapshot

Recent surfaces added since the last consolidated walkthrough of
this chapter:

- **Targeted rejection diagnostics**: mismatched-domain generated repeat-body
  `do` and residual deeper-nested cross-domain activation remain deferred with targeted
  messages (`t/1372`, `t/1387`); four sub-axis activation-override
  gates — `repeat-count parameter`, `wait-count parameter`,
  `latency-bound parameter`, `watchdog-limit parameter` — each with
  its own deferral phrase (`t/1373`); undrained and cross-domain
  loop-contained/deeper-nested repeat-body spawn-drain variants remain
  deferred (`t/1374`/`t/1375`).
- **Loop-contained repeat-body `do`/`spawn`**: a plain local `(do child)`
  (`t/1379`), a same-domain generated `(do child (params ...))` (`t/1380`, child
  instantiated in the `_top`), and the basic `spawn` + same-body `(await_all
  done)`/single-pending `(await_any done)` subset (`t/1383`) inside a
  `(repeat ...)` directly in a single `(while ...)`/`(until ...)` body now lower.
  Multi-pending `(await_any done)` with later same-body `(await_all done)` and
  the documented pending-spawn local-`do` drain shapes also lower; undrained,
  cross-domain, and unstated wider local-`do` variants stay deferred.
- **Deeper-nested repeat-body `do`/`spawn`**: a plain local `(do child)`
  (`t/1381`), a same-domain generated `(do child (params ...))` (`t/1382`), and
  the basic spawn + drain subset (`t/1383`) plus multi-pending `(await_any done)`
  with later same-body `(await_all done)` (`t/1384`) at deeper branch nesting
  (`when⁺ → repeat`, `switch → when⁺ → repeat`) now lower; undrained and
  cross-domain generated `do` stay deferred.
- **Depth-neutral scheduler target**: the intended compositional scheduler
  contract has no arbitrary nesting-depth limit. Deep mixed chains such as
  `while -> do -> spawn -> call -> do -> while -> spawn -> spawn -> do -> do`
  are valid in principle when typed region/effect proofs establish child
  lifetime, loop backedge, binding/domain, generated-instance, and CDC
  invariants. Current bounded depth/context allow-lists remain migration cuts,
  not the target public contract.
- **Depth-neutrality audit boundary**: current hard requirements are the
  child-lifetime and loop-backedge proofs, `await_any` observation versus
  `await_all` drain semantics, deterministic generated-child identity,
  generated-top handoffs, explicit same-domain binding/domain contracts, and
  explicit CDC contracts. Cross-domain `spawn`, implicit CDC, payload CDC, and
  dynamic per-iteration hardware remain real missing contracts. By contrast,
  the former exact one/two/three/four loop-contained fanout gate has been
  replaced by exact-set proof consumption; the loop-plus-branch
  plain-local-only island, nested `switch` / extra-loop deferrals, and
  generated-activation case splits remain migration cuts.
- **Book example correctness build gate**: every `lisp`-tagged book
  example must parse + lower (`t/1376`). Current state: 80
  complete fixtures lower cleanly.
- **Cookbook ISF recipes**: `docs/book/src/12-cookbook.md` now
  carries recipes 9-13 covering basic actor, spawn, parameterized
  blocking do (same-value override), rule trigger, and repeat-body
  generated do. Each recipe carries a `**Walkthrough.**` paragraph.
- **Block-tag convention**: `lisp` blocks are reserved for
  accept-path fixtures that lower cleanly; `text` blocks are for
  schematics, elided actor bodies, and rejected-shape
  illustrations.
- **Handoff documents**: `docs/ISF_PUBLIC_INTERFACE_CONTRACT.md` and
  `docs/SPECFORGE_FEEDBACK_RESPONSE.md` are now current with the
  recent diagnostic surface.
- **Coverage audit**: a comprehensive mdBook coverage audit lives
  at `docs/audits/ISF-MDBOOK-COVERAGE-AUDIT-2026-05-27.md` with
  per-chapter coverage metrics and a prioritized slice queue.

The status markers below predate this snapshot and remain
chapter-internal categorisations; they have not been
retroactively renormalized.

Top-level backlog category ownership is tracked in
[docs/TASK_TREE.md](../../TASK_TREE.md). A category marked there as
`future task tree required` is not an implementation permission slip;
behavior-bearing work still has to create or activate an executable task tree
before code, tests, source artifacts, generated artifacts, or public behavior
changes.

## Backlog Topics

The backlog is partitioned into stable user-facing topics. Each topic remains
a direct `SUMMARY.md` entry so the complete backlog is one navigation step
from the book table of contents.

- [Language and Data](14a-language-and-data.md)
- [Composition](14b-composition-backlog.md)
- [Actor Network Orchestration](14c-actor-network-orchestration.md)
- [IAL2 Foundations](14d-ial2-foundations.md)
- [HIAL/VIAL Verification](14e-hial-vial-verification.md)
- [AXI Manager Core](14f-axi-manager-core.md)
- [AXI Dynamic Identity](14g-axi-dynamic-identity.md)
- [Protocol Profiles and APB](14h-protocol-profiles-and-apb.md)
- [AHB and Integration](14i-ahb-and-integration.md)
- [Extended AXI](14j-extended-axi.md)
- [ISF Language and Scheduling](14k-isf-language-and-scheduling.md)
- [Backends, Validation, and Public APIs](14l-backends-validation-and-apis.md)

## Backends And Validation

The existing deep-link target remains stable. Continue to
[Backends, Validation, and Public APIs](14l-backends-validation-and-apis.md#backends-and-validation).
