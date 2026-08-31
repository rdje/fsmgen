#!/usr/bin/env perl

use strict;
use warnings;

use File::Spec;
use FindBin;
use Test::More;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::VIAL::Parser;

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
