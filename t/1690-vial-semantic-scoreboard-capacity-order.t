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
    die "scoreboard-capacity construction does not contain exactly one source\n"
        unless @inputs == 1;
    return {
        text => $inputs[0]{content},
        source_name => $inputs[0]{relative_path},
        source_catalog => {},
    };
}

my $over_limit = $class->construct({
    primary_axis => 'scoreboard_capacity',
    level => 'over_limit_v1',
    reference_text => undef,
});
my $canonical = FSM::VIAL::Parser->check_source(parser_invocation($over_limit));
ok(!$canonical->{ok}, 'scoreboard capacity 1,000,001 fails closed');
is(scalar(@{$canonical->{diagnostics}}), 1,
    'scoreboard-capacity excess returns one deterministic diagnostic');
is($canonical->{diagnostics}[0]{code}, 'VIAL_LIMIT_ERROR',
    'scoreboard-capacity excess uses the established limit code');
is($canonical->{diagnostics}[0]{phase}, 'limit',
    'scoreboard-capacity excess retains the limit phase');
is($canonical->{diagnostics}[0]{message},
    'integer is outside the bounded range 1 through 1000000',
    'scoreboard-capacity excess retains the established message');
is($canonical->{diagnostics}[0]{semantic_path},
    '/packages/0/scoreboards/0/capacity',
    'scoreboard-capacity excess retains the established scalar path');
ok(!defined($canonical->{semantic_report}),
    'scoreboard-capacity excess exposes no partial semantic report');

my $unresolved_transaction = parser_invocation($over_limit);
my $replacements = ($unresolved_transaction->{text} =~
    s/\(scoreboard scaled_scoreboard \(transaction txn\)/(scoreboard scaled_scoreboard (transaction bad)/);
die "scoreboard transaction mutation did not match exactly once\n"
    unless $replacements == 1;
my $precedence = FSM::VIAL::Parser->check_source($unresolved_transaction);
ok(!$precedence->{ok},
    'known scoreboard-capacity excess fails before transaction resolution');
is_deeply($precedence->{diagnostics}, $canonical->{diagnostics},
    'an unresolved transaction cannot mask or move the capacity limit');
ok(!defined($precedence->{semantic_report}),
    'precedence failure exposes no partial semantic report');

my $at_limit = $class->evaluate({
    construction => $class->construct({
        primary_axis => 'scoreboard_capacity',
        level => 'limit_v1',
        reference_text => undef,
    }),
});
ok($at_limit->{ok}, 'scoreboard capacity 1,000,000 retains its accepted route');
is($at_limit->{status}, 'accepted',
    'the exact scoreboard-capacity boundary remains accepted');
is($at_limit->{metrics}{scoreboard_capacity}, 1_000_000,
    'the accepted boundary retains its full declared capacity');
is($at_limit->{semantic_projection_sha256},
    '3f11f4feae0de3b00745d03c4c9f1e168689df1d1bedb8afd26fb26b3cdab011',
    'the accepted boundary retains its semantic projection identity');
is($at_limit->{semantic_report_sha256},
    '45b56915e01ca3198c5f5c7516f302844e3c2b7de9e4cf9be8f54791c8e97746',
    'the accepted boundary retains its semantic report identity');

done_testing;
