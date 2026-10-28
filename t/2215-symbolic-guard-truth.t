use strict;
use warnings;
use lib 'perl';
use Test::More;
use Lispish;
use FSM::Adapter::FSMGenFull;
use FSM::HDL::FlattenedDT;
use FSM::AST::Node;
use JSON::PP;

sub fixture {
    my ($width, $kind, $language) = @_;
    my $size = $kind eq 'fixed' ? "$width" : '(param W)';
    my $guard = $kind eq 'bare' ? 'A' : $kind eq 'equals_one' ? '(== A 1)'
        : $kind eq 'equals_zero' ? '(== A 0)' : '(& A B)';
    my $source = "(?fsm:generic_truth (+params (W $width)) "
        . "(+size (A $size) (B $size) (DATA 1) (OTHER 1)) "
        . "(idle (<$guard (= (DATA 1)) (= (OTHER 1))) (-> idle)))";
    my $adapter = FSM::Adapter::FSMGenFull->new;
    my $module = $adapter->parse_fsm(scalar Lispish::multi(\$source));
    if ($kind eq 'factorized') {
        my %signals = map {$_ => $adapter->{signal_manager}->get_signal($_)} qw(A B DATA OTHER);
        my $condition = FSM::CoreAST::BinaryOp->new('&',
            map {FSM::CoreAST::SignalRef->new($signals{$_})} qw(A B));
        my @actions = map {FSM::CoreAST::Assignment->new(
            target => FSM::CoreAST::SignalRef->new($signals{$_}),
            source => FSM::CoreAST::Literal->new('1'))} qw(DATA OTHER);
        my $branch = FSM::CoreAST::ConditionalBranch->new(condition => $condition,
            branches => [{condition => $condition, actions => \@actions}]);
        my $tree = FSM::CoreAST::DecisionTree->new(name => 'idle', elements => [$branch,
            FSM::CoreAST::StateTransitionFSM->new(target_state => 'idle')]);
        $module = FSM::CoreAST::FSMModule->new(name => $module->name, signals => \%signals,
            states => [FSM::CoreAST::State->new(name => 'idle', decision_trees => [$tree])],
            parameters => $module->parameters,
            _parameter_default_sources => $module->parameter_default_sources,
            _parameter_default_bindings => $module->parameter_default_bindings);
    }
    my $ctx = FSM::HDL::FlattenedDT->new;
    my $tail = 'FSM::HDL::FlattenedDT::Backend::SystemVerilog::GenerationTailSupport';
    my $generate = $tail->can('generate_systemverilog_tail');
    my %rendered;
    my $hdl;
    {
        no warnings 'redefine';
        no strict 'refs';
        local *{"${tail}::generate_systemverilog_tail"} = sub {
            my $support = $ctx->{enable_graph_ast_support};
            my $json = JSON::PP->new->canonical;
            my @fields = qw(direct_declared_width_emitted_ports direct_declared_width_emitted_signals direct_declared_width_emitted_binary_ranges);
            my $before = $json->encode([@{$ctx}{@fields}]);
            my ($helper) = keys %{$ctx->{direct_declared_width_emitted_binary_ranges}};
            for my $name ('A', defined($helper) ? $helper : ()) {
                for my $case (['==', 0], ['!=', 0], ['==', 1]) {
                    my ($op, $value) = @$case;
                    my $ast = FSM::AST::BinaryOp->new($op,
                        FSM::AST::SignalRef->new($name), FSM::AST::Literal->new("$value"));
                    $rendered{$name}{$op.$value} = $support->ast_to_systemverilog($ast);
                }
            }
            my $bit = FSM::CoreAST::SignalRef->new($module->signals->{A}, slice => [0, 0]);
            $rendered{bit} = $support->_operand_is_single_bit($bit);
            $support->_signal_is_single_bit('UNDECLARED_PROBE');
            $rendered{maps_unchanged} = $before eq $json->encode([@{$ctx}{@fields}]);
            return $generate->(@_);
        };
        $hdl = $language eq 'verilog' ? $ctx->generate_verilog($module) : $ctx->generate_systemverilog($module);
    }
    my ($gate) = $hdl =~ /^  assign idle_data_1_en = (.*?);/m;
    return ($hdl, $gate, \%rendered);
}

subtest 'symbolic source and factorizer guards preserve whole-value truth at default one' => sub {
    for my $kind ('source', 'factorized', 'bare') {
        for my $width (1, 8) {
            my ($hdl, $gate, $rendered) = fixture($width, $kind, $width == 1 ? 'verilog' : 'systemverilog');
            if ($kind eq 'bare') {
                is($gate, 'idle_en & (|A)', "bare default $width reduces the whole predicate before scalar gating");
            } else {
                like($gate, qr/^idle_en && /, "$kind default $width uses whole-value logical gating");
            }
            for my $name (grep {ref($rendered->{$_}) eq 'HASH'} keys %$rendered) {
                is($rendered->{$name}{'==0'}, "(~|$name)", 'zero test folds the whole symbolic vector');
                is($rendered->{$name}{'!=0'}, "(|$name)", 'nonzero test folds the whole symbolic vector');
                is($rendered->{$name}{'==1'}, "$name == 1", 'equals-one retains exact equality');
            }
            is($rendered->{bit}, 1, 'explicit one-bit slice remains scalar');
            ok($rendered->{maps_unchanged}, 'classification leaves all emitted identity maps unchanged');
        }
    }
};
subtest 'authored symbolic comparisons retain whole-value meaning at default one' => sub {
    my (undef, $one) = fixture(1, 'equals_one', 'systemverilog');
    is($one, 'idle_en & (A == 1)', 'authored equals-one remains an exact vector comparison');
    my (undef, $zero) = fixture(1, 'equals_zero', 'systemverilog');
    is($zero, 'idle_en & (~|A)', 'authored zero comparison reduces the entire vector');
};
subtest 'fixed one-bit guards retain compact operators and truth forms' => sub {
    my ($hdl, $gate, $rendered) = fixture(1, 'fixed', 'systemverilog');
    like($gate, qr/^idle_en & /, 'fixed scalar gating stays bitwise');
    is($rendered->{A}{'==0'}, '!A', 'fixed scalar zero test stays compact');
    is($rendered->{A}{'!=0'}, 'A', 'fixed scalar nonzero test stays compact');
    is($rendered->{A}{'==1'}, 'A', 'fixed scalar equals-one test stays compact');
};
subtest 'independent high-bit counterexample distinguishes logical truth from one-bit truncation' => sub {
    my $vector = 128;
    my $old_result = (1 & $vector) & 1;
    my $expected = $vector != 0 ? 1 : 0;
    is($old_result, 0, 'bitwise gate drops a high-bit-only true predicate');
    is($expected, 1, 'whole-vector predicate remains true');
    isnt($old_result, $expected, 'counterexample separates selected-default scalar and generic truth');
};
done_testing();
