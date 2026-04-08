#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use File::Temp qw(tempdir);
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Backend::GeneratedModuleEmitter;
use FSM::HDL::FlattenedDT;
use FSM::HDL::FlattenedDT::Backend::SystemVerilog::InternalDeclarationEmitter;
use FSM::HDL::FlattenedDT::Backend::SystemVerilog::ScaffoldEmitter;
use FSM::Pipeline::SourceFrontend;

subtest 'internal declaration emitter rebuilds the direct backend prefix for a module with internal and helper registers' => sub {
    my $fsm_module = parse_fsm_module(
        'sv_internal_decl_contract',
        <<'FSM'
(?fsm:sv_internal_decl_contract
  (+system
    (clock clk)
    (sreset rstn)
  )
  (+types
    (type signed_byte (signed (bits 8)))
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
    (A signed_byte)
    (B signed_byte)
    (C signed_byte)
    (D signed_byte)
    (E 1)
    (F 1)
    (G 1)
    (H 1)
    (I signed_byte)
    (J signed_byte)
    (K signed_byte)
    (L signed_byte)
    (P1 1)
    (P0 1)
  )
)
FSM
    );

    my $prepared_backend = prepare_flattened_backend($fsm_module);
    my ($prefix, $internal_block) = rebuild_prefix_with_internal_decls($prepared_backend, $fsm_module);
    my $backend_result = FSM::Backend::GeneratedModuleEmitter->emit_from_fsm_module(
        fsm_module => $fsm_module,
        target_language => 'systemverilog',
        debug_level => 0,
    );
    my $normalized_prefix = normalize_dates($prefix);
    my $normalized_hdl = normalize_dates($backend_result->{hdl_code});

    is(
        substr($normalized_hdl, 0, length($normalized_prefix)),
        $normalized_prefix,
        'internal declaration emitter rebuilds the same direct backend prefix as the emitted HDL surface',
    );
    like($internal_block, qr/\breg signed \[7:0\] A;/, 'internal declaration block keeps signed direct internal register declarations');
    like($internal_block, qr/\breg signed \[7:0\] I_next;/, 'internal declaration block keeps signed dual-output helper register declarations');
    like($internal_block, qr/\breg signed \[7:0\] K_q;/, 'internal declaration block keeps signed q-visible helper register declarations');
    like($internal_block, qr/\breg \[2:0\] P1_pulse_delay_pipe;/, 'internal declaration block keeps pulse-delay helper declarations');
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
    return $hdl_generator;
}

sub rebuild_prefix_with_internal_decls {
    my ($hdl_generator, $fsm_module) = @_;
    my $scaffold_emitter = FSM::HDL::FlattenedDT::Backend::SystemVerilog::ScaffoldEmitter->new(
        flattened_dt => $hdl_generator,
    );
    my $declaration_emitter = FSM::HDL::FlattenedDT::Backend::SystemVerilog::InternalDeclarationEmitter->new(
        flattened_dt => $hdl_generator,
    );

    my $prefix = $scaffold_emitter->generate_header($fsm_module)
        . $scaffold_emitter->generate_module_declaration($fsm_module)
        . $scaffold_emitter->generate_state_encoding($fsm_module)
        . $scaffold_emitter->generate_state_register($fsm_module);
    my $internal_block = $declaration_emitter->generate_internal_signal_declarations($fsm_module);

    return (normalize_dates($prefix . $internal_block), $internal_block);
}

sub normalize_dates {
    my ($text) = @_;
    $text //= '';
    $text =~ s{// Date: .*}{// Date: <normalized>}g;
    return $text;
}

sub write_file {
    my ($path, $content) = @_;
    open my $fh, '>', $path or die "Cannot open $path for write: $!";
    print {$fh} $content or die "Cannot write $path: $!";
    close $fh or die "Cannot close $path: $!";
}
