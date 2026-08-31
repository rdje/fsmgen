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
my $root_path = 'generated/vial-scale/semantic_catalog/root.vial';

sub parser_invocation {
    my ($construction) = @_;
    my ($root) = grep { $_->{relative_path} eq $root_path }
        @{$construction->{inputs}};
    die "source-byte construction does not contain its root source\n"
        unless defined $root;
    my %catalog = map { $_->{relative_path} => $_->{content} }
        grep { $_->{relative_path} ne $root_path } @{$construction->{inputs}};
    return {
        text => $root->{content},
        source_name => $root->{relative_path},
        source_catalog => \%catalog,
    };
}

my @cases = (
    {
        axis => 'source_bytes_per_source', boundary => 1_048_576,
        message => 'source exceeds the 1048576-byte limit',
        path => '/',
        projection => 'fc7aa50eb35316b5178a9f0ddca21c21105b38657d8e269db74e5890c296e8e4',
        report => 'd0862f0658dee0f0bf455a752262ea4d4ad4f718182f12ca537936f0557ae024',
        corrupt => sub {
            my ($invocation) = @_;
            return substr($invocation->{text}, 0, 1, ')') eq '(';
        },
    },
    {
        axis => 'source_bytes_combined', boundary => 16_777_216,
        message => 'combined imported source bytes exceed the 16777216-byte limit',
        path => '/packages/0/imports',
        projection => 'c1e8b0b57511fdb638da20130e7f7dbf0a283c8e4f483462ac71a25ca70f5200',
        report => '31ed3d3ec7c5465207a6707837276180d4baed5b575e15b0c8ebb9fd9b2a8cf8',
        corrupt => sub {
            my ($invocation) = @_;
            my $last = 'generated/vial-scale/semantic_catalog/source_00000016.vial';
            die "combined-byte construction lacks its overflowing source\n"
                unless exists $invocation->{source_catalog}{$last};
            return substr($invocation->{source_catalog}{$last}, 0, 1, ')') eq '(';
        },
    },
);

for my $case (@cases) {
    subtest $case->{axis} => sub {
        my $over_limit = $class->construct({
            primary_axis => $case->{axis},
            level => 'over_limit_v1',
            reference_text => undef,
        });
        my $canonical = FSM::VIAL::Parser->check_source(
            parser_invocation($over_limit),
        );
        ok(!$canonical->{ok}, 'over-limit source bytes fail closed');
        is(scalar(@{$canonical->{diagnostics}}), 1,
            'source-byte excess returns one deterministic diagnostic');
        is($canonical->{diagnostics}[0]{code}, 'VIAL_LIMIT_ERROR',
            'source-byte excess uses the established limit code');
        is($canonical->{diagnostics}[0]{phase}, 'limit',
            'source-byte excess retains the limit phase');
        is($canonical->{diagnostics}[0]{message}, $case->{message},
            'source-byte excess retains the established message');
        is($canonical->{diagnostics}[0]{semantic_path}, $case->{path},
            'source-byte excess retains the established semantic path');
        ok(!defined($canonical->{semantic_report}),
            'source-byte excess exposes no partial semantic report');

        my $malformed_source = parser_invocation($over_limit);
        ok($case->{corrupt}->($malformed_source),
            'hostile mutation replaced one opening byte without changing size');
        my $precedence = FSM::VIAL::Parser->check_source($malformed_source);
        ok(!$precedence->{ok},
            'known source-byte excess fails before lexing malformed bytes');
        is_deeply($precedence->{diagnostics}, $canonical->{diagnostics},
            'malformed bytes cannot mask or move the source-byte limit');
        ok(!defined($precedence->{semantic_report}),
            'precedence failure exposes no partial semantic report');

        my $at_limit = $class->evaluate({
            construction => $class->construct({
                primary_axis => $case->{axis},
                level => 'limit_v1',
                reference_text => undef,
            }),
        });
        ok($at_limit->{ok}, 'exact source-byte boundary retains its accepted route');
        is($at_limit->{status}, 'accepted',
            'exact source-byte boundary remains accepted');
        is($at_limit->{metrics}{$case->{axis}}, $case->{boundary},
            'accepted boundary retains its complete byte count');
        is($at_limit->{semantic_projection_sha256}, $case->{projection},
            'accepted boundary retains its semantic projection identity');
        is($at_limit->{semantic_report_sha256}, $case->{report},
            'accepted boundary retains its semantic report identity');
    };
}

done_testing;
