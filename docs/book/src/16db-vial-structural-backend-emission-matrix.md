# Structural Backend-Emission Matrix

`FSM::VIAL::ArchitectureScaleBackendEmissionMeasurementMatrix` turns the per-profile reports from the [verification architecture](16d-hial-vial-verification-architecture.md#structural-backend-emission-measurement-boundary) into one resumable qualification set. It accepts no caller inventory: every `{backend_profile, level}` coordinate comes in order from `ArchitectureScaleBackendEmission->owned_shapes`, and the matrix derives the adapter route from the owned level. Reference, limit, and over-limit coordinates use correctness validation. Gate and qualification coordinates request three and five samples respectively, but only when the canonical structural evaluation says artifacts were emitted.

Each profile is captured or revalidated in a separate guard-visible child. The child reconstructs and validates the complete report, publishes that raw report atomically, and sends only a compact closed entry to the coordinator over a close-on-exec, nonblocking pipe. Exception, signal, nonzero exit, malformed/noncanonical/oversized JSON, identity drift, or artifact drift fails before parent admission. A completed large report therefore leaves the long-lived coordinator's allocator state without weakening regeneration.

<!-- CLAIM-VERIFICATION:BEGIN vial-backend-emission-matrix-bounds-v1 -->
- Claim: The structural backend-emission publisher derives 20 profiles from producer ownership, limits each canonical publication to 524,288 bytes, and limits each compact child result to 65,536 bytes.
- Re-derive: Query producer owned_shapes and matrix publication_limits independently at the current revision.
- Falsify: Run focused matrix-watcher mutations for order, samples, provider evidence, oversized IPC/publications, collisions, and crash staging.
- Durability: Run the tracked matrix watcher and claim/doctrine gates whenever the producer, publisher, runner, book claim, or registry changes.
<!-- CLAIM-VERIFICATION:END vial-backend-emission-matrix-bounds-v1 -->

<!-- CLAIM-VERIFICATION:BEGIN vial-backend-emission-matrix-seal-fdc6e6a1b-v1 -->
- Claim: Clean revision `fdc6e6a1b1eb329286f4f9bdfc111efbc2f3b8df` seals the 20-profile structural matrix as 22 immutable files totaling 2,232,452 bytes; the largest profile is 442,009 bytes, the accepted aggregate has 13 emitted and 7 authoritative-non-emission profiles, 24 raw and zero excluded records, five provider-verification and three preflight-dominated profiles, and a separate guarded reload returns complete identity `backend-emission-matrix/a5bb05a5f4be7fb364fbf52c6750b10e04417d53732f364158e6f143bc71f735`.
- Re-derive: Run guarded `--validate`, census only `backend-emission-*` publication files independently with `find` and `wc`, and hash both manifests with `shasum -a 256`.
- Falsify: Run the exact matrix watcher from the clean revision and require rejection for any profile, manifest, common-identity, sample, provider, dominance, checksum, collision, or staging disagreement.
- Durability: Preserve content-addressed profile publications plus family/complete manifests on the repository volume, and retain the exact task, book, Knowledge Map, watcher, claim record, and Git closure chain.
<!-- CLAIM-VERIFICATION:END vial-backend-emission-matrix-seal-fdc6e6a1b-v1 -->

The closing exact watcher completed successfully in 12,656 seconds on its recorded Apple M4 Pro host under the unchanged 88%-host and 4,096-MiB-per-descendant guard. That duration is provenance for this capture, not a public performance budget. The 30,203-byte family manifest has SHA-256 `fc9e43c11e7be14c8f1bc0c4163c8c2ca4c7ed96280662eb3331e2857bc72ea3`; the 2,535-byte complete manifest has SHA-256 `6c0fbc21d62f2034fb0e2718a3b015b4d335dc2d691bce28dc13b4464124878a`. Twelve profiles are validation-only; eight are measurement candidates, of which six are applicable and two are authoritative non-emission. This partition explains why the raw-record total is 24 rather than treating every coordinate as timed.

The publication ceiling follows a guarded largest-profile canonical-report calibration and retains serialization headroom; the raw-file and compact-IPC ceilings are deliberately separate. They are integrity and failure-containment controls—not performance budgets, backend capacity, or reached-limit evidence.

Profiles publish below root-derived same-volume `.artifacts/qualification/vial-scale/v1/<content-addressed-profile-id>/`, one `measurement-publication.json` per directory. Byte-equal retry resumes; different content collides. Exact complete crash staging can recover, while ambiguity rejects and remains for diagnosis. Family `matrix.json` and complete `complete-matrix.json` remain absent until all profiles agree on one clean Git revision and one host, in-process tool, and enforced-guard identity. Dominance separates emission, authoritative non-emission, preflight dominance, validation-only routes, applicability, raw/excluded samples, diagnostics, and the five read-only OSVVM provider-verification profiles.

Inventory inspection does no measurement and needs no guard. Capture and independent reload require the real repository guard; capture additionally requires a clean Git revision:

```bash
scripts/run_vial_backend_emission_measurement_matrix.pl --inventory
scripts/run_with_ram_guard.sh -- \
  scripts/run_vial_backend_emission_measurement_matrix.pl
scripts/run_with_ram_guard.sh -- \
  scripts/run_vial_backend_emission_measurement_matrix.pl --validate
```

Use `--family` for only the `backend_emission_v1` family manifest. Enable full exact watcher coverage with `FSMGEN_VIAL_SCALE_BACKEND_EMISSION_MATRIX_EXACT=1` below the guard; inventory and default hostile checks stay fast and create no qualification publication. The exact watcher is intentionally heavyweight because it captures and independently reloads every canonical report. These paths do not compile HDL, start a simulator, run IASIM, produce a runtime trace/result, establish tool support, promote a budget, prove capacity/reached boundaries, or add a public product API.
