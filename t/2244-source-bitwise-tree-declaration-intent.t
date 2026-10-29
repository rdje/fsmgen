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
use FSM::Backend::VerilogFamily::DeclarationCapture;
my $class = 'FSM::DirectDeclaredWidthSupport';
my $json = JSON::PP->new->canonical;
unless ($class->can('prepare_source_tree_declaration')) {
    fail('actual source-tree declaration intent API exists');
    done_testing();
    exit;
}
sub fixture {
    my ($width, $expression, @sizes) = @_;
    $expression //= '(& A B C)';
    @sizes = ('(param W)') x 3 unless @sizes;
    my $text = "(?fsm:source_intent (+params (W $width) (COPY W))"
        . " (+size (A $sizes[0]) (B $sizes[1]) (C $sizes[2]) (DATA 1) (OTHER 1))"
        . " (idle (<$expression (= (DATA 1)) (= (OTHER 1))) (-> idle)))";
    my $module = FSM::Adapter::FSMGenFull->new->parse_fsm(scalar Lispish::multi(\$text));
    my $ctx = FSM::HDL::FlattenedDT->new;
    my $capture = FSM::Backend::VerilogFamily::DeclarationCapture->new;
    my $collect = FSM::HDL::FlattenedDT::Backend::SystemVerilog::ConsolidatedIntermediateSupport
        ->can('collect_consolidated_intermediate_signals');
    my ($all, $hdl);
    {
        no warnings 'redefine';
        local *FSM::HDL::FlattenedDT::Backend::SystemVerilog::ConsolidatedIntermediateSupport::collect_consolidated_intermediate_signals = sub {
            $all = $collect->(@_);
            return $all;
        };
        local $ctx->{declared_width_declaration_capture} = $capture;
        $hdl = $ctx->generate_systemverilog($module);
    }
    my $snapshot = $capture->snapshot;
    my @names = grep {exists($snapshot->{target_intermediates}{$_}{source_tree_width_allocation})}
        sort keys %{$snapshot->{target_intermediates}};
    my %child = map {$_ => 1} map {@{$snapshot->{target_intermediates}{$_}{source_tree_width_allocation}{source_names}}} @names;
    my @roots = grep {!$child{$_}} @names;
    die "fixture requires exactly one selected source-tree root\n" unless @roots == 1;
    my $name = $roots[0];
    return {flattened_dt => $ctx, signal_name => $name, signal_info => $all->{$name}, all => $all,
        target_language => 'systemverilog', expression => $snapshot->{target_intermediates}{$name}{expression},
        hdl => $hdl, snapshot => $snapshot};
}
sub prepare {
    my ($in, %override) = @_;
    return $class->prepare_source_tree_declaration(
        (map {$_ => $in->{$_}} qw(flattened_dt signal_name signal_info target_language expression)), %override);
}
subtest 'actual completed source intent proves every original leaf without target inputs' => sub {
    for my $case ([1,'(& A B C)'], [8,'(| A B C)'], [1,'(^ A B A)'], [8,'(!& A B C)']) {
        my $in = fixture(@$case);
        my $before = $json->encode($in->{snapshot});
        my $plan = prepare($in, target_namespace => undef, target_declarations => undef, target_intermediates => undef);
        my $event = $in->{snapshot}{target_intermediates}{$in->{signal_name}};
        is_deeply($plan->{source_tree_width_allocation}, $event->{source_tree_width_allocation}, 'intent binds actual completed source policy');
        is_deeply($plan->{source_tree_origin}, $event->{source_tree_origin}, 'complete typed origin preserves association and ordered slots');
        is_deeply($plan->{leaf_names}, $event->{source_tree_origin}{source_names}, 'all actual original leaves remain ordered including duplicates');
        is_deeply($plan->{expression_tree}, $event->{source_tree_origin}{expression_tree}, 'original tree survives in detached root intent');
        is($plan->{width_plan}{is_vector}, 1, 'mutable default-one original range retains vector rank');
        is($plan->{profile}, 'symbolic', 'every actual mutable contract agrees');
        is($plan->{expression}, $in->{expression}, 'fresh selected expression preserves');
        is($plan->{allocation_role}, 'source_intermediate', 'source allocation role stays separate from computed arithmetic');
        is($json->encode($in->{snapshot}), $before, 'complete caller target snapshot preserves JSON kinds');
        my $fresh = $json->encode($plan);
        $plan->{leaf_names}[0] = 'WRONG';
        $plan->{width_plan}{width_contract}{expression}[1] = 'WRONG';
        is($json->encode(prepare($in)), $fresh, 'returned leaf and nested range data detach');
        unlike($in->{hdl}, qr/^  wire \[\(W - 1\):0\] \Q$in->{signal_name}\E;$/m, 'new preparation does not activate live source-tree range emission');
        ok(!exists($plan->{nodes}) && !exists($plan->{node_order}), 'source intent asserts no selected child-target inventory');
    }
    my $fixed = fixture(8, '(& A B C)', '8','4','2');
    my $plan = prepare($fixed);
    is($plan->{profile}, 'fixed', 'independent fixed leaves retain fixed intent');
    is($plan->{width}, 8, 'root maximum remains actual selected result');
    is($plan->{width_plan}, undef, 'fixed intent invents no mutable contract');
};
subtest 'copy foreign stale text independent floors and incompatible relationships refuse' => sub {
    my $in = fixture(8);
    for my $override (
        {signal_info => {%{$in->{signal_info}}}}, {signal_name => 'FOREIGN'},
        {expression => 'A | B | C'}, {target_language => 'vhdl'},
        {flattened_dt => FSM::HDL::FlattenedDT->new},
    ) {
        ok(!eval {prepare($in, %$override); 1}, 'incoherent actual source selection refuses');
    }
    for my $last ('(param COPY)', '8', '(+ (param W) 0)') {
        my $different = fixture(8, '(& A B C)', '(param W)', '(param W)', $last);
        ok(!eval {prepare($different); 1}, 'different third-leaf contract cannot borrow matching defaults');
        like($@, qr/identical mutable operand contracts/, 'canonical relationship identifies the refusal');
    }
    my $nested = fixture(8, '(& A B (| A B C))');
    ok(!eval {prepare($nested); 1}, 'generated source-helper leaf cannot masquerade as original module input');
    like($@, qr/recursive source-helper proof is pending/, 'recursive actual helper support keeps its precise owned boundary');
    $in->{signal_info}{width} = 32;
    ok(!eval {prepare($in); 1}, 'independent result floor cannot borrow intent');
};
subtest 'late complete source row ownership and supported writes invalidate equal-range intent' => sub {
    my $relationship = $class->can('prepare_source_tree_operand_relationship');
    for my $change (
        sub {$_[0]{flattened_dt}{assignment_analysis}{DATA}{lhs_ast}->signal->{constraints} = ['late constraint']},
        sub {my $s = $_[0]{flattened_dt}{fsm_module}->signals->{C}; $s->set_attribute('width_declared', $s->get_attribute('width_declared'))},
        sub {$_[0]{signal_info}{state_model} = 'late state'},
        sub {my $in = shift; $in->{all}{$in->{signal_name}} = {%{$in->{signal_info}}}},
        sub {delete $_[0]{all}},
        sub {my $ctx = $_[0]{flattened_dt}; $ctx->{backend_sv_intermediate_width_support} = bless {%{$ctx->{backend_sv_intermediate_width_support}}}, ref($ctx->{backend_sv_intermediate_width_support})},
    ) {
        my $in = fixture(8);
        my ($changed, $result, $error);
        {
            no warnings 'redefine';
            local *FSM::DirectDeclaredWidthSupport::prepare_source_tree_operand_relationship = sub {
                my $plan = $relationship->(@_);
                $change->($in) unless $changed++;
                return $plan;
            };
            $result = eval {prepare($in)}; $error = $@;
        }
        ok($changed, 'actual canonical relationship precedes the controlled write');
        ok(!$result && length($error), 'changed complete source or current owner refuses despite equal range text');
    }
};
subtest 'final complete source reads cannot keep released caller rows alive' => sub {
    my $in = fixture(8);
    my $rows = $in->{all}; weaken($rows);
    my $snapshot = $class->can('_capture_source_state');
    my ($reads, $result, $error);
    {
        no warnings 'redefine';
        local *FSM::DirectDeclaredWidthSupport::_capture_source_state = sub {
            my $state = $snapshot->(@_);
            delete $in->{all} if ++$reads == 2;
            return $state;
        };
        $result = eval {prepare($in)}; $error = $@;
    }
    is($reads, 2, 'controlled release follows the final complete source snapshot');
    ok(!$result && length($error), 'source intent refuses after final caller ownership release');
    is($rows, undef, 'proof retains no final temporary row owner');
};
subtest 'detached intent cannot retain or revive the actual weak source-row view' => sub {
    my $in = fixture(8);
    my $rows = $in->{all}; weaken($rows);
    my $plan = prepare($in);
    my $encoded = $json->encode($plan);
    delete $in->{all};
    is($rows, undef, 'returned source intent retains no collected row container');
    is($in->{flattened_dt}{backend_sv_intermediate_width_support}->_current_graph_inference_rows,
        undef, 'installed owner association remains weak');
    is($json->encode($plan), $encoded, 'detached original plan remains a historical snapshot');
    ok(!eval {prepare($in); 1}, 'held root metadata and returned plan cannot revive current source proof');
};
done_testing();
