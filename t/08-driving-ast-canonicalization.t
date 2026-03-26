#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Scalar::Util qw(blessed refaddr);
use File::Spec;
use FindBin;
use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::CoreAST;
use FSM::Adapter::FSMGenFull::SignalManager;
use FSM::Adapter::FSMGenFull::ExpressionBuilder;
use FSM::HDL::FlattenedDT;

my $source_signal = FSM::CoreAST::Signal->new(name => 'src');
my $carrier_signal = FSM::CoreAST::Signal->new(name => 'carrier');
my $attribute_ast = FSM::CoreAST::SignalRef->new($source_signal);

$carrier_signal->set_attribute('driving_ast', $attribute_ast);

ok(
    blessed($carrier_signal->driving_ast),
    'set_attribute(driving_ast => ...) populates the canonical driving_ast field',
);
is(
    refaddr($carrier_signal->driving_ast),
    refaddr($attribute_ast),
    'canonical driving_ast preserves the exact AST object provided via set_attribute',
);
is(
    refaddr($carrier_signal->get_attribute('driving_ast')),
    refaddr($attribute_ast),
    'get_attribute(driving_ast) reads back the canonical driving AST',
);

my $signal_manager = FSM::Adapter::FSMGenFull::SignalManager->new(debug => 0);
$signal_manager->register_signal('A', type => 'wire');
$signal_manager->register_signal('B', type => 'wire');

my $builder = FSM::Adapter::FSMGenFull::ExpressionBuilder->new(
    signal_manager => $signal_manager,
    debug => 0,
);

my $intermediate_ref = $builder->parse_expression(['|', 'A', 'B']);
ok(
    blessed($intermediate_ref) && $intermediate_ref->isa('FSM::CoreAST::SignalRef'),
    'complex logical expression is factored into an intermediate signal reference',
);

my $intermediate_signal = $intermediate_ref->signal;
ok($intermediate_signal, 'factored intermediate signal is available');
ok(
    blessed($intermediate_signal->driving_ast),
    'factored intermediate signal stores its defining AST natively',
);
ok(
    $intermediate_signal->get_attribute('is_intermediate'),
    'factored signal remains marked as an intermediate signal',
);

my %fsm_signals = map { $_ => $signal_manager->get_signal($_) } $signal_manager->get_all_signal_names;
my $fsm_module = FSM::CoreAST::FSMModule->new(
    name => 'driving_ast_canonicalization',
    signals => \%fsm_signals,
);

my $hdl = FSM::HDL::FlattenedDT->new(debug => 0);
$hdl->{fsm_module} = $fsm_module;

my %signal_info;
my $runtime_ast = $hdl->{backend_sv_intermediate_support}->resolve_intermediate_signal_runtime_ast($intermediate_signal->name, \%signal_info);

ok(
    blessed($runtime_ast),
    'backend runtime-AST resolution recovers the factored signal from the canonical driving_ast',
);
is(
    $signal_info{runtime_ast_source},
    'defining_ast',
    'backend resolves the runtime AST through the native defining_ast path',
);
is(
    refaddr($runtime_ast),
    refaddr($intermediate_signal->driving_ast),
    'backend reuses the same canonical driving AST object',
);

done_testing();
