use strict;
use warnings;
use lib 'perl';
use Test::More;
use JSON::PP;
use Lispish;
use FSM::Adapter::FSMGenFull;
use FSM::HDL::FlattenedDT;
use FSM::DirectDeclaredWidthSupport;
use FSM::IntermediateWidthGraphPolicySupport;
use FSM::Backend::VerilogFamily::DeclarationCapture;
my $class = 'FSM::DirectDeclaredWidthSupport';
my $json = JSON::PP->new->canonical;
sub fixture {
    my ($expression, $width, @sizes) = @_;
    @sizes = ('(param W)') x 3 unless @sizes;
    my $source = "(?fsm:graph_ranges (+params (W $width) (COPY W))"
        . " (+size (A $sizes[0]) (B $sizes[1]) (C $sizes[2]) (DATA 1) (OTHER 1))"
        . " (idle (<$expression (= (DATA 1)) (= (OTHER 1))) (-> idle)))";
    my $module = FSM::Adapter::FSMGenFull->new->parse_fsm(scalar Lispish::multi(\$source));
    my $ctx = FSM::HDL::FlattenedDT->new;
    my $capture = FSM::Backend::VerilogFamily::DeclarationCapture->new;
    my $collect = FSM::HDL::FlattenedDT::Backend::SystemVerilog::ConsolidatedIntermediateSupport
        ->can('collect_consolidated_intermediate_signals');
    my ($all, $hdl, %policies);
    {
        no warnings 'redefine';
        local *FSM::HDL::FlattenedDT::Backend::SystemVerilog::ConsolidatedIntermediateSupport::collect_consolidated_intermediate_signals = sub {
            $all = $collect->(@_);
            for my $name (sort keys %$all) {
                my $p = $ctx->{backend_sv_intermediate_width_support}->factorized_graph_width_allocation($name, $all->{$name});
                $policies{$name} = $p if $p;
            }
            return $all;
        };
        local $ctx->{declared_width_declaration_capture} = $capture;
        $hdl = $ctx->generate_systemverilog($module);
    }
    my ($name) = sort {
        @{FSM::IntermediateWidthGraphPolicySupport->leaf_names($policies{$b})}
            <=> @{FSM::IntermediateWidthGraphPolicySupport->leaf_names($policies{$a})} || $a cmp $b
    } keys %policies;
    die "fixture requires current graph policy for $expression at $width with @sizes\n" unless defined($name);
    return {flattened_dt => $ctx, signal_name => $name, signal_info => $all->{$name}, all => $all,
        target_language => 'systemverilog', hdl => $hdl, %{$capture->snapshot}};
}
sub declaration {
    my ($in, %override) = @_;
    return $class->prepare_arithmetic_graph_declaration(flattened_dt => $in->{flattened_dt},
        signal_name => $in->{signal_name}, signal_info => $in->{signal_info}, target_language => 'systemverilog',
        expression => $in->{target_intermediates}{$in->{signal_name}}{expression}, %override);
}
sub completed_root {
    my ($in) = @_;
    my $plan = $class->prepare_arithmetic_graph_intermediate_range(%$in);
    delete @{$plan}{qw(nodes node_order)};
    return $plan;
}
subtest 'source declaration intent agrees with independently completed actual graph root proof' => sub {
    for my $case (['(+ A B C)', 1], ['(+ A (* B C))', 8], ['(+ (+ A B) (+ A B))', 1]) {
        my $in = fixture(@$case);
        my $plan = declaration($in);
        is_deeply($plan, completed_root($in), 'every source declaration field matches independent complete target root proof');
        is($plan->{width_plan}{is_vector}, 1, 'default-one source intent retains vector rank');
        is_deeply($plan->{leaf_names}, FSM::IntermediateWidthGraphPolicySupport->leaf_names($plan->{graph_width_allocation}),
            'ordered original leaf slots and duplicates preserve');
        ok(!exists($plan->{nodes}) && !exists($plan->{node_order}), 'source declaration intent makes no transitive target event assertion');
        $plan->{expression_tree}[0] = 'WRONG';
        $plan->{width_plan}{width_contract}{expression}[1] = 'WRONG';
        is_deeply(declaration($in), completed_root($in), 'returned graph intent deeply detaches');
        my $name = $in->{signal_name};
        like($in->{hdl}, qr/^  wire \[\(W - 1\):0\] \Q$name\E;$/m,
            'actual live parent emission consumes the canonical graph declaration intent');
    }
    my $fixed = fixture('(+ A (* B C))', 8, '8', '4', '2');
    my $plan = declaration($fixed);
    is_deeply($plan, completed_root($fixed), 'fixed source intent preserves independent child/root widths');
    is($plan->{profile}, 'fixed', 'fixed graph creates no mutable declaration range');
    is($plan->{width_plan}, undef, 'fixed source intent contains no symbolic plan');
};
subtest 'copied foreign stale text and independent source relationships cannot mint declaration intent' => sub {
    my $in = fixture('(+ A (* B C))', 8);
    for my $override (
        {signal_info => {%{$in->{signal_info}}}}, {signal_name => 'FOREIGN'},
        {expression => 'A + B'}, {target_language => 'vhdl'},
        {flattened_dt => FSM::HDL::FlattenedDT->new},
    ) {
        ok(!eval {declaration($in, %$override); 1}, 'copied or incoherent source selection refuses');
    }
    ok(!eval {my $independent = fixture('(+ A B C)', 8, '(param W)', '(param W)', '(param COPY)');
        declaration($independent); 1}, 'equal-default independent original root refuses during emission or source intent');
    like($@, qr/identical mutable operand contracts/, 'refusal retains the actual frozen source contract');
    $in->{signal_info}{width} = 32;
    ok(!eval {declaration($in); 1}, 'independent result floor cannot borrow current graph intent');
};
subtest 'late complete source and supported dependency writes invalidate declaration intent' => sub {
    my $relationship = $class->can('prepare_graph_operand_relationship');
    for my $change (
        sub {my $ctx = $_[0]{flattened_dt}; $ctx->{assignment_analysis}{DATA}{lhs_ast}->signal->{constraints} = ['late constraint']},
        sub {my $a = $_[0]{flattened_dt}{fsm_module}->signals->{A}; $a->set_attribute('width_declared', $a->get_attribute('width_declared'))},
        sub {$_[0]{signal_info}{state_model} = 'late independent state profile'},
    ) {
        my $in = fixture('(+ A (* B C))', 8);
        my ($changed, $result, $error);
        {
            no warnings 'redefine';
            local *FSM::DirectDeclaredWidthSupport::prepare_graph_operand_relationship = sub {
                my $plan = $relationship->(@_);
                $change->($in) unless $changed++;
                return $plan;
            };
            $result = eval {declaration($in)}; $error = $@;
        }
        ok($changed, 'actual frozen source relationship preceded the controlled write');
        ok(!$result && length($error), 'source declaration intent withholds after complete source or dependency change');
    }
};
done_testing();
