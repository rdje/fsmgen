#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Adapter::ISF;
use FSM::Scheduler::ISF;

# ISF-NESTED-COUNTED-REPEAT.2
#
# A counted `(repeat …)` may now sit inside another `(repeat …)` body — the substrate for
# nested loops. Each repeat instance gets its OWN counter: the outermost (and
# sequential/while/until/switch-contained) repeats keep the bare `<tx>_cnt`, while a nested
# repeat is lowered with a unique `<tx>_cnt_<n>`, so inner/outer counters never collide.
# Both counters are registered in `+size`; the structure is check-first (the outer continue
# edge enters the inner loop, the inner exit edge returns to the outer check).

sub parse_source {
    my ($source, $label) = @_;
    return FSM::Adapter::ISF->new()->parse_source($source, "$label.isf");
}

subtest '(repeat M (repeat N body)) lowers with two distinct check-first counters' => sub {
    my $actor = parse_source(<<'ISF', 'nested');
(actor nr
  (interface (input start) (output done) (output count (width 8)))
  (transaction main
    (on start)
    (repeat 3
      (repeat 2
        (update count (+ count 1))))
    (complete done)))
ISF
    my $lowered = eval { FSM::Scheduler::ISF->new()->lower($actor) };
    ok($lowered, 'a nested (repeat 3 (repeat 2 …)) lowers') or diag($@);
    my $fsm = $lowered->{files}{'nr.fsm'};

    # both counters are declared, distinct, in +size
    like($fsm, qr/\(main_cnt \d+\)/, 'the outer counter main_cnt is declared');
    like($fsm, qr/\(main_cnt_\d+ \d+\)/, 'the inner counter main_cnt_<n> is declared (distinct from the outer)');

    # outer: load 3, flow to the outer check
    like($fsm, qr/\(main_repeat_init_\d+\n\s+\(<= \(main_cnt 3\)\)\n\s+\(-> main_repeat_check_(\d+)\)/s,
        'the outer repeat loads 3 and flows to its check');
    my ($outer_check) = $fsm =~ /\(<= \(main_cnt 3\)\)\n\s+\(-> (main_repeat_check_\d+)\)/s;

    # inner: load 2, flow to the inner check
    like($fsm, qr/\(main_repeat_init_\d+\n\s+\(<= \(main_cnt_\d+ 2\)\)\n\s+\(-> main_repeat_check_\d+\)/s,
        'the inner repeat loads 2 (its own counter) and flows to its check');

    # the inner check decrements the inner counter; nonzero -> body, zero -> the OUTER check
    like($fsm, qr/\(main_repeat_check_\d+\n\s+\(-- main_cnt_\d+\)\n\s+\(\?main_cnt_\d+\n\s+\(!=0 \(-> main_update_\d+\)\)\n\s+\(=0 \(-> \Q$outer_check\E\)\)/s,
        'the inner check loops to the body when nonzero and returns to the outer check when zero');

    # the outer check decrements the outer counter; nonzero -> the inner init (the outer body)
    like($fsm, qr/\Q$outer_check\E\n\s+\(-- main_cnt\)\n\s+\(\?main_cnt\n\s+\(!=0 \(-> main_repeat_init_\d+\)\)\n\s+\(=0 \(-> main_done_\d+\)\)/s,
        'the outer check loops to the inner repeat (its body) when nonzero and exits when zero');
};

subtest 'deeper nesting gives each level its own counter' => sub {
    my $actor = parse_source(<<'ISF', 'triple');
(actor t3
  (interface (input start) (output done) (output count (width 8)))
  (transaction main
    (on start)
    (repeat 2 (repeat 2 (repeat 2 (update count (+ count 1)))))
    (complete done)))
ISF
    my $fsm = eval { FSM::Scheduler::ISF->new()->lower($actor) }->{files}{'t3.fsm'};
    my %counters;
    while ($fsm =~ /\((main_cnt\w*) \d+\)\n/g) { $counters{$1}++ }
    is(scalar(keys %counters), 3, 'three nested repeats declare three distinct counters')
        or diag('counters: ' . join(', ', sort keys %counters));
};

subtest 'a sequential repeat after a nested repeat reuses the bare counter (no collision)' => sub {
    # The outermost repeats run one at a time, so they share `<tx>_cnt`; only simultaneously
    # active (nested) repeats need distinct counters.
    my $actor = parse_source(<<'ISF', 'seq');
(actor sq
  (interface (input start) (input din (width 8)) (output done) (output count (width 8)))
  (transaction main
    (on start)
    (repeat 2 (repeat 2 (update count (+ count 1))))
    (repeat 4 (update count din))
    (complete done)))
ISF
    my $lowered = eval { FSM::Scheduler::ISF->new()->lower($actor) };
    ok($lowered, 'a nested repeat followed by a sequential repeat lowers') or diag($@);
};

done_testing();
