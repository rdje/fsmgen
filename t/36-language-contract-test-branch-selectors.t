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
my $fsm_path = File::Spec->catfile($tempdir, 'test_branch_selectors.fsm');

write_file($fsm_path, <<'FSM');
(?fsm:test_branch_selectors
  (+system
    (clock clk)
    (sreset rstn)
  )
  (+size
    (COUNT 8)
    (NZ 1)
    (GT 1)
    (LE 1)
  )
  (s0
    (?COUNT
      (!=8'0
        (NZ = 1)
      )
      (>8'3
        (GT = 1)
      )
      (<=8'3
        (LE = 1)
      )
    )
  )
)
FSM

my $raw_ast = Lispish::multi($fsm_path);
my $adapter = FSM::Adapter::FSMGenFull->new(debug => 0);
my $fsm_module = $adapter->parse_fsm($raw_ast);

my $phase1_gen = FSM::HDL::FlattenedDT->new(debug => 0);
$phase1_gen->{enable_graph_signal_support}->set_fsm_module_reference($fsm_module);
$phase1_gen->{orchestrator}->flatten_all_decision_trees($fsm_module);

my ($nz_assignment) = grep { $_->{dt} eq 's0' && $_->{rhs} eq '1' } @{$phase1_gen->{lhs_assignments}->{NZ} || []};
ok($nz_assignment, 'captured assignments include the != selector branch');
is(
    $nz_assignment->{conditions_ast}->to_systemverilog,
    "COUNT != 8'd0",
    '!= selector lowers to != comparison AST'
);

my ($gt_assignment) = grep { $_->{dt} eq 's0' && $_->{rhs} eq '1' } @{$phase1_gen->{lhs_assignments}->{GT} || []};
ok($gt_assignment, 'captured assignments include the > selector branch');
is(
    $gt_assignment->{conditions_ast}->to_systemverilog,
    "COUNT > 8'd3",
    '> selector lowers to > comparison AST'
);

my ($le_assignment) = grep { $_->{dt} eq 's0' && $_->{rhs} eq '1' } @{$phase1_gen->{lhs_assignments}->{LE} || []};
ok($le_assignment, 'captured assignments include the <= selector branch');
is(
    $le_assignment->{conditions_ast}->to_systemverilog,
    "COUNT <= 8'd3",
    '<= selector lowers to <= comparison AST'
);

my $hdl = FSM::HDL::FlattenedDT->new(debug => 0)->generate_systemverilog($fsm_module);

like($hdl, qr/\bs0_nz_1_en\s*=\s*s0_en\s*&\s*\(\|COUNT\)\s*;/, 'generated HDL lowers != zero selector through width-safe reduction truthiness');
like($hdl, qr/\bCOUNT\s*>\s*8'd3\b/, 'generated HDL contains > selector comparison');
like($hdl, qr/\bCOUNT\s*<=\s*8'd3\b/, 'generated HDL contains <= selector comparison');

done_testing();

sub write_file {
    my ($path, $content) = @_;
    open my $fh, '>', $path or die "Cannot open $path for write: $!";
    print {$fh} $content or die "Cannot write $path: $!";
    close $fh or die "Cannot close $path: $!";
}
