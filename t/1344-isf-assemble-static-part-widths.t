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

sub lower_source {
    my ($source, $name) = @_;
    my $actor = FSM::Adapter::ISF->new()->parse_source($source, $name);
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

subtest 'actor-local static assemble part widths lower like known widths' => sub {
    my ($lowered, $report) = lower_source(<<'ISF', 'static-assemble-part-widths.isf');
(actor static_assemble_part_widths
  (clock clk)
  (reset (rst_n async active_low))
  (params
    (HEADER_W 4))
  (constants
    (PAYLOAD_W 8)
    (CRC_W 4))
  (interface
    (input start)
    (input bit_in)
    (output done))
  (transaction main
    (on start)
    (assemble header payload crc as packet (widths HEADER_W PAYLOAD_W CRC_W))
    (shift_right packet bit_in)
    (complete done)))
ISF

    my $fsm = $lowered->{files}{'static_assemble_part_widths.fsm'};

    like(
        $fsm,
        qr/\(<- \(packet \(concat header payload crc\)\)\)/,
        'assemble still lowers to the same reviewable concat assignment',
    );
    like(
        $fsm,
        qr/\(<- \(packet \(\| \(>> packet 1\) \(<< bit_in 15\)\)\)\)/,
        'later shift_right consumes the assemble-derived target width',
    );
    unlike($fsm, qr/WIDTH|HIGH|LOW/, 'static assemble widths leave no placeholder bounds');

    assert_storage($report, 'packet', 'register', 'data_register', 16);
};

subtest 'enum-resolved actor static values are accepted as assemble part widths' => sub {
    my ($lowered) = lower_source(<<'ISF', 'enum-static-assemble-part-widths.isf');
(actor enum_static_assemble_part_widths
  (clock clk)
  (enums
    (sizes (W 6)))
  (params
    (FIELD_W sizes.W))
  (constants
    (TAIL_W sizes.W))
  (interface
    (input start)
    (input bit_in)
    (output done))
  (transaction main
    (on start)
    (assemble field tail as packet (widths FIELD_W TAIL_W))
    (shift_right packet bit_in)
    (complete done)))
ISF

    my $fsm = $lowered->{files}{'enum_static_assemble_part_widths.fsm'};
    like($fsm, qr/\(<- \(packet \(\| \(>> packet 1\) \(<< bit_in 11\)\)\)\)/, 'enum-resolved part widths derive the assembled target width');
};

subtest 'unsupported assemble part width sources fail closed' => sub {
    assert_lower_rejected(
        <<'ISF',
(actor zero_constant_assemble_part_width
  (clock clk)
  (constants
    (PAYLOAD_W 0))
  (interface
    (input start)
    (output done))
  (transaction main
    (on start)
    (assemble header payload as packet (widths 4 PAYLOAD_W))
    (complete done)))
ISF
        'zero-constant-assemble-part-width.isf',
        qr/\ATransaction 'main': assemble width for 'payload' constant 'PAYLOAD_W' must resolve to a positive integer/,
        'zero-valued actor constant width',
    );

    assert_lower_rejected(
        <<'ISF',
(actor unrelated_direct_transaction_parameter_assemble_part_width
  (clock clk)
  (interface
    (input start)
    (output done))
  (transaction main
    (on start)
    (params
      (UNUSED_W 8))
    (assemble header payload as packet (widths 4 8))
    (complete done)))
ISF
        'unrelated-direct-transaction-parameter-assemble-part-width.isf',
        qr/\ATransaction 'main': params are supported only on generated child transactions, same-transaction temporal contract windows, same-transaction data-operation width evidence, or same-transaction transaction-port width evidence/,
        'unrelated direct transaction parameter',
    );

    assert_lower_rejected(
        <<'ISF',
(actor runtime_signal_assemble_part_width
  (clock clk)
  (interface
    (input start)
    (input PAYLOAD_W (width 4))
    (output done))
  (transaction main
    (on start)
    (assemble header payload as packet (widths 4 PAYLOAD_W))
    (complete done)))
ISF
        'runtime-signal-assemble-part-width.isf',
        qr/\ATransaction 'main': assemble width for 'payload' token 'PAYLOAD_W' is a runtime interface signal/,
        'runtime signal width',
    );

    assert_lower_rejected(
        <<'ISF',
(actor unknown_assemble_part_width
  (clock clk)
  (interface
    (input start)
    (output done))
  (transaction main
    (on start)
    (assemble header payload as packet (widths 4 PAYLOAD_W))
    (complete done)))
ISF
        'unknown-assemble-part-width.isf',
        qr/\ATransaction 'main': assemble width for 'payload' token 'PAYLOAD_W' is not a same-transaction scalar parameter, declared actor constant, actor scalar parameter, or imported package scalar constant/,
        'unknown symbolic width',
    );

    assert_lower_rejected(
        <<'ISF',
(actor expression_assemble_part_width
  (clock clk)
  (interface
    (input start)
    (output done))
  (transaction main
    (on start)
    (assemble header payload as packet (widths 4 (+ 4 4)))
    (complete done)))
ISF
        'expression-assemble-part-width.isf',
        qr/\Aassemble widths must be positive integer literals, same-transaction scalar parameters, actor constants, actor scalar parameters, or qualified package scalar constants/,
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
