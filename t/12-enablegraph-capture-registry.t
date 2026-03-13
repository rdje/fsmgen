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
  )
  (s0
    (OUT = IN)
    (-> s1)
  )
  (s1
    (OUT = 0)
  )
)
FSM

my $raw_ast = Lispish::multi($fsm_path);
my $adapter = FSM::Adapter::FSMGenFull->new(debug => 0);
my $fsm_module = $adapter->parse_fsm($raw_ast);
my $hdl_gen = FSM::HDL::FlattenedDT->new(debug => 0);

my $hdl = $hdl_gen->generate_systemverilog($fsm_module);

ok(
    exists $hdl_gen->{lhs_assignments}->{OUT},
    'live generation records captured assignments for OUT',
);
ok(
    ref($hdl_gen->{lhs_assignments}->{OUT}) eq 'ARRAY' && @{$hdl_gen->{lhs_assignments}->{OUT}} >= 1,
    'captured assignments for OUT are stored as an array',
);

my $out_assignment = $hdl_gen->{lhs_assignments}->{OUT}[0];
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
    $out_assignment->{operator},
    '=',
    'captured assignment preserves operator metadata for OUT',
);

ok(
    exists $hdl_gen->{lhs_assignments}->{next_state},
    'live generation records captured next_state transitions',
);
ok(
    ref($hdl_gen->{lhs_assignments}->{next_state}) eq 'ARRAY' && @{$hdl_gen->{lhs_assignments}->{next_state}} >= 1,
    'captured next_state transitions are stored as an array',
);

my $next_state_assignment = $hdl_gen->{lhs_assignments}->{next_state}[0];
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
    $next_state_assignment->{assignment_intent}{assignment_family},
    'state_transition',
    'captured transition stores state-transition assignment metadata',
);

ok(
    exists $hdl_gen->{all_lhs}->{OUT},
    'captured assignment registration tracks OUT in all_lhs',
);
ok(
    exists $hdl_gen->{all_lhs}->{next_state},
    'captured transition registration tracks next_state in all_lhs',
);
ok(
    $hdl_gen->{lhs_ast_map}->{OUT} && ref($hdl_gen->{lhs_ast_map}->{OUT}),
    'captured assignment registration stores OUT in lhs_ast_map',
);
ok(
    $hdl_gen->{lhs_ast_map}->{next_state} && ref($hdl_gen->{lhs_ast_map}->{next_state}),
    'captured transition registration stores synthetic next_state AST in lhs_ast_map',
);
is(
    $hdl_gen->{lhs_ast_map}->{next_state}->to_systemverilog,
    'next_state',
    'synthetic next_state AST renders as next_state',
);

like(
    $hdl,
    qr/\bassign\s+s0_en\s*=\s*current_state == S0\s*;/,
    'generated HDL still emits the state enable for s0',
);
like(
    $hdl,
    qr/\bassign\s+s0_out_in_en\s*=/,
    'generated HDL still emits enable logic for the captured OUT assignment',
);

done_testing();

sub write_file {
    my ($path, $content) = @_;
    open my $fh, '>', $path or die "Cannot open $path for write: $!";
    print {$fh} $content or die "Cannot write $path: $!";
    close $fh or die "Cannot close $path: $!";
}
