use strict;
use warnings;
use lib 'perl';
use Test::More;
use JSON::PP;
use Scalar::Util qw(weaken);
use Lispish;
use FSM::Adapter::FSMGenFull;
use FSM::HDL::FlattenedDT;
use FSM::DirectDeclaredWidthSupport;
use FSM::IntermediateWidthGraphPolicySupport;
use FSM::Backend::VerilogFamily::DeclarationCapture;
my $class = 'FSM::DirectDeclaredWidthSupport';
my $json = JSON::PP->new->canonical;
sub fixture {
    my $source = '(?fsm:graph_closure (+params (W 8))'
        . ' (+size (A (param W)) (B (param W)) (C (param W)) (DATA 1) (OTHER 1))'
        . ' (idle (<(+ A (* B C)) (= (DATA 1)) (= (OTHER 1))) (-> idle)))';
    my $module = FSM::Adapter::FSMGenFull->new->parse_fsm(scalar Lispish::multi(\$source));
    my $ctx = FSM::HDL::FlattenedDT->new;
    my $capture = FSM::Backend::VerilogFamily::DeclarationCapture->new;
    my $build_class = 'FSM::HDL::FlattenedDT::Backend::SystemVerilog::ConsolidatedIntermediatePreparedBlockSupport';
    my $build = $build_class->can('build_prepared_consolidated_intermediate_block');
    my $block;
    {
        no strict 'refs'; no warnings 'redefine';
        local *{"${build_class}::build_prepared_consolidated_intermediate_block"} = sub {
            $block = $build->(@_); return $block;
        };
        local $ctx->{declared_width_declaration_capture} = $capture;
        $ctx->generate_systemverilog($module);
    }
    my $snapshot = $capture->snapshot;
    my ($name) = grep {exists($snapshot->{target_intermediates}{$_}{graph_width_allocation})}
        sort keys %{$snapshot->{target_intermediates}};
    die 'fixture requires actual selected graph' unless defined($name);
    return {flattened_dt => $ctx, signal_name => $name,
        signal_info => $block->{all_intermediate_signals}{$name}, owner_block => $block,
        target_language => 'systemverilog', %$snapshot};
}
sub prepare {
    my ($in) = @_;
    # The actual caller owns its prepared block; pass only the API's inputs so
    # this operation cannot borrow ownership from an unrelated argument.
    return $class->prepare_arithmetic_graph_intermediate_range(map {$_ => $in->{$_}}
        qw(flattened_dt signal_name signal_info target_language target_namespace target_declarations target_intermediates));
}
sub source_plan {
    my ($in) = @_;
    my $ctx = $in->{flattened_dt};
    return $class->prepare_module(fsm_module => $ctx->{fsm_module},
        assignment_analysis => $ctx->{assignment_analysis}, target_language => 'systemverilog');
}
sub mutate_after_relationship {
    my ($in, $change) = @_;
    my $relationship = $class->can('prepare_graph_operand_relationship');
    my ($changed, $result, $error);
    {
        no warnings 'redefine';
        local *FSM::DirectDeclaredWidthSupport::prepare_graph_operand_relationship = sub {
            my $r = $relationship->(@_);
            $change->($in) unless $changed++;
            return $r;
        };
        $result = eval {prepare($in)}; $error = $@;
    }
    return ($result, $error, $changed);
}
subtest 'complete deep target inputs cannot change behind unchanged canonical plans' => sub {
    for my $change (
        sub {my ($in, $child) = @_; $in->{target_declarations}{$child}{opaque_annotation} = {nested => ['changed']}},
        sub {my ($in, $child) = @_; $in->{target_intermediates}{$child}{opaque_annotation} = {nested => ['changed']}},
        sub {my ($in) = @_; $in->{target_intermediates}{$in->{signal_name}}{graph_width_allocation}{expression_tree}[2][2][1] = 'A'},
    ) {
        my $in = fixture;
        my $child = $in->{target_intermediates}{$in->{signal_name}}{graph_width_allocation}{source_names}[1];
        my $target = $class->prepare_declarations(fsm_module => $in->{flattened_dt}{fsm_module},
            assignment_analysis => $in->{flattened_dt}{assignment_analysis}, target_language => 'systemverilog',
            target_namespace => $in->{target_namespace}, target_declarations => $in->{target_declarations});
        my ($result, $error, $changed) = mutate_after_relationship($in, sub {$change->($_[0], $child)});
        ok($changed, 'actual canonical source relationship precedes controlled mutation');
        ok(!$result, 'complete target mutation withholds the private graph plan');
        like($error, qr/changed during preparation/, 'full target snapshot owns the late refusal');
        my $again = $class->prepare_declarations(fsm_module => $in->{flattened_dt}{fsm_module},
            assignment_analysis => $in->{flattened_dt}{assignment_analysis}, target_language => 'systemverilog',
            target_namespace => $in->{target_namespace}, target_declarations => $in->{target_declarations});
        is_deeply($again, $target, 'derived canonical target plan alone would hide this input change');
    }
};
subtest 'complete source constraints and supported dependency writes recheck after source proof' => sub {
    my $in = fixture;
    my $before = source_plan($in);
    my ($result, $error, $changed) = mutate_after_relationship($in, sub {
        my $ctx = $_[0]{flattened_dt};
        $ctx->{assignment_analysis}{DATA}{lhs_ast}->signal->{constraints} = ['late constraint'];
    });
    ok($changed, 'actual source proof preceded the source constraint write');
    is_deeply(source_plan($in), $before, 'canonical source plan alone hides a non-width constraint change');
    ok(!$result, 'full source inputs still invalidate private graph plan');
    like($error, qr/changed during preparation/, 'full source snapshot owns the refusal');
    my $dependency = fixture;
    my ($stale, $reason, $read) = mutate_after_relationship($dependency, sub {
        my $a = $_[0]{flattened_dt}{fsm_module}->signals->{A};
        $a->set_attribute('width_declared', $a->get_attribute('width_declared'));
    });
    ok($read, 'actual source relationship preceded matching supported source write');
    ok(!$stale && length($reason), 'current dependency policy independently rejects the matching supported write');
};
subtest 'returned graph JSON does not retain the actual weak row container' => sub {
    my $in = fixture;
    my $view = $in->{owner_block}{all_intermediate_signals}; weaken($view);
    my $plan = prepare($in);
    ok($view, 'actual caller block owns current graph rows through preparation');
    my $encoded = $json->encode($plan);
    delete $in->{owner_block};
    is($view, undef, 'returned detached graph plan retains no row container');
    is($in->{flattened_dt}{backend_sv_intermediate_width_support}->_current_graph_inference_rows,
        undef, 'width owner retains only its weak association');
    is($json->encode($plan), $encoded, 'returned graph JSON remains a detached historical snapshot');
    ok(!eval {prepare($in); 1}, 'metadata row and prior plan cannot revive expired graph proof');
};
subtest 'losing the last actual row owner during preparation cannot return current proof' => sub {
    my $in = fixture;
    my $view = $in->{owner_block}{all_intermediate_signals}; weaken($view);
    my ($result, $error, $changed) = mutate_after_relationship($in, sub {delete $_[0]{owner_block}});
    ok($changed, 'actual source relationship reached the owner-release control');
    ok(!$result && length($error), 'private operation cannot return proof after actual caller ownership expires');
    is($view, undef, 'private operation releases its temporary row references');
    is($in->{flattened_dt}{backend_sv_intermediate_width_support}->_current_graph_inference_rows,
        undef, 'no hidden strong row view survives the failed preparation');
};
done_testing();
