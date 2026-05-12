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
    build_isf_public_interface_contract
    isf_public_interface_dt_ordering_policy
);

subtest 'APB lowering emits public DT summaries in deterministic order' => sub {
    my $path = File::Spec->catfile($FindBin::Bin, '..', 'isf', 'apb_requester.isf');
    my $source = slurp($path);
    my $expected = [
        qw(
          apb_transfer_cc_inc
          access_phase
          done_phase
          penable
          psel
          setup_phase
        ),
    ];

    my $adapter = FSM::Adapter::ISF->new();
    my $scheduler = FSM::Scheduler::ISF->new();
    my $from_file = $adapter->parse_file($path);
    my $from_source = $adapter->parse_source($source, 'inline-apb-requester.isf');

    my $file_lowered = $scheduler->lower($from_file);
    my $source_lowered = $scheduler->lower($from_source);
    is_deeply(
        dt_block_names_from_fsm($file_lowered->{files}{'apb_requester.fsm'}),
        $expected,
        'parse_file scheduled .fsm emits DT blocks in deterministic lowering order',
    );
    is_deeply(
        dt_block_names_from_fsm($source_lowered->{files}{'apb_requester.fsm'}),
        $expected,
        'parse_source scheduled .fsm emits DT blocks in deterministic lowering order',
    );

    my $file_report = JSON::PP->new->decode($scheduler->report($from_file));
    my $source_report = JSON::PP->new->decode($scheduler->report($from_source));
    is_deeply(
        dt_block_names_from_report($file_report),
        $expected,
        'parse_file schedule report emits DT summaries in the same deterministic order',
    );
    is_deeply(
        dt_block_names_from_report($source_report),
        $expected,
        'parse_source schedule report emits DT summaries in the same deterministic order',
    );

    my $contract = build_isf_public_interface_contract();
    is(
        $contract->{scheduled_fsm_dt_ordering},
        isf_public_interface_dt_ordering_policy(),
        'contract advertises scheduled .fsm DT ordering policy',
    );
    is(
        $contract->{schedule_report_dt_ordering},
        isf_public_interface_dt_ordering_policy(),
        'contract advertises schedule-report DT ordering policy',
    );
};

done_testing();

sub slurp {
    my ($path) = @_;
    open my $fh, '<', $path or die "cannot read $path: $!";
    my $text = do { local $/; <$fh> };
    close $fh or die "cannot close $path: $!";
    return $text;
}

sub dt_block_names_from_fsm {
    my ($fsm_text) = @_;
    return [ $fsm_text =~ /^\s+\(-([A-Za-z_][A-Za-z0-9_]*)\b/gm ];
}

sub dt_block_names_from_report {
    my ($report) = @_;
    return [ map { $_->{name} } @{$report->{dt_blocks} || []} ];
}
