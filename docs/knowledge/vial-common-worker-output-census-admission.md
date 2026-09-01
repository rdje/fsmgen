---
id: vial-common-worker-output-census-admission
title: VIAL common-controller worker-output census is structurally bounded
answers:
  - "how is the VIAL worker output tree bounded after the worker exits?"
  - "what limits apply to the common measurement controller output census?"
  - "does the worker timeout bound the controller output tree walk?"
  - "do per-stage and terminal VIAL artifact admission share one census?"
  - "does interrupted VIAL stage recovery use the bounded output census?"
  - "what binds VIAL cleanup residue to the repository device?"
  - "can a successful VIAL measurement worker leave a live descendant?"
  - "when does the common VIAL controller terminate residual process groups?"
  - "can a VIAL common worker descendant escape containment with setsid?"
  - "what containment proof must reach EOF before VIAL staging cleanup?"
  - "what authenticates the VIAL staging root before destructive cleanup?"
  - "does VIAL cleanup recheck output census bounds before remove_tree?"
  - "does the worker output census create a VIAL capacity claim?"
date: 2026-09-01
status: current
tags: [vial, architecture-scale, worker-output, census, containment]
evidence: >-
  perl/FSM/VIAL/ArchitectureScaleMeasurement.pm;
  t/1749-vial-common-worker-output-census-admission.t;
  t/1748-vial-common-worker-artifact-file-admission.t;
  t/1751-vial-common-interrupted-stage-census-admission.t;
  t/1752-vial-common-worker-process-group-containment.t;
  t/1753-vial-common-bounded-cleanup-admission.t;
  t/1754-vial-common-detached-descendant-containment.t;
  docs/tasks/HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.md;
  docs/book/src/16de-vial-osvvm-runtime-execution-plan.md;
  doctrine/claim_verification/claims.jsonl;
  doctrine/claim_verification/claims-0002.jsonl
reverify: >-
  prove -Iperl -It/lib
  t/1748-vial-common-worker-artifact-file-admission.t
  t/1749-vial-common-worker-output-census-admission.t
  t/1751-vial-common-interrupted-stage-census-admission.t
  t/1752-vial-common-worker-process-group-containment.t
  t/1753-vial-common-bounded-cleanup-admission.t
  t/1754-vial-common-detached-descendant-containment.t
---

The isolated stage worker is timed and its canonical result pipe is bounded,
but those controls end before the parent controller inventories files left in
staging. The common controller therefore owns a separate structural census.

The census reads one directory entry at a time. It requires its root and every
entry to remain symlink-free, on the caller-selected repository device, and
owned by the current user. Each directory pathname, opened handle, and final
pathname must retain the same device, inode, mode, link count, owner, size,
modification time, and change time while it is traversed.

One shared implementation serves both the per-stage unreported-file check and
the terminal whole-staging artifact check. It admits equality at 1,024 files,
1,024 directories, 64 relative-path components, and 262,144 aggregate bytes
across every visited file and directory relative path. Each first excess fails
during traversal. Only the bounded file vector is sorted and returned.

Interrupted-stage recovery also reuses that implementation after acquiring the
exact stage lock and before starting a fresh worker. The exact file boundary is
recoverable, the first excess rejects before recursive reclamation, and the
existing symlink, special-file, and hard-link diagnostics stay authoritative.
Cleanup-residue reporting passes the already validated repository device into
the same census rather than trusting the remaining path as a new authority.

Worker-leader exit alone is never a containment proof. A worker that cannot
establish its exact process-group identity or begins with a live child rejects
before its callback runs. Before exit, it inventories its live parentage tree,
stops newly observed children, kills and reaps every exact observed PID, and
requires absence. A direct child remains in that parentage domain after
`setsid`, even though it has escaped the original process group, so it is
contained and its plausible callback result rejects with
`VIAL_SCALE_MEASUREMENT_PROCESS_RESIDUE_ERROR`.

The worker also sends exactly one safe/unsafe status byte on a dedicated
channel. The parent requires the safe byte and EOF: a surviving fork that still
holds its inherited writer cannot authorize recursive cleanup. The parent then
retains the original negative-PID TERM/KILL fallback. If either side cannot
prove its domain absent, an internal cleanup-safety bit suppresses terminal
census and recursive deletion and reports the exact owned staging identity as
residue.

Stage creation also retains the root's repository device, inode, and owner.
That identity must still match before worker-result validation, terminal
artifact admission, and destructive cleanup. A replacement or missing root
rejects without recursive deletion; if pathname disappearance prevents a
filesystem census, the exact owned staging identity remains the truthful
residue authority.

Cleanup repeats the common bounded census and then rechecks root identity
immediately before removal. Consequently the existing exact 1,024-file
boundary remains removable after terminal census, file 1,025 rejects as
residue, and interrupted recovery rejects the same first excess if it appears
between recovery validation and cleanup.

These are private controller-containment limits. They do not enlarge or reduce
the existing runtime-artifact byte ceiling and do not establish architecture
scale capacity, performance, backend support, or provider generality.
