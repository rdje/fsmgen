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
