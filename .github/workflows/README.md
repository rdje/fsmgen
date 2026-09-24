# GitHub Workflows

## Regression CI

`regression.yml` runs on `main` pushes, pull requests, and manual dispatch.
Seven required families cover doctrine, mdBook, 16 ordinary Perl shards, five
dedicated tests, 64 corpus-entry shards, 68 dynamic cases, and one unsharded
VIAL gate. All four matrices disable fail-fast; long jobs have a five-hour
ceiling; final `build` requires every family.

Ordinary shards partition every tracked `t/*.t` except ten separately owned
tests. Dedicated coordinates are `t/1436`, `t/1437`, `t/1598`, `t/1648`, and
`t/1650`; `t/296`, `t/301`, `t/303`, and `t/1884` each have 16 entry shards; `t/1438`
has 68 case jobs. T1183 locks the complete disjoint inventory.
Full CI and hosted T1884 force all-source selection, refusing ambient filters,
list-only mode or shard coordinates before dispatch. T1885's bounded semantic
and refusal controls stay ordinary.

Ordinary jobs pin Ubuntu 24.04 plus Icarus 12.0-2build2, Verilator 5.020-1,
and Yosys 0.33-5build2 and fetch full history. Dedicated t1436 retains its
Verilator/Yosys pair. Dedicated t1598/t1648/t1650 recursively materialize
OSVVM 2026.05 at `2f7c391051dfb11890fa4bdbda9918d1db492250`. Corpus and
dynamic jobs remain shallow and Perl-only. All project data stays in the job's
repository-local paths; these dependencies do not change public support.

The VIAL family pins Ubuntu 24.04 and Perl 5.32, installs no HDL runtime, and
rejects ambient Verilator or fixed GHDL 6.0.0 coordinates. It materializes the
exact OSVVM commit, calls `./bin/ci-regression vial-gate --no-book`, and runs a
guarded independent verifier requiring eight informational profiles, three
unavailable-not-pass profiles, and 11/33/44 required versus 8/24/32 observed
records. Always-cleanup removes its exact evidence, provider, result, and stage.
This configures CI; it is not a completed hosted performance/support result.

Hosted tests use repository shard options with `full --no-book`; one job owns
mdBook. Local `./bin/ci-regression` retains the unsharded pre-push gate and book.
Actions use immutable Node 24 pins and exact local mdBook 0.5.4; no insecure
Node fallback is enabled.

## GitHub Pages

`pages.yml` builds `docs/book`, uploads `docs/book/book`, and runs on `main`
pushes or manual dispatch.

Repository settings must select GitHub Actions as the Pages source.
