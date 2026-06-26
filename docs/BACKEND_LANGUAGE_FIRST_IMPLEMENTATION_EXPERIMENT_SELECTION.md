# Backend-Language First Implementation Experiment Selection

## Metadata

- Owner leaf: `BACKEND-LANGUAGE-PORTABILITY-CONTRACT-FRONTIER.2.8`
- Date: `2026-06-26`
- Status: `complete`
- Outcome: selected the first backend-language implementation experiment after
  the portable API, host abstraction, parity harness, mdBook blueprint, and
  extension boundary selectors. The selected experiment is a same-repository
  Rust/Rust-Wasm portable API smoke frontier. This selector does not add Rust
  code and does not change current Perl CLI/runtime behavior.

## Evidence Read

- Roadmap H1 Rust guidance in `ROADMAP_V2.md`.
- Project objective and portability summary in `README.md`.
- Prior portability selectors:
  `docs/BACKEND_LANGUAGE_PORTABLE_IN_MEMORY_API_CONTRACT_SELECTION.md`,
  `docs/BACKEND_LANGUAGE_PORTABLE_HOST_ABSTRACTION_SELECTION.md`,
  `docs/BACKEND_LANGUAGE_PORTABLE_PARITY_HARNESS_SELECTION.md`,
  `docs/BACKEND_LANGUAGE_MDBOOK_BLUEPRINT_SELECTION.md`, and
  `docs/BACKEND_LANGUAGE_TYPED_EXTENSION_PORTABILITY_AUDIT.md`.
- Current repository layout: no existing `rust/` implementation subtree.
- Local tool availability on 2026-06-26:
  `cargo 1.95.0`, `rustc 1.95.0`, and `wasm-bindgen 0.2.100` are available;
  `wasm-pack` is not currently available.

## Selected Experiment

The selected first experiment is:

```text
BACKEND-LANGUAGE-PORTABILITY-CONTRACT-FRONTIER.3:
Rust/Rust-Wasm portable API smoke experiment
```

The experiment starts in the same repository, not as a submodule or separate
repository. It is Rust-first with Wasm readiness in mind, but the first slice
does not require `wasm-pack`; plain `cargo test` is the initial validation
gate. Wasm packaging, browser demos, npm artifacts, and JavaScript-facing
bindings are later exact slices after the Rust contract shell exists.

Rust is selected first because:

- it is the roadmap's named H1 implementation direction;
- it can grow toward Rust/Wasm without changing the public FSMGen contracts;
- it gives a strong typed host for the `.2.3` request/result API and `.2.4`
  source-catalog/artifact-sink boundary;
- it can share the repository, task trees, mdBook, facts, fixtures, and
  Perl-reference parity harness;
- it does not require making browser JavaScript, Dart/web, or Julia semantics
  compete with an unsettled first core contract shell.

## Exact First Frontier

The new active owner is added under the portability task tree:

- `.3`: Rust/Rust-Wasm portable API smoke experiment.
- `.3.1`: scaffold the Rust portable API contract crate and tests.
- `.3.2`: add the first direct `.fsm` check-operation smoke once the contract
  shell exists.
- `.3.3`: add the first Perl-oracle parity smoke for the Rust check result.

The first implementation slice is `.3.1`. Its scope is deliberately narrow:

- create a same-repo Rust workspace/crate under `rust/`;
- model the JSON-safe `.2.3` request/result envelope for the initial operation
  family;
- model the `.2.4` host profile/source identity/artifact identity fields
  needed by the first smoke;
- expose a Rust capability/variant profile that clearly advertises the
  experiment as incomplete and not a shipped FSMGen replacement;
- return fail-closed unsupported-operation diagnostics for operations not yet
  implemented;
- add Rust unit tests and documentation for that contract shell;
- do not wire the Rust crate into `bin/fsmgen`, the Perl capability manifest,
  generated HDL, user CLI behavior, package installation, or mdBook examples as
  a shipped runtime.

## Future Smoke Sequence

After `.3.1`, the next bounded slices should be:

- `.3.2`: implement exactly one direct `.fsm` check-operation smoke over a tiny
  supported fixture, returning a JSON-safe public result shape without HDL
  generation.
- `.3.3`: compare that Rust check result against the Perl oracle after the
  `.2.5` normalization rules.

No `.isf`, `.ppif`, HDL generation, semantic JSON, schedule JSON, verification
output, MCP, typed extensions, browser UI, JavaScript bindings, package
publishing, or full corpus parity is part of `.3.1`.

## Validation Plan

Initial validation for `.3.1` should include:

- `cargo test` for the new Rust workspace/crate;
- JSON round-trip tests for the request/result/capability shell;
- a fail-closed unsupported-operation test;
- mdBook build for the updated implementation-blueprint status;
- Knowledge Map, memory architecture, diff whitespace, and doctrine checks.

Future `.3.2` and `.3.3` slices may add guarded Perl-oracle calls, but broad
`prove`/`fsmgen` corpus parity remains outside the first Rust scaffold and must
follow the `.2.5` resource policy.

## Compatibility And Rollback

The selected experiment must be additive:

- no change to current Perl CLI behavior;
- no change to shipped source syntax, diagnostics, reports, generated artifacts,
  HDL, semantic-introspection, support accounting, or extension behavior;
- no claim that Rust is a supported replacement implementation until parity
  gates prove it.

Rollback for `.3.1` is to remove the new `rust/` experiment files and the
task-tree/fact/book status updates for that slice. Because the selector does
not alter runtime behavior, selector rollback is documentation-only.

## Deferrals

- Browser JavaScript, Dart/web, Julia, and separate-repository experiments are
  deferred until the Rust contract smoke either proves or invalidates the first
  implementation path assumptions.
- Wasm packaging is deferred until after the Rust crate exists and passes local
  Rust tests.
- Portable typed extension support remains deferred behind a future extension
  API selector.
