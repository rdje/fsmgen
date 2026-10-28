use strict;
use warnings;
use lib 'perl';
use Test::More;
use JSON::PP;
use Lispish;
use FSM::Adapter::FSMGenFull;
use FSM::HDL::FlattenedDT;
use FSM::AST::Node;
use FSM::DirectDeclaredWidthSupport;
use FSM::IntermediateWidthGraphPolicySupport;
use FSM::Backend::VerilogFamily::DeclarationCapture;
my $json = JSON::PP->new->canonical;
sub fixture {
    my ($expression, $width, %options) = @_;
    my @sizes = @{$options{sizes} // [('(param W)') x 3]};
    my $source = "(?fsm:graph_emission (+params (W $width) (COPY W))"
        . " (+size (A $sizes[0]) (B $sizes[1]) (C $sizes[2]) (DATA 1) (OTHER 1))"
        . " (idle (<$expression (= (DATA 1)) (= (OTHER 1))) (-> idle)))";
    my $module = FSM::Adapter::FSMGenFull->new->parse_fsm(scalar Lispish::multi(\$source));
    my $ctx = $options{ctx} // FSM::HDL::FlattenedDT->new;
    my $capture = FSM::Backend::VerilogFamily::DeclarationCapture->new;
    my $collect_class = 'FSM::HDL::FlattenedDT::Backend::SystemVerilog::ConsolidatedIntermediateSupport';
    my $tail_class = 'FSM::HDL::FlattenedDT::Backend::SystemVerilog::GenerationTailSupport';
    my $collect = $collect_class->can('collect_consolidated_intermediate_signals');
    my $tail = $tail_class->can('generate_systemverilog_tail');
    my $decl = FSM::DirectDeclaredWidthSupport->can('prepare_arithmetic_graph_declaration');
    my $complete = FSM::DirectDeclaredWidthSupport->can('prepare_arithmetic_graph_intermediate_range');
    my ($all, $hdl, $error, $name, %policies, %observed);
    {
        no strict 'refs'; no warnings 'redefine';
        local *{"${collect_class}::collect_consolidated_intermediate_signals"} = sub {
            ++$observed{collections}; $all = $collect->(@_);
            for my $candidate (sort keys %$all) {
                my $p = $ctx->{backend_sv_intermediate_width_support}->factorized_graph_width_allocation($candidate, $all->{$candidate});
                $policies{$candidate} = $p if $p;
            }
            ($name) = sort {
                @{FSM::IntermediateWidthGraphPolicySupport->leaf_names($policies{$b})}
                    <=> @{FSM::IntermediateWidthGraphPolicySupport->leaf_names($policies{$a})} || $a cmp $b
            } keys %policies;
            return $all;
        };
        local *FSM::DirectDeclaredWidthSupport::prepare_arithmetic_graph_declaration = sub {
            ++$observed{source_declarations}; return $decl->(@_);
        };
        local *FSM::DirectDeclaredWidthSupport::prepare_arithmetic_graph_intermediate_range = sub {
            ++$observed{complete_targets}; return $complete->(@_);
        };
        local *{"${tail_class}::generate_systemverilog_tail"} = sub {
            my $map = $ctx->{direct_declared_width_emitted_graph_ranges};
            $observed{graph_ledger} = $json->decode($json->encode($map));
            my $before = $json->encode($map);
            if (defined($name) && exists($map->{$name})) {
                for my $case (['==', 0], ['!=', 0], ['==', 1]) {
                    my ($op, $value) = @$case;
                    my $ast = FSM::AST::BinaryOp->new($op, FSM::AST::SignalRef->new($name), FSM::AST::Literal->new("$value"));
                    $observed{truth}{$op.$value} = $ctx->{enable_graph_ast_support}->ast_to_systemverilog($ast);
                }
                $ctx->{enable_graph_ast_support}->_signal_is_single_bit('UNDECLARED_GRAPH_PROBE');
            }
            $observed{ledger_unchanged} = $before eq $json->encode($map);
            my $result = $tail->(@_);
            $options{late}->($ctx, $name, $all, $capture) if $options{late};
            return $result;
        };
        local $ctx->{declared_width_declaration_capture} = $capture;
        eval {$hdl = ($options{language} // '') eq 'verilog' ? $ctx->generate_verilog($module) : $ctx->generate_systemverilog($module); 1} or $error = $@;
    }
    return {ctx => $ctx, module => $module, capture => $capture, all => $all, name => $name,
        hdl => $hdl, error => $error, observed => \%observed, snapshot => $error ? undef : $capture->snapshot};
}
subtest 'actual graph declarations consume frozen source ranges and independent target closure' => sub {
    for my $expression ('(+ A B C)', '(+ A (* B C))', '(+ (+ A B) (+ A B))') {
        for my $width (1, 8) {
            my $p = fixture($expression, $width, language => $width == 1 ? 'verilog' : 'systemverilog');
            is($p->{error}, undef, 'actual one-pass native generation succeeds') or diag $p->{error};
            next if $p->{error};
            my $name = $p->{name};
            like($p->{hdl}, qr/^  wire \[\(W - 1\):0\] \Q$name\E;$/m, 'actual computed parent keeps the canonical symbolic range');
            is($p->{observed}{collections}, 1, 'generation collects the real graph once');
            ok($p->{observed}{source_declarations}, 'actual declaration stage calls source-only intent');
            ok($p->{observed}{complete_targets}, 'final assembly independently calls completed-target proof');
            for my $candidate (sort keys %{$p->{observed}{graph_ledger}}) {
                my $plan = FSM::DirectDeclaredWidthSupport->prepare_arithmetic_graph_intermediate_range(
                    flattened_dt => $p->{ctx}, signal_name => $candidate, signal_info => $p->{all}{$candidate},
                    target_language => 'systemverilog', %{$p->{snapshot}});
                delete @{$plan}{qw(nodes node_order)};
                is_deeply($p->{observed}{graph_ledger}{$candidate}, $plan, 'every emitted graph root field agrees with independent complete target proof');
            }
        }
    }
};
subtest 'symbolic graph rank preserves whole-value guard and comparison truth at default one' => sub {
    my $p = fixture('(+ A B C)', 1);
    is($p->{error}, undef, 'symbolic graph guard generates');
    my $name = $p->{name};
    like($p->{hdl}, qr/^  assign idle_data_1_en = idle_en && /m, 'symbolic graph predicate uses whole-value logical gating');
    is_deeply($p->{observed}{truth}, {'==0' => "(~|$name)", '!=0' => "(|$name)", '==1' => "$name == 1"},
        'zero nonzero and exact-one tests keep full symbolic graph meaning');
    ok($p->{observed}{ledger_unchanged}, 'guard classification leaves graph declaration intent unchanged');
};
subtest 'fixed graph widths retain numeric declarations and no symbolic ledger' => sub {
    my $p = fixture('(+ A (* B C))', 8, sizes => ['8','4','2']);
    is($p->{error}, undef, 'independent static graph still generates');
    my $name = $p->{name};
    like($p->{hdl}, qr/^  wire \[7:0\] \Q$name\E;$/m, 'fixed parent retains selected numeric width');
    is_deeply($p->{observed}{graph_ledger}, {}, 'fixed graph acquires no symbolic declaration ledger');
};
subtest 'incompatible source contracts and late source or ledger changes publish no artifact' => sub {
    my $different = fixture('(+ A B C)', 8, sizes => ['(param W)','(param W)','(param COPY)']);
    ok($different->{error}, 'independent equal-default root refuses live symbolic range emission');
    is($different->{hdl}, undef, 'failed relation returns no HDL artifact');
    ok(!eval {$different->{capture}->snapshot; 1}, 'failed relation exposes no completed snapshot');
    for my $change (
        sub {my $a = $_[0]{fsm_module}->signals->{A}; $a->set_attribute('width_declared', $a->get_attribute('width_declared'))},
        sub {my ($ctx, $name) = @_; $ctx->{direct_declared_width_emitted_graph_ranges}{$name}{width_plan}{width_contract}{expression}[1] = 'WRONG'},
    ) {
        my $p = fixture('(+ A (* B C))', 8, late => $change);
        ok($p->{error}, 'late source/currentness or complete emitted field mismatch refuses');
        is($p->{hdl}, undef, 'late failed proof returns no artifact');
        ok(!eval {$p->{capture}->snapshot; 1}, 'late failed proof invalidates the snapshot');
        my $retry = fixture('(+ A (* B C))', 1, ctx => $p->{ctx});
        is($retry->{error}, undef, 'fresh generation recovers on the same backend');
    }
};
done_testing();
