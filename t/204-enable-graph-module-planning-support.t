#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use File::Temp qw(tempdir);
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::HDL::FlattenedDT;
use FSM::Pipeline::SourceFrontend;

subtest 'enable-graph module-planning support rebuilds module, declaration, and state plans from a prepared backend context' => sub {
    my $fsm_module = parse_fsm_module(
        'enable_graph_module_planning_contract',
        <<'FSM'
(?fsm:enable_graph_module_planning_contract
  (+system
    (clock clk)
    (sreset rstn)
  )
  (+types
    (type signed_byte (signed (bits 8)))
  )
  (+size
    (OUT signed_byte)
    (IN signed_byte)
    (FLAG 1)
  )
  (idle
    (OUT <= IN)
    (-> run)
  )
  (run
    (FLAG = 1)
  )
)
FSM
    );

    my $prepared_backend = prepare_flattened_backend($fsm_module);
    my $support = $prepared_backend->{enable_graph_module_planning_support};

    my $system_contract = $support->effective_system_contract($fsm_module);
    is($system_contract->{clock}, 'clk', 'module-planning support keeps the explicit clock name');
    is($system_contract->{reset}, 'rstn', 'module-planning support keeps the explicit reset name');
    ok(!$system_contract->{implicit}, 'module-planning support preserves that the system contract is explicit');

    my $state_plan = $support->build_state_register_plan($fsm_module);
    ok($state_plan->{has_state_registers}, 'module-planning support keeps regular-state register planning enabled');
    is($state_plan->{state_count}, 2, 'module-planning support counts the regular states');
    is($state_plan->{state_bits}, 2, 'module-planning support preserves the current two-state encoding width contract');
    is($state_plan->{reset_state_name}, 'IDLE', 'module-planning support keeps the first regular state as the reset state');
    is_deeply(
        [map { $_->{localparam_name} } @{$state_plan->{encodings} || []}],
        ['IDLE', 'RUN'],
        'module-planning support preserves regular-state encoding order',
    );

    my $module_plan = $support->build_module_declaration_plan($fsm_module);
    my %base_port_by_name = map { $_->{name} => $_ } @{$module_plan->{base_ports} || []};
    my %input_by_name = map { $_->{name} => $_ } @{$module_plan->{inputs} || []};
    my %output_by_name = map { $_->{name} => $_ } @{$module_plan->{outputs} || []};

    is($base_port_by_name{clk}{direction}, 'input', 'module-planning support keeps clk as an input base port');
    is($base_port_by_name{rstn}{direction}, 'input', 'module-planning support keeps rstn as an input base port');
    is($input_by_name{IN}{width}, 8, 'module-planning support keeps IN as an 8-bit input');
    is($input_by_name{IN}{signed}, 1, 'module-planning support preserves signed semantic type intent on direct inputs');
    ok(!exists $output_by_name{OUT}, 'module-planning support does not promote OUT to a module output without explicit output exposure');
    ok(!exists $output_by_name{FLAG}, 'module-planning support does not promote FLAG to a module output without explicit output exposure');
    ok(!exists $module_plan->{declared_port_signals}{OUT}, 'module-planning support does not record OUT as a declared module port without explicit output exposure');
    is($module_plan->{port_directions}{IN}, 'input', 'module-planning support records IN as an input');
    ok(!exists $module_plan->{port_directions}{OUT}, 'module-planning support does not assign OUT a module-port direction without explicit output exposure');

    my $decl_plan = $support->build_internal_signal_declaration_plan(
        $fsm_module,
        $module_plan->{declared_port_signals},
    );
    is($decl_plan->{aux_decls}{OUT_q}, 8, 'module-planning support exposes the OUT_q helper width for register-input assignments');
    is($decl_plan->{signal_decls}{OUT}, 8, 'module-planning support keeps OUT as an internal declared signal without explicit output exposure');
    is($decl_plan->{signal_signed}{OUT}, 1, 'module-planning support preserves signed semantic type intent on internal declarations');
    is($decl_plan->{aux_signed}{OUT_q}, 1, 'module-planning support preserves signed semantic type intent on helper declarations');
    is($decl_plan->{signal_decls}{FLAG}, 1, 'module-planning support keeps FLAG as an internal declared signal without explicit output exposure');
};

done_testing();

sub parse_fsm_module {
    my ($basename, $fsm_text) = @_;
    my $tempdir = tempdir(CLEANUP => 1);
    my $fsm_path = File::Spec->catfile($tempdir, "$basename.fsm");

    write_file($fsm_path, $fsm_text);
    my $raw_ast = FSM::Pipeline::SourceFrontend->parse_fsm_file(
        fsm_file => $fsm_path,
        debug_level => 0,
    );
    return FSM::Pipeline::SourceFrontend->create_fsm_module(
        raw_ast => $raw_ast,
        debug_level => 0,
    );
}

sub prepare_flattened_backend {
    my ($fsm_module) = @_;
    my $hdl_generator = FSM::HDL::FlattenedDT->new(debug => 0);
    $hdl_generator->{orchestrator}->reset_generation_state();
    $hdl_generator->{enable_graph_signal_support}->set_fsm_module_reference($fsm_module);
    $hdl_generator->{orchestrator}->flatten_all_decision_trees($fsm_module);
    $hdl_generator->{enable_graph_enable_support}->generate_enable_conditions($fsm_module);
    return $hdl_generator;
}

sub write_file {
    my ($path, $content) = @_;
    open my $fh, '>', $path or die "Cannot open $path for write: $!";
    print {$fh} $content or die "Cannot write $path: $!";
    close $fh or die "Cannot close $path: $!";
}
