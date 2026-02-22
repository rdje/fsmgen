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
my $fsm_path = File::Spec->catfile($tempdir, 'assignment_intent_phase1.fsm');

write_file($fsm_path, <<'FSM');
(?fsm:assignment_intent_phase1
  (+system
    (clock clk)
    (sreset rstn)
  )
  (-state0
    (A <- B)
    (C <= D)
    (E = F)
    (G> = H)
    (I <-= J)
    (K <=+ L)
    (P1 <3 1)
    (P0 <2 0)
  )
  (+size
    (A 8)
    (B 8)
    (C 8)
    (D 8)
    (E 1)
    (F 1)
    (G 1)
    (H 1)
    (I 8)
    (J 8)
    (K 8)
    (L 8)
    (P1 1)
    (P0 1)
  )
)
FSM

my $raw_ast = Lispish::multi($fsm_path);
my $adapter = FSM::Adapter::FSMGenFull->new(debug => 0);
my $fsm_module = $adapter->parse_fsm($raw_ast);

ok($fsm_module, 'parsed FSM module');
ok($fsm_module->states && @{$fsm_module->states} >= 1, 'module has at least one state');

my $state = $fsm_module->states->[0];
my $dts = $state->decision_trees;
ok($dts && @$dts >= 1, 'state has decision trees');

my @elements;
for my $dt (@$dts) {
    my $dt_elements = $dt->elements || [];
    push @elements, @$dt_elements;
}
is(scalar(@elements), 8, 'state decision trees contain expected assignments');

my %assignment_by_target;
for my $element (@elements) {
    ok($element->isa('FSM::CoreAST::Assignment') || $element->isa('FSM::CoreAST::RegisterAssignment'),
        'element is assignment-like');
    my $target_name = extract_target_name($element);
    $assignment_by_target{$target_name} = $element if defined $target_name;
}

ok($assignment_by_target{A}, 'captured assignment for target A');
ok($assignment_by_target{C}, 'captured assignment for target C');
ok($assignment_by_target{E}, 'captured assignment for target E');
ok($assignment_by_target{G}, 'captured assignment for target G');
ok($assignment_by_target{I}, 'captured assignment for target I');
ok($assignment_by_target{K}, 'captured assignment for target K');
ok($assignment_by_target{P1}, 'captured assignment for target P1');
ok($assignment_by_target{P0}, 'captured assignment for target P0');

is($assignment_by_target{A}->operator_symbol, '<-', "A uses '<-' operator intent");
is($assignment_by_target{A}->assignment_intent->{register_style}, 'output_named', "A register style is 'output_named'");
is($assignment_by_target{A}->assignment_intent->{lhs_binding}, 'flop_q_output', "A '<-' binds LHS to flop Q output");
is($assignment_by_target{A}->source_provenance->{raw_operator}, '<-', 'A provenance captures raw operator');

is($assignment_by_target{C}->operator_symbol, '<=', "C uses '<=' operator intent");
is($assignment_by_target{C}->assignment_intent->{register_style}, 'input_named', "C register style is 'input_named'");
is($assignment_by_target{C}->assignment_intent->{lhs_binding}, 'flop_d_input', "C '<=' binds LHS to flop D input");
is(
    $assignment_by_target{C}->assignment_intent->{immediate_visibility},
    'same_cycle_on_d_input',
    "C '<=' exposes same-cycle D-input visibility intent"
);
is(
    $assignment_by_target{C}->assignment_intent->{hold_policy},
    'q_feedback_when_no_enable',
    "C '<=' encodes hold-by-feedback intent when enables are inactive"
);

is($assignment_by_target{E}->operator_symbol, '=', "E uses '=' operator intent");
is($assignment_by_target{E}->assignment_intent->{assignment_family}, 'combinatorial', 'E assignment family is combinatorial');

is($assignment_by_target{G}->output_exposure, 'explicit', "G output marker '>' is preserved as explicit exposure");
is($assignment_by_target{I}->operator_symbol, '<-=', "I uses '<-=' operator intent");
is($assignment_by_target{I}->assignment_intent->{expose_next_output}, 1, "I '<-=' exposes next_* output");
is($assignment_by_target{I}->assignment_intent->{auxiliary_output_name}, 'next_I', "I '<-=' auxiliary output name is next_I");


is($assignment_by_target{K}->operator_symbol, '<=+', "K uses '<=+' operator intent");
is($assignment_by_target{K}->assignment_intent->{expose_q_output}, 1, "K '<=+' exposes *_r output");
is($assignment_by_target{K}->assignment_intent->{auxiliary_output_name}, 'K_r', "K '<=+' auxiliary output name is K_r");

is($assignment_by_target{P1}->operator_symbol, '<3', "P1 uses '<3' operator intent");
is($assignment_by_target{P1}->assignment_intent->{assignment_family}, 'pulse_delay', "P1 is pulse-delay family");
is($assignment_by_target{P1}->assignment_intent->{pulse_delay_cycles}, 3, "P1 pulse delay is 3 cycles (Q+3)");
is($assignment_by_target{P1}->assignment_intent->{pulse_active_level}, 1, "P1 '<3 1' is positive pulse");
is($assignment_by_target{P1}->assignment_intent->{pulse_rest_level}, 0, "P1 '<3 1' rests at 0");
is($assignment_by_target{P1}->assignment_intent->{pulse_width_cycles}, 1, "P1 pulse width is one cycle");

is($assignment_by_target{P0}->operator_symbol, '<2', "P0 uses '<2' operator intent");
is($assignment_by_target{P0}->assignment_intent->{assignment_family}, 'pulse_delay', "P0 is pulse-delay family");
is($assignment_by_target{P0}->assignment_intent->{pulse_delay_cycles}, 2, "P0 pulse delay is 2 cycles (Q+2)");
is($assignment_by_target{P0}->assignment_intent->{pulse_active_level}, 0, "P0 '<2 0' is negative pulse");
is($assignment_by_target{P0}->assignment_intent->{pulse_rest_level}, 1, "P0 '<2 0' rests at 1");
is($assignment_by_target{P0}->assignment_intent->{pulse_width_cycles}, 1, "P0 pulse width is one cycle");

my $hdl_gen = FSM::HDL::FlattenedDT->new(debug => 0);

is(
    $hdl_gen->get_signal_assignment_type('lhs_meta_lte', { assignments => [ { operator => '<=' } ] }),
    'register_in',
    "assignment classifier maps '<=' to register_in"
);

is(
    $hdl_gen->get_signal_assignment_type('lhs_meta_lt', { assignments => [ { operator => '<-' } ] }),
    'register_out',
    "assignment classifier maps '<-' to register_out"
);

is(
    $hdl_gen->get_signal_assignment_type('lhs_meta_eq', { assignments => [ { operator => '=' } ] }),
    'mux_out',
    "assignment classifier maps '=' to mux_out"
);

is(
    $hdl_gen->get_signal_assignment_type('lhs_meta_lt_rm', { assignments => [ { operator => '<-=' } ] }),
    'register_out_dual',
    "assignment classifier maps '<-=' to register_out_dual"
);

is(
    $hdl_gen->get_signal_assignment_type('lhs_meta_lte_mr', { assignments => [ { operator => '<=+' } ] }),
    'register_in_dual',
    "assignment classifier maps '<=+' to register_in_dual"
);

is(
    $hdl_gen->get_signal_assignment_type('lhs_meta_pulse', { assignments => [ { operator => '<3' } ] }),
    'pulse_delayed',
    "assignment classifier maps '<N' to pulse_delayed"
);

my $hdl = $hdl_gen->generate_systemverilog($fsm_module);
like($hdl, qr/\boutput\s+reg\s+\[7:0\]\s+next_I\b/s, "generated HDL exposes next_I output for '<-='");
like($hdl, qr/\boutput\s+reg\s+\[7:0\]\s+K_r\b/s, "generated HDL exposes K_r output for '<=+'");
like($hdl, qr/\breg\s+\[2:0\]\s+P1_pulse_delay_pipe\b/s, "generated HDL declares delay pipeline for P1 <3");
like($hdl, qr/\bif\s*\(\s*P1_pulse_delay_pipe\[2\]\s*\)\s*begin\s*\n\s*P1\s*<=\s*1'b1;/s, "generated HDL emits positive delayed pulse at Q+3 for P1");
like($hdl, qr/\breg\s+\[1:0\]\s+P0_pulse_delay_pipe\b/s, "generated HDL declares delay pipeline for P0 <2");
like($hdl, qr/\bif\s*\(\s*P0_pulse_delay_pipe\[1\]\s*\)\s*begin\s*\n\s*P0\s*<=\s*1'b0;/s, "generated HDL emits negative delayed pulse at Q+2 for P0");

done_testing();

sub extract_target_name {
    my ($assignment) = @_;
    return undef unless $assignment && $assignment->can('target');
    my $target = $assignment->target;
    return undef unless $target;

    if ($target->can('name')) {
        my $name = eval { $target->name };
        return $name if defined $name;
    }

    if ($target->can('signal') && $target->signal && $target->signal->can('name')) {
        return $target->signal->name;
    }

    return undef;
}

sub write_file {
    my ($path, $content) = @_;
    open my $fh, '>', $path or die "Cannot open $path for write: $!";
    print {$fh} $content or die "Cannot write $path: $!";
    close $fh or die "Cannot close $path: $!";
}
