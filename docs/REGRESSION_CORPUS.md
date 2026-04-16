# Regression Corpus

This note is the human-readable companion to the machine-checked regression
catalog in [t/lib/FSM/Test/RegressionCorpus.pm](/Users/richarddje/Documents/github/fsmgen/t/lib/FSM/Test/RegressionCorpus.pm).

The point of `R12` is not just to collect examples. It is to make support
claims auditable:

- named corpus entries exist,
- each entry has an explicit classification,
- each entry has an explicit coverage bucket,
- and only regression-backed assets count toward support claims.

Catalog entries are contract entries, not necessarily one-to-one file names.
The same repo asset may appear more than once when FSMGen intentionally carries
more than one contract for it, for example:

- default-mode compatibility retention,
- and strict-mode expected rejection.

## Classification buckets

- `supported_smoke`: the asset is counted as supported for the bounded coverage
  actually exercised by the regression suite.
- `expected_failure`: the asset is intentionally rejected, and the rejection is
  part of the supported contract.
- `legacy_out_of_scope`: the asset is retained as a known historical or
  exploratory input, but it does not count toward current support claims.

## Coverage buckets

- `direct_root_pipeline_cli`: the entry must compile through both the pipeline
  API and the CLI as a direct root.
- `composition_top_pipeline_cli`: the entry must compile through both the
  pipeline API and the CLI as a composition top, including its realized child
  path.
- `legacy_root_default_pipeline_cli`: the entry is retained as a compatibility
  asset and must still compile through both the pipeline API and the CLI in
  default mode.
- `legacy_section_default_pipeline_cli`: the entry is retained as a
  compatibility residue asset and must still compile through both the pipeline
  API and the CLI in default mode even though it is not part of the preferred
  authored surface.
- `legacy_child_root_default_pipeline_cli`: the entry is retained as a child-
  realization compatibility residue asset and must still compile through both
  the pipeline API and the CLI in default mode, including any extra source
  search roots needed to realize the child.
- `strict_root_rejection_pipeline_cli`: the entry is intentionally rejected in
  strict mode through both the pipeline API and the CLI, and that rejection is
  part of the supported contract.
- `strict_section_rejection_pipeline_cli`: the entry is intentionally rejected
  in strict mode through both the pipeline API and the CLI because it relies on
  compatibility residue at the section level, and that rejection is part of the
  supported contract.
- `strict_child_root_rejection_pipeline_cli`: the entry is intentionally
  rejected in strict mode through both the pipeline API and the CLI because it
  relies on compatibility residue at the generated-child source-root boundary,
  and that rejection is part of the supported contract.
- `language_contract_rejection_pipeline_cli`: the entry is intentionally
  rejected by the normal language-contract boundary through both the pipeline
  API and the CLI, and that rejection is part of the supported contract. This
  bucket now includes malformed `+size` entries and non-positive resolved
  `+size` expression widths, plus unresolved or non-scalar symbols inside
  `+size` expressions.
- `direct_generation_contract_rejection_pipeline_cli`: the entry is
  intentionally rejected by the normal direct-generation contract through both
  the pipeline API and the CLI after parsing succeeds but before HDL is emitted,
  and that rejection is part of the supported contract.
- `composition_contract_rejection_pipeline_cli`: the entry is intentionally
  rejected by the normal composition contract through both the pipeline API and
  the CLI, and that rejection is part of the supported contract. This bucket
  now covers missing external generated-child source lookup, missing external
  `?rtl` sidecar metadata, invalid `.rtlif` system-role directions, and
  duplicate `.rtlif` port declarations, unsupported `.rtlif` port types,
  invalid `.rtlif` port tokens, non-positive `.rtlif` port widths, missing
  `.rtlif` roots, empty `.rtlif` roots, unsupported nested `.rtlif` structures, and
  duplicate embedded `.rtlif` roots.

## Current named entries

| ID | File | Classification | Coverage |
| --- | --- | --- | --- |
| `protocol.apb_requester` | [fsm/apb_requester.fsm](/Users/richarddje/Documents/github/fsmgen/fsm/apb_requester.fsm) | `supported_smoke` | `direct_root_pipeline_cli` |
| `protocol.apb_completer` | [fsm/apb_completer.fsm](/Users/richarddje/Documents/github/fsmgen/fsm/apb_completer.fsm) | `supported_smoke` | `direct_root_pipeline_cli` |
| `protocol.amba_requester` | [fsm/amba_requester.fsm](/Users/richarddje/Documents/github/fsmgen/fsm/amba_requester.fsm) | `supported_smoke` | `direct_root_pipeline_cli` |
| `protocol.apb_tb` | [fsm/apb_tb.fsm](/Users/richarddje/Documents/github/fsmgen/fsm/apb_tb.fsm) | `supported_smoke` | `composition_top_pipeline_cli` |
| `feature.partial_lhs_with_size` | [t/corpus/partial_lhs_with_size.fsm](/Users/richarddje/Documents/github/fsmgen/t/corpus/partial_lhs_with_size.fsm) | `supported_smoke` | `direct_root_pipeline_cli` |
| `feature.partial_lhs_inferred_width` | [t/corpus/partial_lhs_inferred_width.fsm](/Users/richarddje/Documents/github/fsmgen/t/corpus/partial_lhs_inferred_width.fsm) | `supported_smoke` | `direct_root_pipeline_cli` |
| `feature.direct_rhs_concat_pack` | [t/corpus/direct_rhs_concat_pack.fsm](/Users/richarddje/Documents/github/fsmgen/t/corpus/direct_rhs_concat_pack.fsm) | `supported_smoke` | `direct_root_pipeline_cli` |
| `feature.direct_lhs_deconstruct_pack` | [t/corpus/direct_lhs_deconstruct_pack.fsm](/Users/richarddje/Documents/github/fsmgen/t/corpus/direct_lhs_deconstruct_pack.fsm) | `supported_smoke` | `direct_root_pipeline_cli` |
| `feature.direct_sreset_active_high` | [t/corpus/direct_sreset_active_high.fsm](/Users/richarddje/Documents/github/fsmgen/t/corpus/direct_sreset_active_high.fsm) | `supported_smoke` | `direct_root_pipeline_cli` |
| `feature.direct_areset_active_low` | [t/corpus/direct_areset_active_low.fsm](/Users/richarddje/Documents/github/fsmgen/t/corpus/direct_areset_active_low.fsm) | `supported_smoke` | `direct_root_pipeline_cli` |
| `feature.direct_canonical_init_directive` | [t/corpus/direct_canonical_init_directive.fsm](/Users/richarddje/Documents/github/fsmgen/t/corpus/direct_canonical_init_directive.fsm) | `supported_smoke` | `direct_root_pipeline_cli` |
| `feature.direct_size_expression_widths` | [t/corpus/direct_size_expression_widths.fsm](/Users/richarddje/Documents/github/fsmgen/t/corpus/direct_size_expression_widths.fsm) | `supported_smoke` | `direct_root_pipeline_cli` |
| `legacy.mipicsi2_txccore_ulp.default_compat` | [fsm/mipicsi2_txccore_ulp.fsm](/Users/richarddje/Documents/github/fsmgen/fsm/mipicsi2_txccore_ulp.fsm) | `legacy_out_of_scope` | `legacy_root_default_pipeline_cli` |
| `legacy.mipicsi2_txccore_ulp.strict_rejection` | [fsm/mipicsi2_txccore_ulp.fsm](/Users/richarddje/Documents/github/fsmgen/fsm/mipicsi2_txccore_ulp.fsm) | `expected_failure` | `strict_root_rejection_pipeline_cli` |
| `legacy.empty_size_noop.default_compat` | [t/corpus/legacy_empty_size_noop.fsm](/Users/richarddje/Documents/github/fsmgen/t/corpus/legacy_empty_size_noop.fsm) | `legacy_out_of_scope` | `legacy_section_default_pipeline_cli` |
| `legacy.empty_size_noop.strict_rejection` | [t/corpus/legacy_empty_size_noop.fsm](/Users/richarddje/Documents/github/fsmgen/t/corpus/legacy_empty_size_noop.fsm) | `expected_failure` | `strict_section_rejection_pipeline_cli` |
| `legacy.asreset_rstn.default_compat` | [t/corpus/legacy_asreset_rstn.fsm](/Users/richarddje/Documents/github/fsmgen/t/corpus/legacy_asreset_rstn.fsm) | `legacy_out_of_scope` | `legacy_section_default_pipeline_cli` |
| `legacy.asreset_rstn.strict_rejection` | [t/corpus/legacy_asreset_rstn.fsm](/Users/richarddje/Documents/github/fsmgen/t/corpus/legacy_asreset_rstn.fsm) | `expected_failure` | `strict_section_rejection_pipeline_cli` |
| `legacy.sreset_rstn.default_compat` | [t/corpus/legacy_sreset_rstn.fsm](/Users/richarddje/Documents/github/fsmgen/t/corpus/legacy_sreset_rstn.fsm) | `legacy_out_of_scope` | `legacy_section_default_pipeline_cli` |
| `legacy.sreset_rstn.strict_rejection` | [t/corpus/legacy_sreset_rstn.fsm](/Users/richarddje/Documents/github/fsmgen/t/corpus/legacy_sreset_rstn.fsm) | `expected_failure` | `strict_section_rejection_pipeline_cli` |
| `legacy.compact_init_directive.default_compat` | [t/corpus/legacy_compact_init_directive.fsm](/Users/richarddje/Documents/github/fsmgen/t/corpus/legacy_compact_init_directive.fsm) | `legacy_out_of_scope` | `legacy_section_default_pipeline_cli` |
| `legacy.compact_init_directive.strict_rejection` | [t/corpus/legacy_compact_init_directive.fsm](/Users/richarddje/Documents/github/fsmgen/t/corpus/legacy_compact_init_directive.fsm) | `expected_failure` | `strict_section_rejection_pipeline_cli` |
| `legacy.fsm_child_root.default_compat` | [t/corpus/legacy_fsm_child_root_top.fsm](/Users/richarddje/Documents/github/fsmgen/t/corpus/legacy_fsm_child_root_top.fsm) | `legacy_out_of_scope` | `legacy_child_root_default_pipeline_cli` |
| `legacy.fsm_child_root.strict_rejection` | [t/corpus/legacy_fsm_child_root_top.fsm](/Users/richarddje/Documents/github/fsmgen/t/corpus/legacy_fsm_child_root_top.fsm) | `expected_failure` | `strict_child_root_rejection_pipeline_cli` |
| `legacy.dt_child_root.default_compat` | [t/corpus/legacy_dt_child_root_top.fsm](/Users/richarddje/Documents/github/fsmgen/t/corpus/legacy_dt_child_root_top.fsm) | `legacy_out_of_scope` | `legacy_child_root_default_pipeline_cli` |
| `legacy.dt_child_root.strict_rejection` | [t/corpus/legacy_dt_child_root_top.fsm](/Users/richarddje/Documents/github/fsmgen/t/corpus/legacy_dt_child_root_top.fsm) | `expected_failure` | `strict_child_root_rejection_pipeline_cli` |
| `contract.language_contract_bad_size_entry` | [t/corpus/language_contract_bad_size_entry.fsm](/Users/richarddje/Documents/github/fsmgen/t/corpus/language_contract_bad_size_entry.fsm) | `expected_failure` | `language_contract_rejection_pipeline_cli` |
| `contract.direct_size_expression_non_positive` | [t/corpus/direct_size_expression_non_positive.fsm](/Users/richarddje/Documents/github/fsmgen/t/corpus/direct_size_expression_non_positive.fsm) | `expected_failure` | `language_contract_rejection_pipeline_cli` |
| `contract.direct_size_expression_unknown_symbol` | [t/corpus/direct_size_expression_unknown_symbol.fsm](/Users/richarddje/Documents/github/fsmgen/t/corpus/direct_size_expression_unknown_symbol.fsm) | `expected_failure` | `language_contract_rejection_pipeline_cli` |
| `contract.direct_size_expression_aggregate_symbol` | [t/corpus/direct_size_expression_aggregate_symbol.fsm](/Users/richarddje/Documents/github/fsmgen/t/corpus/direct_size_expression_aggregate_symbol.fsm) | `expected_failure` | `language_contract_rejection_pipeline_cli` |
| `contract.direct_lhs_deconstruct_width_mismatch` | [t/corpus/direct_lhs_deconstruct_width_mismatch.fsm](/Users/richarddje/Documents/github/fsmgen/t/corpus/direct_lhs_deconstruct_width_mismatch.fsm) | `expected_failure` | `language_contract_rejection_pipeline_cli` |
| `contract.direct_rhs_concat_width_mismatch` | [t/corpus/direct_rhs_concat_width_mismatch.fsm](/Users/richarddje/Documents/github/fsmgen/t/corpus/direct_rhs_concat_width_mismatch.fsm) | `expected_failure` | `direct_generation_contract_rejection_pipeline_cli` |
| `contract.direct_aggregate_contract_mismatch` | [t/corpus/direct_aggregate_contract_mismatch.fsm](/Users/richarddje/Documents/github/fsmgen/t/corpus/direct_aggregate_contract_mismatch.fsm) | `expected_failure` | `direct_generation_contract_rejection_pipeline_cli` |
| `contract.missing_rtl_metadata_sidecar` | [t/corpus/missing_rtl_metadata_top.fsm](/Users/richarddje/Documents/github/fsmgen/t/corpus/missing_rtl_metadata_top.fsm) | `expected_failure` | `composition_contract_rejection_pipeline_cli` |
| `contract.missing_fsm_child_source` | [t/corpus/missing_fsm_child_source_top.fsm](/Users/richarddje/Documents/github/fsmgen/t/corpus/missing_fsm_child_source_top.fsm) | `expected_failure` | `composition_contract_rejection_pipeline_cli` |
| `contract.missing_dt_child_source` | [t/corpus/missing_dt_child_source_top.fsm](/Users/richarddje/Documents/github/fsmgen/t/corpus/missing_dt_child_source_top.fsm) | `expected_failure` | `composition_contract_rejection_pipeline_cli` |
| `contract.invalid_rtl_system_port_direction` | [t/corpus/invalid_rtl_system_direction_top.fsm](/Users/richarddje/Documents/github/fsmgen/t/corpus/invalid_rtl_system_direction_top.fsm) | `expected_failure` | `composition_contract_rejection_pipeline_cli` |
| `contract.duplicate_rtlif_port_declaration` | [t/corpus/duplicate_rtlif_port_top.fsm](/Users/richarddje/Documents/github/fsmgen/t/corpus/duplicate_rtlif_port_top.fsm) | `expected_failure` | `composition_contract_rejection_pipeline_cli` |
| `contract.invalid_rtlif_port_type` | [t/corpus/invalid_rtlif_port_type_top.fsm](/Users/richarddje/Documents/github/fsmgen/t/corpus/invalid_rtlif_port_type_top.fsm) | `expected_failure` | `composition_contract_rejection_pipeline_cli` |
| `contract.invalid_rtlif_port_token` | [t/corpus/invalid_rtlif_port_token_top.fsm](/Users/richarddje/Documents/github/fsmgen/t/corpus/invalid_rtlif_port_token_top.fsm) | `expected_failure` | `composition_contract_rejection_pipeline_cli` |
| `contract.invalid_rtlif_port_width` | [t/corpus/invalid_rtlif_port_width_top.fsm](/Users/richarddje/Documents/github/fsmgen/t/corpus/invalid_rtlif_port_width_top.fsm) | `expected_failure` | `composition_contract_rejection_pipeline_cli` |
| `contract.missing_rtlif_root` | [t/corpus/missing_rtlif_root_top.fsm](/Users/richarddje/Documents/github/fsmgen/t/corpus/missing_rtlif_root_top.fsm) | `expected_failure` | `composition_contract_rejection_pipeline_cli` |
| `contract.empty_rtlif_port_declaration` | [t/corpus/empty_rtlif_port_top.fsm](/Users/richarddje/Documents/github/fsmgen/t/corpus/empty_rtlif_port_top.fsm) | `expected_failure` | `composition_contract_rejection_pipeline_cli` |
| `contract.nested_rtlif_port_declaration` | [t/corpus/nested_rtlif_port_top.fsm](/Users/richarddje/Documents/github/fsmgen/t/corpus/nested_rtlif_port_top.fsm) | `expected_failure` | `composition_contract_rejection_pipeline_cli` |
| `contract.duplicate_embedded_rtlif_root` | [t/corpus/duplicate_embedded_rtlif_top.fsm](/Users/richarddje/Documents/github/fsmgen/t/corpus/duplicate_embedded_rtlif_top.fsm) | `expected_failure` | `composition_contract_rejection_pipeline_cli` |

## Current locking tests

- [t/247-protocol-fixture-regression-smoke.t](/Users/richarddje/Documents/github/fsmgen/t/247-protocol-fixture-regression-smoke.t)
  executes the first named protocol slice through pipeline and CLI.
- [t/261-regression-corpus-supported-language-features.t](/Users/richarddje/Documents/github/fsmgen/t/261-regression-corpus-supported-language-features.t)
  executes the named supported language-feature entries through pipeline and
  CLI, and keeps specific HDL-shape expectations instead of compile smoke
  only. The `feature.direct_size_expression_widths` entry now specifically
  proves that direct `+size` expressions support constants, enums, params,
  aggregate scalar leaves, bitwise aliases, `0d` decimal terms, signed based
  negative terms, and unsized based literals before HDL generation.
- [t/248-regression-corpus-accounting.t](/Users/richarddje/Documents/github/fsmgen/t/248-regression-corpus-accounting.t)
  checks that the catalog stays named, classified, unique, and pointed at real
  repo assets.
- [t/249-regression-corpus-classified-behavior.t](/Users/richarddje/Documents/github/fsmgen/t/249-regression-corpus-classified-behavior.t)
  checks that the current `legacy_out_of_scope` entries and the current
  `expected_failure` entries actually behave according to their recorded
  contract, including child-root compatibility residue that depends on explicit
  search-path realization.

## Working rule

Imported/example assets become part of FSMGen's support story only after they
appear in the maintained regression corpus with an explicit classification and
live automated coverage.
