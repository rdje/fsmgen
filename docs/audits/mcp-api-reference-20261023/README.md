# MCP operating-reference evidence — 2026-10-23

This directory retains the transport repair, catalog-observer repair and live
public-interface census owned by `PERL-POD-API-REFERENCE`. It is evidence for
the ongoing reference work, not a claim of complete MCP operating documentation.

## Live census boundary

`live-inventory.json.gz` captures the real persistent server at source HEAD
`ed92d0a12`: initialization, discovery, all static resources, every public
manifest section and focused argument/limit/refusal cases. It records complete
raw UTF-8 exchanges and decoded values. No hardware compilation, source-query
epoch, simulation or temporal execution is run by this metadata capture.

Recheck the saved artifact from the repository root:

```bash
scripts/run_with_ram_guard.sh -- python3 -B docs/audits/mcp-api-reference-20261023/verify_inventory.py docs/audits/mcp-api-reference-20261023/live-inventory.json.gz --controls
```

The independent reader joins wire frames, dispatcher methods, manifest
declarations, field rows, selected source hashes and exact producer versions.
It reports observed discrepancies without treating them as successful schema
conformance. `live-inventory-custody.json` binds compressed/uncompressed bytes,
collector and reader identities. Re-derivation is the live collector;
falsification is the saved reader's genuine missing/extra/borrowed/type/wire/
source interventions; durability is this packet, its sources and Git boundary.

The capture has 7 methods, 9 tools, 6 static resources, 13 listed templates and
74 exchanges. It joins 406 selected source/schema/doc files to Git, including
all 399 tracked FSM modules. Named property rows contain 21 input and 63 output
paths, including nested inspection-envelope properties. Open-object members
and complete backing-model semantics are not inferred from these counts.

## Confirmed repair cohorts

| Owner suffix under `.6.1.2.2` | Evidence |
| --- | --- |
| `.1` source identities | Repaired after the census: discovery now requires a nonempty selector alternative; original observations remain in the saved capture |
| `.2` diagnostic limit | Repaired: discovery advertises the diagnostic sample limit; defaults retain |
| `.3` capability payload | Repaired: selected version retains its integer payload; the schema admits it |
| `.4` argument enforcement | Repaired: metadata/envelope, numeric limits, source kinds and caller copies |
| `.5` error locations | Locations/operator context repaired; zero-reason fallback fix owned |
| `.6` documentation type | Ordinary example results contain a documentation object against an array declaration |

Findings are per-exchange observations and can overlap; they are not a count
of distinct defects. Exact repair nodes, priority and follow-up reference work
live in `docs/tasks/PERL-POD-API-REFERENCE.md`.

## Source-selector repair

`source-identity-before.json.gz` and `source-identity-after.json.gz` retain full persistent exchanges from predecessor `9032514b0`, with actual source hashes.
All 12 valid results conserve, including aliases, absolute-path admission and source_path precedence; all 51 refusals preserve their reason/code. Private
error locations remain owned. Live VIAL/version and existing MCP regressions pass.

```bash
python3 -B docs/audits/mcp-api-reference-20261023/verify_source_identity.py docs/audits/mcp-api-reference-20261023/source-identity-before.json.gz docs/audits/mcp-api-reference-20261023/source-identity-after.json.gz
```

The reader joins raw/decoded data, sources, exact metadata changes, unchanged query runtime and full results. Four coherent adverse controls reject at their
intended checks. Task .6.1.2.2.1 owns detailed evidence and original failures;
these selected queries imply no full-feature, platform, timing or runtime claim.

## Limits and numeric control

The reader implements only the emitted schema keyword subset and fails on
unhandled keywords; it is not a general JSON Schema validator. The selected
repository source footprint is explicit; external toolchain binaries/modules
are not fully fingerprinted. No platform matrix or timing guarantee is claimed.

The prepublication numeric control caught a reader enum comparison that
distinguished equivalent numeric spellings. The corrected reader accepts 1.0
for numeric enum 1 while keeping Booleans distinct. The original source/control
is retained in `reader-numeric-control-before.json.gz`. The governing rules are
[JSON Schema instance equality](https://json-schema.org/draft/2020-12/json-schema-core#section-4.2.2)
and [MCP structured-result conformance](https://modelcontextprotocol.io/specification/2025-06-18/server/tools#output-schema).
