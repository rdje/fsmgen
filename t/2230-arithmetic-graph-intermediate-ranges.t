use strict;
use warnings;
use lib 'perl';
use Test::More;
use JSON::PP;
use POSIX ();
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
sub prepare {return $class->prepare_arithmetic_graph_intermediate_range(%{$_[0]})}
sub copy_inputs {
    my ($in) = @_;
    return {%$in, map {$_ => $json->decode($json->encode($in->{$_}))}
        qw(target_namespace target_declarations target_intermediates)};
}
sub caller_state {
    my ($in) = @_;
    my $m = $in->{flattened_dt}{fsm_module};
    return $json->encode([$in->{target_namespace}, $in->{target_declarations}, $in->{target_intermediates},
        $m->parameters, $m->parameter_default_sources, $m->parameter_default_bindings,
        {map {my $s = $m->signals->{$_}; $_ => [$s->width, $s->declared_width_source,
            $s->declared_width_binding, $s->declared_width_requirements]} sort keys %{$m->signals}}]);
}
subtest 'actual selected arithmetic DAG privately joins every child and frozen original leaf' => sub {
    for my $case (['(+ A B C)', 1], ['(+ A (* B C))', 8],
        ['(+ (+ A B C) (+ B C A))', 1], ['(+ (+ A B) (+ A B))', 8]) {
        my $in = fixture(@$case);
        my $before = caller_state($in);
        my $plan = eval {prepare($in)};
        ok($plan, 'actual selected graph has a canonical private source/target proof') or diag $@;
        next unless $plan;
        is($plan->{profile}, 'symbolic', 'all original leaves have the same frozen mutable contract');
        is_deeply($plan->{expression_tree}, $in->{target_intermediates}{$in->{signal_name}}{graph_width_allocation}{expression_tree}, 'expanded actual selected graph retains its original ordered tree');
        is_deeply($plan->{leaf_names}, FSM::IntermediateWidthGraphPolicySupport->leaf_names($plan->{graph_width_allocation}), 'original duplicate leaf vector retains');
        is($plan->{node_order}[-1], $in->{signal_name}, 'root follows actual selected children');
        is($plan->{width_plan}{is_vector}, 1, 'default-one frozen width retains vector rank');
        for my $name (@{$plan->{node_order}}) {
            my $node = $plan->{nodes}{$name};
            is($node->{target_name}, $name, 'actual child/result identity owns each plan');
            is($node->{width}, $in->{target_declarations}{$name}{width}, 'independent selected declaration width retains');
            is($node->{width_plan}{source_signal}, $node->{leaf_names}[0], 'child representative retains its own first original source');
            is_deeply($node->{arithmetic_origin}, $in->{target_intermediates}{$name}{arithmetic_origin}, 'every selected ordered operator/edge origin joins');
        }
        is(caller_state($in), $before, 'complete source and target caller records preserve kinds');
        $plan->{nodes}{$in->{signal_name}}{leaf_names}[0] = 'WRONG';
        $plan->{width_plan}{width_contract}{expression}[1] = 'WRONG';
        isnt(prepare($in)->{leaf_names}[0], 'WRONG', 'returned graph plan deeply detaches');
        my $verilog = copy_inputs($in); $verilog->{target_language} = 'verilog';
        is(prepare($verilog)->{target_language}, 'verilog', 'private join supports the same Verilog family');
    }
};
subtest 'numeric or printed child evidence incomplete targets and independent floors refuse' => sub {
    my $base = fixture('(+ A (* B C))', 8);
    my $child = $base->{target_intermediates}{$base->{signal_name}}{graph_width_allocation}{source_names}[1];
    for my $change (
        sub {delete $_[0]{target_intermediates}{$child}},
        sub {delete $_[0]{target_intermediates}{$child}{width_allocation}; $_[0]{target_intermediates}{$child}{range_text} = '[(W-1):0]'},
        sub {$_[0]{target_intermediates}{$child}{expression} = 'B + C'},
        sub {$_[0]{target_intermediates}{$child}{arithmetic_origin}{source_names} = ['C','B']},
        sub {$_[0]{target_declarations}{$child}{width} = 32},
        sub {$_[0]{target_declarations}{$_[0]{signal_name}}{width} = 32},
        sub {$_[0]{target_declarations}{$child}{state_model} = 'known'},
        sub {delete $_[0]{target_declarations}{C}},
        sub {$_[0]{target_intermediates}{A} = {expression => 'B + C'}},
        sub {$_[0]{target_namespace}{identifier_map}{$child} = 'FOREIGN'},
        sub {$_[0]{target_namespace}{signals} = []},
        sub {$_[0]{signal_info} = {%{$_[0]{signal_info}}}},
        sub {$_[0]{target_language} = 'vhdl'},
    ) {
        my $in = copy_inputs($base);
        $change->($in);
        ok(!eval {prepare($in); 1}, 'incomplete stale foreign typed or independently constrained target data refuses');
    }
    my $different = fixture('(+ A B C)', 8, '(param W)', '(param W)', '(param COPY)');
    ok(!eval {prepare($different); 1}, 'equal numeric graph defaults cannot hide a different frozen original root');
};
subtest 'fixed graph leaves keep independent widths and current identities remain mandatory' => sub {
    my $in = fixture('(+ A (* B C))', 8, '8', '4', '2');
    my $plan = prepare($in);
    is($plan->{profile}, 'fixed', 'fully static graph stays fixed');
    is($plan->{width_plan}, undef, 'fixed graph invents no symbolic range');
    is_deeply([map {$plan->{nodes}{$_}{width}} @{$plan->{node_order}}], [4,8], 'child and root retain distinct actual selected maxima');
    my $stale = fixture('(+ A (* B C))', 8);
    my $a = $stale->{flattened_dt}{fsm_module}->signals->{A};
    $a->set_attribute('width_declared', $a->get_attribute('width_declared'));
    ok(!eval {prepare($stale); 1}, 'supported matching source write revokes actual graph proof');
};
subtest 'active numeric cycles terminate without turning a sibling revisit into recursion' => sub {
    my $in = fixture('(+ A (* B C))', 8);
    my $owner = $in->{flattened_dt}{backend_sv_intermediate_width_support};
    my $loop = FSM::HDL::IntermediateSignalRef->new(signal_name => 'LOOP');
    my $info = {source => 'cycle_control', ast => $loop, runtime_ast => $loop,
        runtime_ast_source => 'cycle_control'};
    my %active;
    local $SIG{ALRM} = sub {POSIX::_exit(124)};
    alarm 5; # A broken recursion guard must fail the test, even through eval.
    my $width = $owner->resolve_intermediate_signal_width('LOOP', $info, {LOOP => $info}, \%active);
    alarm 0;
    is($width, 1, 'real active cycle retains conservative numeric fallback');
    is_deeply(\%active, {}, 'dynamic active markers restore after recursion unwinds');
    is($owner->factorized_graph_width_allocation('LOOP', $info), undef, 'cycle creates no completed graph proof');
};
done_testing();
