---
id: vial-common-worker-output-census-admission
title: VIAL common-controller worker-output census is structurally bounded
answers:
  - "how is the VIAL worker output tree bounded after the worker exits?"
  - "what limits apply to the common measurement controller output census?"
  - "does the worker timeout bound the controller output tree walk?"
  - "do per-stage and terminal VIAL artifact admission share one census?"
  - "does the worker output census create a VIAL capacity claim?"
date: 2026-09-01
status: current
tags: [vial, architecture-scale, worker-output, census, containment]
evidence: >-
  perl/FSM/VIAL/ArchitectureScaleMeasurement.pm;
  t/1749-vial-common-worker-output-census-admission.t;
  t/1748-vial-common-worker-artifact-file-admission.t;
  docs/tasks/HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.md;
  docs/book/src/16de-vial-osvvm-runtime-execution-plan.md;
  doctrine/claim_verification/claims.jsonl
reverify: >-
  prove -Iperl -It/lib
  t/1748-vial-common-worker-artifact-file-admission.t
  t/1749-vial-common-worker-output-census-admission.t
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

These are private controller-containment limits. They do not enlarge or reduce
the existing runtime-artifact byte ceiling and do not establish architecture
scale capacity, performance, backend support, or provider generality.
