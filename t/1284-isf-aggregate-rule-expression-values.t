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

subtest 'actor-local aggregate storage leaves are valid rule assignment RHS expression operands' => sub {
    my $dir = tempdir(CLEANUP => 1);
    my $isf_path = File::Spec->catfile($dir, 'local_aggregate_rule_expression_value.isf');
    write_file($isf_path, <<'ISF');
(actor local_aggregate_rule_expression_value
  (types
    (type frame_t (record (mode (bits 2)) (flag bit))))
  (clock clk)
  (reset rst)
  (interface
    (input ready)
    (input frame_in (width 3))
    (input mode_in (width 2))
    (output mode_out (width 2)))
  (storage
    (var frame (type frame_t)))
  (transaction capture
    (on ready)
    (set frame frame_in))
  (rule expose_mode ready
    (set mode_out (+ frame.mode mode_in))))
ISF

    my $actor = FSM::Adapter::ISF->new()->parse_file($isf_path);
    my $fsm = FSM::Scheduler::ISF->new()->lower($actor)->{files}{'local_aggregate_rule_expression_value.fsm'};
    like($fsm, qr/\(-expose_mode\s+<ready\s+\(<- \(mode_out> \(\+ frame\.mode mode_in\)\)\)\s+\)/s,
        'scheduled .fsm preserves aggregate leaf rule RHS expression operand');

    my $ir = FSM::Scheduler::ISF::LoweringIR->new()->build_module($actor);
    my $record = find_record($ir, target => 'mode_out', source_kind => 'rule_action');
    is($record->{rhs}, '(+ frame.mode mode_in)', 'assignment provenance records aggregate leaf expression RHS');
    is($record->{operator}, '<-', 'aggregate rule expression assignment keeps flopped operator');
    is($record->{domain}, 'data', 'aggregate rule expression assignment remains in the data domain');

    my $hdl_path = File::Spec->catfile($dir, 'local_aggregate_rule_expression_value.sv');
    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--strict', '--output', $hdl_path, $isf_path],
    );
    ok($success, 'CLI HDL generation succeeds for local aggregate rule RHS expression operands');
    is(join('', @{$stderr_buf || []}), '', 'CLI keeps stderr clean for local aggregate rule RHS expression operands');
    ok(-s $hdl_path, 'CLI writes HDL for local aggregate rule RHS expression operands');
};

subtest 'package aggregate storage leaves are valid shorthand rule assignment RHS expression operands' => sub {
    my $dir = tempdir(CLEANUP => 1);
    write_file(File::Spec->catfile($dir, 'shared.fsm'), <<'FSM');
(?pkg:shared
  (+types
    (type lanes_t (list bit (bits 2))))
)
FSM
    my $isf_path = File::Spec->catfile($dir, 'package_aggregate_rule_expression_value.isf');
    write_file($isf_path, <<'ISF');
(actor package_aggregate_rule_expression_value
  (imports
    (package shared))
  (clock clk)
  (reset rst)
  (interface
    (input ready)
    (input lanes_in (width 3))
    (input pair_in (width 2))
    (output pair_out (width 2)))
  (storage
    (var lanes (type shared.lanes_t)))
  (transaction capture
    (on ready)
    (set lanes lanes_in))
  (rule expose_pair ready
    (pair_out (^ lanes[1] pair_in))))
ISF

    my $actor = FSM::Adapter::ISF->new()->parse_file($isf_path);
    my $fsm = FSM::Scheduler::ISF->new()->lower($actor)->{files}{'package_aggregate_rule_expression_value.fsm'};
    like($fsm, qr/\(\+import\s+shared\s+\)/s, 'scheduled .fsm emits package import');
    like($fsm, qr/\(-expose_pair\s+<ready\s+\(<- \(pair_out> \(\^ lanes\[1\] pair_in\)\)\)\s+\)/s,
        'scheduled .fsm preserves package aggregate leaf shorthand rule RHS expression operand');
    like($fsm, qr/\(\?pkg:shared[\s\S]*\(\+types[\s\S]*\(type lanes_t \(list bit \(bits 2\)\)\)/,
        'scheduled .fsm embeds imported aggregate package root');

    my $hdl_path = File::Spec->catfile($dir, 'package_aggregate_rule_expression_value.sv');
    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--strict', '--outdir', $dir, '--output', $hdl_path, $isf_path],
    );
    ok($success, 'CLI HDL generation succeeds for package aggregate rule RHS expression operands');
    is(join('', @{$stderr_buf || []}), '', 'CLI keeps stderr clean for package aggregate rule RHS expression operands');
    ok(-s $hdl_path, 'CLI writes HDL for package aggregate rule RHS expression operands');
};

subtest 'rule aggregate expression diagnostics stay operand-only' => sub {
    assert_parse_rejected(
        <<'ISF',
(actor aggregate_rule_expr_unknown_member
  (types
    (type frame_t (record (mode (bits 2)) (flag bit))))
  (clock clk)
  (reset rst)
  (interface
    (input ready)
    (output mode_out (width 2)))
  (storage
    (var frame (type frame_t)))
  (rule expose_mode ready
    (set mode_out (+ frame.missing 1))))
ISF
        qr/invalid aggregate storage path 'frame\.missing': record member 'missing' is not declared; known members: mode, flag/,
        'unknown record member rule RHS expression operand fails before lowering',
    );

    assert_parse_rejected(
        <<'ISF',
(actor aggregate_rule_expr_operator_path
  (types
    (type frame_t (record (mode (bits 2)) (flag bit))))
  (clock clk)
  (reset rst)
  (interface
    (input ready)
    (output mode_out (width 2)))
  (storage
    (var frame (type frame_t)))
  (rule expose_mode ready
    (set mode_out (frame.mode 1))))
ISF
        qr/rule 'expose_mode' assignment RHS expression operator references aggregate storage path 'frame\.mode'; this ISF slice accepts aggregate storage paths inside rule assignment RHS expressions only as scalar operands/,
        'aggregate rule RHS expression operator paths remain deferred',
    );

    assert_parse_rejected(
        <<'ISF',
(actor aggregate_rule_expr_subaggregate_operand
  (types
    (type payload_t (list bit (bits 2)))
    (type frame_t (record (mode (bits 2)) (payload payload_t))))
  (clock clk)
  (reset rst)
  (interface
    (input ready)
    (output mode_out (width 2)))
  (storage
    (var frame (type frame_t)))
  (rule expose_mode ready
    (set mode_out (+ frame.payload 1))))
ISF
        qr/rule 'expose_mode' assignment RHS references aggregate storage path 'frame\.payload' that resolves to aggregate kind 'list'; this ISF slice accepts only scalar aggregate leaf reads/,
        'subaggregate rule RHS expression operands remain deferred',
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
