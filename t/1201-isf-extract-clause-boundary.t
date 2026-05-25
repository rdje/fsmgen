#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Adapter::ISF;
use FSM::Scheduler::ISF;

sub lower_source {
    my ($source) = @_;
    my $actor = FSM::Adapter::ISF->new()->parse_source($source, 'extract-clause-boundary.isf');
    return FSM::Scheduler::ISF->new()->lower($actor);
}

sub assert_lower_rejected {
    my ($source, $label, $diagnostic_re) = @_;

    my $ok = eval {
        lower_source($source);
        1;
    };
    my $diagnostic = $@;

    ok(!$ok, "$label is rejected during lowering");
    ok(!ref($diagnostic), "$label diagnostic is scalar");
    like($diagnostic, $diagnostic_re, "$label diagnostic is targeted");
}

subtest 'valid extract clause lowers exact slices with explicit widths' => sub {
    my $result = lower_source(<<'ISF');
(actor extract_boundary
  (clock clk)
  (interface
    (input start)
    (input packet (width 12))
    (output header (width 4))
    (output payload (width 8))
    (output done))
  (transaction main
    (on start)
    (extract packet as header payload (widths 4 8))
    (complete done)))
ISF

    my $fsm = $result->{files}{'extract_boundary.fsm'};
    like($fsm, qr/\(<= \(header> \(slice packet 11 8\)\)\)/, 'extract lowers first exact slice');
    like($fsm, qr/\(<= \(payload> \(slice packet 7 0\)\)\)/, 'extract lowers second exact slice');
};

subtest 'malformed extract clauses fail before scheduled emission' => sub {
    assert_lower_rejected(<<'ISF', 'nested extract word', qr/\Aextract word must be a scalar name/);
(actor nested_extract_word
  (clock clk)
  (interface (input start) (input packet) (output header) (output done))
  (transaction main
    (on start)
    (extract (packet) as header)
    (complete done)))
ISF

    assert_lower_rejected(<<'ISF', 'nested extract field', qr/\Aextract field must be a scalar name/);
(actor nested_extract_field
  (clock clk)
  (interface (input start) (input packet) (output header) (output done))
  (transaction main
    (on start)
    (extract packet as (header))
    (complete done)))
ISF

    assert_lower_rejected(<<'ISF', 'unknown extract option', qr/\Aextract optional arguments must be '\(widths N\|PARAM\|CONST\|PACKAGE\.CONSTANT\.\.\.\)'/);
(actor unknown_extract_option
  (clock clk)
  (interface (input start) (input packet) (output header) (output done))
  (transaction main
    (on start)
    (extract packet as header (width 4))
    (complete done)))
ISF

    assert_lower_rejected(<<'ISF', 'extract field after widths', qr/\Aextract fields must precede the '\(widths \.\.\.\)' option/);
(actor extract_field_after_widths
  (clock clk)
  (interface (input start) (input packet) (output header) (output payload) (output done))
  (transaction main
    (on start)
    (extract packet as header (widths 4) payload)
    (complete done)))
ISF
};

done_testing();
