# Structural Backend-Emission Matrix

`FSM::VIAL::ArchitectureScaleBackendEmissionMeasurementMatrix` turns the per-profile reports from the [verification architecture](16d-hial-vial-verification-architecture.md#structural-backend-emission-measurement-boundary) into one resumable qualification set. It accepts no caller inventory: every `{backend_profile, level}` coordinate comes in order from `ArchitectureScaleBackendEmission->owned_shapes`, and the matrix derives the adapter route from the owned level. Reference, limit, and over-limit coordinates use correctness validation. Gate and qualification coordinates request three and five samples respectively, but only when the canonical structural evaluation says artifacts were emitted.

Each profile is captured or revalidated in a separate guard-visible child. The child reconstructs and validates the complete report, publishes that raw report atomically, and sends only a compact closed entry to the coordinator over a close-on-exec, nonblocking pipe. Exception, signal, nonzero exit, malformed/noncanonical/oversized JSON, identity drift, or artifact drift fails before parent admission. A completed large report therefore leaves the long-lived coordinator's allocator state without weakening regeneration.

<!-- CLAIM-VERIFICATION:BEGIN vial-backend-emission-matrix-bounds-v1 -->
- Claim: The structural backend-emission publisher derives 20 profiles from producer ownership, limits each canonical publication to 524,288 bytes, and limits each compact child result to 65,536 bytes.
- Re-derive: Query producer owned_shapes and matrix publication_limits independently at the current revision.
- Falsify: Run focused matrix-watcher mutations for order, samples, provider evidence, oversized IPC/publications, collisions, and crash staging.
- Durability: Run the tracked matrix watcher and claim/doctrine gates whenever the producer, publisher, runner, book claim, or registry changes.
<!-- CLAIM-VERIFICATION:END vial-backend-emission-matrix-bounds-v1 -->

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

Use `--family` for only the `backend_emission_v1` family manifest. Enable full exact watcher coverage with `FSMGEN_VIAL_SCALE_BACKEND_EMISSION_MATRIX_EXACT=1` below the guard; inventory and default hostile checks stay fast and create no qualification publication. These paths do not compile HDL, start a simulator, run IASIM, produce a runtime trace/result, establish tool support, promote a budget, prove capacity/reached boundaries, or add a public product API.
