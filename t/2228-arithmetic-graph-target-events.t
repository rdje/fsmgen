use strict;
use warnings;
use lib 'perl';
use Test::More;
use JSON::PP;
use Lispish;
use FSM::Adapter::FSMGenFull;
use FSM::HDL::FlattenedDT;
use FSM::Backend::VerilogFamily::DeclarationCapture;
use FSM::IntermediateWidthGraphPolicySupport;
my $json = JSON::PP->new->canonical;
my $width_class = 'FSM::HDL::FlattenedDT::Backend::SystemVerilog::IntermediateSignalWidthSupport';
my $collect_class = 'FSM::HDL::FlattenedDT::Backend::SystemVerilog::ConsolidatedIntermediateSupport';
my $normalize_class = 'FSM::HDL::FlattenedDT::Backend::SystemVerilog::ConsolidatedIntermediateNormalizationSupport';
sub fixture {
    my ($expression, $width, %options) = @_;
    my $source = "(?fsm:graph_target (+params (W $width))"
        . ' (+size (A (param W)) (B (param W)) (C (param W)) (DATA 1) (OTHER 1))'
        . " (idle (<$expression (= (DATA 1)) (= (OTHER 1))) (-> idle)))";
    my $module = FSM::Adapter::FSMGenFull->new->parse_fsm(scalar Lispish::multi(\$source));
    $options{module}->($module) if $options{module};
    my $ctx = FSM::HDL::FlattenedDT->new;
    my $capture = FSM::Backend::VerilogFamily::DeclarationCapture->new;
    my $collect = $collect_class->can('collect_consolidated_intermediate_signals');
    my $normalize = $normalize_class->can('normalize_consolidated_intermediate_metadata');
    my $lookup = $width_class->can('factorized_graph_width_allocation');
    my ($all, $hdl, $error, $prepared, $changed, %policies);
    {
        no warnings 'redefine'; no strict 'refs';
        local *{"${normalize_class}::normalize_consolidated_intermediate_metadata"} = sub {
            my ($owner, $rows) = @_;
            # Install independent profiles before ANY child can infer. A root
            # resolver callback is too late when hash order resolved its child.
            if ($options{before_inference} && !$prepared++) {
                my ($name) = sort grep {$ctx->{ast_factorizer}->intermediate_width_graph_birth($_)} keys %$rows;
                die "constraint fixture requires an actual graph root\n" unless defined($name);
                $options{before_inference}->($ctx, $name, $rows->{$name}, $rows);
            }
            return $normalize->(@_);
        };
        local *{"${collect_class}::collect_consolidated_intermediate_signals"} = sub {
            $all = $collect->(@_);
            for my $name (sort keys %$all) {
                my $p = $lookup->($ctx->{backend_sv_intermediate_width_support}, $name, $all->{$name});
                $policies{$name} = $p if $p;
            }
            $options{collected}->($ctx, $all) if $options{collected};
            return $all;
        };
        local *{"${width_class}::factorized_graph_width_allocation"} = sub {
            my $p = $lookup->(@_);
            if ($p && $options{during_lookup} && !$changed++) {$options{during_lookup}->($ctx)}
            return $p;
        };
        local $ctx->{declared_width_declaration_capture} = $capture;
        eval {$hdl = $ctx->generate_systemverilog($module); 1} or $error = $@;
    }
    my @names = sort {
        @{FSM::IntermediateWidthGraphPolicySupport->leaf_names($policies{$b})}
            <=> @{FSM::IntermediateWidthGraphPolicySupport->leaf_names($policies{$a})}
        || $a cmp $b
    } keys %policies;
    return {ctx => $ctx, module => $module, capture => $capture, all => $all, name => $names[0],
        policies => \%policies, changed => $changed, hdl => $hdl, error => $error,
        snapshot => $error ? undef : $capture->snapshot};
}
sub selected_policy {
    my ($p, $info, $expression) = @_;
    my $name = $p->{name};
    my $event = $p->{snapshot}{target_intermediates}{$name};
    return $p->{ctx}{backend_sv_intermediate_recovery_support}->arithmetic_graph_width_allocation(
        $name, $info // $p->{all}{$name}, $expression // $event->{expression});
}
subtest 'actual selected graph events join completed policy and ordered arithmetic origin' => sub {
    for my $case (map({["($_ A B C)", 8]} ('+', '-', '*', '/', '%')),
        ['(+ A (* B C))', 1], ['(+ A A A)', 1], ['(+ (+ A B C) (+ B C A))', 8]) {
        my $p = fixture(@$case);
        is($p->{error}, undef, 'ordinary native generation succeeds');
        ok(keys %{$p->{policies}}, 'actual completed graph policy exists');
        for my $name (sort keys %{$p->{policies}}) {
            my $event = $p->{snapshot}{target_intermediates}{$name};
            next unless $event;
            my $policy = $p->{policies}{$name};
            is_deeply($event->{graph_width_allocation}, $policy, 'emitted graph field retains the actual completed record');
            is_deeply($event->{arithmetic_origin}, {kind => 'binary_arithmetic',
                operator => $policy->{operator}, source_names => $policy->{source_names}}, 'selected ordered origin matches graph current edges');
            ok(!exists($event->{width_allocation}), 'graph event stays separate from binary allocation');
            my $info = $p->{all}{$name};
            is($p->{ctx}{backend_sv_intermediate_recovery_support}->arithmetic_width_allocation($name, $info, $event->{expression}),
                undef, 'ordinary arithmetic policy API stays binary-only');
        }
        my $copy = selected_policy($p);
        is_deeply($copy, $p->{policies}{$p->{name}}, 'current recovery publisher yields same detached policy');
        $copy->{expression_tree}[0] = 'WRONG';
        is_deeply(selected_policy($p), $p->{policies}{$p->{name}}, 'caller mutation cannot alter current proof');
    }
};
subtest 'numeric graph proof alone cannot publish constrained transitive target profiles' => sub {
    for my $options (
        {label => 'source', module => sub {$_[0]->signals->{C}{state_model} = 'known'}},
        {label => 'collected root', before_inference => sub {my ($ctx, $name, $info) = @_; $info->{state_model} = 'known'}},
        {label => 'collected child', before_inference => sub {
            my ($ctx, $name, $info, $rows) = @_;
            my $child = $info->{ast}->right->name;
            $rows->{$child}{state_model} = 'known';
        }},
        {label => 'allocated root', before_inference => sub {
            my ($ctx, $name) = @_;
            $ctx->{ast_factorizer}{intermediate_signals}{$name}{state_model} = 'known';
        }},
    ) {
        my $p = fixture('(+ A (* B C))', 8, %$options);
        is($p->{error}, undef, 'existing numeric generation remains valid');
        ok(keys %{$p->{policies}}, "$options->{label}: numeric completed graph retains its independently snapshotted constraint");
        next unless keys %{$p->{policies}};
        ok(!exists($p->{snapshot}{target_intermediates}{$p->{name}}{graph_width_allocation}), 'target graph field refuses constrained source/result/child profile');
        is(selected_policy($p), undef, 'recovery cannot turn numeric policy into plain target proof');
    }
};
subtest 'copied stale floored and mismatched selected inputs cannot publish graph policy' => sub {
    my $p = fixture('(+ A (* B C))', 8);
    is(selected_policy($p, {%{$p->{all}{$p->{name}}}}), undef, 'equal copied row has no current policy');
    is(selected_policy($p, undef, 'A + B'), undef, 'different selected text cannot borrow graph policy');
    my $info = $p->{all}{$p->{name}};
    $info->{width} = 32;
    is(selected_policy($p), undef, 'independent root floor revokes graph policy');
    my $q = fixture('(+ A (* B C))', 8);
    my $a = $q->{module}->signals->{A};
    $a->set_attribute('width_declared', $a->get_attribute('width_declared'));
    is(selected_policy($q), undef, 'matching supported source mutation revokes graph publication');
    my $r = fixture('(+ A (* B C))', 8, during_lookup => sub {
        my $a = $_[0]{fsm_module}->signals->{A};
        $a->set_attribute('width_declared', $a->get_attribute('width_declared'));
    });
    is($r->{error}, undef, 'controlled mutation preserves ordinary generation');
    ok($r->{changed}, 'actual graph publisher read current completed policy');
    ok(!exists($r->{snapshot}{target_intermediates}{$r->{name}}{graph_width_allocation}), 'final currentness read refuses mutation during publication');
};
subtest 'legacy recovery provider retains original expression-only event' => sub {
    my $ctx = FSM::HDL::FlattenedDT->new;
    $ctx->{backend_sv_intermediate_recovery_support} = bless {}, 'Local::LegacyGraphRecovery';
    my $capture = FSM::Backend::VerilogFamily::DeclarationCapture->new;
    $capture->begin_module('legacy');
    local $ctx->{declared_width_declaration_capture} = $capture;
    my $block = {sorted_signals => ['RESULT'], filtered_signals => {RESULT => {width => 8}}};
    $ctx->{backend_sv_consolidated_intermediate_declaration_support}->render_consolidated_intermediate_declarations($block);
    my $hdl = $ctx->{backend_sv_consolidated_intermediate_assignment_support}->render_consolidated_intermediate_assignments($block);
    $capture->complete;
    is_deeply($capture->snapshot->{target_intermediates}{RESULT}, {expression => 'A + B'}, 'optional graph API is not required of legacy providers');
    like($hdl, qr/assign RESULT = A \+ B;/, 'legacy HDL preserves');
};
{package Local::LegacyGraphRecovery;
 sub render_intermediate_signal_expression {return 'A + B'}
 sub scalar_reduction_origin {return}
 sub binary_bitwise_origin {return}}
done_testing();
