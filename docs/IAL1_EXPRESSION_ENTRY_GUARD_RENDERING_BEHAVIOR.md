# IAL1 Expression Entry-Guard Rendering Behavior

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.561`

Date: 2026-06-26

## Outcome

`IAL2-FEATURE-COMPLETENESS-FRONTIER.561` repairs generated IAL1 lowering for a
transaction whose first clause is an expression activation guard:

```lisp
(when (& go (! busy))
  (sample din as hold))
```

Generated `.fsm` entry-state sample enables and the entry transition now use
rendered `.fsm` expression text:

```lisp
(<= (hold din) <(& go (! busy)))
(-> main_done_1 <(& go (! busy)))
```

The lowerer also keeps the structured expression AST in `expr_ast` for internal
condition-term analysis while storing the rendered expression in `expr` for the
`.fsm` emitter. Scalar entry guards remain unchanged and continue to emit
`<start`-style guards.

This is an IAL1 substrate repair only. It does not add APB `.ppif` completer
parser behavior, generator behavior, samples, support-accounting entries,
`.apb` widening, AXI behavior, APB requester-transfer behavior, direct backend
behavior, verification-output generation, backend-language variant behavior, or
VHDL behavior.

## APB Relevance

The selected future APB completer contract needs setup detection on
`PSEL && !PENABLE`, written in generated IAL1 as:

```lisp
(when (& PSEL (! PENABLE))
  (sample PADDR as addr)
  (sample PWRITE as write_q)
  (sample PWDATA as wdata_q)
  (sample wait_cycles as wait_n))
```

`.561` proves that the generated `.fsm` carries that guard on each setup sample
and the entry transition without leaking `ARRAY(...)` text. Direct APB
completer behavior is still deferred to the next task-tree owner.

## Validation

Focused validation passed:

```bash
perl -Iperl -c perl/FSM/Scheduler/ISF/LoweringIR.pm
perl -Iperl -c t/1100-isf-sample-piggyback.t
perl -Iperl -c t/1107-isf-when-body-ops.t
perl -Iperl -c t/1244-isf-wait-clause-lowering.t
prove -Iperl t/1100-isf-sample-piggyback.t
scripts/run_with_ram_guard.sh -- prove -Iperl t/1107-isf-when-body-ops.t t/1244-isf-wait-clause-lowering.t
```

The first unguarded `perl -c perl/FSM/Scheduler/ISF/LoweringIR.pm` attempt was
invalid because it omitted `-Iperl`; the corrected `perl -Iperl -c` syntax
check passed.

## Rollback

Rollback is localized to the entry-activation guard construction helper in
`FSM::Scheduler::ISF::LoweringIR` and the focused tests added to
`t/1100-isf-sample-piggyback.t`. Reverting this behavior reintroduces invalid
`ARRAY(...)` guard suffixes for expression entry activation and would block the
selected APB completer implementation again.
