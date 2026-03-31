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

subtest 'decision-tree flattening support owns recursive flattening and unified assignment-analysis handoff' => sub {
    my $fsm_module = parse_fsm_module(
        'decision_tree_flattening_support_contract',
        <<'FSM'
(?fsm:decision_tree_flattening_support_contract
  (+system
    (clock clk)
    (sreset rstn)
  )
  (+size
    (A 1)
    (B 1)
    (OUT1 1)
    (OUT2 1)
  )
  (idle
    (<A
      (OUT1 <= 1)
      (-> done)
    )
  )
  (done
    (OUT1 <= 0)
  )
  (-helper
    (?B
      (=0 (OUT2 = 0))
      (=1 (OUT2 = 1))
    )
  )
)
FSM
    );

    my $expected_backend = prepare_flattened_backend($fsm_module);
    my $actual_backend = prepare_flattened_backend($fsm_module);

    $expected_backend->{orchestrator}->flatten_all_decision_trees($fsm_module);
    $actual_backend->{decision_tree_flattening_support}->flatten_all_decision_trees($fsm_module);

    is_deeply(
        normalize_flattened_state($actual_backend),
        normalize_flattened_state($expected_backend),
        'decision-tree flattening support rebuilds the same prepared flattening state as the orchestrator wrapper',
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
    return $hdl_generator;
}

sub normalize_flattened_state {
    my ($backend) = @_;

    return {
        state_enables => normalize_ast_map($backend->{state_enables}),
        dt_enables => normalize_ast_map($backend->{dt_enables}),
        lhs_assignments => normalize_lhs_assignments($backend->{lhs_assignments}),
        all_lhs => [sort keys %{$backend->{all_lhs} || {}}],
        assignment_analysis => normalize_assignment_analysis($backend->{assignment_analysis}),
    };
}

sub normalize_ast_map {
    my ($map) = @_;
    my %normalized;
    for my $key (sort keys %{$map || {}}) {
        my $value = $map->{$key};
        $normalized{$key} = (ref($value) && $value->can('to_systemverilog'))
            ? $value->to_systemverilog
            : $value;
    }
    return \%normalized;
}

sub normalize_lhs_assignments {
    my ($lhs_assignments) = @_;
    my %normalized;
    for my $lhs (sort keys %{$lhs_assignments || {}}) {
        $normalized{$lhs} = [
            map {
                {
                    dt => $_->{dt},
                    conditions_ast => (ref($_->{conditions_ast}) && $_->{conditions_ast}->can('to_systemverilog'))
                        ? $_->{conditions_ast}->to_systemverilog
                        : $_->{conditions_ast},
                    rhs => $_->{rhs},
                    operator => $_->{operator},
                    is_state_trans => $_->{is_state_trans} ? 1 : 0,
                }
            } @{$lhs_assignments->{$lhs} || []}
        ];
    }
    return \%normalized;
}

sub normalize_assignment_analysis {
    my ($assignment_analysis) = @_;
    my %normalized;
    for my $lhs (sort keys %{$assignment_analysis || {}}) {
        my $entry = $assignment_analysis->{$lhs} || {};
        $normalized{$lhs} = {
            rhs_groups => [sort keys %{$entry->{rhs_groups} || {}}],
            multiplexer_type => $entry->{multiplexer}{type},
            is_flop => $entry->{signal_info}{is_flop} ? 1 : 0,
        };
    }
    return \%normalized;
}

sub write_file {
    my ($path, $content) = @_;
    open my $fh, '>', $path or die "Cannot open $path for write: $!";
    print {$fh} $content or die "Cannot write $path: $!";
    close $fh or die "Cannot close $path: $!";
}
