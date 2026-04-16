#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use File::Temp qw(tempdir);
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::HDL::FlattenedDT;
use FSM::HDL::FlattenedDT::Backend::SystemVerilog::PostFlatteningAssemblySupport;
use FSM::Pipeline::SourceFrontend;

{
    package Local::SequenceStageSupport;
    use v5.20;
    use feature qw(signatures);
    no warnings 'experimental::signatures';
    sub new ($class, $events) { bless { events => $events }, $class }
    sub generate_consolidated_intermediate_block ($self, $fsm_module) {
        push @{$self->{events}}, 'stage';
        return "STAGE\n";
    }
}

{
    package Local::SequenceScaffold;
    use v5.20;
    use feature qw(signatures);
    no warnings 'experimental::signatures';
    sub new ($class, $events) { bless { events => $events }, $class }
    sub generate_header ($self, $fsm_module) {
        push @{$self->{events}}, 'header';
        return "HEADER\n";
    }
    sub generate_module_declaration ($self, $fsm_module) {
        push @{$self->{events}}, 'module_declaration';
        return "MODULE_DECLARATION\n";
    }
    sub generate_state_encoding ($self, $fsm_module) {
        push @{$self->{events}}, 'state_encoding';
        return "STATE_ENCODING\n";
    }
    sub generate_state_register ($self, $fsm_module) {
        push @{$self->{events}}, 'state_register';
        return "STATE_REGISTER\n";
    }
}

{
    package Local::SequenceInternalDecl;
    use v5.20;
    use feature qw(signatures);
    no warnings 'experimental::signatures';
    sub new ($class, $events) { bless { events => $events }, $class }
    sub generate_internal_signal_declarations ($self, $fsm_module) {
        my $stage_seen = grep { $_ eq 'stage' } @{$self->{events}};
        push @{$self->{events}}, 'internal_declarations';
        return $stage_seen ? "DECLARATIONS_STAGE_READY\n" : "DECLARATIONS_STAGE_MISSING\n";
    }
}

{
    package Local::SequenceEnableSupport;
    use v5.20;
    use feature qw(signatures);
    no warnings 'experimental::signatures';
    sub new ($class, $events) { bless { events => $events }, $class }
    sub generate_enable_conditions ($self, $fsm_module) {
        push @{$self->{events}}, 'enable_conditions';
        return "ENABLES\n";
    }
}

{
    package Local::SequenceTailSupport;
    use v5.20;
    use feature qw(signatures);
    no warnings 'experimental::signatures';
    sub new ($class, $events) { bless { events => $events }, $class }
    sub generate_systemverilog_tail ($self, $fsm_module) {
        push @{$self->{events}}, 'tail';
        return "TAIL\n";
    }
}

subtest 'post-flattening assembly support owns the live scaffold/declaration/enable/stage/tail sequence' => sub {
    my $fsm_module = parse_fsm_module(
        'sv_post_flattening_assembly_support_contract',
        <<'FSM'
(?fsm:sv_post_flattening_assembly_support_contract
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
    my $assembly_support = FSM::HDL::FlattenedDT::Backend::SystemVerilog::PostFlatteningAssemblySupport->new(
        flattened_dt => $prepared_backend,
    );

    my $expected_hdl = build_expected_hdl($prepared_backend, $fsm_module);
    my $generated_hdl = $assembly_support->generate_systemverilog_module($fsm_module);

    normalize_generated_date(\$expected_hdl);
    normalize_generated_date(\$generated_hdl);

    is(
        $generated_hdl,
        $expected_hdl,
        'post-flattening assembly support rebuilds the same HDL sequence as the lower-level live owners',
    );
};

subtest 'orchestrator delegates post-flattening module assembly to the live assembly owner' => sub {
    my $fsm_module = parse_fsm_module(
        'sv_orchestrator_post_flattening_assembly_contract',
        <<'FSM'
(?fsm:sv_orchestrator_post_flattening_assembly_contract
  (+system
    (clock clk)
    (sreset rstn)
  )
  (+size
    (REQ 1)
    (ACK 1)
    (DONE 1)
  )
  (idle
    (<REQ
      (DONE <= ACK)
    )
  )
)
FSM
    );

    my $expected_backend = prepare_flattened_backend($fsm_module);
    my $expected_hdl = $expected_backend->{backend_sv_post_flattening_assembly_support}
        ->generate_systemverilog_module($fsm_module);

    my $actual_backend = FSM::HDL::FlattenedDT->new(debug => 0);
    my $generated_hdl = $actual_backend->{orchestrator}->generate_systemverilog($fsm_module);

    normalize_generated_date(\$expected_hdl);
    normalize_generated_date(\$generated_hdl);

    is(
        $generated_hdl,
        $expected_hdl,
        'orchestrator output matches the post-flattening assembly owner after reset/module attachment/flattening',
    );
};

subtest 'post-flattening assembly prepares consolidated stage before declarations' => sub {
    my @events;
    my $ctx = {
        backend_sv_consolidated_intermediate_stage_support => Local::SequenceStageSupport->new(\@events),
        backend_sv_scaffold                              => Local::SequenceScaffold->new(\@events),
        backend_sv_internal_decl                         => Local::SequenceInternalDecl->new(\@events),
        enable_graph_enable_support                      => Local::SequenceEnableSupport->new(\@events),
        backend_sv_generation_tail_support               => Local::SequenceTailSupport->new(\@events),
    };
    my $assembly_support = FSM::HDL::FlattenedDT::Backend::SystemVerilog::PostFlatteningAssemblySupport->new(
        flattened_dt => $ctx,
    );

    my $hdl = $assembly_support->generate_systemverilog_module(bless({}, 'Local::FakeFSMModule'));

    is_deeply(
        \@events,
        [
            'stage',
            'header',
            'module_declaration',
            'state_encoding',
            'state_register',
            'internal_declarations',
            'enable_conditions',
            'tail',
        ],
        'stage preparation runs before declaration emission even though the stage text is emitted later',
    );
    like(
        $hdl,
        qr/DECLARATIONS_STAGE_READY.*ENABLES\nSTAGE\nTAIL/s,
        'assembly emits declarations before stage HDL while still making stage-discovered helpers visible to declarations',
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
    return $hdl_generator;
}

sub build_expected_hdl {
    my ($prepared_backend, $fsm_module) = @_;

    my $consolidated_intermediate_hdl = $prepared_backend->{backend_sv_consolidated_intermediate_stage_support}
        ->generate_consolidated_intermediate_block($fsm_module);
    my $hdl = $prepared_backend->{backend_sv_scaffold}->generate_header($fsm_module);
    $hdl .= $prepared_backend->{backend_sv_scaffold}->generate_module_declaration($fsm_module);
    $hdl .= $prepared_backend->{backend_sv_scaffold}->generate_state_encoding($fsm_module);
    $hdl .= $prepared_backend->{backend_sv_scaffold}->generate_state_register($fsm_module);
    $hdl .= $prepared_backend->{backend_sv_internal_decl}->generate_internal_signal_declarations($fsm_module);
    $hdl .= $prepared_backend->{enable_graph_enable_support}
        ->generate_enable_conditions($fsm_module);
    $hdl .= $consolidated_intermediate_hdl;
    $hdl .= $prepared_backend->{backend_sv_generation_tail_support}
        ->generate_systemverilog_tail($fsm_module);

    return $hdl;
}

sub write_file {
    my ($path, $content) = @_;
    open my $fh, '>', $path or die "Cannot open $path for write: $!";
    print {$fh} $content or die "Cannot write $path: $!";
    close $fh or die "Cannot close $path: $!";
}

sub normalize_generated_date {
    my ($text_ref) = @_;
    return unless defined $text_ref && ref($text_ref) eq 'SCALAR';
    $$text_ref =~ s{// Date: .*}{// Date: <normalized>}g;
}
