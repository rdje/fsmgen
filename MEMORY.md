# MEMORY — pointer to the frontier (layer A; state only, overwrite-only)

Pointer only — decisions `0067` and `0068`. Evidence: `docs/tasks/`.
Read `README.md` and `MEMORY_ARCHITECTURE.md`; decisions: `docs/decisions/`.

## Resume

- repository_revision: derive with `git log -1 --format='%H %s'`; never shadow `HEAD` here.
- active_work_unit: `PUBLICATION-REGRESSION-REPAIRS.40`
- next_action: Finish readiness commit if pending. Bind actual clean HEAD/runtime and
  small readiness tail in publication-split-runtime-20261103; inspect remote upload ref
  plus per-piece state/log/receipt before running the next unspent worker slot. After24
  prefixes, normal main push/all exact-SHA hosted/Pages, owned-ref cleanup and pause.
- in_flight_uncommitted: Derive with git status --short.
- in_flight_background: Derive publication-upload-piece-*.state.json under
  .artifacts/push-readiness-20261025; failed single-pack and census outcomes consumed.
- blockers: Bounded history transport pending; critical local code qualified. No full-local
  retry. Keep500 cadence (director confirmed),88/4096 and immutable history.
  Honor pause after final publication before macOS/width/other work; P2 .39 follows
  resume and boundary waves remain discussion only.
