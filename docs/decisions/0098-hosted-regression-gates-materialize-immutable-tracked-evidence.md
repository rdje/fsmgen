# Decision 0098: Hosted regression gates materialize immutable tracked evidence

- **Status:** Accepted
- **Date:** 2026-09-03
- **Owner:** `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.5.4.3.1`
- **Refines:** [0088](0088-provider-backed-hosted-tests-use-explicit-dedicated-coordinates.md), [0096](0096-regression-promotion-uses-a-current-eleven-profile-corpus.md), [0097](0097-regression-gates-publish-replaceable-observations-without-recalibrating.md)

## Context

The regression-promotion gate authenticates two immutable evidence namespaces
before it can execute: the current corpus and its budget qualification. Both
live below ignored `.artifacts/qualification/vial-scale/v2/`. A fresh tracked
checkout therefore contains neither namespace even though ordinary hosted
file shards exercise the synthetic gate watchers.

The exact current source census is thirteen corpus files plus two
qualification files, 7,012,284 bytes in total. The corpus seal binds corpus
identity `ab2df8992d85b8466f4afca530a5af36984031c453002534fc92ff5678a2e505`
and file-set SHA-256
`dc5b315b827389eb466776716f6851cdd9ddd13b2f1aec441f8a51b7d72dc66f`.
The qualification seal binds qualification identity
`d8fb18132ebb52d85f30f40edc46f8e81a47bba90eb61f9bf02ae0821da60c97`
and combined qualification file-set SHA-256
`28ba972c3f8cbcc00d1d32c9db0d4015de57f0df49d11d7076262cd050069095`.
`git ls-files` returns none of those fifteen paths.

Regenerating on Ubuntu cannot reconstruct an Apple M4 Pro measurement seal,
and a cache or prior workflow artifact is mutable, expiring run state rather
than immutable qualification input. Installing Ubuntu's ambient Verilator
would be worse than absence: its version differs from the qualified 5.046
provider, so the gate correctly rejects provider drift. The qualified GHDL
6.0.0 LLVM-JIT package is repository-local macOS arm64 material and cannot be
substituted by an Ubuntu package.

## Decision

1. The durable source is a versioned tracked bundle rooted at
   `vial/qualification/regression_promotion_gate/evidence-v1/`. It contains a
   canonical `transport-manifest.json` and a `payload/` tree mirroring the two
   fixed destination namespaces below
   `.artifacts/qualification/vial-scale/v2/`.
2. The fifteen payload files are copied byte-for-byte as canonical JSON. They
   are not recomputed, normalized, concatenated, archived, or compressed at
   the application layer. Git's object storage may compress them
   transparently; the checked-out source stays directly inspectable and needs
   no extraction library or executable.
3. The manifest schema is closed and canonical. It orders exactly fifteen
   entries and records each payload-relative source, fixed destination,
   classification, byte count, and SHA-256. Its bundle identity is SHA-256
   over the schema plus ordered entry projection. The payload total is capped
   at 8,388,608 bytes and the manifest at 32,768 bytes. These are evidence
   transport bounds, not product scale or support claims.
4. Materialization accepts no caller root, source, destination, identity, or
   overwrite choice. It derives the repository and bundle roots from the
   tracked executable, authenticates ordinary same-device regular files,
   rejects links, aliases, extra/missing paths, noncanonical bytes, and every
   size/digest mismatch, then stages both complete namespaces on the repository
   volume.
5. Existing exact destinations make materialization idempotent. Any existing
   mismatch rejects without replacement. On an empty destination, the corpus
   root is atomically installed first and the qualification root is the commit
   point: before that point the gate has no qualification and cannot run.
   Recovery may finish only the one exact identity-scoped transaction; it
   otherwise removes owned staging and never combines versions. Cleanup
   removes only paths the invocation proved it created.
6. Local `full` pre-push runs the guarded gate exactly once after ordinary
   regression, and one explicit selected-important-step mode runs the same
   bounded entrypoint. Quick, smoke, ISF, focused tests, and ordinary slice
   commits do not acquire the full gate.
7. Hosted CI adds one unsharded seventh family on `ubuntu-24.04` with exact
   Perl setup. It installs no Verilator or GHDL package, asserts that
   `verilator` is absent and that the fixed repository GHDL archive/binary are
   absent, and materializes OSVVM 2026.05 at commit
   `2f7c391051dfb11890fa4bdbda9918d1db492250`.
8. Under that hosted provider state, profile ordinals 1-7 and 11 execute their
   available correctness, determinism, safety, measurement, publication, and
   cleanup routes. Ordinals 8-10 report exact-provider `unavailable`, never
   `pass`; the eight executed profiles report unmatched-host performance
   informationally. The aggregate result is therefore `unavailable`, with
   required topology 11/33/44 but honest observed topology 8/24/32.
9. The hosted job runs beneath the repository RAM guard, validates the
   canonical latest observation and exact qualification references, and then
   removes only its owned evidence, OSVVM, result, and staging paths. A changed
   runner image that supplies an ambient conflicting provider fails the
   prerequisite instead of feeding drift into the gate.
10. This transport does not recalibrate, rewrite, or reinterpret the evidence.
    It activates no pinned-host performance pass, support tier, capacity,
    mixed-language, full-language, or cross-backend parity claim.

## Alternatives rejected

- **Regenerate the corpus and qualification in hosted CI:** measurements,
  provider identity, and publisher provenance would differ, so the result
  would be a new calibration rather than transport of the accepted seal.
- **Download a prior run artifact or use Actions cache:** either source can
  expire or be replaced and neither is a repository-owned immutable input.
- **Force-add the payload under `.artifacts/`:** that confuses durable source
  with ignored generated state and makes normal artifact cleanup unsafe.
- **Store an application-level archive:** it hides per-file review, adds an
  extraction dependency and archive-path attack surface, and offers no
  semantic advantage over Git's own transparent object compression.
- **Install convenient Ubuntu Verilator/GHDL versions:** a near version is
  provider drift, not qualification and not honest unavailability.
- **Accept caller-supplied paths, URLs, or identities:** that bypasses the
  fixed qualification and permits history substitution.

## Verification legs

- **Re-derive:** run the independent corpus and qualification verifiers, then
  enumerate the two current source namespaces as ordinary files and recompute
  every byte count and SHA-256. Require thirteen plus two files, 7,012,284
  bytes, and the corpus/qualification identities above.
- **Falsify:** compare the census with `git ls-files` and a tracked-only fresh
  checkout; neither contains a source payload. Source regeneration, cache,
  caller-input, substitute-tool, and application-archive alternatives fail at
  least one identity, immutability, provider, or reviewability requirement.
- **Durability:** this decision, the owning task, synchronized mdBook and
  Knowledge Map fact, the fifteen tracked payloads, canonical manifest,
  producer-independent verifier, root-derived transactional materializer,
  hostile copied transport/materialization watchers, production corpus and
  qualification validators, `bin/ci-regression`, its copied-command inventory
  watcher, and work-unit commits retain the selection and exact audit. Hosted
  wiring remains separately owned after the local-driver child closes.

## Consequences and nonclaims

- A fresh checkout contains a repository-authenticated source for the exact
  current evidence without turning generated `.artifacts` into source. The
  explicit fixed-coordinate materializer can now construct and independently
  validate those generated coordinates or remove only receipt-owned roots.
- Local `vial-gate` and unsharded `full` now share the exact materialize, two-
  validator, RAM-guarded gate, and receipt-cleanup lifecycle. Full enters it
  once after ordinary regression; hosted shard modes, quick, smoke, and ISF do
  not. Exact pre-existing evidence and the latest gate observation survive.
- Hosted CI will exercise every route that is honestly available and preserve
  distinct unavailable and informational truth for the rest.
- The local driver placement is inventory-tested without running the real gate;
  hosted workflow activation and an independently authenticated real execution
  remain separately owned.

## Rollback

Before implementation, rollback removes this decision and synchronized
selection references and returns `.17.5.4.3.1` to active. After implementation,
remove hosted and local consumers first, then the materializer and tracked
bundle. Rollback never changes either immutable evidence identity or authorizes
recalibration.
