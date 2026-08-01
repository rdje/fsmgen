# TOOLBOX.md - FSMGEN Diagnostic And Doctrine Toolbox

Use this first when diagnosing FSMGEN issues. The goal is to locate the exact
why and where with repo-owned tools before changing code.

For code changes, record the relevant command and result in the owning
task-tree leaf. The commit must still follow `COMMIT.md`, and the doctrine
driver must pass:

```bash
scripts/check_doctrines.sh
```

## Code-Change Task Acceptance

`TASK_ACCEPTANCE.md` defines the neutral enforced contract. Any staged code,
test, source, generated-artifact, enforcement, or configuration change matching
`doctrine/task_acceptance/change_paths.tsv` must update one owning task file
with this current-slice checklist:

```markdown
## Acceptance Checklist (enforced)

- [ ] **ROOT CAUSE (WHY + WHERE)** — <tool output naming the mechanism and locus>
- [ ] **ADDRESSED (verified)** — <before→after result from a named command>
- [ ] **NO REGRESSION** — <named broader gate and deterministic result>
```

Before staging the final slice, tick all three. After staging, run:

```bash
scripts/check_task_acceptance.sh
scripts/check_doctrines.sh
```

The required box headers must be added or changed in the current staged diff;
an old checklist does not count. ROOT CAUSE and NO REGRESSION must each carry a
matching signature inside that box's own body. FSMGen's canonical signature
rows live in `doctrine/task_acceptance/evidence_signatures.tsv`:

| Scope | Families | Representative evidence |
| --- | --- | --- |
| Root cause | `fsmgen_trace`, `fsmgen_check`, `fsmgen_schedule`, `fsmgen_semantic` | `--trace-log`, `--check --json`, `--emit-schedule-json`, `--emit-semantic-json` |
| Root cause | `perl_diagnostic`, `git_history`, `hdl_compiler` | a Perl diagnostic locus, `git log -S`, Verilator/Yosys error output |
| No regression | `prove_summary`, `doctrine_driver`, `knowledge_map`, `readme_guard` | `All tests successful`, measured `Files/Tests`, all doctrines passed, `knowledge-map: OK` |
| No regression | `perl_syntax`, `hdl_verification` | `syntax OK`, `verilator_lint`, `yosys_synthesis` |

The TSV is authoritative; the table is a chooser. If a legitimate defect class
has no fitting family, open a task-tree leaf to calibrate a narrow native
signature instead of pasting unrelated evidence or weakening the checklist.

## Quick Chooser

| Symptom or question | First tool |
| --- | --- |
| Generated HDL looks wrong or a CLI run fails | Trace workflow with `--trace-verbosity=debug --trace-log=FILE`. |
| Need the legacy debug stream | `--debug=N` where `N` is `1..4`; bare `--debug` means `4`. |
| ISF or PPIF lowering/report shape is unclear | `--emit-schedule-json`. |
| Need stable diagnostics without writing HDL | `--strict --check --json`. |
| Need sanitized semantic/IR structure | `--strict --emit-semantic-json`. |
| Need generated SystemVerilog checked by external tools | `--verify-hdl --output .artifacts/sv/out.sv`. |
| Need support-accounting coverage truth | `prove -Iperl t/248-regression-corpus-accounting.t`. |
| Need a specific parser/generator regression | Focused `prove -Iperl t/<test>.t`. |
| Need user-facing docs proof | `mdbook build docs/book`. |
| Need docs path hygiene | `scripts/check_docs_relative_paths.sh`. |
| Need live-document pressure, maintained-reference aggregate authority, typed routes, index/evidence completeness, retention contracts, ceiling authority, or executed freshness/retrieval/currency truth | `scripts/check_live_document_size.sh`. |
| Need README entry-point hygiene | `scripts/check_readme_entrypoint.sh`. |
| Need Knowledge Map sync | `knowledge-map/scripts/gen_knowledge_map.sh` then `knowledge-map/scripts/check_knowledge_map.sh`. |
| Need doctrine/memory gate truth | `scripts/check_doctrines.sh`. |
| Need authoritative active task-tree structure or sealed-history truth | `scripts/check_task_tree_integrity.pl`. |
| Need code-slice evidence acceptance | Stage the intended slice, then run `scripts/check_task_acceptance.sh`. |
| Need diff hygiene before commit | `git --no-pager diff --check` and `git status --short`. |
| Need a downstream repro bundle | `./bin/fsmgen-issue-bundle --case PATH --issue-id ID -- [FSMGEN_OPTIONS...]`. |

## 1. Trace And Debug

### Trace log

Use this when the control flow, lowering path, or diagnostic context is unclear.

```bash
./bin/fsmgen --trace-verbosity=debug --trace-log=.artifacts/logs/fsmgen.trace \
  --output .artifacts/sv/fsmgen_out.sv path/to/input.fsm
```

Expected signal: command stderr/stdout stays readable, while
`.artifacts/logs/fsmgen.trace` contains origin-tagged trace lines with file,
function, and line information.
Use lower verbosity (`low`, `medium`, `high`) when the trace is too large.

For `.isf` or `.ppif` inputs, keep report-only JSON stdout clean by routing
trace output to a file:

```bash
./bin/fsmgen --quiet --trace-verbosity=debug --trace-log=.artifacts/logs/fsmgen.trace \
  --emit-schedule-json path/to/input.ppif
```

### Numeric debug

Use this for the older compatibility debug stream:

```bash
./bin/fsmgen --debug=3 --output .artifacts/sv/fsmgen_out.sv path/to/input.fsm
```

Expected signal: debug output identifies parser/generator phases and major
decision points. Prefer the named trace log when you need structured trace
routing.

## 2. Report-Only JSON Surfaces

### Schedule JSON

Use this first for `.isf` and `.ppif` lowering questions.

```bash
./bin/fsmgen --quiet --emit-schedule-json path/to/input.isf
./bin/fsmgen --quiet --emit-schedule-json path/to/input.ppif
```

Expected signal: stdout is JSON describing the scheduled/lowered intent. For
PPIF AXI manager work, this is the fastest way to inspect generated behavior
flags, report modes, generated rules, assertions, support residue, and source
identity before reading code.

### Strict check JSON

Use this for stable success/failure diagnostics and support-accounting matches.

```bash
./bin/fsmgen --quiet --strict --check --json path/to/input.fsm
./bin/fsmgen --quiet --strict --check --json path/to/input.isf
./bin/fsmgen --quiet --strict --check --json path/to/input.ppif
```

Expected signal: success reports include `success: true` and support-accounting
metadata when the source is catalogued. Failures return `success: false` with a
bounded diagnostic object instead of partial HDL artifacts.

### Semantic JSON

Use this when the generated HDL is downstream of a semantic shape problem.

```bash
./bin/fsmgen --quiet --strict --emit-semantic-json path/to/input.fsm
./bin/fsmgen --quiet --strict --emit-semantic-json path/to/input.isf
./bin/fsmgen --quiet --strict --emit-semantic-json path/to/input.ppif
```

Expected signal: stdout contains bounded normalized semantic JSON with module,
system, signal-analysis, symbol, and forward-IR projections. For `.isf` and
`.ppif`, the public source path remains the source identity even when generated
temporary `.fsm` sources are used internally.

## 3. HDL And External Validation

Use `--verify-hdl` after generating SystemVerilog when the suspected issue is
backend output quality or external-tool compatibility.

```bash
./bin/fsmgen --quiet --verify-hdl --output .artifacts/sv/fsmgen_out.sv path/to/input.fsm
```

Expected signal: FSMGEN writes SystemVerilog and runs the configured
Verilator/Yosys validation path when available. Missing optional external tools
are reported according to the existing validation contract; do not treat missing
optional tools as a behavior fix.

For direct inspection without external tools:

```bash
./bin/fsmgen --quiet --output .artifacts/sv/fsmgen_out.sv path/to/input.fsm
rg -n 'signal_or_rule_name|assert|always_ff' .artifacts/sv/fsmgen_out.sv
```

All project-owned output, trace, cache, and temporary paths must remain inside
the repository. Use [PROJECT_DATA_LOCALITY.md](PROJECT_DATA_LOCALITY.md) for
the canonical roots and the bounded external-input exception.

## 4. Support Accounting And Regression

Use support accounting when the question is "is this public sample or expected
failure catalogued and covered?"

```bash
prove -Iperl t/248-regression-corpus-accounting.t
```

Expected signal: the corpus-accounting test reports all catalogued supported,
strict-supported, semantic, and expected-failure entries as accounted.

Use focused tests for the owning subsystem:

```bash
prove -Iperl t/1436-ial2-ppif-parser-cli.t
prove -Iperl t/1437-axi-ial2-manager-capacity-status-generator.t
```

Use the repo-owned local regression tiers for broader checks:

```bash
./bin/ci-regression quick
./bin/ci-regression smoke
./bin/ci-regression isf
./bin/ci-regression
```

Broad or potentially heavy Perl runs launched by agents must use the RAM guard
or an equivalent active monitor:

```bash
scripts/run_with_ram_guard.sh -- prove -Iperl t/248-regression-corpus-accounting.t
```

## 5. Documentation, Knowledge, And Doctrine Gates

Use these when the issue touches user-facing docs, task continuity, or repo
policy.

```bash
mdbook build docs/book
scripts/check_docs_relative_paths.sh
scripts/check_live_document_size.sh
scripts/check_readme_entrypoint.sh
knowledge-map/scripts/gen_knowledge_map.sh
knowledge-map/scripts/check_knowledge_map.sh
scripts/check_memory_architecture.sh
scripts/check_task_tree_integrity.pl
scripts/check_doctrines.sh
```

Expected signals:

- mdBook completes without broken source or renderer errors.
- docs relative-path audit reports no machine-local home-directory paths.
- live-document size check reports all six pressure axes, proves bounded JSONL
  control data and maintained-reference authority, and rejects scalar/array,
  locality, coverage, pressure, route, index, evidence, and identity drift.
- README entry-point check confirms `README.md` is under its line and byte caps
  while retaining the purpose, first-use path, architecture summary, and
  navigation expected of the rendered GitHub landing page; it also rejects
  per-leaf work-unit narration (`docs/decisions/0021`, `0024`, and `0041`;
  reusable policy: `README_POLICY.md`).
- Knowledge Map check says facts are valid, IDs are unique, and the map is in sync.
- memory architecture check confirms `MEMORY.md` is bounded and bootstrap/task/decision stores exist.
- task-tree integrity reports active-tree/node/segment/compact-terminal/index-
  archive counts, rejects cross-file identity/source/retrieval drift, and proves
  bounded query-first completed rows while ignoring unregistered historical
  views under decisions `0019` and `0042`.
- doctrine bootstrap check confirms root doctrine/toolbox docs, bootstrap
  pointers, hook wiring, and CI wiring exist.
- doctrine driver reports every registered doctrine as `PASS`.

## 6. Task-Tree And Git Hygiene

Before any code, test, source, generated-artifact, or config change, identify
the owning task-tree leaf:

```bash
rg -n 'Current Frontier|<LEAF-ID>|Verification Log|Commit Log' docs/tasks docs/TASK_TREE.md
scripts/check_task_tree_integrity.pl
```

Before commit, follow `COMMIT.md`; after staging the intended paths, run the
staged-index acceptance check and full doctrine driver:

```bash
git status --short
git --no-pager diff --check
scripts/check_task_acceptance.sh
scripts/check_doctrines.sh
```

After commit, truncate `git_message_brief.txt` and verify a clean tree:

```bash
truncate -s 0 git_message_brief.txt
git status --short
```

Use the work-unit ID in every task-scoped Git subject; the owning task node and
Git are the change-history authorities under decision `0047`. Update
`DEVELOPMENT_NOTES.md` only when durable engineering rationale, constraints,
or working decisions warrant it. Decisions `0048` and `0049` retire the former
achievement journal and roadmap-status board; route direction, canonical
state, and completion evidence to `ROADMAP_V2.md`, task trees, `MEMORY.md`,
decisions, facts, the mdBook, and Git.

## 7. Downstream Issue Bundles

Use the bundle helper when a failure needs to be handed off or replayed without
asking the downstream reporter to classify the FSMGEN layer.

```bash
./bin/fsmgen-issue-bundle \
  --case path/to/input.isf \
  --issue-id short-id \
  --failure-class rejected-input \
  --expected 'expected behavior' \
  --observed 'observed behavior' \
  -- --strict
```

Expected signal: the bundle directory contains environment metadata, the input
artifact, capability manifest, original command output, check JSON, strict check
JSON, semantic JSON, schedule JSON, and generated SystemVerilog probes.

## 8. When The Toolbox Is Not Enough

If no command above can identify the why and where:

1. Record the missing diagnostic capability in the owning task-tree leaf.
2. Add or improve a tool under a new exact task-tree owner.
3. Add a deterministic doctrine check only when there is an invariant that can
   be re-derived from the repository or rerun as an oracle.

Do not replace missing tool evidence with speculation.
