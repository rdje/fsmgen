#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;
use JSON::PP qw(decode_json);

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Adapter::ISF;
use FSM::Scheduler::ISF;
use FSM::Scheduler::ISF::Emitter::JSON;
use FSM::Scheduler::ISF::LoweringIR;

sub parse_source {
    my ($source, $name) = @_;
    return FSM::Adapter::ISF->new()->parse_source($source, $name);
}

sub lower_source {
    my ($source, $name) = @_;
    my $actor = parse_source($source, $name);
    my $scheduler = FSM::Scheduler::ISF->new();
    return ($actor, $scheduler->lower($actor));
}

sub assert_lower_rejected {
    my ($source, $name, $diagnostic_re, $label) = @_;

    my $ok = eval {
        my $actor = parse_source($source, $name);
        FSM::Scheduler::ISF->new()->lower($actor);
        1;
    };
    my $diagnostic = $@;

    ok(!$ok, "$label is rejected during lowering");
    ok(!ref($diagnostic), "$label diagnostic is scalar");
    like($diagnostic, $diagnostic_re, "$label diagnostic is targeted");
}

subtest 'generated child transaction parameters are accepted as data-operation widths' => sub {
    my $source = <<'ISF';
(actor generated_child_data_op_transaction_param_widths
  (clock clk)
  (reset rst_n)
  (constants
    (SHREG_W 5))
  (interface
    (input start)
    (input bit_in)
    (input packet (width 16))
    (output done))
  (transaction parent
    (on start)
    (spawn child as c0)
    (complete done))
  (transaction child
    (params
      (SHREG_W 8)
      (FLAT_W 4'd8)
      (HEADER_W 4)
      (PAYLOAD_W 8)
      (CRC_W 4)
      (DERIVED_W SHREG_W))
    (shift_left shreg bit_in (width FLAT_W))
    (shift_right shreg bit_in (width DERIVED_W))
    (extract packet as header payload crc (widths HEADER_W PAYLOAD_W CRC_W))
    (assemble header payload crc as assembled (widths HEADER_W PAYLOAD_W CRC_W))
    (shift_right assembled bit_in)
    (complete done)))
ISF

    my ($actor, $lowered) = lower_source($source, 'generated-child-data-op-transaction-param-widths.isf');
    my $child_fsm = $lowered->{files}{'child.fsm'};

    like(
        $child_fsm,
        qr/\(<- \(shreg \(\| \(>> shreg 1\) \(<< bit_in 7\)\)\)\)/,
        'generated child shift_right uses transaction-local width before actor constant of the same name',
    );
    like($child_fsm, qr/\(<= \(header \(slice packet 15 12\)\)\)/, 'transaction parameter extract width drives first slice');
    like($child_fsm, qr/\(<= \(payload \(slice packet 11 4\)\)\)/, 'transaction parameter extract width drives middle slice');
    like($child_fsm, qr/\(<= \(crc \(slice packet 3 0\)\)\)/, 'transaction parameter extract width drives final slice');
    like(
        $child_fsm,
        qr/\(<- \(assembled \(\| \(>> assembled 1\) \(<< bit_in 15\)\)\)\)/,
        'assemble target width derived from transaction parameter part widths feeds later shift_right',
    );
    unlike($child_fsm, qr/WIDTH|HIGH|LOW/, 'accepted transaction-parameter data widths leave no placeholders');

    my $ir = FSM::Scheduler::ISF::LoweringIR->new()->build_module($actor);
    my $child_report = FSM::Scheduler::ISF::Emitter::JSON->new()->report_hash($ir->{children}{child});
    assert_storage($child_report, 'shreg', 8);
    assert_storage($child_report, 'assembled', 16);
};

subtest 'direct transaction parameters are accepted as data-operation widths' => sub {
    my $source = <<'ISF';
(actor direct_data_op_transaction_param_widths
  (clock clk)
  (reset rst_n)
  (constants
    (SHREG_W 5))
  (interface
    (input start)
    (input bit_in)
    (input packet (width 16))
    (output done))
  (transaction main
    (on start)
    (params
      (SHREG_W 8)
      (FLAT_W 4'd8)
      (HEADER_W 4)
      (PAYLOAD_W 8)
      (CRC_W 4)
      (DERIVED_W SHREG_W))
    (contract bit_seen (eventually bit_in (within SHREG_W)))
    (shift_left shreg bit_in (width FLAT_W))
    (shift_right shreg bit_in (width DERIVED_W))
    (extract packet as header payload crc (widths HEADER_W PAYLOAD_W CRC_W))
    (assemble header payload crc as assembled (widths HEADER_W PAYLOAD_W CRC_W))
    (shift_right assembled bit_in)
    (complete done)))
ISF

    my ($actor, $lowered) = lower_source($source, 'direct-data-op-transaction-param-widths.isf');
    my $fsm = $lowered->{files}{'direct_data_op_transaction_param_widths.fsm'};

    like(
        $fsm,
        qr/\(<- \(shreg \(\| \(>> shreg 1\) \(<< bit_in 7\)\)\)\)/,
        'direct shift_right uses transaction-local width before actor constant of the same name',
    );
    like($fsm, qr/\(<= \(header \(slice packet 15 12\)\)\)/, 'direct transaction parameter extract width drives first slice');
    like($fsm, qr/\(<= \(payload \(slice packet 11 4\)\)\)/, 'direct transaction parameter extract width drives middle slice');
    like($fsm, qr/\(<= \(crc \(slice packet 3 0\)\)\)/, 'direct transaction parameter extract width drives final slice');
    like(
        $fsm,
        qr/\(<- \(assembled \(\| \(>> assembled 1\) \(<< bit_in 15\)\)\)\)/,
        'direct assemble target width derived from transaction parameter part widths feeds later shift_right',
    );
    unlike($fsm, qr/WIDTH|HIGH|LOW/, 'accepted direct transaction-parameter data widths leave no placeholders');

    my $ir = FSM::Scheduler::ISF::LoweringIR->new()->build_module($actor);
    my $report = FSM::Scheduler::ISF::Emitter::JSON->new()->report_hash($ir);
    assert_storage($report, 'shreg', 8);
    assert_storage($report, 'assembled', 16);
};

subtest 'transaction parameter data-width diagnostics fail closed' => sub {
    assert_lower_rejected(
        <<'ISF',
(actor zero_generated_child_data_op_transaction_param_width
  (clock clk)
  (interface
    (input start)
    (input bit_in)
    (output done))
  (transaction parent
    (on start)
    (spawn child as c0)
    (complete done))
  (transaction child
    (params
      (SHREG_W 0))
    (shift_right shreg bit_in (width SHREG_W))
    (complete done)))
ISF
        'zero-generated-child-data-op-transaction-param-width.isf',
        qr/\ATransaction 'child': shift_right width transaction parameter 'SHREG_W' must resolve to a positive integer/,
        'zero-valued generated child transaction parameter width',
    );

    assert_lower_rejected(
        <<'ISF',
(actor aggregate_generated_child_data_op_transaction_param_width
  (clock clk)
  (interface
    (input start)
    (input bit_in)
    (output done))
  (transaction parent
    (on start)
    (spawn child as c0)
    (complete done))
  (transaction child
    (params
      (SHREG_W (8 8)))
    (shift_right shreg bit_in (width SHREG_W))
    (complete done)))
ISF
        'aggregate-generated-child-data-op-transaction-param-width.isf',
        qr/\ATransaction 'child': shift_right width transaction parameter 'SHREG_W' must resolve to a positive integer/,
        'aggregate generated child transaction parameter width',
    );

    assert_lower_rejected(
        <<'ISF',
(actor unrelated_direct_transaction_parameter_data_op_width
  (clock clk)
  (interface
    (input start)
    (input bit_in)
    (output done))
  (transaction main
    (on start)
    (params
      (UNUSED_W 8))
    (shift_right shreg bit_in (width 8))
    (complete done)))
ISF
        'unrelated-direct-transaction-parameter-data-op-width.isf',
        qr/\ATransaction 'main': params are supported only on generated child transactions, same-transaction temporal contract windows, same-transaction data-operation width evidence, or same-transaction transaction-port width evidence/,
        'unrelated direct transaction parameters remain rejected',
    );

    assert_lower_rejected(
        <<'ISF',
(actor zero_direct_data_op_transaction_param_width
  (clock clk)
  (interface
    (input start)
    (input bit_in)
    (output done))
  (transaction main
    (on start)
    (params
      (SHREG_W 0))
    (shift_right shreg bit_in (width SHREG_W))
    (complete done)))
ISF
        'zero-direct-data-op-transaction-param-width.isf',
        qr/\ATransaction 'main': shift_right width transaction parameter 'SHREG_W' must resolve to a positive integer/,
        'zero-valued direct transaction parameter width',
    );

    assert_lower_rejected(
        <<'ISF',
(actor aggregate_direct_data_op_transaction_param_width
  (clock clk)
  (interface
    (input start)
    (input bit_in)
    (output done))
  (transaction main
    (on start)
    (params
      (SHREG_W (8 8)))
    (shift_right shreg bit_in (width SHREG_W))
    (complete done)))
ISF
        'aggregate-direct-data-op-transaction-param-width.isf',
        qr/\ATransaction 'main': shift_right width transaction parameter 'SHREG_W' must resolve to a positive integer/,
        'aggregate direct transaction parameter width',
    );

    assert_lower_rejected(
        <<'ISF',
(actor expression_direct_data_op_transaction_param_width
  (clock clk)
  (interface
    (input start)
    (input bit_in)
    (output done))
  (transaction main
    (on start)
    (params
      (SHREG_W 8))
    (shift_right shreg bit_in (width (+ SHREG_W 1)))
    (complete done)))
ISF
        'expression-direct-data-op-transaction-param-width.isf',
        qr/\Ashift_right width must be a positive integer literal, same-transaction scalar parameter, actor constant, actor scalar parameter, or qualified package scalar constant/,
        'direct transaction parameter width expressions remain rejected',
    );

    assert_lower_rejected(
        <<'ISF',
(actor cross_transaction_data_op_param_width
  (clock clk)
  (interface
    (input start)
    (input bit_in)
    (output done))
  (transaction helper
    (params
      (OTHER_W 4))
    (complete done))
  (transaction main
    (on start)
    (params
      (SHREG_W 8))
    (spawn helper as h0)
    (shift_left shreg bit_in (width SHREG_W))
    (shift_right other bit_in (width OTHER_W))
    (complete done)))
ISF
        'cross-transaction-data-op-param-width.isf',
        qr/\ATransaction 'main': shift_right width token 'OTHER_W' is not a same-transaction scalar parameter, declared actor constant, actor scalar parameter, or imported package scalar constant/,
        'cross-transaction parameter widths remain rejected',
    );
};

done_testing();

sub assert_storage {
    my ($report, $name, $width) = @_;
    my ($entry) = grep { $_->{name} eq $name } @{$report->{inferred_storage} || []};

    ok($entry, "storage entry '$name' exists");
    return unless $entry;
    is($entry->{kind}, 'register', "storage entry '$name' kind");
    is($entry->{role}, 'data_register', "storage entry '$name' role");
    is($entry->{width}, $width, "storage entry '$name' width");
}
