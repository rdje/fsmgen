#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Spec;
use File::Temp qw/ tempdir /;
use FindBin;
use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use Lispish;
use FSM::Adapter::FSMGenFull;
use FSM::HDL::FlattenedDT;

# ISF-REGISTER-RESET-VALUES.2
#
# A `+size` register may carry an optional `(reset V)` marker —
# `(signal width (reset V))` — that pins its hardware reset value. The value is
# carried as a signal attribute the HDL backend already consumes, so the register
# powers up at V. When no `(reset V)` is given the register resets to all-0s, exactly
# as before (fully backward-compatible). The marker is unambiguous against width
# expressions.

my $tempdir = tempdir(CLEANUP => 1);

sub generate_hdl {
    my ($fsm_text, $name) = @_;
    my $path = File::Spec->catfile($tempdir, "$name.fsm");
    open my $fh, '>', $path or die "write $path: $!";
    print $fh $fsm_text;
    close $fh;
    my $raw_ast = Lispish::multi($path);
    my $module  = FSM::Adapter::FSMGenFull->new(debug => 0)->parse_fsm($raw_ast);
    return FSM::HDL::FlattenedDT->new(debug => 0)->generate_systemverilog($module);
}

subtest 'a (reset V) marker pins the register hardware reset value' => sub {
    my $hdl = generate_hdl(<<'FSM', 'reset5');
(?fsm:rv5
  (+system (clock clk) (areset rst_n))
  (+size (start 1) (din 8) (done 1) (q 8 (reset 5)))
  (rv5_idle_0 (= (can_accept 1)) (<start (-> rv5_update_1)))
  (rv5_update_1 (<- (q> din)) (-> rv5_done_2))
  (rv5_done_2 (<1 (done> 1)) (-> rv5_idle_0))
)
FSM
    ok($hdl && $hdl ne '', 'HDL generated for the reset-5 FSM');
    like($hdl, qr/\bq <= 5\b/, 'q resets to its declared reset value (5), not 0');
    unlike($hdl, qr/\bq <= 8'h00\b/, 'q no longer resets to 0');
};

subtest 'without a (reset V) the register resets to all-0s (backward-compatible)' => sub {
    my $hdl = generate_hdl(<<'FSM', 'reset0');
(?fsm:rv0
  (+system (clock clk) (areset rst_n))
  (+size (start 1) (din 8) (done 1) (q 8))
  (rv0_idle_0 (= (can_accept 1)) (<start (-> rv0_update_1)))
  (rv0_update_1 (<- (q> din)) (-> rv0_done_2))
  (rv0_done_2 (<1 (done> 1)) (-> rv0_idle_0))
)
FSM
    like($hdl, qr/\bq <= 8'h00\b/, 'q resets to all-0s when no reset value is given');
};

subtest 'a non-integer (reset V) fails closed' => sub {
    my $ok = eval {
        generate_hdl(<<'FSM', 'resetbad');
(?fsm:rvb
  (+system (clock clk) (areset rst_n))
  (+size (start 1) (din 8) (done 1) (q 8 (reset foo)))
  (rvb_idle_0 (= (can_accept 1)) (<start (-> rvb_update_1)))
  (rvb_update_1 (<- (q> din)) (-> rvb_done_2))
  (rvb_done_2 (<1 (done> 1)) (-> rvb_idle_0))
)
FSM
        1;
    };
    my $err = $@;
    ok(!$ok, 'a non-integer reset value is rejected');
    like($err, qr/'\(reset V\)' reset value must be a non-negative integer literal/,
        'the diagnostic names the malformed reset value');
};

done_testing();
