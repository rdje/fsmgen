#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Adapter::ISF;
use FSM::Scheduler::ISF;

# Records the fail-closed terminal for ISF-FULL-WIDTH-INFERENCE: there is no
# decidable multi-unknown data-operation width sub-case beyond the shipped
# single-missing inference. Genuinely two-or-more-unknown widths are
# underdetermined (N unknowns, one total-width equation), so the lowerer
# correctly fails closed. This test locks that boundary so the terminal is
# executable rather than asserted only in prose.
#
# Tree: ISF-FULL-WIDTH-INFERENCE (.1, terminal record)

sub lower_rejects {
    my ($src, $pattern, $label) = @_;
    my $ok = eval {
        my $actor = FSM::Adapter::ISF->new()->parse_source($src, 'full-width-inference-terminal.isf');
        FSM::Scheduler::ISF->new()->lower($actor);
        1;
    };
    ok(!$ok, "$label is rejected");
    like($@, $pattern, "$label diagnostic");
}

subtest 'partial assemble (widths ...) is rejected: no per-part inference of the omitted widths' => sub {
    # Two parts, one explicit width -> the (widths ...) count must match the
    # part count; there is no "infer the other unknown part widths" path.
    lower_rejects(<<'ISF', qr/assemble '\(widths \.\.\.\)' count must match the part count/,
(actor partial_assemble_widths
  (clock clk)
  (reset rst_n)
  (interface
    (input start) (input p) (input q) (output done) (output packet (width 8)))
  (transaction main
    (on start)
    (assemble p q as packet (widths 4))
    (complete done)))
ISF
        'partial assemble (widths) with fewer widths than parts');
};

subtest 'partial extract (widths ...) is rejected: no per-field inference of the omitted widths' => sub {
    lower_rejects(<<'ISF', qr/extract '\(widths \.\.\.\)' count must match the field count/,
(actor partial_extract_widths
  (clock clk)
  (reset rst_n)
  (interface
    (input start) (input word (width 8)) (output done) (output lo) (output hi))
  (transaction main
    (on start)
    (extract word as lo hi (widths 3))
    (complete done)))
ISF
        'partial extract (widths) with fewer widths than fields');
};

subtest 'multiple parts whose widths do not determine the target fail closed (no multi-unknown inference)' => sub {
    # p, q default to width 1 each (sum 2); the known target width is 8. There
    # is no inference that would assign the remaining 6 bits across two parts
    # (underdetermined), so this fails closed with a sum-conflict.
    lower_rejects(<<'ISF', qr/assemble part widths sum \d+ conflicts with known width 8 for 'packet'/,
(actor multi_unknown_assemble
  (clock clk)
  (reset rst_n)
  (interface
    (input start) (input p) (input q) (output done) (output packet (width 8)))
  (transaction main
    (on start)
    (assemble p q as packet)
    (complete done)))
ISF
        'two underdetermined assemble parts against a known target');
};

done_testing();
