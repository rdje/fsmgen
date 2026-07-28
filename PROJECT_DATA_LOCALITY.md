# Project Data Locality And Same-Volume Storage

FSMGen keeps all project-owned data on the filesystem volume that contains the
repository. This is a correctness and recoverability rule, not a preference.

The authoritative decision is
[docs/decisions/0022-project-data-locality-and-same-volume-storage.md](docs/decisions/0022-project-data-locality-and-same-volume-storage.md).
The adoption work is owned by
[docs/tasks/PROJECT-DATA-LOCALITY-SAME-VOLUME-ADOPTION.md](docs/tasks/PROJECT-DATA-LOCALITY-SAME-VOLUME-ADOPTION.md).

## Owned Data

The rule covers every path created, populated, or maintained for this project,
including:

- generated HDL and review artifacts;
- build products and incremental state;
- package, dependency, and tool caches;
- logs, traces, profiles, and coverage data;
- runtime-created test fixtures and temporary lowering workspaces;
- documentation build output and derived indexes;
- downloaded or copied project reference material.

## Canonical Repository-Local Roots

Persisted paths are written relative to the repository root. Runtime code and
tools derive the absolute root at execution time; they never persist the
machine's current absolute checkout path as project configuration.

| Data family | Repository-relative root |
| --- | --- |
| Generated user/review artifacts | `.artifacts/` |
| Temporary workspaces | `.artifacts/tmp/` |
| Test fixtures | `.artifacts/tmp/tests/` |
| Logs and traces | `.artifacts/logs/` |
| Tool and dependency caches | `.artifacts/cache/` |
| Build products without an established in-tree root | `.artifacts/build/` |
| Rust build products | `rust/target/` or an explicitly selected repository-relative target directory |
| mdBook output | `docs/book/book/` |

These directories are generated state and stay ignored unless an exact task
selects a review artifact for tracking.

## Root Derivation

- Repository scripts derive the root from their own tracked location or with
  `git rev-parse --show-toplevel` and then validate the result.
- Perl runtime code derives the root from the installed project entrypoint or
  an explicit repository-root argument; it does not infer project storage from
  an ambient operating-system temporary directory.
- Standard test and gate launchers establish repository-local `TMPDIR`, `TMP`,
  and `TEMP` before any fixture is created.
- Tool-specific stores such as Cargo, package-manager, coverage, or profiler
  caches must be pointed at a repository-relative cache/build root before use.
- An unset or unusable project-local root is a failure. Falling back to a
  home-directory or operating-system temporary directory is forbidden.

## Explicit Paths And External Inputs

Project-owned output options must resolve inside the repository volume. A
caller may choose a different repository-relative destination, but an explicit
output flag is not permission to write project data off-volume.

Caller-authorized external inputs may be read from another volume when the
workflow genuinely requires them. Keep that access read-only where possible,
identify it explicitly in the command or configuration, and record why it is
necessary. Required operating-system executables and toolchains are external
dependencies, not project-owned data; their caches and outputs are still
project-local.

## Existing Off-Volume Data

For exact project-owned data found off-volume, use this sequence:

1. Copy or move it to a repository-derived path on the repository volume.
2. Verify file counts and byte sizes, plus hashes when the content is material.
3. Run the owning workflow successfully from the repository-local copy.
4. Delete only the exact old project-owned data.
5. Re-run a residue census and record the result in the owning task-tree.

Never delete an ambiguous shared cache. Populate a project-local replacement,
stop accessing the shared copy, and remove only entries proven to belong to
FSMGen.

## Enforcement

Run:

```bash
scripts/check_project_data_locality.sh
```

The check is registered in `scripts/check_doctrines.sh`. During the bounded
adoption tree it pins the exact pre-adoption violation signatures so the debt
can only shrink; the final adoption leaf removes those signatures and leaves a
strict zero-new-default gate over live runtime, test, and public-instruction
surfaces. Historical completed task-tree evidence and frozen legacy prose are
not active instructions and are not rewritten merely to disguise old paths.
