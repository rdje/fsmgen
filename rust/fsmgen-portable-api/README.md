# fsmgen_portable_api

This crate is the first Rust/Rust-Wasm portability smoke scaffold for FSMGen.

It models the initial JSON-safe request/result, source identity, host profile,
virtual artifact, diagnostic, and capability-profile shell selected by the
backend-language portability task tree. It is intentionally incomplete and is
not wired into the shipped Perl CLI or capability manifest.

Current behavior:

- `capabilities()` reports an experimental incomplete Rust contract shell.
- `execute(request)` returns a public fail-closed unsupported-operation result
  for every operation.
- No `.fsm`, `.isf`, `.ppif`, HDL, semantic JSON, schedule JSON,
  verification-output, MCP, or extension behavior is implemented yet.

The active owner is
`BACKEND-LANGUAGE-PORTABILITY-CONTRACT-FRONTIER.3.1`.
