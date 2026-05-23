#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Adapter::ISF;
use FSM::Scheduler::ISF;

sub parse_source {
    my ($source, $label) = @_;
    return FSM::Adapter::ISF->new()->parse_source($source, "$label.isf");
}

sub lower_source {
    my ($source, $label) = @_;
    my $actor = parse_source($source, $label);
    return FSM::Scheduler::ISF->new()->lower($actor);
}

sub assert_parse_rejected {
    my ($source, $label, $diagnostic_re) = @_;

    my $ok = eval {
        parse_source($source, $label);
        1;
    };
    my $diagnostic = $@;

    ok(!$ok, "$label is rejected during parsing");
    ok(!ref($diagnostic), "$label diagnostic is scalar");
    like($diagnostic, $diagnostic_re, "$label diagnostic is targeted");
}

subtest 'literal zero division divisor in transaction RHS fails closed' => sub {
    assert_parse_rejected(<<'ISF', 'transaction_division_by_zero', qr/\AError: transaction 'main' set RHS expression '\(\/ numerator 0\)' uses literal zero divisor '0' in division/);
(actor transaction_division_by_zero
  (clock clk)
  (reset rst)
  (interface
    (input start)
    (input numerator (width 8))
    (output out (width 8)))
  (transaction main
    (on start)
    (set out (/ numerator 0))))
ISF
};

subtest 'literal zero modulo divisor in nested rule RHS fails closed' => sub {
    assert_parse_rejected(<<'ISF', 'rule_nested_modulo_by_zero', qr/\AError: rule 'capture' set RHS expression '\(% numerator 8'd0\)' uses literal zero divisor '8'd0' in modulo/);
(actor rule_nested_modulo_by_zero
  (clock clk)
  (reset rst)
  (interface
    (input ready)
    (input numerator (width 8))
    (input mask (width 8))
    (output out (width 8)))
  (rule capture ready
    (set out (+ mask (% numerator 8'd0)))))
ISF
};

subtest 'literal zero divisor in runtime wait expression fails closed' => sub {
    assert_parse_rejected(<<'ISF', 'wait_expression_division_by_zero', qr/\AError: transaction 'main' wait count expression '\(\/ delay_count 0\)' uses literal zero divisor '0' in division/);
(actor wait_expression_division_by_zero
  (clock clk)
  (reset rst)
  (interface
    (input start)
    (input delay_count (width 4))
    (output done))
  (transaction main
    (on start)
    (wait (/ delay_count 0))
    (complete done)))
ISF
};

subtest 'literal zero divisor in transaction condition fails closed' => sub {
    assert_parse_rejected(<<'ISF', 'condition_division_by_zero', qr/\AError: transaction 'main' when condition expression '\(\/ numerator 0\)' uses literal zero divisor '0' in division/);
(actor condition_division_by_zero
  (clock clk)
  (reset rst)
  (interface
    (input start)
    (input numerator (width 8))
    (output out (width 8)))
  (transaction main
    (on start)
    (when (/ numerator 0)
      (set out 1))))
ISF
};

subtest 'actor zero constant divisor in rule guard fails closed' => sub {
    assert_parse_rejected(<<'ISF', 'rule_guard_constant_division_by_zero', qr/\AError: rule 'capture' guard expression '\(\/ numerator ZERO\)' uses actor constant zero divisor 'ZERO' in division/);
(actor rule_guard_constant_division_by_zero
  (clock clk)
  (reset rst)
  (constants
    (ZERO 0))
  (interface
    (input numerator (width 8))
    (output out (width 8)))
  (rule capture (when (/ numerator ZERO))
    (set out 1)))
ISF
};

subtest 'literal zero divisor in bank store index fails closed' => sub {
    assert_parse_rejected(<<'ISF', 'bank_store_index_division_by_zero', qr/\AError: transaction 'main' store index expression '\(\/ idx 0\)' uses literal zero divisor '0' in division/);
(actor bank_store_index_division_by_zero
  (clock clk)
  (reset rst)
  (interface
    (input start)
    (input value (width 8))
    (output done))
  (storage
    (var idx (width 2))
    (bank data (width 8) (depth 4)))
  (transaction main
    (on start)
    (store data (/ idx 0) value)
    (complete done)))
ISF
};

subtest 'actor zero constant divisor in bank store value fails closed' => sub {
    assert_parse_rejected(<<'ISF', 'bank_store_value_constant_division_by_zero', qr/\AError: transaction 'main' store value expression '\(\/ value ZERO\)' uses actor constant zero divisor 'ZERO' in division/);
(actor bank_store_value_constant_division_by_zero
  (clock clk)
  (reset rst)
  (constants
    (ZERO 0))
  (interface
    (input start)
    (input value (width 8))
    (output done))
  (storage
    (var idx (width 2))
    (bank data (width 8) (depth 4)))
  (transaction main
    (on start)
    (store data idx (/ value ZERO))
    (complete done)))
ISF
};

subtest 'literal zero divisor in bank load index fails closed' => sub {
    assert_parse_rejected(<<'ISF', 'bank_load_index_division_by_zero', qr/\AError: transaction 'main' load index expression '\(\/ idx 0\)' uses literal zero divisor '0' in division/);
(actor bank_load_index_division_by_zero
  (clock clk)
  (reset rst)
  (interface
    (input start)
    (output out (width 8)))
  (storage
    (var idx (width 2))
    (bank data (width 8) (depth 4)))
  (transaction main
    (on start)
    (load data (/ idx 0) as out)))
ISF
};

subtest 'literal zero divisor in activation input binding expression fails closed' => sub {
    assert_parse_rejected(<<'ISF', 'activation_binding_division_by_zero', qr/\AError: transaction 'main' do input binding 'value' expression '\(\/ numerator 0\)' uses literal zero divisor '0' in division/);
(actor activation_binding_division_by_zero
  (clock clk)
  (reset rst)
  (interface
    (input start)
    (input numerator (width 8))
    (output out (width 8)))
  (transaction child
    (ports
      (input value (width 8))
      (output result (width 8)))
    (on start)
    (set result value))
  (transaction main
    (on start)
    (do child
      (bind
        (input value (/ numerator 0))
        (output result out)))))
ISF
};

subtest 'literal zero divisor in named drive actual fails closed' => sub {
    assert_parse_rejected(<<'ISF', 'drive_actual_division_by_zero', qr/\AError: transaction 'main' drive 'publish' actual expression '\(\/ numerator 0\)' uses literal zero divisor '0' in division/);
(actor drive_actual_division_by_zero
  (clock clk)
  (reset rst)
  (interface
    (input start)
    (input numerator (width 8))
    (output out (width 8)))
  (drive (publish value)
    (out value))
  (transaction main
    (on start)
    (drive publish (/ numerator 0))))
ISF
};

subtest 'actor zero constant divisor in inline drive RHS fails closed' => sub {
    assert_parse_rejected(<<'ISF', 'inline_drive_constant_division_by_zero', qr/\AError: transaction 'main' inline drive RHS expression '\(\/ numerator ZERO\)' uses actor constant zero divisor 'ZERO' in division/);
(actor inline_drive_constant_division_by_zero
  (clock clk)
  (reset rst)
  (constants
    (ZERO 0))
  (interface
    (input start)
    (input numerator (width 8))
    (output out (width 8)))
  (transaction main
    (on start)
    (drive
      (out (/ numerator ZERO)))))
ISF
};

subtest 'actor zero constant division divisor in transaction RHS fails closed' => sub {
    assert_parse_rejected(<<'ISF', 'transaction_constant_division_by_zero', qr/\AError: transaction 'main' set RHS expression '\(\/ numerator ZERO\)' uses actor constant zero divisor 'ZERO' in division/);
(actor transaction_constant_division_by_zero
  (clock clk)
  (reset rst)
  (constants
    (ZERO 0))
  (interface
    (input start)
    (input numerator (width 8))
    (output out (width 8)))
  (transaction main
    (on start)
    (set out (/ numerator ZERO))))
ISF
};

subtest 'actor enum-resolved zero constant modulo divisor fails closed' => sub {
    assert_parse_rejected(<<'ISF', 'rule_enum_constant_modulo_by_zero', qr/\AError: rule 'capture' set RHS expression '\(% numerator DEN\)' uses actor constant zero divisor 'DEN' in modulo/);
(actor rule_enum_constant_modulo_by_zero
  (clock clk)
  (reset rst)
  (enums
    (denom (ZERO 0) (TWO 2)))
  (constants
    (DEN denom.ZERO))
  (interface
    (input ready)
    (input numerator (width 8))
    (output out (width 8)))
  (rule capture ready
    (set out (% numerator DEN))))
ISF
};

subtest 'actor zero parameter division divisor in transaction RHS fails closed' => sub {
    assert_parse_rejected(<<'ISF', 'transaction_parameter_division_by_zero', qr/\AError: transaction 'main' set RHS expression '\(\/ numerator DEN\)' uses actor parameter zero divisor 'DEN' in division/);
(actor transaction_parameter_division_by_zero
  (clock clk)
  (reset rst)
  (params
    (DEN 0))
  (interface
    (input start)
    (input numerator (width 8))
    (output out (width 8)))
  (transaction main
    (on start)
    (set out (/ numerator DEN))))
ISF
};

subtest 'actor enum-resolved zero parameter modulo divisor fails closed' => sub {
    assert_parse_rejected(<<'ISF', 'rule_enum_parameter_modulo_by_zero', qr/\AError: rule 'capture' set RHS expression '\(% numerator DEN\)' uses actor parameter zero divisor 'DEN' in modulo/);
(actor rule_enum_parameter_modulo_by_zero
  (clock clk)
  (reset rst)
  (enums
    (denom (ZERO 0) (TWO 2)))
  (params
    (DEN denom.ZERO))
  (interface
    (input ready)
    (input numerator (width 8))
    (output out (width 8)))
  (rule capture ready
    (set out (% numerator DEN))))
ISF
};

subtest 'dynamic divisor lowers unchanged' => sub {
    my $result = lower_source(<<'ISF', 'dynamic_divisor_ok');
(actor dynamic_divisor_ok
  (clock clk)
  (reset rst)
  (interface
    (input start)
    (input numerator (width 8))
    (input divisor (width 8))
    (output out (width 8)))
  (transaction main
    (on start)
    (set out (/ numerator divisor))))
ISF

    my $fsm = $result->{files}{'dynamic_divisor_ok.fsm'};
    like($fsm, qr{\(<- \(out>? \(/ numerator divisor\)\)\)},
        'scheduled .fsm preserves runtime dynamic divisor expression');
};

subtest 'nonzero actor parameter divisor lowers unchanged' => sub {
    my $result = lower_source(<<'ISF', 'nonzero_parameter_divisor_ok');
(actor nonzero_parameter_divisor_ok
  (clock clk)
  (reset rst)
  (params
    (DEN 2))
  (interface
    (input start)
    (input numerator (width 8))
    (output out (width 8)))
  (transaction main
    (on start)
    (set out (/ numerator DEN))))
ISF

    my $fsm = $result->{files}{'nonzero_parameter_divisor_ok.fsm'};
    like($fsm, qr{\(\+params\s+\(DEN 2\)\s+\)}s,
        'scheduled .fsm preserves nonzero actor parameter declaration');
    like($fsm, qr{\(<- \(out>? \(/ numerator DEN\)\)\)},
        'scheduled .fsm preserves nonzero actor parameter divisor expression');
};

subtest 'nonzero actor constant divisor lowers unchanged' => sub {
    my $result = lower_source(<<'ISF', 'nonzero_constant_divisor_ok');
(actor nonzero_constant_divisor_ok
  (clock clk)
  (reset rst)
  (constants
    (DEN 2))
  (interface
    (input start)
    (input numerator (width 8))
    (output out (width 8)))
  (transaction main
    (on start)
    (set out (/ numerator DEN))))
ISF

    my $fsm = $result->{files}{'nonzero_constant_divisor_ok.fsm'};
    like($fsm, qr{\(\+constants\s+\(DEN 2\)\s+\)}s,
        'scheduled .fsm preserves nonzero actor constant declaration');
    like($fsm, qr{\(<- \(out>? \(/ numerator DEN\)\)\)},
        'scheduled .fsm preserves nonzero actor constant divisor expression');
};

subtest 'nonzero exact-width literal divisor lowers unchanged' => sub {
    my $result = lower_source(<<'ISF', 'nonzero_literal_divisor_ok');
(actor nonzero_literal_divisor_ok
  (clock clk)
  (reset rst)
  (interface
    (input start)
    (input numerator (width 8))
    (output out (width 8)))
  (transaction main
    (on start)
    (set out (/ numerator 8'd2))))
ISF

    my $fsm = $result->{files}{'nonzero_literal_divisor_ok.fsm'};
    like($fsm, qr{\(<- \(out>? \(/ numerator 8'd2\)\)\)},
        'scheduled .fsm preserves nonzero exact-width literal divisor expression');
};

done_testing();
