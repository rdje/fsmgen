#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use File::Temp qw(tempdir);
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::HDL::FlattenedDT;
use FSM::HDL::FlattenedDT::Backend::SystemVerilog::ConsolidatedIntermediateGenerationSupport;
use FSM::HDL::FlattenedDT::Backend::SystemVerilog::ConsolidatedIntermediateStageSupport;
use FSM::Pipeline::SourceFrontend;

{
    package Local::SpyStageSupport;
    use v5.20;
    use strict;
    use warnings;
    use feature qw(signatures);
    no warnings 'experimental::signatures';

    sub new ($class) {
        return bless { calls => [] }, $class;
    }

    sub calls ($self) {
        return $self->{calls};
    }

    sub generate_consolidated_intermediate_block ($self, $fsm_module) {
        push @{$self->{calls}}, $fsm_module;
        return "stage-generated:$fsm_module->{name}";
    }
}

subtest 'consolidated intermediate generation support requires only the live stage-generation owner' => sub {
    my $fsm_module = { name => 'generation_shell_contract' };
    my $stage_support = Local::SpyStageSupport->new();
    my $generation_support = FSM::HDL::FlattenedDT::Backend::SystemVerilog::ConsolidatedIntermediateGenerationSupport->new(
        flattened_dt => {
            backend_sv_consolidated_intermediate_stage_support => $stage_support,
        },
    );

    my $generated_block = $generation_support->generate_consolidated_intermediate_block($fsm_module);

    is(
        $generated_block,
        'stage-generated:generation_shell_contract',
        'generation shell delegates directly to the stage-generation owner',
    );
    is(
        scalar(@{$stage_support->calls}),
        1,
        'generation shell calls the stage-generation owner exactly once',
    );
    is(
        $stage_support->calls->[0],
        $fsm_module,
        'generation shell passes the FSM module through unchanged',
    );
};

subtest 'consolidated intermediate generation support remains a compatibility wrapper over the live stage-generation owner' => sub {
    my $fsm_module = parse_fsm_module(
        'sv_consolidated_generation_support_contract',
        <<'FSM'
(?fsm:sv_consolidated_generation_support_contract
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
    my $generation_support = FSM::HDL::FlattenedDT::Backend::SystemVerilog::ConsolidatedIntermediateGenerationSupport->new(
        flattened_dt => $prepared_backend,
    );
    my $stage_support = FSM::HDL::FlattenedDT::Backend::SystemVerilog::ConsolidatedIntermediateStageSupport->new(
        flattened_dt => $prepared_backend,
    );

    my $expected_block = $stage_support->generate_consolidated_intermediate_block($fsm_module);
    my $generated_block = $generation_support->generate_consolidated_intermediate_block($fsm_module);

    is(
        $generated_block,
        $expected_block,
        'generation support compatibility wrapper rebuilds the same full consolidated block as the live stage-generation owner',
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
