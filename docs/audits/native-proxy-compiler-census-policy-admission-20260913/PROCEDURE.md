# Compiler workspace census with local Git policy

This directory owns source qualification only. The parent task must be committed
as done before the separate execution owner in `plan.json` becomes active. The
one-use issuer checks that committed task status, every input and implementation
pin, the current execution owner, normal-user identity, fresh roots and the
selected installed compiler/SDK epoch. It never invokes a compiler.

The future procedure is fixed; these commands are not source-qualification
checks. Run them only in the separately activated execution leaf, in order:

```bash
scripts/run_with_ram_guard.sh -- python3 -B docs/audits/native-proxy-compiler-census-policy-admission-20260913/admission.py emit
scripts/run_with_ram_guard.sh -- /bin/bash docs/audits/native-proxy-compiler-census-policy-admission-20260913/execute_once.sh
scripts/run_with_ram_guard.sh -- python3 -B docs/audits/native-proxy-compiler-census-policy-admission-20260913/review_profile.py --review-and-clean
```

Retain each command's first outer stdout, stderr and exit status in fresh
repository-local logs. Consume the runner's terminal tool result before review.
The shell records its separate runner streams and exit status in the plan's
output directory; RAM-guard diagnostics stay in the outer logs. A nonzero exit,
missing terminal result, missing capture or unexpected node blocks review and
the next command. Preserve all outputs and roots, then own the diagnosis. Do not
repeat an issuer, runner or cleanup entrypoint after a partial outcome.

The earlier invocation stopped in Git preflight. Its permit, rejected streams
and absence evidence remain preserved under their original output names. This
admission uses a distinct output and permit epoch. The fixed compiler workspace
names remain fresh because the earlier runner created none; preflight must
still prove their absence. Never clear or consume the earlier permit.

Every admission Git command selects the pinned installed `/usr/bin/git`, sets
`core.excludesFile=.gitignore`, and supplies a closed environment with
repository-derived temporary storage. The repository ignores only the exact
local `.claude/settings.local.json`; shared configuration stays visible.
Caller Git environment overrides and personal ignore configuration do not
define the admission view. Both permit preflights revalidate installed inputs
before querying Git; the independent cleanup review does the same.

`compile_profile.pl` rechecks the existing permit and exclusively consumes it
before creating a workspace. It uses the original native fixture builder for
the fixed nonzero and decoy modes, sequentially, with its existing compiler
request, environment and supervision bounds. Its observer retains the same
internal supervisor state object, without I/O or exceptions after fork. The
compiler's own supervisor retains control until it returns; the surrounding
phase alarm is disabled during that interval. Original results, direct-child
wait status and group settlement precede any profile or second compilation.

The original retirement walker records pre-compilation source custody. After
successful preparation it hashes the entire canonical metadata projection,
then adds the exact source-derived wrapper and controlled relative Cargo link.
Neither role is executed. The final full-byte capture must reconstruct that
earlier compiler-only projection exactly when the two controlled roles are
excluded. Failed settled preparation or failed walker capture retains its
available original error and node prefix. Unsettled process ownership grants no
further workspace access or cleanup.

The independent reader rechecks full membership, bytes, identities, modes and
links twice, then compares them with the original walker. Review requires the
unchanged installed epoch and successful original compiler receipts. Exact
cleanup rechecks the entire remaining node set before and after each removal;
only directory link counts may change as their known children disappear. Every
removal is journaled, with final root absence. No recursive catch-all removal is
used. Commit the first raw outputs, permit, independent capture, review and
cleanup evidence before closing the execution leaf; leave original historical
archives untouched.

The profiles establish only the selected current compiler's workspace behavior
under these bounded modes, plus the controlled unexecuted roles. They do not
attest a loaded image or complete SDK/library closure, prove the historical
startup cause, execute a native proxy, qualify general native receipt adapters,
publish a canonical image, or activate a product feature. The source model's
synthetic image and process identities are explicitly in-memory data.

Read-only repeatable source/data check after qualification:

```bash
scripts/run_with_ram_guard.sh -- python3 -B docs/audits/native-proxy-compiler-census-policy-admission-20260913/audit.py --verify-saved
```
