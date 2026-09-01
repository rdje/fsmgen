#!/usr/bin/env perl

use strict;
use warnings;

use Digest::SHA qw(sha256_hex);
use File::Spec;
use FindBin;
use JSON::PP ();
use Test::More;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::VIAL::ArchitectureScaleSemanticCatalog;
use FSM::VIAL::Parser;
use FSM::VIAL::SourceProjection;

my $catalog_class = 'FSM::VIAL::ArchitectureScaleSemanticCatalog';
my $json = JSON::PP->new->canonical(1)->utf8(1);

my $source_name = 'vial/ahb_subordinate_base_output_arbitration.vial';
my $source_path = File::Spec->catfile(
    $FindBin::Bin, '..', split(m{/}, $source_name),
);
open my $source_fh, '<:raw', $source_path
    or die "Cannot read $source_name: $!";
local $/;
my $source = <$source_fh>;
close $source_fh or die "Cannot close $source_name: $!";

sub with_first_reset_replaced {
    my ($replacement) = @_;
    my $mutated = $source;
    my $count = ($mutated =~ s/\(reset bus 3\)/$replacement/);
    die "action-cap mutation did not match exactly once\n" unless $count == 1;
    return $mutated;
}

sub check_earliest_action_cap {
    my ($label, $replacement) = @_;
    my $checked = FSM::VIAL::Parser->check_source({
        text => with_first_reset_replaced($replacement),
        source_name => $source_name,
        source_catalog => {},
    });

    ok(!$checked->{ok}, "$label fails closed");
    is(scalar(@{$checked->{diagnostics}}), 1,
        "$label returns one deterministic diagnostic");
    is($checked->{diagnostics}[0]{code}, 'VIAL_LIMIT_ERROR',
        "$label gives the action ceiling precedence over the later malformed sibling");
    is($checked->{diagnostics}[0]{phase}, 'limit',
        "$label retains the limit phase");
    is($checked->{diagnostics}[0]{message},
        'scenario exceeds 65536 expanded actions',
        "$label retains the established action-ceiling message");
    is($checked->{diagnostics}[0]{semantic_path},
        '/packages/0/fixtures/0/scenarios/0',
        "$label retains the established scenario path");
    ok(!defined($checked->{semantic_report}),
        "$label exposes no partial semantic report");
}

my $boundary_construction = $catalog_class->construct({
    primary_axis => 'literal_repeat_count',
    level => 'gate_candidate_v1',
    reference_text => undef,
});
is($boundary_construction->{specification}{backend_profile}, undef,
    'effective repeat boundary selects no backend');
is($boundary_construction->{specification}{tool_profile}, undef,
    'effective repeat boundary selects no external tool');
my @boundary_inputs = @{$boundary_construction->{inputs}};
is(scalar(@boundary_inputs), 1,
    'effective repeat boundary uses one canonical VIAL source');
my $boundary_text = $boundary_inputs[0]{content};
my $boundary_replacements =
    ($boundary_text =~ s/\(repeat 4096 /\(repeat 65535 /);
die "effective repeat-boundary mutation did not match exactly once\n"
    unless $boundary_replacements == 1;
my $boundary_invocation = {
    text => $boundary_text,
    source_name => $boundary_inputs[0]{relative_path},
    source_catalog => {},
};
my $boundary_checked = FSM::VIAL::Parser->check_source($boundary_invocation);
ok($boundary_checked->{ok},
    'repeat count 65535 reaches the accepted effective boundary');
diag($json->encode($boundary_checked->{diagnostics}))
    unless $boundary_checked->{ok};
my $boundary_ir = FSM::VIAL::Parser->parse_source($boundary_invocation);
my $boundary_data = $boundary_ir->as_hashref;
my $boundary_scenario =
    $boundary_data->{packages}[0]{fixtures}[0]{scenarios}[0];
is($boundary_scenario->{actions}[0]{count}, 65_535,
    'accepted effective boundary retains the literal repeat count');
is($boundary_scenario->{action_count}, 65_536,
    'accepted effective boundary reaches the expanded-action ceiling exactly');
is(FSM::VIAL::SourceProjection->semantic_projection_sha256($boundary_ir),
    'fa7bd219ec498b398d3879bef3d4e23adf033b1820a63e05ebbe9d3b52caaf54',
    'accepted effective boundary retains its semantic projection identity');
is(sha256_hex($json->encode($boundary_checked->{semantic_report})),
    '68ad63316b17a6bbe4dacfaadc4d54b495cf8476f95646544c21ecb8baff179a',
    'accepted effective boundary retains its semantic report identity');

check_earliest_action_cap(
    'repeat-expanded excess',
    '(repeat 65536 (reset bus 1)) (unknown_action)',
);
check_earliest_action_cap(
    'full boundary before another action',
    '(repeat 65535 (reset bus 1)) (unknown_action)',
);
check_earliest_action_cap(
    'full boundary before malformed action syntax',
    '(repeat 65535 (reset bus 1)) malformed_action_atom',
);

done_testing;
