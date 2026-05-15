# Composition Legacy Mapping

This note records how the obsolete `fx/bin/fsmgen` composition flow worked and how that historical behavior maps into the active `R6` plan.

It is context only.

The active source of truth remains:
- [docs/COMPOSITION_SCOPE.md](docs/COMPOSITION_SCOPE.md)
- [ROADMAP_STATUS.md](ROADMAP_STATUS.md)

## Why this note exists
- The legacy tool already had a real composition path.
- That historical path helps explain the intended language concepts.
- The implementation technique used there is not acceptable as the active architecture.

So the useful question is not “how do we copy the old code?”, but:
- which language ideas survive,
- which behaviors should be narrowed,
- and which mechanisms must be retired.

## Legacy call tree
The legacy composition entrypath was:

- [fx/bin/fsmgen](fx/bin/fsmgen)
  - CLI argument parsing only
- [fx/perl/FSMGen.pm](fx/perl/FSMGen.pm) `start_from_file(...)`
  - loads Lispish ASTs
  - classifies `?define:*`, `?fsm:*`, and `?top:*`
  - calls `top_exec(...)` for each top-level `?top:*`

The key historical point is that the old tool did already have a separate composition lane.

## What `top_exec(...)` actually did
In [fx/perl/FSMGen.pm](fx/perl/FSMGen.pm), `top_exec(...)` recursively handled:

- `?fsmc`
  - compile child FSM content through the old FSM path
- `?rtl`
  - bind an external RTL module and load its interface
- `?ports`
  - describe interface/port objects
- `?wiring`
  - reuse/remap another top-level interface
- nested `?top`
  - recursively build more hierarchy

It then inferred:
- top-level ports,
- internal signals,
- some signal assignments,
- instance declarations,
- and architecture/plugin emission steps.

## Legacy mechanisms we should not reproduce
The old composition system depended heavily on dynamic dispatch through:

- [fx/perl/FSMGen.pm](fx/perl/FSMGen.pm) `AUTOLOAD`
- [fx/perl/PPlugin.pm](fx/perl/PPlugin.pm)
- [fx/plugin/fsmgen.plg](fx/plugin/fsmgen.plg)

That means many composition helpers were not normal typed code paths at all. They were plugin/eval-resolved helpers such as:

- `interface_objects`
- `map_objects`
- `generic_objects`
- `portlist_2hash`
- `portlist_2force`
- `getop_plugin_list`

The old top-emission flow also exposed dynamic architecture phases:

- `cclausearch`
- `declarch`
- `beginarch`
- `endarch`
- `endtop`

These are historical evidence of extension points, not the model for the active implementation.

## Legacy concepts that do survive into `R6`
These historical concepts are still useful and are already reflected in the scoped modern plan:

- `?top:name`
  - composition root
- `?fsmc`
  - child FSM instance that should reuse the active FSM pipeline
- `?rtl`
  - external RTL instance with a declared interface
- `?ports`
  - explicit interface declaration surface
- `?wiring`
  - connectivity/wiring concept between composition-level endpoints

So the language ideas survive, but the implementation must be typed and deterministic.

## Historical behaviors the active architecture narrows on purpose
### 1. Legacy inline top-port shorthand
Legacy `?top:name` forms often carried direct scalar interface items after the top header.

Example shape:
```lisp
(?top:foo clk rstn data>8 ...)
```

Active `R6` direction:
- reject this shorthand in the first lane,
- require explicit `?ports` blocks instead.

Reason:
- explicit blocks are easier to type, validate, and test.

### 2. Multi-source `?fsmc`
Legacy `?fsmc` could carry more than one FSM source name and route them through old hierarchy-specific behavior.

Active `R6` direction:
- the first lane supports exactly one FSM source per child instance.

Reason:
- this keeps child realization deterministic and aligned with the current single-FSM pipeline.

### 3. Nested `?top`
Legacy `top_exec(...)` recursively processed nested `?top` blocks.

Active `R6` direction:
- the first lane does not support nested `?top` blocks.

Reason:
- the first active composition lane is intentionally flat and bounded.

### 4. Broad connect-by-name inference
Legacy top building inferred many top ports/signals from child directionality and shared names.

Active `R6` direction:
- explicit wiring first,
- connect-by-name only when declared and unambiguous.
- the shipped modern `C4` slice narrows that further to top ports declared as
  compact `=name` or verbose `:same-name` inside `?ports`.

Reason:
- hidden inference is hard to validate and hard to make deterministic.

### 6. How `?rtl` interface loading is narrowed
Legacy `?rtl` loaded interface information through the old environment-specific entity/database path (`entity_loader(...)`) and then pushed that data through plugin-style port-mapping helpers.

Active modern direction, started in `R6` and widened in `R11`:
- keep `?rtl` as an external-interface binding concept,
- but load it from a typed sidecar metadata artifact (`<module>.rtlif`) during composition planning,
- allow the modern `(?rtl:instance module)` form when one declared RTL module/interface contract must be instantiated several times under distinct instance names,
- allow bounded scalar and aggregate `.rtlif` parameter/generic declarations whose defaults may use package-qualified shared symbols, bounded scalar expressions, and matching-shape leafwise aggregate expressions, plus resolved composition-top/package-symbol per-instance `?rtl` `(params (NAME value) ...)` override blocks that are name-validated and aggregate-shape-validated before target lowering,
- allow bounded generated-child `?fsmc` / `?dtc` `(params (NAME value) ...)` override blocks that target direct child-source `(+params ...)` declarations, resolve the same composition-top/package symbols, and validate aggregate shape before target lowering,
- allow `.rtlif` interface ports to be authored as compact tokens such as
  `core_clk:clock` / `data_in<8:data` / `txd>:data` or as verbose declarations
  such as `(input core_clk :clock)`, `(input data_in (width 8) :data)`, and
  `(output txd :data)`,
- treat typed `.rtlif` `clock` and `reset` categories as system-input roles rather than HDL data types, so output-direction system-role tokens and verbose output-role declarations are rejected while ordinary `data` outputs remain valid,
- do not parse or regenerate the external RTL child at this composition layer,
- and keep VHDL generic-map lowering plus richer expression domains beyond the shipped bounded scalar-expression and leafwise aggregate-expression slices as future semantic follow-ups rather than reviving raw legacy template/plugin parameter passing.

Reason:
- this preserves the real composition need, interface-aware wiring and validation,
- without reviving environment-specific DB loaders, `AUTOLOAD`, or plugin/eval dispatch.

### 5. Plugin-driven architecture mutation
Legacy composition emission used plugin callbacks to mutate architecture output late in the process.

Active `R6` direction:
- do not revive `.plg` / `PPlugin` behavior for composition,
- keep extension redesign in `R7`.

Reason:
- `R6` is about a typed composition model, not about reintroducing eval/plugin architecture.

## Practical mapping from legacy terms to active typed work
- Legacy `?top:name`
  - modern `CompositionTop`
- Legacy `?fsmc`
  - modern typed child instance referencing one FSM source
- Legacy `?rtl`
  - modern typed external RTL instance
- Legacy `?ports`
  - modern typed interface declaration block
- Legacy `?wiring`
  - modern typed connectivity/link block

The exact package names may evolve, but the active design direction is:
- typed IR first,
- child realization second,
- top planning/emission after that.

## Current active conclusion
The legacy pass confirms that `R6` is the right roadmap lane and that the scoped source model is historically grounded.

It also confirms the main discipline we need to keep:
- inherit the concepts,
- not the plugin/eval machinery.
