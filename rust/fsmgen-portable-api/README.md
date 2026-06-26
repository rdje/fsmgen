# fsmgen_portable_api

This crate is the first Rust/Rust-Wasm portability smoke scaffold for FSMGen.

It models the initial JSON-safe request/result, source identity, host profile,
virtual artifact, diagnostic, and capability-profile shell selected by the
backend-language portability task tree. It is intentionally incomplete and is
not wired into the shipped Perl CLI or capability manifest.

Current behavior:

- `capabilities()` reports an experimental incomplete Rust contract shell with
  only the `check` operation partially implemented.
- `execute(request)` succeeds only for the direct `.fsm`
  `feature.direct_sreset_active_high` check smoke.
- `fsmgen-portable-api-check-smoke` is a test-only projection binary for the
  supported check smoke. It exists so the Perl parity test can execute the Rust
  crate and compare normalized check-JSON fields against the Perl oracle.
- Other `.fsm` check inputs return `E_PORTABLE_RUST_UNSUPPORTED_CHECK_SOURCE`.
- Non-check operations return `E_PORTABLE_RUST_UNIMPLEMENTED_OPERATION`.
- No general `.fsm`, `.isf`, `.ppif`, HDL, semantic JSON, schedule JSON,
  verification-output, MCP, or extension behavior is implemented yet.

The `.3.2` owner added the first direct `.fsm` check smoke; `.3.3` added the
first Perl-oracle parity smoke for that result.
