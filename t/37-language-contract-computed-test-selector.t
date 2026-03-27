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

my $tempdir = tempdir(CLEANUP => 1);
my $fsm_path = File::Spec->catfile($tempdir, 'computed_test_selector.fsm');

write_file($fsm_path, <<'FSM');
(?fsm:computed_test_selector
  (+system
    (clock clk)
    (sreset rstn)
  )
  (+size
    (A 1)
    (B 1)
    (X 1)
    (Y 1)
  )
  (s0
    (?(| A B)
      (=0
        (X = 1)
      )
      (=1
        (Y = 1)
      )
    )
  )
)
FSM

my $raw_ast = Lispish::multi($fsm_path);
my $adapter = FSM::Adapter::FSMGenFull->new(debug => 0);
my $fsm_module = $adapter->parse_fsm($raw_ast);

my @computed_test_signals = sort grep {
    ($fsm_module->signals->{$_}->get_attribute('is_intermediate') // 0)
} keys %{$fsm_module->signals || {}};

is(scalar(@computed_test_signals), 1, 'computed selector produces exactly one intermediate test signal');
my $condition_signal = $computed_test_signals[0];
ok($condition_signal, 'computed selector intermediate signal name was captured');

my $phase1_gen = FSM::HDL::FlattenedDT->new(debug => 0);
$phase1_gen->{enable_graph_signal_support}->set_fsm_module_reference($fsm_module);
$phase1_gen->{orchestrator}->flatten_all_decision_trees($fsm_module);

my ($x_assignment) = grep { $_->{dt} eq 's0' && $_->{rhs} eq '1' } @{$phase1_gen->{lhs_assignments}->{X} || []};
ok($x_assignment, 'captured assignments include the computed-selector =0 branch');
is(
    $x_assignment->{conditions_ast}->to_systemverilog,
    "$condition_signal == 1'b0",
    'computed selector =0 branch lowers through the intermediate condition signal'
);

my ($y_assignment) = grep { $_->{dt} eq 's0' && $_->{rhs} eq '1' } @{$phase1_gen->{lhs_assignments}->{Y} || []};
ok($y_assignment, 'captured assignments include the computed-selector =1 branch');
is(
    $y_assignment->{conditions_ast}->to_systemverilog,
    "$condition_signal == 1'b1",
    'computed selector =1 branch lowers through the intermediate condition signal'
);

my $hdl = FSM::HDL::FlattenedDT->new(debug => 0)->generate_systemverilog($fsm_module);

like($hdl, qr/\binput\s+wire\s+A\b/, 'generated HDL exposes A as an input');
like($hdl, qr/\binput\s+wire\s+B\b/, 'generated HDL exposes B as an input');
like($hdl, qr/\bwire\s+\Q$condition_signal\E\s*;/, 'generated HDL declares the computed selector intermediate signal');
like($hdl, qr/\bassign\s+\Q$condition_signal\E\s*=\s*A\s*\|\s*B\s*;/, 'generated HDL drives the computed selector intermediate signal from the expression');
like($hdl, qr/\b\Q$condition_signal\E\s*==\s*1'b0\b/, 'generated HDL reuses the intermediate signal in the =0 branch');
like($hdl, qr/\b\Q$condition_signal\E\s*==\s*1'b1\b/, 'generated HDL reuses the intermediate signal in the =1 branch');

done_testing();

sub write_file {
    my ($path, $content) = @_;
    open my $fh, '>', $path or die "Cannot open $path for write: $!";
    print {$fh} $content or die "Cannot write $path: $!";
    close $fh or die "Cannot close $path: $!";
}
