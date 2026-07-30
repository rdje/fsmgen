# Project-Neutral Task-Acceptance Standard

This standard makes a code-changing task's cause → fix → effect chain
mechanically visible without embedding one project's tools in a reusable
checker. Projects declare their own change paths and evidence signatures as
data; the checker owns only the neutral checklist and matching semantics.

## 1. Contract

When a staged change touches a project-declared implementation path, one staged
task file under `docs/tasks/` must contain all three hard-gated boxes:

```markdown
## Acceptance Checklist (enforced)

- [ ] **ROOT CAUSE (WHY + WHERE)** — <tool output naming mechanism and locus>
- [ ] **ADDRESSED (verified)** — <before→after result from a named command>
- [ ] **NO REGRESSION** — <named broader gate and deterministic result>
```

Before commit, all three boxes must be checked. The root-cause and
no-regression boxes must each contain a matching project-declared evidence
signature inside that box's own body. Evidence in another box, elsewhere in
the file, or in a co-staged task file does not count.

Projects may add advisory REPRODUCE, FIX, and LOCKSTEP boxes. The neutral gate
does not hard-code them because their useful shape varies by project.

## 2. Current-Slice Freshness

An old checked checklist must never satisfy a later code change. Each required
checked box header must therefore be added or changed in the staged diff for
the current slice. The checker reads both checklist content and freshness from
the Git index, never from unstaged worktree text.

This permits the normal workflow: create unchecked boxes while investigating,
then change them to `[x]` with the final evidence in the code-bearing commit.
It also permits a newly added, already-complete checklist. Merely editing a
different part of a long-lived task file cannot reactivate an old checklist.

If several task files are staged, one file must independently satisfy the
entire checklist. Boxes and signatures are never assembled across files.

## 3. Project Declarations

The recommended project-local declarations live under
`doctrine/task_acceptance/`. They are plain UTF-8 tab-separated data, not shell
fragments, and are interpreted relative to the repository root.

### 3.1 Implementation-change paths

`doctrine/task_acceptance/change_paths.tsv` has two columns:

```text
path_ere<TAB>description
```

After the exact header row, every non-comment row declares one POSIX extended
regular expression matched against a staged repository-relative path. Anchor
patterns when whole prefixes or exact files are intended. At least one row is
required. Blank patterns, malformed expressions, extra/missing columns, and an
empty registry fail closed.

Deleted and renamed implementation paths count. Documentation-only work exits
successfully when no staged path matches, but both declaration files are still
validated so configuration rot cannot hide behind a docs-only commit.

### 3.2 Evidence signatures

`doctrine/task_acceptance/evidence_signatures.tsv` has six columns:

```text
scope<TAB>family<TAB>match<TAB>case<TAB>pattern<TAB>description
```

Allowed values are:

| Column | Allowed values | Meaning |
| --- | --- | --- |
| `scope` | `root_cause`, `no_regression` | Which required box the signature may back |
| `family` | lowercase identifier `[a-z][a-z0-9_-]*` | Project-owned tool/evidence family |
| `match` | `literal`, `ere` | Fixed-string or POSIX-ERE matching |
| `case` | `sensitive`, `insensitive` | Case behavior is explicit, never implicit |
| `pattern` | non-empty, no tab/newline | Tool-output token or expression |
| `description` | non-empty, no tab/newline | Reviewer-facing reason the token is probative |

At least one signature for each scope is required. Every ERE is compiled during
configuration validation. Unknown scopes/modes, malformed family ids,
malformed expressions, duplicate rows, extra/missing columns, and empty
required scopes fail closed.

Use literal matching by default. Use an ERE only when variable tool output
requires it, and keep the expression narrow enough that ordinary prose cannot
satisfy it. A bare source location or “verified by grep” is normally a claim,
not evidence from the diagnosing or regression oracle.

## 4. Checker Behavior

The neutral checker must:

1. derive the repository root from its own tracked path;
2. validate both declaration registries before interpreting the staged change;
3. enumerate staged paths from the Git index and test them against the declared
   change-path expressions;
4. exit successfully with an explicit “not required” result when no path
   matches;
5. read staged `docs/tasks/*.md` snapshots and staged added/changed line
   positions from the index;
6. identify Markdown checklist bodies by indentation and heading boundaries;
7. require fresh checked ROOT CAUSE, ADDRESSED, and NO REGRESSION boxes in one
   task file;
8. require box-scoped declared signatures for ROOT CAUSE and NO REGRESSION;
9. fail with actionable diagnostics that name the missing box, freshness, or
   signature scope; and
10. return nonzero on malformed configuration, Git/index errors, or ambiguous
    internal state rather than silently skipping enforcement.

Paths and scratch work stay repository-derived and on the repository volume.
The reference probes use an isolated repository-local Git fixture so they do
not mutate the caller's real index.

## 5. Calibration And Extension

Signature families describe the adopting project's real tools, not generic
aspirations. Before adding a family:

1. census actual task-leaf evidence for the defect class;
2. select tokens emitted by the tools authors really run;
3. prove positive cases and prose-only negative controls;
4. reject patterns that match unrelated narrative; and
5. land the registry change with focused checker probes.

If a legitimate defect class fits no family, open a task-tree leaf to extend
the registry. Do not weaken the checklist or paste an unrelated token merely
to pass the gate.

## 6. Enforcement And Honest Limits

Register the checker in the project's doctrine driver. The existing pre-commit
hook supplies local feedback and the hosted CI invocation is the merge
backstop. Both must run the same driver.

The checker proves presence, freshness, box scoping, and declared evidence
shape. It cannot prove understanding, prevent fabricated output, or replace
the deterministic commands cited by the task. Focused tests and broader CI
must still re-run the real oracles. Local hooks remain bypassable; CI is the
non-local enforcement layer. An incomplete change-path registry can miss work,
so registry coverage itself needs focused probes and review.

## 7. Adoption Checklist

1. Copy this standard and the neutral checker.
2. Create project-native `change_paths.tsv` and `evidence_signatures.tsv`.
3. Add the checklist template to the project's toolbox/task template.
4. Add focused RED/GREEN/control probes for configuration and checklist cases.
5. Register `TASK-ACCEPTANCE` in the doctrine driver used by hook and CI.
6. Run the focused probes and full doctrine gate before enabling enforcement.
