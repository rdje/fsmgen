# FSMGen

FSMGen compiles Lisp-like state-machine and intent specifications into
synthesizable HDL. It emphasizes explicit semantics, reviewable lowering,
machine-readable diagnostics, and generated output that remains practical to
inspect and verify.

The repository is under active development. For exact current coverage, use
the [mdBook](docs/book/src/SUMMARY.md) and the machine-readable capability
manifest instead of inferring support from parser acceptance.

## What FSMGen does

FSMGen accepts three intent layers:

| Layer | Public sources | Responsibility |
| --- | --- | --- |
| IAL2 | `.ppif`, with bounded `.axi`, `.apb`, and `.ahb` profile aliases | Protocol and platform intent |
| IAL1 | `.isf` | Actors, transactions, scheduling, control flow, priorities, and verification intent |
| IAL0 | `.fsm` | Explicit cycle-authored state machines and decision trees |

Lowering is always reviewable and ordered:

```text
IAL2 -> IAL1 -> IAL0 -> SystemVerilog / Verilog / bounded VHDL
```

IAL2 never bypasses IAL1. The public formats and their observable behavior are
backend-language-neutral contracts; the current Perl 5 implementation is the
reference implementation, not the definition of those layers. See decisions
[0014](docs/decisions/0014-protocol-platform-intent-surface-and-layered-lowering.md),
[0015](docs/decisions/0015-ial2-profile-extensions-are-vocabulary-aliases.md),
and
[0018](docs/decisions/0018-ial-contracts-are-backend-language-neutral.md).

The primary backend is SystemVerilog. Verilog uses the compatible generation
path, while VHDL intentionally supports only documented, fail-closed subsets.
The precise backend and language boundaries live in
[Backends and Validation](docs/book/src/14-feature-backlog.md#backends-and-validation).

## Requirements

- Perl 5.20 or newer for the main implementation.
- mdBook to build or serve the user manual.
- Verilator and Yosys only when `--verify-hdl` external SystemVerilog
  validation is requested.

Run commands from the repository root. Project-owned outputs, logs, caches,
fixtures, and temporary workspaces must stay on the repository filesystem
volume; see [PROJECT_DATA_LOCALITY.md](PROJECT_DATA_LOCALITY.md).

## Quick start

Inspect the CLI and validate a shipped direct FSM without writing HDL:

```bash
./bin/fsmgen --help
./bin/fsmgen --quiet --strict --check --json fsm/ahb_lite_subordinate.fsm
```

Generate SystemVerilog:

```bash
./bin/fsmgen --strict fsm/ahb_lite_subordinate.fsm
./bin/fsmgen --strict --output .artifacts/sv/ahb_lite_subordinate.sv fsm/ahb_lite_subordinate.fsm
```

Without `--output`, generated HDL goes to the git-ignored
`.artifacts/<language>/` tree. Explicit output paths must also remain inside
the repository.

Preview higher-level lowering without writing HDL:

```bash
./bin/fsmgen --quiet --strict --emit-schedule-json isf/i2c_master.isf
./bin/fsmgen --quiet --strict --emit-schedule-json ppif/axi_aw_valid_ready.ppif
```

Inspect the current machine-readable product surface:

```bash
./bin/fsmgen --capability-manifest
./bin/fsmgen --quiet --strict --emit-semantic-json ppif/axi_aw_valid_ready.ppif
```

Common modes are discoverable through `./bin/fsmgen --help`:

| Need | Option |
| --- | --- |
| Check without writing HDL | `--check --json` |
| Emit normalized semantics | `--emit-semantic-json` |
| Preview IAL1/IAL2 scheduling | `--emit-schedule-json` |
| Select HDL | `--language systemverilog|verilog|vhdl` |
| Validate generated SystemVerilog externally | `--verify-hdl` |
| Emit a supported verification artifact | `--emit-verification-output TARGET --verification-outdir DIR` |
| Inspect supported surfaces | `--capability-manifest` |
| Enable deterministic trace output | `--trace-verbosity LEVEL --trace-log FILE` |

FSMGen also provides `bin/fsmgen-mcp`, a read-only local JSON-RPC stdio
adapter over the semantic-introspection contract. Its supported resources,
tools, safety boundary, and examples are documented in
[Extensions and Embedding](docs/book/src/11-extensions-and-embedding.md).

## Documentation

The mdBook is the user-facing product manual:

- [Introduction](docs/book/src/00-introduction.md)
- [Your First FSM](docs/book/src/01-first-fsm.md)
- [Language Basics](docs/book/src/02-language-basics.md)
- [Cookbook](docs/book/src/12-cookbook.md)
- [Implementation Blueprint](docs/book/src/15-implementation-blueprint.md)
- [Full table of contents](docs/book/src/SUMMARY.md)

Build or serve it from the repository:

```bash
mdbook build docs/book
cd docs/book
mdbook serve
```

Focused references remain outside the book where a narrower contract is more
useful:

| Topic | Canonical reference |
| --- | --- |
| Broad language reference during book migration | [docs/USER_GUIDE.md](docs/USER_GUIDE.md) |
| IAL1 syntax and semantics | [docs/ISF_SPEC.md](docs/ISF_SPEC.md) |
| Downstream IAL1/IAL2 integration | [docs/ISF_DOWNSTREAM_INTEGRATION_SPEC.md](docs/ISF_DOWNSTREAM_INTEGRATION_SPEC.md) |
| Composition boundary | [docs/COMPOSITION_SCOPE.md](docs/COMPOSITION_SCOPE.md) |
| Typed extension boundary | [docs/EXTENSION_MODEL.md](docs/EXTENSION_MODEL.md) |
| Supported sample corpus | [docs/REGRESSION_CORPUS.md](docs/REGRESSION_CORPUS.md) |
| Live CLI import architecture | [docs/BIN_FSMGEN_IMPORT_TREE.md](docs/BIN_FSMGEN_IMPORT_TREE.md) |

This README deliberately does not hand-maintain an exhaustive file index.
Derive it from the repository when needed:

```bash
rg --files -g '*.md' | sort
```

## Where current truth lives

Changing project state does not belong in this landing page:

| Question | Source of truth |
| --- | --- |
| What does shipped behavior do? | [mdBook](docs/book/src/SUMMARY.md) |
| What capabilities are reported now? | `./bin/fsmgen --capability-manifest` |
| What is the high-level direction? | [ROADMAP_V2.md](ROADMAP_V2.md) |
| What is active and what comes next? | [MEMORY.md](MEMORY.md), then [docs/TASK_TREE.md](docs/TASK_TREE.md) |
| What owns a task and its evidence? | The matching tree under [docs/tasks/](docs/tasks/) |
| Why was a cross-cutting choice made? | [docs/decisions/INDEX.md](docs/decisions/INDEX.md) |
| Is a fact already established? | [KNOWLEDGE_MAP.md](KNOWLEDGE_MAP.md) |
| What changed in a work unit? | [CHANGES.md](CHANGES.md), then `git log --grep=<UNIT-ID>` for the exact commit |
| How do I diagnose a failure? | [TOOLBOX.md](TOOLBOX.md) |
| Which repository rules are enforced? | [DOCTRINE_ENFORCEMENT.md](DOCTRINE_ENFORCEMENT.md) |

`CHANGES.md` receives one concise entry per completed slice.
`DEVELOPMENT_NOTES.md` is updated only when durable engineering rationale is
warranted. `ROADMAP_STATUS.md` and `LIVE_ACHIEVEMENT_STATUS.md` remain frozen
legacy records and are not live status sources; decision
[0025](docs/decisions/0025-project-document-interim-lifecycle.md) defines the
interim split pending their scheduled lifecycle review.

## Repository orientation

| Path | Purpose |
| --- | --- |
| `bin/fsmgen` | Main CLI |
| `bin/fsmgen-mcp` | Read-only semantic-introspection adapter |
| `perl/FSM/` | Reference parser, lowering, IR, generation, reporting, and support implementation |
| `fsm/`, `isf/`, `ppif/` | Public samples and support-accounted source corpus |
| `t/` | Perl regression and contract tests |
| `docs/book/` | mdBook source |
| `docs/tasks/` | Task-tree work memory |
| `docs/decisions/` | Durable decision records |
| `docs/knowledge/` | Dated fact cards indexed by `KNOWLEDGE_MAP.md` |
| `scripts/` | Doctrine, validation, resource-guard, and maintenance tooling |
| `.artifacts/` | Git-ignored, repository-local generated output |

For the exact transitive entrypoint graph and package ownership, use
[docs/BIN_FSMGEN_IMPORT_TREE.md](docs/BIN_FSMGEN_IMPORT_TREE.md), not a package
list duplicated here.

## Development workflow

Before changing code, tests, sources, generated artifacts, configuration, or
durable documentation:

1. Read [AGENTS.md](AGENTS.md), [MEMORY_ARCHITECTURE.md](MEMORY_ARCHITECTURE.md),
   [DOCTRINE_ENFORCEMENT.md](DOCTRINE_ENFORCEMENT.md), and
   [TOOLBOX.md](TOOLBOX.md).
2. Resume from [MEMORY.md](MEMORY.md), the active task tree, and only the
   relevant decision/fact records.
3. Ensure an exact task-tree leaf owns the change before making it.
4. Keep code, live references, task-tree evidence, and mdBook behavior
   documentation synchronized in the same slice.
5. Complete and commit each slice through [COMMIT.md](COMMIT.md) before
   switching tasks.

Activate the repository hooks once per clone:

```bash
git config core.hooksPath .githooks
```

Useful validation entrypoints:

```bash
scripts/check_doctrines.sh
./bin/ci-regression quick
./bin/ci-regression
prove -Iperl t/248-regression-corpus-accounting.t
mdbook build docs/book
```

Run broad or potentially heavy commands through the repository RAM guard:

```bash
scripts/run_with_ram_guard.sh -- ./bin/ci-regression
scripts/run_with_ram_guard.sh -- prove -Iperl t/248-regression-corpus-accounting.t
```

Use [SESSION_BOOTSTRAP.md](SESSION_BOOTSTRAP.md) for the full fresh-session
ritual. Paths recorded by the project must remain relative to the repository
root so the repository can move without invalidating its state.

## README maintenance

This file is a stable landing page, not a status board, implementation catalog,
or changelog. Change it only when the project objective, first-use path,
top-level architecture, or canonical navigation changes. Put feature detail in
the mdBook, work state in task trees, decisions in decision records, established
facts in the Knowledge Map, and history in git.

The bounded-entrypoint rationale is recorded in decision
[0021](docs/decisions/0021-readme-is-a-bounded-discovery-entrypoint.md). The
shareable, project-neutral guard and adoption checklist are tracked in
[README_POLICY.md](README_POLICY.md).

## License

FSMGen is licensed under the [Apache License 2.0](LICENSE).
