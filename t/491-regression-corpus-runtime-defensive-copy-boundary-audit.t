#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;
use Scalar::Util qw(refaddr);

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');
use lib File::Spec->catdir($FindBin::Bin, 'lib');

use FSM::Support::RegressionCorpus qw(
    protocol_fixture_entries
    regression_corpus_entries
);
use FSM::Test::DefensiveCopyAudit qw(
    contains_sentinel
    mutate_structure
);

my $sentinel = '__mutated_by_t491__';

assert_catalog_returns_fresh_entries(
    label => 'regression corpus',
    build => sub { regression_corpus_entries() },
);

assert_catalog_returns_fresh_entries(
    label => 'protocol fixture corpus',
    build => sub { protocol_fixture_entries() },
);

done_testing();

sub assert_catalog_returns_fresh_entries {
    my (%args) = @_;
    my $label = $args{label};
    my $build = $args{build};

    subtest "$label entries return fresh structures" => sub {
        my @first = $build->();
        my @second = $build->();

        ok(@first, "$label exposes entries");
        is_deeply(
            [map { $_->{id} } @second],
            [map { $_->{id} } @first],
            "$label preserves entry id order across calls",
        );

        for my $index (0 .. $#first) {
            my $first_entry = $first[$index];
            my $second_entry = $second[$index];
            my $id = $first_entry->{id};

            isnt(refaddr($first_entry), refaddr($second_entry), "$label entry $id hash is fresh");

            for my $field (qw(expected_child_modules expected_hdl_patterns search_path_relpaths)) {
                next unless ref($first_entry->{$field}) eq 'ARRAY';
                ok(ref($second_entry->{$field}) eq 'ARRAY', "$label entry $id keeps $field as an array");
                isnt(
                    refaddr($first_entry->{$field}),
                    refaddr($second_entry->{$field}),
                    "$label entry $id $field array is fresh",
                );
            }

            assert_no_shared_mutable_refs(
                $first_entry,
                $second_entry,
                "$label entry $id",
            );
        }

        mutate_structure(\@first, $sentinel);
        my @third = $build->();

        ok(!contains_sentinel(\@third, $sentinel), "$label fresh lookup is not affected by prior caller mutation");
        is_deeply(
            [map { $_->{id} } @third],
            [map { $_->{id} } @second],
            "$label fresh lookup preserves canonical entry id order after mutation",
        );
    };
}

sub assert_no_shared_mutable_refs {
    my ($left, $right, $label) = @_;
    return unless ref($left) && ref($right);
    return unless ref($left) eq ref($right);

    if (ref($left) eq 'HASH') {
        isnt(refaddr($left), refaddr($right), "$label hash container is fresh");
        for my $key (sort keys %{$left}) {
            next unless exists $right->{$key};
            assert_no_shared_mutable_refs($left->{$key}, $right->{$key}, "$label.$key");
        }
        return;
    }

    if (ref($left) eq 'ARRAY') {
        isnt(refaddr($left), refaddr($right), "$label array container is fresh");
        for my $index (0 .. $#{$left}) {
            next unless exists $right->[$index];
            assert_no_shared_mutable_refs($left->[$index], $right->[$index], "$label\[$index\]");
        }
    }
}
