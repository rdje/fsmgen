use strict;
use warnings;
use lib 'perl';
use Test::More;
use JSON::PP;
use FSM::CoreAST;
use FSM::HDL::FlattenedDT;
my $json=JSON::PP->new->canonical;
my $has_api=FSM::HDL::FlattenedDT::Backend::SystemVerilog::IntermediateSignalWidthSupport->can('factorized_width_allocation');
sub model {
    my ($width,$op) = @_;
    my %s = map {$_=>FSM::CoreAST::Signal->new(name=>$_,width=>/^[AB]$/?$width:1)} qw(A B DATA OTHER);
    my $condition=FSM::CoreAST::BinaryOp->new($op,FSM::CoreAST::SignalRef->new($s{A}),FSM::CoreAST::SignalRef->new($s{B}));
    my @actions=map {FSM::CoreAST::Assignment->new(target=>FSM::CoreAST::SignalRef->new($s{$_}),source=>FSM::CoreAST::Literal->new('1'))} qw(DATA OTHER);
    my $branch=FSM::CoreAST::ConditionalBranch->new(condition=>$condition,branches=>[{condition=>$condition,actions=>\@actions}]);
    my $tree=FSM::CoreAST::DecisionTree->new(name=>'idle',elements=>[$branch,FSM::CoreAST::StateTransitionFSM->new(target_state=>'idle')]);
    return FSM::CoreAST::FSMModule->new(name=>'inference',signals=>\%s,states=>[FSM::CoreAST::State->new(name=>'idle',decision_trees=>[$tree])]);
}
sub policy {
    my($owner,$name,$info)=@_;
    return $has_api ? scalar($owner->factorized_width_allocation($name,$info)) : undef;
}
sub expected {{kind=>'binary_operand_max',operator=>$_[0],source_names=>['A','B'],selected_width=>$_[1]}}
sub probe {
    my($width,%options)=@_;my $module=model($width,$options{operator}//'&');my $backend=FSM::HDL::FlattenedDT->new;
    my $normal=FSM::HDL::FlattenedDT::Backend::SystemVerilog::ConsolidatedIntermediateNormalizationSupport->can('normalize_consolidated_intermediate_metadata');
    my $collect=FSM::HDL::FlattenedDT::Backend::SystemVerilog::ConsolidatedIntermediateSupport->can('collect_consolidated_intermediate_signals');
    my $resolve=FSM::HDL::FlattenedDT::Backend::SystemVerilog::IntermediateSignalWidthSupport->can('resolve_intermediate_signal_width');
    my $dependencies=FSM::HDL::FlattenedDT::Backend::SystemVerilog::IntermediateSignalRecoverySupport->can('resolve_intermediate_signal_dependencies');
    my $sync=FSM::HDL::FlattenedDT::Backend::SystemVerilog::ConsolidatedIntermediateSupport->can('sync_consolidated_signals_to_registry');
    my $declarations=FSM::HDL::FlattenedDT::Backend::SystemVerilog::ConsolidatedIntermediateDeclarationSupport->can('render_consolidated_intermediate_declarations');
    my ($name,$all,$hdl,$ok,$error,@observations);
    {
        no warnings 'redefine';
        local *FSM::HDL::FlattenedDT::Backend::SystemVerilog::ConsolidatedIntermediateNormalizationSupport::normalize_consolidated_intermediate_metadata=sub {
            my($self,$rows)=@_;$all=$rows;
            ($name)=grep {my $b=$self->{flattened_dt}{ast_factorizer}->intermediate_width_allocation_birth($_);$b && $json->encode($b->{source_names}) eq '["A","B"]'} keys %$rows;
            die "candidate missing\n" unless defined $name;
            my $ok=eval {$normal->(@_);1};my $error=$@;
            unless ($ok) {
                push @observations,{phase=>'normalization_failed',events=>$json->decode($json->encode($self->{flattened_dt}{backend_sv_intermediate_width_support}{_width_inference_events}))};
                die $error;
            }
            push @observations,{phase=>'normalized',policy=>scalar(policy($self->{flattened_dt}{backend_sv_intermediate_width_support},$name,$rows->{$name}))};
        };
        local *FSM::HDL::FlattenedDT::Backend::SystemVerilog::ConsolidatedIntermediateSupport::collect_consolidated_intermediate_signals=sub {
            my($self)=@_;my $rows;my $ok=eval {$rows=$collect->(@_);1};my $error=$@;
            unless ($ok) {
                push @observations,{phase=>'collection_failed',events=>$json->decode($json->encode($self->{flattened_dt}{backend_sv_intermediate_width_support}{_width_inference_events}))};
                die $error;
            }
            push @observations,{phase=>'collected',policy=>scalar(policy($self->{flattened_dt}{backend_sv_intermediate_width_support},$name,$rows->{$name}))};
            return $rows;
        };
        local *FSM::HDL::FlattenedDT::Backend::SystemVerilog::IntermediateSignalWidthSupport::resolve_intermediate_signal_width=sub {
            my($self,$n,$info)=@_;my $width=$resolve->(@_);
            push @observations,{phase=>'resolved',event=>scalar($self->factorized_width_inference_event($n,$info)),policy=>scalar(policy($self,$n,$info))} if defined($name) && $n eq $name;
            return $width;
        };
        local *FSM::HDL::FlattenedDT::Backend::SystemVerilog::IntermediateSignalRecoverySupport::resolve_intermediate_signal_dependencies=sub {
            die "injected normalization failure\n" if $options{fail_normalization} && defined($name) && $_[1] eq $name;
            return $dependencies->(@_);
        };
        local *FSM::HDL::FlattenedDT::Backend::SystemVerilog::ConsolidatedIntermediateSupport::sync_consolidated_signals_to_registry=sub {
            my $result=$sync->(@_);die "injected registry failure\n" if $options{fail_registry} && defined $name;return $result;
        };
        local *FSM::HDL::FlattenedDT::Backend::SystemVerilog::ConsolidatedIntermediateDeclarationSupport::render_consolidated_intermediate_declarations=sub {
            my $result=$declarations->(@_);die "injected generation failure\n" if $options{fail_generation};return $result;
        };
        $ok=eval {$hdl=$backend->generate_systemverilog($module);1};$error=$@;
    }
    return {ok=>$ok,error=>$error,hdl=>$hdl,backend=>$backend,module=>$module,name=>$name,all=>$all,observations=>\@observations};
}
subtest 'completed current policy survives actual cache selection' => sub {
    for my $width (1,8) {for my $op ('&','|','^') {
        my $p=probe($width,operator=>$op);ok($p->{ok},'actual generation succeeds') or diag $p->{error};
        my @resolved=grep {$_->{phase} eq 'resolved'} @{$p->{observations}};
        ok(@resolved>=2,'actual inference and later declaration cache observed');
        is($resolved[0]{policy},undef,'initial inference is not completed policy');
        is_deeply($resolved[-1]{event},expected($op,$width),'actual subsequent cache retains the original event');
        is_deeply($resolved[-1]{policy},expected($op,$width),'successful collected policy survives cache');
        my ($normalized)=grep {$_->{phase} eq 'normalized'} @{$p->{observations}};
        is($normalized->{policy},undef,'normalization alone is incomplete');
        my ($collected)=grep {$_->{phase} eq 'collected'} @{$p->{observations}};
        is_deeply($collected->{policy},expected($op,$width),'actual registry handoff completes policy');
    }}
};
subtest 'unknown changes and recursive fallback cannot revive cached policy' => sub {
    plan skip_all=>'completed policy API absent' unless $has_api;
    for my $mutate (
        sub {$_[2]{width}=32},
        sub {$_[2]{width_source}='independent'},
        sub {my($ctx,$n)=@_;$ctx->{intermediate_signals}{$n}={%{$ctx->{intermediate_signals}{$n}}}},
        sub {my($ctx)=@_;my $a=$ctx->{fsm_module}->signals->{A};$a->set_attribute('width_declared',$a->get_attribute('width_declared'))},
    ) {
        my $p=probe(8);my $ctx=$p->{backend};my $owner=$ctx->{backend_sv_intermediate_width_support};my $n=$p->{name};my $info=$p->{all}{$n};
        ok(policy($owner,$n,$info),'baseline complete');$mutate->($ctx,$n,$info);
        $owner->resolve_intermediate_signal_width($n,$info,$p->{all});
        is(policy($owner,$n,$info),undef,'new floor/label/copy/source change cannot be rebased');
    }
    my $p=probe(8);my $owner=$p->{backend}{backend_sv_intermediate_width_support};my $n=$p->{name};my $info=$p->{all}{$n};
    is(policy($owner,$n,{%$info}),undef,'equal input clone cannot borrow completed policy');
    is($owner->resolve_intermediate_signal_width($n,$info,$p->{all},{$n=>1}),8,'recursive fallback keeps numeric result');
    is(policy($owner,$n,$info),undef,'recursive fallback revokes policy');
    $owner->resolve_intermediate_signal_width($n,$info,$p->{all});
    is(policy($owner,$n,$info),undef,'later cache equality cannot remint');
};
subtest 'matching source mutation during scalar cache inference revokes' => sub {
    plan skip_all=>'completed policy API absent' unless $has_api;
    my $p=probe(1);my $ctx=$p->{backend};my $owner=$ctx->{backend_sv_intermediate_width_support};my $n=$p->{name};my $info=$p->{all}{$n};
    my $infer=$owner->can('infer_width_from_intermediate_ast');my $changed;
    {
        no warnings 'redefine';
        local *FSM::HDL::FlattenedDT::Backend::SystemVerilog::IntermediateSignalWidthSupport::infer_width_from_intermediate_ast=sub {
            my $value=$infer->(@_);
            unless ($changed++) {my $a=$ctx->{fsm_module}->signals->{A};$a->set_attribute('width_declared',$a->get_attribute('width_declared'))}
            return $value;
        };
        is($owner->resolve_intermediate_signal_width($n,$info,$p->{all}),1,'actual scalar AST cache path keeps numeric selection');
    }
    ok($changed,'actual recursive AST inference was reached');
    is(policy($owner,$n,$info),undef,'matching mutation inside cache inference cannot refresh');
};
subtest 'normalization registry and later generation failures clear partial policy' => sub {
    plan skip_all=>'completed policy API absent' unless $has_api;
    for my $phase ('normalization','registry','generation') {
        my $p=probe(8,'fail_'.$phase=>1);ok(!$p->{ok},'injected actual phase fails');like($p->{error},qr/injected .* failure/,'original failure preserves');
        my $owner=$p->{backend}{backend_sv_intermediate_width_support};
        is(policy($owner,$p->{name},$p->{all}{$p->{name}}),undef,'failed generation leaves no completed policy');
        is_deeply($owner->{_width_inference_events},{},'partial diagnostic events clear');
        for my $observation (grep {$_->{phase}=~/_failed$/} @{$p->{observations}}) {
            is_deeply($observation->{events},{},'inner failing boundary clears before outer generation catches');
        }
    }
};
subtest 'reset repeated normalization and generator reuse start fresh scopes' => sub {
    plan skip_all=>'completed policy API absent' unless $has_api;
    my $p=probe(8);my $ctx=$p->{backend};my $owner=$ctx->{backend_sv_intermediate_width_support};my $n=$p->{name};my $info=$p->{all}{$n};
    my $record=policy($owner,$n,$info);$record->{source_names}[0]='WRONG';
    is_deeply(policy($owner,$n,$info),expected('&',8),'completed getter detaches');
    $ctx->{backend_sv_consolidated_intermediate_normalization_support}->normalize_consolidated_intermediate_metadata($p->{all});
    is(policy($owner,$n,$info),undef,'repeated normalization starts a fresh epoch without reminting cache proof');
    $ctx->{orchestrator}->reset_generation_state;
    is_deeply($owner->{_width_inference_events},{},'explicit generation reset clears retained plain capsules');
    my $hdl=$ctx->generate_systemverilog($p->{module});ok(defined $hdl,'same backend can generate again');
    is(policy($owner,$n,$info),undef,'old exact metadata cannot borrow the new generation');
};
subtest 'normalization wrapper preserves scalar list and void caller contexts' => sub {
    my $ctx=FSM::HDL::FlattenedDT->new;
    my $normalizer=$ctx->{backend_sv_consolidated_intermediate_normalization_support};my $void;
    {
        no warnings 'redefine';
        local *FSM::HDL::FlattenedDT::Backend::SystemVerilog::ConsolidatedIntermediateNormalizationSupport::_normalize_metadata=sub {
            if (!defined wantarray) {++$void;return}
            return wantarray ? ('left','right') : 'scalar';
        };
        is(scalar($normalizer->normalize_consolidated_intermediate_metadata({})),'scalar','scalar context preserves');
        my @values=$normalizer->normalize_consolidated_intermediate_metadata({});is_deeply(\@values,['left','right'],'list context preserves');
        $normalizer->normalize_consolidated_intermediate_metadata({});is($void,1,'void context preserves');
    }
};
done_testing();
