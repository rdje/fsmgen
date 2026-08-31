#!/usr/bin/env perl

use strict;
use warnings;

use File::Spec;
use FindBin;
use Test::More;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::VIAL::ArchitectureScaleSemanticCatalog;
use FSM::VIAL::Parser;

my $class = 'FSM::VIAL::ArchitectureScaleSemanticCatalog';

sub parser_invocation {
    my ($construction) = @_;
    my @inputs = @{$construction->{inputs}};
    die "coverage-bin construction does not contain exactly one source\n"
        unless @inputs == 1;
    return {
        text => $inputs[0]{content},
        source_name => $inputs[0]{relative_path},
        source_catalog => {},
    };
}

my $over_limit = $class->construct({
    primary_axis => 'coverage_bins',
    level => 'over_limit_v1',
    reference_text => undef,
});
my $canonical = FSM::VIAL::Parser->check_source(parser_invocation($over_limit));
ok(!$canonical->{ok}, 'cross max_bins 1,000,001 fails closed');
is(scalar(@{$canonical->{diagnostics}}), 1,
    'cross-max-bins excess returns one deterministic diagnostic');
is($canonical->{diagnostics}[0]{code}, 'VIAL_LIMIT_ERROR',
    'cross-max-bins excess uses the established limit code');
is($canonical->{diagnostics}[0]{phase}, 'limit',
    'cross-max-bins excess retains the limit phase');
is($canonical->{diagnostics}[0]{message},
    'integer is outside the bounded range 1 through 1000000',
    'cross-max-bins excess retains the established message');
is($canonical->{diagnostics}[0]{semantic_path},
    '/packages/0/fixtures/0/coverage/2/max_bins',
    'cross-max-bins excess retains the established scalar path');
ok(!defined($canonical->{semantic_report}),
    'cross-max-bins excess exposes no partial semantic report');

my $unresolved_point = parser_invocation($over_limit);
my $replacements = ($unresolved_point->{text} =~
    s/\(points point_a point_b\)/(points point_x point_b)/);
die "cross point mutation did not match exactly once\n"
    unless $replacements == 1;
my $precedence = FSM::VIAL::Parser->check_source($unresolved_point);
ok(!$precedence->{ok},
    'known cross-max-bins excess fails before coverpoint resolution');
is_deeply($precedence->{diagnostics}, $canonical->{diagnostics},
    'an unresolved coverpoint cannot mask or move the max_bins limit');
ok(!defined($precedence->{semantic_report}),
    'precedence failure exposes no partial semantic report');

my $at_limit = $class->evaluate({
    construction => $class->construct({
        primary_axis => 'coverage_bins',
        level => 'limit_v1',
        reference_text => undef,
    }),
});
ok($at_limit->{ok}, 'cross max_bins 1,000,000 retains its accepted route');
is($at_limit->{status}, 'accepted',
    'the exact cross-max-bins boundary remains accepted');
is($at_limit->{metrics}{coverage_bins}, 1_000_000,
    'the accepted boundary retains its full declared max_bins');
is($at_limit->{semantic_projection_sha256},
    'd7bb9eaa7c491a503e3e9569259263f1c711c91a60cd0057e8cb91ad3264a4f7',
    'the accepted boundary retains its semantic projection identity');
is($at_limit->{semantic_report_sha256},
    '51a77c3040242ccb1d8c03896073761f2d9d22af5b9d991d2b33a134f018ce14',
    'the accepted boundary retains its semantic report identity');

done_testing;
