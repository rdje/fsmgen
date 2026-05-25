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

sub parse_source {
    my ($source, $name) = @_;
    return FSM::Adapter::ISF->new()->parse_source($source, $name);
}

sub lower_source {
    my ($source, $name) = @_;
    my $actor = parse_source($source, $name);
    my $scheduler = FSM::Scheduler::ISF->new();
    my $lowered = $scheduler->lower($actor);
    return ($lowered, decode_json($scheduler->report($actor)));
}

sub assert_lower_rejected {
    my ($source, $name, $diagnostic_re, $label) = @_;

    my $ok = eval {
        lower_source($source, $name);
        1;
    };
    my $diagnostic = $@;

    ok(!$ok, "$label is rejected during lowering");
    ok(!ref($diagnostic), "$label diagnostic is scalar");
    like($diagnostic, $diagnostic_re, "$label diagnostic is targeted");
}

subtest 'actor-local static data-operation width sources lower like literal widths' => sub {
    my ($lowered, $report) = lower_source(<<'ISF', 'static-data-op-widths.isf');
(actor static_data_op_widths
  (clock clk)
  (reset (rst_n async active_low))
  (params
    (SHREG_W 8)
    (HEADER_W 4))
  (constants
    (PAYLOAD_W 8)
    (CRC_W 4))
  (interface
    (input start)
    (input bit_in)
    (input packet (width 16))
    (output done))
  (transaction main
    (on start)
    (shift_left shreg bit_in (width SHREG_W))
    (shift_right shreg bit_in)
    (extract packet as header payload crc (widths HEADER_W PAYLOAD_W CRC_W))
    (complete done)))
ISF

    my $fsm = $lowered->{files}{'static_data_op_widths.fsm'};

    like(
        $fsm,
        qr/\(<- \(shreg \(\| \(<< shreg 1\) bit_in\)\)\)/,
        'actor-parameter shift_left width keeps ordinary shift-left lowering',
    );
    like(
        $fsm,
        qr/\(<- \(shreg \(\| \(>> shreg 1\) \(<< bit_in 7\)\)\)\)/,
        'later shift_right consumes actor-parameter width evidence',
    );
    like($fsm, qr/\(<= \(header \(slice packet 15 12\)\)\)/, 'actor-parameter extract width drives first slice');
    like($fsm, qr/\(<= \(payload \(slice packet 11 4\)\)\)/, 'actor-constant extract width drives middle slice');
    like($fsm, qr/\(<= \(crc \(slice packet 3 0\)\)\)/, 'actor-constant extract width drives final slice');
    unlike($fsm, qr/WIDTH|HIGH|LOW/, 'static data-operation widths leave no placeholder bounds');

    assert_storage($report, 'shreg', 'register', 'data_register', 8);
    assert_storage($report, 'header', 'register', 'extract_field', 4);
    assert_storage($report, 'payload', 'register', 'extract_field', 8);
    assert_storage($report, 'crc', 'register', 'extract_field', 4);
};

subtest 'enum-resolved actor static values are accepted as data-operation widths' => sub {
    my ($lowered) = lower_source(<<'ISF', 'enum-static-data-op-widths.isf');
(actor enum_static_data_op_widths
  (clock clk)
  (enums
    (sizes (W 6)))
  (params
    (SHREG_W sizes.W))
  (constants
    (FIELD_W sizes.W))
  (interface
    (input start)
    (input bit_in)
    (input packet (width 6))
    (output done))
  (transaction main
    (on start)
    (shift_right shreg bit_in (width SHREG_W))
    (extract packet as field (widths FIELD_W))
    (complete done)))
ISF

    my $fsm = $lowered->{files}{'enum_static_data_op_widths.fsm'};
    like($fsm, qr/\(<- \(shreg \(\| \(>> shreg 1\) \(<< bit_in 5\)\)\)\)/, 'enum-resolved actor parameter width selects shift insert position');
    like($fsm, qr/\(<= \(field \(slice packet 5 0\)\)\)/, 'enum-resolved actor constant width selects extract slice');
};

subtest 'unsupported data-operation width sources fail closed' => sub {
    assert_lower_rejected(
        <<'ISF',
(actor zero_constant_data_op_width
  (clock clk)
  (constants
    (SHREG_W 0))
  (interface
    (input start)
    (input bit_in)
    (output done))
  (transaction main
    (on start)
    (shift_right shreg bit_in (width SHREG_W))
    (complete done)))
ISF
        'zero-constant-data-op-width.isf',
        qr/\ATransaction 'main': shift_right width constant 'SHREG_W' must resolve to a positive integer/,
        'zero-valued actor constant width',
    );

    assert_lower_rejected(
        <<'ISF',
(actor zero_parameter_data_op_width
  (clock clk)
  (params
    (SHREG_W 0))
  (interface
    (input start)
    (input bit_in)
    (output done))
  (transaction main
    (on start)
    (shift_left shreg bit_in (width SHREG_W))
    (complete done)))
ISF
        'zero-parameter-data-op-width.isf',
        qr/\ATransaction 'main': shift_left width parameter 'SHREG_W' must resolve to a positive integer/,
        'zero-valued actor parameter width',
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
        qr/\ATransaction 'main': params are supported only on generated child transactions, same-transaction temporal contract windows, same-transaction data-operation width evidence, same-transaction transaction-port width evidence, same-transaction repeat counts, same-transaction wait counts, or same-transaction latency bounds/,
        'unrelated direct transaction parameter',
    );

    assert_lower_rejected(
        <<'ISF',
(actor runtime_signal_data_op_width
  (clock clk)
  (interface
    (input start)
    (input bit_in)
    (input SHREG_W (width 4))
    (output done))
  (transaction main
    (on start)
    (shift_right shreg bit_in (width SHREG_W))
    (complete done)))
ISF
        'runtime-signal-data-op-width.isf',
        qr/\ATransaction 'main': shift_right width token 'SHREG_W' is a runtime interface signal/,
        'runtime signal width',
    );

    assert_lower_rejected(
        <<'ISF',
(actor unknown_data_op_width
  (clock clk)
  (interface
    (input start)
    (input bit_in)
    (output done))
  (transaction main
    (on start)
    (shift_right shreg bit_in (width SHREG_W))
    (complete done)))
ISF
        'unknown-data-op-width.isf',
        qr/\ATransaction 'main': shift_right width token 'SHREG_W' is not a same-transaction scalar parameter, declared actor constant, actor scalar parameter, or imported package scalar constant/,
        'unknown symbolic width',
    );

    assert_lower_rejected(
        <<'ISF',
(actor expression_data_op_width
  (clock clk)
  (interface
    (input start)
    (input bit_in)
    (output done))
  (transaction main
    (on start)
    (shift_right shreg bit_in (width (+ 4 4)))
    (complete done)))
ISF
        'expression-data-op-width.isf',
        qr/\Ashift_right width must be a positive integer literal, same-transaction scalar parameter, actor constant, actor scalar parameter, or qualified package scalar constant/,
        'expression width',
    );
};

done_testing();

sub assert_storage {
    my ($report, $name, $kind, $role, $width) = @_;
    my ($entry) = grep { $_->{name} eq $name } @{$report->{inferred_storage} || []};

    ok($entry, "storage entry '$name' exists");
    return unless $entry;
    is($entry->{kind}, $kind, "storage entry '$name' kind");
    is($entry->{role}, $role, "storage entry '$name' role");
    is($entry->{width}, $width, "storage entry '$name' width");
}
