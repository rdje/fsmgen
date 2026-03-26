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
use FSM::HDL::FlattenedDT::Backend::SystemVerilog::ConsolidatedIntermediateEmitter;
use FSM::HDL::FlattenedDT::Backend::SystemVerilog::InternalDeclarationEmitter;
use FSM::HDL::FlattenedDT::Backend::SystemVerilog::ScaffoldEmitter;
use FSM::Pipeline::SourceFrontend;

subtest 'consolidated intermediate emitter rebuilds the direct backend prefix through the consolidated wire block' => sub {
    my $fsm_module = parse_fsm_module(
        'sv_consolidated_contract',
        <<'FSM'
(?fsm:sv_consolidated_contract
  (+system
    (clock clk)
    (sreset rstn)
  )
  (+size
    (A 1)
    (B 1)
    (C 1)
    (D 1)
    (OUT1 1)
    (OUT2 1)
  )
  (idle
    (<(| A B)
      (OUT1 <= C)
    )
    (<(| A B)
      (OUT2 <= D)
    )
  )
)
FSM
    );

    my $prepared_backend = prepare_flattened_backend($fsm_module);
    my ($prefix, $consolidated_block) = rebuild_prefix_with_consolidated_intermediates($prepared_backend, $fsm_module);
    my $backend_result = FSM::Backend::GeneratedModuleEmitter->emit_from_fsm_module(
        fsm_module => $fsm_module,
        target_language => 'systemverilog',
        debug_level => 0,
    );
    my $normalized_prefix = normalize_generated_prefix($prefix);
    my $normalized_hdl = normalize_generated_prefix($backend_result->{hdl_code});

    is(
        substr($normalized_hdl, 0, length($normalized_prefix)),
        $normalized_prefix,
        'consolidated intermediate emitter rebuilds the same direct backend prefix through the consolidated block',
    );
    like(
        $consolidated_block,
        qr{// Consolidated intermediate signals \(AST factorization \+ pre-scan\)},
        'consolidated block keeps the consolidated intermediate comment header',
    );
    like(
        $consolidated_block,
        qr/\bwire A_or_B;/,
        'consolidated block keeps the shared factorized wire declaration',
    );
    like(
        $consolidated_block,
        qr/\bassign A_or_B = A \| B; \/\/ Source: ast_factorization\b/,
        'consolidated block keeps the shared factorized assign',
    );
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
    $hdl_generator->{enable_graph}->set_fsm_module_reference($fsm_module);
    $hdl_generator->{orchestrator}->flatten_all_decision_trees($fsm_module);
    return $hdl_generator;
}

sub rebuild_prefix_with_consolidated_intermediates {
    my ($hdl_generator, $fsm_module) = @_;
    my $scaffold_emitter = FSM::HDL::FlattenedDT::Backend::SystemVerilog::ScaffoldEmitter->new(
        flattened_dt => $hdl_generator,
    );
    my $declaration_emitter = FSM::HDL::FlattenedDT::Backend::SystemVerilog::InternalDeclarationEmitter->new(
        flattened_dt => $hdl_generator,
    );
    my $consolidated_emitter = FSM::HDL::FlattenedDT::Backend::SystemVerilog::ConsolidatedIntermediateEmitter->new(
        flattened_dt => $hdl_generator,
    );

    my $prefix = $scaffold_emitter->generate_header($fsm_module)
        . $scaffold_emitter->generate_module_declaration($fsm_module)
        . $scaffold_emitter->generate_state_encoding($fsm_module)
        . $scaffold_emitter->generate_state_register($fsm_module)
        . $declaration_emitter->generate_internal_signal_declarations($fsm_module);

    $prefix .= $hdl_generator->{enable_graph}->generate_enable_conditions($fsm_module);
    $hdl_generator->{enable_graph}->count_binary_logical_operation_occurrences();
    $hdl_generator->{enable_graph}->prescan_wen_en_for_intermediate_signals();

    my $consolidated_block = $consolidated_emitter->generate_consolidated_intermediate_signals($fsm_module);

    return ($prefix . $consolidated_block, $consolidated_block);
}

sub normalize_generated_prefix {
    my ($text) = @_;
    $text //= '';
    $text =~ s{// Date: .*}{// Date: <normalized>}g;
    $text =~ s{
        (//\s+Consolidated\ intermediate\ signals.*?\n)
        (.*?)
        (\n\s*//\s+Unified\ WEN/EN\ Signal\ Generation\ from\ Phase\ 1\ Analysis|\z)
    }{
        my ($header, $body, $footer) = ($1, $2, $3);
        my @body_lines = grep { length($_) } split /\n/, $body;
        $header . join("\n", sort @body_lines) . $footer;
    }gsex;
    return $text;
}

sub write_file {
    my ($path, $content) = @_;
    open my $fh, '>', $path or die "Cannot open $path for write: $!";
    print {$fh} $content or die "Cannot write $path: $!";
    close $fh or die "Cannot close $path: $!";
}
