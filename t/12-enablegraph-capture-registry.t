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
my $fsm_path = File::Spec->catfile($tempdir, 'capture_registry.fsm');

write_file($fsm_path, <<'FSM');
(?fsm:capture_registry
  (+system
    (clock clk)
    (sreset rstn)
  )
  (+size
    (OUT 1)
    (IN 1)
    (MODE 1)
  )
  (s0
    (?MODE
      (=0
        (OUT = 0)
      )
      (=1
        (OUT = IN)
        (-> s1)
      )
    )
  )
  (s1
    (OUT = 0)
  )
)
FSM

my $raw_ast = Lispish::multi($fsm_path);
my $adapter = FSM::Adapter::FSMGenFull->new(debug => 0);
my $fsm_module = $adapter->parse_fsm($raw_ast);
my $phase1_gen = FSM::HDL::FlattenedDT->new(debug => 0);
$phase1_gen->{enable_graph_signal_support}->set_fsm_module_reference($fsm_module);
$phase1_gen->{orchestrator}->flatten_all_decision_trees($fsm_module);
my $state_plan = $phase1_gen->{enable_graph_module_planning_support}->build_state_register_plan($fsm_module);

ok(
    exists $phase1_gen->{lhs_assignments}->{OUT},
    'live generation records captured assignments for OUT',
);
ok(
    ref($phase1_gen->{lhs_assignments}->{OUT}) eq 'ARRAY' && @{$phase1_gen->{lhs_assignments}->{OUT}} >= 1,
    'captured assignments for OUT are stored as an array',
);

my ($out_assignment) = grep {
    $_->{dt} eq 's0' && $_->{rhs} eq 'IN'
} @{$phase1_gen->{lhs_assignments}->{OUT}};

ok(
    $out_assignment,
    'captured assignments for OUT include the MODE==1 branch assignment',
);
ok(
    $out_assignment->{lhs_ast} && ref($out_assignment->{lhs_ast}),
    'captured assignment stores lhs_ast metadata',
);
ok(
    $out_assignment->{conditions_ast} && ref($out_assignment->{conditions_ast}),
    'captured assignment stores conditions_ast metadata',
);
is(
    $out_assignment->{rhs},
    'IN',
    'captured assignment preserves RHS text for OUT',
);
is(
    $out_assignment->{conditions_ast}->to_systemverilog,
    "MODE == 1'b1",
    'captured assignment stores the test-node condition AST through EnableGraph ownership',
);
is(
    $out_assignment->{operator},
    '=',
    'captured assignment preserves operator metadata for OUT',
);

ok(
    exists $phase1_gen->{lhs_assignments}->{next_state},
    'live generation records captured next_state transitions',
);
ok(
    ref($phase1_gen->{lhs_assignments}->{next_state}) eq 'ARRAY' && @{$phase1_gen->{lhs_assignments}->{next_state}} >= 1,
    'captured next_state transitions are stored as an array',
);

my $next_state_assignment = $phase1_gen->{lhs_assignments}->{next_state}[0];
is(
    $next_state_assignment->{rhs},
    'S1',
    'captured transition stores the uppercased target state',
);
ok(
    $next_state_assignment->{conditions_ast} && ref($next_state_assignment->{conditions_ast}),
    'captured transition stores conditions_ast metadata',
);
is(
    $next_state_assignment->{conditions_ast}->to_systemverilog,
    "MODE == 1'b1",
    'captured transition stores the test-node condition AST through EnableGraph ownership',
);
is(
    $next_state_assignment->{assignment_intent}{assignment_family},
    'state_transition',
    'captured transition stores state-transition assignment metadata',
);

ok(
    exists $phase1_gen->{all_lhs}->{OUT},
    'captured assignment registration tracks OUT in all_lhs',
);
ok(
    exists $phase1_gen->{all_lhs}->{next_state},
    'captured transition registration tracks next_state in all_lhs',
);
ok(
    $phase1_gen->{lhs_ast_map}->{OUT} && ref($phase1_gen->{lhs_ast_map}->{OUT}),
    'captured assignment registration stores OUT in lhs_ast_map',
);
ok(
    $phase1_gen->{lhs_ast_map}->{next_state} && ref($phase1_gen->{lhs_ast_map}->{next_state}),
    'captured transition registration stores synthetic next_state AST in lhs_ast_map',
);
is(
    $phase1_gen->{lhs_ast_map}->{next_state}->to_systemverilog,
    'next_state',
    'synthetic next_state AST renders as next_state',
);
ok(
    $state_plan->{has_state_registers},
    'state register plan stays enabled for regular-state FSMs',
);
is(
    $state_plan->{reset_state_name},
    'S0',
    'state register plan keeps the first regular state as reset state',
);
is(
    $state_plan->{state_bits},
    2,
    'state register plan preserves the current two-state encoding width contract',
);
is(
    join(',', map { $_->{localparam_name} } @{$state_plan->{encodings} || []}),
    'S0,S1',
    'state register plan preserves regular-state encoding order',
);

my $hdl_gen = FSM::HDL::FlattenedDT->new(debug => 0);
my $hdl = $hdl_gen->generate_systemverilog($fsm_module);

like(
    $hdl,
    qr/\bassign\s+s0_en\s*=\s*current_state == S0\s*;/,
    'generated HDL still emits the state enable for s0',
);
like(
    $hdl,
    qr/\bMODE\s*==\s*1'b1\b/,
    'generated HDL still emits the test-node comparison in enable logic',
);

done_testing();

sub write_file {
    my ($path, $content) = @_;
    open my $fh, '>', $path or die "Cannot open $path for write: $!";
    print {$fh} $content or die "Cannot write $path: $!";
    close $fh or die "Cannot close $path: $!";
}
