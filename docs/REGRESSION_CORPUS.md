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
- `strict_root_rejection_pipeline_cli`: the entry is intentionally rejected in
  strict mode through both the pipeline API and the CLI, and that rejection is
  part of the supported contract.
- `language_contract_rejection_pipeline_cli`: the entry is intentionally
  rejected by the normal language-contract boundary through both the pipeline
  API and the CLI, and that rejection is part of the supported contract.

## Current named entries

| ID | File | Classification | Coverage |
| --- | --- | --- | --- |
| `protocol.apb_requester` | [fsm/apb_requester.fsm](/Users/richarddje/Documents/github/fsmgen/fsm/apb_requester.fsm) | `supported_smoke` | `direct_root_pipeline_cli` |
| `protocol.apb_completer` | [fsm/apb_completer.fsm](/Users/richarddje/Documents/github/fsmgen/fsm/apb_completer.fsm) | `supported_smoke` | `direct_root_pipeline_cli` |
| `protocol.amba_requester` | [fsm/amba_requester.fsm](/Users/richarddje/Documents/github/fsmgen/fsm/amba_requester.fsm) | `supported_smoke` | `direct_root_pipeline_cli` |
| `protocol.apb_tb` | [fsm/apb_tb.fsm](/Users/richarddje/Documents/github/fsmgen/fsm/apb_tb.fsm) | `supported_smoke` | `composition_top_pipeline_cli` |
| `legacy.mipicsi2_txccore_ulp.default_compat` | [fsm/mipicsi2_txccore_ulp.fsm](/Users/richarddje/Documents/github/fsmgen/fsm/mipicsi2_txccore_ulp.fsm) | `legacy_out_of_scope` | `legacy_root_default_pipeline_cli` |
| `legacy.mipicsi2_txccore_ulp.strict_rejection` | [fsm/mipicsi2_txccore_ulp.fsm](/Users/richarddje/Documents/github/fsmgen/fsm/mipicsi2_txccore_ulp.fsm) | `expected_failure` | `strict_root_rejection_pipeline_cli` |
| `contract.language_contract_bad_size_entry` | [t/corpus/language_contract_bad_size_entry.fsm](/Users/richarddje/Documents/github/fsmgen/t/corpus/language_contract_bad_size_entry.fsm) | `expected_failure` | `language_contract_rejection_pipeline_cli` |

## Current locking tests

- [t/247-protocol-fixture-regression-smoke.t](/Users/richarddje/Documents/github/fsmgen/t/247-protocol-fixture-regression-smoke.t)
  executes the first named protocol slice through pipeline and CLI.
- [t/248-regression-corpus-accounting.t](/Users/richarddje/Documents/github/fsmgen/t/248-regression-corpus-accounting.t)
  checks that the catalog stays named, classified, unique, and pointed at real
  repo assets.
- [t/249-regression-corpus-classified-behavior.t](/Users/richarddje/Documents/github/fsmgen/t/249-regression-corpus-classified-behavior.t)
  checks that the first `legacy_out_of_scope` and the first two
  `expected_failure` entries actually behave according to their recorded
  contract.

## Working rule

Imported/example assets become part of FSMGen's support story only after they
appear in the maintained regression corpus with an explicit classification and
live automated coverage.
