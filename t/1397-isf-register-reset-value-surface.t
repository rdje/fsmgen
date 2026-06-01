#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Spec;
use File::Temp qw/ tempdir /;
use FindBin;
use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Adapter::ISF;
use FSM::Scheduler::ISF;
use Lispish;
use FSM::Adapter::FSMGenFull;
use FSM::HDL::FlattenedDT;

# ISF-REGISTER-RESET-VALUES.3
#
# ISF surface for a register's HARDWARE reset value: `(local NAME (width N) (reset V))`
# emits the `.fsm` `+size` carrier `(NAME N (reset V))` (ISF-REGISTER-RESET-VALUES.2), so
# the register powers up at V out of hardware reset. This is distinct from the
# init-on-entry `(default V)`/`(init V)`. Unspecified -> resets to all-0s (unchanged). An
# over-width or non-integer reset value fails closed.

sub lower_fsm {
    my ($source, $name) = @_;
    my $actor = FSM::Adapter::ISF->new()->parse_source($source, "$name.isf");
    return FSM::Scheduler::ISF->new()->lower($actor)->{files}{"$name.fsm"};
}

sub lower_error {
    my ($source, $name) = @_;
    my $ok = eval { lower_fsm($source, $name); 1 };
    return $ok ? '' : $@;
}

my $tempdir = tempdir(CLEANUP => 1);
sub fsm_to_hdl {
    my ($fsm_text, $name) = @_;
    my $path = File::Spec->catfile($tempdir, "$name.fsm");
    open my $fh, '>', $path or die "write $path: $!";
    print $fh $fsm_text; close $fh;
    my $module = FSM::Adapter::FSMGenFull->new(debug => 0)->parse_fsm(Lispish::multi($path));
    return FSM::HDL::FlattenedDT->new(debug => 0)->generate_systemverilog($module);
}

subtest '(local NAME (width N) (reset V)) emits the +size (reset V) carrier' => sub {
    my $fsm = lower_fsm(<<'ISF', 'rv');
(actor rv
  (interface (input start) (input din (width 8)) (output done) (output q (width 8)))
  (transaction main
    (on start)
    (local acc (width 8) (reset 5))
    (update acc (+ acc din))
    (update q acc)
    (complete done)))
ISF
    like($fsm, qr/\(acc 8 \(reset 5\)\)/, 'the local declares its width with a (reset 5) carrier in +size');
};

subtest 'the reset value flows to the HDL reset block (powers up at V)' => sub {
    my $fsm = lower_fsm(<<'ISF', 'rvh');
(actor rvh
  (interface (input start) (input din (width 8)) (output done) (output q (width 8)))
  (transaction main
    (on start)
    (local acc (width 8) (reset 5))
    (update acc (+ acc din))
    (update q acc)
    (complete done)))
ISF
    my $hdl = fsm_to_hdl($fsm, 'rvh');
    like($hdl, qr/\bacc <= 5\b/, 'acc powers up at its reset value 5');
    unlike($hdl, qr/\bacc <= 8'b0+\b/, 'acc no longer resets to all-0s');
};

subtest 'without (reset V) the local resets to all-0s (backward-compatible)' => sub {
    my $fsm = lower_fsm(<<'ISF', 'rv0');
(actor rv0
  (interface (input start) (input din (width 8)) (output done) (output q (width 8)))
  (transaction main
    (on start)
    (local acc (width 8))
    (update acc (+ acc din))
    (update q acc)
    (complete done)))
ISF
    unlike($fsm, qr/\(acc 8 \(reset/, 'no (reset …) carrier is emitted when none is given');
    my $hdl = fsm_to_hdl($fsm, 'rv0');
    like($hdl, qr/\bacc <= 8'b0+\b/, 'acc resets to all-0s as before');
};

subtest '(reset V) and (default V) are orthogonal (power-up value vs init-on-entry)' => sub {
    my $fsm = lower_fsm(<<'ISF', 'rvd');
(actor rvd
  (interface (input start) (input din (width 8)) (output done) (output q (width 8)))
  (transaction main
    (on start)
    (local acc (width 8) (default 3) (reset 5))
    (update acc (+ acc din))
    (update q acc)
    (complete done)))
ISF
    like($fsm, qr/\(acc 8 \(reset 5\)\)/, 'the reset value 5 is carried in +size');
    like($fsm, qr/\(<- \(acc 3\)\)/, 'the default 3 is materialized as an init-on-entry set');
};

subtest 'an over-width or non-integer (reset V) fails closed' => sub {
    my $over = lower_error(<<'ISF', 'rvbadw');
(actor t
  (interface (input start) (input din (width 8)) (output done) (output q (width 8)))
  (transaction main
    (on start)
    (local acc (width 8) (reset 256))
    (update q acc)
    (complete done)))
ISF
    like($over, qr/reset value does not fit in 8 bit/, 'a reset value wider than the register is rejected');

    my $nonint = lower_error(<<'ISF', 'rvbadi');
(actor t
  (interface (input start) (input din (width 8)) (output done) (output q (width 8)))
  (transaction main
    (on start)
    (local acc (width 8) (reset foo))
    (update q acc)
    (complete done)))
ISF
    like($nonint, qr/\(reset V\)\)' requires a non-negative integer literal/, 'a non-integer reset value is rejected');
};

done_testing();
