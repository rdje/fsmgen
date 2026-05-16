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

subtest 'actor-local aggregate storage leaves are valid rule guard expression operands' => sub {
    my $dir = tempdir(CLEANUP => 1);
    my $isf_path = File::Spec->catfile($dir, 'local_aggregate_rule_guard_value.isf');
    write_file($isf_path, <<'ISF');
(actor local_aggregate_rule_guard_value
  (types
    (type frame_t (record (mode (bits 2)) (flag bit))))
  (clock clk)
  (reset rst)
  (interface
    (input ready)
    (input frame_in (width 3))
    (output fire))
  (storage
    (var frame (type frame_t)))
  (transaction capture
    (on ready)
    (set frame frame_in))
  (rule fire_when_flag (& ready frame.flag)
    (set fire 1)))
ISF

    my $actor = FSM::Adapter::ISF->new()->parse_file($isf_path);
    my %rule_by_name = map { $_->{name} => $_ } @{$actor->{rules}};
    is_deeply(
        $rule_by_name{fire_when_flag}{when},
        ['when', ['&', 'ready', 'frame.flag']],
        'local aggregate rule guard expression normalizes into the public when field',
    );

    my $fsm = FSM::Scheduler::ISF->new()->lower($actor)->{files}{'local_aggregate_rule_guard_value.fsm'};
    like($fsm, qr/\(-fire_when_flag\s+<\(& ready frame\.flag\)\s+\(<- \(fire> 1\)\)\s+\)/s,
        'scheduled .fsm preserves local aggregate leaf rule guard expression operand');

    my $hdl_path = File::Spec->catfile($dir, 'local_aggregate_rule_guard_value.sv');
    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--strict', '--output', $hdl_path, $isf_path],
    );
    ok($success, 'CLI HDL generation succeeds for local aggregate rule guard expression operands');
    is(join('', @{$stderr_buf || []}), '', 'CLI keeps stderr clean for local aggregate rule guard expression operands');
    ok(-s $hdl_path, 'CLI writes HDL for local aggregate rule guard expression operands');
};

subtest 'package aggregate storage leaves are valid long-form rule guard expression operands' => sub {
    my $dir = tempdir(CLEANUP => 1);
    write_file(File::Spec->catfile($dir, 'shared.fsm'), <<'FSM');
(?pkg:shared
  (+types
    (type lanes_t (list bit (bits 2))))
)
FSM
    my $isf_path = File::Spec->catfile($dir, 'package_aggregate_rule_guard_value.isf');
    write_file($isf_path, <<'ISF');
(actor package_aggregate_rule_guard_value
  (imports
    (package shared))
  (clock clk)
  (reset rst)
  (interface
    (input ready)
    (input lanes_in (width 3))
    (output fire))
  (storage
    (var lanes (type shared.lanes_t)))
  (transaction capture
    (on ready)
    (set lanes lanes_in))
  (rule fire_when_lane
    (when (& ready lanes[1]))
    (fire 1)))
ISF

    my $actor = FSM::Adapter::ISF->new()->parse_file($isf_path);
    my %rule_by_name = map { $_->{name} => $_ } @{$actor->{rules}};
    is_deeply(
        $rule_by_name{fire_when_lane}{when},
        ['when', ['&', 'ready', 'lanes[1]']],
        'package aggregate rule guard expression normalizes into the public when field',
    );

    my $fsm = FSM::Scheduler::ISF->new()->lower($actor)->{files}{'package_aggregate_rule_guard_value.fsm'};
    like($fsm, qr/\(\+import\s+shared\s+\)/s, 'scheduled .fsm emits package import');
    like($fsm, qr/\(-fire_when_lane\s+<\(& ready lanes\[1\]\)\s+\(<- \(fire> 1\)\)\s+\)/s,
        'scheduled .fsm preserves package aggregate leaf rule guard expression operand');
    like($fsm, qr/\(\?pkg:shared[\s\S]*\(\+types[\s\S]*\(type lanes_t \(list bit \(bits 2\)\)\)/,
        'scheduled .fsm embeds imported aggregate package root');

    my $hdl_path = File::Spec->catfile($dir, 'package_aggregate_rule_guard_value.sv');
    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--strict', '--outdir', $dir, '--output', $hdl_path, $isf_path],
    );
    ok($success, 'CLI HDL generation succeeds for package aggregate rule guard expression operands');
    is(join('', @{$stderr_buf || []}), '', 'CLI keeps stderr clean for package aggregate rule guard expression operands');
    ok(-s $hdl_path, 'CLI writes HDL for package aggregate rule guard expression operands');
};

subtest 'rule guard aggregate diagnostics stay expression-operand-only' => sub {
    assert_parse_rejected(
        <<'ISF',
(actor aggregate_rule_guard_unknown_member
  (types
    (type frame_t (record (mode (bits 2)) (flag bit))))
  (clock clk)
  (reset rst)
  (interface
    (input ready)
    (output fire))
  (storage
    (var frame (type frame_t)))
  (rule fire_when_flag (& ready frame.missing)
    (set fire 1)))
ISF
        qr/invalid aggregate storage path 'frame\.missing': record member 'missing' is not declared; known members: mode, flag/,
        'unknown record member rule guard expression operand fails before lowering',
    );

    assert_parse_rejected(
        <<'ISF',
(actor aggregate_rule_guard_operator_path
  (types
    (type frame_t (record (mode (bits 2)) (flag bit))))
  (clock clk)
  (reset rst)
  (interface
    (input ready)
    (output fire))
  (storage
    (var frame (type frame_t)))
  (rule fire_when_flag
    (when (frame.flag ready))
    (set fire 1)))
ISF
        qr/rule 'fire_when_flag' guard expression operator references aggregate storage path 'frame\.flag'; this ISF slice accepts aggregate storage paths inside rule guard expressions only as scalar operands/,
        'aggregate rule guard expression operator paths remain deferred',
    );

    assert_parse_rejected(
        <<'ISF',
(actor aggregate_rule_guard_scalar_path
  (types
    (type frame_t (record (mode (bits 2)) (flag bit))))
  (clock clk)
  (reset rst)
  (interface
    (output fire))
  (storage
    (var frame (type frame_t)))
  (rule fire_when_flag frame.flag
    (set fire 1)))
ISF
        qr/rule 'fire_when_flag' guard references aggregate storage path 'frame\.flag'; this ISF slice accepts aggregate storage paths only as direct transaction set RHS scalar leaf reads, direct transaction set target scalar leaf writes, transaction condition expression scalar operands, rule assignment RHS scalar values or operands, rule guard expression scalar operands, drive body RHS scalar values or operands, inline drive assignment RHS scalar values or operands, or drive-call actual scalar values or operands/,
        'standalone aggregate rule guards remain deferred',
    );

    assert_parse_rejected(
        <<'ISF',
(actor aggregate_rule_guard_subaggregate_operand
  (types
    (type payload_t (list bit (bits 2)))
    (type frame_t (record (mode (bits 2)) (payload payload_t))))
  (clock clk)
  (reset rst)
  (interface
    (input ready)
    (output fire))
  (storage
    (var frame (type frame_t)))
  (rule fire_when_payload (& ready frame.payload)
    (set fire 1)))
ISF
        qr/rule 'fire_when_payload' guard references aggregate storage path 'frame\.payload' that resolves to aggregate kind 'list'; this ISF slice accepts only scalar aggregate leaf reads/,
        'subaggregate rule guard expression operands remain deferred',
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

sub write_file {
    my ($path, $content) = @_;
    open my $fh, '>', $path or die "open $path: $!";
    print {$fh} $content;
    close $fh or die "close $path: $!";
    return $path;
}
