#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Adapter::ISF;
use FSM::Scheduler::ISF;

# ISF-LOCAL-VARIABLES.2
#
# `(local NAME (width N))` declares an internal register at an explicit width: NAME
# is emitted in the module `+size` block at width N and is readable/writable in the
# transaction body (vs. an implicit internal scalar whose width is only inferred).
# It fails closed on a missing/invalid width or a collision with an interface port.

sub lower_source {
    my ($source, $label) = @_;
    my $actor = FSM::Adapter::ISF->new()->parse_source($source, "$label.isf");
    return FSM::Scheduler::ISF->new()->lower($actor);
}

sub lower_error {
    my ($source, $label) = @_;
    my $ok = eval { lower_source($source, $label); 1 };
    return $ok ? '' : $@;
}

subtest '(local NAME (width N)) declares an internal register at the explicit width' => sub {
    my $lowered = eval {
        lower_source(<<'ISF', 'lv_acc');
(actor lv_acc
  (interface (input start) (input din (width 8)) (output done) (output result (width 8)))
  (transaction main
    (on start)
    (local acc (width 8))
    (sample din as s)
    (set acc (+ acc s))
    (update result acc)
    (complete done)))
ISF
    };
    ok($lowered, 'a (local) declaration lowers') or diag($@);
    my $fsm = $lowered->{files}{'lv_acc.fsm'};
    my ($size) = $fsm =~ /(\(\+size[\s\S]*?\n  \))/;
    like($size, qr/\(acc 8\)/, 'the local is emitted in +size at the declared width');
    like($fsm, qr/\(acc \(\+ acc s\)\)/, 'the local is writable (set acc <- acc + s)');
    like($fsm, qr/\(result>\s*acc\)/, 'the local is readable (result <- acc)');
};

subtest 'the declared width is honored (a 12-bit local is a 12-bit register)' => sub {
    my $lowered = lower_source(<<'ISF', 'lv_wide');
(actor lv_wide
  (interface (input start) (input din (width 8)) (output done) (output result (width 12)))
  (transaction main
    (on start)
    (local wide (width 12))
    (set wide din)
    (update result wide)
    (complete done)))
ISF
    my ($size) = $lowered->{files}{'lv_wide.fsm'} =~ /(\(\+size[\s\S]*?\n  \))/;
    like($size, qr/\(wide 12\)/, 'the local keeps its declared 12-bit width');
};

subtest '(local NAME (width N) (default V)) initializes the local on transaction entry' => sub {
    # ISF-LOCAL-VARIABLES.3: a transaction-local is re-initialized each time the
    # transaction runs. `(default V)` and `(init V)` are accepted synonyms; both
    # materialize a set-to-V on entry.
    for my $kw (qw(default init)) {
        my $lowered = eval {
            lower_source(<<"ISF", "lvi-$kw");
(actor lvi
  (interface (input start) (input din (width 8)) (output done) (output result (width 8)))
  (transaction main
    (on start)
    (local acc (width 8) ($kw 5))
    (sample din as s)
    (set acc (+ acc s))
    (update result acc)
    (complete done)))
ISF
        };
        ok($lowered, "a (local ... ($kw V)) lowers") or diag($@);
        my $fsm = $lowered->{files}{'lvi.fsm'};
        like($fsm, qr/\(acc 8\)/, "$kw: the local is still declared at its width");
        like($fsm, qr/\(acc 5\)/, "$kw: the initial value materializes a set of the local to 5");
    }
};

subtest 'an out-of-range or non-integer (default V) fails closed' => sub {
    my $base = sub {
        my ($decl) = @_;
        return "(actor lv (interface (input start) (output done) (output result (width 8))) "
            . "(transaction main (on start) $decl (update result x) (complete done)))";
    };
    like(lower_error($base->('(local x (width 4) (default 99))'), 'wide'),
        qr/default value does not fit in 4 bit\(s\)/, 'default wider than the declared width');
    like(lower_error($base->('(local x (width 8) (init foo))'), 'nonint'),
        qr/'\(local x \.\.\. \(default V\)\)' requires a non-negative integer literal/, 'non-integer default (via init synonym)');
};

subtest '(local) declarations fail closed on misuse' => sub {
    my $base = sub {
        my ($decl) = @_;
        return "(actor lv (interface (input start) (input din (width 8)) (output done) (output result (width 8))) "
            . "(transaction main (on start) $decl (update result din) (complete done)))";
    };

    like(lower_error($base->('(local din (width 8))'), 'collide'),
        qr/'\(local din \.\.\.\)' collides with interface port 'din'/, 'collision with an interface port');

    like(lower_error($base->('(local x)'), 'nowidth'),
        qr/'\(local x \.\.\.\)' requires a '\(width N\)' with a positive integer/, 'missing width');

    like(lower_error($base->('(local x (width 0))'), 'zerowidth'),
        qr/'\(local x \.\.\.\)' requires a '\(width N\)' with a positive integer/, 'zero width');
};

subtest '(let NAME EXPR) names an intermediate value (pure substitution, no register)' => sub {
    # ISF-LOCAL-VARIABLES.4: `(let NAME EXPR)` substitutes NAME -> EXPR in the rest of
    # the body. It is a pure desugar — no register, no runtime cost.
    my $lowered = eval {
        lower_source(<<'ISF', 'letdemo');
(actor letdemo
  (interface (input start) (input a (width 8)) (input b (width 8)) (output done) (output result (width 8)))
  (transaction main
    (on start)
    (sample a as av)
    (sample b as bv)
    (let sum (+ av bv))
    (update result (+ sum 1))
    (complete done)))
ISF
    };
    ok($lowered, 'a (let ...) lowers') or diag($@);
    my $fsm = $lowered->{files}{'letdemo.fsm'};
    like($fsm, qr/\(result>\s*\(\+ \(\+ av bv\) 1\)\)/, 'the let name is substituted by its expression');
    unlike($fsm, qr/\(sum /, 'no register is created for the let binding');
};

subtest '(let ...) misuse fails closed' => sub {
    my $base = sub {
        my ($body) = @_;
        return "(actor t (interface (input start) (input a (width 8)) (output done) (output result (width 8))) "
            . "(transaction main (on start) $body (update result a) (complete done)))";
    };
    like(lower_error($base->('(let x 1) (let x 2)'), 'redef'),
        qr/\(let x \.\.\.\) in transaction 'main' redefines an already-bound name 'x'/, 'redefining a let name');
    like(lower_error($base->('(let a 1)'), 'portcollide'),
        qr/\(let a \.\.\.\) in transaction 'main' collides with an interface port 'a'/, 'let name colliding with an interface port');
};

done_testing();
