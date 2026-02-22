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
is(scalar(@elements), 4, 'state decision trees contain expected assignments');

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
