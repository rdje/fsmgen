#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Support::ISFPublicInterfaceContract qw(
    isf_public_interface_live_document_paths
);

my $repo_root = File::Spec->rel2abs(File::Spec->catdir($FindBin::Bin, '..'));
my $matrix_path = 'docs/book/src/13k-isf-feature-support-matrix.md';
my $composition_path = 'docs/book/src/13f-composition.md';
my $backlog_path = 'docs/book/src/14-feature-backlog.md';
my $downstream_path = 'docs/ISF_DOWNSTREAM_INTEGRATION_SPEC.md';
my $design_path = 'docs/ISF_ATL_DESIGN_PROPOSAL.md';
my $task_tree_path = 'docs/TASK_TREE.md';
my $matrix = read_repo_file($matrix_path);
my $matrix_flat = $matrix;
$matrix_flat =~ s/\s+/ /g;
my $composition = read_repo_file($composition_path);
my $backlog = read_repo_file($backlog_path);
my $downstream = read_repo_file($downstream_path);
my $design = read_repo_file($design_path);
my $task_tree = read_repo_file($task_tree_path);
my $summary = read_repo_file('docs/book/src/SUMMARY.md');

like(
    $summary,
    qr{\[Feature Support Matrix\]\(13k-isf-feature-support-matrix\.md\)},
    'ISF feature support matrix is reachable from the mdBook summary',
);

like(
    $summary,
    qr{\[Composition\]\(13f-composition\.md\)},
    'ISF composition chapter is reachable from the mdBook summary',
);

like(
    $summary,
    qr{\[Feature Backlog\]\(14-feature-backlog\.md\)},
    'ISF feature backlog chapter is reachable from the mdBook summary',
);

my @book_backlog_categories = $backlog =~ /^## ([^\n]+)$/mg;
is_deeply(
    \@book_backlog_categories,
    [
        'Language Ergonomics',
        'Aggregate Types And Data',
        'Composition',
        'Intent Scheduling Format',
        'Backends And Validation',
        'Embedding And Public APIs',
    ],
    'feature backlog category set is explicit',
);

like(
    $task_tree,
    qr{## Book-Facing Feature Backlog Owner Coverage},
    'task tree documents book-facing feature backlog owner coverage',
);

for my $category (@book_backlog_categories) {
    like(
        $task_tree,
        qr{\|\s*`\Q$category\E`\s*\|},
        "task tree owner coverage lists feature backlog category $category",
    );
}

for my $phrase (
    'future task tree required',
    'not an implementation permission slip',
) {
    like(
        $task_tree,
        qr{\Q$phrase\E},
        "task tree owner coverage makes $phrase explicit",
    );
    like(
        $backlog,
        qr{\Q$phrase\E},
        "feature backlog introduction makes $phrase explicit",
    );
}

my %live_paths = map { $_ => 1 } @{isf_public_interface_live_document_paths()};
ok(
    $live_paths{$matrix_path},
    'ISF feature support matrix is advertised through live_document_paths',
);

my @required_rows = (
    ['`.isf` CLI input', 'shipped'],
    ['Public parser and scheduler facades', 'shipped bounded surface'],
    ['Actor envelope', 'shipped'],
    ['Actor report metadata and params', 'shipped bounded surface'],
    ['Single-clock timing', 'shipped'],
    ['Multi-clock domains', 'shipped bounded surface'],
    ['Acknowledged event CDC', 'shipped bounded surface'],
    ['Interface ports', 'shipped'],
    ['Actor-owned scalar storage', 'shipped'],
    ['Actor-owned banks', 'shipped bounded surface'],
    ['Type aliases and package imports', 'shipped bounded surface'],
    ['Enum member values', 'shipped bounded surface'],
    ['Aggregate scalar leaves', 'shipped bounded surface'],
    ['Transaction entry', 'shipped'],
    ['Transaction ports and activation bindings', 'shipped bounded surface'],
    ['Transaction assignments', 'shipped'],
    ['Runtime expression divisor safety', 'shipped bounded surface'],
    ['Named and inline drives', 'shipped'],
    ['Await and latency', 'shipped'],
    ['Static and dynamic waits', 'shipped bounded surface'],
    ['Transaction control flow', 'shipped bounded surface'],
    ['Transaction stages', 'shipped bounded surface'],
    ['Temporal contracts', 'shipped bounded surface'],
    ['Data manipulation', 'shipped bounded surface'],
    ['Rules and trigger fan-in', 'shipped'],
    ['Rule conflicts and priorities', 'shipped bounded surface'],
    ['Resources', 'shipped bounded surface'],
    ['Blocking child activation', 'shipped bounded surface'],
    ['Spawned generated children', 'shipped bounded surface'],
    ['Reusable ISF libraries', 'shipped bounded surface'],
    ['Schedule reports', 'shipped bounded surface'],
    ['Schedule report schema and storage roles', 'shipped bounded surface'],
    ['Diagnostics and downstream issue reporting', 'shipped'],
);

for my $row (@required_rows) {
    my ($feature, $status) = @{$row};
    like(
        $matrix,
        qr{\|\s*\Q$feature\E\s*\|\s*\Q$status\E\s*\|},
        "matrix documents $feature as $status",
    );
}

my @required_examples = (
    '(clock-domains',
    './bin/fsmgen --strict isf/apb_requester.isf',
    '(crossings',
    '(stage wait_ready',
    '(monitor (within',
    '(transaction read_word',
    '(bind',
    'transaction_port_bindings[]',
    '(repeat count',
    '(types',
    '(storage',
    '(resources',
    '(spawn worker as w0',
    '(imports',
    '--emit-schedule-json',
    '--strict --outdir /tmp/isf-build',
    'I2C-like fixture',
    'burst-reader fixture',
    'UART-like fixture',
    'phase fixture',
    'switch fixture',
    'when fixture',
    'generated-composition fixture',
    'rule/resource fixture',
    'stage fixture',
    'FIFO datapath fixture',
    'FIFO controller fixture',
    'FIFO library fixture',
    'ATL temporary trigger-batch fixture',
    'same-source/same-sink scalar or exact-width vector generated-child actor-to-actor routes are shipped through that two-child top',
    'one exact-width vector top-level input-pin to resolved-child input route',
    'same-child vector multi-route subset',
    'its own exact matching top-input/child-input width',
    'vector_pin_to_actor_handoff',
    'top_level_input_pin_resolved_child_endpoint_exact_width',
    'one exact-width vector resolved-child output to top-level output route',
    'vector same-child pin-egress multi-route extension',
    'exact matching child-output/top-output width',
    'vector_actor_to_pin_handoff',
    'top_level_output_pin_resolved_child_endpoint_exact_width',
    'actor-to-actor route between two resolved children through the generated ATL',
    'one named drive-call cycle',
    'Generated-child actor-to-actor and pin route support is intentionally',
    'generated handoffs, and one named',
    'route drive unparameterized',
    'route drive call remains',
    'argument-free: `(drive',
    'route endpoint-expression hardening',
    '(writer.payload (+ reader.payload 1))',
    '((+ writer.payload 1) reader.payload)',
    'source-order independent',
    '((out) 1)',
    'placing the named `forward_payload` route drive before',
    './bin/fsmgen -l sv isf/apb_requester.isf',
    '"schema_version": 1',
    '"actor_params"',
    '"actor_phases"',
    'dynamic_wait_counter',
    'consecutive runtime waits',
    'bank access predecessors',
    'sample-preserving zero-count clones',
    'independent scalar setters',
    'independent shifts',
    'independent assemble states',
    'independent extract states',
    'independent bank loads',
    'independent bank stores',
    'top-level await_all/await_any sync states',
    'top-level spawn states',
    'top-level transaction phase states',
    'top-level ready/valid stages',
    'top-level monitor arm states',
    'loop decision states',
    'top-level repeat-body local blocking do',
    'plain local `while -> when -> repeat -> do`',
    'documented top-level, top-level repeat, top-level branch/loop, loop-contained repeat, deeper branch-contained repeat, and top-level `when`/`switch` nested-repeat contexts',
    'same-body proof rule owns the child lifetime',
    'generated instances must have deterministic static top wiring',
    'every pending generated-spawn done set must be observed only by `await_any` and drained by a later exact same-body `await_all`',
    'Loop-contained local-do fanout has no public child-count cap once exact-set proofs hold',
    'Repeat-body activation matrix note: the shipped nested-repeat activation shapes under top-level `when` and `switch` branches are described by construction',
    'The accepted activation kinds are local `do`, generated-child `do`, generated `do` with static `(params ...)`',
    'generated `do` with `(bind ...)` handoffs',
    'optional bind handoffs plus same-domain metadata',
    'a blocking `do` must observe its own fresh done handoff',
    'declared same-domain metadata records ownership without adding CDC',
    'observations before the `do`, post-`do` observations, and second post-spawn observations',
    'an accepted blocking `do` may run while generated spawns are already pending',
    'may be followed by one or more later generated spawns before the final drain',
    'The documented top-level `when` and `switch` branch paths mirror each other',
    'Spawned generated children',
    '(spawn child as inst [(params ...)] [(bind ...)] [(domain NAME)])',
    'same-body drain rule owns the generated-child lifetime',
    'samples before or after spawn before same-body sync',
    'samples before or after repeat-body do before the repeat check',
    'multi-pending repeat-body await_any with mandatory same-body await_all drain',
    'actor parameter wait count',
    '(/ numerator 0)',
    '(/ numerator ZERO)',
    'exactly one missing part width',
    'exactly one missing destination field width',
    'schedule_report_full_schema_stable',
    './bin/fsmgen-issue-bundle',
    '--issue-id sf-0001',
    '--failure-class unknown',
    'commands.sh',
);

for my $example (@required_examples) {
    like(
        $matrix_flat,
        qr{\Q$example\E},
        "matrix keeps representative example marker $example",
    );
}

my @required_non_claims = (
    'Multi-bit CDC payloads',
    # Top-level repeat-body cross-domain `(do)` is now shipped
    # (ISF-NESTED-CROSS-DOMAIN-ACTIVATION.3); the matrix must still defer the deeper
    # cases. These two non-claims track that remaining deferred boundary.
    'Generated or spawned nested activation',
    'DEEPER-nested cross-domain',
    'Dynamic division/modulo nonzero proof is not shipped',
    'Enum members are not writable targets',
    'Aggregate interface ports',
    'Backlog resource kinds',
    'Actor-level phase and stage metadata is report-only',
    'Direct `(on ...)` activation-site `(params ...)`',
    'Rule-trigger output bindings',
    'snapshot-vs-live binding timing selection',
    'Nested stages',
    'Temporal contracts beyond the top-level bounded eventual subset',
    'remapping or reuse',
    'parameterized route drive definitions',
    'route drive-call actual arguments',
    'Missing same-body drains, cross-domain activation without an explicit crossing, deeper branch/loop nesting, implicit CDC, dynamic generated-child specialization, and broader outstanding-child lifetime semantics remain fail-closed',
    'Missing drains, cross-domain `spawn`, dynamic per-iteration specialization, implicit CDC, and broader generated-child lifetime semantics remain fail-closed',
    'Raw parser actor hashes',
    'VHDL is recognized as a target family',
);

for my $non_claim (@required_non_claims) {
    like(
        $matrix_flat,
        qr{\Q$non_claim\E},
        "matrix keeps explicit non-claim: $non_claim",
    );
}

unlike(
    $matrix,
    qr{Actor-to-actor generated-child routes, multi-child data wiring, route\s+mux/storage, CDC/reset remapping, ready/backpressure, and payload protocols\s+remain backlog\.},
    'matrix no longer treats all actor-to-actor generated-child routes as backlog',
);

unlike(
    $matrix,
    qr{positive multi-child ATL top\s+scheduling remains backlog},
    'matrix no longer claims positive multi-child ATL top scheduling remains backlog',
);

for my $doc (
    ['composition chapter', $composition],
    ['feature backlog',     $backlog],
    ['downstream handoff',  $downstream],
    ['ATL design proposal', $design],
) {
    my ($label, $content) = @{$doc};
    unlike(
        $content,
        qr{reserved generated-child actor-to-actor(?: data-route)? shape now fails closed},
        "$label no longer says the reserved actor-to-actor route shape now fails closed as a whole",
    );
    unlike(
        $content,
        qr{fails closed reserved generated-child actor-to-actor data movement},
        "$label no longer uses stale reserved-route fail-closed wording",
    );
}

unlike(
    $design,
    qr{Actor-to-actor generated-child routes,\s+multi-child data wiring,\s+route mux/storage,\s+CDC/reset remapping,\s+ready/backpressure,\s+and payload protocols remain deferred\.},
    'ATL design proposal no longer uses blanket generated-child actor-to-actor route deferral for one-child pin routes',
);

like(
    $composition,
    qr{The selected generated-child actor-to-actor data-route shape across two\s+resolved children reuses the existing `\(sink source\)` drive-body movement\s+surface},
    'composition chapter states selected generated-child actor-to-actor route is shipped narrowly',
);

like(
    $downstream,
    qr{The selected generated-child actor-to-actor data route set is shipped only for\s+same-source/same-sink two-child shapes},
    'downstream handoff states selected generated-child actor-to-actor route is shipped narrowly',
);

like(
    $backlog,
    qr{The selected generated-child actor-to-actor data movement across two resolved\s+children is shipped only for same-source/same-sink two-child routes},
    'feature backlog states selected generated-child actor-to-actor route is shipped narrowly',
);

like(
    $design,
    qr{This one-child pin-ingress\s+route does not include actor-to-actor generated-child routing},
    'ATL design proposal distinguishes one-child pin-ingress route scope from actor-to-actor routing',
);

like(
    $design,
    qr{This one-child pin-egress route does not include actor-to-actor\s+generated-child routing},
    'ATL design proposal distinguishes one-child pin-egress route scope from actor-to-actor routing',
);

like(
    $design,
    qr{The selected generated-child actor-to-actor data-route shape across two\s+resolved children is shipped through the two-child generated ATL top},
    'ATL design proposal states the selected generated-child actor-to-actor route is shipped',
);

like(
    $design,
    qr{Broader fan-in/fan-out\s+route sets, route mux/storage, CDC/reset\s+remapping, ready/backpressure,\s+payload protocols, recursive actor networks,\s+and permanent actor grouping\s+remain deferred},
    'ATL design proposal keeps broader generated-child route features deferred',
);

my $atl_composition_section = markdown_heading_section(
    $composition,
    '## Static Actor-Network Metadata',
);

ok(
    length($atl_composition_section),
    'composition chapter keeps a dedicated ATL actor-network section',
);

my @required_atl_concept_markers = (
    '### Actor-As-Network Boundary And Direct Instances',
    '### Drive-Body Data Movement',
    '### Trigger And Event Pulses',
    '### Static Groups Versus Task-Scoped Associations',
    '### Generated-Child Top Data Routes',
    'The enclosing actor is the network boundary',
    'rather than a `(network ...)` section',
    'drive-body pair shape in `(sink source)` order',
    'Events are one-cycle control',
    'pulses with no payloads in ATL v0',
    'static review metadata, not a permanent runtime association',
    'lifetime `task_scoped`',
    'These one-child pin-ingress routes do not include actor-to-actor',
    'This one-child pin-egress route does not include actor-to-actor',
    'The selected generated-child actor-to-actor data-route shape across two',
    'generated handoff',
    'route mux/storage',
    'fan-in/fan-out',
    'ready/backpressure',
    'payload protocols',
    'recursive actor networks',
    'permanent actor grouping',
);

for my $marker (@required_atl_concept_markers) {
    like(
        $atl_composition_section,
        qr{\Q$marker\E},
        "ATL composition section keeps concept marker: $marker",
    );
}

my $downstream_atl_section = markdown_heading_section(
    $downstream,
    '## 12.5. Static Actor Network Metadata',
);

ok(
    length($downstream_atl_section),
    'downstream handoff keeps a dedicated ATL actor-network section',
);

my @required_downstream_atl_markers = (
    '### 12.5.1. Actor-As-Network Boundary And Direct Instances',
    '### 12.5.2. Drive-Body Data Movement And Endpoint Vocabulary',
    '### 12.5.3. Static Groups Versus Task-Scoped Associations',
    '### 12.5.4. Trigger And Event Pulses',
    '### 12.5.5. Generated-Child Route Terms And Boundaries',
    '### 12.5.6. Generated Child Artifacts And Top Data Routes',
    'The enclosing actor is the network boundary',
    'static ATL declarations in `(network ...)`',
    'drive body pair stays `(sink source)`',
    '`connect`, `transfer`, and `move` are not public ATL v0 movement clauses',
    'scheduling: "metadata_only"',
    'lifetime: "task_scoped"',
    'events are one-cycle control pulses',
    'one-cycle parent output named `actor_transaction_start`',
    'Route lifetime is one named drive-call cycle',
    'Generated handoffs are deterministic',
    'Handoff remapping is not shipped',
    'Route muxing and route storage are not shipped',
    'Fan-in and fan-out are not shipped',
    'Ready/backpressure is not shipped',
    'Payload protocols are not shipped',
    'Route endpoint expressions are not shipped',
    'sink expression such as `(+ writer.payload 1)`',
    'source-order independent',
    '((out) 1)',
    'accepted actor-to-actor route is also source-order independent',
    'exact-width vector two-child actor-to-actor route set',
    'broader actor-to-actor generated-child',
);

for my $marker (@required_downstream_atl_markers) {
    like(
        $downstream_atl_section,
        qr{\Q$marker\E},
        "downstream ATL section keeps concept marker: $marker",
    );
}

my $route_terms_section = markdown_heading_section(
    $composition,
    '#### Generated-Child Route Terms',
);

ok(
    length($route_terms_section),
    'composition chapter keeps a dedicated generated-child route terms section',
);

my @required_route_term_markers = (
    '##### Route Lifetime And Value Boundary',
    '##### Generated Handoffs',
    '##### Handoff Remapping',
    '##### Diagnostic Ownership',
    '##### Route Muxing And Route Storage',
    '##### Fan-In And Fan-Out',
    '##### Ready/Backpressure',
    '##### Payload Protocols',
    'one child output reaches one child input',
    'named drive-call cycle',
    'Parameterized route drive definitions',
    'drive-call actual arguments',
    'Route endpoint expressions',
    'sink expression such as `(+ writer.payload 1)`',
    'source-order independent',
    '((out) 1)',
    'accepted actor-to-actor route is source-order independent',
    'Generated handoffs are',
    'Handoff remapping would',
    'Route muxing would',
    'storage would hold route data across cycles',
    'Fan-in would',
    'Fan-out would',
    'Ready/backpressure would',
    'Payload protocols would',
    'Parser-owned diagnostics',
    'The lowerer repeats the safety check',
    'already registered generated',
    'transfers each value during its named drive-call cycle',
);

for my $marker (@required_route_term_markers) {
    like(
        $route_terms_section,
        qr{\Q$marker\E},
        "generated-child route terms section keeps marker: $marker",
    );
}

unlike(
    $backlog,
    qr/Task-tree owner(?: for the remaining backlog)?:/,
    'feature backlog does not present closed task trees as current owners',
);

my @required_backlog_owner_markers = (
    'Historical task-tree record:',
    'That tree is closed; future repeat-body child-activation behavior needs a new',
    'task-tree leaf before implementation.',
    'That tree is closed; future ATL behavior changes need a new task-tree leaf',
);

for my $marker (@required_backlog_owner_markers) {
    like(
        $backlog,
        qr{\Q$marker\E},
        "feature backlog keeps owner-truth marker: $marker",
    );
}

unlike(
    $design,
    qr/Task-tree owner:/,
    'ATL design proposal does not present the closed ATL tree as a current owner',
);

like(
    $design,
    qr{\QHistorical task-tree record:\E},
    'ATL design proposal keeps the historical task-tree label',
);

like(
    $design,
    qr{\QThat tree is closed; future ATL behavior changes need new task-tree leaves\E},
    'ATL design proposal states future ATL changes need new task-tree leaves',
);

done_testing();

sub read_repo_file {
    my ($relpath) = @_;
    my $path = File::Spec->catfile($repo_root, split m{/}, $relpath);
    open my $fh, '<', $path or die "Unable to read $path: $!";
    my $content = do { local $/; <$fh> };
    close $fh;
    return $content;
}

sub markdown_heading_section {
    my ($content, $heading) = @_;
    my ($marks) = $heading =~ /^([#]+)\s+\S/;
    return '' unless defined $marks;
    my $level = length $marks;
    my $closing_heading = qr/^ [#]{1,$level} \s+ \S/msx;
    return $1 if $content =~ /^ \Q$heading\E \s* \n (.*?)(?=$closing_heading|\z)/msx;
    return '';
}
