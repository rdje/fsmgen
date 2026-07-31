# 0024 — `README.md` is a nearly static landing page

- Date: 2026-07-30
- Type: convention
- Status: accepted
- Extends: [0021](0021-readme-is-a-bounded-discovery-entrypoint.md)
- Refined by: [0038](0038-readme-policy-is-harness-neutral-and-locally-authoritative.md),
  [0040](0040-readme-routing-must-close-destination-pressure.md)

## Context

Decision 0021 stopped README per-leaf chronology and reduced the file from
9,911 lines to a bounded discovery entry point. Its 2,600-line ceiling was
calibrated around that emergency cleanup, however, and still allowed the
GitHub landing page to reach 2,353 lines / 377,853 bytes.

The remaining bulk was primarily a hand-maintained documentation inventory and
detailed implementation/status narration already derivable from the mdBook,
task trees, decision index, Knowledge Map, source tree, capability manifest,
and git. The director requires the README to be almost static and asked for a
small reusable policy that other projects can adopt.

## Decision

1. `README.md` is the concise GitHub landing page. It changes only when the
   project objective, first-use path, top-level architecture, or canonical
   navigation changes.
2. Dynamic behavior detail belongs in the mdBook; current work in Memory and
   task trees; rationale in decision records; facts in the Knowledge Map;
   inventories in generated/dedicated references; and history in git.
3. FSMGen caps the reviewed landing page at 300 lines and 16,384 bytes. Both
   budgets are enforced by `scripts/check_readme_entrypoint.sh` through the
   pre-commit hook and CI. A cap must not be raised merely to fit new prose; a
   future increase requires an explicit reviewed decision that the
   landing-page contract itself expanded.
4. [README_POLICY.md](../../README_POLICY.md) is the small, self-contained,
   project-neutral adoption standard. It is tracked for direct sharing and does
   not depend on FSMGen's task-tree or memory architecture.

Decision 0038 refines the current local limits to 275 lines / 12,288 bytes and
makes the reusable standard explicitly harness-neutral, locally authoritative,
independent of its originating template, and unconditionally enforced.

## Consequences

- The mandatory first read remains fast and useful.
- README growth fails mechanically by both line count and byte size.
- Changing project state no longer creates routine README churn.
- Detailed information remains available from one canonical maintained home
  instead of being duplicated into a new prose blob.
