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
    my $source = "(?fsm:source_tree_emission (+params (W $width) (COPY W))"
        . " (+size (A $sizes[0]) (B $sizes[1]) (C $sizes[2]) (DATA 1) (OTHER 1))"
        . " (idle (<$expression (= (DATA 1)) (= (OTHER 1))) (-> idle)))";
    my $module = FSM::Adapter::FSMGenFull->new->parse_fsm(scalar Lispish::multi(\$source));
    my $ctx = $options{ctx} // FSM::HDL::FlattenedDT->new;
    my $capture = FSM::Backend::VerilogFamily::DeclarationCapture->new;
    my $collect_class = 'FSM::HDL::FlattenedDT::Backend::SystemVerilog::ConsolidatedIntermediateSupport';
    my $tail_class = 'FSM::HDL::FlattenedDT::Backend::SystemVerilog::GenerationTailSupport';
    my $collect = $collect_class->can('collect_consolidated_intermediate_signals');
    my $tail = $tail_class->can('generate_systemverilog_tail');
    my $decl = FSM::DirectDeclaredWidthSupport->can('prepare_source_tree_declaration');
    my $complete = FSM::DirectDeclaredWidthSupport->can('prepare_source_tree_intermediate_range');
    my ($all, $hdl, $error, $name, %policies, %observed, %children);
    my $record = FSM::Backend::VerilogFamily::DeclarationCapture->can('record_intermediate_assignment');
    {
        no strict 'refs'; no warnings 'redefine';
        local *{"${collect_class}::collect_consolidated_intermediate_signals"} = sub {
            ++$observed{collections}; $all = $collect->(@_);
            for my $candidate (sort keys %$all) {
                my $p = $ctx->{backend_sv_intermediate_width_support}->source_bitwise_tree_width_allocation($candidate, $all->{$candidate});
                $policies{$candidate} = $p if $p;
                next unless ($all->{$candidate}{source} // '') eq 'fsmgen_parsing';
                $p //= $ctx->{backend_sv_intermediate_width_support}->intermediate_width_allocation($candidate, $all->{$candidate});
                $children{$_} = 1 for @{$p ? $p->{source_names} : []};
            }
            ($name) = sort {
                @{$policies{$b}{source_names}}
                    <=> @{$policies{$a}{source_names}} || $a cmp $b
            } grep {!$children{$_}} keys %policies;
            $options{before}->($ctx,$name,$all) if $options{before};
            return $all;
        };
        local *FSM::Backend::VerilogFamily::DeclarationCapture::record_intermediate_assignment = sub {
            my ($capture,$candidate,$event)=@_;
            if ($options{omit_event} && defined($name)) {
                return if $options{omit_event} eq 'root' && $candidate eq $name;
                return if $options{omit_event} eq 'child' && $candidate ne $name
                    && ($all->{$candidate}{source} // '') eq 'fsmgen_parsing';
            }
            return $record->(@_);
        };
        local *FSM::DirectDeclaredWidthSupport::prepare_source_tree_declaration = sub {
            ++$observed{source_declarations}; return $decl->(@_);
        };
        local *FSM::DirectDeclaredWidthSupport::prepare_source_tree_intermediate_range = sub {
            ++$observed{complete_targets};
            my ($class,%args)=@_;
            my $plan=$complete->(@_);
            $options{after_target}->($ctx,$args{signal_name},$name,$all,[sort keys %policies]) if $options{after_target};
            return $plan;
        };
        local *{"${tail_class}::generate_systemverilog_tail"} = sub {
            my $map = $ctx->{direct_declared_width_emitted_source_tree_ranges} // {};
            $observed{source_ledger} = $json->decode($json->encode($map));
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
subtest 'actual source trees and computed binary children emit symbolic ranges with independent closure' => sub {
    for my $expression ('(& A B C)', '(^ (| A B C) (& A C) A)', '(& A B (| (| A B C) C))') {
        for my $width (1,8) {
            my $p=fixture($expression,$width,language=>$width==1 ? 'verilog' : 'systemverilog');
            is($p->{error},undef,'actual native source generation succeeds') or diag $p->{error};
            next if $p->{error};
            my $name=$p->{name};
            like($p->{hdl},qr/^  wire \[\(W - 1\):0\] \Q$name\E;$/m,'source tree root retains the actual mutable range');
            is($p->{observed}{collections},1,'actual generation collects once');
            ok($p->{observed}{source_declarations},'declarations consume separate source intent');
            ok($p->{observed}{complete_targets},'final assembly calls independent completed-target proof');
            ok(keys(%{$p->{observed}{source_ledger}}),'source ledger records actual emitted symbolic declarations');
            for my $candidate (sort keys %{$p->{observed}{source_ledger}}) {
                my $entry=$p->{observed}{source_ledger}{$candidate};
                my $method=exists($entry->{source_tree_width_allocation}) ? 'prepare_source_tree_intermediate_range'
                    : 'prepare_computed_source_binary_intermediate_range';
                my $plan=FSM::DirectDeclaredWidthSupport->$method(flattened_dt=>$p->{ctx},signal_name=>$candidate,
                    signal_info=>$p->{all}{$candidate},target_language=>'systemverilog',%{$p->{snapshot}});
                delete @{$plan}{qw(nodes node_order)};
                is_deeply($entry,$plan,'every emitted source helper field matches independent target proof');
                like($p->{hdl},qr/^  wire \[\(W - 1\):0\] \Q$candidate\E;$/m,'every selected source ledger helper has the proved vector declaration');
            }
        }
    }
};
subtest 'source tree vector rank keeps zero nonzero and exact-one guards at default one' => sub {
    my $p=fixture('(& A B C)',1); is($p->{error},undef,'source guard generation succeeds');
    my $name=$p->{name};
    is_deeply($p->{observed}{truth},{'==0'=>"(~|$name)",'!=0'=>"(|$name)",'==1'=>"$name == 1"},
        'whole symbolic source helper truth cannot fold to scalar negation');
    like($p->{hdl},qr/^  assign idle_data_1_en = idle_en && /m,'whole source predicate uses logical enable gating');
    ok($p->{observed}{ledger_unchanged},'guard classification preserves declaration intent');
};
subtest 'logical negation and unary reductions retain scalar results beside source vector ranges' => sub {
    my $negated=fixture('(! (& A B C))',1);
    is($negated->{error},undef,'logical negation around a symbolic source tree still generates');
    ok(keys(%{$negated->{observed}{source_ledger}}),'underlying source bitwise tree retains its vector declaration');
    like($negated->{hdl},qr/!\Q$negated->{name}\E/,'logical NOT consumes the whole source vector');
    my $unary=fixture('(^ A)',1);
    is($unary->{error},undef,'unary reduction over symbolic input still generates');
    is_deeply($unary->{observed}{source_ledger},{},'scalar reduction acquires no source vector ledger');
    my @reductions=grep {exists($unary->{snapshot}{target_intermediates}{$_}{reduction_origin})}
        keys %{$unary->{snapshot}{target_intermediates}};
    ok(@reductions,'actual selected reduction result remains visible');
    is($unary->{snapshot}{target_declarations}{$_}{width},1,'actual reduction declaration stays scalar') for @reductions;
};
subtest 'independent fixed source widths preserve numeric declarations and empty ledger' => sub {
    my $p=fixture('(& A B (| (| A B C) C))',8,sizes=>['8','4','2']);
    is($p->{error},undef,'independent fixed nested source still generates');
    my $name=$p->{name};
    like($p->{hdl},qr/^  wire \[7:0\] \Q$name\E;$/m,'fixed selected source maximum stays numeric');
    is_deeply($p->{observed}{source_ledger},{},'fixed helpers acquire no symbolic source ledger');
};
subtest 'missing pre-declaration policy and actual selected root or child event cannot fall back' => sub {
    my $missing=fixture('(& A B C)',1,before=>sub {
        my ($ctx,$name)=@_;delete $ctx->{backend_sv_intermediate_width_support}{_source_bitwise_tree_allocation_events}{$name};
    });
    ok($missing->{error},'absent current policy cannot emit numeric fallback for a symbolic source tree');
    is($missing->{hdl},undef,'missing source policy returns no artifact');
    ok(!eval {$missing->{capture}->snapshot;1},'missing source policy exposes no completed capture');
    for my $which ('child','root') {
        my $p=fixture('(& A B (| (| A B C) C))',1,omit_event=>$which);
        ok($p->{error},"actual missing $which assignment event refuses final closure");
        is($p->{hdl},undef,'missing selected event returns no HDL');
        ok(!eval {$p->{capture}->snapshot;1},'missing selected event invalidates capture');
    }
};
subtest 'a later target proof cannot revoke an earlier source helper after its own proof' => sub {
    my $changed;
    my $p=fixture('(& A B (| (| A B C) C))',1,after_target=>sub {
        my ($ctx,$current,$root,$rows,$trees)=@_;
        if ($current eq $trees->[-1] && $current ne $root) {
            $rows->{$root}{state_model}='changed by a later target proof'; ++$changed;
        }
    });
    ok($changed,'change follows a later selected child target proof');
    ok($p->{error},'whole-generation currentness rejects previously proved row revoked by a later proof');
    is($p->{hdl},undef,'cross-root late change returns no HDL');
    ok(!eval {$p->{capture}->snapshot;1},'cross-root failure invalidates completed capture');
};
subtest 'incompatible source contracts and late source ledger or selected targets return no artifact' => sub {
    my $bad=fixture('(& A B C)',8,sizes=>['(param W)','(param W)','(param COPY)']);
    ok($bad->{error},'different original mutable ancestry refuses despite equal defaults');
    is($bad->{hdl},undef,'source refusal returns no HDL');
    ok(!eval {$bad->{capture}->snapshot;1},'source refusal exposes no completed snapshot');
    for my $change (
        sub {my $a=$_[0]{fsm_module}->signals->{A};$a->set_attribute('width_declared',$a->get_attribute('width_declared'))},
        sub {my ($ctx,$name)=@_;$ctx->{direct_declared_width_emitted_source_tree_ranges}{$name}{width_plan}{width_contract}{expression}[1]='WRONG'},
        sub {my ($ctx,$name)=@_;delete $ctx->{direct_declared_width_emitted_source_tree_ranges}{$name}},
        sub {my ($ctx,$name,$rows)=@_;$rows->{$name}{state_model}='late source state'},
    ) {
        my $p=fixture('(& A B (| (| A B C) C))',8,late=>$change);
        ok($p->{error},'late source/row/complete ledger disagreement refuses');
        is($p->{hdl},undef,'late refusal returns no artifact');
        ok(!eval {$p->{capture}->snapshot;1},'late refusal invalidates the completed snapshot');
        my $retry=fixture('(& A B (| (| A B C) C))',1,ctx=>$p->{ctx});
        is($retry->{error},undef,'fresh same-backend generation recovers');
    }
};
done_testing();
