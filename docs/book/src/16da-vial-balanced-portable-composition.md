# Balanced Portable Composition

The balanced portable workload is qualification infrastructure for proving that
the six orthogonal VIAL architecture-scale families compose correctly. It is
not a public fixture-building API, supported-capacity promise, performance
result, or runtime result. Decision `0077` gives it a dedicated caller-sealed
revision-2 bridge instead of weakening either the public AHB bridge or the
private-nonportable revision-1 scale route.

## Closed construction boundary

`FSM::VIAL::ArchitectureScaleBalancedPortable` owns the only canonical
composer. `construct` accepts the frozen checked-AHB HIAL and VIAL texts,
verifies their complete byte identities, and generates one ordinary
repository-relative `.isf`/`.vial` pair. A caller cannot supply SemanticIR, a
bridge manifest, ExecutionIR, a plan, gate reports, or requested counts.

`build` evaluates a fresh substantive gate from each completed family before
the balanced route becomes reachable:

- semantic catalog: the 32-record-field gate;
- bridge fanout: the 256-endpoint, one-unit/one-domain gate;
- execution graph: the 2,048-binding gate;
- checking state: the 1,024-occurrence generated/replayed gate;
- backend emission: the portable-SystemVerilog artifact-graph gate; and
- runtime stream: the 10,000-record provider-free input gate.

Each full report must match its closed family, axis, level, schema, successful
status, empty diagnostics, and family-specific semantic oracle. The composer
stores the report digest and selected projection; it never accepts cached or
injected evidence. After those prerequisites pass, the private route parses and
lowers HIAL, parses VIAL, uses the revision-2 bridge, binds ExecutionIR, and
constructs the target-neutral plan.

## Exact interaction proof

`evaluate` rebuilds each canonical stage twice and compares complete stage
bytes. It then creates a strict replay manifest for every keyed choice, rebuilds
the route a third time, normalizes only the generated/replayed origin marker,
and requires plan equality.

The report derives this complete vector from the produced bridge, ExecutionIR,
and plan rather than copying the catalog request:

| Resource | Derived value |
| --- | ---: |
| selected units / domains | 1 / 1 |
| endpoints / events / probes | 128 / 128 / 32 |
| transactions / fields | 16 / 1,744 (109 each) |
| scenarios / operations | 32 / 1,024 |
| total / simultaneously live fibers | 128 / 32 |
| bindings / execution types | 2,048 / 512 |
| models / scalar cells | 32 / 512 |
| scoreboards / total declared capacity | 32 / 4,096 |
| coverpoints / authored bins | 256 / 4,096 |
| faults / keyed random occurrences | 32 / 1,024 |

The binding equation is `1 unit + 1 domain + 126 data endpoints + 32 probes +
16 aliases + 1,744 fields + 128 events = 2,048`. Every field is backed by a
real endpoint; there are no event-input, adapter-state, comment, path, or opaque
padding bindings.

Count equality alone is insufficient. The evaluator also verifies:

- `drive → sample → react → check` logical-time order and the exact stable
  tie-break fields;
- per-scenario fiber counts `32, 4, 4, 4, then 3 × 28` and operation counts
  `60, 32, 32, 32, then 31 × 28`;
- 32 sixteen-cell models with exercised increment assignments;
- 32 capacity-128 scoreboards with expect/start/check structure;
- 256 coverpoints with sixteen authored bins each and 32 one-cycle faults; and
- 1,024 unique `sha256_counter_rejection_v1` occurrences, 32 per scenario,
  with normalized generated/replayed plan equality.

## Repository-root example

Run this diagnostic from the repository root. It supplies no intermediate
evidence and therefore exercises the same closed composition boundary as the
qualification watcher:

```perl
use strict;
use warnings;
use FSM::VIAL::ArchitectureScaleBalancedPortable;

sub read_raw {
    my ($path) = @_;
    open my $fh, '<:raw', $path or die "cannot read $path: $!";
    local $/;
    return <$fh>;
}

my $class = 'FSM::VIAL::ArchitectureScaleBalancedPortable';
my $construction = $class->construct({
    reference_hial_text => read_raw('ppif/ahb_lite_subordinate.ppif'),
    reference_vial_text =>
        read_raw('vial/ahb_subordinate_base_output_arbitration.vial'),
});
my $report = $class->evaluate({construction => $construction});
die "balanced composition rejected\n" unless $report->{ok};

printf "endpoints=%d transactions=%d fields/transaction=%d bindings=%d\n",
    $report->{metrics}{endpoints},
    $report->{metrics}{transactions},
    $report->{metrics}{fields_per_transaction}[0],
    $report->{metrics}{bindings};
```

Run it as `perl -Iperl example.pl` if saved as `example.pl`. The output is:

```text
endpoints=128 transactions=16 fields/transaction=109 bindings=2048
```

`validate_report` does not merely check the report's shape or digest. It
defensively regenerates the complete evaluation and accepts only canonical byte
equality. Direct calls to the private canonical route, bridge seal, or execution
seal fail. `with_staging` delegates to the repository-local scale staging
contract, verifies same-volume placement, sanitizes consumer failures, and
removes the exact staging tree after success or failure.

Focused `t/1653-vial-balanced-portable-composition.t` is the durability and
falsification watcher. It rejects source/report mutation, gate injection,
private-route borrowing, and machine-local residue. The guarded nine-file
family matrix independently re-derives the six prerequisites and complete
composition together.

## Deliberate nonclaims

This slice ends at target-neutral plan construction. Portable-SystemVerilog
emission remains separately owned by `.17.2.7.2.4`, which must negotiate the
complete revision-2 bridge and ExecutionIR shape rather than trusting a
capability label. No external compiler or runtime executes here. Public
planning, other backends, support, performance, capacity, and reached-boundary
claims remain unchanged.
