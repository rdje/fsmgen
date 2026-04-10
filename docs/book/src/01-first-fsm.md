# Your First FSM

This chapter gets you from zero to a generated HDL file quickly.

## Minimal CLI Shape

From repository root:

```bash
./bin/fsmgen [options] <fsm_file>
```

Useful first commands:

```bash
./bin/fsmgen fsm/trial_0.fsm
./bin/fsmgen --output /tmp/trial_0.sv fsm/trial_0.fsm
./bin/fsmgen --debug=3 fsm/lte_dif_pmaster.fsm
```

## A Small First FSM

```lisp
(?fsm:counter_demo
  (+system
    (clock clk)
    (sreset reset)
  )
  (+size
    (start 1)
    (done 1)
    (count 8)
  )
  (idle
    (<start
      (count <- 0)
      (done = 0)
      (-> run)
    )
  )
  (run
    (count <- (+ count 1))
    (<count=8'd15
      (done = 1)
      (-> idle)
    )
  )
)
```

This shows the core ideas:

- `?fsm:name` declares one FSM root
- `+system` declares clock/reset convention; `(sreset reset)` is synchronous active-high
- `+size` declares signal widths
- states such as `idle` and `run` contain assignments and transitions
- `<...` guards gate actions

## Reset Naming

FSMGen treats reset kind and polarity as intent:

- `(sreset reset)` means synchronous active-high reset
- `(areset rst_n)` means asynchronous active-low reset
- names ending in `_n` or `n` should be reserved for active-low reset signals

Default mode still accepts some older compatibility spellings, but strict mode
rejects misleading combinations such as `(sreset rstn)`.

## What To Expect In The Output

The generated HDL is currently flattened for FSM/DT lowering. That means the
output emphasizes:

- explicit state registers,
- explicit enable logic,
- explicit mux/default behavior,
- and predictable generated names.

That flattening is intentional today because it is easier to debug and easier
to regression-lock.

## First Debug Loop

When something looks wrong:

```bash
./bin/fsmgen --trace-verbosity=debug --trace-log=trace.log \
  --output /tmp/counter_demo.sv \
  path/to/counter_demo.fsm
```

Then inspect:

- `trace.log`
- the emitted `.sv`
- any failure summary on the CLI

## Current Boundary For This Chapter

This first chapter stays on:

- one direct `?fsm` root,
- explicit `+system`,
- explicit `+size`,
- normal state blocks,
- simple guards and transitions.

For deeper syntax, continue with [Language Basics](02-language-basics.md) and
[Decision Trees and FSMs](03-decision-trees-and-fsms.md).
