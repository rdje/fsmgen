#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Spec;
use File::Temp qw(tempdir);
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Adapter::ISF;
use FSM::HDL::FlattenedDT;
use FSM::Pipeline::SourceFrontend;
use FSM::Scheduler::ISF;
use FSM::Scheduler::ISF::LoweringIR;

my $source = <<'ISF';
(actor rule_expression_assignment
  (clock clk)
  (reset (rst_n async active_low))
  (interface
    (input start)
    (input ready)
    (input req_valid)
    (input error_seen)
    (input count (width 8))
    (output valid)
    (output next_count (width 8))
    (output done))
  (transaction main
    (on start)
    (complete done))
  (rule drive_status ready
    (valid (| req_valid error_seen))
    (next_count (+ count 1))
    (trigger main)))
ISF

my $actor = FSM::Adapter::ISF->new()->parse_source($source, 'rule-expression-assignment.isf');
my $result = FSM::Scheduler::ISF->new()->lower($actor);
my $fsm = $result->{files}{'rule_expression_assignment.fsm'};

like(
    $fsm,
    qr/\(-drive_status\s+<ready\s+\(<- \(valid> \(\| req_valid error_seen\)\)\)\s+\(<- \(next_count> \(\+ count 1\)\)\)\s+\(<1 \(drive_status_main 1\)\)\s+\)/s,
    'rule expression assignments lower as flopped assignments in the guarded rule DT',
);
like(
    $fsm,
    qr/\(-main_trigger_fanin\s+\(= \(main_start drive_status_main\)\)\s+\)/s,
    'rule trigger fan-in remains separate from expression-valued data assignments',
);

my $ir = FSM::Scheduler::ISF::LoweringIR->new()->build_module($actor);
my $valid_record = find_record($ir, target => 'valid', source_kind => 'rule_action');
is($valid_record->{rhs}, '(| req_valid error_seen)', 'provenance records formatted expression RHS for valid');
is($valid_record->{operator}, '<-', 'expression rule assignment keeps flopped operator');
is($valid_record->{domain}, 'data', 'expression rule assignment remains in the data domain');

my $tempdir = tempdir(CLEANUP => 1);
my $fsm_path = File::Spec->catfile($tempdir, 'rule_expression_assignment.fsm');
write_file($fsm_path, $fsm);

my $raw_ast = FSM::Pipeline::SourceFrontend->parse_fsm_file(
    fsm_file => $fsm_path,
    debug_level => 0,
);
my $fsm_module = FSM::Pipeline::SourceFrontend->create_fsm_module(
    raw_ast => $raw_ast,
    debug_level => 0,
);
ok($fsm_module, 'scheduled .fsm with rule expression assignments parses through the normal .fsm frontend');

my $hdl = FSM::HDL::FlattenedDT->new(debug => 0)->generate_systemverilog($fsm_module);
like($hdl, qr/\bmodule\s+rule_expression_assignment\b/, 'rule expression assignment reaches HDL generation');

done_testing();

sub find_record {
    my ($ir, %want) = @_;
    RECORD:
    for my $record (@{$ir->{assignment_provenance} || []}) {
        for my $key (sort keys %want) {
            next RECORD unless defined($record->{$key}) && $record->{$key} eq $want{$key};
        }
        return $record;
    }
    fail('found provenance record for ' . join(', ', map { "$_=$want{$_}" } sort keys %want));
    return {};
}

sub write_file {
    my ($path, $content) = @_;
    open my $fh, '>', $path or die "Cannot open $path for write: $!";
    print {$fh} $content or die "Cannot write $path: $!";
    close $fh or die "Cannot close $path: $!";
}
