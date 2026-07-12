# Decision records (layer C)

Durable, cross-cutting facts, constraints, conventions, preferences, and
"tried X, failed because Y" — one ADR-style record per file
(*Context → Decision → Consequences*). This is the in-repo, git-tracked home for
what used to live only in harness home-dir memory (`~/.claude/.../memory/`) or be
buried in the `MEMORY.md` blob. See `MEMORY_ARCHITECTURE.md` (layer C).

Conventions:
- One durable fact per `NNNN-kebab-title.md`, dated, with Context/Decision/Consequences.
- **Supersede, don't mutate**: when a fact changes, add a new record (or mark the old
  one `superseded by NNNN`); keep the audit trail honest.
- Before writing, check this index for an existing record and update it instead of forking.

| # | Title | Type | Summary |
| --- | --- | --- | --- |
| [0001](0001-isf-abstraction-layering.md) | ISF abstraction layering (ISF = IAL1) | architecture | HLL sugar desugars into ISF; only genuinely new models go to ATL. |
| [0002](0002-isf-language-richness-frontier.md) | ISF high-level-language richness frontier | project | The "feels like a high-level language" theme + the shipped construct surface. |
| [0003](0003-autonomous-pnt-and-no-mid-flow-pausing.md) | Autonomous PNT; do not pause mid-flow | feedback | PNT through frontier items autonomously; don't stop to ask "what's next." |
| [0004](0004-simulate-to-catch-codegen-bugs.md) | Simulate control flow — lint/synth aren't enough | learning | `verilator --binary` testbenches catch functional codegen bugs gates miss. |
| [0005](0005-push-only-on-explicit-request.md) | Push only on explicit request | feedback | Pushing is fully user-initiated; no commit-count cadence; don't fret about it. |
| [0006](0006-thorough-mdbook-runnable-examples.md) | Thorough mdBook with runnable examples | convention | Every feature documented with lots of runnable, lowering-clean examples. |
| [0007](0007-memory-architecture-supersedes-blob-narration.md) | Memory architecture supersedes blob narration | architecture | `MEMORY.md` is the bounded pointer; git + task-trees + ADRs are the record; legacy prose blobs frozen. |
| [0008](0008-verification-property-language-unification.md) | Unify verification on one property language | architecture | assert/assume/cover → clocked SV properties; `(contract …)` removed; one temporal-intent grammar. |
| [0009](0009-trigger-anchor-vocabulary.md) | Trigger-anchor vocabulary for bounded-eventually | architecture | Three trigger spellings (event/inline/ref) + a synthesizable-monitor output-mode; `contract` dissolves into the engine. |
| [0010](0010-severity-never-gated-by-trace-level.md) | Severity (≥ warning) is never gated by a trace level | convention | Warnings/errors/fatals always display (ungated `fsm_warn`/`fsm_error`/`fsm_fatal` → STDERR); trace levels gate informational output only. |
| [0011](0011-doc-file-paths-relative-to-repo-root.md) | Doc file paths are relative to the repo root | convention | No absolute machine-local path in docs; guard `t/1414` enforces it. |
| [0012](0012-knowledge-map-paths-relative-to-repo-root.md) | Knowledge Map paths are relative to the repo root | convention | Extends the relative-path invariant to `KNOWLEDGE_MAP.md` and fact cards; guard `t/1414` scans docs plus the generated map. |
| [0013](0013-compositional-control-flow-activation-model.md) | Compositional control-flow/activation model | architecture | Move ISF control-flow/activation support from enumerated syntax paths toward shadow-first typed region/effect contracts that prove hardware invariants before validator widening. |
| [0014](0014-protocol-platform-intent-surface-and-layered-lowering.md) | Protocol/platform intent surface and layered lowering for IAL2 | architecture | Future IAL2 generic containers include `.pif`, `.ppi`, and `.ppif` candidates; direct IAL2 → IAL0 lowering is forbidden; refined by `0015` for profile extensions. |
| [0015](0015-ial2-profile-extensions-are-vocabulary-aliases.md) | IAL2 profile extensions are vocabulary aliases | architecture | Protocol-specific extensions such as `.axi`/`.chi` may be accepted later as vocabulary/profile aliases over the same IAL2 layer, with no direct-lowering privilege. |
| [0016](0016-ppif-is-first-public-ial2-container.md) | `.ppif` is the first public IAL2 container | architecture | Selects `.ppif` as the first generic IAL2 file suffix and records the first public Valid-Ready source shape; parser/CLI implementation remains a later exact owner. |
| [0017](0017-ppif-valid-ready-bundle-contract.md) | PPIF Valid-Ready bundle contract | architecture | Selects a future multi-channel `.ppif` aggregate bundle report over per-channel generated `.isf`/`.fsm` artifacts; default HDL entry stays fail-closed until a wrapper or explicit entry owner lands. |
| [0018](0018-ial-contracts-are-backend-language-neutral.md) | IAL contracts and mdBook are backend-language-neutral | architecture | IAL0/IAL1/IAL2 and mdBook document portable semantics/contracts, while current Perl modules are reference implementation entrypoints for future Rust, JavaScript, and Dart parity. |
| [0019](0019-task-tree-in-file-secondary-views-are-historical.md) | Task-tree in-file secondary views are historical | convention | The node list + `docs/TASK_TREE.md` + git are the live sources; the in-file `## Current Frontier`/`## Verification Log`/`## Commit Log`/`## Changelog` are optional historical snapshots (not maintained per-slice); PNT selects from the node list. |
| [0020](0020-ial2-layered-composable-transactor-roles.md) | IAL2 roles as layered, composable transactors (future North Star) | architecture | Director-stated future horizon (no pivot): a protocol-agnostic transaction interface (write/read, single or burst) upward, primitive per-(protocol,role) bus-adapter role blocks, composed into higher-order entities that present the interface up the stack; owned by proposed `IAL2-TRANSACTION-LAYERED-ROLE-COMPOSITION-HORIZON`. |
