#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;
use JSON::PP ();

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Adapter::ISF;
use FSM::Scheduler::ISF;
use FSM::Support::ISFPublicInterfaceContract qw(
    isf_public_interface_schedule_report_presence_key_family_map
    isf_public_interface_schedule_report_top_level_keys
);

subtest 'APB schedule report conforms to advertised public key families' => sub {
    my $isf_file = File::Spec->catfile($FindBin::Bin, '..', 'isf', 'apb_requester.isf');
    my $actor    = FSM::Adapter::ISF->new()->parse_file($isf_file);
    my $report   = JSON::PP->new->decode(FSM::Scheduler::ISF->new()->report($actor));
    my $families = isf_public_interface_schedule_report_presence_key_family_map();

    is_deeply(
        sorted([keys %{$report}]),
        sorted(isf_public_interface_schedule_report_top_level_keys()),
        'schedule report exposes exactly the advertised top-level keys',
    );
    is_deeply(
        sorted([keys %{$report->{reset}}]),
        sorted($families->{schedule_report_reset_keys}),
        'reset summary exposes exactly the advertised keys',
    );

    for my $entry (@{$report->{actor_constants}}) {
        is_deeply(
            sorted([keys %{$entry}]),
            sorted($families->{schedule_report_actor_constant_keys}),
            "actor constant entry $entry->{name} exposes exactly the advertised keys",
        );
    }

    for my $entry (@{$report->{inferred_storage}}) {
        assert_required_and_optional_keys(
            $entry,
            $families->{schedule_report_storage_required_keys},
            $families->{schedule_report_storage_optional_keys},
            "storage entry $entry->{name}",
        );
    }

    for my $entry (@{$report->{transactions}}) {
        is_deeply(
            sorted([keys %{$entry}]),
            sorted($families->{schedule_report_transaction_keys}),
            "transaction entry $entry->{name} exposes exactly the advertised keys",
        );
    }

    is(ref($report->{transaction_stages}), 'ARRAY', 'transaction_stages is an array in the advertised report shell');
    is(ref($report->{actor_constants}), 'ARRAY', 'actor_constants is an array in the advertised report shell');
    is(ref($report->{transaction_waits}), 'ARRAY', 'transaction_waits is an array in the advertised report shell');
    is(ref($report->{transaction_loops}), 'ARRAY', 'transaction_loops is an array in the advertised report shell');
    is(ref($report->{temporal_contracts}), 'ARRAY', 'temporal_contracts is an array in the advertised report shell');
    is(ref($report->{bank_accesses}), 'ARRAY', 'bank_accesses is an array in the advertised report shell');
    is(ref($report->{transaction_port_bindings}), 'ARRAY', 'transaction_port_bindings is an array in the advertised report shell');
    is(scalar(@{$report->{transaction_stages}}), 0, 'APB report has no transaction stage summaries');
    is(scalar(@{$report->{actor_constants}}), 0, 'APB report has no actor constant summaries');
    is(scalar(@{$report->{transaction_waits}}), 0, 'APB report has no transaction wait summaries');
    is(scalar(@{$report->{transaction_loops}}), 0, 'APB report has no transaction loop summaries');
    is(scalar(@{$report->{temporal_contracts}}), 0, 'APB report has no temporal contract summaries');
    is(scalar(@{$report->{bank_accesses}}), 0, 'APB report has no bank access summaries');
    is(scalar(@{$report->{transaction_port_bindings}}), 0, 'APB report has no transaction port binding summaries');

    for my $entry (@{$report->{dt_blocks}}) {
        is_deeply(
            sorted([keys %{$entry}]),
            sorted($families->{schedule_report_dt_keys}),
            "DT entry $entry->{name} exposes exactly the advertised keys",
        );
    }

    is(ref($report->{compile_issues}), 'ARRAY', 'compile_issues is an array in the advertised report shell');
    is(ref($report->{compatible_fanin_groups}), 'ARRAY', 'compatible_fanin_groups is an array in the advertised report shell');
    is(ref($report->{library_uses}), 'ARRAY', 'library_uses is an array in the advertised report shell');
    is_deeply($report->{library_uses}, [], 'library_uses is empty when no ISF libraries are used');
    is($report->{generated_composition}, undef, 'generated_composition is null when no generated top exists');
};

done_testing();

sub assert_required_and_optional_keys {
    my ($entry, $required, $optional, $label) = @_;
    my %allowed = map { $_ => 1 } (@{$required || []}, @{$optional || []});

    for my $key (@{$required || []}) {
        ok(exists $entry->{$key}, "$label keeps required key $key");
    }

    for my $key (sort keys %{$entry}) {
        ok($allowed{$key}, "$label key $key is advertised");
    }
}

sub sorted {
    my ($values) = @_;
    return [sort @{$values || []}];
}
