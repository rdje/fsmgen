# 0022 — Project data stays on the repository filesystem volume

- Date: 2026-07-29
- Type: convention
- Status: accepted (execution owned by `PROJECT-DATA-LOCALITY-SAME-VOLUME-ADOPTION`)
- Extends: [0011](0011-doc-file-paths-relative-to-repo-root.md), [0012](0012-knowledge-map-paths-relative-to-repo-root.md)

## Context

FSMGen already routes implicit generated HDL into `.artifacts/`, but the
startup audit found other live project-owned data paths still inheriting the
operating-system temporary directory or instructing users to write to it:

- CLI and in-process IAL1/IAL2 lowering use `File::Temp` without a
  repository-local `DIR`;
- Knowledge Map validation uses unqualified `mktemp`;
- standard Perl tests create hundreds of `File::Temp` fixtures under the host
  temporary root unless the harness controls the environment;
- active README, toolbox, mdBook, and fact-card commands use off-volume output
  examples; and
- a legacy configuration retains machine-local home-directory executable
  paths.

That state breaks repository portability, makes cleanup ownership ambiguous,
and can strand large or important generated state on another volume.

## Decision

1. All data created or maintained for FSMGen stays on the repository volume.
2. Persisted project paths are repository-relative. Runtime code derives
   absolute paths from the current repository root only when performing I/O.
3. `.artifacts/` is the general generated-state root. Temporary workspaces,
   test fixtures, logs, caches, and otherwise-unowned build output use its
   typed subdirectories.
4. Established same-volume roots such as `rust/target/` and
   `docs/book/book/` remain valid when they are already the tool's explicit
   repository-local build destination.
5. Explicit output flags do not authorize off-volume project writes. External
   caller-authorized inputs and required OS/toolchain executables may be read
   across volumes only when necessary, explicit, read-only where possible, and
   documented.
6. Existing exact project-owned off-volume data follows
   copy/verify/use/delete. Ambiguous shared caches are never deleted; the
   project instead populates and uses a local cache and stops consulting the
   shared one.
7. A registered doctrine check guards live runtime defaults, test/gate
   controls, public instructions, and project configuration. During adoption,
   exact baseline signatures make existing violations monotonic debt rather
   than allowing new violations; the closeout removes the baselines.
8. Completed task-tree evidence and pre-`0025` legacy-document contents remain
   historical. They are not rewritten solely to make old commands appear to
   have followed a policy adopted later. Decision `0025` subsequently
   reactivates only prospective `CHANGES.md` and conditional
   `DEVELOPMENT_NOTES.md` updates.

## Consequences

- Project workflows become movable across paths and filesystems without
  silently changing where owned state is stored.
- CLI and test behavior that previously relied on host temporary-directory
  defaults must establish a repository-local workspace explicitly.
- Public command examples and fact-card reverify commands must use
  repository-relative `.artifacts/` destinations.
- Tool cache setup becomes part of the standard project-local environment,
  including future Rust, Dart, Julia, Lua, and other toolchain work.
- Off-volume cleanup requires evidence of ownership and successful use of the
  local replacement; convenience is not sufficient reason to delete a shared
  cache.
