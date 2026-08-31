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
my @cases = (
    {
        axis => 'scalar_or_list_length', boundary => 65_536,
        message => 'integer is outside the bounded range 1 through 65536',
        path => '/packages/0/types/0/type/length',
        projection => '3ecc27777058d4689443860bb45916ac79dffa0efc983a892b80919e6958e5f3',
        report => 'caec2676089fd7b83adfea651dab51debe640990d154b531701255a00f9c4ccf',
        mutate => sub { $_[0] =~ s/\(list 65537 \(logic 1\)\)/(list 65537 (bogus 1))/ },
    },
    {
        axis => 'record_fields', boundary => 256,
        message => 'record exceeds 256 fields',
        path => '/packages/0/types/0/type',
        projection => '4c9e9ac4217d9663806bddb47c22cbccb6d3137cc44c10f5d8e8e62da762586b',
        report => 'd7f8f8a0b8061eed07ced04737a517a6d3986bf8c162111b9d584d739c58cfaf',
        mutate => sub { $_[0] =~ s/\(field_00000000 \(logic 1\)\)/(field_00000000 (bogus 1))/ },
    },
    {
        axis => 'aggregate_depth', boundary => 32,
        message => 'aggregate nesting exceeds 32 levels',
        path => join('', '/packages/0/types/0/type', ('/element_type') x 32),
        projection => '61b56ad7deaeff5b2f4c2a5fc6733e12dedd4b8078d52de224b1dcfb6013f350',
        report => '68a839ca3a0ee3ce348cabcfaca59a148a113316408bf7fbde911fa478d52896',
        mutate => sub { $_[0] =~ s/\(logic 1\)/(bogus 1)/ },
    },
);

sub parser_invocation {
    my ($construction) = @_;
    my @inputs = @{$construction->{inputs}};
    die "type-shape construction does not contain exactly one source\n"
        unless @inputs == 1;
    return {
        text => $inputs[0]{content},
        source_name => $inputs[0]{relative_path},
        source_catalog => {},
    };
}

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
        ok(!$canonical->{ok}, 'over-limit type shape fails closed');
        is(scalar(@{$canonical->{diagnostics}}), 1,
            'type-shape excess returns one deterministic diagnostic');
        is($canonical->{diagnostics}[0]{code}, 'VIAL_LIMIT_ERROR',
            'type-shape excess uses the established limit code');
        is($canonical->{diagnostics}[0]{phase}, 'limit',
            'type-shape excess retains the limit phase');
        is($canonical->{diagnostics}[0]{message}, $case->{message},
            'type-shape excess retains the established message');
        is($canonical->{diagnostics}[0]{semantic_path}, $case->{path},
            'type-shape excess retains the established semantic path');
        ok(!defined($canonical->{semantic_report}),
            'type-shape excess exposes no partial semantic report');

        my $invalid_inner = parser_invocation($over_limit);
        my $replacements = $case->{mutate}->($invalid_inner->{text});
        die "$case->{axis} inner-type mutation did not match exactly once\n"
            unless $replacements == 1;
        my $precedence = FSM::VIAL::Parser->check_source($invalid_inner);
        ok(!$precedence->{ok},
            'known type-shape excess fails before inner-type resolution');
        is_deeply($precedence->{diagnostics}, $canonical->{diagnostics},
            'an invalid inner type cannot mask or move the shape limit');
        ok(!defined($precedence->{semantic_report}),
            'precedence failure exposes no partial semantic report');

        my $at_limit = $class->evaluate({
            construction => $class->construct({
                primary_axis => $case->{axis},
                level => 'limit_v1',
                reference_text => undef,
            }),
        });
        ok($at_limit->{ok}, 'exact type-shape boundary retains its accepted route');
        is($at_limit->{status}, 'accepted',
            'exact type-shape boundary remains accepted');
        is($at_limit->{metrics}{$case->{axis}}, $case->{boundary},
            'accepted boundary retains its complete requested shape');
        is($at_limit->{semantic_projection_sha256}, $case->{projection},
            'accepted boundary retains its semantic projection identity');
        is($at_limit->{semantic_report_sha256}, $case->{report},
            'accepted boundary retains its semantic report identity');
    };
}

done_testing;
