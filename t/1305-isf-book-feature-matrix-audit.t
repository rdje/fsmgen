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
my $matrix = read_repo_file($matrix_path);
my $summary = read_repo_file('docs/book/src/SUMMARY.md');

like(
    $summary,
    qr{\[Feature Support Matrix\]\(13k-isf-feature-support-matrix\.md\)},
    'ISF feature support matrix is reachable from the mdBook summary',
);

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
    '(contract finish_seen',
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
    'stage/contract fixture',
    'FIFO datapath fixture',
    'FIFO controller fixture',
    'FIFO library fixture',
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
    'top-level contract arm states',
    'loop decision states',
    'top-level repeat-body local blocking do',
    'top-level when-body nested repeat local do',
    'top-level switch-branch nested repeat local do',
    'top-level when-body nested repeat generated spawns with optional static params, bind handoffs, same-domain domain metadata, source-order samples, same-body await_all, single-pending same-body await_any when exactly one generated child is pending, and multi-pending same-body await_any with mandatory same-body await_all drain',
    'top-level when-body nested repeat local do while generated nested spawn pending before same-body await_all drain',
    'top-level when-body nested repeat generated-child do while generated nested spawn pending before same-body await_all drain',
    'top-level when-body nested repeat generated do with static params while generated nested spawn pending before same-body await_all drain',
    'top-level when-body nested repeat generated do with static params and bind handoffs while generated nested spawn pending before same-body await_all drain',
    'top-level switch-branch nested repeat generated spawns with optional static params, bind handoffs, same-domain domain metadata, source-order samples, same-body await_all, single-pending same-body await_any when exactly one generated child is pending, and multi-pending same-body await_any with mandatory same-body await_all drain',
    'top-level switch-branch nested repeat local do while generated nested spawn pending before same-body await_all drain',
    'top-level switch-branch nested repeat generated-child do while generated nested spawn pending before same-body await_all drain',
    'top-level switch-branch nested repeat generated do with static params while generated nested spawn pending before same-body await_all drain',
    'top-level switch-branch nested repeat generated do with static params and bind handoffs while generated nested spawn pending before same-body await_all drain',
    'top-level repeat-body generated-child blocking do',
    'top-level repeat-body generated blocking do with static params, bind handoffs, and same-domain domain metadata',
    'samples before or after spawn before same-body sync',
    'samples before or after repeat-body do before the repeat check',
    'multi-pending repeat-body await_any with mandatory same-body await_all drain',
    'top-level repeat-body spawn with optional static params, optional bind handoffs, optional same-domain domain metadata, samples before or after spawn before same-body sync, same-body await_all, single-pending same-body await_any, and multi-pending repeat-body await_any with mandatory same-body await_all drain subset',
    'top-level when-body and switch-branch nested repeat generated spawns with same-body await_all, single-pending same-body await_any when exactly one generated child is pending, or multi-pending same-body await_any with mandatory same-body await_all drain',
    'top-level when-body nested repeat local do while generated nested spawn pending before same-body await_all drain subset',
    'top-level when-body nested repeat generated-child do while generated nested spawn pending before same-body await_all drain subset',
    'top-level when-body nested repeat generated do with static params while generated nested spawn pending before same-body await_all drain subset',
    'top-level when-body nested repeat generated do with static params and bind handoffs while generated nested spawn pending before same-body await_all drain subset',
    'top-level switch-branch nested repeat local do while generated nested spawn pending before same-body await_all drain subset',
    'top-level switch-branch nested repeat generated-child do while generated nested spawn pending before same-body await_all drain subset',
    'top-level switch-branch nested repeat generated do with static params while generated nested spawn pending before same-body await_all drain subset',
    'top-level switch-branch nested repeat generated do with static params and bind handoffs while generated nested spawn pending before same-body await_all drain subset',
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
        $matrix,
        qr{\Q$example\E},
        "matrix keeps representative example marker $example",
    );
}

my @required_non_claims = (
    'Multi-bit CDC payloads',
    'Cross-domain repeat-body `do`, generated or spawned nested activation',
    'cross-domain activation inside repeat bodies',
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
    'Raw parser actor hashes',
    'VHDL is recognized as a target family',
);

for my $non_claim (@required_non_claims) {
    like(
        $matrix,
        qr{\Q$non_claim\E},
        "matrix keeps explicit non-claim: $non_claim",
    );
}

done_testing();

sub read_repo_file {
    my ($relpath) = @_;
    my $path = File::Spec->catfile($repo_root, split m{/}, $relpath);
    open my $fh, '<', $path or die "Unable to read $path: $!";
    my $content = do { local $/; <$fh> };
    close $fh;
    return $content;
}
