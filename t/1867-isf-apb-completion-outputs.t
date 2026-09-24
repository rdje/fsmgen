#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Spec;
use File::Temp qw(tempdir);
use lib 'perl', 't/lib';
use FSM::Test::ProjectDataLocality;
use FSM::Adapter::ISF;
use FSM::Scheduler::ISF;
use FSM::Pipeline::HDLGenerator;

my $actor = FSM::Adapter::ISF->new->parse_file('isf/apb_requester.isf');
my $lowered = FSM::Scheduler::ISF->new->lower($actor)->{files}{'apb_requester.fsm'};

subtest 'completion clears public bus outputs in one drive phase' => sub {
    my ($phase) = $lowered =~ /^  \(-done_phase\n(.*?^  \))/ms;
    ok(defined $phase, 'completion drive exists');
    for my $signal (qw(PSEL PENABLE)) {
        like($phase // '', qr/\Q(<- ($signal> 0) <done_phase_start)\E/,
            "completion writes zero to public $signal");
    }
    unlike($phase // '', qr/\(<- \((?:psel|penable)\b/,
        'completion does not write accidental lowercase internal signals');
    ok(!exists $actor->{drives}{psel} && !exists $actor->{drives}{penable},
        'unused drive helpers cannot expose external start/value controls');
};

my $work = tempdir(CLEANUP => 1);
my $path = File::Spec->catfile($work, 'apb_requester.fsm');
open my $fh, '>', $path or die "$path: $!";
print {$fh} $lowered or die "$path: $!";
close $fh or die "$path: $!";
my $result = FSM::Pipeline::HDLGenerator->new(
    debug_level => 0, target_language => 'systemverilog', quiet => 1,
)->generate_hdl_from_file($path);
my $ir = $result->{structural_rtl_ir};

subtest 'generated public ports match the authored APB interface' => sub {
    for my $direction (qw(input output)) {
        my @actual = sort map { $_->{name} }
            grep { $_->{direction} eq $direction && $_->{name} ne 'clk' && $_->{name} ne 'rst_n' }
            @{$ir->{ports}};
        my @expected = sort map { $_->{name} } @{$actor->{interface}{$direction . 's'}};
        is_deeply(\@actual, \@expected, "$direction ports have no accidental helper controls");
    }
};

subtest 'semantic driver provenance retains both completion clears' => sub {
    for my $signal (qw(PSEL PENABLE)) {
        my @records = grep {
            ($_->{provenance}{role} // '') eq 'dt_specific_enable'
                && $_->{provenance}{lhs_signal} eq $signal
                && $_->{provenance}{dt_name} eq '-done_phase'
                && $_->{provenance}{rhs_value} eq '0'
        } @{$ir->{assignment_records}};
        is(scalar @records, 1, "one completion clear driver for $signal");
        like($records[0]{rhs}{text} // '', qr/\bdone_phase_start\b/,
            "$signal clear is gated by the original completion phase") if @records;
    }
};

done_testing();
