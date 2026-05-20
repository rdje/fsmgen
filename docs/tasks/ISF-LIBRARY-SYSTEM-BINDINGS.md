# ISF-LIBRARY-SYSTEM-BINDINGS: Library System-Port Remapping

## Metadata

- Tree ID: `ISF-LIBRARY-SYSTEM-BINDINGS`
- Status: `done`
- Roadmap lane: `R14`
- Created: `2026-05-15`
- Last updated: `2026-05-15`
- Owner: repo-local workflow

## Goal

Ship ISF reusable-library clock/reset use-site remapping so a library actor may
author its own system signal names while an importing actor binds those ports
to differently named parent clock/reset signals.

## Non-Goals

- Do not add use-site reset-policy overrides; the reusable actor still owns
  sync/async and reset polarity semantics.
- Do not add multi-clock-domain scheduling semantics. ISF currently models one
  clock domain per actor/generated top; remapping changes signal names at the
  composition boundary, not the clock-domain model.
- Do not change FIFO library parameters, storage shape, or data-path behavior.

## Acceptance Criteria

- Same-name library clock/reset system bindings can be inferred when the parent
  and child clock names match and the reset name/kind/polarity matches.
- Library `(bind (clock parent) (reset parent))` entries emit explicit
  generated top links when the child system names differ from the parent names.
- Direct `.fsm +system` accepts HDL-identifier-compatible clock names so
  specialized library children with authored clock names can reach HDL.
- Malformed clock names still fail closed with a targeted diagnostic.
- Focused parser, generated-top, and HDL generation coverage passes.
- The mdBook, ISF spec, catalog, public contract, roadmap status, and live docs
  no longer claim clock/reset remapping is fail-closed.
- The completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `ISF-LIBRARY-SYSTEM-BINDINGS`
  Status: `done`
  Goal: `Enable library actor system-port remapping through generated top and direct .fsm HDL generation.`
  Children: `ISF-LIBRARY-SYSTEM-BINDINGS.1`

- ID: `ISF-LIBRARY-SYSTEM-BINDINGS.1`
  Status: `done`
  Goal: `Support remapped reusable-library clock/reset bindings end to end.`
  Acceptance: `Generated top emits explicit remap links, direct .fsm accepts authored clock identifiers, malformed clock identifiers remain rejected, and remapped library children reach SystemVerilog.`
  Verification: `perl -Iperl -c perl/FSM/Adapter/FSMGenFull/Parser.pm; perl -Iperl -c perl/FSM/Scheduler/ISF/Emitter/CompositionTop.pm; perl t/31-language-contract-system-section.t; perl t/72-language-contract-system-section-entrypoints.t; perl t/80-language-contract-system-reset-name-boundary.t; perl t/1231-isf-library-generated-top.t; perl t/1239-isf-library-catalog-contract.t; perl t/317-language-surface-contract.t; perl t/446-language-surface-contract-defensive-copy-boundary-audit.t; perl t/1142-isf-public-guidance-metadata-audit.t; ./bin/ci-regression quick; mdbook build docs/book; git diff --check`
  Commit: `ISF-LIBRARY-SYSTEM-BINDINGS.1: support library system remaps`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `ISF-LIBRARY-SYSTEM-BINDINGS.1` | `done` | Closed; remapped library system bindings now reach generated HDL. |

## Decisions

- `2026-05-15`: Treat clock/reset remapping as generated-top wiring, not reset
  policy rewriting. The child actor keeps its authored system names and reset
  policy; the top-level composition links parent clock/reset signals to those
  child system ports explicitly when names differ.
- `2026-05-15`: Broaden direct `.fsm +system` clock names from literal `clk`
  to any HDL-compatible identifier. The backend already consumes the effective
  system contract, so preserving the authored clock name is the correct root
  fix for generated library children.
- `2026-05-15`: Keep this feature scoped to the current one-clock-domain ISF
  model. Multi-clock, asynchronous, and interacting clock domains need their
  own public semantics, scheduling model, diagnostics, and verification plan.

## Open Questions

- None.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-15` | `ISF-LIBRARY-SYSTEM-BINDINGS.1` | `perl -Iperl -c perl/FSM/Adapter/FSMGenFull/Parser.pm`; `perl -Iperl -c perl/FSM/Scheduler/ISF/Emitter/CompositionTop.pm`; `perl t/31-language-contract-system-section.t`; `perl t/72-language-contract-system-section-entrypoints.t`; `perl t/80-language-contract-system-reset-name-boundary.t`; `perl t/1231-isf-library-generated-top.t`; `perl t/1239-isf-library-catalog-contract.t`; `perl t/317-language-surface-contract.t`; `perl t/446-language-surface-contract-defensive-copy-boundary-audit.t`; `perl t/1142-isf-public-guidance-metadata-audit.t`; `./bin/ci-regression quick`; `mdbook build docs/book`; `git diff --check` | `passed` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-LIBRARY-SYSTEM-BINDINGS.1` | `ISF-LIBRARY-SYSTEM-BINDINGS.1: support library system remaps` | `Generated-top remap links, authored .fsm clock names, docs, and tests.` |

## Changelog

- `2026-05-15`: Created task tree and started the first end-to-end remapping leaf.
- `2026-05-15`: Completed `ISF-LIBRARY-SYSTEM-BINDINGS.1` and closed the tree.
