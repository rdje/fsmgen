#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Spec;
use File::Temp qw(tempdir);
use FindBin;
use JSON::PP qw(decode_json);

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Adapter::ISF;
use FSM::HDL::FlattenedDT;
use FSM::Pipeline::SourceFrontend;
use FSM::Scheduler::ISF;

subtest 'actor constants transaction port widths lower like literal widths' => sub {
    my $source = <<'ISF';
(actor constant_transaction_port_widths
  (clock clk)
  (constants
    (DATA_W 8))
  (interface
    (input start)
    (input req_addr (width 8))
    (output done)
    (output resp (width 8)))
  (transaction child
    (ports
      (input addr (width DATA_W))
      (output data (width DATA_W)))
    (on child_start)
    (update data addr)
    (complete child_done))
  (transaction parent
    (on start)
    (do child
      (bind
        (input addr req_addr)
        (output data resp)))
    (complete done)))
ISF

    my $actor = parse_source($source, 'constant-transaction-port-widths.isf');
    is(transaction_port_width($actor, 'child', 'inputs', 'addr'), 8, 'input port width resolves from actor constant');
    is(transaction_port_width($actor, 'child', 'outputs', 'data'), 8, 'output port width resolves from actor constant');

    my $scheduler = FSM::Scheduler::ISF->new();
    my $lowered = $scheduler->lower($actor);
    my $fsm = $lowered->{files}{'constant_transaction_port_widths.fsm'};

    like($fsm, qr/\(\+constants\s+\(DATA_W 8\)\s+\)/s, 'scheduled .fsm preserves actor constant declaration');
    like($fsm, qr/\(\+size[\s\S]*\(addr 8\)[\s\S]*\(data 8\)/, 'scheduled .fsm uses resolved transaction port widths');
    like($fsm, qr/\(= \(addr req_addr\)\)/, 'do binding drives resolved input port');
    like($fsm, qr/\(= \(resp> data\) <child_done\)/, 'do binding reads resolved output port');

    my $report = decode_json($scheduler->report($actor));
    is_deeply(
        [map { $_->{width} } @{$report->{transaction_port_bindings} || []}],
        [8, 8],
        'schedule report binding widths use the resolved transaction port width',
    );

    assert_fsm_reaches_hdl($fsm, 'constant_transaction_port_widths', qr/\breg\s+\[7:0\]\s+addr\b/, 'HDL addr width is resolved');
    assert_fsm_reaches_hdl($fsm, 'constant_transaction_port_widths', qr/\breg\s+\[7:0\]\s+data\b/, 'HDL data width is resolved');
};

subtest 'enum-resolved actor constant transaction port width lowers' => sub {
    my $actor = parse_source(<<'ISF', 'enum-constant-transaction-port-width.isf');
(actor enum_constant_transaction_port_width
  (clock clk)
  (enums
    (sizes (W 6)))
  (constants
    (DATA_W sizes.W))
  (interface
    (input start)
    (input req (width 6))
    (output done))
  (transaction child
    (ports
      (input data (width DATA_W)))
    (on child_start)
    (complete child_done))
  (transaction parent
    (on start)
    (do child
      (bind
        (input data req)))
    (complete done)))
ISF

    is(transaction_port_width($actor, 'child', 'inputs', 'data'), 6, 'enum-resolved actor constant becomes a positive transaction port width');

    my $fsm = FSM::Scheduler::ISF->new()->lower($actor)->{files}{'enum_constant_transaction_port_width.fsm'};
    like($fsm, qr/\(\+size[\s\S]*\(data 6\)/, 'scheduled .fsm uses enum-resolved transaction port width');
};

subtest 'unsupported actor constant transaction port width sources fail closed' => sub {
    assert_parse_rejected(
        <<'ISF',
(actor zero_constant_transaction_port_width
  (clock clk)
  (constants
    (DATA_W 0))
  (interface
    (input start)
    (output done))
  (transaction child
    (ports
      (input addr (width DATA_W)))))
ISF
        qr/\AError: actor 'zero_constant_transaction_port_width' transaction 'child' port 'addr' width constant 'DATA_W' must resolve to a positive integer/,
        'zero-valued actor constant is rejected',
    );

    assert_parse_rejected(
        <<'ISF',
(actor aggregate_constant_transaction_port_width
  (clock clk)
  (constants
    (DATA_W (4 4)))
  (interface
    (input start)
    (output done))
  (transaction child
    (ports
      (input addr (width DATA_W)))))
ISF
        qr/\AError: actor 'aggregate_constant_transaction_port_width' constant 'DATA_W' requires a non-negative integer literal value or enum member reference/,
        'non-scalar actor constant definition is rejected',
    );

    my $actor = parse_source(<<'ISF', 'transaction-parameter-port-constant-width.isf');
(actor transaction_parameter_port_constant_width
  (clock clk)
  (interface
    (input start)
    (output done))
  (transaction child
    (params
      (DATA_W 8))
    (ports
      (input addr (width DATA_W)))))
ISF
    is(transaction_port_width($actor, 'child', 'inputs', 'addr'), 8,
        'direct transaction parameters are accepted as same-transaction port-width evidence');

    assert_parse_rejected(
        <<'ISF',
(actor unknown_constant_transaction_port_width
  (clock clk)
  (interface
    (input start)
    (output done))
  (transaction child
    (ports
      (input addr (width DATA_W)))))
ISF
        qr/\AError: actor 'unknown_constant_transaction_port_width' transaction 'child' port 'addr' width token 'DATA_W' is not a same-transaction scalar parameter, declared actor scalar parameter, actor constant, or imported package scalar constant/,
        'unknown symbolic width is rejected',
    );

    assert_parse_rejected(
        <<'ISF',
(actor runtime_constant_transaction_port_width
  (clock clk)
  (interface
    (input start)
    (input DATA_W)
    (output done))
  (transaction child
    (ports
      (input addr (width DATA_W)))))
ISF
        qr/\AError: actor 'runtime_constant_transaction_port_width' transaction 'child' port 'addr' width token 'DATA_W' is a runtime interface signal/,
        'runtime interface signals are rejected as widths',
    );

    assert_parse_rejected(
        <<'ISF',
(actor expression_constant_transaction_port_width
  (clock clk)
  (interface
    (input start)
    (output done))
  (transaction child
    (ports
      (input addr (width (+ DATA_W 1))))))
ISF
        qr/\AError: transaction 'child' port 'addr' width requires '\(width positive_integer_or_same_transaction_scalar_parameter_or_actor_scalar_parameter_or_actor_constant_or_qualified_package_scalar_constant\)'/,
        'width expressions are rejected at parse time',
    );
};

done_testing();

sub parse_source {
    my ($source, $label) = @_;
    return FSM::Adapter::ISF->new()->parse_source($source, $label);
}

sub assert_parse_rejected {
    my ($source, $diagnostic_re, $label) = @_;
    my $ok = eval {
        parse_source($source, "$label.isf");
        1;
    };
    my $diagnostic = $@;

    ok(!$ok, "$label fails closed");
    ok(!ref($diagnostic), "$label diagnostic is scalar");
    like($diagnostic, $diagnostic_re, "$label diagnostic is targeted");
}

sub transaction_by_name {
    my ($actor, $name) = @_;
    my ($tx) = grep { $_->{name} eq $name } @{$actor->{transactions} || []};
    ok($tx, "found transaction '$name'");
    return $tx;
}

sub transaction_port_width {
    my ($actor, $transaction_name, $direction, $port_name) = @_;
    my $tx = transaction_by_name($actor, $transaction_name);
    my ($port) = grep { $_->{name} eq $port_name } @{($tx->{ports} || {})->{$direction} || []};
    ok($port, "found $direction port '$port_name'");
    return $port ? $port->{width} : undef;
}

sub assert_fsm_reaches_hdl {
    my ($fsm, $module_name, $hdl_re, $label) = @_;
    my $tempdir = tempdir(CLEANUP => 1);
    my $fsm_path = File::Spec->catfile($tempdir, "$module_name.fsm");
    write_file($fsm_path, $fsm);

    my $raw_ast = FSM::Pipeline::SourceFrontend->parse_fsm_file(
        fsm_file    => $fsm_path,
        debug_level => 0,
    );
    my $fsm_module = FSM::Pipeline::SourceFrontend->create_fsm_module(
        raw_ast     => $raw_ast,
        debug_level => 0,
    );
    ok($fsm_module, "$label scheduled .fsm parses through the normal frontend");

    my $hdl = FSM::HDL::FlattenedDT->new(debug => 0)->generate_systemverilog($fsm_module);
    like($hdl, $hdl_re, $label);
}

sub write_file {
    my ($path, $content) = @_;
    open my $fh, '>', $path or die "Cannot open $path for write: $!";
    print {$fh} $content or die "Cannot write $path: $!";
    close $fh or die "Cannot close $path: $!";
}
