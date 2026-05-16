#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Spec;
use File::Temp qw(tempdir);
use FindBin;
use IPC::Cmd qw(run);

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Adapter::ISF;
use FSM::Scheduler::ISF;
use FSM::Scheduler::ISF::LoweringIR;

subtest 'actor-local aggregate storage leaves are valid named drive targets' => sub {
    my $dir = tempdir(CLEANUP => 1);
    my $isf_path = File::Spec->catfile($dir, 'local_aggregate_drive_target.isf');
    write_file($isf_path, <<'ISF');
(actor local_aggregate_drive_target
  (types
    (type frame_t (record (mode (bits 2)) (flag bit))))
  (clock clk)
  (reset rst)
  (interface
    (input start)
    (input mode_in (width 2))
    (input flag_in)
    (output done))
  (storage
    (var frame (type frame_t)))
  (drive capture
    (frame.mode mode_in)
    (frame.flag flag_in))
  (transaction main
    (on start)
    (drive capture)
    (complete done)))
ISF

    my $actor = FSM::Adapter::ISF->new()->parse_file($isf_path);
    my $fsm = FSM::Scheduler::ISF->new()->lower($actor)->{files}{'local_aggregate_drive_target.fsm'};
    like($fsm, qr/\(\+size[\s\S]*\(frame frame_t\)/,
        'scheduled .fsm preserves aggregate carrier type');
    like($fsm, qr/\(-capture[\s\S]*\(<- \(frame\.mode mode_in\)/,
        'scheduled .fsm preserves record member drive target');
    like($fsm, qr/\(-capture[\s\S]*\(<- \(frame\.flag flag_in\)/,
        'scheduled .fsm preserves one-bit record member drive target');

    my $ir = FSM::Scheduler::ISF::LoweringIR->new()->build_module($actor);
    my $mode_record = find_record($ir, target => 'frame.mode', source_kind => 'drive_body');
    is($mode_record->{rhs}, 'mode_in', 'assignment provenance records aggregate leaf drive target');
    is($mode_record->{operator}, '<-', 'aggregate drive target keeps flopped operator');
    is($mode_record->{domain}, 'data', 'aggregate drive target remains in the data domain');

    my $hdl_path = File::Spec->catfile($dir, 'local_aggregate_drive_target.sv');
    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--strict', '--output', $hdl_path, $isf_path],
    );
    ok($success, 'CLI HDL generation succeeds for local aggregate drive targets');
    is(join('', @{$stderr_buf || []}), '', 'CLI keeps stderr clean for local aggregate drive targets');
    ok(-s $hdl_path, 'CLI writes HDL for local aggregate drive targets');
};

subtest 'package aggregate storage leaves are valid named drive targets' => sub {
    my $dir = tempdir(CLEANUP => 1);
    write_file(File::Spec->catfile($dir, 'shared.fsm'), <<'FSM');
(?pkg:shared
  (+types
    (type lanes_t (list bit (bits 2))))
)
FSM
    my $isf_path = File::Spec->catfile($dir, 'package_aggregate_drive_target.isf');
    write_file($isf_path, <<'ISF');
(actor package_aggregate_drive_target
  (imports
    (package shared))
  (clock clk)
  (reset rst)
  (interface
    (input start)
    (input bit_in)
    (input pair_in (width 2))
    (output done))
  (storage
    (var lanes (type shared.lanes_t)))
  (drive capture
    (lanes[0] bit_in)
    (lanes[1] pair_in))
  (transaction main
    (on start)
    (drive capture)
    (complete done)))
ISF

    my $actor = FSM::Adapter::ISF->new()->parse_file($isf_path);
    my $fsm = FSM::Scheduler::ISF->new()->lower($actor)->{files}{'package_aggregate_drive_target.fsm'};
    like($fsm, qr/\(\+import\s+shared\s+\)/s, 'scheduled .fsm emits package import');
    like($fsm, qr/\(-capture[\s\S]*\(<- \(lanes\[0\] bit_in\)/,
        'scheduled .fsm preserves package list scalar drive target');
    like($fsm, qr/\(-capture[\s\S]*\(<- \(lanes\[1\] pair_in\)/,
        'scheduled .fsm preserves package list multi-bit drive target');
    like($fsm, qr/\(\?pkg:shared[\s\S]*\(\+types[\s\S]*\(type lanes_t \(list bit \(bits 2\)\)\)/,
        'scheduled .fsm embeds imported aggregate package root');

    my $ir = FSM::Scheduler::ISF::LoweringIR->new()->build_module($actor);
    my $pair_record = find_record($ir, target => 'lanes[1]', source_kind => 'drive_body');
    is($pair_record->{rhs}, 'pair_in', 'assignment provenance records package aggregate leaf drive target');

    my $hdl_path = File::Spec->catfile($dir, 'package_aggregate_drive_target.sv');
    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--strict', '--outdir', $dir, '--output', $hdl_path, $isf_path],
    );
    ok($success, 'CLI HDL generation succeeds for package aggregate drive targets');
    is(join('', @{$stderr_buf || []}), '', 'CLI keeps stderr clean for package aggregate drive targets');
    ok(-s $hdl_path, 'CLI writes HDL for package aggregate drive targets');
};

subtest 'named drive aggregate target diagnostics stay scalar-leaf-only' => sub {
    assert_parse_rejected(
        <<'ISF',
(actor aggregate_drive_unknown_target_member
  (types
    (type frame_t (record (mode (bits 2)) (flag bit))))
  (clock clk)
  (reset rst)
  (interface
    (input start)
    (input mode_in (width 2)))
  (storage
    (var frame (type frame_t)))
  (drive capture
    (frame.missing mode_in))
  (transaction main
    (on start)
    (drive capture)))
ISF
        qr/invalid aggregate storage path 'frame\.missing': record member 'missing' is not declared; known members: mode, flag/,
        'unknown record member drive target fails before lowering',
    );

    assert_parse_rejected(
        <<'ISF',
(actor aggregate_drive_subaggregate_target
  (types
    (type payload_t (list bit (bits 2)))
    (type frame_t (record (mode (bits 2)) (payload payload_t))))
  (clock clk)
  (reset rst)
  (interface
    (input start)
    (input payload_in (width 3)))
  (storage
    (var frame (type frame_t)))
  (drive capture
    (frame.payload payload_in))
  (transaction main
    (on start)
    (drive capture)))
ISF
        qr/drive 'capture' target references aggregate storage path 'frame\.payload' that resolves to aggregate kind 'list'; this ISF slice accepts only scalar aggregate leaf writes/,
        'subaggregate drive targets remain deferred',
    );
};

done_testing();

sub assert_parse_rejected {
    my ($source, $regex, $label) = @_;
    my $ok = eval {
        FSM::Adapter::ISF->new()->parse_source($source, "$label.isf");
        1;
    };
    ok(!$ok, "$label is rejected");
    like($@, $regex, "$label diagnostic");
}

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
    open my $fh, '>', $path or die "open $path: $!";
    print {$fh} $content;
    close $fh or die "close $path: $!";
    return $path;
}
