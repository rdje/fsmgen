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
    die "parallel-fiber construction does not contain exactly one source\n"
        unless @inputs == 1;
    return {
        text => $inputs[0]{content},
        source_name => $inputs[0]{relative_path},
        source_catalog => {},
    };
}

my $over_limit = $class->construct({
    primary_axis => 'fibers_per_parallel',
    level => 'over_limit_v1',
    reference_text => undef,
});
my $canonical = FSM::VIAL::Parser->check_source(parser_invocation($over_limit));
ok(!$canonical->{ok}, '257 fibers in one parallel form fail closed');
is(scalar(@{$canonical->{diagnostics}}), 1,
    'parallel-fiber excess returns one deterministic diagnostic');
is($canonical->{diagnostics}[0]{code}, 'VIAL_LIMIT_ERROR',
    'parallel-fiber excess uses the established limit code');
is($canonical->{diagnostics}[0]{phase}, 'limit',
    'parallel-fiber excess retains the limit phase');
is($canonical->{diagnostics}[0]{message}, 'parallel exceeds 256 fibers',
    'parallel-fiber excess retains the established message');
is($canonical->{diagnostics}[0]{semantic_path},
    '/packages/0/fixtures/0/scenarios/0/actions/0',
    'parallel-fiber excess retains the established action path');
ok(!defined($canonical->{semantic_report}),
    'parallel-fiber excess exposes no partial semantic report');

my $invalid_join = parser_invocation($over_limit);
my $replacements =
    ($invalid_join->{text} =~ s/\(parallel all/\(parallel bad/);
die "parallel-fiber join mutation did not match exactly once\n"
    unless $replacements == 1;
my $precedence = FSM::VIAL::Parser->check_source($invalid_join);
ok(!$precedence->{ok},
    'known parallel-fiber excess fails before join-value resolution');
is_deeply($precedence->{diagnostics}, $canonical->{diagnostics},
    'an invalid join cannot mask or move the parallel-fiber limit');
ok(!defined($precedence->{semantic_report}),
    'precedence failure exposes no partial semantic report');

my $at_limit = $class->evaluate({
    construction => $class->construct({
        primary_axis => 'fibers_per_parallel',
        level => 'limit_v1',
        reference_text => undef,
    }),
});
ok($at_limit->{ok}, '256 parallel fibers retain their accepted semantic route');
is($at_limit->{status}, 'accepted',
    'the exact parallel-fiber boundary remains accepted');
is($at_limit->{metrics}{fibers_per_parallel}, 256,
    'the accepted boundary retains all 256 fibers');
is($at_limit->{semantic_projection_sha256},
    'dc5cb88040017313929b1fecafce9b823a451cb22d46220f1c5a7c951bc7c9da',
    'the accepted boundary retains its semantic projection identity');
is($at_limit->{semantic_report_sha256},
    'b818bac3b2219f2adec45c933df49186dd0f42b683fca3ca5a77419bc17ef1e3',
    'the accepted boundary retains its semantic report identity');

done_testing;
