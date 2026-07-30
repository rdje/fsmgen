# 0026 — Task acceptance uses project-declared evidence registries

- Date: 2026-07-30
- Type: architecture
- Status: accepted (contract selected in
  `TASK-ACCEPTANCE-PORTABLE-DOCTRINE.1`; enforcement pending `.2`/`.3`)

## Context

FSMGen adopted PGEN's portable doctrine driver, hook, CI, and toolbox model in
June, but deliberately did not copy PGEN's `TASK-ACCEPTANCE` gate. That gate's
evidence families name PGEN's own parser, certificate, Rust, profiler, codegen,
and operations tools. Copying those expressions would create a misleading
PGEN fork in a supposedly project-neutral template.

The omission boundary was sound, but no follow-up owner or neutral design was
recorded. Repository and all-history searches on `2026-07-30` confirmed that
FSMGen had neither a task-acceptance doctrine nor a project-declared signature
mechanism.

## Decision

The portable standard is `TASK_ACCEPTANCE.md`. Its neutral checker consumes two
data-only project declarations:

1. `doctrine/task_acceptance/change_paths.tsv` declares POSIX EREs for staged
   repository-relative paths that require acceptance evidence.
2. `doctrine/task_acceptance/evidence_signatures.tsv` declares root-cause and
   no-regression signatures by family, fixed-string/ERE mode, explicit case
   behavior, pattern, and reviewer-facing description.

The files are TSV data, never sourced shell. They fail closed on malformed
rows, invalid expressions, empty required scopes, or unknown modes.

For a matching staged change, one staged `docs/tasks/*.md` file must contain
fresh checked ROOT CAUSE (WHY + WHERE), ADDRESSED, and NO REGRESSION boxes. The
root-cause and no-regression boxes require matching declared evidence inside
their own bodies. Each required box header must be added or changed in the
current staged diff, preventing an old checklist in a long-lived task tree from
satisfying later work. All content is read from the Git index.

Documentation-only slices are exempt when no declared implementation path is
staged, but registry validation still runs. Existing tests and CI remain the
oracle: the task-acceptance checker proves evidence presence, freshness, scope,
and shape, not truth or human understanding.

## Consequences

- The checker can be copied without inheriting FSMGen or PGEN tool names.
- Each adopting project reviews its own change scope and evidence vocabulary as
  data.
- FSMGen must calibrate narrow native signatures and focused negative controls
  before registering the doctrine.
- A stale checked checklist cannot satisfy a new implementation slice merely
  because the same task file changed.
- Local enforcement remains bypassable; the existing hosted doctrine driver is
  the merge backstop once `.3` registers the gate.
