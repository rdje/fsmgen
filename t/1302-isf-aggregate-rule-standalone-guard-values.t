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

subtest 'actor-local aggregate storage leaves are valid standalone rule guards' => sub {
    my $dir = tempdir(CLEANUP => 1);
    my $isf_path = File::Spec->catfile($dir, 'local_aggregate_rule_standalone_guard.isf');
    write_file($isf_path, <<'ISF');
(actor local_aggregate_rule_standalone_guard
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

    my $actor = FSM::Adapter::ISF->new()->parse_file($isf_path);
    my %rule_by_name = map { $_->{name} => $_ } @{$actor->{rules}};
    is_deeply(
        $rule_by_name{fire_when_flag}{when},
        ['when', 'frame.flag'],
        'local standalone aggregate rule guard normalizes into the public when field',
    );

    my $fsm = FSM::Scheduler::ISF->new()->lower($actor)->{files}{'local_aggregate_rule_standalone_guard.fsm'};
    like($fsm, qr/\(\+types\s+\(type frame_t \(record \(mode \(bits 2\)\) \(flag bit\)\)\)\s+\)/s,
        'scheduled .fsm preserves local aggregate type declaration');
    like($fsm, qr/\(-fire_when_flag\s+<frame\.flag\s+\(<- \(fire> 1\)\)\s+\)/s,
        'scheduled .fsm preserves standalone local aggregate leaf rule guard');

    my $hdl_path = File::Spec->catfile($dir, 'local_aggregate_rule_standalone_guard.sv');
    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--strict', '--output', $hdl_path, $isf_path],
    );
    ok($success, 'CLI HDL generation succeeds for local standalone aggregate rule guards');
    is(join('', @{$stderr_buf || []}), '', 'CLI keeps stderr clean for local standalone aggregate rule guards');
    ok(-s $hdl_path, 'CLI writes HDL for local standalone aggregate rule guards');
};

subtest 'package aggregate storage leaves are valid long-form standalone rule guards' => sub {
    my $dir = tempdir(CLEANUP => 1);
    write_file(File::Spec->catfile($dir, 'shared.fsm'), <<'FSM');
(?pkg:shared
  (+types
    (type lanes_t (list bit (bits 2))))
)
FSM
    my $isf_path = File::Spec->catfile($dir, 'package_aggregate_rule_standalone_guard.isf');
    write_file($isf_path, <<'ISF');
(actor package_aggregate_rule_standalone_guard
  (imports
    (package shared))
  (clock clk)
  (reset rst)
  (interface
    (output fire))
  (storage
    (var lanes (type shared.lanes_t)))
  (rule fire_when_lane
    (when lanes[1])
    (set fire 1)))
ISF

    my $actor = FSM::Adapter::ISF->new()->parse_file($isf_path);
    my %rule_by_name = map { $_->{name} => $_ } @{$actor->{rules}};
    is_deeply(
        $rule_by_name{fire_when_lane}{when},
        ['when', 'lanes[1]'],
        'package standalone aggregate rule guard normalizes into the public when field',
    );

    my $fsm = FSM::Scheduler::ISF->new()->lower($actor)->{files}{'package_aggregate_rule_standalone_guard.fsm'};
    like($fsm, qr/\(\+import\s+shared\s+\)/s, 'scheduled .fsm emits package import');
    like($fsm, qr/\(-fire_when_lane\s+<lanes\[1\]\s+\(<- \(fire> 1\)\)\s+\)/s,
        'scheduled .fsm preserves standalone package aggregate leaf rule guard');
    like($fsm, qr/\(\?pkg:shared[\s\S]*\(\+types[\s\S]*\(type lanes_t \(list bit \(bits 2\)\)\)/,
        'scheduled .fsm embeds imported aggregate package root');

    my $hdl_path = File::Spec->catfile($dir, 'package_aggregate_rule_standalone_guard.sv');
    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--strict', '--outdir', $dir, '--output', $hdl_path, $isf_path],
    );
    ok($success, 'CLI HDL generation succeeds for package standalone aggregate rule guards');
    is(join('', @{$stderr_buf || []}), '', 'CLI keeps stderr clean for package standalone aggregate rule guards');
    ok(-s $hdl_path, 'CLI writes HDL for package standalone aggregate rule guards');
};

subtest 'standalone aggregate rule guard diagnostics stay scalar-leaf-only' => sub {
    assert_parse_rejected(
        <<'ISF',
(actor aggregate_rule_standalone_guard_unknown_member
  (types
    (type frame_t (record (mode (bits 2)) (flag bit))))
  (clock clk)
  (reset rst)
  (interface
    (output fire))
  (storage
    (var frame (type frame_t)))
  (rule fire_when_flag frame.missing
    (set fire 1)))
ISF
        qr/invalid aggregate storage path 'frame\.missing': record member 'missing' is not declared; known members: mode, flag/,
        'unknown record member standalone rule guard fails before lowering',
    );

    assert_parse_rejected(
        <<'ISF',
(actor aggregate_rule_standalone_guard_subaggregate
  (types
    (type payload_t (list bit (bits 2)))
    (type frame_t (record (mode (bits 2)) (payload payload_t))))
  (clock clk)
  (reset rst)
  (interface
    (output fire))
  (storage
    (var frame (type frame_t)))
  (rule fire_when_payload frame.payload
    (set fire 1)))
ISF
        qr/rule 'fire_when_payload' guard references aggregate storage path 'frame\.payload' that resolves to aggregate kind 'list'; this ISF slice accepts only scalar aggregate leaf reads/,
        'subaggregate standalone rule guards remain deferred',
    );

    assert_parse_rejected(
        <<'ISF',
(actor aggregate_rule_standalone_guard_out_of_range_item
  (types
    (type lanes_t (list bit (bits 2))))
  (clock clk)
  (reset rst)
  (interface
    (output fire))
  (storage
    (var lanes (type lanes_t)))
  (rule fire_when_lane lanes[2]
    (set fire 1)))
ISF
        qr/invalid aggregate storage path 'lanes\[2\]': list index '2' is outside the declared item range 0\.\.1/,
        'out-of-range list item standalone rule guard fails before lowering',
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
