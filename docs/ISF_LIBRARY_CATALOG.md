# ISF Library Catalog

This is the live catalog of reusable ISF definitions that are shipped in this
repository. It is a companion to the ISF public interface contract, not a
replacement for the syntax specification.

The machine-readable public contract advertises this file through
`library_catalog_paths`, advertises the expected entry fields through
`library_catalog_entry_keys`, and exposes the current shipped entries through
`shipped_library_definitions`. Keep this catalog, the source fixtures, the
mdBook, and the contract metadata synchronized in the same slice whenever a
definition is added, removed, or materially changed.

## Catalog Policy

An entry may be marked `shipped` only when all of these are true:

- The reusable source lives in the repository and is importable through the
  public `(library ...)`, `(imports ...)`, and `(use ...)` surface.
- Lowering emits reviewable scheduled `.fsm` artifacts or fails closed with
  targeted diagnostics.
- Schedule reports expose bounded provenance for the reusable use.
- The generated HDL path is proven for at least one realistic importing
  fixture when the reusable definition is intended for HDL generation.
- Parameters, public interface, internal storage, runtime semantics, tests,
  and limitations are recorded here.

Catalog entries use the same public fields advertised by
`library_catalog_entry_keys`: `qualified_name`, `library`, `export`, `kind`,
`status`, `source`, `import_fixture`, `parameters`, `interface`, `storage`,
`semantics`, `tests`, and `limitations`.

## Shipped Definitions

| Qualified name | Kind | Status | Source | Import fixture |
| --- | --- | --- | --- | --- |
| `common.fifo.fifo` | `actor` | `shipped` | [isf/common/fifo.isf](../isf/common/fifo.isf) | [isf/fifo_library_use.isf](../isf/fifo_library_use.isf) |

### `common.fifo.fifo`

`common.fifo.fifo` is the first reusable FIFO actor library fixture. It is a
fixed-shape depth-4 FIFO actor, not a depth-1 placeholder or a transaction-only
abstraction. The actor owns its storage, pointers, occupancy, flags, reset
policy, and public FIFO interface behavior.

Public identity:

- `qualified_name`: `common.fifo.fifo`
- `library`: `common.fifo`
- `export`: `fifo`
- `kind`: `actor`
- `status`: `shipped`
- `source`: [isf/common/fifo.isf](../isf/common/fifo.isf)
- `import_fixture`: [isf/fifo_library_use.isf](../isf/fifo_library_use.isf)

Parameters:

| Name | Value | Current meaning |
| --- | --- | --- |
| `DATA_WIDTH` | `8` | Public data input/output width for this fixed fixture. |
| `DEPTH` | `4` | Number of modeled FIFO entries. |
| `PTR_WIDTH` | `2` | Width of `wr_ptr` and `rd_ptr` for entry wrap. |
| `OCC_WIDTH` | `3` | Width of `occupancy`, covering values 0 through 4. |

These parameters are shipped as provenance and use-site binding evidence. They
do not yet drive generic interface or storage elaboration.

Public interface:

| Direction | Name | Width | Meaning |
| --- | --- | --- | --- |
| input | `write_req` | `1` | Push request. |
| input | `data_in` | `8` | Push data. |
| input | `read_req` | `1` | Pop request. |
| output | `full` | `1` | Actor-maintained full flag. |
| output | `empty` | `1` | Actor-maintained empty flag. |
| output | `data_out` | `8` | Pop data. |

Internal storage:

| Name | Kind | Width | Depth | Meaning |
| --- | --- | --- | --- | --- |
| `wr_ptr` | `var` | `2` | n/a | Entry selected by the next accepted push. |
| `rd_ptr` | `var` | `2` | n/a | Entry selected by the next accepted pop. |
| `occupancy` | `var` | `3` | n/a | Number of occupied entries, 0 through 4. |
| `data` | `bank` | `8` | `4` | Scalarized FIFO data entries. |

Runtime semantics:

- `full` is maintained by the actor and is asserted when `occupancy == 4`.
- `empty` is maintained by the actor and is asserted when `occupancy == 0`.
- The actor covers all four request cases every cycle: no request, push-only,
  pop-only, and push-plus-pop.
- Push-only updates occupancy and `wr_ptr` when the FIFO is not full.
- Pop-only updates occupancy and `rd_ptr` when the FIFO is not empty.
- Push-plus-pop derives read-fire and write-fire behavior from the same
  pre-cycle state and updates both sides atomically for the cycle.
- `wr_ptr` and `rd_ptr` wrap from entry 3 back to entry 0.
- Bank access uses the shipped read-before-write policy: a same-cycle load
  observes the current entry value, while a store selects the next value.

Verification:

- [t/1237-isf-fifo-library-fixture.t](../t/1237-isf-fifo-library-fixture.t)
  proves file-backed import resolution, specialized child scheduled `.fsm`
  emission, generated top wiring, schedule-report `library_uses` metadata,
  and visible FIFO update artifacts.
- [t/1238-isf-fifo-library-hdl-generation.t](../t/1238-isf-fifo-library-hdl-generation.t)
  proves CLI generated-top SystemVerilog for the FIFO fixture, including
  fixed parameter bindings, scalarized data entries, and pointer-gated
  accepted push/pop selectors.
- [t/1239-isf-library-catalog-contract.t](../t/1239-isf-library-catalog-contract.t)
  keeps this catalog aligned with the machine-readable ISF public contract.

Limitations:

- The fixture is fixed to `DATA_WIDTH=8`, `DEPTH=4`, `PTR_WIDTH=2`, and
  `OCC_WIDTH=3`.
- Parameter-driven interface and storage elaboration is not shipped yet.
- The backend still emits scalarized bank entries, not a native memory-array
  FIFO storage primitive.
- Automatic non-zero reset values, such as reset-time `empty = 1`, are not
  shipped yet.
- Standalone transaction and drive exports are not shipped as reusable
  library definitions yet.
- Library actors that import other libraries are not shipped yet.
- Clock/reset name remapping at the use site is shipped for generated tops:
  differently named parent/child system signals are linked explicitly while
  the reusable actor keeps its reset kind and polarity. This is name remapping
  inside the current single-clock-domain ISF model, not multi-clock-domain
  behavior.
