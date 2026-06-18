#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Scalar::Util qw(blessed);
use File::Spec;
use File::Temp qw(tempdir);
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::CoreAST;
use FSM::HDL::FlattenedDT;
use FSM::Pipeline::SourceFrontend;

subtest 'enable-graph capture support rebuilds AST capture, condition conversion, and test-selector handling from a prepared backend context' => sub {
    my $fsm_module = parse_fsm_module(
        'enable_graph_capture_support_contract',
        <<'FSM'
(?fsm:enable_graph_capture_support_contract
  (+system
    (clock clk)
    (sreset rstn)
  )
  (+size
    (A 1)
    (OUT1 1)
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
)
FSM
    );

    my $prepared_backend = prepare_flattened_backend($fsm_module);
    my $support = $prepared_backend->{enable_graph_capture_support};

    my ($idle_state) = grep { $_->name eq 'idle' } @{$fsm_module->states};
    ok($idle_state, 'fixture FSM exposes the idle state');

    my $decision_tree = $idle_state->decision_trees->[0];
    my $conditional = $decision_tree->elements->[0];
    my $branch = $conditional->branches->[0];
    my $assignment = $branch->{actions}[0];
    my $transition = $branch->{actions}[1];

    my $condition_ast = $support->convert_condition_to_ast($branch->{condition});
    ok(blessed($condition_ast), 'capture support converts branch conditions into AST nodes');
    is($condition_ast->to_systemverilog, "A != 1'b0", 'capture support preserves the current truthy-branch condition AST contract');

    my $stack_condition_ast = $support->create_condition_expression([$condition_ast]);
    ok(blessed($stack_condition_ast), 'capture support keeps a single-condition stack as a typed AST node');
    is($stack_condition_ast->to_systemverilog, "A != 1'b0", 'capture support keeps single-condition stack semantics stable');

    my ($selector_op, $selector_value) = $support->parse_test_value_selector("!=8'0");
    is($selector_op, '!=', 'capture support parses explicit test selector operators');
    is($selector_value, "8'0", 'capture support preserves explicit test selector values');

    my $test_value_ast = $support->convert_test_value_to_ast('0');
    ok(blessed($test_value_ast), 'capture support converts selector values into literal AST nodes');
    is($test_value_ast->to_systemverilog, "1'b0", 'capture support keeps zero selectors as 1-bit zero literals');

    my $test_condition_ast = $support->build_test_condition_ast('A', '=0');
    ok(blessed($test_condition_ast), 'capture support builds typed AST conditions for test-node selectors');
    is($test_condition_ast->to_systemverilog, "A == 1'b0", 'capture support keeps explicit test-node equality semantics stable');

    ok($support->is_default_test_selector('default'), 'capture support recognizes the canonical default test selector');
    ok($support->is_default_test_selector('_'), 'capture support recognizes the wildcard default test selector');

    my $default_condition_ast = $support->build_default_test_condition_ast(
        'A',
        [
            { value => '=0', actions => [] },
            { value => '=1', actions => [] },
            { value => 'default', actions => [] },
        ],
    );
    ok(blessed($default_condition_ast), 'capture support builds typed AST conditions for default test-node selectors');
    is(
        $default_condition_ast->to_systemverilog,
        "!(A == 1'b0 || A == 1'b1)",
        'default test-node selector negates the OR of sibling explicit predicates',
    );

    is(
        $support->extract_signal_name_from_ast($assignment->target),
        'OUT1',
        'capture support extracts stable signal names from assignment targets',
    );

    my $rhs_capture_value = $support->extract_rhs_capture_value($assignment->source);
    like(
        $rhs_capture_value,
        qr/^(?:1|1'b1)$/,
        'capture support renders assignment RHS values into stable capture metadata',
    );

    my $bus_signal = FSM::CoreAST::Signal->new(name => 'BUS', width => 8);
    my $bus_ref = sub { FSM::CoreAST::SignalRef->new($bus_signal) };
    is(
        $support->extract_rhs_capture_value(
            FSM::CoreAST::BinaryOp->new(
                '&',
                $bus_ref->(),
                FSM::CoreAST::Literal->new('11111111', width => 8, radix => 'binary'),
            ),
        ),
        'BUS',
        'capture support renders captured vector RHS values through the shared AST simplifier',
    );
    is(
        $support->extract_rhs_capture_value(
            FSM::CoreAST::BinaryOp->new(
                '&',
                $bus_ref->(),
                FSM::CoreAST::Literal->new('1', width => 1, radix => 'binary'),
            ),
        ),
        "BUS & 1'b1",
        'capture support preserves captured vector RHS masks when simplification would change width semantics',
    );

    my $capture_metadata = $support->extract_assignment_capture_metadata($assignment);
    is($capture_metadata->{operator}, '<=', 'capture support keeps assignment operators in normalized capture metadata');

    $support->capture_assignment_from_ast('idle', $assignment, [$condition_ast]);
    ok(
        exists $prepared_backend->{lhs_assignments}{OUT1},
        'capture support records captured assignments in the prepared LHS registry',
    );
    is(
        $prepared_backend->{lhs_assignments}{OUT1}[0]{conditions_ast}->to_systemverilog,
        "A != 1'b0",
        'capture support keeps captured assignment conditions as typed AST nodes',
    );
    is(
        $prepared_backend->{lhs_assignments}{OUT1}[0]{operator},
        '<=',
        'capture support keeps captured assignment operators stable',
    );
    ok(
        exists $prepared_backend->{all_lhs}{OUT1},
        'capture support keeps the all_lhs registry in sync with captured assignments',
    );

    $support->capture_transition_from_ast('idle', $transition, [$condition_ast]);
    ok(
        exists $prepared_backend->{lhs_assignments}{next_state},
        'capture support records transitions through the normalized next_state registry',
    );
    is(
        $prepared_backend->{lhs_assignments}{next_state}[0]{rhs},
        'DONE',
        'capture support normalizes transition targets into uppercased next_state values',
    );
    is(
        $prepared_backend->{lhs_assignments}{next_state}[0]{conditions_ast}->to_systemverilog,
        "A != 1'b0",
        'capture support keeps transition guards as typed AST nodes',
    );
    ok(
        $prepared_backend->{lhs_ast_map}{next_state}->can('is_fsm_state_next')
            && $prepared_backend->{lhs_ast_map}{next_state}->is_fsm_state_next,
        'capture support marks next_state as the dedicated FSM next-state signal',
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

sub write_file {
    my ($path, $content) = @_;
    open my $fh, '>', $path or die "Cannot open $path for write: $!";
    print {$fh} $content or die "Cannot write $path: $!";
    close $fh or die "Cannot close $path: $!";
}
