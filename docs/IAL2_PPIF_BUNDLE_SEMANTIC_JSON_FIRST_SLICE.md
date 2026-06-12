# IAL2 PPIF Bundle Semantic JSON First Slice

Status: shipped bounded aggregate normalized semantic JSON for multi-channel
`.ppif` Valid-Ready bundles.

Task tree:
[docs/tasks/IAL2-PPIF-BUNDLE-SEMANTIC-JSON-FIRST-SLICE.md](tasks/IAL2-PPIF-BUNDLE-SEMANTIC-JSON-FIRST-SLICE.md).

Builds on:
[docs/IAL2_PPIF_VALID_READY_BUNDLE_FIRST_SLICE.md](IAL2_PPIF_VALID_READY_BUNDLE_FIRST_SLICE.md).

Later HDL entry implementation:
[docs/IAL2_PPIF_BUNDLE_HDL_ENTRY_FIRST_SLICE.md](IAL2_PPIF_BUNDLE_HDL_ENTRY_FIRST_SLICE.md).

Runnable sample:
[ppif/axi_aw_w_valid_ready_bundle.ppif](../ppif/axi_aw_w_valid_ready_bundle.ppif).

## Scope

Multi-channel `.ppif` Valid-Ready bundles now support:

```bash
./bin/fsmgen --strict --emit-semantic-json ppif/axi_aw_w_valid_ready_bundle.ppif
```

The command emits normalized semantic JSON to stdout, writes no HDL, preserves
the public `.ppif` path in `source.resolved_path`, and reports the source as an
aggregate PPIF bundle semantic root.

The semantic root is not one generated channel `.fsm`. The root summary uses:

```text
semantic.module.source_root_kind = ppif_bundle
semantic.module.name             = <protocol-platform-intent name>
```

For the checked-in sample, the module name is
`axi_aw_w_valid_ready_bundle` and the aggregate child count is `2`.

## Payload Shape

The aggregate bundle payload is exposed under the optional semantic child:

```text
semantic.protocol_intent_bundle
```

The bounded first-slice fields are:

- `schema`: `fsmgen.ial2.protocol_intent.valid_ready_bundle.v1`;
- `mode`: the bundle report mode;
- `source_object`: the aggregate PPIF source object and anchors;
- `bundle`: protocol, channel count, channel object names, and inherited-source
  count;
- `channels[]`: per-channel source, target-channel, binding, generated
  artifact, transfer-fire, assertion, and residue metadata;
- `generated_artifacts`: generated `.isf`, generated channel `.fsm`, and
  aggregate wrapper/top `.fsm` review artifact summaries plus the selected
  HDL entry; and
- `generated_ial1_schedule_reports[]`: per-channel schedule-report presence
  summaries.

The key-presence contract is discoverable through
[perl/FSM/Support/NormalizedSemanticProtocolIntentBundleContract.pm](../perl/FSM/Support/NormalizedSemanticProtocolIntentBundleContract.pm)
and is advertised by the existing normalized semantic payload contract as the
optional `protocol_intent_bundle` child.

## Still Deferred

Default bundle HDL generation and `--verify-hdl` are shipped by the later
aggregate wrapper/top implementation. Full AXI manager behavior remains
outside this semantic export: transaction IDs, outstanding windows, bursts,
responses, ordering, and cross-channel dependency rules are still residue.

Single-channel `.ppif` semantic JSON is unchanged: it still lowers through the
generated `.fsm` path and reports the generated `.fsm` as the semantic root.

## Validation

Focused coverage lives in:

- [t/1436-ial2-ppif-parser-cli.t](../t/1436-ial2-ppif-parser-cli.t)
- [t/301-check-json-supported-corpus.t](../t/301-check-json-supported-corpus.t)
- [t/303-normalized-semantic-json-supported-corpus.t](../t/303-normalized-semantic-json-supported-corpus.t)
- [t/442-normalized-semantic-payload-contract-defensive-copy-boundary-audit.t](../t/442-normalized-semantic-payload-contract-defensive-copy-boundary-audit.t)

The corpus entry
`intent.ppif_axi_aw_w_valid_ready_bundle` records the public support-accounting
identity for both check JSON and normalized semantic JSON.
