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
use FSM::HDL::FlattenedDT::Backend::SystemVerilog::ScaffoldEmitter;
use FSM::Pipeline::SourceFrontend;

subtest 'scaffold emitter rebuilds the regular-state direct backend prefix from a prepared backend context' => sub {
    my $fsm_module = parse_fsm_module(
        'sv_scaffold_regular_state',
        <<'FSM'
(?fsm:sv_scaffold_regular_state
  (+system
    (clock clk)
    (sreset rstn)
  )
  (+size
    (OUT 1)
    (IN 1)
  )
  (idle
    (OUT <= IN)
  )
)
FSM
    );

    my $prepared_backend = prepare_flattened_backend($fsm_module);
    my $scaffold = rebuild_scaffold_prefix($prepared_backend, $fsm_module);
    my $backend_result = FSM::Backend::GeneratedModuleEmitter->emit_from_fsm_module(
        fsm_module => $fsm_module,
        target_language => 'systemverilog',
        debug_level => 0,
    );
    my $normalized_scaffold = normalize_dates($scaffold);
    my $normalized_hdl = normalize_dates($backend_result->{hdl_code});

    is(
        substr($normalized_hdl, 0, length($normalized_scaffold)),
        $normalized_scaffold,
        'scaffold emitter rebuilds the same regular-state prefix as the direct backend output',
    );
    like($scaffold, qr/localparam\s+IDLE\s*=\s*1'd0;/, 'regular-state scaffold keeps the state encoding block');
    like($scaffold, qr/always_ff\s*@\(posedge clk or negedge rstn\)/, 'regular-state scaffold keeps the sequential state block');
};

subtest 'scaffold emitter rebuilds the standalone-dt direct backend prefix and keeps the no-state comment' => sub {
    my $fsm_module = parse_fsm_module(
        'sv_scaffold_dt_only',
        <<'FSM'
(?dt:sv_scaffold_dt_only
  (+size
    (SEL 1)
    (A 8)
    (B 8)
    (OUT 8)
  )
  (-from_a
    (<SEL==1'b0
      (OUT = A)
    )
  )
  (-from_b
    (<SEL==1'b1
      (OUT = B)
    )
  )
)
FSM
    );

    my $prepared_backend = prepare_flattened_backend($fsm_module);
    my $scaffold = rebuild_scaffold_prefix($prepared_backend, $fsm_module);
    my $backend_result = FSM::Backend::GeneratedModuleEmitter->emit_from_fsm_module(
        fsm_module => $fsm_module,
        target_language => 'systemverilog',
        debug_level => 0,
    );
    my $normalized_scaffold = normalize_dates($scaffold);
    my $normalized_hdl = normalize_dates($backend_result->{hdl_code});

    is(
        substr($normalized_hdl, 0, length($normalized_scaffold)),
        $normalized_scaffold,
        'scaffold emitter rebuilds the same standalone-dt prefix as the direct backend output',
    );
    like($scaffold, qr/No state registers needed/, 'standalone-dt scaffold keeps the no-state-register comment');
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

sub rebuild_scaffold_prefix {
    my ($hdl_generator, $fsm_module) = @_;
    my $emitter = FSM::HDL::FlattenedDT::Backend::SystemVerilog::ScaffoldEmitter->new(
        flattened_dt => $hdl_generator,
    );

    return normalize_dates(
        $emitter->generate_header($fsm_module)
        . $emitter->generate_module_declaration($fsm_module)
        . $emitter->generate_state_encoding($fsm_module)
        . $emitter->generate_state_register($fsm_module)
    );
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
