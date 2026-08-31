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
my $root_name = 'generated/vial-scale/semantic_catalog/root.vial';

sub parser_invocation {
    my ($construction) = @_;
    my ($root) = grep { $_->{relative_path} eq $root_name }
        @{$construction->{inputs}};
    die "direct-import construction has no root source\n" unless $root;
    my %catalog = map { $_->{relative_path} => $_->{content} }
        grep { $_->{relative_path} ne $root_name }
        @{$construction->{inputs}};
    return {
        text => $root->{content},
        source_name => $root_name,
        source_catalog => \%catalog,
    };
}

my $over_limit = $class->construct({
    primary_axis => 'imports',
    level => 'over_limit_v1',
    reference_text => undef,
});
my $canonical = FSM::VIAL::Parser->check_source(parser_invocation($over_limit));
ok(!$canonical->{ok}, '65 direct imports fail closed');
is(scalar(@{$canonical->{diagnostics}}), 1,
    'direct-import excess returns one deterministic diagnostic');
is($canonical->{diagnostics}[0]{code}, 'VIAL_LIMIT_ERROR',
    'direct-import excess uses the established limit code');
is($canonical->{diagnostics}[0]{phase}, 'limit',
    'direct-import excess retains the limit phase');
is($canonical->{diagnostics}[0]{message},
    'imported sources exceed the 64-source limit',
    'direct-import excess retains the established message');
is($canonical->{diagnostics}[0]{semantic_path}, '/packages/0/imports',
    'direct-import excess retains the established import path');
ok(!defined($canonical->{semantic_report}),
    'direct-import excess exposes no partial semantic report');

my $malformed_invocation = parser_invocation($over_limit);
my $first_import =
    'generated/vial-scale/semantic_catalog/import_00000000.vial';
die "direct-import construction has no first imported source\n"
    unless exists $malformed_invocation->{source_catalog}{$first_import};
$malformed_invocation->{source_catalog}{$first_import} = '(';
my $precedence = FSM::VIAL::Parser->check_source($malformed_invocation);
ok(!$precedence->{ok},
    'known direct-import excess fails before recursive source parsing');
is_deeply($precedence->{diagnostics}, $canonical->{diagnostics},
    'malformed imported content cannot mask or move the direct-import limit');
ok(!defined($precedence->{semantic_report}),
    'precedence failure exposes no partial semantic report');

my $at_limit = $class->evaluate({
    construction => $class->construct({
        primary_axis => 'imports',
        level => 'limit_v1',
        reference_text => undef,
    }),
});
ok($at_limit->{ok}, '64 direct imports retain their accepted semantic route');
is($at_limit->{status}, 'accepted',
    'the exact direct-import boundary remains accepted');
is($at_limit->{metrics}{imports}, 64,
    'the accepted boundary retains all 64 imports');
is($at_limit->{metrics}{sources}, 65,
    'the accepted boundary retains root plus 64 imported sources');
is($at_limit->{semantic_projection_sha256},
    '5dc5e920c45740bb43a8ced50e289dce390fb03dcd970cbe51440e38c87446b0',
    'the accepted boundary retains its semantic projection identity');
is($at_limit->{semantic_report_sha256},
    '17fa8ad2dec3b14064377fbb6ff34d81ec2804141cb031de00066ecdd73cc597',
    'the accepted boundary retains its semantic report identity');

done_testing;
