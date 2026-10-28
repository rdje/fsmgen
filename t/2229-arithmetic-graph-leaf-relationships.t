use strict;
use warnings;
use lib 'perl';
use Test::More;
use JSON::PP;
use Lispish;
use FSM::Adapter::FSMGenFull;
use FSM::HDL::FlattenedDT;
use FSM::DirectDeclaredWidthSupport;
my $class = 'FSM::DirectDeclaredWidthSupport';
my $json = JSON::PP->new->canonical;
sub policy {
    return {kind => 'arithmetic_graph_operand_max', operator => '+', source_names => ['AB','C'],
        expression_tree => ['+', ['+', ['signal','A'], ['signal','B']], ['signal','C']], selected_width => 8};
}
sub fixture {
    my ($width, @sizes) = @_;
    @sizes = ('(param W)') x 3 unless @sizes;
    my $source = "(?fsm:graph_leaves (+params (W $width) (COPY W) (SAME $width))"
        . " (+size (A $sizes[0]) (B $sizes[1]) (C $sizes[2]) (DATA 1) (OTHER 1))"
        . ' (idle (<(+ A B C) (= (DATA 1)) (= (OTHER 1))) (-> idle)))';
    my $module = FSM::Adapter::FSMGenFull->new->parse_fsm(scalar Lispish::multi(\$source));
    my $ctx = FSM::HDL::FlattenedDT->new;
    $ctx->generate_systemverilog($module);
    return {fsm_module => $module, assignment_analysis => $ctx->{assignment_analysis},
        target_language => 'systemverilog', graph_width_allocation => policy};
}
sub prepare {return $class->prepare_graph_operand_relationship(%{$_[0]})}
sub source_state {
    my ($in) = @_;
    my $m = $in->{fsm_module};
    return $json->encode([$in->{graph_width_allocation}, $m->parameters, $m->parameter_default_sources,
        $m->parameter_default_bindings, {map {my $s = $m->signals->{$_};
            $_ => [$s->width, $s->signed, $s->declared_width_source, $s->declared_width_binding,
                $s->declared_width_requirements]} sort keys %{$m->signals}}]);
}
subtest 'all original leaves share the canonical frozen mutable range with duplicate slots' => sub {
    for my $width (1, 8) {
        my $in = fixture($width);
        my $before = source_state($in);
        my $plan = prepare($in);
        is($plan->{profile}, 'symbolic', 'same actual mutable source contracts qualify');
        is_deeply($plan->{source_names}, ['A','B','C'], 'original tree order selects every actual source');
        is_deeply($plan->{operand_widths}, [$width,$width,$width], 'each independently observed width retains');
        is_deeply($plan->{width_plan}, $class->prepare_module(%$in)->{signals}{A}{width_plan},
            'representative comes from canonical source proof');
        is($plan->{width_plan}{is_vector}, 1, 'default-one mutable range retains vector rank');
        is(source_state($in), $before, 'graph data and all source/default/binding/requirement kinds preserve');
        $plan->{source_names}[0] = 'WRONG';
        $plan->{width_plan}{width_contract}{expression}[1] = 'WRONG';
        is_deeply(prepare($in)->{source_names}, ['A','B','C'], 'ordered return vector detaches');
        is(prepare($in)->{width_plan}{width_contract}{expression}[1], 'W', 'nested range contract detaches');
    }
    my $in = fixture(8, ('(+ (param W) (param W))') x 3);
    $in->{graph_width_allocation}{expression_tree}[2] = ['signal','A'];
    my $plan = prepare($in);
    is_deeply($plan->{source_names}, ['A','B','A'], 'repeated original source slot stays repeated');
    is_deeply($plan->{width_plan}, $class->prepare_module(%$in)->{signals}{A}{width_plan}, 'repeated parameter roots and width tree preserve');
    $in->{target_language} = 'vhdl';
    is(prepare($in)->{target_language}, 'vhdl', 'source-only adaptation remains separate from target graph admission');
};
subtest 'later independent roots trees and static floors cannot borrow an earlier match' => sub {
    for my $last ('(param COPY)', '(param SAME)', '8', '(+ (param W) 0)') {
        my $in = fixture(8, '(param W)', '(param W)', $last);
        my $before = source_state($in);
        ok(!eval {prepare($in); 1}, 'matching earlier leaves cannot hide a different final contract');
        like($@, qr/identical mutable operand contracts/, 'refusal identifies the frozen relationship');
        is(source_state($in), $before, 'refusal preserves complete caller state');
    }
    my $fixed = fixture(8, '8', '2', '4');
    my $plan = prepare($fixed);
    is($plan->{profile}, 'fixed', 'independent static source widths remain fixed');
    is_deeply($plan->{operand_widths}, [8,2,4], 'no numeric equality is imposed on fixed leaves');
    is($plan->{width_plan}, undef, 'fixed source relationship invents no symbolic range');
};
subtest 'schema source membership types constraints and stale captures refuse' => sub {
    my $in = fixture(8);
    for my $bad (undef, {kind => 'binary_operand_max', operator => '+', source_names => ['A','B'], selected_width => 8},
        {%{policy()}, expression_tree => ['+', ['signal','A'], ['signal','B']]}) {
        ok(!eval {$class->prepare_graph_operand_relationship(%$in, graph_width_allocation => $bad); 1}, 'non-graph schema cannot select source leaves');
    }
    for my $case (
        ['foreign', sub {$_[0]{graph_width_allocation}{expression_tree}[2] = ['signal','FOREIGN']}],
        ['signed', sub {$_[0]{fsm_module}->signals->{C}{signed} = 1}],
        ['state', sub {$_[0]{fsm_module}->signals->{C}{state_model} = 'known'}],
        ['type', sub {$_[0]{fsm_module}->signals->{C}{declared_type_name} = 'word_t'}],
        ['constraints', sub {$_[0]{fsm_module}->signals->{C}{constraints} = ['opaque']}],
        ['stale parameter', sub {$_[0]{fsm_module}{parameters}{W} = 9}],
    ) {
        my $current = fixture(8);
        $case->[1]->($current);
        ok(!eval {prepare($current); 1}, "$case->[0] cannot gain an actual source relationship");
    }
    ok(!eval {$class->prepare_binary_operand_relationship(%$in, source_names => ['A','B','C']); 1}, 'existing binary API keeps its exact arity');
    is_deeply([sort keys %{prepare($in)}], [sort qw(profile target_language source_scope source_names operand_widths width_plan)],
        'source-only graph plan contains neither allocation attestation nor target evidence');
};
done_testing();
