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
    die "declaration construction does not contain exactly one source\n"
        unless @inputs == 1;
    return {
        text => $inputs[0]{content},
        source_name => $inputs[0]{relative_path},
        source_catalog => {},
    };
}

my $over_limit = $class->construct({
    primary_axis => 'declarations',
    level => 'over_limit_v1',
    reference_text => undef,
});
my $canonical = FSM::VIAL::Parser->check_source(parser_invocation($over_limit));
ok(!$canonical->{ok}, '4097 declarations in one section fail closed');
is(scalar(@{$canonical->{diagnostics}}), 1,
    'declaration excess returns one deterministic diagnostic');
is($canonical->{diagnostics}[0]{code}, 'VIAL_LIMIT_ERROR',
    'declaration excess uses the established limit code');
is($canonical->{diagnostics}[0]{phase}, 'limit',
    'declaration excess retains the limit phase');
is($canonical->{diagnostics}[0]{message},
    "package section 'types' exceeds 4096 declarations",
    'declaration excess retains the established message');
is($canonical->{diagnostics}[0]{semantic_path}, '/packages/0/types',
    'declaration excess retains the established section path');
ok(!defined($canonical->{semantic_report}),
    'declaration excess exposes no partial semantic report');

my $malformed_later_section = parser_invocation($over_limit);
my $replacements = ($malformed_later_section->{text} =~
    s/\(transactions/\(transactioxx/);
die "later-section mutation did not match exactly once\n"
    unless $replacements == 1;
my $precedence = FSM::VIAL::Parser->check_source($malformed_later_section);
ok(!$precedence->{ok},
    'known declaration excess fails before later section parsing');
is_deeply($precedence->{diagnostics}, $canonical->{diagnostics},
    'a malformed later section cannot mask or move the declaration limit');
ok(!defined($precedence->{semantic_report}),
    'precedence failure exposes no partial semantic report');

my $at_limit = $class->evaluate({
    construction => $class->construct({
        primary_axis => 'declarations',
        level => 'limit_v1',
        reference_text => undef,
    }),
});
ok($at_limit->{ok}, '4096 declarations retain their accepted semantic route');
is($at_limit->{status}, 'accepted',
    'the exact declaration boundary remains accepted');
is($at_limit->{metrics}{declarations}, 4_096,
    'the accepted boundary retains all declarations');
is($at_limit->{semantic_projection_sha256},
    'e794a3ef46ca2033ef2b5b1f5a2e1dae2e6e1e43c5f29b64d1bb73f4fb220bf4',
    'the accepted boundary retains its semantic projection identity');
is($at_limit->{semantic_report_sha256},
    'f0477be32c1dd412c7708b7602a5a846d911e15654891ab417489386effb3b73',
    'the accepted boundary retains its semantic report identity');

done_testing;
