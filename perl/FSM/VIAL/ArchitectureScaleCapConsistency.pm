package FSM::VIAL::ArchitectureScaleCapConsistency;

use v5.20;
use strict;
use warnings;

use Carp qw(confess);
use Scalar::Util qw(blessed);

use FSM::VIAL::ArchitectureScaleCapPolicy qw(
    build_architecture_scale_cap_policy
);

my $SCHEMA = 'fsmgen.vial_architecture_scale_cap_consistency.v1';
my $POLICY_BUILDER =
    'FSM::VIAL::ArchitectureScaleCapPolicy::build_architecture_scale_cap_policy';
my $CALIBRATION_AUTHORITY =
    'FSM::VIAL::ArchitectureScaleCalibrationClosurePublication';
my @DIMENSIONS = qw(
    boundary adjacent_excess diagnostics atomicity no_tool cleanup
    accepted_identity
);

# Later family-specific slices may promote one entry only after independently
# reviewing its evidence. An absent entry is deliberately visible as pending;
# policy citations are candidates, not dimension proof. Each promoted test is
# listed once with only the dimensions it proves, so the join remains auditable.
my @RUNTIME_EVIDENCE = (
    [
        't/1663-vial-architecture-scale-portable-runtime-materialization.t',
        qw(boundary adjacent_excess atomicity no_tool cleanup accepted_identity),
    ],
    [
        't/1672-vial-architecture-scale-portable-vhdl-runtime-materialization.t',
        qw(boundary adjacent_excess atomicity no_tool cleanup accepted_identity),
    ],
    [
        't/1676-vial-architecture-scale-osvvm-runtime-materialization.t',
        qw(boundary adjacent_excess atomicity no_tool cleanup accepted_identity),
    ],
    [
        't/1720-vial-runtime-structural-artifact-preflight.t',
        qw(adjacent_excess diagnostics atomicity no_tool),
    ],
    [
        't/1721-vial-runtime-trace-artifact-preflight.t',
        qw(boundary adjacent_excess diagnostics atomicity),
    ],
    [
        't/1722-vial-runtime-result-artifact-preflight.t',
        qw(boundary adjacent_excess diagnostics atomicity),
    ],
    [
        't/1723-vial-runtime-final-artifact-graph.t',
        qw(boundary adjacent_excess diagnostics atomicity),
    ],
    [
        't/1724-vial-runtime-process-envelope.t',
        qw(diagnostics atomicity cleanup),
    ],
    [
        't/1725-vial-ghdl-cleanup-diagnostic-authority.t',
        qw(diagnostics cleanup),
    ],
    [
        't/1726-vial-ghdl-admission-cleanup-evidence.t',
        qw(diagnostics cleanup),
    ],
    [
        't/1727-vial-ghdl-probe-timeout-diagnostic-authority.t',
        qw(diagnostics),
    ],
    [
        't/1728-vial-ghdl-probe-abort-cleanup-authority.t',
        qw(diagnostics cleanup),
    ],
    [
        't/1729-vial-ghdl-result-record-admission.t',
        qw(boundary adjacent_excess diagnostics accepted_identity),
    ],
    [
        't/1730-vial-ghdl-osvvm-provider-report-byte-preflight.t',
        qw(boundary adjacent_excess diagnostics atomicity),
    ],
    [
        't/1731-vial-ghdl-capture-evidence-admission.t',
        qw(accepted_identity),
    ],
    [
        't/1732-vial-ghdl-state-evidence-admission.t',
        qw(accepted_identity),
    ],
    [
        't/1733-vial-ghdl-terminal-payload-resume-admission.t',
        qw(accepted_identity),
    ],
    [
        't/1734-vial-verilator-terminal-resume-admission.t',
        qw(accepted_identity),
    ],
    [
        't/1735-vial-ghdl-authority-object-admission.t',
        qw(accepted_identity),
    ],
    [
        't/1736-vial-ghdl-object-descriptor-admission.t',
        qw(cleanup accepted_identity),
    ],
    [
        't/1737-vial-ghdl-state-owner-file-admission.t',
        qw(cleanup accepted_identity),
    ],
    [
        't/1738-vial-ghdl-handle-state-scalar-types.t',
        qw(cleanup accepted_identity),
    ],
    [
        't/1739-vial-ghdl-request-scalar-types.t',
        qw(cleanup accepted_identity),
    ],
    [
        't/1740-vial-osvvm-persisted-request-scalar-types.t',
        qw(accepted_identity),
    ],
    [
        't/1741-vial-osvvm-persisted-provider-admission.t',
        qw(accepted_identity),
    ],
    [
        't/1742-vial-osvvm-persisted-ghdl-provider-admission.t',
        qw(accepted_identity),
    ],
    [
        't/1743-vial-osvvm-persisted-emission-identity.t',
        qw(accepted_identity),
    ],
    [
        't/1744-vial-osvvm-persisted-command-authority.t',
        qw(atomicity accepted_identity),
    ],
    [
        't/1745-vial-osvvm-persisted-lifecycle-storage-admission.t',
        qw(atomicity accepted_identity),
    ],
    [
        't/1746-vial-osvvm-persisted-lifecycle-validation-admission.t',
        qw(atomicity accepted_identity),
    ],
    [
        't/1747-vial-osvvm-outer-persisted-json-file-admission.t',
        qw(atomicity cleanup accepted_identity),
    ],
    [
        't/1748-vial-common-worker-artifact-file-admission.t',
        qw(boundary adjacent_excess diagnostics cleanup accepted_identity),
    ],
    [
        't/1749-vial-common-worker-output-census-admission.t',
        qw(boundary adjacent_excess diagnostics atomicity cleanup),
    ],
    [
        't/1751-vial-common-interrupted-stage-census-admission.t',
        qw(boundary adjacent_excess diagnostics atomicity cleanup),
    ],
    [
        't/1752-vial-common-worker-process-group-containment.t',
        qw(diagnostics atomicity cleanup accepted_identity),
    ],
    [
        't/1753-vial-common-bounded-cleanup-admission.t',
        qw(boundary adjacent_excess diagnostics atomicity cleanup accepted_identity),
    ],
    [
        't/1754-vial-common-detached-descendant-containment.t',
        qw(diagnostics atomicity cleanup accepted_identity),
    ],
    [
        't/1755-vial-selected-tool-detached-descendant-containment.t',
        qw(diagnostics atomicity cleanup),
    ],
    [
        't/1756-vial-selected-tool-host-observer-deadline.t',
        qw(diagnostics atomicity cleanup),
    ],
    [
        't/1757-vial-selected-tool-monotonic-containment.t',
        qw(diagnostics atomicity cleanup),
    ],
    [
        't/1758-vial-selected-tool-bounded-leader-reap.t',
        qw(diagnostics atomicity cleanup),
    ],
    [
        't/1759-vial-selected-tool-interrupted-wait.t',
        qw(diagnostics atomicity cleanup),
    ],
    [
        't/1760-vial-selected-tool-interrupted-observer-read.t',
        qw(diagnostics atomicity cleanup),
    ],
    [
        't/1761-vial-selected-tool-observation-timeout-precedence.t',
        qw(diagnostics atomicity cleanup),
    ],
    [
        't/1762-vial-selected-tool-interrupted-containment-pipe-read.t',
        qw(diagnostics atomicity cleanup),
    ],
);
my %RUNTIME_RATIONALE = (
    boundary =>
        'exact runtime artifact, result, report, census, and cleanup ceilings admit at their selected boundary',
    adjacent_excess =>
        'the first structural, byte, count, report, census, and cleanup excess rejects',
    diagnostics =>
        'runtime limit, admission, timeout, containment, and cleanup failures retain stable authority',
    atomicity =>
        'known excess and supervised failure publish no partial graph and preserve authenticated staging',
    no_tool =>
        'all three profile preflights and structural excess reject before provider or selected-tool execution',
    cleanup =>
        'owned staging and supervised process domains are removed exactly or report bounded residue',
    accepted_identity =>
        'all three profiles and persisted runtime objects rebind to selected source, plan, tool, trace, result, and storage authority',
);
my @BACKEND_EVIDENCE = (
    [
        't/1646-vial-architecture-scale-backend-emission-portable-sv.t',
        qw(boundary adjacent_excess diagnostics atomicity no_tool cleanup accepted_identity),
    ],
    [
        't/1647-vial-architecture-scale-backend-emission-portable-vhdl.t',
        qw(boundary adjacent_excess diagnostics atomicity no_tool cleanup accepted_identity),
    ],
    [
        't/1648-vial-architecture-scale-backend-emission-osvvm.t',
        qw(boundary adjacent_excess diagnostics atomicity no_tool cleanup accepted_identity),
    ],
    [
        't/1649-vial-architecture-scale-backend-emission-native-uvm.t',
        qw(boundary adjacent_excess diagnostics atomicity no_tool cleanup accepted_identity),
    ],
    [
        't/1650-vial-architecture-scale-backend-emission-family-qualification.t',
        qw(boundary adjacent_excess diagnostics atomicity no_tool cleanup accepted_identity),
    ],
    [
        't/1716-vial-backend-portable-sv-cap-order.t',
        qw(adjacent_excess diagnostics atomicity no_tool),
    ],
    [
        't/1717-vial-backend-portable-vhdl-cap-order.t',
        qw(adjacent_excess diagnostics atomicity no_tool),
    ],
    [
        't/1718-vial-backend-osvvm-provider-admission-order.t',
        qw(adjacent_excess diagnostics atomicity no_tool accepted_identity),
    ],
    [
        't/1719-vial-backend-native-uvm-cap-order.t',
        qw(adjacent_excess diagnostics atomicity no_tool),
    ],
);
my %BACKEND_RATIONALE = (
    boundary =>
        'each selected backend profile admits its exact owned artifact-graph boundary',
    adjacent_excess =>
        'the first unowned shape, generated-byte, map, inventory, or adapter excess rejects',
    diagnostics =>
        'profile-local negotiation, byte, map, inventory, and provider diagnostics retain stable paths',
    atomicity =>
        'known backend excess publishes no partial source, map, artifact graph, or provider evidence',
    no_tool =>
        'pure emitters start no runtime and known OSVVM foundation excess does not verify its provider',
    cleanup =>
        'accepted, rejected, and consumer-failure staging is same-volume and removed exactly',
    accepted_identity =>
        'selected artifact, source-map, provider, validation, and review identities are deterministic and profile-local',
);
my @CHECKING_MODEL_EVIDENCE = (
    [
        't/1630-vial-architecture-scale-checking-models.t',
        qw(boundary adjacent_excess diagnostics atomicity no_tool cleanup accepted_identity),
    ],
    [
        't/1711-vial-execution-model-cardinality-preflight.t',
        qw(adjacent_excess diagnostics atomicity no_tool accepted_identity),
    ],
);
my %CHECKING_MODEL_RATIONALE = (
    boundary =>
        'both selected checking-model axes admit their exact provider-free oracle limits',
    adjacent_excess =>
        'the first model instance or scalar state cell excess rejects',
    diagnostics =>
        'checking-model limit, oracle, and staging failures retain stable diagnostics',
    atomicity =>
        'compact model excess performs no model normalization and publishes no ExecutionIR or plan',
    no_tool =>
        'the complete checking-model ladder uses a provider-free oracle and starts no external tool',
    cleanup =>
        'accepted and consumer-failure staging is same-volume and residue-free',
    accepted_identity =>
        'accepted construction, evaluation, rerun, plan, and compact-preflight identities are deterministic',
);
my @CHECKING_FAULT_EVIDENCE = (
    [
        't/1633-vial-architecture-scale-checking-faults.t',
        qw(boundary adjacent_excess diagnostics atomicity no_tool cleanup accepted_identity),
    ],
    [
        't/1714-vial-execution-fault-cardinality-preflight.t',
        qw(adjacent_excess diagnostics atomicity no_tool accepted_identity),
    ],
);
my %CHECKING_FAULT_RATIONALE = (
    boundary =>
        'the selected fault axis admits its exact provider-free lifecycle limit',
    adjacent_excess =>
        'the first excess fault rejects before fault normalization',
    diagnostics =>
        'fault limit, lifecycle-oracle, and staging failures retain stable diagnostics',
    atomicity =>
        'compact fault excess performs no fault normalization and publishes no ExecutionIR or plan',
    no_tool =>
        'the complete fault ladder uses a provider-free lifecycle oracle and starts no external tool',
    cleanup =>
        'accepted and consumer-failure fault staging is same-volume and residue-free',
    accepted_identity =>
        'accepted fault construction, evaluation, rerun, plan, and compact-preflight identities are deterministic',
);
my @CHECKING_RANDOMNESS_EVIDENCE = (
    [
        't/1634-vial-architecture-scale-checking-random-replay.t',
        qw(boundary adjacent_excess diagnostics atomicity no_tool cleanup accepted_identity),
    ],
    [
        't/1715-vial-execution-random-occurrence-preflight.t',
        qw(adjacent_excess diagnostics atomicity no_tool accepted_identity),
    ],
);
my %CHECKING_RANDOMNESS_RATIONALE = (
    boundary =>
        'the selected route admits 8,440 occurrences, rejects 8,441 on plan bytes, and records 65,536-occurrence preflight dominance',
    adjacent_excess =>
        'the first route-plan or random-occurrence excess rejects before forbidden materialization',
    diagnostics =>
        'plan-byte, occurrence-limit, replay-oracle, and staging failures retain stable diagnostics',
    atomicity =>
        'known route or occurrence excess publishes no ExecutionIR, plan, replay, or checking result',
    no_tool =>
        'the complete random/replay proofs are provider-free and start no external tool',
    cleanup =>
        'accepted and consumer-failure random staging is same-volume and residue-free',
    accepted_identity =>
        'accepted workload, evaluation, rerun, replay, plan, and compact-preflight identities are deterministic',
);
my @CHECKING_SCOREBOARD_EVIDENCE = (
    [
        't/1631-vial-architecture-scale-checking-scoreboards.t',
        qw(boundary adjacent_excess diagnostics atomicity no_tool cleanup accepted_identity),
    ],
    [
        't/1690-vial-semantic-scoreboard-capacity-order.t',
        qw(boundary adjacent_excess diagnostics atomicity no_tool accepted_identity),
    ],
    [
        't/1712-vial-execution-scoreboard-cardinality-preflight.t',
        qw(adjacent_excess diagnostics atomicity no_tool accepted_identity),
    ],
);
my %CHECKING_SCOREBOARD_RATIONALE = (
    boundary =>
        'both selected scoreboard axes admit their exact provider-free limits, including semantic capacity admission',
    adjacent_excess =>
        'the first semantic scalar, scoreboard instance, or aggregate capacity excess rejects',
    diagnostics =>
        'semantic, execution, FIFO-oracle, and staging failures retain stable diagnostics',
    atomicity =>
        'known excess publishes no semantic report, normalized scoreboards, ExecutionIR, plan, or checking result',
    no_tool =>
        'the complete scoreboard ladder, semantic order, and compact preflight start no external tool',
    cleanup =>
        'accepted and consumer-failure scoreboard staging is same-volume and residue-free',
    accepted_identity =>
        'accepted construction, semantic, evaluation, rerun, plan, and compact-preflight identities are deterministic',
);
my @CHECKING_COVERAGE_EVIDENCE = (
    [
        't/1632-vial-architecture-scale-checking-coverage.t',
        qw(boundary adjacent_excess diagnostics atomicity no_tool cleanup accepted_identity),
    ],
    [
        't/1691-vial-semantic-cross-max-bins-order.t',
        qw(boundary adjacent_excess diagnostics atomicity no_tool accepted_identity),
    ],
    [
        't/1713-vial-execution-coverage-cardinality-preflight.t',
        qw(adjacent_excess diagnostics atomicity no_tool accepted_identity),
    ],
);
my %CHECKING_COVERAGE_RATIONALE = (
    boundary =>
        'static-domain and semantic scalar limits admit exactly while the coverpoint route freezes lower source-byte dominance',
    adjacent_excess =>
        'the first static-domain, semantic scalar, defensive coverpoint, or parser-route excess rejects',
    diagnostics =>
        'fixture-envelope, parser-source, semantic, execution, coverage-oracle, and staging failures retain stable diagnostics',
    atomicity =>
        'known excess publishes no unadmitted source, semantic report, normalized coverage, ExecutionIR, plan, or checking result',
    no_tool =>
        'the complete coverage ladder, parser boundary, semantic order, and compact preflight start no external tool',
    cleanup =>
        'accepted and consumer-failure coverage staging is same-volume and residue-free',
    accepted_identity =>
        'accepted construction, semantic, evaluation, rerun, plan, and compact-preflight identities are deterministic',
);
my @BRIDGE_PROFILE_EVIDENCE = (
    [
        't/1602-vial-architecture-scale-bridge-fanout.t',
        qw(boundary adjacent_excess diagnostics atomicity no_tool cleanup accepted_identity),
    ],
);
my %BRIDGE_PROFILE_RATIONALE = (
    boundary =>
        'the selected single-unit and single-domain bridge profiles admit at their exact limits',
    adjacent_excess =>
        'the first second unit or domain rejects before normalized manifest construction',
    diagnostics =>
        'profile excess retains its stable bridge capability diagnostic and semantic path',
    atomicity =>
        'profile rejection publishes empty metrics and no manifest or report identity',
    no_tool =>
        'every bridge construction has no backend or external-tool selector and uses the reviewed in-process route',
    cleanup =>
        'accepted and consumer-failure bridge staging is same-volume and residue-free',
    accepted_identity =>
        'accepted construction, manifest, report, input, and review-route identities are deterministic',
);
my @BRIDGE_SERIALIZED_EVIDENCE = (
    [
        't/1602-vial-architecture-scale-bridge-fanout.t',
        qw(boundary adjacent_excess diagnostics atomicity no_tool cleanup accepted_identity),
    ],
    [
        't/1704-hial-vial-bridge-serialized-manifest-terminal-authority.t',
        qw(boundary adjacent_excess diagnostics atomicity accepted_identity),
    ],
);
my %BRIDGE_SERIALIZED_RATIONALE = (
    boundary =>
        'the exact workload ladder and terminal observer both admit a 16777216-byte canonical manifest',
    adjacent_excess =>
        'the enclosing route and terminal observer both reject the first complete valid record above the byte cap',
    diagnostics =>
        'workload and terminal checks retain the authoritative bridge limit diagnostic and manifest-root locus',
    atomicity =>
        'terminal and enclosing rejections publish no manifest, report, metrics, or identities',
    no_tool =>
        'the exact serialized-manifest workload carries no backend or external-tool selector',
    cleanup =>
        'serialized-manifest workload success and consumer failure are same-volume and residue-free',
    accepted_identity =>
        'the exact workload identities and terminal canonical SHA are deterministic and byte-equal',
);
my @BRIDGE_NORMALIZED_EVIDENCE = (
    [
        't/1602-vial-architecture-scale-bridge-fanout.t',
        qw(boundary adjacent_excess diagnostics atomicity no_tool cleanup accepted_identity),
    ],
    map {
        [$_, qw(adjacent_excess diagnostics atomicity accepted_identity)]
    } qw(
        t/1694-hial-vial-bridge-configuration-cap-order.t
        t/1695-hial-vial-bridge-endpoint-cap-order.t
        t/1696-hial-vial-bridge-observation-cap-order.t
        t/1697-hial-vial-bridge-probe-cap-order.t
        t/1698-hial-vial-bridge-type-cap-order.t
        t/1699-hial-vial-bridge-transaction-cap-order.t
        t/1700-hial-vial-bridge-event-cap-order.t
        t/1701-hial-vial-bridge-residue-cap-order.t
        t/1702-hial-vial-bridge-backend-binding-cap-order.t
        t/1703-hial-vial-bridge-source-map-cap-order.t
    ),
);
my %BRIDGE_NORMALIZED_RATIONALE = (
    boundary =>
        'the exact workload ladder admits all ten normalized collection axes at their selected limits',
    adjacent_excess =>
        'the exact ladder plus ten order witnesses reject each first constructible excess, including the 16386 binding shape',
    diagnostics =>
        'every collection retains the authoritative bridge limit code, count message, and normalized path',
    atomicity =>
        'every collection excess publishes no manifest or report, and the exact route withholds metrics and identities',
    no_tool =>
        'the exact normalized-collection workload carries no backend or external-tool selector',
    cleanup =>
        'normalized-collection workload success and consumer failure are same-volume and residue-free',
    accepted_identity =>
        'the exact ladder and ten representative accepted controls retain deterministic byte-equal manifest/report identities',
);
my @EXECUTION_PROFILE_EVIDENCE = (
    [
        't/1603-vial-architecture-scale-execution-foundation.t',
        qw(adjacent_excess diagnostics atomicity no_tool),
    ],
    [
        't/1616-vial-architecture-scale-execution-scenario-qualification.t',
        qw(no_tool cleanup accepted_identity),
    ],
    [
        't/1617-vial-architecture-scale-execution-scenario-limit.t',
        qw(boundary accepted_identity),
    ],
    [
        't/1618-vial-architecture-scale-execution-scenario-over-limit.t',
        qw(adjacent_excess diagnostics atomicity no_tool),
    ],
    [
        't/1705-vial-execution-selected-domain-cap-order.t',
        qw(boundary adjacent_excess diagnostics atomicity no_tool accepted_identity),
    ],
);
my %EXECUTION_PROFILE_RATIONALE = (
    boundary =>
        'the exact 4096-scenario limit and fixed one-fixture, one-unit, one-domain profile admit',
    adjacent_excess =>
        '4097 scenarios reject, fixed-scalar over-limit shapes stay caller-sealed, and defensive second unit/domain inputs reject',
    diagnostics =>
        'caller-sealed shape, scenario-limit, unit-reference, and domain-limit failures retain stable loci',
    atomicity =>
        'unowned shapes construct no workload while execution excess publishes no ExecutionIR, plan, or metrics',
    no_tool =>
        'workload specifications and ordinary execution arguments carry no backend, provider, or tool selector',
    cleanup =>
        'qualification staging success and consumer failure are same-volume and residue-free',
    accepted_identity =>
        'qualification, exact-limit, and ordinary fixed-profile plans retain deterministic identities',
);
my @EXECUTION_OPERATION_EVIDENCE = (
    [
        't/1619-vial-architecture-scale-execution-operation-qualification.t',
        qw(no_tool cleanup accepted_identity),
    ],
    [
        't/1620-vial-architecture-scale-execution-operation-limit.t',
        qw(boundary diagnostics atomicity no_tool accepted_identity),
    ],
    [
        't/1621-vial-architecture-scale-execution-operation-over-limit.t',
        qw(adjacent_excess diagnostics atomicity no_tool),
    ],
    [
        't/1622-vial-architecture-scale-execution-total-operation-qualification.t',
        qw(diagnostics atomicity no_tool accepted_identity),
    ],
    [
        't/1626-vial-architecture-scale-execution-total-operation-limit.t',
        qw(boundary adjacent_excess diagnostics atomicity no_tool accepted_identity),
    ],
    [
        't/1706-vial-execution-operation-cardinality-cap-order.t',
        qw(boundary adjacent_excess diagnostics atomicity no_tool accepted_identity),
    ],
);
my %EXECUTION_OPERATION_RATIONALE = (
    boundary =>
        'the exact 65536 per-scenario and 1000000 aggregate preflights admit before any later plan-byte authority',
    adjacent_excess =>
        'the first 65537 per-scenario and 1000001 aggregate excesses reject at their earliest semantic or execution authority',
    diagnostics =>
        'semantic action, plan-byte dominance, compact invariant, and operation-cardinality failures retain stable loci',
    atomicity =>
        'known semantic, plan-byte, and compact-preflight excess publishes no ExecutionIR, plan, metrics, or bridge index',
    no_tool =>
        'every workload specification and ordinary execution argument set carries no backend, provider, or tool selector',
    cleanup =>
        'operation qualification staging success and consumer failure are same-volume and residue-free',
    accepted_identity =>
        'qualification plans, exact-limit semantic stages, and the ordinary accepted plan retain deterministic identities',
);
my @EXECUTION_FIBER_EVIDENCE = (
    [
        't/1623-vial-architecture-scale-execution-fiber-qualification.t',
        qw(no_tool cleanup accepted_identity),
    ],
    [
        't/1624-vial-architecture-scale-execution-live-fiber-limit.t',
        qw(boundary adjacent_excess diagnostics atomicity no_tool accepted_identity),
    ],
    [
        't/1625-vial-architecture-scale-execution-total-fiber-limit.t',
        qw(boundary adjacent_excess diagnostics atomicity no_tool accepted_identity),
    ],
);
my %EXECUTION_FIBER_RATIONALE = (
    boundary =>
        'the exact 16384 live-fiber and 65536 total-fiber component preflights admit before any later authority',
    adjacent_excess =>
        'the first 16385 live-fiber and 65537 total-fiber excesses reject at the execution-graph authority',
    diagnostics =>
        'live-fiber, total-fiber, and later serialized-plan route outcomes retain stable loci',
    atomicity =>
        'known fiber or later plan excess publishes no ExecutionIR, plan, metrics, or bridge index',
    no_tool =>
        'every fiber workload specification carries no backend or external-tool selector',
    cleanup =>
        'both fiber qualification axes stage on-volume and remove success or consumer-failure residue',
    accepted_identity =>
        'qualification plans, the exact live-fiber plan, and total-fiber semantic stages retain deterministic identities',
);
my @EXECUTION_ROUTE_EVIDENCE = (
    [
        't/1603-vial-architecture-scale-execution-foundation.t',
        qw(no_tool cleanup accepted_identity),
    ],
    [
        't/1606-vial-architecture-scale-execution-types.t',
        qw(no_tool cleanup accepted_identity),
    ],
    [
        't/1607-vial-architecture-scale-execution-source-maps.t',
        qw(boundary adjacent_excess diagnostics atomicity no_tool cleanup accepted_identity),
    ],
    [
        't/1627-vial-architecture-scale-execution-type-qualification.t',
        qw(boundary adjacent_excess diagnostics atomicity no_tool accepted_identity),
    ],
    [
        't/1628-vial-architecture-scale-execution-binding-limits.t',
        qw(boundary adjacent_excess diagnostics atomicity no_tool accepted_identity),
    ],
    [
        't/1707-vial-execution-type-cap-order.t',
        qw(boundary adjacent_excess diagnostics atomicity accepted_identity),
    ],
    [
        't/1708-vial-execution-source-map-cap-order.t',
        qw(boundary adjacent_excess diagnostics atomicity accepted_identity),
    ],
    [
        't/1709-vial-execution-binding-cardinality-preflight.t',
        qw(adjacent_excess diagnostics atomicity accepted_identity),
    ],
);
my %EXECUTION_ROUTE_RATIONALE = (
    boundary =>
        'the binding, execution-type, and source-map routes plus type-table and source-map components admit at their exact reachable boundaries',
    adjacent_excess =>
        'the first route, type-table, source-map, or compact binding excess rejects at its earliest layered authority',
    diagnostics =>
        'bridge, semantic, plan-byte, type-table, source-map, and binding-preflight failures retain stable loci',
    atomicity =>
        'known route or local-defense excess publishes no partial manifest, ExecutionIR, plan, type entry, source map, or binding record',
    no_tool =>
        'all three accepted gate constructions and their layered route rejections carry no backend or external-tool selector',
    cleanup =>
        'binding, type, and source-map gate staging removes same-volume success and consumer-failure residue',
    accepted_identity =>
        'all three accepted gate plans, exact route controls, and local-defense controls retain deterministic identities',
);
my @EXECUTION_RANDOM_EVIDENCE = (
    [
        't/1614-vial-architecture-scale-execution-random-limit.t',
        qw(boundary no_tool cleanup accepted_identity),
    ],
    [
        't/1615-vial-architecture-scale-execution-random-over-limit.t',
        qw(adjacent_excess diagnostics atomicity no_tool),
    ],
    [
        't/1710-vial-execution-random-attempt-authority.t',
        qw(adjacent_excess diagnostics atomicity),
    ],
);
my %EXECUTION_RANDOM_RATIONALE = (
    boundary =>
        'the exact 1000000-attempt generated and replayed plans admit at zero-based attempt 999999',
    adjacent_excess =>
        'attempt 1000001 exhausts at the public boundary and the terminal seam confirms the same projection authority',
    diagnostics =>
        'public and terminal exhaustion retain the stable random code, source locus, and decision identity',
    atomicity =>
        'random exhaustion precedes plan preflight and publishes no random decision, ExecutionIR, plan, report, or metrics',
    no_tool =>
        'the accepted boundary and adjacent excess carry no backend or external-tool selector',
    cleanup =>
        'accepted boundary staging success and consumer failure are same-volume and residue-free',
    accepted_identity =>
        'the exact-limit construction, generated plan, replayed plan, decision, and evaluation identities are deterministic',
);
my @EXECUTION_PLAN_EVIDENCE = (
    [
        't/1611-vial-architecture-scale-execution-plan-limit.t',
        qw(boundary no_tool cleanup accepted_identity),
    ],
    [
        't/1612-vial-architecture-scale-execution-plan-over-limit.t',
        qw(adjacent_excess diagnostics atomicity no_tool),
    ],
    [
        't/1634-vial-architecture-scale-checking-random-replay.t',
        qw(diagnostics atomicity cleanup accepted_identity),
    ],
);
my %EXECUTION_PLAN_RATIONALE = (
    boundary =>
        'the exact 16777216-byte canonical plan admits through the public binder',
    adjacent_excess =>
        'the first complete valid plan above 16777216 bytes rejects at preflight',
    diagnostics =>
        'public and independent seam rejections retain the stable plan-root limit diagnostic',
    atomicity =>
        'known plan excess precedes random decisions, ExecutionIR, plan, replay, report, and metrics publication',
    no_tool =>
        'the exact boundary and first complete excess carry no backend or external-tool selector',
    cleanup =>
        'exact-boundary and replay-gate staging remove same-volume success and consumer-failure residue',
    accepted_identity =>
        'the exact-limit plan plus accepted replay-gate workload, evaluation, rerun, and replay identities are deterministic',
);
my @SEMANTIC_PARSER_EVIDENCE = (
    [
        't/1601-vial-architecture-scale-semantic-catalog.t',
        qw(no_tool cleanup accepted_identity),
    ],
    [
        't/1687-vial-parser-direct-import-cap-order.t',
        qw(boundary adjacent_excess diagnostics atomicity accepted_identity),
    ],
    [
        't/1693-vial-parser-source-byte-cap-order.t',
        qw(boundary adjacent_excess diagnostics atomicity accepted_identity),
    ],
);
my %SEMANTIC_PARSER_RATIONALE = (
    boundary =>
        'direct imports plus per-source and combined source bytes admit at their exact parser boundaries',
    adjacent_excess =>
        'the first direct-import and source-byte excesses reject at parser preflight',
    diagnostics =>
        'import and source-byte excesses retain their stable public code, phase, message, and semantic path',
    atomicity =>
        'known import excess precedes recursion and known byte excess precedes lexing without a semantic report',
    no_tool =>
        'every selected semantic construction carries no backend or external-tool selector',
    cleanup =>
        'semantic gate staging removes same-volume success and consumer-failure residue',
    accepted_identity =>
        'the closed catalog plus exact import and byte boundaries retain deterministic semantic identities',
);
my @SEMANTIC_DECLARATION_EVIDENCE = (
    [
        't/1601-vial-architecture-scale-semantic-catalog.t',
        @DIMENSIONS,
    ],
    [
        't/1689-vial-semantic-declaration-cap-order.t',
        qw(boundary adjacent_excess diagnostics atomicity accepted_identity),
    ],
);
my %SEMANTIC_DECLARATION_RATIONALE = (
    boundary =>
        'exact declaration and fixture axes admit at their selected cardinality boundaries',
    adjacent_excess =>
        'the first declaration and fixture excesses reject at semantic preflight',
    diagnostics =>
        'declaration and fixture excesses retain the stable limit family and semantic path',
    atomicity =>
        'known declaration excess precedes later shapes and both excess axes publish no partial semantic identities',
    no_tool =>
        'every selected semantic construction carries no backend or external-tool selector',
    cleanup =>
        'semantic gate staging removes same-volume success and consumer-failure residue',
    accepted_identity =>
        'the closed catalog and exact declaration boundary retain deterministic semantic identities',
);
my %runtime_dimensions = map {
    $_ => {
        status => 'verified',
        evidence => [],
        rationale => $RUNTIME_RATIONALE{$_},
    }
} @DIMENSIONS;
for my $entry (@RUNTIME_EVIDENCE) {
    my ($path, @dimensions) = @{$entry};
    push @{$runtime_dimensions{$_}{evidence}}, $path for @dimensions;
}
my %backend_dimensions = map {
    $_ => {
        status => 'verified',
        evidence => [],
        rationale => $BACKEND_RATIONALE{$_},
    }
} @DIMENSIONS;
for my $entry (@BACKEND_EVIDENCE) {
    my ($path, @dimensions) = @{$entry};
    push @{$backend_dimensions{$_}{evidence}}, $path for @dimensions;
}
my %checking_model_dimensions = map {
    $_ => {
        status => 'verified',
        evidence => [],
        rationale => $CHECKING_MODEL_RATIONALE{$_},
    }
} @DIMENSIONS;
for my $entry (@CHECKING_MODEL_EVIDENCE) {
    my ($path, @dimensions) = @{$entry};
    push @{$checking_model_dimensions{$_}{evidence}}, $path for @dimensions;
}
my %checking_fault_dimensions = map {
    $_ => {
        status => 'verified',
        evidence => [],
        rationale => $CHECKING_FAULT_RATIONALE{$_},
    }
} @DIMENSIONS;
for my $entry (@CHECKING_FAULT_EVIDENCE) {
    my ($path, @dimensions) = @{$entry};
    push @{$checking_fault_dimensions{$_}{evidence}}, $path for @dimensions;
}
my %checking_randomness_dimensions = map {
    $_ => {
        status => 'verified',
        evidence => [],
        rationale => $CHECKING_RANDOMNESS_RATIONALE{$_},
    }
} @DIMENSIONS;
for my $entry (@CHECKING_RANDOMNESS_EVIDENCE) {
    my ($path, @dimensions) = @{$entry};
    push @{$checking_randomness_dimensions{$_}{evidence}}, $path
        for @dimensions;
}
my %checking_scoreboard_dimensions = map {
    $_ => {
        status => 'verified',
        evidence => [],
        rationale => $CHECKING_SCOREBOARD_RATIONALE{$_},
    }
} @DIMENSIONS;
for my $entry (@CHECKING_SCOREBOARD_EVIDENCE) {
    my ($path, @dimensions) = @{$entry};
    push @{$checking_scoreboard_dimensions{$_}{evidence}}, $path
        for @dimensions;
}
my %checking_coverage_dimensions = map {
    $_ => {
        status => 'verified',
        evidence => [],
        rationale => $CHECKING_COVERAGE_RATIONALE{$_},
    }
} @DIMENSIONS;
for my $entry (@CHECKING_COVERAGE_EVIDENCE) {
    my ($path, @dimensions) = @{$entry};
    push @{$checking_coverage_dimensions{$_}{evidence}}, $path
        for @dimensions;
}
my %bridge_profile_dimensions = map {
    $_ => {
        status => 'verified',
        evidence => [],
        rationale => $BRIDGE_PROFILE_RATIONALE{$_},
    }
} @DIMENSIONS;
for my $entry (@BRIDGE_PROFILE_EVIDENCE) {
    my ($path, @dimensions) = @{$entry};
    push @{$bridge_profile_dimensions{$_}{evidence}}, $path for @dimensions;
}
my %bridge_serialized_dimensions = map {
    $_ => {
        status => 'verified',
        evidence => [],
        rationale => $BRIDGE_SERIALIZED_RATIONALE{$_},
    }
} @DIMENSIONS;
for my $entry (@BRIDGE_SERIALIZED_EVIDENCE) {
    my ($path, @dimensions) = @{$entry};
    push @{$bridge_serialized_dimensions{$_}{evidence}}, $path
        for @dimensions;
}
my %bridge_normalized_dimensions = map {
    $_ => {
        status => 'verified',
        evidence => [],
        rationale => $BRIDGE_NORMALIZED_RATIONALE{$_},
    }
} @DIMENSIONS;
for my $entry (@BRIDGE_NORMALIZED_EVIDENCE) {
    my ($path, @dimensions) = @{$entry};
    push @{$bridge_normalized_dimensions{$_}{evidence}}, $path
        for @dimensions;
}
my %execution_profile_dimensions = map {
    $_ => {
        status => 'verified',
        evidence => [],
        rationale => $EXECUTION_PROFILE_RATIONALE{$_},
    }
} @DIMENSIONS;
for my $entry (@EXECUTION_PROFILE_EVIDENCE) {
    my ($path, @dimensions) = @{$entry};
    push @{$execution_profile_dimensions{$_}{evidence}}, $path
        for @dimensions;
}
my %execution_operation_dimensions = map {
    $_ => {
        status => 'verified',
        evidence => [],
        rationale => $EXECUTION_OPERATION_RATIONALE{$_},
    }
} @DIMENSIONS;
for my $entry (@EXECUTION_OPERATION_EVIDENCE) {
    my ($path, @dimensions) = @{$entry};
    push @{$execution_operation_dimensions{$_}{evidence}}, $path
        for @dimensions;
}
my %execution_fiber_dimensions = map {
    $_ => {
        status => 'verified',
        evidence => [],
        rationale => $EXECUTION_FIBER_RATIONALE{$_},
    }
} @DIMENSIONS;
for my $entry (@EXECUTION_FIBER_EVIDENCE) {
    my ($path, @dimensions) = @{$entry};
    push @{$execution_fiber_dimensions{$_}{evidence}}, $path
        for @dimensions;
}
my %execution_route_dimensions = map {
    $_ => {
        status => 'verified',
        evidence => [],
        rationale => $EXECUTION_ROUTE_RATIONALE{$_},
    }
} @DIMENSIONS;
for my $entry (@EXECUTION_ROUTE_EVIDENCE) {
    my ($path, @dimensions) = @{$entry};
    push @{$execution_route_dimensions{$_}{evidence}}, $path
        for @dimensions;
}
my %execution_random_dimensions = map {
    $_ => {
        status => 'verified',
        evidence => [],
        rationale => $EXECUTION_RANDOM_RATIONALE{$_},
    }
} @DIMENSIONS;
for my $entry (@EXECUTION_RANDOM_EVIDENCE) {
    my ($path, @dimensions) = @{$entry};
    push @{$execution_random_dimensions{$_}{evidence}}, $path
        for @dimensions;
}
my %execution_plan_dimensions = map {
    $_ => {
        status => 'verified',
        evidence => [],
        rationale => $EXECUTION_PLAN_RATIONALE{$_},
    }
} @DIMENSIONS;
for my $entry (@EXECUTION_PLAN_EVIDENCE) {
    my ($path, @dimensions) = @{$entry};
    push @{$execution_plan_dimensions{$_}{evidence}}, $path
        for @dimensions;
}
my %semantic_parser_dimensions = map {
    $_ => {
        status => 'verified',
        evidence => [],
        rationale => $SEMANTIC_PARSER_RATIONALE{$_},
    }
} @DIMENSIONS;
for my $entry (@SEMANTIC_PARSER_EVIDENCE) {
    my ($path, @dimensions) = @{$entry};
    push @{$semantic_parser_dimensions{$_}{evidence}}, $path
        for @dimensions;
}
my %semantic_declaration_dimensions = map {
    $_ => {
        status => 'verified',
        evidence => [],
        rationale => $SEMANTIC_DECLARATION_RATIONALE{$_},
    }
} @DIMENSIONS;
for my $entry (@SEMANTIC_DECLARATION_EVIDENCE) {
    my ($path, @dimensions) = @{$entry};
    push @{$semantic_declaration_dimensions{$_}{evidence}}, $path
        for @dimensions;
}
my $VERIFIED_DIMENSIONS = {
    backend_artifact_graph => \%backend_dimensions,
    bridge_normalized_collections => \%bridge_normalized_dimensions,
    bridge_profile_cardinality => \%bridge_profile_dimensions,
    bridge_serialized_manifest => \%bridge_serialized_dimensions,
    checking_coverage => \%checking_coverage_dimensions,
    checking_faults => \%checking_fault_dimensions,
    checking_models => \%checking_model_dimensions,
    checking_randomness => \%checking_randomness_dimensions,
    checking_scoreboards => \%checking_scoreboard_dimensions,
    execution_fiber_cardinality => \%execution_fiber_dimensions,
    execution_operation_cardinality => \%execution_operation_dimensions,
    execution_serialized_plan => \%execution_plan_dimensions,
    execution_profile_selection => \%execution_profile_dimensions,
    execution_random_attempts => \%execution_random_dimensions,
    execution_route_collections => \%execution_route_dimensions,
    runtime_stream_envelopes => \%runtime_dimensions,
    semantic_declaration_cardinality => \%semantic_declaration_dimensions,
    semantic_parser_admission => \%semantic_parser_dimensions,
};

sub build {
    my ($class, @args) = @_;
    _exact_invocant($class, 'build');
    confess __PACKAGE__ . "->build requires no arguments\n" if @args;
    my $report = _expected_report();
    _assert_report($report);
    return _clone($report);
}

sub required_dimensions {
    my ($class, @args) = @_;
    _exact_invocant($class, 'required_dimensions');
    confess __PACKAGE__ . "->required_dimensions requires no arguments\n"
        if @args;
    return [@DIMENSIONS];
}

sub _expected_report {
    my $policy = build_architecture_scale_cap_policy();
    my %axes_for;
    for my $family (sort keys %{$policy->{axis_groups}}) {
        for my $axis (sort keys %{$policy->{axis_groups}{$family}}) {
            my $group = $policy->{axis_groups}{$family}{$axis};
            push @{$axes_for{$group}}, "$family/$axis";
        }
    }

    my %groups;
    my $complete = 1;
    for my $name (sort keys %{$policy->{groups}}) {
        my $selected = $policy->{groups}{$name};
        my %dimensions;
        for my $dimension (@DIMENSIONS) {
            my $verified = exists($VERIFIED_DIMENSIONS->{$name})
                ? $VERIFIED_DIMENSIONS->{$name}{$dimension}
                : undef;
            my $record = defined($verified)
                ? _clone($verified)
                : {
                    status => 'pending_independent_verification',
                    evidence => [],
                    rationale =>
                        'policy citations are candidates, not dimension proof',
                };
            $complete = 0 unless $record->{status} eq 'verified';
            $dimensions{$dimension} = $record;
        }
        $groups{$name} = {
            axes => [@{$axes_for{$name} // []}],
            declared_authority => $selected->{declared_authority},
            earliest_stage => $selected->{earliest_stage},
            path_contract => $selected->{path_contract},
            atomicity_contract => $selected->{atomicity},
            implementation_leaf => $selected->{implementation_leaf},
            diagnostic_families => _clone(
                $selected->{diagnostic_families},
            ),
            candidate_evidence => _clone($selected->{evidence}),
            dimensions => \%dimensions,
        };
    }

    return {
        schema => $SCHEMA,
        schema_version => 1,
        decision => $policy->{decision},
        policy => {
            builder => $POLICY_BUILDER,
            schema => $policy->{schema},
            decision => $policy->{decision},
        },
        required_dimensions => [@DIMENSIONS],
        groups => \%groups,
        calibration => {
            authority => $CALIBRATION_AUTHORITY,
            evidence_role => 'historical_measurement_only',
            cap_proof_status => $complete ? 'complete' : 'incomplete',
            disposition => $complete
                ? 'eligible_for_explicit_revalidation'
                : 'blocked_pending_current_cap_verification',
            unlock_condition => 'all_group_dimensions_verified',
            prohibited_relabel => 'cap_implementation',
        },
        explicit_nonclaims => _clone($policy->{explicit_nonclaims}),
    };
}

sub _assert_report {
    my ($report) = @_;
    confess "architecture-scale cap consistency report must be one unblessed hash\n"
        unless @_ == 1 && ref($report) eq 'HASH' && !blessed($report);
    _assert_exact_keys($report, [qw(
        schema schema_version decision policy required_dimensions groups
        calibration explicit_nonclaims
    )], 'consistency report');
    confess "architecture-scale cap consistency schema is unsupported\n"
        unless ($report->{schema} // '') eq $SCHEMA
            && ($report->{schema_version} // 0) == 1;

    my $policy = build_architecture_scale_cap_policy();
    my $expected = _expected_report();
    confess "consistency report decision contradicts the cap policy\n"
        unless ($report->{decision} // '') eq $policy->{decision};
    _assert_exact_keys(
        $report->{policy}, [qw(builder schema decision)],
        'consistency policy authority',
    );
    confess "consistency report policy authority contradicts the live policy\n"
        unless ($report->{policy}{builder} // '') eq $POLICY_BUILDER
            && ($report->{policy}{schema} // '') eq $policy->{schema}
            && ($report->{policy}{decision} // '') eq $policy->{decision};
    _assert_string_array(
        $report->{required_dimensions}, 'required closeout dimensions',
    );
    confess "required closeout dimensions contradict the sealed contract\n"
        unless join("\0", @{$report->{required_dimensions}})
            eq join("\0", @DIMENSIONS);

    confess "consistency report groups must be one unblessed hash\n"
        unless ref($report->{groups}) eq 'HASH'
            && !blessed($report->{groups});
    my @actual_groups = sort keys %{$report->{groups}};
    my @expected_groups = sort keys %{$policy->{groups}};
    confess "consistency report group inventory contradicts the cap policy\n"
        unless join("\0", @actual_groups) eq join("\0", @expected_groups);

    my %axes_for;
    for my $family (sort keys %{$policy->{axis_groups}}) {
        for my $axis (sort keys %{$policy->{axis_groups}{$family}}) {
            push @{$axes_for{$policy->{axis_groups}{$family}{$axis}}},
                "$family/$axis";
        }
    }

    for my $name (@actual_groups) {
        my $group = $report->{groups}{$name};
        _assert_exact_keys($group, [qw(
            axes declared_authority earliest_stage path_contract
            atomicity_contract implementation_leaf diagnostic_families
            candidate_evidence dimensions
        )], "consistency group '$name'");
        _assert_string_array($group->{axes},
            "consistency group '$name' axes");
        confess "consistency group '$name' axes contradict the cap policy\n"
            unless join("\0", @{$group->{axes}})
                eq join("\0", @{$axes_for{$name} // []});
        my $selected = $policy->{groups}{$name};
        for my $pair (
            [declared_authority => 'declared_authority'],
            [earliest_stage => 'earliest_stage'],
            [path_contract => 'path_contract'],
            [atomicity_contract => 'atomicity'],
            [implementation_leaf => 'implementation_leaf'],
        ) {
            my ($report_field, $policy_field) = @{$pair};
            confess "consistency group '$name/$report_field' contradicts the cap policy\n"
                unless defined($group->{$report_field})
                    && !ref($group->{$report_field})
                    && $group->{$report_field} eq $selected->{$policy_field};
        }
        _assert_string_array($group->{diagnostic_families},
            "consistency group '$name' diagnostics");
        _assert_string_array($group->{candidate_evidence},
            "consistency group '$name' candidate evidence");
        confess "consistency group '$name' diagnostics contradict the cap policy\n"
            unless _same_plain(
                $group->{diagnostic_families},
                $selected->{diagnostic_families},
            );
        confess "consistency group '$name' candidate evidence contradicts the cap policy\n"
            unless _same_plain(
                $group->{candidate_evidence}, $selected->{evidence},
            );

        _assert_exact_keys(
            $group->{dimensions}, \@DIMENSIONS,
            "consistency group '$name' dimensions",
        );
        for my $dimension (@DIMENSIONS) {
            my $record = $group->{dimensions}{$dimension};
            _assert_exact_keys($record, [qw(status evidence rationale)],
                "consistency group '$name/$dimension'");
            confess "consistency group '$name/$dimension' evidence must be one array\n"
                unless ref($record->{evidence}) eq 'ARRAY';
            confess "consistency group '$name/$dimension' rationale must be a non-empty scalar\n"
                unless defined($record->{rationale})
                    && !ref($record->{rationale})
                    && length($record->{rationale});
            if (($record->{status} // '') eq 'pending_independent_verification') {
                confess "consistency group '$name/$dimension' pending evidence must be empty\n"
                    if @{$record->{evidence}};
            } elsif (($record->{status} // '') eq 'verified') {
                _assert_string_array($record->{evidence},
                    "consistency group '$name/$dimension' verified evidence");
            } else {
                confess "consistency group '$name/$dimension' has unsupported status\n";
            }
            confess "consistency group '$name/$dimension' contradicts "
                . "the sealed evidence authority\n"
                unless _same_plain(
                    $record,
                    $expected->{groups}{$name}{dimensions}{$dimension},
                );
        }
    }

    _assert_exact_keys($report->{calibration}, [qw(
        authority evidence_role cap_proof_status disposition unlock_condition
        prohibited_relabel
    )], 'calibration consistency barrier');
    my $expected_proof = $expected->{calibration}{cap_proof_status};
    my $expected_disposition = $expected->{calibration}{disposition};
    confess "calibration authority contradicts the sealed contract\n"
        unless ($report->{calibration}{authority} // '')
            eq $CALIBRATION_AUTHORITY;
    confess "calibration evidence role contradicts the sealed contract\n"
        unless ($report->{calibration}{evidence_role} // '')
            eq 'historical_measurement_only';
    confess "calibration proof status contradicts verification state\n"
        unless ($report->{calibration}{cap_proof_status} // '')
            eq $expected_proof;
    confess "calibration disposition contradicts verification state\n"
        unless ($report->{calibration}{disposition} // '')
            eq $expected_disposition;
    confess "calibration unlock condition contradicts the sealed contract\n"
        unless ($report->{calibration}{unlock_condition} // '')
            eq 'all_group_dimensions_verified';
    confess "calibration prohibited relabel contradicts the publication nonclaim\n"
        unless ($report->{calibration}{prohibited_relabel} // '')
            eq 'cap_implementation';
    _assert_string_array($report->{explicit_nonclaims}, 'explicit nonclaims');
    confess "consistency report nonclaims contradict the cap policy\n"
        unless _same_plain(
            $report->{explicit_nonclaims}, $policy->{explicit_nonclaims},
        );
    return 1;
}

sub _assert_exact_keys {
    my ($value, $expected, $label) = @_;
    confess "$label must be one unblessed hash\n"
        unless ref($value) eq 'HASH' && !blessed($value);
    my %expected = map { $_ => 1 } @{$expected};
    my @unknown = sort grep { !$expected{$_} } keys %{$value};
    my @missing = grep { !exists($value->{$_}) } @{$expected};
    confess "$label has unknown field '$unknown[0]'\n" if @unknown;
    confess "$label is missing field '$missing[0]'\n" if @missing;
}

sub _assert_string_array {
    my ($value, $label) = @_;
    confess "$label must be one non-empty array\n"
        unless ref($value) eq 'ARRAY' && @{$value};
    my %seen;
    for my $entry (@{$value}) {
        confess "$label must contain unique non-empty scalars\n"
            unless defined($entry) && !ref($entry) && length($entry)
                && !$seen{$entry}++;
    }
}

sub _same_plain {
    my ($left, $right) = @_;
    return 1 if !defined($left) && !defined($right);
    return 0 unless defined($left) && defined($right);
    return $left eq $right unless ref($left) || ref($right);
    return 0 unless ref($left) eq ref($right);
    if (ref($left) eq 'HASH') {
        return 0 unless join("\0", sort keys %{$left})
            eq join("\0", sort keys %{$right});
        return 0 if grep { !_same_plain($left->{$_}, $right->{$_}) }
            keys %{$left};
        return 1;
    }
    if (ref($left) eq 'ARRAY') {
        return 0 unless @{$left} == @{$right};
        for my $index (0 .. $#{$left}) {
            return 0 unless _same_plain($left->[$index], $right->[$index]);
        }
        return 1;
    }
    return 0;
}

sub _clone {
    my ($value) = @_;
    return undef unless defined $value;
    return {map { $_ => _clone($value->{$_}) } keys %{$value}}
        if ref($value) eq 'HASH';
    return [map { _clone($_) } @{$value}] if ref($value) eq 'ARRAY';
    return $value;
}

sub _exact_invocant {
    my ($class, $method) = @_;
    confess __PACKAGE__ . "->$method requires the exact class invocant\n"
        unless defined($class) && !ref($class) && $class eq __PACKAGE__;
}

1;
