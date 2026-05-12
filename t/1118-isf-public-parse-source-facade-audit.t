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

subtest 'parse_source returns a scheduler-consumable actor matching parse_file' => sub {
    my $path = File::Spec->catfile($FindBin::Bin, '..', 'isf', 'apb_requester.isf');
    open my $fh, '<', $path or die "cannot read $path: $!";
    my $source = do { local $/; <$fh> };
    close $fh or die "cannot close $path: $!";

    my $adapter = FSM::Adapter::ISF->new();
    my $from_file = $adapter->parse_file($path);
    my $from_source = $adapter->parse_source($source, 'inline-apb-requester.isf');
    my $scheduler = FSM::Scheduler::ISF->new();

    my $source_lowered = $scheduler->lower($from_source);
    my $file_lowered   = $scheduler->lower($from_file);
    is_deeply(
        sorted([keys %{$source_lowered->{files}}]),
        sorted([keys %{$file_lowered->{files}}]),
        'parse_source actor lowers to the same scheduled file set as parse_file',
    );
    like(
        $source_lowered->{files}{'apb_requester.fsm'},
        qr/\A\(\?fsm:apb_requester\b/,
        'parse_source lower result contains scheduler-consumable .fsm text',
    );

    my $source_report = JSON::PP->new->decode($scheduler->report($from_source));
    my $file_report   = JSON::PP->new->decode($scheduler->report($from_file));
    for my $key (qw(source scheduled_fsm clock watchdog port_count inputs outputs state_count)) {
        is($source_report->{$key}, $file_report->{$key}, "parse_source report matches parse_file $key");
    }
    is_deeply($source_report->{reset}, $file_report->{reset}, 'parse_source report matches parse_file reset summary');
    is_deeply(
        sorted_names($source_report->{inferred_storage}),
        sorted_names($file_report->{inferred_storage}),
        'parse_source report matches parse_file inferred storage names',
    );
    is_deeply(
        sorted_names($source_report->{transactions}),
        sorted_names($file_report->{transactions}),
        'parse_source report matches parse_file transaction names',
    );
    is_deeply(
        sorted_names($source_report->{dt_blocks}),
        sorted_names($file_report->{dt_blocks}),
        'parse_source report matches parse_file DT names',
    );
};

done_testing();

sub sorted {
    my ($values) = @_;
    return [sort @{$values || []}];
}

sub sorted_names {
    my ($entries) = @_;
    return [sort map { $_->{name} } @{$entries || []}];
}
